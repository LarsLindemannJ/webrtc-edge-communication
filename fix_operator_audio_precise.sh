#!/usr/bin/env bash
set -e

cp public/operator-camera-audio-widgets.js public/operator-camera-audio-widgets.js.backup.precise-operator-audio.$(date +%Y%m%d-%H%M%S)

python3 <<'PY'
from pathlib import Path

p = Path("public/operator-camera-audio-widgets.js")
s = p.read_text()

s = s.replace(
'''      document.getElementById("operatorAudio") ||
      document.getElementById("localOperatorAudio") ||
      document.querySelector("audio");''',
'''      document.getElementById("operatorAudio") ||
      document.getElementById("localOperatorAudio") ||
      (operatorAudioLabel ? operatorAudioLabel.parentElement.querySelector("audio") : null);'''
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
