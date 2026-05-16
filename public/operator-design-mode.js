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

  window.setOperatorDesignMode = setDesignMode;

  function createToolbar() {
    if (document.getElementById("designModeToolbar")) return;

    const toolbar = document.createElement("div");
    toolbar.id = "designModeToolbar";
    toolbar.innerHTML = `
      <button id="toggleDesignModeBtn" type="button">Design mode</button>
      <button id="saveDefaultLayoutBtn" type="button">Gem layout som default</button>
      <button id="resetAllLayoutsBtn" type="button">Reset layouts</button>
    `;

    document.body.appendChild(toolbar);

    document.getElementById("toggleDesignModeBtn").onclick = () => {
      const enabled = !document.body.classList.contains("design-mode-on");
      setDesignMode(enabled);
    };

    document.getElementById("saveDefaultLayoutBtn").onclick = () => {
      allGrids().forEach(grid => {
        try {
          if (grid.el && grid.el.id === "operatorMainGrid") {
            localStorage.setItem("webrtc-main-grid-layout-v2", JSON.stringify(grid.save(false)));
          }
        } catch (e) {}
      });
      alert("Layout gemt som default.");
    };

    document.getElementById("resetAllLayoutsBtn").onclick = () => {
      Object.keys(localStorage)
        .filter(k => k.includes("webrtc") && k.includes("layout"))
        .forEach(k => localStorage.removeItem(k));

      localStorage.setItem(STORAGE_KEY, "0");
      location.reload();
    };
  }

  window.addEventListener("load", () => {
    createToolbar();

    // Start ALTID låst som default
    localStorage.setItem(STORAGE_KEY, "0");

    // Lås både før og efter operatorMainGrid bliver oprettet ved 1500 ms
    [100, 500, 1200, 1800, 2500, 4000].forEach(ms => {
      setTimeout(() => setDesignMode(false), ms);
    });

    // Hvis nye grids dukker op senere, så lås dem også
    const observer = new MutationObserver(() => {
      if (!document.body.classList.contains("design-mode-on")) {
        setDesignMode(false);
      }
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  });
})();
