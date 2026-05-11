#!/usr/bin/env bash
set -e

cp public/operator.html public/operator.html.backup.design-mode.$(date +%Y%m%d-%H%M%S)

cat > public/operator-design-mode.css <<'CSS'
#designModeToolbar {
  position: fixed;
  right: 16px;
  top: 16px;
  z-index: 99999;
  background: var(--panel, #111827);
  color: var(--text, #f9fafb);
  border: 1px solid var(--border, #374151);
  border-radius: 12px;
  padding: 10px;
  display: flex;
  gap: 8px;
  box-shadow: 0 10px 24px rgba(0,0,0,.35);
}

#designModeToolbar button {
  padding: 8px 12px;
}

body.design-mode-on .grid-stack-item-content {
  outline: 2px dashed var(--accent, #ff8800);
}

body.design-mode-off .grid-stack-item-content {
  outline: none;
}
CSS

cat > public/operator-design-mode.js <<'JS'
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
JS

python3 <<'PY'
from pathlib import Path

p = Path("public/operator.html")
s = p.read_text()

for inc in [
  '<link rel="stylesheet" href="operator-design-mode.css">',
  '<script src="operator-design-mode.js"></script>',
]:
    s = s.replace("  " + inc + "\n", "")
    s = s.replace(inc + "\n", "")
    s = s.replace(inc, "")

s = s.replace("</head>", '  <link rel="stylesheet" href="operator-design-mode.css">\n</head>', 1)

idx = s.rfind("</body>")
s = s[:idx] + '  <script src="operator-design-mode.js"></script>\n' + s[idx:]

p.write_text(s)
PY

docker stop webrtc-support || true
docker rm webrtc-support || true
docker build -t webrtc-support .
docker run -d \
  --name webrtc-support \
  --restart unless-stopped \
  -p 8443:8443 \
  webrtc-support
