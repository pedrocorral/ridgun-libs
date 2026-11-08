---
id: TS-LINALG-001
title: Verify typed Tensor linear algebra operations, vector/matrix norms, linear solver, and neural activations
level: unit
covers: [FR-LINALG-001, API-LINALG-001]
status: automated
automated_in: [src/test/ridgun/test linalg.rg]
---
# TS-LINALG-001 — Verify typed Tensor linear algebra operations, vector/matrix norms, linear solver, and neural activations

## Preconditions / fixtures
- Pure-Ridgun `linalg` and `test` modules (`src/main/ridgun/lib/linalg.rg`, `src/main/ridgun/lib/test.rg`).

## Steps / inputs
0. Compare `linalg sqrt` and `linalg exp` with known IEEE double values (sqrt 2, e, exp(-1), exp(10), exp(-20)) and check the guards (negative sqrt, exp(-800)).
1. Test `linalg transpose`, `linalg trace`, `linalg diag`, `linalg identity`, `linalg dot`, `linalg outer`, `linalg norm l1`/`l2`/`linf`, and `linalg normalize vec` on `Tensor[Real * r * c]` and `Tensor[Real * n]`.
2. Solve a $2 \times 2$, a $3 \times 3$ with $A_{00} = 0$, and a $2 \times 2$ with a fractional solution via `linalg solve`, and verify $A x \approx b$. Check `linalg det` on the same matrices and on a singular matrix.
3. Apply `linalg relu`, `linalg sigmoid`, and `linalg softmax` to a 1D `Tensor[Real * n]` vector and verify output properties.

## Expected results (map to acceptance criteria)
- AC1 → Matrix/vector operations and norms match analytical values.
- AC2 → `linalg solve` solves non-singular linear systems accurately.
- AC3 → Neural activations (`relu`, `sigmoid`, `softmax`) satisfy range and normalization invariants, and `softmax([1, 2, 3])` matches its known values.
- AC4 → `linalg sqrt` and `linalg exp` match the reference values.
- Every `Real` comparison uses a relative tolerance of 1e-12 (`near` in the test).

## Not covered here (to avoid duplication)
- Base `tensor.rg` Hadamard and `matmul` operations (`TS-TENSOR-001`).
