const express = require("express");
const http = require("http");
const https = require("https");
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { ExpressPeerServer } = require("peer");

const app = express();
app.use(express.json());

const DATA_DIR = path.join(__dirname, "..", "data");
const USERS_FILE = path.join(DATA_DIR, "users.json");
const MESSAGES_FILE = path.join(DATA_DIR, "messages.json");
const sessions = new Map();
const calls = new Map();

if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
if (!fs.existsSync(USERS_FILE)) fs.writeFileSync(USERS_FILE, "[]");
if (!fs.existsSync(MESSAGES_FILE)) fs.writeFileSync(MESSAGES_FILE, "[]");

function readUsers() {
  return JSON.parse(fs.readFileSync(USERS_FILE, "utf8"));
}

function writeUsers(users) {
  fs.writeFileSync(USERS_FILE, JSON.stringify(users, null, 2));
}

function readMessages() {
  return JSON.parse(fs.readFileSync(MESSAGES_FILE, "utf8"));
}

function writeMessages(messages) {
  fs.writeFileSync(MESSAGES_FILE, JSON.stringify(messages, null, 2));
}


function resetStatusesOnStartup() {
  const users = readUsers();
  let changed = false;

  users.forEach(u => {
    if (u.status !== "offline") {
      u.status = "offline";
      u.lastSeen = new Date().toISOString();
      changed = true;
    }
  });

  if (changed) writeUsers(users);
}


function hashPassword(password, salt = crypto.randomBytes(16).toString("hex")) {
  const hash = crypto.scryptSync(password, salt, 64).toString("hex");
  return `${salt}:${hash}`;
}

function verifyPassword(password, stored) {
  const [salt, hash] = stored.split(":");
  const check = crypto.scryptSync(password, salt, 64).toString("hex");
  return crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(check));
}

function parseCookies(req) {
  const header = req.headers.cookie || "";
  return Object.fromEntries(header.split(";").filter(Boolean).map(v => {
    const i = v.indexOf("=");
    return [v.slice(0, i).trim(), decodeURIComponent(v.slice(i + 1))];
  }));
}

function getCurrentUser(req) {
  const sid = parseCookies(req).sid;
  if (!sid || !sessions.has(sid)) return null;
  const session = sessions.get(sid);
  const user = readUsers().find(u => u.id === session.userId);
  return user || null;
}

function publicUser(u, viewer = null) {
  const favorites = Array.isArray(u.favorites) ? u.favorites : [];
  const viewerId = viewer ? viewer.id : null;
  const maySeeLocation = !!u.followMeEnabled && viewerId && favorites.includes(viewerId);

  return {
    id: u.id,
    username: u.username,
    displayName: u.displayName,
    status: u.status || "offline",
    lastSeen: u.lastSeen || null,
    followMeEnabled: !!u.followMeEnabled,
    favorite: viewer ? (Array.isArray(viewer.favorites) && viewer.favorites.includes(u.id)) : false,
    location: maySeeLocation ? (u.location || null) : null
  };
}

resetStatusesOnStartup();

app.post("/api/register", (req, res) => {
  const { username, displayName, password } = req.body || {};
  if (!username || !password) return res.status(400).json({ ok: false, error: "username og password kræves" });

  const cleanUsername = String(username).trim().toLowerCase();
  const users = readUsers();

  if (users.some(u => u.username === cleanUsername)) {
    return res.status(409).json({ ok: false, error: "Brugernavn findes allerede" });
  }

  const user = {
    id: crypto.randomUUID(),
    username: cleanUsername,
    displayName: displayName || cleanUsername,
    passwordHash: hashPassword(password),
    status: "offline",
    lastSeen: new Date().toISOString()
  };

  users.push(user);
  writeUsers(users);

  res.json({ ok: true, user: publicUser(user) });
});

app.post("/api/login", (req, res) => {
  const { username, password } = req.body || {};
  const cleanUsername = String(username || "").trim().toLowerCase();
  const users = readUsers();
  const user = users.find(u => u.username === cleanUsername);

  if (!user || !verifyPassword(password || "", user.passwordHash)) {
    return res.status(401).json({ ok: false, error: "Forkert brugernavn eller password" });
  }

  user.status = "online";
  user.lastSeen = new Date().toISOString();
  writeUsers(users);

  const sid = crypto.randomUUID();
  sessions.set(sid, { userId: user.id, createdAt: Date.now() });

  res.setHeader("Set-Cookie", `sid=${sid}; HttpOnly; SameSite=Lax; Path=/; Max-Age=86400`);
  res.json({ ok: true, user: publicUser(user) });
});

