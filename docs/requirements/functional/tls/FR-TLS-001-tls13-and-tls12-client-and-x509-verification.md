---
id: FR-TLS-001
title: Provide RFC 8446 TLS 1.3 and RFC 5246 TLS 1.2 (ECDHE + AEAD) Client Protocol and X.509 Certificate Verification Library
type: functional
status: implemented
priority: must
domain: TLS
depends_on: [FR-CRYPTO-006, FR-SOCK-004]
related: [API-TLS-001, DM-Tls, VUL-AUTHN-001, VUL-INPUT-001]
tests: [TS-TLS-001]
---
# FR-TLS-001 — Provide RFC 8446 TLS 1.3 and RFC 5246 TLS 1.2 (ECDHE + AEAD) Client Protocol and X.509 Certificate Verification Library

## Statement
The `tls` lib (`src/main/ridgun/lib/tls.ridgun`) SHALL provide a 100% pure-Ridgun TLS client implementation supporting RFC 8446 TLS 1.3 (`TLS_AES_128_GCM_SHA256`, `TLS_CHACHA20_POLY1305_SHA256`) and RFC 5246 TLS 1.2 with ECDHE and AEAD cipher suites (`ECDHE-ECDSA` and `ECDHE-RSA` with `AES-128-GCM` or `ChaCha20-Poly1305`), X25519 and P-256 key exchange, mandatory SNI, optional ALPN, and unconditional X.509 certificate chain and RFC 6125 `subjectAltName` hostname verification against `/etc/ssl/certs/ca-certificates.crt` (or a configurable root store path via `tls with roots`).

## Rationale
Solstice (`ridgun.com`) requires outbound TLS connections in pure Ridgun for SMTP email verification and password reset delivery (`FR-MAIL-001`), as well as future outbound HTTPS and encrypted PostgreSQL connections, without invoking external binaries or libraries.

## Acceptance criteria
- AC1: Given the RFC 8448 §3 TLS 1.3 1-RTT example trace, when the TLS 1.3 key schedule, transcript hashes, handshake record encryption/decryption (`TLS_AES_128_GCM_SHA256`), `Finished` MAC verification, and application-data encryption/decryption are executed, then every intermediate secret, key, IV, and record matches RFC 8448 §3 bit-for-bit, and the RFC 8448 `CertificateVerify` (signed with a 1024-bit RSA key) is rejected by the 2048-bit RSA floor of `FR-CRYPTO-006` AC5 (`ADR-0005`).
- AC2: Given an open `Socket` connected to a live TLS server (`www.debian.org:443` or `smtp.gmail.com:465`) or a local TLS server, when `tls connect sock host (tls defaults)`, `tls send`, `tls recv`, and `tls close` are called, then `tls connect` completes the TLS handshake, validates the full certificate chain against `/etc/ssl/certs/ca-certificates.crt` (or custom roots via `tls with roots`), verifies the server's `subjectAltName` and `CertificateVerify` / `ServerKeyExchange` + `Finished`, exchanges encrypted application data, and closes cleanly.
- AC3: Given connections to invalid endpoints (`expired.badssl.com`, `wrong.host.badssl.com`, `self-signed.badssl.com`, `untrusted-root.badssl.com`, `tls-v1-0.badssl.com`, or local equivalents), when `tls connect` is called, then it rejects every invalid case and returns a typed `TlsErr` distinguishing `TlsCertExpired`, `TlsHostnameMismatch`, `TlsInvalidChain`, `TlsUnsupportedVersion`, `TlsServerAlert`, and `TlsTimeout`.
- AC4: Given any `TlsConfig`, `tls.ridgun` SHALL NOT expose any flag or code path that skips certificate chain, expiration, signature, or `subjectAltName` hostname verification (`tls with roots` only substitutes the trusted root CA PEM bundle for tests).
