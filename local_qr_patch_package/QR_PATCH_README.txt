Lokal QR patch til WebRTC Support System

Filer:
- operator_patched.html: Tilrettet operator.html
- local_qr_patch.diff: Unified diff patch

Vigtigt:
Denne patch forventer en lokal QR-library-fil i web-roden:

  /qrcode.min.js

Brug fx qrcodejs/qrcode.min.js og læg den samme sted som operator.html/client.html serveres fra.

Efter kopiering skal operator.html indeholde:

  <script src="/qrcode.min.js"></script>

QR-knappen bruger derefter:

  new QRCode(...)

og kalder ikke længere:

  https://api.qrserver.com/...

Implementering:
1. Kopiér operator_patched.html over din eksisterende operator.html
2. Læg qrcode.min.js i web-roden
3. Genbyg/genstart Docker image/container
4. Test offline: åbn operator.html og tryk QR

Patchen tilføjer også:
- <div id="cameraSelector">...</div>, fordi eksisterende JS bruger cameraSelector.