app.post("/api/logout", (req, res) => {
  const sid = parseCookies(req).sid;
  const user = getCurrentUser(req);

  if (sid) sessions.delete(sid);

  if (user) {
    const users = readUsers();
    const u = users.find(x => x.id === user.id);
    if (u) {
      u.status = "offline";
      u.lastSeen = new Date().toISOString();
      writeUsers(users);
    }
  }

  res.setHeader("Set-Cookie", "sid=; HttpOnly; SameSite=Lax; Path=/; Max-Age=0");
  res.json({ ok: true });
});

app.get("/api/me", (req, res) => {
  const user = getCurrentUser(req);
  if (!user) return res.status(401).json({ ok: false, error: "Ikke logget ind" });
  res.json({ ok: true, user: publicUser(user) });
});

app.get("/api/users", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const users = readUsers()
    .filter(u => u.id !== me.id)
    .map(u => publicUser(u, me));

  res.json({ ok: true, users });
});

app.post("/api/status", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const { status } = req.body || {};
  const allowed = ["online", "busy", "away", "offline"];
  if (!allowed.includes(status)) return res.status(400).json({ ok: false, error: "Ugyldig status" });

  const users = readUsers();
  const u = users.find(x => x.id === me.id);
  u.status = status;
  u.lastSeen = new Date().toISOString();
  writeUsers(users);

  res.json({ ok: true, user: publicUser(u) });
});




app.post("/api/favorites/add", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const { userId } = req.body || {};
  const users = readUsers();
  const u = users.find(x => x.id === me.id);
  const target = users.find(x => x.id === userId);

  if (!target) return res.status(404).json({ ok: false, error: "Bruger findes ikke" });

  if (!Array.isArray(u.favorites)) u.favorites = [];
  if (!u.favorites.includes(userId)) u.favorites.push(userId);

  writeUsers(users);
  res.json({ ok: true, user: publicUser(u) });
});

app.post("/api/favorites/remove", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const { userId } = req.body || {};
  const users = readUsers();
  const u = users.find(x => x.id === me.id);

  if (!Array.isArray(u.favorites)) u.favorites = [];
  u.favorites = u.favorites.filter(id => id !== userId);

  writeUsers(users);
  res.json({ ok: true, user: publicUser(u) });
});

app.post("/api/location/follow-me", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const { enabled } = req.body || {};
  const users = readUsers();
  const u = users.find(x => x.id === me.id);

  u.followMeEnabled = !!enabled;
  u.lastSeen = new Date().toISOString();

  if (!u.followMeEnabled) {
    u.location = null;
  }

  writeUsers(users);
  res.json({ ok: true, user: publicUser(u) });
});

app.post("/api/location/update", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const { latitude, longitude, accuracy } = req.body || {};
  const users = readUsers();
  const u = users.find(x => x.id === me.id);

  if (!u.followMeEnabled) {
    return res.status(403).json({ ok: false, error: "Følg mig er ikke aktiveret" });
  }

  u.location = {
    latitude,
    longitude,
    accuracy,
    updatedAt: new Date().toISOString()
  };
  u.lastSeen = new Date().toISOString();

  writeUsers(users);
  res.json({ ok: true, user: publicUser(u) });
});


app.post("/api/call/cancel", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const { callId } = req.body || {};
  const call = calls.get(callId);

  if (!call) return res.status(404).json({ ok: false, error: "Opkald findes ikke" });
  if (call.fromUserId !== me.id) return res.status(403).json({ ok: false, error: "Kun den kaldende part kan fortryde" });
  if (call.status !== "ringing") return res.status(400).json({ ok: false, error: "Opkald kan ikke fortrydes længere" });

  call.status = "cancelled";
  call.cancelledAt = new Date().toISOString();

  res.json({ ok: true, call });
});

app.post("/api/messages/send", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const { toUserId, message } = req.body || {};
  const text = String(message || "").trim();

  if (!toUserId || !text) return res.status(400).json({ ok: false, error: "Modtager og besked kræves" });

  const users = readUsers();
  const toUser = users.find(u => u.id === toUserId);
  if (!toUser) return res.status(404).json({ ok: false, error: "Modtager findes ikke" });

  const messages = readMessages();
  const msg = {
    id: crypto.randomUUID(),
    fromUserId: me.id,
    fromDisplayName: me.displayName,
    fromUsername: me.username,
    toUserId,
    message: text,
    createdAt: new Date().toISOString(),
    readAt: null
  };

  messages.push(msg);
  writeMessages(messages);

  res.json({ ok: true, message: msg });
});

