---
id: FR-LINALG-001
title: Provide typed Tensor linear algebra operations, vector/matrix norms, linear solver, and neural activations
type: functional
status: implemented
priority: must
domain: LINALG
depends_on: [FR-TENSOR-001]
related: [ADR-0002, ADR-0008, DM-Linalg, DM-Tensor, API-LINALG-001, VUL-INPUT-001]
tests: [TS-LINALG-001]
---
# FR-LINALG-001 — Provide typed Tensor linear algebra operations, vector/matrix norms, linear solver, and neural activations

## Statement
The `linalg` library SHALL provide typed `Tensor[Real * r * c]` and `Tensor[Real * n]` operations: `linalg transpose`, `linalg trace`, `linalg diag`, `linalg identity`, `linalg dot`, `linalg outer`, `linalg matvec`, `linalg matmul`, `linalg det`, `linalg norm l1`, `linalg norm l2`, `linalg norm linf`, `linalg frobenius norm`, `linalg normalize vec`, `linalg cosine similarity`, `linalg solve` (Gaussian elimination with partial pivoting), the scalar functions `linalg sqrt` and `linalg exp`, and neural activations (`linalg relu`, `linalg sigmoid`, `linalg softmax`).
All values are `Real` (ADR-0008). Only dimensions (`linalg vec len`, `linalg mat rows`, `linalg mat cols`) are `Int`.

## Rationale
Scientific computing, statistical modeling, and lightweight machine learning inference in Ridgun require higher-level linear algebra and activation functions built on `Tensor[Real * ...]`.

## Acceptance criteria
- AC1: Given 2D `Tensor[Real * r * c]` matrices and 1D `Tensor[Real * n]` vectors, when `linalg transpose`, `linalg trace`, `linalg diag`, `linalg identity`, `linalg dot`, `linalg outer`, `linalg matvec`, `linalg matmul`, `linalg det`, and the norms are called, then they return `Real` results within a relative error of 1e-12 of analytical linear algebra.
- AC2: Given a non-singular $N \times N$ matrix $A$ and right-hand side vector $b$, when `linalg solve A b` is called, then it returns vector $x$ such that $A x = b$ within a relative error of 1e-12, also when $A_{00} = 0$ (partial pivoting).
- AC3: Given a 1D `Tensor[Real * n]` vector, when `linalg relu`, `linalg sigmoid`, and `linalg softmax` are called, then `relu` clamps negatives to `0.0`, `sigmoid` maps into `(0, 1)` with `sigmoid(0) == 0.5` and `sigmoid(-x) + sigmoid(x) == 1`, and `softmax` shifts by `-max(x)` and returns a probability distribution summing to `1.0`.
- AC4: `linalg sqrt x` and `linalg exp x` are within a relative error of 1e-12 of the IEEE double result for `x` in the ranges the library uses (`sqrt`: `x >= 0`; `exp`: `-745 <= x <= 709`). `linalg sqrt` of a negative value is `0.0`; `linalg exp` below `-745` is `0.0`.

## Actors & permissions
- Any Ridgun program or lib importing `linalg`.

## Constraints & edge cases
- `linalg softmax` shifts inputs by `-max(x)` to avoid floating-point overflow.
- `linalg sigmoid` only passes values `<= 0` to `linalg exp`, so it cannot overflow.
- A singular matrix gives `linalg det == 0.0`; `linalg solve` returns a vector without dividing by zero (the components it cannot determine are `0.0`).
- Runs on x86_64 only until the arm64 backend supports `Real` (ridgunc 0.9.41).

## Data & privacy
- Contiguous `Tensor[Real]` buffers in `RMM1`/`RMM2` memory.

## Security & observability notes
- Mitigates `VUL-INPUT-001` via pattern-bound dimension checks and zero-division guards.

## Out of scope
- Complex-valued eigensolvers.
