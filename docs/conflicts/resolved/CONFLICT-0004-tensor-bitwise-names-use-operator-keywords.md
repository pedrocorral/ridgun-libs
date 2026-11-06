---
id: CONFLICT-0004
title: Tensor bitwise function names contain operator keywords and cannot be called
status: resolved            # open | resolved
date: 2026-11-06
affects: [API-TENSOR-001, FR-TENSOR-001, TS-TENSOR-001, DM-Tensor, src/main/ridgun/lib/tensor.rg, "src/test/ridgun/test tensor.rg", docs/book]
adr: ADR-0006
---
# CONFLICT-0004 — Tensor bitwise function names contain operator keywords and cannot be called

## Conflict
`API-TENSOR-001` names three functions `tensor xor blocks`, `tensor and blocks` and `tensor or blocks`.
The Ridgun spec (`docs/lang/spec.md`, "Contextual keywords") makes only `type` and `with` usable as words inside names; `and`, `or` and `xor` are logical operators.
`tensor.rg` declares the functions (registered as `tensor_xor_blocks`, `tensor_and_blocks`, `tensor_or_blocks`), but a spaced call such as `tensor and blocks ua ub` parses as `tensor and (blocks ua ub)`.
Strict mode (`build.rg` `strict mode = True`) forbids the underscore call form, so the functions cannot be called at all.
Commit `19fc716` (TASK-0039) changed `test tensor.rg` from the underscore calls to spaced calls, and since then `test tensor.rg` fails to compile: `undefined variable 'tensor'`, `undefined function 'blocks'`.

| Requirement says | Code / other spec does | Impact if we follow the requirement |
|---|---|---|
| `API-TENSOR-001`: `tensor xor blocks`, `tensor and blocks`, `tensor or blocks` | The language cannot call these names in strict mode | `test tensor.rg` stays broken; the three functions are unusable; the book examples (8 editions, chapter 05) do not compile |

## Options and consequences
- A. Change code to match requirement: not possible without changing the compiler (another repository) or turning off strict mode.
- B. Change requirement (ADR): rename to `tensor bitxor blocks`, `tensor bitand blocks`, `tensor bitor blocks` (matching `crypto.rg`'s `bitxor byte strings`) in `tensor.rg`, the test, API/FR/TS/DM docs and the 8 book chapters. Verified: with the rename, `test tensor.rg` passes.
- C. Split: not applicable.

## Agent recommendation
Option B.

## Human decision
Option B, chosen by the user on 2026-11-06.

## Resolution evidence (ADR, commits, tests)
- `ADR-0006-tensor-bitwise-functions-use-bit-prefixed-names.md` (accepted).
- Renamed in `tensor.rg`, `test tensor.rg`, API/FR/TS/DM docs and book chapter 05 (8 editions); `index.html` files regenerated with `docs/book/build_book.py` (rename-only diff).
- `ridgunc run "src/test/ridgun/test tensor.rg"` → `[PASS] test tensor: TS-TENSOR-001 passed`.
