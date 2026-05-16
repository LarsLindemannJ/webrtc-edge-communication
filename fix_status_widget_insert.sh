#!/usr/bin/env bash
set -e

cp public/operator-status-widget.js public/operator-status-widget.js.backup.$(date +%Y%m%d-%H%M%S)

python3 <<'PY'
from pathlib import Path

p = Path("public/operator-status-widget.js")
s = p.read_text()

s = s.replace(
'''    const first = systemStatusBox || statusEl;

    const grid = document.createElement("div");''',
'''    const first = systemStatusBox || statusEl;
    const insertParent = first.parentNode;
    const insertBefore = first;

    const grid = document.createElement("div");'''
)

s = s.replace(
'''    first.parentNode.insertBefore(grid, first);''',
'''    insertParent.insertBefore(grid, insertBefore);'''
)

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
