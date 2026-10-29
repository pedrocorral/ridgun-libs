---
id: TASK-0036
title: Signature-aware fn and op declaration and definition highlighting in fmt lib
status: completed
created: 2026-10-29
completed: 2026-10-29
requirements: [FR-FMT-001, API-FMT-001]
tests: [TS-FMT-001]
security: [VUL-INPUT-001]
context_files:
  - docs/requirements/functional/fmt/FR-FMT-001-ridgun-source-formatting-and-rich-syntax-highlighting.md
  - docs/requirements/api/fmt/API-FMT-001-fmt-module-contract.md
  - docs/tests/functional/fmt/TS-FMT-001-ridgun-source-formatting-and-rich-syntax-highlighting.md
  - src/main/ridgun/lib/fmt.rg
  - src/test/ridgun/test fmt.rg
scope:
  - src/main/ridgun/lib/fmt.rg
  - src/test/ridgun/test fmt.rg
  - docs/tests/functional/fmt/TS-FMT-001-ridgun-source-formatting-and-rich-syntax-highlighting.md
owner: agent-001
claimed: 2026-10-29T15:48
claimed_by: gemini@solarfall
---
# TASK-0036 — Signature-aware fn and op declaration and definition highlighting in fmt lib

## Goal (one sentence)
Highlight all `fn` and `op` name words (including contextual/keyword/logic words like `otherwise`, `with`, `to`, `or`, `and`, `from`, `try`, `map`, `filter`, `fold`) with the dedicated `function` declaration colour in both `fn ::` / `op ::` declarations and their `=` clause definitions using signature-aware (`2b`) slot positions, while keeping parameter type slots (`type`), bound parameter patterns (`plain`), and body invocations distinct.

## Plan
- [x] Update `src/main/ridgun/lib/fmt.rg` so signature lines (`fn ::`, `op ::`, and bare top-level signatures) highlight all non-type LHS words as `"function"` (bypassing keyword/logic classification) and parameter type slots as `"type"`.
- [x] Thread the active `FmtSig` across lines in `fmt highlight lines` so matching `=` and guard-header clause definitions highlight `fn`/`op` name slots as `"function"` and parameter pattern slots as parameter patterns (where lowercase variable bindings are `"plain"` rather than `"function"` or `"keyword"`).
- [x] Extend `src/test/ridgun/test fmt.rg` and `TS-FMT-001` to verify multi-word `fn ::` and mixfix `op ::` declarations/definitions containing `otherwise`, `with`, `to`, `or`, and `and`, and run `ridgunc`, `stable`, and `aix docs validate`.

## Progress log (append-only, newest last)
- 2026-10-29: Created and started `TASK-0036`.
- 2026-10-29: Implemented signature-aware (`2b`) declaration and clause definition highlighting in `src/main/ridgun/lib/fmt.rg` (`fmt highlight sig line`, `fmt highlight clause line`, `fmt highlight param loop`, `fmt highlight lines with sig`) and fixed `fmt count sig params` to count type tokens accurately for multi-word `fn ::` signatures.
- 2026-10-29: Added `test fmt signature aware fn and op highlighting` in `src/test/ridgun/test fmt.rg`, updated `TS-FMT-001`, rebuilt `fmt.rglib`/`libfmt.so`, and verified `ridgunc run --strict "src/test/ridgun/test fmt.rg"`, `stable check`, and `aix docs validate`.

## Files changed (keep current)
- `src/main/ridgun/lib/fmt.rg`
- `src/test/ridgun/test fmt.rg`
- `docs/tests/functional/fmt/TS-FMT-001-ridgun-source-formatting-and-rich-syntax-highlighting.md`

## Verification performed (command → result, newest last)
- `ridgunc check --strict src/main/ridgun/lib/fmt.rg` → `0 error(s)`.
- `ridgunc build --strict --so src/main/ridgun/lib/fmt.rg -o target/libfmt.so` → created `target/libfmt.so`.
- `ridgunc run --strict "src/test/ridgun/test fmt.rg"` → `[PASS] test fmt: TS-FMT-001 passed`.
- `stable check` → `Checked 33 module(s) — 0 errors`.
- `aix docs coverage && aix docs validate` → `0 errors, 0 warnings`.

## Exact next actions
1. Complete `TASK-0036` and hand off session state.

## Decisions / open questions
- User selected Option `2b` (signature-aware highlighting of `fn`/`op` name words vs parameter slots in declarations and definitions, leaving invocations unhighlighted).

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
