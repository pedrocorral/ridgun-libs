---
id: TS-CRYPTO-004
title: Verify Solstice RGF-015 RFC 9106 Argon2id 5-arg API and RFC 8439 ChaCha20-Poly1305 AEAD
level: unit
covers: [FR-CRYPTO-004]
status: automated
automated_in: [src/test/ridgun/test crypto.rg]
---
# TS-CRYPTO-004 — Verify Solstice RGF-015 RFC 9106 Argon2id 5-arg API and RFC 8439 ChaCha20-Poly1305 AEAD

## Preconditions / fixtures
- Pure-Ridgun `crypto` and `argon2id` modules (`src/main/ridgun/lib/crypto.rg`, `src/main/ridgun/lib/argon2id.rg`).

## Steps / inputs
1. Call `argon2id_hash "correct horse battery staple" "0123456789abcdef" 64 2 1`, verify the returned PHC string starts with `$argon2id$v=19$m=64,t=2,p=1$`, verify `argon2id_verify "correct horse battery staple" phc == True`, `argon2id_verify "wrong" phc == False`, and verify RFC 7693 Blake2b / RFC 9106 Argon2id test vector derivation.
2. Encrypt the RFC 8439 §2.8.2 plaintext (`"Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."`) with the RFC 8439 32-byte key (`0x80..0x9f`), 12-byte nonce (`07 00 00 00 40 41 42 43 44 45 46 47`), and 12-byte AAD (`50 51 52 53 c0 c1 c2 c3 c4 c5 c6 c7`) using `aead_seal`, and compare the resulting ciphertext and 16-byte Poly1305 tag (`1a e1 0b 59 4f 09 e2 6a 7e 90 2e cb d0 60 06 91`) bit-for-bit.
3. Decrypt the sealed ciphertext with `aead_open` and verify `(0, plaintext)`; flip one byte of the tag, one byte of the AAD, or one byte of the nonce and verify `aead_open` returns `(-12, "")` (`AUTH_FAILED`); pass an invalid 16-byte key and verify `(-7, "")` (`INVALID`).

## Expected results (map to acceptance criteria)
- AC1 → `argon2id_hash` (5-arg) and `argon2id_verify` (`pwd, phc`) produce and verify RFC 9106 PHC strings accurately.
- AC2 → `aead_seal` matches the RFC 8439 §2.8.2 ChaCha20-Poly1305 ciphertext and tag bit-for-bit.
- AC3 → `aead_open` returns `(0, pt)` on valid inputs, `(-12, "")` on any authentication failure, and `(-7, "")` on invalid key/nonce/ciphertext length.

## Not covered here (to avoid duplication)
- see `TS-CRYPTO-003` for `RGF-019` byte/bit ops, `sha256_bytes`, `hmac_sha256`, and `pbkdf2_hmac_sha256`.
