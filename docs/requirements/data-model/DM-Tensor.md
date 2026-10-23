---
id: DM-Tensor
title: Typed Tensor dimension, subscript view, and block compression models
status: approved
related: [FR-TENSOR-001, API-TENSOR-001, FR-CRYPTO-004, ADR-0002]
---
# DM-Tensor — Typed Tensor dimension, subscript view, and block compression models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| row_count | Int | `>= 0` | Number of rows `r` bound by pattern `Tensor[T * r * c]` |
| col_count | Int | `>= 0` | Number of columns `c` bound by pattern `Tensor[T * r * c]` |
| row_idx | Int | `0..row_count-1` | Zero-based row index for subscript slice `m_(row_idx,)` |
| col_idx | Int | `0..col_count-1` | Zero-based column index for subscript slice `m_(,col_idx)` |

## Relations
- Used by `tensor.rg` (`tensor rows`, `tensor cols`, `tensor row`, `tensor col`, `tensor xor blocks`, `tensor matmul`, and arithmetic/bitwise Hadamard helpers) and by `crypto.rg` / `argon2id.rg` (`Tensor[U64 * 16]` and `Tensor[U64 * 8 * 16]` for Argon2id/Blake2b `BlaMka` 1024-byte block compression).

## Invariants
- Integer and byte tensors (`Tensor[Int]`, `Tensor[U64]`, `Tensor[Byte]`) store unboxed 64-bit integer values without lossy floating-point conversion.
- Explicit tensor cloning (`z = r_ij`) produces an independent buffer so in-place axis mappings (`map f in z_(i,)`, `map f in z_(,j)`, `||map f in z_(i,)`) never mutate the source tensor `r`.

## Lifecycle
- Allocated via glued-bracket constructors (`Tensor[U64 * 8 * 16]`) or tensor literals (`|[1, 2], [3, 4]|`), transformed via subscript views and `map ... in`, and reclaimed deterministically by `RMM1`/`RMM2` on scope exit.
