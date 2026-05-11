(function () {
  const STORAGE_KEY = "webrtc-battery-widget-layout-v1";

  function initBatteryWidget() {
    if (!window.GridStack) return;
    if (document.getElementById("batteryWidgetGrid")) return;

    const batteryBox = document.getElementById("batteryBox");
    if (!batteryBox) {
      console.warn("Batteri-widget: fandt ikke #batteryBox");
      return;
    }

    const parent = batteryBox.parentNode;

    const gridEl = document.createElement("div");
    gridEl.id = "batteryWidgetGrid";
    gridEl.className = "grid-stack";

    parent.insertBefore(gridEl, batteryBox);

    const item = document.createElement("div");
    item.className = "grid-stack-item";
    item.setAttribute("gs-id", "battery-widget");
    item.setAttribute("gs-x", "0");
    item.setAttribute("gs-y", "0");
    item.setAttribute("gs-w", "4");
    item.setAttribute("gs-h", "3");

    const content = document.createElement("div");
    content.className = "grid-stack-item-content";

    const title = document.createElement("div");
    title.className = "battery-widget-title";
    title.textContent = "Batteri";

    content.appendChild(title);
    content.appendChild(batteryBox);

    item.appendChild(content);
    gridEl.appendChild(item);

    const grid = GridStack.init({
      column: 12,
      cellHeight: 70,
      margin: 8,
      float: true,
      handle: ".battery-widget-title",
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

  window.addEventListener("load", initBatteryWidget);
})();
