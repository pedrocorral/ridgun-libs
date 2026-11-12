---
id: TS-TLS-001
title: Verify RFC 8448 TLS 1.3 Vectors, Live TLS Handshakes, X.509 Chain Verification, and badssl.com Rejection Cases
status: automated
level: functional
domain: TLS
covers: [FR-TLS-001, API-TLS-001, DM-Tls]
automated_in: [src/test/ridgun/test tls.ridgun]
---
# TS-TLS-001 — Verify RFC 8448 TLS 1.3 Vectors, Live TLS Handshakes, X.509 Chain Verification, and badssl.com Rejection Cases

## Scope
Verifies `src/main/ridgun/lib/tls.ridgun` across RFC 8448 §3 TLS 1.3 1-RTT handshake and application-data test vectors, live TLS connections (`www.debian.org:443` / `smtp.gmail.com:465`) and local TLS test servers, and rejection of `expired.badssl.com`, `wrong.host.badssl.com`, `self-signed.badssl.com`, `untrusted-root.badssl.com`, and `tls-v1-0.badssl.com` with typed `TlsError` reasons.

## Test Cases
1. **RFC 8448 §3 TLS 1.3 1-RTT Handshake & Record Vectors (`AC1`)**:
   - Verifies exact X25519 shared secret, `handshake_secret`, `c_hs_traffic`, `s_hs_traffic`, `EncryptedExtensions`, `Certificate`, `CertificateVerify` (1024-bit RSA-PSS SHA-256: must be rejected by the 2048-bit floor, `ADR-0005`), `Finished`, `master_secret`, `c_ap_traffic`, `s_ap_traffic`, and encrypted application-data records.
2. **Live and Local Server TLS Handshake & Encrypted I/O (`AC2`)**:
   - Verifies `tls connect`, `tls send`, `tls recv`, and `tls close` against a real server (`www.debian.org:443` and `smtp.gmail.com:465`) using `/etc/ssl/certs/ca-certificates.crt` as well as a local test server using `tls with roots`.
3. **Rejection of Invalid Certificates, Hostnames, and Old Protocol Versions (`AC3`, `AC4`)**:
   - Verifies that `expired.`, `wrong.host.`, `self-signed.`, `untrusted-root.`, and `tls-v1-0.` fail with `TlsCertExpired`, `TlsHostnameMismatch`, `TlsInvalidChain`, and `TlsUnsupportedVersion` / `TlsServerAlert`, and that no configuration option bypasses verification.
