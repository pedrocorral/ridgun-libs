---
id: FR-CRYPTO-006
title: Provide SHA-384, HKDF, X25519, AES-128-GCM, ECDHE P-256, ECDSA P-256/P-384, RSA PKCS#1 v1.5/PSS verification, and ASN.1 DER / X.509 / PEM parsing
type: functional
status: implemented
priority: must
domain: CRYPTO
depends_on: [FR-CRYPTO-003, FR-CRYPTO-004, FR-CRYPTO-005]
related: [ADR-0002, API-CRYPTO-001, DM-Argon2, VUL-AUTHN-001, VUL-INPUT-001]
tests: [TS-CRYPTO-006]
---
# FR-CRYPTO-006 — Provide SHA-384, HKDF, X25519, AES-128-GCM, ECDHE P-256, ECDSA P-256/P-384, RSA PKCS#1 v1.5/PSS verification, and ASN.1 DER / X.509 / PEM parsing

## Statement
The `crypto` lib (`src/main/ridgun/lib/crypto.rg`) SHALL provide 100% pure-Ridgun implementations of FIPS 180-4 SHA-384 (`sha384 bytes`, `sha384 hex`) and HMAC-SHA-384 (`hmac sha384`), RFC 5869 HKDF (`hkdf extract`, `hkdf expand`, `hkdf extract sha384`, `hkdf expand sha384`, `hkdf expand label`, `derive secret`), RFC 7748 X25519 key exchange (`x25519`, `x25519 public key`), FIPS 197 / NIST SP 800-38D AES-128-GCM (`aes128 block`, `aes128 gcm seal`, `aes128 gcm open`), FIPS 186-4 ECDHE P-256 (`p256 public key`, `p256 ecdh`) and ECDSA P-256 / P-384 signature verification (`ecdsa p256 verify`, `ecdsa p256 verify sha256`, `ecdsa p384 verify`, `ecdsa p384 verify sha384`), RFC 8017 RSA PKCS#1 v1.5 and RSA-PSS signature verification for 2048-bit and larger keys (`rsa mod exp`, `rsa verify pkcs1`, `rsa verify pss`), and ASN.1 DER, PEM, and RFC 5280 / RFC 6125 X.509 certificate parsing and verification (`pem decode blocks`, `asn1 parse tlv`, `x509 parse cert`, `x509 match hostname`, `x509 verify cert sig`).

## Rationale
The `tls` client lib (`FR-TLS-001`), the `mail` SMTP client lib (`FR-MAIL-001`), and future outbound HTTPS, PostgreSQL TLS, and JWT/PKI consumers need standard TLS 1.3 / 1.2 cryptographic primitives and X.509 certificate chain verification in `crypto` as a reusable leaf lib without external dependencies.

## Acceptance criteria
- AC1: Given an arbitrary byte string `msg` and key `k`, when `sha384 bytes msg`, `sha384 hex msg`, `hmac sha384 k msg`, `hkdf extract salt ikm`, `hkdf expand prk info len`, and `hkdf expand label secret label context len` are called, then they produce digests and derived keys matching FIPS 180-4 SHA-384, RFC 4231 HMAC-SHA-384, RFC 5869 Appendix A HKDF-SHA256, and RFC 8448 TLS 1.3 key-schedule test vectors bit-for-bit.
- AC2: Given 32-byte scalar `k` and 32-byte u-coordinate `u`, when `x25519 k u` and `x25519 public key k` are called, then they execute the RFC 7748 constant-time Montgomery ladder with scalar clamping (`k[0] &= 248`, `k[31] = (k[31] & 127) | 64`) and high-bit masking (`u[31] &= 127`), match the RFC 7748 §5.2 and §6.1 test vectors bit-for-bit, and return `""` if input lengths are not 32 bytes or if the shared secret is the all-zero low-order output.
- AC3: Given a 16-byte key, 12-byte nonce, `aad`, and `plaintext`, when `aes128 gcm seal key nonce aad plaintext` and `aes128 gcm open key nonce aad ct_and_tag` are called, then `aes128 gcm seal` returns `ciphertext || 16-byte tag` matching NIST SP 800-38D and RFC 8448 AES-128-GCM test vectors, and `aes128 gcm open` verifies the 16-byte GHASH authentication tag in constant time (`ct equal`), returning `(0, plaintext)` on valid tag, `(-12, "")` on tag mismatch without releasing unauthenticated plaintext, and `(-7, "")` on invalid key/nonce/ciphertext lengths.
- AC4: Given P-256 (`secp256r1`) and P-384 (`secp384r1`) public keys, scalars, and signatures (in either raw `r || s` or ASN.1 DER `SEQUENCE { INTEGER r, INTEGER s }` format), when `p256 public key`, `p256 ecdh`, `ecdsa p256 verify`, and `ecdsa p384 verify` are called, then `p256 ecdh` validates that the peer uncompressed point (`0x04 || X || Y`, 65 bytes) lies on P-256 before computing the shared secret $X$, and `ecdsa p256 verify` / `ecdsa p384 verify` accept valid FIPS 186-4 / RFC 6979 signatures and reject corrupted messages, out-of-range $(r, s)$, or off-curve points.
- AC5: Given an RSA public key `(n_be, e_be)` with modulus length $\ge 256$ bytes (2048 bits or more), a hash algorithm (`"sha256"`, `"sha384"`, or `"sha512"`), `msg`, and `sig`, when `rsa verify pkcs1` and `rsa verify pss` are called, then they verify RFC 8017 PKCS#1 v1.5 and RSA-PSS (MGF1) signatures, reject any key smaller than 2048 bits (`str len n_be < 256`), and reject any modified message or signature byte.
- AC6: Given PEM or ASN.1 DER X.509 v3 certificates, when `pem decode blocks`, `x509 parse cert`, `x509 match hostname`, and `x509 verify cert sig` are called, then they parse `tbs_der`, `issuer_der`, `subject_der`, `not_before_at`, `not_after_at`, `subjectPublicKeyInfo` (RSA, ECDSA P-256/P-384, Ed25519), `basicConstraints` (`is_ca`), `keyUsage`, `extKeyUsage`, and `subjectAltName` `dNSName` entries, enforce RFC 6125 wildcard matching only in the leftmost label (`*.example.com` matches `a.example.com` but not `b.a.example.com` or `example.com`), and verify certificate signatures across RSA PKCS#1 v1.5, RSA-PSS, ECDSA P-256/P-384, and Ed25519.

## Constraints & edge cases
- All operations touching secret keys, scalars, or authentication tags must execute in constant time without secret-dependent branches.
- Malformed ASN.1 DER lengths (indefinite lengths, truncated TLVs, negative or overflowing offsets) must return `False` without crashing.
