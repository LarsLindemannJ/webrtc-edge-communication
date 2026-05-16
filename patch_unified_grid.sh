#!/usr/bin/env bash
set -e

cp public/operator.html public/operator.html.backup.unified-grid.$(date +%Y%m%d-%H%M%S)

cat > public/operator-main-grid.css <<'CSS'
#operatorMainGrid {
  margin-top: 20px;
}

#operatorMainGrid .grid-stack-item-content {
  background: var(--panel, #111827);
  color: var(--text, #f9fafb);
  border: 1px solid var(--border, #374151);
  border-radius: 12px;
  overflow: auto;
  padding: 10px;
}
CSS

cat > public/operator-main-grid.js <<'JS'
(function () {
  const STORAGE_KEY = "webrtc-main-grid-layout-v1";

  function collectWidgets(mainGridEl) {
    const grids = Array.from(document.querySelectorAll(".grid-stack"))
      .filter(g => g.id !== "operatorMainGrid");

    grids.forEach(gridEl => {
      const items = Array.from(gridEl.querySelectorAll(".grid-stack-item"));

      items.forEach(item => {
        mainGridEl.appendChild(item);
      });

      gridEl.remove();
    });
  }

  function initUnifiedGrid() {
    if (document.getElementById("operatorMainGrid")) return;

    const anchor =
      document.querySelector(".grid-stack-item") ||
      document.querySelector("video") ||
      document.body.firstElementChild;

    if (!anchor || !anchor.parentNode) {
      console.warn("UnifiedGrid: kunne ikke finde anchor");
      return;
    }

    const mainGrid = document.createElement("div");
    mainGrid.id = "operatorMainGrid";
    mainGrid.className = "grid-stack";

    anchor.parentNode.insertBefore(mainGrid, anchor);

    collectWidgets(mainGrid);

    const grid = GridStack.init({
      column: 12,
      cellHeight: 70,
      margin: 8,
      float: true,
      animate: true,
      resizable: { handles: "e,se,s,sw,w" }
    }, mainGrid);

    const saved = localStorage.getItem(STORAGE_KEY);

    if (saved) {
      try {
        grid.load(JSON.parse(saved));
      } catch (err) {
        console.warn("Kunne ikke indlæse layout", err);
      }
    }

    grid.on("change", () => {
      localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify(grid.save(false))
      );
    });

    window.operatorMainGrid = grid;

    console.log("Unified Grid initialiseret");
  }

  window.addEventListener("load", () => {
    setTimeout(initUnifiedGrid, 1000);
  });
})();
JS

python3 <<'PY'
from pathlib import Path

p = Path("public/operator.html")
s = p.read_text()

for inc in [
  '<link rel="stylesheet" href="operator-main-grid.css">',
  '<script src="operator-main-grid.js"></script>',
]:
    s = s.replace("  " + inc + "\n", "")
    s = s.replace(inc + "\n", "")
    s = s.replace(inc, "")

s = s.replace(
    "</head>",
    '  <link rel="stylesheet" href="operator-main-grid.css">\n</head>',
    1
)

idx = s.rfind("</body>")

s = (
    s[:idx]
    + '  <script src="operator-main-grid.js"></script>\n'
    + s[idx:]
)

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
