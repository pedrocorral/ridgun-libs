---
id: TASK-0044
title: Rename tensor bitwise functions so they can be called (CONFLICT-0004)
status: completed
created: 2026-11-06
completed: 2026-11-06
requirements: [FR-TENSOR-001, API-TENSOR-001, DM-Tensor]
tests: [TS-TENSOR-001]
security: []
context_files: [docs/requirements/decisions/ADR-0006-tensor-bitwise-functions-use-bit-prefixed-names.md, src/main/ridgun/lib/tensor.rg, "src/test/ridgun/test tensor.rg"]
scope: [src/main/ridgun/lib/tensor.rg, "src/test/ridgun/test tensor.rg", docs/requirements/**, docs/tests/**, docs/book/**, docs/conflicts/**]
owner: agent-001
claimed: 2026-11-06T21:05:16Z
claimed_by: claude claude@solarfall
policy:                     # a cycle for this task only (hotfix, release, ...); empty = the project's (aix policy)
---
# TASK-0044 — Rename tensor bitwise functions so they can be called (CONFLICT-0004)

## Goal (one sentence)
Make `test tensor.rg` compile again by renaming `tensor xor/and/or blocks`, whose operator-keyword words cannot be called in strict mode, to `tensor bitxor/bitand/bitor blocks` (`ADR-0006`).

## Plan
- [x] Find the cause: commit `19fc716` (TASK-0039) turned `tensor_and_blocks` calls into `tensor and blocks`, which parses as `tensor and (blocks ...)`.
- [x] Record `CONFLICT-0004`; user chose the rename → `ADR-0006`.
- [x] Rename in `tensor.rg`, `test tensor.rg`, API/FR/TS/DM docs and book chapter 05 (8 editions); regenerate the book HTML.
- [x] Run the tensor tests; rebuild the tensor bundle and `.so`.

## Progress log (append-only, newest last)
- 2026-11-06: Diagnosed, recorded `CONFLICT-0004`, renamed per `ADR-0006`, tests green.

## Files changed (keep current)
- `src/main/ridgun/lib/tensor.rg`, `src/test/ridgun/test tensor.rg`
- `docs/requirements/api/tensor/API-TENSOR-001-tensor-module-contract.md`, `docs/requirements/functional/tensor/FR-TENSOR-001-typed-tensor-operations-views-and-linear-algebra.md`, `docs/requirements/data-model/DM-Tensor.md`, `docs/tests/functional/tensor/TS-TENSOR-001-typed-tensor-operations-views-and-linear-algebra.md`
- `docs/book/*/05-lib-tensor-*.md` (8 editions), `docs/book/index.html`, `docs/book/*/index.html`
- `docs/requirements/decisions/ADR-0006-tensor-bitwise-functions-use-bit-prefixed-names.md`, `docs/conflicts/resolved/CONFLICT-0004-tensor-bitwise-names-use-operator-keywords.md`, INDEX files
- `build/tensor.rglib`, `target/bundles/tensor.rglib`, `target/tensor.rgc`, `target/libtensor.so`

## Verification performed (command → result, newest last)
- `ridgunc run "src/test/ridgun/test tensor.rg"` at HEAD → `undefined variable 'tensor'`, `undefined function 'blocks'`.
- `ridgunc run "src/test/ridgun/test tensor.rg"` after the rename → `[PASS] test tensor: TS-TENSOR-001 passed`.
- `python3 -I docs/book/build_book.py` → 9 HTML books regenerated; each differs from HEAD only by the rename.
- `ridgunc build --strict --so src/main/ridgun/lib/tensor.rg` → OK.

## Exact next actions
1. None; commit on user approval.

## Decisions / open questions
- `and`, `or`, `xor` and `not` must not be used as words in `fn ::` names (`ADR-0006`).

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
