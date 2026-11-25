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
4. `test sha256 and pbkdf2 on processor operations`: the digests of every length from 0 to 300 bytes, from 500 to 580, around 4 KB and of 70 000 bytes, chained and compared with Python's value; one million `a` (FIPS 180-4); `sha256 raw`, `sha256 str`, `sha256 digest` of a tensor; `sha256 file` of a 3-byte file, of a 200 000-byte file, of a missing file and of a directory; HMAC-SHA-256 on RFC 4231 test cases 2 and 6 and on 401 messages with keys of 0 to 149 bytes, chained and compared with Python's value.
5. The same test: PBKDF2-HMAC-SHA-256 on the two vectors of RFC 7914 §11 and on four cases from Python (4 096 iterations; a 65-byte password with a 55-byte salt; a 200-byte password with a 120-byte salt and 100 bytes of output; empty password and salt).
6. Both tests run a second time with `RIDGUN_CPU=2`.
7. `test processor operations one by one`: `sha256 schedule`, `sha256 rounds`, `aes round` and `aes last round` each called alone: words 16 to 19 and the first four rounds of the block of `abc` (FIPS 180-4), and round 1 and the last round of the example of FIPS 197 Appendix B. The values given are unchanged after the call.
8. `test aes gcm on every length`: AES-128-GCM and AES-256-GCM, the sealed messages of every length from 0 to 600 bytes and of 4 064, 4 096, 65 535 and 1 048 577 bytes, and 300 bytes with 5 000 bytes of additional data, against Python's AESGCM. Every length from 0 to 300 opens to its message. For messages of 0, 15, 16, 17, 33 and 200 bytes, every single bit of the box and of the additional data is changed in turn and each open must be refused with no text.

## Expected results (map to acceptance criteria)
- AC1 → step 1. AC2 → step 2. AC3 → steps 2 and 3.
- AC4 → step 6 gives the same results as the first run for steps 1 to 5.
- AC5 → step 4.

## Not covered here (to avoid duplication)
- AES-128-GCM test cases 1 to 4 and the TLS 1.3 records (`TS-CRYPTO-006`).
- SHA-256, HMAC and PBKDF2 of short inputs (`TS-CRYPTO-003`).
