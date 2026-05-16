#!/usr/bin/env bash
set -e

cp public/operator.html public/operator.html.backup.disconnect.$(date +%Y%m%d-%H%M%S)

python3 <<'PY'
from pathlib import Path

p = Path("public/operator.html")
s = p.read_text()

needle = '''    conn.on("data", data => {'''

insert = '''
    conn.on("close", () => {
      statusEl.textContent = "klient offline - venter på genforbindelse";
    });

    conn.on("error", err => {
      statusEl.textContent = "klientforbindelse fejl: " + err.message;
    });

'''

if insert not in s:
    s = s.replace(needle, insert + needle, 1)

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
