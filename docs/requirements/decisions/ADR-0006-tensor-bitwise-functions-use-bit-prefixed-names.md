---
id: ADR-0006
title: Tensor bitwise functions use bit-prefixed names
status: accepted
date: 2026-11-06
supersedes: []
affects: [API-TENSOR-001, FR-TENSOR-001, TS-TENSOR-001, DM-Tensor, src/main/ridgun/lib/tensor.rg, "src/test/ridgun/test tensor.rg", docs/book]
---
# ADR-0006 — Tensor bitwise functions use bit-prefixed names

## Context
`CONFLICT-0004`: `API-TENSOR-001` named three functions `tensor xor blocks`, `tensor and blocks` and `tensor or blocks`.
`and`, `or` and `xor` are logical operators; the Ridgun spec only allows `type` and `with` as words inside names.
A spaced call such as `tensor and blocks a b` parses as `tensor and (blocks a b)`, and strict mode forbids the underscore form.
Since commit `19fc716` (TASK-0039) `test tensor.rg` did not compile.

## Options considered
1. Keep the names and change the compiler or turn off strict mode.
2. Rename the three functions to names without operator keywords.

## Decision
Option 2, chosen by the user on 2026-11-06.
The functions are `tensor bitxor blocks`, `tensor bitand blocks` and `tensor bitor blocks`, matching `crypto.rg`'s `bitxor byte strings`.
Do not use `and`, `or`, `xor` or `not` as words in `fn ::` names.

## Consequences
- Requirements to update: `API-TENSOR-001`, `FR-TENSOR-001`, `DM-Tensor` (names only).
- Tests to update: `TS-TENSOR-001`, `src/test/ridgun/test tensor.rg`.
- Code to update: `src/main/ridgun/lib/tensor.rg`, book chapter 05 in all 8 editions and the generated `index.html` files.
