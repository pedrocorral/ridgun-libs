---
id: TS-MATH-001
title: Verify integer arithmetic, rounding division, powers/roots/logarithms, modular number theory, combinatorics, and list statistics
level: unit
covers: [FR-MATH-001, API-MATH-001]
status: automated
automated_in: [src/test/ridgun/test math.rg]
---
# TS-MATH-001 — Verify integer arithmetic, rounding division, powers/roots/logarithms, modular number theory, combinatorics, and list statistics

## Preconditions / fixtures
- Pure-Ridgun `math` module (`src/main/ridgun/lib/math.rg`).

## Steps / inputs
1. Call `math abs`, `math sign`, `math min`, `math max`, `math clamp`, `clamp x between lo and hi`, `math is even`, `math is odd`, `math div ceil`, `math div floor`, `math div euclid`, and `math mod euclid` with positive, negative, and zero-divisor inputs.
2. Call `math pow`, `math isqrt`, `math ilog2`, `math ilog10`, `math is power of two`, `math next power of two`, `math gcd`, `math lcm`, `math mod pow`, `math mod inv`, `math is prime`, `math factorial`, `math ncr`, and `math fibonacci` across boundary and negative cases.
3. Call `math sum`, `math product`, `math mean`, `math median`, `math min list`, and `math max list` on odd-length, even-length, single-element, and empty lists.

## Expected results (map to acceptance criteria)
- AC1 → Bounds, parity, and rounding/Euclidean division functions return exact values and `0` on zero divisor.
- AC2 → Powers, roots, logarithms, number-theory (`gcd`, `lcm`, `mod_pow`, `mod_inv`, `is_prime`), and combinatorics match exact reference values and return `-1`/`0` on invalid domains.
- AC3 → List statistics return exact aggregates on non-empty lists and safe defaults on `[]`.

## Not covered here (to avoid duplication)
- 32-bit unsigned bitwise operations (`band`, `bor`, `bxor`, `shl`, `shr`) are covered in `TS-CRYPTO-003`.
