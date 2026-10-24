---
id: API-TENSOR-001
title: Public lib contract for tensor (tensor.rglib / libtensor.so)
status: approved
implements: [FR-TENSOR-001]
auth: none
---
# API-TENSOR-001 — Public lib contract for `tensor` (`tensor.rg`)

## Request
- Imported via `import tensor`.
- Inputs (see `DM-Tensor`): `row_count` (`Int`), `col_count` (`Int`), `row_idx` (`Int`), `col_idx` (`Int`).
- Dimension & Slice Operations:
  - `tensor rows (Tensor[Int * r * c] m) => Int`
  - `tensor cols (Tensor[Int * r * c] m) => Int`
  - `tensor shape (Tensor[Int * r * c] m) => Int Int`
  - `tensor row (Tensor[Int * r * c] m) Int => Tensor[Int * c]`
  - `tensor col (Tensor[Int * r * c] m) Int => Tensor[Int * r]`
- Bitwise & Arithmetic Hadamard Operations:
  - `tensor xor blocks (Tensor[U64 * r * c] a) (Tensor[U64 * r * c] b) => Tensor[U64 * r * c]`
  - `tensor and blocks (Tensor[U64 * r * c] a) (Tensor[U64 * r * c] b) => Tensor[U64 * r * c]`
  - `tensor or blocks (Tensor[U64 * r * c] a) (Tensor[U64 * r * c] b) => Tensor[U64 * r * c]`
  - `tensor add blocks (Tensor[Int * r * c] a) (Tensor[Int * r * c] b) => Tensor[Int * r * c]`
  - `tensor sub blocks (Tensor[Int * r * c] a) (Tensor[Int * r * c] b) => Tensor[Int * r * c]`
  - `tensor mul blocks (Tensor[Int * r * c] a) (Tensor[Int * r * c] b) => Tensor[Int * r * c]`
  - `tensor clone (Tensor[U64 * r * c] m) => Tensor[U64 * r * c]`
- Einstein Contraction:
  - `tensor matmul (Tensor[Real * r * k] a) (Tensor[Real * k * c] b) => Tensor[Real * r * c]`

## Responses
| Code | When | Body |
|---|---|---|
| `Int` / `Int Int` | Dimension query on 2D tensor | `row_count`, `col_count`, or `(row_count, col_count)` |
| `Tensor[T * n]` | Row or column view query | 1D tensor slice `m_(row_idx,)` or `m_(,col_idx)` |
| `Tensor[T * r * c]` | Hadamard, clone, or matrix multiplication | Resulting 2D tensor |

## Rules
- All public functions use natural space-separated Ridgun names (`tensor rows`, `tensor xor blocks`, `tensor matmul`, etc.).
- Dimension variables (`r`, `c`, `k`) are bound directly in the `Tensor[T * r * c]` parameter pattern.
