---
id: API-UUID-001
title: Public lib contract for uuid (uuid.rglib / libuuid.so)
status: approved
implements: [FR-UUID-001]
related: [ADR-0010]
auth: none
---
# API-UUID-001 — Public lib contract for `uuid` (`uuid.rg`)

## Request
- Imported via `import uuid`.
- Functions:
  - `uuid v4 => String`, `uuid v7 => String`, `uuid v7 at Int => String`
  - `uuid is valid String => Bool`, `uuid version String => Int`
  - `fnv1a 32 String => Int`, `adler32 String => Int`, `crc32 String => Int`
  - `prng next Int => Int`, `prng range Int Int Int => (Int, Int)`

## Responses
| Code | When | Body |
|---|---|---|
| `String` / `Int` / `Bool` | UUID generation, validation, checksum, or PRNG step | Canonical 36-char UUID, 32-bit unsigned checksum, or `(next_seed, val)` |

## Rules
- `crc32`, `adler32`, and `fnv1a 32` return 32-bit unsigned integers in `0..4294967295`.
- `crc32 s` equals the built-in `crc32 range s 0 (str len s) 0` (`ADR-0010`); the signature `crc32 String => Int` is unchanged.
- `uuid v7` uses the built-in `sys wall time ms`; random bytes come from `getrandom` into a `Tensor[U8 * 16]` (no memfd buffer).
