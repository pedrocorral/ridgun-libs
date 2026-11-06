#!/bin/sh
# Throwaway TLS test PKI for `test tls.rg` and `test mail.rg` (TS-TLS-001, TS-MAIL-001).
# Keys are generated at test time and never committed.
# Usage: gen-certs.sh <dir>
set -eu
d="$1"
mkdir -p "$d"
cd "$d"
q() { "$@" >/dev/null 2>&1; }

# Root CA (RSA-2048) -> intermediate CA (P-256) -> ECDSA P-256 and RSA-2048 leaves for "localhost".
q openssl req -x509 -newkey rsa:2048 -nodes -keyout ca.key -out ca.pem -days 3 -subj "/CN=Ridgun TLS Test Root" \
  -addext "basicConstraints=critical,CA:TRUE" -addext "keyUsage=critical,keyCertSign,cRLSign"
q openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -keyout int.key -out int.csr -subj "/CN=Ridgun TLS Test Intermediate"
printf 'basicConstraints=critical,CA:TRUE\nkeyUsage=critical,keyCertSign,cRLSign\n' > int.ext
q openssl x509 -req -in int.csr -CA ca.pem -CAkey ca.key -CAcreateserial -days 3 -sha256 -extfile int.ext -out int.pem

printf 'basicConstraints=CA:FALSE\nsubjectAltName=DNS:localhost\nextendedKeyUsage=serverAuth\nkeyUsage=critical,digitalSignature\n' > leaf.ext
q openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -keyout ec.key -out ec.csr -subj "/CN=localhost"
q openssl x509 -req -in ec.csr -CA int.pem -CAkey int.key -CAcreateserial -days 3 -sha256 -extfile leaf.ext -out ec.pem
q openssl req -new -newkey rsa:2048 -nodes -keyout rsa.key -out rsa.csr -subj "/CN=localhost"
q openssl x509 -req -in rsa.csr -CA int.pem -CAkey int.key -CAcreateserial -days 3 -sha256 -extfile leaf.ext -out rsa.pem

# A self-signed "localhost" leaf and an unrelated root CA.
q openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -keyout self.key -out self.pem -days 3 -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost"
q openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -keyout other.key -out other.pem -days 3 -subj "/CN=Unrelated Test Root" \
  -addext "basicConstraints=critical,CA:TRUE"

# Ed25519 "localhost" certificate for the Ridgun TLS 1.3 test server in `test mail.rg`;
# ed.seed.hex is the 32-byte private seed (last 32 bytes of the PKCS#8 DER) in hex.
q openssl genpkey -algorithm ED25519 -out ed.key
q openssl req -x509 -new -key ed.key -out ed.pem -days 3 -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost"
openssl pkey -in ed.key -outform DER 2>/dev/null | tail -c 32 | od -An -v -tx1 | tr -d ' \n' > ed.seed.hex

echo ok > done
