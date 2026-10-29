---
id: TASK-0037
title: Remove where keyword and highlight bare fn/op declarations in fmt
status: completed
created: 2026-10-29
completed: 2026-10-29
requirements: [FR-FMT-001, API-FMT-001, DM-Formatter]
tests: [TS-FMT-001]
security: [VUL-INPUT-001]
context_files:
  - src/main/ridgun/lib/fmt.rg
  - src/test/ridgun/test fmt.rg
  - docs/tests/functional/fmt/TS-FMT-001-ridgun-source-formatting-and-rich-syntax-highlighting.md
scope:
  - src/main/ridgun/lib/fmt.rg
  - src/test/ridgun/test fmt.rg
  - docs/tests/functional/fmt/TS-FMT-001-ridgun-source-formatting-and-rich-syntax-highlighting.md
  - docs/book/build_book.py
  - docs/book/index.html
  - docs/book/*/index.html
owner: agent-001
claimed: 2026-10-29T19:45:31Z
claimed_by: agent gemini@solarfall
---
# TASK-0037 — Remove where keyword and highlight bare fn/op declarations in fmt

## Goal (one sentence)
Remove `where` from the reserved keywords in `fmt` and ensure `fn`/`op` declarations and clauses without a `fn ::` / `op ::` prefix (at any indentation, as well as single-line `fmt highlight line` calls and standalone clause definitions) highlight only the function/operator name words as `rg-fn` while keeping parameter slots plain and `with`/`to`/`from` as keywords in expressions.

## Plan
- [x] Remove `"where"` from `fmt is keyword` in `src/main/ridgun/lib/fmt.rg`.
- [x] Update `fmt parse sig tokens` and `fmt is top decl toks` so bare signatures (`swap A with B => (B, A)`, `bigger Int Int => Int`) are recognised regardless of leading indentation and whether the first token is a lowercase word or a type token.
- [x] Fix `fmt highlight line` and signature-less clause highlighting so clause parameter slots (`a`, `b` in `bigger a b = ...` or `x`, `y` in `swap x with y = ...`) are highlighted as plain parameter slots rather than `rg-fn`, and bare clauses without `fn ::` / `op ::` still highlight their function/operator name words as `rg-fn`.
- [x] Add regression tests in `src/test/ridgun/test fmt.rg` and `TS-FMT-001` for `where` removal, bare signatures/clauses at any indentation, standalone clauses, single-line `fmt highlight line`, and `with`/`to`/`from` in body expressions.
- [x] Rebuild `fmt.rglib`, `fmt.rgc`, `libfmt.so`, sync `/home/gemini/.local/lib/ridgun/fmt.rglib`, and update `docs/book/build_book.py`.

## Progress log (append-only, newest last)
- 2026-10-29: Created and started TASK-0037 to address user feedback and `/tmp/ridgun-lib/requirements/2026-10-29-fmt-declarations-without-prefix.md`.
- 2026-10-29: Removed `"where"` from `fmt is keyword` in `src/main/ridgun/lib/fmt.rg`, allowed bare signatures without `fn ::` / `op ::` at any indentation, fixed `fmt highlight line` and signature-less clause highlighting so parameter slots remain plain while function/operator words receive `rg-fn`, synced `/home/gemini/.local/lib/ridgun/fmt.rglib`, updated `docs/book/build_book.py`, and verified `TS-FMT-001`.

## Files changed (keep current)
- `src/main/ridgun/lib/fmt.rg`
- `src/test/ridgun/test fmt.rg`
- `docs/tests/functional/fmt/TS-FMT-001-ridgun-source-formatting-and-rich-syntax-highlighting.md`
- `docs/book/build_book.py`
- `docs/book/index.html` and `docs/book/*/index.html`
- `target/bundles/fmt.rglib`, `target/fmt.rgc`, `build/fmt.rglib`, `target/libfmt.so`, `/home/gemini/.local/lib/ridgun/fmt.rglib`

## Verification performed (command → result, newest last)
- `ridgunc check --strict src/main/ridgun/lib/fmt.rg` → 200 functions, 7 types, 0 errors.
- `ridgunc run --strict "src/test/ridgun/test fmt.rg"` → `[PASS] test fmt: TS-FMT-001 passed`.
- `aix docs coverage && aix docs validate` → 0 errors, 0 warnings.

## Exact next actions
1. Complete `TASK-0037`.

## Decisions / open questions
- None.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
