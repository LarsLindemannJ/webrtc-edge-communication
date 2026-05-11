#!/usr/bin/env bash
set -e

cat > public/hide-topbar-status.js <<'JS'
window.addEventListener("load", () => {
  setTimeout(() => {
    const statusEl = document.getElementById("status");
    const systemStatus = document.getElementById("systemStatus");

    [statusEl, systemStatus].forEach(el => {
      if (!el) return;

      if (!el.closest(".grid-stack-item-content")) {
        el.style.display = "none";
      }
    });
  }, 1200);
});
JS

python3 <<'PY'
from pathlib import Path

p = Path("public/operator.html")
s = p.read_text()

line = '<script src="hide-topbar-status.js"></script>'

s = s.replace("  " + line + "\n", "")
s = s.replace(line + "\n", "")
s = s.replace(line, "")

idx = s.rfind("</body>")
s = s[:idx] + "  " + line + "\n" + s[idx:]

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
