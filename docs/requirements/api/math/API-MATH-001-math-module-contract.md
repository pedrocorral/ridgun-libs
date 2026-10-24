---
id: API-MATH-001
title: Public lib contract for math (math.rglib / libmath.so)
status: approved
implements: [FR-MATH-001]
auth: none
---
# API-MATH-001 — Public lib contract for `math` (`math.rg`)

## Request
- Imported via `import math`.
- Bounds & Parity:
  - `math abs Int => Int`, `math sign Int => Int`, `math min Int Int => Int`, `math max Int Int => Int`, `math clamp Int Int Int => Int`, `op :: clamp Int between Int and Int => Int`, `math is even Int => Bool`, `math is odd Int => Bool`
- Rounding & Euclidean Division:
  - `math div ceil Int Int => Int`, `math div floor Int Int => Int`, `math div euclid Int Int => Int`, `math mod euclid Int Int => Int`
- Powers, Roots & Logarithms:
  - `math pow Int Int => Int`, `math isqrt Int => Int`, `math ilog2 Int => Int`, `math ilog10 Int => Int`, `math is power of two Int => Bool`, `math next power of two Int => Int`
- Number Theory & Combinatorics:
  - `math gcd Int Int => Int`, `math lcm Int Int => Int`, `math mod pow Int Int Int => Int`, `math mod inv Int Int => Int`, `math is prime Int => Bool`, `math factorial Int => Int`, `math ncr Int Int => Int`, `math fibonacci Int => Int`
- List Statistics:
  - `math sum [Int] => Int`, `math product [Int] => Int`, `math mean [Int] => Int`, `math median [Int] => Int`, `math min list [Int] => Int`, `math max list [Int] => Int`

## Responses
| Code | When | Body |
|---|---|---|
| `Int` / `Bool` | Valid mathematical input | Exact computed integer or boolean result |
| `0` / `-1` | Invalid domain (division by zero, negative `isqrt`, non-coprime `mod_inv`) | Safe sentinel (`0` for division/modulo/negative exponent, `-1` for undefined root/log/inverse) |

## Rules
- All functions are pure and total (never divide by zero at the CPU level).
