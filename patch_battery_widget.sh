#!/usr/bin/env bash
set -e

cp public/operator.html public/operator.html.backup.battery-widget.$(date +%Y%m%d-%H%M%S)

cat > public/operator-battery-widget.css <<'CSS'
#batteryWidgetGrid {
  margin: 12px 0;
}

#batteryWidgetGrid .grid-stack-item-content {
  background: var(--panel, #111827);
  color: var(--text, #f9fafb);
  border: 1px solid var(--border, #374151);
  border-radius: var(--radius, 12px);
  padding: 10px;
  overflow: auto;
}

.battery-widget-title {
  cursor: move;
  user-select: none;
  font-weight: 700;
  color: var(--accent, #ff8800);
  border-bottom: 1px solid var(--border, #374151);
  padding-bottom: 6px;
  margin-bottom: 8px;
}
CSS

cat > public/operator-battery-widget.js <<'JS'
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
JS

python3 <<'PY'
from pathlib import Path

p = Path("public/operator.html")
s = p.read_text()

includes = [
  '<link rel="stylesheet" href="operator-battery-widget.css">',
  '<script src="operator-battery-widget.js"></script>',
]

for inc in includes:
    s = s.replace("  " + inc + "\n", "")
    s = s.replace(inc + "\n", "")
    s = s.replace(inc, "")

s = s.replace("</head>", '  <link rel="stylesheet" href="operator-battery-widget.css">\n</head>', 1)

idx = s.rfind("</body>")
s = s[:idx] + '  <script src="operator-battery-widget.js"></script>\n' + s[idx:]

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
