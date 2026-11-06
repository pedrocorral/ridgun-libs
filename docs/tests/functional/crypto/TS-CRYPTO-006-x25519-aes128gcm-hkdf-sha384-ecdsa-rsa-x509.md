---
id: TS-CRYPTO-006
title: Verify SHA-384, HKDF, X25519, AES-128-GCM, ECDHE P-256, ECDSA P-256/P-384, RSA PKCS#1 v1.5/PSS, and ASN.1 DER / X.509 / PEM parsing
status: automated
level: unit
domain: CRYPTO
covers: [FR-CRYPTO-006, API-CRYPTO-001]
automated_in: [src/test/ridgun/test crypto.rg]
---
# TS-CRYPTO-006 — Verify SHA-384, HKDF, X25519, AES-128-GCM, ECDHE P-256, ECDSA P-256/P-384, RSA PKCS#1 v1.5/PSS, and ASN.1 DER / X.509 / PEM parsing

## Scope
Verifies the `FR-CRYPTO-006` additions in `src/main/ridgun/lib/crypto.rg`: FIPS 180-4 SHA-384 & HMAC-SHA-384, RFC 5869 HKDF & TLS 1.3 `HKDF-Expand-Label`, RFC 7748 X25519, NIST SP 800-38D AES-128-GCM, FIPS 186-4 ECDHE P-256 and ECDSA P-256/P-384 verification, RFC 8017 RSA PKCS#1 v1.5 and RSA-PSS verification, and ASN.1 DER / PEM / X.509 v3 certificate parsing, RFC 6125 `subjectAltName` hostname matching, and signature verification.

## Test Cases
1. **SHA-384, HMAC-SHA-384, and HKDF (`AC1`)**:
   - Verifies FIPS 180-4 SHA-384 vectors (`""`, `"abc"`), RFC 4231 HMAC-SHA-384, RFC 5869 Appendix A.1 HKDF-SHA256, and RFC 8448 TLS 1.3 `hkdf expand label` / `derive secret`.
2. **X25519 Key Exchange (`AC2`)**:
   - Verifies RFC 7748 §6.1 Alice/Bob keypair and shared secret derivation and RFC 7748 §5.2 iterative test vector, plus rejection of wrong input lengths and all-zero low-order shared secrets.
3. **AES-128-GCM Authenticated Encryption (`AC3`)**:
   - Verifies FIPS 197 AES-128 block encryption, NIST SP 800-38D Test Case 1/2/3/4 and RFC 8448 TLS 1.3 record encryption/decryption, and constant-time `-12` rejection on tampered ciphertext, AAD, or tag.
4. **ECDHE P-256 and ECDSA P-256 / P-384 Verification (`AC4`)**:
   - Verifies P-256 public key derivation, ECDHE shared secret symmetry, off-curve peer point rejection, and ECDSA P-256 (`SHA-256`) and P-384 (`SHA-384`) signature verification on raw and ASN.1 DER signatures (accepting valid vectors and rejecting modified messages or signatures).
5. **RSA PKCS#1 v1.5 and RSA-PSS Verification (`AC5`)**:
   - Verifies 2048-bit RSA PKCS#1 v1.5 (`SHA-256`, `SHA-384`, `SHA-512`) and generated 2048-bit RSA-PSS (`SHA-256`, `SHA-384`) signatures (the RFC 8448 key is 1024-bit and must be rejected, `ADR-0005`), rejecting keys `< 2048` bits and tampered messages/signatures.
6. **ASN.1 DER, PEM, X.509 Certificate Parsing & RFC 6125 Hostname Matching (`AC6`)**:
   - Verifies PEM decoding, X.509 certificate parsing, signature verification (`x509 verify cert sig`), and RFC 6125 `subjectAltName` wildcard matching (`*.example.com` matches `sub.example.com`, rejects `a.b.example.com` and `example.com`).
