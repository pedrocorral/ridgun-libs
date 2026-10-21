---
id: TASK-0005
title: Implement str.rg library and extend test.rg with RG-011 message-annotated assertions
status: pending
created: 2026-10-21
completed:
requirements: [FR-STR-001, FR-TST-001]
tests: [TS-STR-001, TS-TST-001]
security: [VUL-INPUT-001]
context_files: [docs/requirements/functional/str/FR-STR-001-string-search-trim-replace-split-and-case.md, docs/requirements/functional/tst/FR-TST-001-test-assertions-library.md, docs/requirements/api/str/API-STR-001-str-module-contract.md, docs/requirements/api/tst/API-TST-001-test-module-contract.md, docs/tests/functional/str/TS-STR-001-string-search-trim-replace-split-and-case.md, docs/tests/functional/tst/TS-TST-001-test-assertions-library.md, src/main/ridgun/lib/str.rg, src/main/ridgun/lib/test.rg, src/test/ridgun/test_str.rg, src/test/ridgun/test_test.rg]
scope: [src/main/ridgun/lib/str.rg, src/main/ridgun/lib/test.rg, src/test/ridgun/test_str.rg, src/test/ridgun/test_test.rg]
owner:
claimed:
claimed_by:
policy:
---
# TASK-0005 — Implement `str.rg` library and extend `test.rg` with `RG-011` message-annotated assertions

## Goal (one sentence)
Implement the `str` (`str.rglib`) string manipulation library and extend the `test` (`test.rglib`) assertion library with `RG-011` 3-argument `assert_equals` and 2-argument `assert_true` / `assert_false` helpers.

## Plan
- [ ] Extend `src/main/ridgun/lib/test.rg` with `assert_equals`, `assert_true`, `assert_false`, `assert_str_eq`, and non-exiting `check eq`/`check true` predicates.
- [ ] Implement `src/main/ridgun/lib/str.rg` with `str_index_of`, `str_trim`, `str_replace`, `str_split`, `str_to_upper`, `str_to_lower`, and natural-space helpers.
- [ ] Automate the string and test-assertion test suites in `src/test/ridgun/test_str.rg` and `src/test/ridgun/test_test.rg`, and verify with `stable check` and `stable test`.

## Progress log (append-only, newest last)
- 2026-10-21: Task created and planned.

## Files changed (keep current)
-

## Verification performed (command → result, newest last)
-

## Exact next actions
1. Start `TASK-0005` (`aix task start TASK-0005`) and implement `test.rg` and `str.rg`.

## Decisions / open questions
- None (`ADR-0002`).

## Definition of done checklist
- [ ] requirements referenced are `implemented`  - [ ] tests automated & green
- [ ] security entries updated  - [ ] docs INDEX updated  - [ ] coverage matrix regenerated
