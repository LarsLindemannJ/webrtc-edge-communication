const express = require("express");
const http = require("http");
const https = require("https");
const fs = require("fs");
const { ExpressPeerServer } = require("peer");

const app = express();
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
    peerjs: true
  });
});

app.use(express.static("public"));

const httpServer = http.createServer(app);
const httpsServer = https.createServer({
  key: fs.readFileSync("cert/key.pem"),
  cert: fs.readFileSync("cert/cert.pem")
}, app);

app.use("/peerjs", ExpressPeerServer(httpsServer, {
  debug: true,
  path: "/"
}));

httpServer.listen(8080, "0.0.0.0", () => {
  console.log("HTTP running on port 8080");
});

httpsServer.listen(8443, "0.0.0.0", () => {
  console.log("HTTPS running on port 8443");
});
