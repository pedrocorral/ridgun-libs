---
id: ADR-0014
title: The hot loops of crypto and argon2id run on element-wise tensor operations
status: accepted
date: 2026-11-19
supersedes: []
affects: [FR-CRYPTO-004, FR-CRYPTO-006, NFR-PERF-001, src/main/ridgun/lib/crypto.ridgun, src/main/ridgun/lib/argon2id.ridgun]
---
# ADR-0014 — The hot loops of crypto and argon2id run on element-wise tensor operations

## Context
`crypto` and `argon2id` used tensors as arrays and did the arithmetic one element at a time with `Int`.
ridgunc 1.0.37 to 1.0.39 run a sequence of element-wise statements as one vector loop (`a_i + b_i`, `rotl`, `shr`, indexed reads `t_(x_i)`, `clmul`, `mulhi`, `Tensor[U8]`/`U16`/`U32` that wrap at their width). The user asked on 2026-11-19 to use them in the libs.

## Options considered
1. Keep the element-by-element code.
2. Rewrite the hot loops so that many blocks, rows or lanes are computed by the same statements.

## Decision
Option 2, for these primitives. The public functions and their results do not change.
- **ChaCha20:** one `Tensor[U32 * n]` per state word, n = up to 64 blocks; the ten double rounds are consecutive element-wise statements in a function that calls itself with `k - 1`.
- **Poly1305:** 5 limbs of 26 bits as `Tensor[U64 * 32]`; lane l takes blocks l, l + 32, …; every step multiplies by r^32 and the last one by r^(32 - l). Used when the ciphertext has at least 4 steps (2048 bytes); shorter inputs and the remainder go block by block.
- **AES-128-CTR (GCM):** one `Tensor[U8 * n]` per state byte, n = up to 256 blocks; SubBytes and ShiftRows are an indexed read of the S-box.
- **GHASH:** `clmul` and `clmulhi` on two 64-bit halves, then the reduction.
- **Argon2id:** a block is `Tensor[U64 * 128]` (it was 256 halves of 32 bits); the permutation P runs on the eight rows, then on the eight columns, with 4 tensors of 32 lanes.

## Consequences
- Libs need ridgunc 1.0.42 or later.
- Measured on a Ryzen 7 8845HS, one core: ChaCha20 1 MiB 120 ms to 1 ms; `aead seal` 1 MiB 142 ms to 3 ms; `aes128 gcm seal` 64 KiB 49 ms to 3 ms; Argon2id m=19456 t=2 p=1 0.647 s to 0.152 s; RSA-2048 verify 75 ms to 5 ms; ECDSA P-256 verify 454 ms to 73 ms.
- Each rewrite was compared with the code it replaces (same bytes for several lengths, offsets and counters) before the suites ran.
- ChaCha20 and AES-CTR turn their word and byte tensors into the key stream with `tensor interleave` and `tensor bytes` (ridgunc 1.0.40), all the blocks of a chunk of 1 MiB at once.
- Blamka puts its results back into the block with indexed writes (`q_(p_i) = t_i`, ridgunc 1.0.41), and Poly1305 reads the message bytes with `as U64` in one repeated loop.
- **Bignum (RSA, P-256, P-384):** Montgomery multiplication on 16-bit limbs, one element-wise statement per limb; the curve formulas keep their coordinates in Montgomery form.
- The vector loops exist on x86-64 Linux with LLVM. Other targets run the same statements element by element, more slowly.
- Not done: SHA-1, SHA-512, PBKDF2, X25519 and Ed25519 still work one element at a time.
