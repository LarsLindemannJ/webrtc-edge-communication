# Arkitektur

## Overblik

Løsningen består af en operator, en klient og en Node.js/Express-server med PeerJS signaling.

```text
+-------------+          HTTPS/HTTP           +----------------+
|  Operator   | <---------------------------> | Node/Express   |
| operator UI |                               | PeerJS server  |
+-------------+                               +----------------+
       ^                                             ^
       |                                             |
       |              WebRTC / PeerJS                |
       v                                             v
+-------------+          HTTPS/HTTP           +----------------+
|   Klient    | <---------------------------> | Static files   |
| client UI   |                               | API endpoints  |
+-------------+                               +----------------+
```

## Flow

1. Operator åbner `operator.html`.
2. Operator genererer et klientlink eller QR-kode.
3. Klient åbner `client.html`.
4. Operator og klient registreres via PeerJS signaling.
5. WebRTC-forbindelsen etableres.
6. Lyd, video, chat og data udveksles mellem peers.

## Komponenter

### Operator

Operatoren fungerer som betjeningsinterface og supportside.

### Klient

Klienten bruges af den person eller enhed, der skal modtage support eller kommunikere med operatoren.

### Server

Serveren hoster statiske filer og håndterer PeerJS signaling.
