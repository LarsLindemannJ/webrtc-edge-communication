#!/usr/bin/env bash
set -e

cat > public/remove-old-status.js <<'JS'
window.addEventListener("load", () => {
  setTimeout(() => {

    const candidates = Array.from(document.querySelectorAll("*"));

    candidates.forEach(el => {
      const txt = (el.innerText || el.textContent || "").trim();

      const isOldStatus =
        txt.includes("System:") ||
        txt.includes("Status:");

      const insideWidget =
        el.closest(".grid-stack-item-content");

      if (isOldStatus && !insideWidget) {
        el.remove();
      }
    });

  }, 1200);
});
JS

python3 <<'PY'
from pathlib import Path

p = Path("public/operator.html")
s = p.read_text()

line = '<script src="remove-old-status.js"></script>'

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
