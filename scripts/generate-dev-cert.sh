#!/usr/bin/env sh
set -eu

mkdir -p cert

openssl req -x509 -newkey rsa:4096 \
  -keyout cert/key.pem \
  -out cert/cert.pem \
  -sha256 \
  -days 365 \
  -nodes \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

echo "Development certificate created in cert/."
echo "The files are ignored by git and must not be committed."
