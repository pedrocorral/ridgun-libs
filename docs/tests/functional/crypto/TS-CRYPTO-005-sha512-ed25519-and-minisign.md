---
id: TS-CRYPTO-005
title: Verify FIPS 180-4 SHA-512, RFC 8032 §5.1 pure Ed25519 test vectors and negative cases, and Minisign format round-trips
level: unit
covers: [FR-CRYPTO-005]
status: automated
automated_in: [src/test/ridgun/test crypto.rg]
---
# TS-CRYPTO-005 — Verify FIPS 180-4 SHA-512, RFC 8032 §5.1 pure Ed25519 test vectors and negative cases, and Minisign format round-trips

## Preconditions / fixtures
- Pure-Ridgun `crypto` library (`src/main/ridgun/lib/crypto.rg`).

## Steps / inputs
1. Call `sha512 hex` and `sha512 bytes` on the FIPS 180-4 test vectors: `""`, `"abc"`, `"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"` (448 bits), `"abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu"` (896 bits), and $1\,000\,000 \times \text{"a"}$; verify all 64-byte raw and 128-char hex digests match FIPS 180-4 bit-for-bit.
2. Call `ed25519 public key`, `ed25519 sign`, and `ed25519 verify` on all five RFC 8032 §7.1 test vectors (TEST 1: empty message `""`; TEST 2: 1-byte `0x72`; TEST 3: 2-byte `0xaf82`; TEST 4: 1023-byte message; TEST 5: 20-byte `SHA-1("abc")`), verifying that both the derived 32-byte public keys and the 64-byte signatures match RFC 8032 §7.1 bit-for-bit and `ed25519 verify` returns `True`.
3. Exercise negative Ed25519 cases on `ed25519 verify`: flip 1 bit in the message, flip 1 bit in `R` or `S` of the signature, flip 1 bit in the public key, construct a signature with $S = L$ and $S = L + 1$ (malleability check), pass a `y` coordinate without a valid curve square root, and pass wrong lengths (`31` or `33` B key, `63` or `65` B signature); verify `ed25519 verify` returns `False` on every negative case without crashing.
4. Encode a Minisign public key (`minisign encode pubkey`), sign a `SHA256SUMS` payload with a trusted comment (`minisign sign`), verify with `minisign verify`, extract the trusted comment (`minisign trusted comment`), and verify that tampering with either the payload or the trusted comment causes `minisign verify` to return `False`.

## Expected results (map to acceptance criteria)
- AC1 → `sha512 bytes` and `sha512 hex` match all FIPS 180-4 test vectors including $1\,000\,000 \times \text{"a"}$.
- AC2 → `ed25519 public key` and `ed25519 sign` match all five RFC 8032 §7.1 test vectors bit-for-bit.
- AC3 → `ed25519 verify` returns `True` on valid signatures and `False` on bit flips, $S \ge L$, invalid curve points, or invalid lengths.
- AC4 → `minisign encode pubkey`, `minisign decode pubkey`, `minisign sign`, and `minisign verify` round-trip and reject any payload or trusted-comment modification.

## Not covered here (to avoid duplication)
- see `TS-CRYPTO-003` and `TS-CRYPTO-004` for SHA-256, HMAC-SHA-256, PBKDF2, Argon2id, and ChaCha20-Poly1305 AEAD.
