(function () {
  const widgets = [
    {
      storage: "webrtc-phone-widget-layout-v1",
      gridId: "phoneWidgetGrid",
      itemId: "phone-widget",
      boxId: "phoneModelBox",
      title: "Telefontype",
      w: 4,
      h: 3
    },
    {
      storage: "webrtc-device-widget-layout-v1",
      gridId: "deviceWidgetGrid",
      itemId: "device-widget",
      boxId: "deviceBox",
      title: "Enhed",
      w: 4,
      h: 4
    },
    {
      storage: "webrtc-network-widget-layout-v1",
      gridId: "networkWidgetGrid",
      itemId: "network-widget",
      boxId: "ipBox",
      title: "Netværk / IP",
      w: 4,
      h: 4
    }
  ];

  function initWidget(config) {
    if (!window.GridStack) return;
    if (document.getElementById(config.gridId)) return;

    const box = document.getElementById(config.boxId);
    if (!box) {
      console.warn(config.title + "-widget: fandt ikke #" + config.boxId);
      return;
    }

    const parent = box.parentNode;

    const gridEl = document.createElement("div");
    gridEl.id = config.gridId;
    gridEl.className = "grid-stack";

    parent.insertBefore(gridEl, box);

    const item = document.createElement("div");
    item.className = "grid-stack-item";
    item.setAttribute("gs-id", config.itemId);
    item.setAttribute("gs-x", "0");
    item.setAttribute("gs-y", "0");
    item.setAttribute("gs-w", String(config.w));
    item.setAttribute("gs-h", String(config.h));

    const content = document.createElement("div");
    content.className = "grid-stack-item-content";

    const title = document.createElement("div");
    title.className = "info-widget-title";
    title.textContent = config.title;

    content.appendChild(title);
    content.appendChild(box);

    item.appendChild(content);
    gridEl.appendChild(item);

    const grid = GridStack.init({
      column: 12,
      cellHeight: 70,
      margin: 8,
      float: true,
      handle: ".info-widget-title",
      resizable: { handles: "e,se,s,sw,w" }
    }, gridEl);

    const saved = localStorage.getItem(config.storage);
    if (saved) {
      try { grid.load(JSON.parse(saved)); } catch (e) {}
    }

    grid.on("change", () => {
      localStorage.setItem(config.storage, JSON.stringify(grid.save(false)));
    });
  }

  function init() {
    widgets.forEach(initWidget);
  }

  window.addEventListener("load", init);
})();
