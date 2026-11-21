---
id: TS-CRYPTO-007
title: Verify AES-256, AES-256-GCM and that SHA-256, PBKDF2 and AES agree on the processor instructions and on the portable definitions
status: automated
level: unit
domain: CRYPTO
covers: [FR-CRYPTO-007, API-CRYPTO-001]
automated_in: [src/test/ridgun/test crypto.ridgun]
---
# TS-CRYPTO-007 — Verify AES-256, AES-256-GCM and that SHA-256, PBKDF2 and AES agree on the processor instructions and on the portable definitions

## Preconditions / fixtures
- `stable test` of ridgunc 1.0.51 or later: it runs each suite twice when a lib has a processor operation with a variant, the second time with `RIDGUN_CPU=2`.
- Reference values computed with Python (`hashlib.pbkdf2_hmac`, `cryptography` AESGCM).

## Steps / inputs
1. `test aes on processor operations`: `aes128 block` and `aes256 block` on FIPS 197 C.1 and C.3; `aes256 block` of zeros; wrong key and block lengths.
2. The same test: `aes256 gcm seal` on GCM test cases 13, 14 and 16; `aes256 gcm open` of the result; other associated data; one changed byte; a 31-byte key; an 11-byte nonce.
3. The same test: 70 000 bytes sealed with AES-128-GCM and AES-256-GCM, the last 32 bytes compared with Python's result, and both opened again.
4. `test sha256 and pbkdf2 on processor operations`: `sha256 cpu bytes` against the SHA-256 of the runtime for every length from 0 to 300, from 500 to 580, around 4 KB and for 70 000 bytes; `sha256 bytes` at 511 and 512 bytes; one million `a` (FIPS 180-4).
5. The same test: PBKDF2-HMAC-SHA-256 on the two vectors of RFC 7914 §11 and on four cases from Python (4 096 iterations; a 65-byte password with a 55-byte salt; a 200-byte password with a 120-byte salt and 100 bytes of output; empty password and salt).
6. Both tests run a second time with `RIDGUN_CPU=2`.

## Expected results (map to acceptance criteria)
- AC1 → step 1. AC2 → step 2. AC3 → steps 2 and 3.
- AC4 → step 6 gives the same results as the first run for steps 1 to 5.
- AC5 → step 4.

## Not covered here (to avoid duplication)
- AES-128-GCM test cases 1 to 4 and the TLS 1.3 records (`TS-CRYPTO-006`).
- SHA-256, HMAC and PBKDF2 of short inputs (`TS-CRYPTO-003`).
