#!/usr/bin/env bash
set -e

cp public/operator-camera-audio-widgets.js public/operator-camera-audio-widgets.js.backup.audiofix.$(date +%Y%m%d-%H%M%S)

python3 <<'PY'
from pathlib import Path

p = Path("public/operator-camera-audio-widgets.js")
s = p.read_text()

old = '''    const operatorAudioBtn =
      document.getElementById("operatorAudioToggleBtn") ||
      byTextContains("button", "Operator-lyd");'''

new = '''    const operatorAudioBtn =
      document.getElementById("operatorAudioToggleBtn") ||
      document.getElementById("operatorAudioBtn") ||
      document.getElementById("startOperatorAudioBtn") ||
      document.getElementById("operatorMuteBtn") ||
      byTextContains("button", "Operator-lyd") ||
      byTextContains("button", "Operator lyd") ||
      byTextContains("button", "Audio Operator") ||
      byTextContains("button", "Start operator-lyd") ||
      byTextContains("button", "Start lyd");'''

s = s.replace(old, new)

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
