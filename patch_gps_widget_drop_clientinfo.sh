#!/usr/bin/env bash
set -e

cp public/operator.html public/operator.html.backup.gps-widget.$(date +%Y%m%d-%H%M%S)

cat > public/operator-gps-widget.css <<'CSS'
#gpsWidgetGrid {
  margin: 12px 0;
}

#gpsWidgetGrid .grid-stack-item-content {
  background: var(--panel, #111827);
  color: var(--text, #f9fafb);
  border: 1px solid var(--border, #374151);
  border-radius: var(--radius, 12px);
  padding: 10px;
  overflow: auto;
}

.gps-widget-title {
  cursor: move;
  user-select: none;
  font-weight: 700;
  color: var(--accent, #ff8800);
  border-bottom: 1px solid var(--border, #374151);
  padding-bottom: 6px;
  margin-bottom: 8px;
}
CSS

cat > public/operator-gps-widget.js <<'JS'
(function () {
  const STORAGE_KEY = "webrtc-gps-widget-layout-v1";

  function hideClientInfo() {
    const clientInfo = document.getElementById("chat");
    if (!clientInfo) return;

    const heading = Array.from(document.querySelectorAll("h1,h2,h3,h4,p,div,span"))
      .find(el => (el.innerText || "").trim() === "Client info");

    if (heading) heading.style.display = "none";
    clientInfo.style.display = "none";
  }

  function initGpsWidget() {
    if (!window.GridStack) return;
    if (document.getElementById("gpsWidgetGrid")) return;

    hideClientInfo();

    const gpsBox = document.getElementById("gpsBox");
    if (!gpsBox) {
      console.warn("GPS-widget: fandt ikke #gpsBox");
      return;
    }

    const anchor = gpsBox;
    const parent = anchor.parentNode;

    const gridEl = document.createElement("div");
    gridEl.id = "gpsWidgetGrid";
    gridEl.className = "grid-stack";

    parent.insertBefore(gridEl, anchor);

    const item = document.createElement("div");
    item.className = "grid-stack-item";
    item.setAttribute("gs-id", "gps-widget");
    item.setAttribute("gs-x", "0");
    item.setAttribute("gs-y", "0");
    item.setAttribute("gs-w", "6");
    item.setAttribute("gs-h", "3");

    const content = document.createElement("div");
    content.className = "grid-stack-item-content";

    const title = document.createElement("div");
    title.className = "gps-widget-title";
    title.textContent = "GPS / Lokation";

    content.appendChild(title);
    content.appendChild(gpsBox);

    item.appendChild(content);
    gridEl.appendChild(item);

    const grid = GridStack.init({
      column: 12,
      cellHeight: 70,
      margin: 8,
      float: true,
      handle: ".gps-widget-title",
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

  window.addEventListener("load", initGpsWidget);
})();
JS

python3 <<'PY'
from pathlib import Path

p = Path("public/operator.html")
s = p.read_text()

includes = [
  '<link rel="stylesheet" href="operator-gps-widget.css">',
  '<script src="operator-gps-widget.js"></script>',
]

for inc in includes:
    s = s.replace("  " + inc + "\n", "")
    s = s.replace(inc + "\n", "")
    s = s.replace(inc, "")

if "operator-gps-widget.css" not in s:
    s = s.replace("</head>", '  <link rel="stylesheet" href="operator-gps-widget.css">\n</head>', 1)

if "operator-gps-widget.js" not in s:
    idx = s.rfind("</body>")
    s = s[:idx] + '  <script src="operator-gps-widget.js"></script>\n' + s[idx:]

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
