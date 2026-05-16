#!/usr/bin/env bash
set -e

cat > public/remove-empty-widget-titles.js <<'JS'
window.addEventListener("load", () => {
  setTimeout(() => {

    const titles = [
      "GPS / Lokation",
      "Batteri",
      "Telefontype",
      "Enhed",
      "Netværk / IP"
    ];

    document.querySelectorAll("*").forEach(el => {
      const txt = (el.innerText || el.textContent || "").trim();

      if (
        titles.includes(txt) &&
        !el.closest(".grid-stack-item-content")
      ) {
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

line = '<script src="remove-empty-widget-titles.js"></script>'

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
