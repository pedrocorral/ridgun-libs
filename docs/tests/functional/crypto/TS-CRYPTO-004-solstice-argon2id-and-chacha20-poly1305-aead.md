---
id: TS-CRYPTO-004
title: Verify Solstice RGF-015 RFC 9106 Argon2id 5-arg API and RFC 8439 ChaCha20-Poly1305 AEAD
level: unit
covers: [FR-CRYPTO-004]
status: automated
automated_in: [src/test/ridgun/test crypto.ridgun]
---
# TS-CRYPTO-004 — Verify Solstice RGF-015 RFC 9106 Argon2id 5-arg API and RFC 8439 ChaCha20-Poly1305 AEAD

## Preconditions / fixtures
- Pure-Ridgun `crypto` and `argon2id` modules (`src/main/ridgun/lib/crypto.ridgun`, `src/main/ridgun/lib/argon2id.ridgun`).

## Steps / inputs
1. Call `argon2id_hash "correct horse battery staple" "0123456789abcdef" 64 2 1`, verify the returned PHC string starts with `$argon2id$v=19$m=64,t=2,p=1$`, verify `argon2id_verify "correct horse battery staple" phc == True`, `argon2id_verify "wrong" phc == False`, and verify RFC 7693 Blake2b / RFC 9106 Argon2id test vector derivation.
2. Encrypt the RFC 8439 §2.8.2 plaintext (`"Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."`) with the RFC 8439 32-byte key (`0x80..0x9f`), 12-byte nonce (`07 00 00 00 40 41 42 43 44 45 46 47`), and 12-byte AAD (`50 51 52 53 c0 c1 c2 c3 c4 c5 c6 c7`) using `aead_seal`, and compare the resulting ciphertext and 16-byte Poly1305 tag (`1a e1 0b 59 4f 09 e2 6a 7e 90 2e cb d0 60 06 91`) bit-for-bit.
3. Decrypt the sealed ciphertext with `aead_open` and verify `(0, plaintext)`; flip one byte of the tag, one byte of the AAD, or one byte of the nonce and verify `aead_open` returns `(-12, "")` (`AUTH_FAILED`); pass an invalid 16-byte key and verify `(-7, "")` (`INVALID`).
4. `test chacha20 key stream on every length`: the key streams of every length from 0 to 700 bytes (counters 0 to 4), and of 4 064, 4 096, 65 535, 1 048 576, 1 048 577, 1 048 640 and 2 100 000 bytes, against Python's `cryptography` ChaCha20. Every length from 0 to 400 is also compared byte by byte with the same blocks made one call each.
5. `test aead on every length`: the sealed messages of every length from 0 to 1100, 2030 to 2070, 2040 to 2600 and 4000 to 4130 bytes (with 8 and with 32 lanes of Poly1305, every count of blocks left over), each with its own nonce and 0 to 63 bytes of additional data, and of 4 064, 4 096, 65 535, 65 536 bytes, one megabyte, one megabyte and a byte, one megabyte and a block and 2 100 000 bytes, against Python's ChaCha20Poly1305. Long additional data (700, 1 000 and 5 000 bytes) too. For every length from 0 to 1100 and 4060 to 4100: the box is the cipher of `chacha20 bitxor` plus the tag of `poly1305 aead mac` made from the public parts, it opens to the message, and the message is unchanged.
6. `test aead refuses every change`: for messages of 0, 1, 15, 16, 17, 63, 64, 65, 200, 600 and 1 111 bytes, every single bit of the box, of the key, of the nonce and of the additional data is changed in turn, and each open must give `(-12, "")`. A box cut to each of its first 0 to 115 bytes, a box one byte longer at either end, other additional data, another nonce and another key are refused. Keys of 0 to 40 bytes that are not 32 and nonces of 0 to 24 bytes that are not 12 seal nothing and open with `-7`. The checker is checked first: the untouched box must count as accepted.
7. The tests of steps 4 to 6 were checked against thirteen faults planted in a copy of `crypto` (a cut one byte short or long, a wrong limb mask in Poly1305, a wrong step of the lanes, a skipped last lane step, a tag compared on 15 bytes, a key stream that continues one block late past one megabyte, and others): the suite stops on every one of them.

## Expected results (map to acceptance criteria)
- AC1 → `argon2id_hash` (5-arg) and `argon2id_verify` (`pwd, phc`) produce and verify RFC 9106 PHC strings accurately.
- AC2 → `aead_seal` matches the RFC 8439 §2.8.2 ChaCha20-Poly1305 ciphertext and tag bit-for-bit.
- AC3 → `aead_open` returns `(0, pt)` on valid inputs, `(-12, "")` on any authentication failure, and `(-7, "")` on invalid key/nonce/ciphertext length.
- AC2 → the key stream and the sealed message are Python's for every length tested, in both modes of `stable test` (steps 4 and 5).
- AC3 → no change of one bit, no cut and no wrong size is accepted (step 6).

## Not covered here (to avoid duplication)
- see `TS-CRYPTO-003` for `RGF-019` byte/bit ops, `sha256_bytes`, `hmac_sha256`, and `pbkdf2_hmac_sha256`.
