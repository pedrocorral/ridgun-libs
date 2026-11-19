---
id: TS-HASH-001
title: SipHash-1-3 vectors, ranges and invalid input
level: unit
covers: [FR-HASH-001, API-HASH-001]
status: automated
automated_in: [src/test/ridgun/test hash.ridgun]
---
# TS-HASH-001 — SipHash-1-3 vectors, ranges and invalid input

## Steps
1. For the key `00 01 .. 0f` and the inputs `00 .. n-1` (n in 0, 1, 7, 8, 9, 15, 16, 17, 25, 63, 64), compare the low and the high 32 bits of `siphash13 range` with the reference values.
2. Hash a range inside a longer string and the same bytes alone.
3. Call with a short key, a reversed range and a range past the data.
4. Make two keys with `siphash new key`.
5. For every length from 0 to 70 and the offsets 0, 3 and 25, compare the native operation with `siphash13 reference`.

## Expected
- AC1 → the 22 values match.
- AC2 → both results are equal.
- AC3 → every result is 0.
- AC4 → 16 bytes each, and different.
- AC5 → no difference.
