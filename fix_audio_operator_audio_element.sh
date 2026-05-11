#!/usr/bin/env bash
set -e

cp public/operator-camera-audio-widgets.js public/operator-camera-audio-widgets.js.backup.operatoraudio.$(date +%Y%m%d-%H%M%S)

python3 <<'PY'
from pathlib import Path

p = Path("public/operator-camera-audio-widgets.js")
s = p.read_text()

old = '''    const audioNodes = [operatorAudioBtn, clientAudioBtn, clientVolume, audioStatus].filter(Boolean);'''

new = '''    const operatorAudioLabel =
      byTextContains("div", "Operator-lyd") ||
      byTextContains("p", "Operator-lyd") ||
      byTextContains("span", "Operator-lyd");

    const operatorAudioElement =
      document.getElementById("operatorAudio") ||
      document.getElementById("localOperatorAudio") ||
      document.querySelector("audio");

    const clientAudioLabel =
      byTextContains("div", "Operator-lyd hos klient") ||
      byTextContains("p", "Operator-lyd hos klient") ||
      byTextContains("span", "Operator-lyd hos klient");

    if (operatorAudioLabel) operatorAudioLabel.textContent = "Audio Operator";
    if (clientAudioLabel) clientAudioLabel.textContent = "Audio bruger";

    const audioNodes = [
      operatorAudioLabel,
      operatorAudioElement,
      clientAudioLabel,
      operatorAudioBtn,
      clientAudioBtn,
      clientVolume,
      audioStatus
    ].filter(Boolean);'''

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
