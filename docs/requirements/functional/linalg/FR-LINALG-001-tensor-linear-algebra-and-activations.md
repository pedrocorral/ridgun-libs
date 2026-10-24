---
id: FR-LINALG-001
title: Provide typed Tensor linear algebra operations, vector/matrix norms, linear solver, and neural activations
type: functional
status: implemented
priority: must
domain: LINALG
depends_on: [FR-TENSOR-001]
related: [ADR-0002, DM-Linalg, DM-Tensor, API-LINALG-001, VUL-INPUT-001]
tests: [TS-LINALG-001]
---
# FR-LINALG-001 — Provide typed Tensor linear algebra operations, vector/matrix norms, linear solver, and neural activations

## Statement
The `linalg` library SHALL provide typed `Tensor[Real * r * c]` and `Tensor[Real * n]` operations: `linalg transpose`, `linalg trace`, `linalg diag`, `linalg identity`, `linalg dot`, `linalg outer`, `linalg norm l1`, `linalg norm l2`, `linalg norm linf`, `linalg normalize vec`, `linalg solve` (Gaussian elimination with partial pivoting), and neural activations (`linalg relu`, `linalg sigmoid`, `linalg softmax`).

## Rationale
Scientific computing, statistical modeling, and lightweight machine learning inference in Ridgun require higher-level linear algebra and activation functions built on `Tensor[Real * ...]`.

## Acceptance criteria
- AC1: Given 2D `Tensor[Real * r * c]` matrices and 1D `Tensor[Real * n]` vectors, when `linalg transpose`, `linalg trace`, `linalg diag`, `linalg identity`, `linalg dot`, `linalg outer`, `linalg det`, and `linalg norm l1`/`l2`/`linf` are called, then they return exact results matching analytical linear algebra.
- AC2: Given a non-singular $N \times N$ matrix $A$ and right-hand side vector $b$, when `linalg solve A b` is called, then it returns vector $x$ such that $A x = b$.
- AC3: Given a 1D `Tensor[Real * n]` vector, when `linalg relu`, `linalg sigmoid`, and `linalg softmax` are called, then `relu` clamps negatives to `0`, `sigmoid` maps into permille `(0, 1000)` with `sigmoid(0) == 500`, and `softmax` shifts by `-max(x)` and produces a valid probability distribution summing to `1000` (`1.000`).

## Actors & permissions
- Any Ridgun program or lib importing `linalg`.

## Constraints & edge cases
- `linalg softmax` shifts inputs by `-max(x)` to avoid floating-point overflow.

## Data & privacy
- Contiguous `Tensor[Real]` buffers in `RMM1`/`RMM2` memory.

## Security & observability notes
- Mitigates `VUL-INPUT-001` via pattern-bound dimension checks and zero-division guards.

## Out of scope
- Complex-valued eigensolvers.
