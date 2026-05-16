(function () {
  const STORAGE_KEY = "webrtc-main-grid-layout-v2";

  function collectWidgets(mainGridEl) {
    const oldGrids = Array.from(document.querySelectorAll(".grid-stack"))
      .filter(g => g.id !== "operatorMainGrid");

    oldGrids.forEach(gridEl => {
      const items = Array.from(gridEl.children)
        .filter(el => el.classList.contains("grid-stack-item"));

      items.forEach(item => mainGridEl.appendChild(item));

      if (gridEl.children.length === 0) {
        gridEl.remove();
      }
    });
  }

  function initUnifiedGrid() {
    if (!window.GridStack) return;
    if (document.getElementById("operatorMainGrid")) return;

    const firstOldGrid = document.querySelector(".grid-stack");

    if (!firstOldGrid || !firstOldGrid.parentNode) {
      console.warn("UnifiedGrid: fandt ingen eksisterende widgets");
      return;
    }

    const parent = firstOldGrid.parentNode;

    const mainGrid = document.createElement("div");
    mainGrid.id = "operatorMainGrid";
    mainGrid.className = "grid-stack";

    parent.insertBefore(mainGrid, firstOldGrid);

    collectWidgets(mainGrid);

    const grid = GridStack.init({
      column: 12,
      cellHeight: 70,
      margin: 8,
      float: true,
      animate: true,
      handle: ".status-widget-title, .gps-widget-title, .battery-widget-title, .info-widget-title, .camera-audio-widget-title",
      resizable: { handles: "e,se,s,sw,w" }
    }, mainGrid);

    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      try { grid.load(JSON.parse(saved)); } catch (e) {}
    }

    grid.on("change", () => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(grid.save(false)));
    });

    window.operatorMainGrid = grid;
  }

  window.addEventListener("load", () => {
    setTimeout(initUnifiedGrid, 1500);
  });
})();
