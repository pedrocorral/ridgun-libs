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
1. Test `linalg transpose`, `linalg trace`, `linalg diag`, `linalg identity`, `linalg dot`, `linalg outer`, `linalg norm l1`/`l2`/`linf`, and `linalg normalize vec` on `Tensor[Real * r * c]` and `Tensor[Real * n]`.
2. Solve a $2 \times 2$ and $3 \times 3$ linear system $A x = b$ via `linalg solve` and verify $A x \approx b$.
3. Apply `linalg relu`, `linalg sigmoid`, and `linalg softmax` to a 1D `Tensor[Real * n]` vector and verify output properties.

## Expected results (map to acceptance criteria)
- AC1 → Matrix/vector operations and norms match analytical values.
- AC2 → `linalg solve` solves non-singular linear systems accurately.
- AC3 → Neural activations (`relu`, `sigmoid`, `softmax`) satisfy range and normalization invariants.

## Not covered here (to avoid duplication)
- Base `tensor.rg` Hadamard and `matmul` operations (`TS-TENSOR-001`).
