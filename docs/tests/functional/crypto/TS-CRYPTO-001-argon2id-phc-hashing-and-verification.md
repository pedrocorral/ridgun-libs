---
id: TS-CRYPTO-001
title: Verify RFC 9106 Argon2id PHC hashing, parameter validation, and constant-time verification
level: unit
covers: [FR-CRYPTO-001]
status: automated
automated_in: [src/test/ridgun/test argon2id.rg]
---
# TS-CRYPTO-001 — Verify RFC 9106 Argon2id PHC hashing, parameter validation, and constant-time verification

## Preconditions / fixtures
- Pure-Ridgun `argon2id` module (`src/main/ridgun/lib/argon2id.rg`).

## Steps / inputs
1. Hash a password and salt (`>= 8` bytes) with valid RFC 9106 Argon2id parameters (`m_cost = 32`, `t_cost = 3`, `lanes = 4`, `tag_len = 32`) via `argon2id hash`, verifying deterministic in-process pure-Ridgun output (`RG-050`), canonical PHC format `$argon2id$v=19$m=32,t=3,p=4$<salt_b64>$<tag_b64>`, OpenSSL 3.5 vectors (`m=8,t=1,p=1`, `m=64,t=2,p=1`, `m=256,t=2,p=1`), and the RFC 9106 §5.3 official 32-byte test vector (`0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659`).
2. Call `argon2id hash` with invalid parameters (`t_cost = 0`, `lanes = 0`, `m_cost < 8 * lanes`, `tag_len = 2`, and 4-byte salt).
3. Verify the generated PHC string with `argon2id verify` against the matching password, a wrong password, and malformed PHC strings (`$argon2i$...`, missing segments, empty tag `$argon2id$v=19$m=64,t=2,p=1$c2FsdHNhbHRzYWx0c2FsdA$` per `RG-051`, corrupted Base64).

## Expected results (map to acceptance criteria)
- AC1 → Valid parameters produce deterministic RFC 9106 Argon2id output encoded as `$argon2id$v=19$m=...,t=...,p=...$<salt_b64>$<tag_b64>`.
- AC2 → Invalid parameters or short salts return `Argon2Err` without executing memory-matrix compression.
- AC3 → `argon2id verify` returns `True` for the matching password and `False` for wrong passwords or malformed PHC strings using constant-time comparison.

## Not covered here (to avoid duplication)
- Socket operations (`TS-SOCK-001`, `TS-SOCK-002`).
