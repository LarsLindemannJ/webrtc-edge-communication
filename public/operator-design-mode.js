(function () {
  const STORAGE_KEY = "webrtc-design-mode-enabled";

  function allGrids() {
    return Array.from(document.querySelectorAll(".grid-stack"))
      .map(el => el.gridstack)
      .filter(Boolean);
  }

  function setDesignMode(enabled) {
    document.body.classList.toggle("design-mode-on", enabled);
    document.body.classList.toggle("design-mode-off", !enabled);

    allGrids().forEach(grid => {
      try {
        grid.enableMove(enabled);
        grid.enableResize(enabled);
      } catch (e) {
        console.warn("Kunne ikke ændre grid mode", e);
      }
    });

    localStorage.setItem(STORAGE_KEY, enabled ? "1" : "0");

    const btn = document.getElementById("toggleDesignModeBtn");
    if (btn) btn.textContent = enabled ? "Lås layout" : "Design mode";
  }

  function createToolbar() {
    if (document.getElementById("designModeToolbar")) return;

    const toolbar = document.createElement("div");
    toolbar.id = "designModeToolbar";
    toolbar.innerHTML = `
      <button id="toggleDesignModeBtn" type="button">Design mode</button>
      <button id="resetAllLayoutsBtn" type="button">Reset layouts</button>
    `;

    document.body.appendChild(toolbar);

    document.getElementById("toggleDesignModeBtn").onclick = () => {
      const enabled = !document.body.classList.contains("design-mode-on");
      setDesignMode(enabled);
    };

    document.getElementById("resetAllLayoutsBtn").onclick = () => {
      Object.keys(localStorage)
        .filter(k => k.includes("webrtc") && k.includes("widget-layout"))
        .forEach(k => localStorage.removeItem(k));

      location.reload();
    };
  }

  window.addEventListener("load", () => {
    createToolbar();

    setTimeout(() => {
      const enabled = localStorage.getItem(STORAGE_KEY) === "1";
      setDesignMode(enabled);
    }, 500);
  });
})();
