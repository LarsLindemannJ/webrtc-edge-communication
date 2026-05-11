#!/usr/bin/env bash
set -e

cp public/operator.html public/operator.html.backup.before-grid-safe.$(date +%Y%m%d-%H%M%S)

mkdir -p public/vendor/gridstack

curl -L https://cdn.jsdelivr.net/npm/gridstack@10.3.1/dist/gridstack.min.css \
  -o public/vendor/gridstack/gridstack.min.css

curl -L https://cdn.jsdelivr.net/npm/gridstack@10.3.1/dist/gridstack-all.js \
  -o public/vendor/gridstack/gridstack-all.js

cat > public/operator-grid-safe.css <<'CSS'
.operator-layout-toolbar {
  display: flex;
  gap: 8px;
  margin: 12px 0;
}

.operator-layout-toolbar button {
  padding: 8px 12px;
}

.grid-stack-item-content {
  background: var(--panel, #111827);
  color: var(--text, #f9fafb);
  border: 1px solid var(--border, #374151);
  border-radius: var(--radius, 12px);
  padding: 10px;
  overflow: auto;
}

.operator-widget-title {
  font-weight: 700;
  cursor: move;
  margin-bottom: 8px;
  color: var(--accent, #ff8800);
  border-bottom: 1px solid var(--border, #374151);
  padding-bottom: 6px;
}
CSS

cat > public/operator-grid-safe.js <<'JS'
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
JS

python3 <<'PY'
from pathlib import Path

p = Path("public/operator.html")
s = p.read_text()

# Fjern gamle GridStack references
bad = [
  '<link rel="stylesheet" href="vendor/gridstack/gridstack.min.css">',
  '<link rel="stylesheet" href="operator-grid.css">',
  '<link rel="stylesheet" href="operator-widgets.css">',
  '<link rel="stylesheet" href="operator-grid-safe.css">',
  '<script src="vendor/gridstack/gridstack-all.js"></script>',
  '<script src="operator-grid.js"></script>',
  '<script src="operator-widgets.js"></script>',
  '<script src="operator-grid-safe.js"></script>',
]

for b in bad:
    for pre in ["", "  ", "    ", "      ", "        "]:
        s = s.replace(pre + b + "\n", "")
        s = s.replace(pre + b, "")

s = s.replace("</head>", '''  <link rel="stylesheet" href="vendor/gridstack/gridstack.min.css">
  <link rel="stylesheet" href="operator-grid-safe.css">
</head>''', 1)

idx = s.rfind("</body>")
insert = '''  <script src="vendor/gridstack/gridstack-all.js"></script>
  <script src="operator-grid-safe.js"></script>
'''
s = s[:idx] + insert + s[idx:]

p.write_text(s)
PY

echo "Safe GridStack base added."
