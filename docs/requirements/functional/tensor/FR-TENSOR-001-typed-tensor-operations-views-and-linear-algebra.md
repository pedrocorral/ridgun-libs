---
id: FR-TENSOR-001
title: Provide typed tensor dimension inspection, subscript row/column views, bitwise/arithmetic Hadamard combinators, and Einstein contraction
type: functional
status: implemented
priority: must
domain: TENSOR
depends_on: []
related: [ADR-0002, DM-Tensor, API-TENSOR-001, VUL-INPUT-001]
tests: [TS-TENSOR-001]
---
# FR-TENSOR-001 — Provide typed tensor dimension inspection, subscript row/column views, bitwise/arithmetic Hadamard combinators, and Einstein contraction

## Statement
The `tensor` library SHALL provide typed tensor dimension inspection (`tensor rows`, `tensor cols`, `tensor shape`), subscript row and column slice extraction (`tensor row`, `tensor col`), element-wise bitwise and arithmetic Hadamard operations (`tensor xor blocks`, `tensor and blocks`, `tensor or blocks`, `tensor add blocks`, `tensor sub blocks`, `tensor mul blocks`), explicit cloning (`tensor clone`), and Einstein matrix contraction (`tensor matmul`) built on Ridgun v0.9.15's first-class `Tensor[...]` primitives.

## Rationale
Applications and cryptographic/numerical kernels require reusable, type-safe combinators over `Tensor[Int * r * c]`, `Tensor[U64 * r * c]`, and `Tensor[Real * r * c]` using Ridgun v0.9.15's glued-bracket dimension patterns (`Tensor[T * r * c] m`), subscript slicing (`m_(idx,)`, `m_(,idx)`), native 1-cycle bitwise Hadamard operators (`a_ij xor b_ij`), and Einstein summation (`a_ik @ b_kj`).

## Acceptance criteria
- AC1: Given a 2D tensor `m` of shape `r * c`, when `tensor rows m`, `tensor cols m`, `tensor shape m`, `tensor row m row_idx`, and `tensor col m col_idx` are called, then `tensor rows` returns `r`, `tensor cols` returns `c`, `tensor shape` returns `(r, c)`, `tensor row` returns the 1D row slice `m_(row_idx,)` of length `c`, and `tensor col` returns the 1D column slice `m_(,col_idx)` of length `r`.
- AC2: Given two 2D tensors `a` and `b` of matching shape `r * c`, when `tensor xor blocks a b`, `tensor and blocks a b`, `tensor or blocks a b`, `tensor add blocks a b`, `tensor sub blocks a b`, `tensor mul blocks a b`, or `tensor clone a` are called, then they return a new tensor with the corresponding element-wise 64-bit bitwise or arithmetic result without mutating `a` or `b`.
- AC3: Given a 2D tensor `a` of shape `r * k` and a 2D tensor `b` of shape `k * c`, when `tensor matmul a b` is called, then it returns the contracted 2D tensor `a_ik @ b_kj` of shape `r * c`.

## Actors & permissions
- Any Ridgun module importing `tensor`.

## Constraints & edge cases
- Subscript indexing uses 0-based indices (`0..row_count-1`, `0..col_count-1`).
- `tensor clone` uses `r_ij` (`:tensor-clone:`) so subsequent in-place mutations on the returned tensor never alias the input tensor.

## Data & privacy
- All tensors reside in deterministic `RMM1`/`RMM2` heap or lexical region memory.

## Security & observability notes
- Mitigates `VUL-INPUT-001` via compile-time and pattern-bound dimension checks.

## Out of scope
- GPU/CUDA offload.