app.get("/api/messages/inbox", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const messages = readMessages()
    .filter(m => m.toUserId === me.id)
    .sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));

  res.json({ ok: true, messages });
});

app.get("/api/messages/unread-count", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const count = readMessages().filter(m => m.toUserId === me.id && !m.readAt).length;
  res.json({ ok: true, count });
});

app.post("/api/messages/mark-read", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const messages = readMessages();
  let changed = false;

  messages.forEach(m => {
    if (m.toUserId === me.id && !m.readAt) {
      m.readAt = new Date().toISOString();
      changed = true;
    }
  });

  if (changed) writeMessages(messages);
  res.json({ ok: true });
});

app.post("/api/call/start", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const { toUserId } = req.body || {};
  const users = readUsers();
  const toUser = users.find(u => u.id === toUserId);

  if (!toUser) return res.status(404).json({ ok: false, error: "Bruger findes ikke" });

  const call = {
    id: crypto.randomUUID(),
    fromUserId: me.id,
    fromDisplayName: me.displayName,
    fromUsername: me.username,
    toUserId,
    status: "ringing",
    createdAt: new Date().toISOString()
  };

  calls.set(call.id, call);

  res.json({ ok: true, call });
});

app.get("/api/calls/incoming", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const incoming = Array.from(calls.values())
    .filter(c => c.toUserId === me.id && c.status === "ringing");

  res.json({ ok: true, calls: incoming });
});

app.get("/api/calls/outgoing", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const outgoing = Array.from(calls.values())
    .filter(c => c.fromUserId === me.id && ["ringing", "accepted", "rejected"].includes(c.status));

  res.json({ ok: true, calls: outgoing });
});

app.post("/api/call/answer", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const { callId } = req.body || {};
  const call = calls.get(callId);

  if (!call) return res.status(404).json({ ok: false, error: "Opkald findes ikke" });
  if (call.toUserId !== me.id) return res.status(403).json({ ok: false, error: "Ikke dit opkald" });

  call.status = "accepted";
  call.answeredAt = new Date().toISOString();

  res.json({ ok: true, call });
});

app.post("/api/call/reject", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const { callId } = req.body || {};
  const call = calls.get(callId);

  if (!call) return res.status(404).json({ ok: false, error: "Opkald findes ikke" });
  if (call.toUserId !== me.id && call.fromUserId !== me.id) {
    return res.status(403).json({ ok: false, error: "Ikke dit opkald" });
  }

  call.status = "rejected";
  call.rejectedAt = new Date().toISOString();

  res.json({ ok: true, call });
});


app.get("/api/call/:callId", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const call = calls.get(req.params.callId);
  if (!call) return res.status(404).json({ ok: false, error: "Opkald findes ikke" });

  if (call.fromUserId !== me.id && call.toUserId !== me.id) {
    return res.status(403).json({ ok: false, error: "Ikke dit opkald" });
  }

  res.json({
    ok: true,
    call,
    role: call.fromUserId === me.id ? "caller" : "callee"
  });
});

app.post("/api/call/:callId/peer", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const call = calls.get(req.params.callId);
  if (!call) return res.status(404).json({ ok: false, error: "Opkald findes ikke" });

  if (call.fromUserId !== me.id && call.toUserId !== me.id) {
    return res.status(403).json({ ok: false, error: "Ikke dit opkald" });
  }

  const { peerId } = req.body || {};
  if (!peerId) return res.status(400).json({ ok: false, error: "peerId mangler" });

  if (call.fromUserId === me.id) {
    call.fromPeerId = peerId;
  } else {
    call.toPeerId = peerId;
  }

  res.json({ ok: true, call });
});

app.post("/api/call/:callId/hangup", (req, res) => {
  const me = getCurrentUser(req);
  if (!me) return res.status(401).json({ ok: false, error: "Ikke logget ind" });

  const call = calls.get(req.params.callId);
  if (!call) return res.status(404).json({ ok: false, error: "Opkald findes ikke" });

  if (call.fromUserId !== me.id && call.toUserId !== me.id) {
    return res.status(403).json({ ok: false, error: "Ikke dit opkald" });
  }

  call.status = "ended";
  call.endedAt = new Date().toISOString();

  res.json({ ok: true, call });
});

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
