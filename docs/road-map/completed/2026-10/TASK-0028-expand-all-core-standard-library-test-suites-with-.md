---
id: TASK-0028
title: Expand all core standard library test suites with reference vectors and boundary tests
status: completed
created: 2026-10-24
completed: 2026-10-24
requirements: [FR-GLOB-001, FR-LOG-001, FR-CLI-001, FR-PATH-001, FR-UUID-001, FR-TIME-001, FR-STR-001, FR-LIST-001]
tests: [TS-GLOB-001, TS-LOG-001, TS-CLI-001, TS-PATH-001, TS-UUID-001, TS-TIME-001, TS-STR-001, TS-LIST-001]
security: [VUL-INPUT-001, VUL-INJ-002]
context_files:
  - docs/tests/coverage-matrix.md
scope:
  - src/test/ridgun/test glob.rg
  - src/test/ridgun/test log.rg
  - src/test/ridgun/test cli.rg
  - src/test/ridgun/test path.rg
  - src/test/ridgun/test uuid.rg
  - src/test/ridgun/test time.rg
  - src/test/ridgun/test str.rg
  - src/test/ridgun/test list.rg
owner: agent-001
claimed: 2026-10-24T08:17:36Z
claimed_by: agent gemini@solarfall
---
# TASK-0028 — Expand all core standard library test suites with reference vectors and boundary tests

## Goal (one sentence)
Expand the older/shorter standard library test suites (`test glob.rg`, `test log.rg`, `test cli.rg`, `test path.rg`, `test uuid.rg`, `test time.rg`, `test str.rg`, `test list.rg`) with RFC/POSIX/reference test vectors, boundary conditions, and adversarial inputs, and execute all 30 test suites end-to-end.
## Plan
- [x] Expand `test glob.rg` with POSIX `fnmatch` / Go `filepath.Match` boundary cases, multi-range classes, and pathological `****` backtracking checks.
- [x] Expand `test log.rg` with Rust `tracing` / OWASP log-injection (`\n`, `\r`, `\t`, `\\`, `\"`) and secret-key redaction vectors.
- [x] Expand `test cli.rg` with POSIX `getopt` / `clap` bundled short flags, `-k=val`, `--empty=`, `-` stdin positional, and `--` separator vectors.
- [x] Expand `test path.rg` with Go `path.Clean` canonical test table, `path_split`, multi-dot extensions, and OWASP path-traversal/shell-metacharacter vectors.
- [x] Expand `test uuid.rg` with RFC 9562 UUIDv4/UUIDv7 ordering/variant checks and official FNV-1a, RFC 1950 Adler-32, and IEEE 802.3 CRC-32 vectors.
- [x] Expand `test time.rg` with Gregorian 4/100/400 century leap-year vectors, Y2038 / billennium milestones, and invalid calendar date rejection.
- [x] Expand `test str.rg` and `test list.rg` with boundary slicing, prefix-sharing mergesort, and empty/degenerate cases.
- [x] Verify all 32 modules (`stable check`) and all 30 test suites (`ridgunc run`).
## Progress log (append-only, newest last)
- 2026-10-24: Expanded `test glob.rg`, `test log.rg`, `test cli.rg`, `test path.rg`, `test uuid.rg`, `test time.rg`, `test str.rg`, and `test list.rg`; verified `stable check` (32/32 modules, 0 errors) and all 30 test suites.
## Files changed (keep current)
- `src/test/ridgun/test glob.rg`
- `src/test/ridgun/test log.rg`
- `src/test/ridgun/test cli.rg`
- `src/test/ridgun/test path.rg`
- `src/test/ridgun/test uuid.rg`
- `src/test/ridgun/test time.rg`
- `src/test/ridgun/test str.rg`
- `src/test/ridgun/test list.rg`
## Verification performed (command → result, newest last)
- `stable check` → `Checked 32 module(s) — 0 errors.`
- `ridgunc run src/test/ridgun/test *.rg` → `30/30 test suites [PASS]`
## Exact next actions
1. Mark `TASK-0028` done and commit.
## Decisions / open questions
- None.
## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
