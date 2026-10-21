---
id: TASK-0011
title: Implement math.rg, list.rg, codec.rg, and cli.rg standard libraries with test suites and bundles
status: completed
created: 2026-10-21
completed: 2026-10-21
requirements: [FR-MATH-001, FR-LIST-001, FR-CODEC-001, FR-CLI-001, NFR-SEC-001]
tests: [TS-MATH-001, TS-LIST-001, TS-CODEC-001, TS-CLI-001]
security: [VUL-INPUT-001]
context_files: [build.rg, src/main/ridgun/lib/math.rg, src/main/ridgun/lib/list.rg, src/main/ridgun/lib/codec.rg, src/main/ridgun/lib/cli.rg, src/test/ridgun/test_math.rg, src/test/ridgun/test_list.rg, src/test/ridgun/test_codec.rg, src/test/ridgun/test_cli.rg]
scope: [build.rg, src/main/ridgun/lib/math.rg, src/main/ridgun/lib/list.rg, src/main/ridgun/lib/codec.rg, src/main/ridgun/lib/cli.rg, src/test/ridgun/test_math.rg, src/test/ridgun/test_list.rg, src/test/ridgun/test_codec.rg, src/test/ridgun/test_cli.rg, docs/requirements/functional/math/, docs/requirements/functional/list/, docs/requirements/functional/codec/, docs/requirements/functional/cli/, docs/requirements/api/math/, docs/requirements/api/list/, docs/requirements/api/codec/, docs/requirements/api/cli/, docs/tests/functional/math/, docs/tests/functional/list/, docs/tests/functional/codec/, docs/tests/functional/cli/]
owner: agent-001
claimed: 2026-10-21T20:27:25Z
claimed_by: agent gemini@solarfall
---
# TASK-0011 — Implement `math.rg`, `list.rg`, `codec.rg`, and `cli.rg` standard libraries with test suites and bundles

## Goal (one sentence)
Specify, implement, test, and bundle four foundational pure-Ridgun standard libraries (`math.rg`, `list.rg`, `codec.rg`, and `cli.rg`) with full AIX traceability (`FR-*`, `API-*`, `TS-*`).

## Plan
- [x] Author functional requirements (`FR-MATH-001`, `FR-LIST-001`, `FR-CODEC-001`, `FR-CLI-001`), API contracts (`API-MATH-001`, `API-LIST-001`, `API-CODEC-001`, `API-CLI-001`), and test specifications (`TS-MATH-001`, `TS-LIST-001`, `TS-CODEC-001`, `TS-CLI-001`).
- [x] Implement `src/main/ridgun/lib/math.rg` (bounds, parity, Euclidean/floor/ceil division, powers, roots, logarithms, GCD/LCM, `mod_pow`, `mod_inv`, primality, combinatorics, and list statistics).
- [x] Implement `src/main/ridgun/lib/list.rg` (list indexing, slicing, reversal, range generation, search, deduplication, $O(N \log N)$ mergesort, and associative `[(String, String)]` key-value map utilities).
- [x] Implement `src/main/ridgun/lib/codec.rg` (RFC 4648 Hex, Base64, Base64url, RFC 3986 URL percent-encoding and query strings, and RFC 8259 JSON formatting, escaping, and field extraction).
- [x] Implement `src/main/ridgun/lib/cli.rg` (CLI flag, bundled short-flag, `--key=val` / `--key val` option, `--` end-of-options, positional/subcommand parser, and typed environment variable readers).
- [x] Automate `src/test/ridgun/test_math.rg`, `src/test/ridgun/test_list.rg`, `src/test/ridgun/test_codec.rg`, and `src/test/ridgun/test_cli.rg`, update `build.rg`, and verify `11/11` modules and test suites pass.

## Progress log (append-only, newest last)
- 2026-10-21: Created `FR-MATH-001`, `FR-LIST-001`, `FR-CODEC-001`, `FR-CLI-001`, `API-*`, and `TS-*` specifications.
- 2026-10-21: Implemented `math.rg`, `list.rg`, `codec.rg`, and `cli.rg` plus `test_math.rg`, `test_list.rg`, `test_codec.rg`, and `test_cli.rg`.
- 2026-10-21: Verified `stable format && stable check && stable bundle && stable test` (`11/11` modules checked with `0` errors, `11/11` test suites passed with `0` failures).

## Files changed (keep current)
- `build.rg`
- `src/main/ridgun/lib/math.rg`
- `src/main/ridgun/lib/list.rg`
- `src/main/ridgun/lib/codec.rg`
- `src/main/ridgun/lib/cli.rg`
- `src/test/ridgun/test_math.rg`
- `src/test/ridgun/test_list.rg`
- `src/test/ridgun/test_codec.rg`
- `src/test/ridgun/test_cli.rg`
- `docs/requirements/product/glossary.md`
- `docs/requirements/product/vision.md`
- `docs/requirements/functional/{math,list,codec,cli}/*`
- `docs/requirements/api/{math,list,codec,cli}/*`
- `docs/tests/functional/{math,list,codec,cli}/*`

## Verification performed (command → result, newest last)
- `stable format && stable check && stable bundle && stable test` → `Checked 11 module(s) — 0 errors; Passed 11/11 test suite(s) — 0 failures.`
- `aix docs coverage && aix docs validate` → `0 errors, 0 warnings`

## Exact next actions
1. Task complete.

## Decisions / open questions
- None.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
