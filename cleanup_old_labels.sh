#!/usr/bin/env bash
set -e

cat > public/operator-widget-cleanup.js <<'JS'
window.addEventListener("load", () => {
  setTimeout(() => {

    const textsToHide = [
      "Operator-lyd",
      "Operator-lyd hos klient",
      "Kamera-vælger"
    ];

    const elements = Array.from(
      document.querySelectorAll("div,h1,h2,h3,h4,p,span")
    );

    elements.forEach(el => {
      const txt = (el.innerText || el.textContent || "").trim();

      if (textsToHide.includes(txt)) {
        el.style.display = "none";
      }
    });

    const oldCameraSelector =
      Array.from(document.querySelectorAll("*"))
      .find(el =>
        (el.innerText || "").includes("Vis stream") &&
        (el.innerText || "").includes("Skjul/sluk")
      );

    if (oldCameraSelector) {
      oldCameraSelector.style.display = "none";
    }

  }, 1200);
});
JS

python3 <<'PY'
from pathlib import Path

p = Path("public/operator.html")
s = p.read_text()

line = '<script src="operator-widget-cleanup.js"></script>'

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
