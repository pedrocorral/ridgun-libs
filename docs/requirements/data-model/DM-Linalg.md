---
id: DM-Linalg
title: Typed Tensor linear algebra, norms, linear solver, and neural activation models
status: approved
related: [FR-LINALG-001, API-LINALG-001, DM-Tensor, ADR-0002]
---
# DM-Linalg — Typed Tensor linear algebra, norms, linear solver, and neural activation models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| row_count | Int | `>= 1` | Matrix row count `r` bound via `Tensor[Real * r * c]` |
| col_count | Int | `>= 1` | Matrix column count `c` bound via `Tensor[Real * r * c]` |
| norm_value | Real | `>= 0.0` | Scalar vector/matrix norm ($L_1$, $L_2$, or $L_\infty$) |

## Relations
- Extends `DM-Tensor` and `tensor.rg` for `linalg.rg` (`linalg transpose`, `linalg trace`, `linalg norm l1`/`l2`/`linf`, `linalg outer`, `linalg solve`, `linalg relu`, `linalg sigmoid`, `linalg softmax`).

## Invariants
- `linalg softmax` subtracts `max(x)` before exponentiation for numerical stability and guarantees $\sum_i \text{softmax}(x)_i \approx 1.0$.

## Lifecycle
- Operates over contiguous `Tensor[Real * r * c]` and `Tensor[Real * n]` buffers managed by `RMM1`/`RMM2`.
