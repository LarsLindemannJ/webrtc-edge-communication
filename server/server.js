const express = require("express");
const http = require("http");
const https = require("https");
const fs = require("fs");
const path = require("path");
const { ExpressPeerServer } = require("peer");

const app = express();

const HTTP_PORT = Number(process.env.HTTP_PORT || 8080);
const HTTPS_PORT = Number(process.env.HTTPS_PORT || 8443);
const CERT_DIR = process.env.CERT_DIR || "cert";
const CERT_KEY_PATH = path.join(CERT_DIR, "key.pem");
const CERT_PATH = path.join(CERT_DIR, "cert.pem");

app.get("/api/whoami", (req, res) => {
  res.json({
    remoteAddress: req.socket.remoteAddress,
    xForwardedFor: req.headers["x-forwarded-for"] || null,
    userAgent: req.headers["user-agent"] || null
  });
});

app.get("/api/status", (req, res) => {
  res.json({
    ok: true,
    service: "webrtc-support",
    time: new Date().toISOString(),
    uptimeSeconds: Math.round(process.uptime()),
    peerjs: true,
    httpsEnabled: fs.existsSync(CERT_KEY_PATH) && fs.existsSync(CERT_PATH)
  });
});

app.use(express.static("public"));

function createPeerMiddleware(server) {
  return ExpressPeerServer(server, {
    debug: true,
    path: "/"
  });
}

const hasCertificates = fs.existsSync(CERT_KEY_PATH) && fs.existsSync(CERT_PATH);

if (hasCertificates) {
  const httpsServer = https.createServer({
    key: fs.readFileSync(CERT_KEY_PATH),
    cert: fs.readFileSync(CERT_PATH)
  }, app);

  app.use("/peerjs", createPeerMiddleware(httpsServer));

  httpsServer.listen(HTTPS_PORT, "0.0.0.0", () => {
    console.log(`HTTPS running on port ${HTTPS_PORT}`);
    console.log(`PeerJS available at https://localhost:${HTTPS_PORT}/peerjs`);
  });

  const redirectApp = express();
  redirectApp.get("/api/status", (req, res) => res.redirect(`https://${req.hostname}:${HTTPS_PORT}/api/status`));
  redirectApp.use((req, res) => res.redirect(`https://${req.hostname}:${HTTPS_PORT}${req.url}`));

  http.createServer(redirectApp).listen(HTTP_PORT, "0.0.0.0", () => {
    console.log(`HTTP redirect running on port ${HTTP_PORT}`);
  });
} else {
  const httpServer = http.createServer(app);

  app.use("/peerjs", createPeerMiddleware(httpServer));

  httpServer.listen(HTTP_PORT, "0.0.0.0", () => {
    console.log(`HTTP running on port ${HTTP_PORT}`);
    console.log(`PeerJS available at http://localhost:${HTTP_PORT}/peerjs`);
    console.log("No certificates found. For camera/microphone access from other devices, generate local HTTPS certificates with scripts/generate-dev-cert.sh");
  });
}
