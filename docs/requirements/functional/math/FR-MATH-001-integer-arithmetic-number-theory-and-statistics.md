---
id: FR-MATH-001
title: Provide pure-Ridgun integer arithmetic, rounding division, powers/roots/logarithms, modular number theory, combinatorics, and list statistics
type: functional
status: implemented
priority: must
domain: MATH
depends_on: []
related: [ADR-0002, VUL-INPUT-001]
tests: [TS-MATH-001]
---
# FR-MATH-001 — Provide pure-Ridgun integer arithmetic, rounding division, powers/roots/logarithms, modular number theory, combinatorics, and list statistics

## Statement
The `math` library SHALL provide pure-Ridgun integer mathematical functions covering basic bounds (`math abs`, `math sign`, `math min`, `math max`, `math clamp`, `math is even`, `math is odd`, and natural-language operator `clamp x between lo and hi`), exact rounding division (`math div ceil`, `math div floor`, `math div euclid`, `math mod euclid`), powers/roots/logarithms (`math pow`, `math isqrt`, `math ilog2`, `math ilog10`, `math is power of two`, `math next power of two`), modular number theory (`math gcd`, `math lcm`, `math mod pow`, `math mod inv`, `math is prime`), combinatorics (`math factorial`, `math ncr`, `math fibonacci`), and integer list statistics (`math sum`, `math product`, `math mean`, `math median`, `math min list`, `math max list`).

## Rationale
Ridgun's compiler provides `+`, `-`, `*`, `/`, and `%`, while algorithms, cryptographic primitives, networking calculators, and CLI utilities require deterministic, division-by-zero-safe mathematical primitives without C `libm`.

## Acceptance criteria
- AC1: Given signed integers, when `math abs`, `math sign`, `math min`, `math max`, `math clamp`, `math div ceil`, `math div floor`, `math div euclid`, and `math mod euclid` are called, then they return exact results and safely return `0` when a divisor is `0` without trapping (`SIGFPE`).
- AC2: Given integer operands, when `math pow`, `math isqrt`, `math ilog2`, `math ilog10`, `math is power of two`, `math next power of two`, `math gcd`, `math lcm`, `math mod pow`, `math mod inv`, `math is prime`, `math factorial`, `math ncr`, and `math fibonacci` are called, then they return exact mathematical values (with `math isqrt n` returning `-1` for `n < 0`, `math ilog2`/`math ilog10` returning `-1` for `n <= 0`, and `math mod inv a m` returning `-1` when $\gcd(a, m) \neq 1$).
- AC3: Given integer lists `[Int]`, when `math sum`, `math product`, `math mean`, `math median`, `math min list`, and `math max list` are called, then they return the exact aggregate over non-empty lists and `0` (or `1` for `math product []`) on empty lists.

## Actors & permissions
- Any Ridgun program or lib importing `math`.

## Constraints & edge cases
- Division or modulo by `0` in any `math` function returns `0` (or `-1` for `math mod inv`) and never triggers a CPU divide-by-zero fault.
- Negative exponents in `math pow` and `math mod pow` return `0`.

## Data & privacy
- Pure in-memory integer computations.

## Security & observability notes
- Mitigates `VUL-INPUT-001` by guarding all divisions, modular reductions, negative roots, and non-positive logarithms against invalid inputs.

## Out of scope
- IEEE-754 transcendental floating-point functions (`sin`, `cos`, `atan2`).
