---
id: API-LINALG-001
title: Public lib contract for linalg (linalg.rglib / liblinalg.so)
status: approved
implements: [FR-LINALG-001]
auth: none
---
# API-LINALG-001 — Public lib contract for `linalg` (`linalg.rg`)

## Request
- Imported via `import linalg`.
- Inputs (see `DM-Linalg` and `DM-Tensor`): `row_count`, `col_count`, `norm_value`.
- Matrix & Vector Operations:
  - `linalg transpose (Tensor[Real * r * c] m) => Tensor[Real * c * r]`
  - `linalg trace (Tensor[Real * n * n] m) => Real`
  - `linalg diag (Tensor[Real * n * n] m) => Tensor[Real * n]`
  - `linalg identity Int => Tensor[Real * n * n]`
  - `linalg dot (Tensor[Real * n] a) (Tensor[Real * n] b) => Real`
  - `linalg outer (Tensor[Real * r] a) (Tensor[Real * c] b) => Tensor[Real * r * c]`
  - `linalg matvec (Tensor[Real * r * c] m) (Tensor[Real * c] v) => Tensor[Real * r]`
  - `linalg matmul (Tensor[Real * r * k] a) (Tensor[Real * k * c] b) => Tensor[Real * r * c]`
  - `linalg det (Tensor[Real * n * n] m) => Real`
- Norms, Normalization & Linear Solver:
  - `linalg norm l1 (Tensor[Real * n] v) => Real`
  - `linalg norm l2 (Tensor[Real * n] v) => Real`
  - `linalg norm linf (Tensor[Real * n] v) => Real`
  - `linalg normalize vec (Tensor[Real * n] v) => Tensor[Real * n]`
  - `linalg norm l2 sq (Tensor[Real * n] v) => Real`
  - `linalg frobenius norm (Tensor[Real * r * c] m) => Real`
  - `linalg cosine similarity (Tensor[Real * n] a) (Tensor[Real * n] b) => Real`
  - `linalg solve (Tensor[Real * n * n] a) (Tensor[Real * n] b) => Tensor[Real * n]`
- Scalar functions:
  - `linalg sqrt Real => Real`
  - `linalg exp Real => Real`
- Neural Activations (`Real` values; `sigmoid` in (0, 1), `softmax` sums to 1.0):
  - `linalg relu (Tensor[Real * n] v) => Tensor[Real * n]`
  - `linalg sigmoid (Tensor[Real * n] v) => Tensor[Real * n]`
  - `linalg softmax (Tensor[Real * n] v) => Tensor[Real * n]`

## Responses
| Code | When | Body |
|---|---|---|
| `Real` | `linalg trace`, `linalg dot`, `linalg det`, `linalg norm*`, `linalg cosine similarity`, `linalg sqrt`, `linalg exp` | Scalar result (`norm_value`) |
| `Int` | `linalg vec len`, `linalg mat rows`, `linalg mat cols` | Dimension |
| `Tensor[Real * n]` | `linalg diag`, `linalg matvec`, `linalg solve`, `linalg relu`/`sigmoid`/`softmax` | 1D tensor |
| `Tensor[Real * c * r]` | `linalg transpose`, `linalg outer`, `linalg identity` | 2D tensor |

## Rules
- Dimension variables (`r`, `c`, `n`) are bound via `Tensor[Real * ...]` patterns.
