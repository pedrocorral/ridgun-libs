---
id: FR-HASH-001
title: Provide a keyed hash for hash tables that resists chosen keys (SipHash-1-3)
type: functional
status: implemented
priority: must
domain: HASH
depends_on: []
related: [FR-HASHMAP-001, VUL-INPUT-001]
tests: [TS-HASH-001]
---
# FR-HASH-001 — Provide a keyed hash for hash tables that resists chosen keys (SipHash-1-3)

## Statement
The `hash` library SHALL provide SipHash-1-3 (Aumasson and Bernstein) with a 128-bit key and a 64-bit result, over a whole `String` or a range of it, and a function that makes a new random key.

## Rationale
A hash table whose hash can be predicted lets whoever chooses the keys put them all in one slot (hash flooding). `crc32 range` is fast but linear, and SHA-256 is safe but costs a whole compression per key. SipHash is a keyed pseudo-random function made for this; Rust, Python and Redis use it. Eterval asked for it on 2026-11-19 (`/tmp/ridgun-lib/eterval-hash-con-clave.md`): it keeps the key on disk and its `SCAN` cursors show the order of the hash, so the result must also be the same in every version and on every architecture.

## Acceptance criteria
- AC1: Given the key `00 01 .. 0f` and the input `00 01 .. n-1` for n in 0, 1, 7, 8, 9, 15, 16, 17, 25, 63, 64, when `siphash13 range` is called, then the 64 bits equal the reference values (the reference reproduces the official SipHash-2-4 vectors with c = 2, d = 4).
- AC2: Given a range inside a longer string, when `siphash13 range` is called, then the result equals that of the same bytes alone, and no substring is made.
- AC3: Given a key that is not 16 bytes, or a range outside the data, when any function is called, then the result is 0.
- AC4: Given two calls of `siphash new key`, then each result has 16 bytes and they differ.
- AC5: Given any length from 0 to 70 and a range starting at 0, 3 or 25, when the native operation and `siphash13 reference` are called, then the low 32 bits and the 64 bits are equal.

## Actors & permissions
- Any Ridgun program or lib importing `hash`.

## Constraints & edge cases
- `siphash13 range low` gives the low 32 bits of the same hash.
- The result does not depend on the architecture: words are read little-endian from the bytes.
- **Speed.** `siphash13 range` and `siphash13 range low` are native operations of the compiler since ridgunc 1.0.44: 19 ns for a 25-byte key on a Ryzen 7 8845HS (52 ns for `crc32 range`, 222 ns for `sha256 raw`). The lib keeps the same hash in plain Ridgun as `siphash13 reference` (about 2 µs per key); the tests compare both for every length from 0 to 70. `hashmap` uses the native one.

## Data & privacy
- The key is a secret of the program that owns the table.

## Security & observability notes
- Mitigates `VUL-INPUT-001` (keys chosen by an attacker).

## Out of scope
- SipHash-2-4, 128-bit results, and use as a message authentication code.
