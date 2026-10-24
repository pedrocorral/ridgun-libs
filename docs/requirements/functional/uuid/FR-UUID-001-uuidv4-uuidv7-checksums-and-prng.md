---
id: FR-UUID-001
title: Provide pure-Ridgun RFC 9562 UUIDv4/UUIDv7, FNV-1a/Adler-32/CRC-32 checksums, and seeded deterministic PRNG
type: functional
status: implemented
priority: must
domain: UUID
depends_on: []
related: [ADR-0002, VUL-INPUT-001]
tests: [TS-UUID-001]
---
# FR-UUID-001 — Provide pure-Ridgun RFC 9562 UUIDv4/UUIDv7, FNV-1a/Adler-32/CRC-32 checksums, and seeded deterministic PRNG

## Statement
The `uuid` library SHALL provide pure-Ridgun RFC 9562 UUIDv4 and time-ordered UUIDv7 generation and validation (`uuid v4`, `uuid v7`, `uuid v7 at`, `uuid is valid`, `uuid version`), fast non-cryptographic checksums (`fnv1a 32`, `adler32`, `crc32`), and a seeded 31-bit deterministic pseudo-random number generator (`prng next`, `prng range`) for reproducible testing and simulations.

## Rationale
Distributed services, databases, and network framing require RFC 9562 UUIDv4/UUIDv7 identifiers, standard `CRC-32`/`Adler-32`/`FNV-1a` frame checksums, and deterministic seeded PRNG streams.

## Acceptance criteria
- AC1: When `uuid v4`, `uuid v7`, and `uuid v7 at ts_ms` are called, then they produce canonical 36-character lowercase `8-4-4-4-12` UUID strings with version nibble `4` or `7` and RFC 9562 variant `8..b`, `uuid is valid` returns `True` (`uuid version` returns `4` or `7`), and `uuid v7 at t1` is lexicographically `<` `uuid v7 at t2` whenever `t1 < t2`.
- AC2: Given input strings, when `fnv1a 32`, `adler32`, and `crc32` are called, then `fnv1a 32 "foobar"` returns `3214735752` (`0xbf9cf968`), `adler32 "Wikipedia"` returns `300286872` (`0x11e60398`), and `crc32 "123456789"` returns `3421780262` (`0xcbf43926`).
- AC3: Given an integer seed and bounds `[lo, hi]`, when `prng next` and `prng range` are called, then identical seeds produce identical deterministic sequences and `prng range seed lo hi` returns `(next_seed, val)` with `lo <= val <= hi`.

## Actors & permissions
- Any Ridgun program or lib importing `uuid`.

## Constraints & edge cases
- `uuid is valid` rejects strings whose length is not `36`, where hyphens are not at indices `8, 13, 18, 23`, or where any hex digit or RFC 9562 variant nibble is invalid.

## Data & privacy
- Pure in-memory ID, checksum, and PRNG computations.

## Security & observability notes
- Mitigates `VUL-INPUT-001` via strict 36-character UUID syntax and variant validation.

## Out of scope
- Cryptographic stream ciphers (covered in `crypto.rg`).
