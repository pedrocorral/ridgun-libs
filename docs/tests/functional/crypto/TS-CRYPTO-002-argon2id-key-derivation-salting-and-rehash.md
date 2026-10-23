---
id: TS-CRYPTO-002
title: Verify Argon2id salt generation, auto-salted password hashing, PHC parsing, rehash detection, raw key derivation, context pepper/AD, and presets
level: unit
covers: [FR-CRYPTO-002]
status: automated
automated_in: [src/test/ridgun/test argon2id.rg]
---
# TS-CRYPTO-002 — Verify Argon2id salt generation, auto-salted password hashing, PHC parsing, rehash detection, raw key derivation, context pepper/AD, and presets

## Preconditions / fixtures
- Pure-Ridgun `argon2id` module (`src/main/ridgun/lib/argon2id.rg`).

## Steps / inputs
1. Generate salts with `argon2id generate salt 16`, hash a password with `argon2id hash password`, and verify the resulting PHC string with `argon2id verify`.
2. Parse the PHC string with `argon2id parse phc` and check `argon2id needs rehash` against the same `Argon2Params` (`False`) and upgraded `Argon2Params` (`True`), plus malformed PHC input (`True`).
3. Derive raw keys with `argon2id derive key` and `argon2id derive key hex`, check preset constructors (`argon2 interactive params`, `argon2 moderate params`, `argon2 sensitive params`), and hash/verify with `secret` (pepper) and `associated_data` (`argon2id hash with context`, `argon2id verify with context`), verifying that wrong pepper or wrong AD fails verification.

## Expected results (map to acceptance criteria)
- AC1 → `argon2id generate salt` returns `>= 16` bytes and `argon2id hash password` produces a valid PHC hash that verifies with `argon2id verify`.
- AC2 → `argon2id parse phc` extracts parameters/salt/tag and `argon2id needs rehash` accurately detects parameter changes or malformed strings.
- AC3 → `argon2id derive key` / `argon2id derive key hex` return deterministic raw/hex keys, preset profiles pass validation, and `argon2id verify with context` succeeds only when both password, pepper (`secret`), and `ad` match.

## Not covered here (to avoid duplication)
- see `TS-CRYPTO-001` for baseline PHC hashing and invalid parameter rejection.
