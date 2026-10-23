---
id: TS-TENSOR-001
title: Verify typed tensor dimension inspection, subscript row/column views, bitwise/arithmetic Hadamard combinators, Einstein contraction, and BlaMka tensor block compression
level: unit
covers: [FR-TENSOR-001, API-TENSOR-001]
status: automated
automated_in: [src/test/ridgun/test tensor.rg]
---
# TS-TENSOR-001 — Verify typed tensor dimension inspection, subscript row/column views, bitwise/arithmetic Hadamard combinators, Einstein contraction, and BlaMka tensor block compression

## Preconditions / fixtures
- Pure-Ridgun `tensor`, `crypto`, and `test` modules (`src/main/ridgun/lib/tensor.rg`, `src/main/ridgun/lib/crypto.rg`, `src/main/ridgun/lib/test.rg`).

## Steps / inputs
1. Construct a 2D integer tensor `m = |[10, 20, 30], [40, 50, 60]|`; verify `tensor rows m == 2`, `tensor cols m == 3`, `tensor shape m == (2, 3)`, `tensor row m 1` returns `|40, 50, 60|`, and `tensor col m 2` returns `|30, 60|`.
2. Construct two 2D `U64` tensors `a` and `b` (`Tensor[U64 * 8 * 16]`) and two 2D `Int` tensors; verify `tensor xor blocks`, `tensor and blocks`, `tensor or blocks`, `tensor add blocks`, `tensor sub blocks`, `tensor mul blocks`, and `tensor clone` (`z = r_ij`) preserve source tensors and produce exact element-wise results.
3. Construct 2D `Real` matrices `a` (`2 * 3`) and `b` (`3 * 2`); verify `tensor matmul a b` (`a_ik @ b_kj`) produces the exact `2 * 2` matrix product.
4. Invoke `f blamka`, `blamka g`, `blamka p16`, and `compress block` on `Tensor[U64 * 8 * 16]` blocks (`map blamka p16 in z_(i,)` and `map blamka p16 in z_(,j)`); verify in-place row/column mutation and exact RFC 9106 Argon2id block compression results.

## Expected results (map to acceptance criteria)
- AC1 → Dimension binding patterns (`Tensor[Int * r * c]`) and subscript row/column views (`m_(idx,)`, `m_(,idx)`) return exact dimensions and 1D slices.
- AC2 → Bitwise and arithmetic Hadamard combinators and explicit tensor cloning (`r_ij`) return exact element-wise tensors without mutating inputs.
- AC3 → `tensor matmul` contracts inner dimension `k` via `a_ik @ b_kj` accurately, and `compress block` executes `BlaMka` over `Tensor[U64 * 8 * 16]` using 1-cycle bitwise instructions and axis-aware in-place `map`.

## Not covered here (to avoid duplication)
- High-level Argon2id PHC string parsing and ChaCha20-Poly1305 AEAD tag verification (covered in `TS-CRYPTO-004`).
