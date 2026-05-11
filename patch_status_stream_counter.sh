#!/usr/bin/env bash
set -e

cp public/operator-status-widget.js public/operator-status-widget.js.backup.streamcounter.$(date +%Y%m%d-%H%M%S)

python3 <<'PY'
from pathlib import Path

p = Path("public/operator-status-widget.js")
s = p.read_text()

s = s.replace(
'''    if (systemStatusBox) content.appendChild(systemStatusBox);
    if (statusEl) content.appendChild(statusEl);''',
'''    if (systemStatusBox) content.appendChild(systemStatusBox);
    if (statusEl) content.appendChild(statusEl);

    const streamStatus = document.createElement("div");
    streamStatus.id = "streamStatus";
    streamStatus.style.marginTop = "8px";
    streamStatus.style.whiteSpace = "pre-wrap";
    streamStatus.textContent = "Streams: venter...";
    content.appendChild(streamStatus);

    function updateStreamStatus() {
      const videos = Array.from(document.querySelectorAll("video"));

      const activeVideos = videos.filter(v => {
        const stream = v.srcObject;
        if (!stream || !stream.getTracks) return false;
        return stream.getTracks().some(t => t.readyState === "live");
      });

      const remoteVideos = activeVideos.filter(v => v.id !== "localOperatorVideo");

      streamStatus.textContent =
        "Aktive video-streams: " + remoteVideos.length + "\\n" +
        "Alle aktive videoelementer inkl. operator-kamera: " + activeVideos.length;
    }

    setInterval(updateStreamStatus, 1000);
    updateStreamStatus();'''
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
