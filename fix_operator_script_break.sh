#!/usr/bin/env bash
set -e

cp public/operator.html public/operator.html.backup.scriptbreak.$(date +%Y%m%d-%H%M%S)

python3 <<'PY'
from pathlib import Path

p = Path("public/operator.html")
s = p.read_text()

s = s.replace(
    '<script src=\\"/qrcode.min.js\\"></script>',
    '<script src=\\"/qrcode.min.js\\"><\\/script>'
)

s = s.replace(
    '<script src="/qrcode.min.js"></script> findes i operator.html.',
    '<script src="/qrcode.min.js"><\\/script> findes i operator.html.'
)

p.write_text(s)
PY

rm -f public/qrcode.min.js

curl -L https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js \
  -o public/qrcode.min.js

echo "== Check qrcode file =="
head -1 public/qrcode.min.js

echo "== Check dangerous script string =="
grep -n "qrcode.min.js" public/operator.html

docker stop webrtc-support || true
docker rm webrtc-support || true

docker build -t webrtc-support .

docker run -d \
  --name webrtc-support \
  --restart unless-stopped \
  -p 8443:8443 \
  webrtc-support
