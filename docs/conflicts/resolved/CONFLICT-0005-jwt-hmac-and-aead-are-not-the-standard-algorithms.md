---
id: CONFLICT-0005
title: jwt's HS256 is not RFC 2104 HMAC and its AEAD is not ChaCha20-Poly1305
status: resolved            # open | resolved
date: 2026-11-09
affects: [FR-JWT-001, API-JWT-001, DM-Jwt, TS-JWT-001, src/main/ridgun/lib/jwt.ridgun, "src/test/ridgun/test jwt.ridgun"]
adr: ADR-0011
---
# CONFLICT-0005 — jwt's HS256 is not RFC 2104 HMAC and its AEAD is not ChaCha20-Poly1305

## Conflict
Found during TASK-0049 while moving `jwt.ridgun` to `Tensor[U8]`.

| Requirement says | Code does | Impact if we follow the requirement |
|---|---|---|
| `FR-JWT-001` AC1/AC2: RFC 7519 `HS256` (`HMAC-SHA256`) | `jwt hmac sha256 b64url` built the pads as `((k xor pad) % 126) + 1` and hashed the inner digest as hex text | Tokens interoperate with every other JWT implementation; tokens signed before the change no longer verify |
| `FR-JWT-001` AC3: RFC 8439 ChaCha20-Poly1305 | `jwt seal aead` used a SHA-256 keystream (`SHA-256(key ":" nonce ":" blk)`) and the non-standard HMAC as tag | Real AEAD security; tokens sealed before the change no longer open |

## Options and consequences
- A. Change code to match requirement: call `hmac sha256` and `aead seal` / `aead open` from `crypto.ridgun`, already tested with RFC 4231 and RFC 8439 vectors. Old tokens stop working; nothing in the ecosystem calls `jwt`.
- B. Change requirement: document the home-made scheme. Not acceptable: it is not HS256, and the AEAD has no security analysis.
- C. Split: not applicable.

## Agent recommendation
Option A.

## Human decision
Option A, chosen by the user on 2026-11-09.

## Resolution evidence (ADR, commits, tests)
- `ADR-0011-jwt-uses-the-standard-hmac-and-aead.md` (accepted).
- `test jwt.ridgun`: RFC 4231 test case 2, RFC 7515 A.1 token, RFC 8439 §2.8.2 ciphertext, and a cross-check against `crypto`'s `aead seal` → `[PASS] test jwt: TS-JWT-001 passed`.
