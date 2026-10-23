---
id: TS-CRYPTO-003
title: Verify raw byte manipulation, 32-bit bitwise operations, SHA-256, HMAC-SHA-256, constant-time equality, and PBKDF2-HMAC-SHA-256
level: unit
covers: [FR-CRYPTO-003, API-CRYPTO-001]
status: automated
automated_in: [src/test/ridgun/test crypto.rg]
---
# TS-CRYPTO-003 — Verify raw byte manipulation, 32-bit bitwise operations, SHA-256, HMAC-SHA-256, constant-time equality, and PBKDF2-HMAC-SHA-256

## Preconditions / fixtures
- Pure-Ridgun `crypto` module (`src/main/ridgun/lib/crypto.rg`).

## Steps / inputs
1. Test `byte_str` for `0`, `127`, `128`, `255` (`str_len == 1`), `bytes_to_list (bytes_from_list [0, 1, 127, 128, 255])`, and 32-bit bitwise operations `band`, `bor`, `bxor`, `shl`, `shr` against the `RGF-019` test vectors (`band 4294967295 255 == 255`, `bxor 305419896 4294967295 == 3989547399`, `shl 1 31 == 2147483648`, `shl 1 32 == 0`, `shr 2147483648 31 == 1`).
2. Test `sha256_bytes "abc"` (`ba7816bf...`, 32 raw bytes), `sha256_hex "abc"`, `hmac_sha256 "Jefe" "what do ya want for nothing?"` (RFC 4231 vector `5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843`), and `ct_equal` on equal, same-length differing, and different-length strings.
3. Test `pbkdf2_hmac_sha256 "password" "salt" 1 32` (`120fb6cf...`) and `pbkdf2_hmac_sha256 "password" "salt" 4096 32` (`c5e478d5...`) against RFC 6070 vectors.

## Expected results (map to acceptance criteria)
- AC1 → All 256 byte values have length `1` and round-trip cleanly; all `RGF-019` 32-bit bitwise identities match.
- AC2 → `sha256_bytes`, `sha256_hex`, `hmac_sha256`, and `ct_equal` match FIPS 180-4 and RFC 4231 test vectors.
- AC3 → `pbkdf2_hmac_sha256` matches RFC 6070 test vectors for `c=1` and `c=4096`.

## Not covered here (to avoid duplication)
- see `TS-CRYPTO-004` for 5-arg `argon2id_hash`/`argon2id_verify` and RFC 8439 ChaCha20-Poly1305 `aead_seal`/`aead_open`.
