---
id: TS-UUID-001
title: Verify RFC 9562 UUIDv4/UUIDv7, FNV-1a/Adler-32/CRC-32 standard vectors, and seeded PRNG
level: unit
covers: [FR-UUID-001, API-UUID-001]
status: automated
automated_in: [src/test/ridgun/test uuid.rg]
---
# TS-UUID-001 — Verify RFC 9562 UUIDv4/UUIDv7, FNV-1a/Adler-32/CRC-32 standard vectors, and seeded PRNG

## Preconditions / fixtures
- Pure-Ridgun `uuid` module (`src/main/ridgun/lib/uuid.rg`).

## Steps / inputs
1. Call `uuid v4`, `uuid v7`, `uuid v7 at`, `uuid is valid`, and `uuid version` on valid and malformed UUIDs.
2. Call `fnv1a 32 "foobar"`, `adler32 "Wikipedia"`, and `crc32 "123456789"`.
3. Call `prng next` and `prng range` and verify determinism and `[lo, hi]` bounds.

## Expected results (map to acceptance criteria)
- AC1 → Generated UUIDv4/UUIDv7 strings pass `uuid is valid` with version `4`/`7` and chronological ordering for UUIDv7.
- AC2 → Checksums match standard reference test vectors (`3214735752`, `300286872`, `3421780262`).
- AC3 → Seeded PRNG is deterministic and stays within `[lo, hi]`.

## Not covered here (to avoid duplication)
- SHA-256 and HMAC-SHA-256 are covered in `TS-CRYPTO-003`.
