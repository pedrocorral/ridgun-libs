---
id: API-LINALG-001
title: Public module contract for linalg (linalg.rglib / liblinalg.so)
status: approved
implements: [FR-LINALG-001]
auth: none
---
# API-LINALG-001 — Public module contract for `linalg` (`linalg.rg`)

## Request
- Imported via `import linalg`.
- Inputs (see `DM-Linalg` and `DM-Tensor`): `row_count`, `col_count`, `norm_value`.
- Matrix & Vector Operations:
  - `linalg transpose (Tensor[Real * r * c] m) => Tensor[Real * c * r]`
  - `linalg trace (Tensor[Real * n * n] m) => Int`
  - `linalg diag (Tensor[Real * n * n] m) => Tensor[Real * n]`
  - `linalg identity Int => Tensor[Real * n * n]`
  - `linalg dot (Tensor[Real * n] a) (Tensor[Real * n] b) => Int`
  - `linalg outer (Tensor[Real * r] a) (Tensor[Real * c] b) => Tensor[Real * r * c]`
  - `linalg matvec (Tensor[Real * r * c] m) (Tensor[Real * c] v) => Tensor[Real * r]`
  - `linalg det (Tensor[Real * n * n] m) => Int`
- Norms, Normalization & Linear Solver:
  - `linalg norm l1 (Tensor[Real * n] v) => Int`
  - `linalg norm l2 (Tensor[Real * n] v) => Int`
  - `linalg norm linf (Tensor[Real * n] v) => Int`
  - `linalg normalize vec (Tensor[Real * n] v) => Tensor[Real * n]`
  - `linalg solve (Tensor[Real * n * n] a) (Tensor[Real * n] b) => Tensor[Real * n]`
- Neural Activations (permille `1000 = 1.000` fixed-point scale):
  - `linalg relu (Tensor[Real * n] v) => Tensor[Real * n]`
  - `linalg sigmoid (Tensor[Real * n] v) => Tensor[Real * n]`
  - `linalg softmax (Tensor[Real * n] v) => Tensor[Real * n]`

## Responses
| Code | When | Body |
|---|---|---|
| `Int` | `linalg trace`, `linalg dot`, `linalg det`, `linalg norm*` | Scalar result (`norm_value`) |
| `Tensor[Real * n]` | `linalg diag`, `linalg matvec`, `linalg solve`, `linalg relu`/`sigmoid`/`softmax` | 1D tensor |
| `Tensor[Real * c * r]` | `linalg transpose`, `linalg outer`, `linalg identity` | 2D tensor |

## Rules
- Dimension variables (`r`, `c`, `n`) are bound via `Tensor[Real * ...]` patterns.
