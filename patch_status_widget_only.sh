#!/usr/bin/env bash
set -e

cp public/operator.html public/operator.html.backup.status-widget.$(date +%Y%m%d-%H%M%S)

mkdir -p public/vendor/gridstack

[ -f public/vendor/gridstack/gridstack.min.css ] || \
curl -L https://cdn.jsdelivr.net/npm/gridstack@10.3.1/dist/gridstack.min.css \
  -o public/vendor/gridstack/gridstack.min.css

[ -f public/vendor/gridstack/gridstack-all.js ] || \
curl -L https://cdn.jsdelivr.net/npm/gridstack@10.3.1/dist/gridstack-all.js \
  -o public/vendor/gridstack/gridstack-all.js

cat > public/operator-status-widget.css <<'CSS'
#statusWidgetGrid {
  margin: 12px 0;
}

#statusWidgetGrid .grid-stack-item-content {
  background: var(--panel, #111827);
  color: var(--text, #f9fafb);
  border: 1px solid var(--border, #374151);
  border-radius: var(--radius, 12px);
  padding: 10px;
  overflow: auto;
}

.status-widget-title {
  cursor: move;
  user-select: none;
  font-weight: 700;
  color: var(--accent, #ff8800);
  border-bottom: 1px solid var(--border, #374151);
  padding-bottom: 6px;
  margin-bottom: 8px;
}
CSS

cat > public/operator-status-widget.js <<'JS'
(function () {
  const STORAGE_KEY = "webrtc-status-widget-layout-v1";

  function initStatusWidget() {
    if (!window.GridStack) return;
    if (document.getElementById("statusWidgetGrid")) return;

    const statusEl = document.getElementById("status");
    const systemStatusBox = document.getElementById("systemStatus");

    if (!statusEl && !systemStatusBox) {
      console.warn("Status-widget: fandt ikke #status eller #systemStatus");
      return;
    }

    const first = systemStatusBox || statusEl;

    const grid = document.createElement("div");
    grid.id = "statusWidgetGrid";
    grid.className = "grid-stack";

    const item = document.createElement("div");
    item.className = "grid-stack-item";
    item.setAttribute("gs-id", "status-widget");
    item.setAttribute("gs-x", "0");
    item.setAttribute("gs-y", "0");
    item.setAttribute("gs-w", "12");
    item.setAttribute("gs-h", "2");

    const content = document.createElement("div");
    content.className = "grid-stack-item-content";

    const title = document.createElement("div");
    title.className = "status-widget-title";
    title.textContent = "Status";

    content.appendChild(title);

    if (systemStatusBox) content.appendChild(systemStatusBox);
    if (statusEl) content.appendChild(statusEl);

    item.appendChild(content);
    grid.appendChild(item);

    first.parentNode.insertBefore(grid, first);

    const gs = GridStack.init({
      column: 12,
      cellHeight: 70,
      margin: 8,
      float: true,
      handle: ".status-widget-title",
      resizable: { handles: "e,se,s,sw,w" }
    }, grid);

    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      try { gs.load(JSON.parse(saved)); } catch (e) {}
    }

    gs.on("change", () => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(gs.save(false)));
    });
  }

  window.addEventListener("load", initStatusWidget);
})();
JS

python3 <<'PY'
from pathlib import Path

p = Path("public/operator.html")
s = p.read_text()

includes = [
  '<link rel="stylesheet" href="vendor/gridstack/gridstack.min.css">',
  '<link rel="stylesheet" href="operator-status-widget.css">',
  '<script src="vendor/gridstack/gridstack-all.js"></script>',
  '<script src="operator-status-widget.js"></script>',
]

for inc in includes:
    s = s.replace("  " + inc + "\n", "")
    s = s.replace(inc + "\n", "")
    s = s.replace(inc, "")

s = s.replace("</head>", '''  <link rel="stylesheet" href="vendor/gridstack/gridstack.min.css">
  <link rel="stylesheet" href="operator-status-widget.css">
</head>''', 1)

idx = s.rfind("</body>")
s = s[:idx] + '''  <script src="vendor/gridstack/gridstack-all.js"></script>
  <script src="operator-status-widget.js"></script>
''' + s[idx:]

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

echo "Færdig. Åbn operator-siden og tryk Ctrl+Shift+R."
