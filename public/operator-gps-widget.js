(function () {
  const STORAGE_KEY = "webrtc-gps-widget-layout-v1";

  function hideClientInfo() {
    const clientInfo = document.getElementById("chat");
    if (!clientInfo) return;

    const heading = Array.from(document.querySelectorAll("h1,h2,h3,h4,p,div,span"))
      .find(el => (el.innerText || "").trim() === "Client info");

    if (heading) heading.style.display = "none";
    clientInfo.style.display = "none";
  }

  function initGpsWidget() {
    if (!window.GridStack) return;
    if (document.getElementById("gpsWidgetGrid")) return;

    hideClientInfo();

    const gpsBox = document.getElementById("gpsBox");
    if (!gpsBox) {
      console.warn("GPS-widget: fandt ikke #gpsBox");
      return;
    }

    const anchor = gpsBox;
    const parent = anchor.parentNode;

    const gridEl = document.createElement("div");
    gridEl.id = "gpsWidgetGrid";
    gridEl.className = "grid-stack";

    parent.insertBefore(gridEl, anchor);

    const item = document.createElement("div");
    item.className = "grid-stack-item";
    item.setAttribute("gs-id", "gps-widget");
    item.setAttribute("gs-x", "0");
    item.setAttribute("gs-y", "0");
    item.setAttribute("gs-w", "6");
    item.setAttribute("gs-h", "3");

    const content = document.createElement("div");
    content.className = "grid-stack-item-content";

    const title = document.createElement("div");
    title.className = "gps-widget-title";
    title.textContent = "GPS / Lokation";

    content.appendChild(title);
    content.appendChild(gpsBox);

    item.appendChild(content);
    gridEl.appendChild(item);

    const grid = GridStack.init({
      column: 12,
      cellHeight: 70,
      margin: 8,
      float: true,
      handle: ".gps-widget-title",
      resizable: { handles: "e,se,s,sw,w" }
    }, gridEl);

    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      try { grid.load(JSON.parse(saved)); } catch (e) {}
    }

    grid.on("change", () => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(grid.save(false)));
    });
  }

  window.addEventListener("load", initGpsWidget);
})();
