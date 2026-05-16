(function () {
  const STORAGE_KEY = "webrtc-support-grid-safe-v1";

  function initGrid() {
    const gridEl = document.querySelector(".grid-stack");
    if (!gridEl || !window.GridStack) return;

    const grid = GridStack.init({
      column: 12,
      cellHeight: 80,
      margin: 8,
      float: true,
      handle: ".operator-widget-title",
      resizable: { handles: "e,se,s,sw,w" }
    }, gridEl);

    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      try { grid.load(JSON.parse(saved)); } catch (e) {}
    }

    grid.on("change", () => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(grid.save(false)));
    });

    window.operatorGrid = grid;
  }

  window.addEventListener("load", initGrid);
})();
