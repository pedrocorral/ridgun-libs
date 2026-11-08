---
id: ADR-0008
title: linalg computes with Real, not with integers in Real tensors
status: accepted
date: 2026-11-07
supersedes: []
affects: [FR-LINALG-001, API-LINALG-001, DM-Linalg, TS-LINALG-001, FR-TENSOR-001, src/main/ridgun/lib/linalg.rg, src/main/ridgun/lib/tensor.rg, src/test/ridgun/test linalg.rg, src/test/ridgun/test tensor.rg]
---
# ADR-0008 — linalg computes with Real, not with integers in Real tensors

## Context
`linalg` declared `Tensor[Real * ...]`, but every value it stored and returned was an integer:
- `trace`, `dot`, `det` and the norms returned `Int`.
- `sigmoid` and `softmax` used permille: `sigmoid(0) == 500`, and `softmax` summed to `1000`.
- `exp` was a table of 16 integer values. `norm l2` used an integer square root.

Before ridgunc 0.9.41, an element of a `Tensor[Real]` behaved as an `Int`, so this compiled.
ridgunc 0.9.41 (general tensors, see the compiler release note `/tmp/tensors-0.9.41.md`) types an element of a `Tensor[Real]` as a `Real`.
Storing an `Int` in it is a compile error, so `linalg` and `test linalg.rg` stopped compiling (51 errors).

ridgunc 0.9.41 has `Real` arithmetic (`+`, `-`, `*`, `/`, comparisons), but no `sqrt`, no `exp` and no conversion between `Int` and `Real`.
In the same version, `a_ik @ b_kj` on `Real` tensors returns a tensor of zeros.

## Options considered
1. Switch `linalg` to `Tensor[Int]` and keep the integer and permille results.
2. Make `linalg` compute with `Real`: real-valued results, `sigmoid` in (0, 1), `softmax` summing to 1.0.

## Decision
Option 2, chosen by the user on 2026-11-07. Linear algebra is real-valued, so option 1 would keep a wrong design only to compile.
- Every scalar that `linalg` returns, except dimensions, is a `Real`.
- `linalg sqrt` (Newton's method from above) and `linalg exp` (halve the argument to |r| <= 0.5, 24-term Taylor series, square back) are written in Ridgun.
- `linalg det` and `linalg solve` use Gaussian elimination with partial pivoting. Bareiss fraction-free elimination was only needed for integers.
- `tensor matmul` uses explicit loops instead of `a_ik @ b_kj` until the compiler fixes `@` on `Real` tensors. `linalg matmul` calls `tensor matmul`.
- The compiler is not asked for `sqrt` or `exp`: they can be written in Ridgun with the arithmetic that exists.

## Consequences
- Requirements to update: `FR-LINALG-001` (Real results, sigmoid and softmax ranges, sqrt and exp), `API-LINALG-001` (return types), `DM-Linalg` (`norm_value` is `Real`), `FR-TENSOR-001` AC3 (`tensor matmul` result, not the `@` operator).
- Tests to update: `TS-LINALG-001` and `test linalg.rg` compare `Real` values with a relative tolerance of 1e-12; `test tensor.rg` uses `Real` literals.
- Behaviour change for callers: results are `Real` instead of `Int`, and activations are no longer in permille. No other project imports `linalg`.
- `linalg` runs only on x86_64 until the arm64 backend supports `Real` (ridgunc 0.9.41 "Pendiente").
- The `@` fault is reported to the compiler team in `/tmp/ridgun-compiler/2026-11-07/tensor-from-list-longitud.md`.
- ridgunc 0.9.45 fixed `@` on `Real` tensors (2026-11-08). `tensor matmul` uses `a_ik @ b_kj` again: a 200 × 200 product takes 1 ms instead of 1.3 s with the loops.
