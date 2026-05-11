#!/usr/bin/env bash
set -e

cp public/operator.html public/operator.html.backup.camera-audio.$(date +%Y%m%d-%H%M%S)

cat > public/operator-camera-audio-widgets.css <<'CSS'
#cameraWidgetGrid,
#audioWidgetGrid {
  margin: 12px 0;
}

#cameraWidgetGrid .grid-stack-item-content,
#audioWidgetGrid .grid-stack-item-content {
  background: var(--panel, #111827);
  color: var(--text, #f9fafb);
  border: 1px solid var(--border, #374151);
  border-radius: var(--radius, 12px);
  padding: 10px;
  overflow: auto;
}

.camera-audio-widget-title {
  cursor: move;
  user-select: none;
  font-weight: 700;
  color: var(--accent, #ff8800);
  border-bottom: 1px solid var(--border, #374151);
  padding-bottom: 6px;
  margin-bottom: 8px;
}

.camera-audio-widget-body video {
  width: 100%;
  max-height: 320px;
  background: #000;
}

.camera-audio-widget-buttons {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  margin-top: 8px;
}
CSS

cat > public/operator-camera-audio-widgets.js <<'JS'
(function () {
  function makeWidget({ gridId, storageKey, itemId, title, anchor, nodes, w = 6, h = 4 }) {
    if (!window.GridStack) return;
    if (!anchor || !nodes.length || document.getElementById(gridId)) return;

    const parent = anchor.parentNode;

    const gridEl = document.createElement("div");
    gridEl.id = gridId;
    gridEl.className = "grid-stack";

    parent.insertBefore(gridEl, anchor);

    const item = document.createElement("div");
    item.className = "grid-stack-item";
    item.setAttribute("gs-id", itemId);
    item.setAttribute("gs-x", "0");
    item.setAttribute("gs-y", "0");
    item.setAttribute("gs-w", String(w));
    item.setAttribute("gs-h", String(h));

    const content = document.createElement("div");
    content.className = "grid-stack-item-content";

    const titleEl = document.createElement("div");
    titleEl.className = "camera-audio-widget-title";
    titleEl.textContent = title;

    const body = document.createElement("div");
    body.className = "camera-audio-widget-body";

    const buttonRow = document.createElement("div");
    buttonRow.className = "camera-audio-widget-buttons";

    nodes.forEach(node => {
      if (!node) return;
      if (node.tagName === "BUTTON" || node.tagName === "INPUT" || node.tagName === "SELECT") {
        buttonRow.appendChild(node);
      } else {
        body.appendChild(node);
      }
    });

    if (buttonRow.children.length) body.appendChild(buttonRow);

    content.appendChild(titleEl);
    content.appendChild(body);
    item.appendChild(content);
    gridEl.appendChild(item);

    const grid = GridStack.init({
      column: 12,
      cellHeight: 70,
      margin: 8,
      float: true,
      handle: ".camera-audio-widget-title",
      resizable: { handles: "e,se,s,sw,w" }
    }, gridEl);

    const saved = localStorage.getItem(storageKey);
    if (saved) {
      try { grid.load(JSON.parse(saved)); } catch (e) {}
    }

    grid.on("change", () => {
      localStorage.setItem(storageKey, JSON.stringify(grid.save(false)));
    });
  }

  function byText(tag, text) {
    return Array.from(document.querySelectorAll(tag))
      .find(el => (el.innerText || el.textContent || "").trim() === text);
  }

  function byTextContains(tag, text) {
    return Array.from(document.querySelectorAll(tag))
      .find(el => (el.innerText || el.textContent || "").trim().includes(text));
  }

  function hideHeading(text) {
    const h = Array.from(document.querySelectorAll("h1,h2,h3,h4,p,div,span"))
      .find(el => (el.innerText || el.textContent || "").trim() === text);
    if (h) h.style.display = "none";
  }

  function initCameraAudioWidgets() {
    const localOperatorVideo =
      document.getElementById("localOperatorVideo") ||
      document.querySelector("video#operatorVideo") ||
      document.querySelector("video");

    const startOperatorBtn =
      document.getElementById("startOperatorBtn") ||
      byTextContains("button", "Start operator-kamera") ||
      byTextContains("button", "Start kamera");

    const stopOperatorBtn =
      document.getElementById("stopOperatorBtn") ||
      byTextContains("button", "Sluk operator-kamera") ||
      byTextContains("button", "Sluk kamera");

    if (localOperatorVideo && startOperatorBtn && stopOperatorBtn) {
      hideHeading("Dit kamera til brugeren");

      startOperatorBtn.textContent = "Start kamera";
      stopOperatorBtn.textContent = "Sluk kamera";

      makeWidget({
        gridId: "cameraWidgetGrid",
        storageKey: "webrtc-camera-widget-layout-v1",
        itemId: "camera-widget",
        title: "Dit kamera til brugeren",
        anchor: localOperatorVideo,
        nodes: [localOperatorVideo, startOperatorBtn, stopOperatorBtn],
        w: 6,
        h: 5
      });
    } else {
      console.warn("Kamera-widget: fandt ikke video/start/stop", {
        localOperatorVideo,
        startOperatorBtn,
        stopOperatorBtn
      });
    }

    const operatorAudioBtn =
      document.getElementById("operatorAudioToggleBtn") ||
      byTextContains("button", "Operator-lyd");

    const clientAudioBtn =
      document.getElementById("clientRemoteAudioToggleBtn") ||
      byTextContains("button", "Operator-lyd hos klient") ||
      byTextContains("button", "Mute") ||
      byTextContains("button", "Unmute");

    const audioStatus =
      document.getElementById("clientAudioControlStatus") ||
      byTextContains("div", "Ikke sendt endnu") ||
      byTextContains("span", "Ikke sendt endnu");

    const clientVolume =
      document.getElementById("clientVolumeRange");

    const audioNodes = [operatorAudioBtn, clientAudioBtn, clientVolume, audioStatus].filter(Boolean);

    if (audioNodes.length) {
      if (operatorAudioBtn) operatorAudioBtn.textContent = "Audio Operator";
      if (clientAudioBtn) clientAudioBtn.textContent = "Audio bruger";

      makeWidget({
        gridId: "audioWidgetGrid",
        storageKey: "webrtc-audio-widget-layout-v1",
        itemId: "audio-widget",
        title: "Audio",
        anchor: audioNodes[0],
        nodes: audioNodes,
        w: 6,
        h: 3
      });
    } else {
      console.warn("Audio-widget: fandt ingen audio controls");
    }
  }

  window.addEventListener("load", initCameraAudioWidgets);
})();
JS

python3 <<'PY'
from pathlib import Path

p = Path("public/operator.html")
s = p.read_text()

includes = [
  '<link rel="stylesheet" href="operator-camera-audio-widgets.css">',
  '<script src="operator-camera-audio-widgets.js"></script>',
]

for inc in includes:
    s = s.replace("  " + inc + "\n", "")
    s = s.replace(inc + "\n", "")
    s = s.replace(inc, "")

s = s.replace("</head>", '  <link rel="stylesheet" href="operator-camera-audio-widgets.css">\n</head>', 1)

idx = s.rfind("</body>")
s = s[:idx] + '  <script src="operator-camera-audio-widgets.js"></script>\n' + s[idx:]

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
