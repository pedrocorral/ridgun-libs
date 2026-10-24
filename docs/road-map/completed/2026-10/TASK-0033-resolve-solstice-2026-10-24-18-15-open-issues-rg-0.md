---
id: TASK-0033
title: Resolve Solstice 2026-10-24 18:15 open issues (RG-083, RG-082, RG-084, RG-062, RG-080, RG-043, RG-060) and add raw POSIX process/pipe primitives
status: completed
created: 2026-10-24
completed: 2026-10-24
requirements: [FR-STR-001, FR-CODEC-001, FR-CRYPTO-001, FR-CRYPTO-002, FR-JSON-001, FR-POSIX-001, API-STR-001, API-CODEC-001, API-CRYPTO-001, API-CRYPTO-002, API-JSON-001, API-POSIX-001]
tests: [TS-STR-001, TS-CODEC-001, TS-CRYPTO-001, TS-CRYPTO-002, TS-JSON-001, TS-POSIX-001]
security: [VUL-INPUT-001, VUL-AUTHN-001]
context_files: [docs/requirements/functional/FR-POSIX-001.md, docs/requirements/contracts/API-POSIX-001.md, docs/tests/unit/TS-POSIX-001.md, src/main/ridgun/lib/str.rg, src/main/ridgun/lib/codec.rg, src/main/ridgun/lib/crypto.rg, src/main/ridgun/lib/argon2id.rg, src/main/ridgun/lib/json.rg, src/main/ridgun/lib/posix.rg]
scope: [src/main/ridgun/lib/, src/test/ridgun/, target/bundles/, docs/requirements/, docs/tests/]
owner: agent-001
claimed: 2026-10-24T16:22:19Z
claimed_by: agent gemini@solarfall
policy:                     # a cycle for this task only (hotfix, release, ...); empty = the project's (aix policy)
---
# TASK-0033 — Resolve Solstice 2026-10-24 18:15 open issues (RG-083, RG-082, RG-084, RG-062, RG-080, RG-043, RG-060) and add raw POSIX process/pipe primitives

## Goal (one sentence)
Resolve all open Solstice issues (`RG-083`, `RG-082`, `RG-084`, `RG-062`, `RG-080`, `RG-043`, `RG-060`), expose raw Linux x86_64 kernel process/descriptor primitives (`posix fork`, `posix execve`, `posix waitpid`, `posix pipe`, `posix pipe cloexec`, `posix dup2`, `posix exit`) in `posix.rg`, and ensure all 32 libs compile cleanly under `ridgunc --strict` both individually and when imported all together.

## Plan
- [x] Rewrite `str.rg` (`RG-082`, `RG-087`) with 4-level String builder, 3-level List builder, zero-syscall `s raw byte ub`, and binary-safe slicing.
- [x] Rewrite `codec.rg` (`RG-083`, `RG-084`, `RG-080`) with tail-recursive builders, zero-syscall `cd raw byte ub`, and rename internal `json get *` helpers to `codec json get *`.
- [x] Update `argon2id.rg` and `crypto.rg` (`RG-062`, `RG-084`, `RG-043`, `RG-060`) to eliminate `sys call 290`, deduplicate `argon2id *` functions via `import argon2id`, and make byte/hex conversions tail-recursive and binary-safe.
- [x] Update `posix.rg` (`FR-POSIX-001`, `API-POSIX-001`, `TS-POSIX-001`) with raw process and pipeline primitives (`posix fork`, `posix execve`, `posix waitpid`, `posix pipe`, `posix pipe cloexec`, `posix dup2`, `posix exit`, `wnohang`, `wuntraced`, `waitpid decode status`) and eliminate `sys call 290`.
- [x] Convert all remaining libraries (`json.rg`, `btree.rg`, `csv.rg`, `diff.rg`, `fmt.rg`, `ini.rg`, `jwt.rg`, `regex.rg`, `template.rg`, `ws.rg`) to strict Ridgun syntax (`ridgunc check --strict`) and sync `target/bundles/*.rglib`.
- [x] Pass all 38 checks in `python3 tests/run.py` and `aix docs validate`.

## Progress log (append-only, newest last)
- 2026-10-24: Completed rewrites of `str.rg`, `codec.rg`, `argon2id.rg`, `crypto.rg`, `posix.rg`, and `json.rg`, and converted all 32 libraries to pass `ridgunc check --strict` individually and together.

## Files changed (keep current)
- `src/main/ridgun/lib/str.rg`, `src/main/ridgun/lib/codec.rg`, `src/main/ridgun/lib/argon2id.rg`, `src/main/ridgun/lib/crypto.rg`, `src/main/ridgun/lib/posix.rg`, `src/main/ridgun/lib/json.rg`, `src/main/ridgun/lib/btree.rg`, `src/main/ridgun/lib/csv.rg`, `src/main/ridgun/lib/diff.rg`, `src/main/ridgun/lib/fmt.rg`, `src/main/ridgun/lib/ini.rg`, `src/main/ridgun/lib/jwt.rg`, `src/main/ridgun/lib/regex.rg`, `src/main/ridgun/lib/template.rg`, `src/main/ridgun/lib/ws.rg`
- `src/test/ridgun/test posix.rg`
- `docs/requirements/functional/FR-POSIX-001.md`, `docs/requirements/contracts/API-POSIX-001.md`, `docs/tests/unit/TS-POSIX-001.md`
- `target/bundles/*.rglib`

## Verification performed (command → result, newest last)
- `ridgunc check --strict src/main/ridgun/lib/*.rg` → all 32 libraries pass with 0 errors.
- `ridgunc run "src/test/ridgun/test posix.rg"` → `[PASS] test posix: TS-POSIX-001 passed`.
- `ridgunc run "src/test/ridgun/test json.rg"` → `[PASS] test json: TS-JSON-001 (including RG-076, RG-077, RG-078) passed`.
- `python3 tests/run.py` → 38 of 38 passed.
- `aix docs validate` → 0 errors, 0 warnings.

## Exact next actions
1. Complete `TASK-0033` with `aix task done TASK-0033` and commit changes.

## Decisions / open questions
- None.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
