---
id: ADR-0011
title: jwt uses the crypto lib's HMAC-SHA256 and ChaCha20-Poly1305
status: accepted
date: 2026-11-09
supersedes: []
affects: [FR-JWT-001, API-JWT-001, DM-Jwt, TS-JWT-001, src/main/ridgun/lib/jwt.ridgun]
---
# ADR-0011 — jwt uses the crypto lib's HMAC-SHA256 and ChaCha20-Poly1305

## Context
`CONFLICT-0005`: `jwt.ridgun` had its own HMAC (wrong pads, inner digest hashed as hex) and an AEAD made of a SHA-256 keystream. `FR-JWT-001` requires RFC 7519 HS256 and RFC 8439 ChaCha20-Poly1305. `crypto.ridgun` already implements both, tested with RFC 4231 and RFC 8439 vectors.

## Decision
- `jwt hmac sha256 b64url` is `crypto`'s `hmac sha256`, Base64url-encoded without padding.
- `jwt seal aead` / `jwt open aead` are `crypto`'s `aead seal` / `aead open`.
- The sealed token is `RGAEAD2.<nonce>.<ciphertext>.<tag>`, each part unpadded Base64url. The AAD is `RGAEAD2.<nonce>`, so the version and the nonce are authenticated.
- The version label changes from `RGAEAD1` to `RGAEAD2`, so an old token fails with "invalid AEAD token version" instead of a tag error.
- `jwt` imports `crypto`; its own HMAC key block and keystream code is removed.

## Alternatives considered
1. Keep the home-made scheme and document it: rejected; it is not HS256 and the AEAD has no security analysis.
2. Keep the label `RGAEAD1`: rejected; old tokens would fail with a misleading tag error.

## Consequences
- Tokens signed or sealed before this change no longer verify or open. Nothing in the ecosystem calls `jwt` (checked 2026-11-09).
- HS256 tokens now interoperate with other JWT implementations (RFC 7515 A.1 verifies).
- The `jwt` lib now depends on `crypto` (and through it on `argon2id` and `posix`).
