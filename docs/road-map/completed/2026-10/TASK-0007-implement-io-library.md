---
id: TASK-0007
title: Implement io.rg library (IoError, IoResult, timeout descriptor ops, file metadata, streams)
status: completed
created: 2026-10-21
completed: 2026-10-21
requirements: [FR-IO-001, FR-IO-002, NFR-PERF-001]
tests: [TS-IO-001, TS-IO-002, TS-PERF-001]
security: [VUL-INJ-002, VUL-INPUT-001]
context_files: [docs/requirements/functional/io/FR-IO-001-io-error-types-and-timeout-descriptor-ops.md, docs/requirements/functional/io/FR-IO-002-file-predicates-metadata-and-streams.md, docs/requirements/non-functional/NFR-PERF-001-crypto-and-io-latency.md, docs/requirements/data-model/DM-IoResult.md, docs/requirements/api/io/API-IO-001-io-module-contract.md, docs/tests/functional/io/TS-IO-001-io-error-types-and-timeout-descriptor-ops.md, docs/tests/functional/io/TS-IO-002-file-predicates-metadata-and-streams.md, docs/tests/non-functional/perf/TS-PERF-001-argon2id-and-poll-timeout-bounds.md, src/main/ridgun/lib/posix.rg, src/main/ridgun/lib/io.rg, src/test/ridgun/test io.rg]
scope: [src/main/ridgun/lib/io.rg, src/test/ridgun/test io.rg]
owner: agent-001
claimed: 2026-10-21T18:51:25Z
claimed_by: agent gemini@solarfall
---
# TASK-0007 — Implement `io.rg` library (`IoError`, `IoResult`, timeout descriptor ops, file metadata, streams)

## Goal (one sentence)
Implement `src/main/ridgun/lib/io.rg` (`io.rglib` / `libio.so`) on top of `posix.rg` with extensible `IoError` and `IoResult` types, `format io error`, timeout-guarded `read fd`, `write fd`, `io exec timeout`, `RG-010` file predicates (`is_symlink`, `file_mtime`, `append_file`), and line-stream helpers (`FR-IO-001`, `FR-IO-002`, `API-IO-001`).

## Plan
- [x] Implement `IoError`, `IoResult`, `format io error`, `read fd`, `read fd after poll`, `write fd`, `write fd after poll`, and `io exec timeout` in `src/main/ridgun/lib/io.rg` (`@implements FR-IO-001`, `@implements API-IO-001`, `@implements NFR-PERF-001`).
- [x] Implement `RG-010` file helpers (`read_file`, `write_file`, `append_file`, `file_exists`, `is_dir`, `is_file`, `is_symlink`, `file_size`, `file_mtime`, `file_mode`, `io read file safe`, `io read lines`, `io write lines`) in `src/main/ridgun/lib/io.rg` (`@implements FR-IO-002`).
- [x] Automate `TS-IO-001`, `TS-IO-002`, and the poll-timeout portion of `TS-PERF-001` in `src/test/ridgun/test io.rg`, and verify with `stable check` and `stable test`.

## Progress log (append-only, newest last)
- 2026-10-21: Task created and planned.
- 2026-10-21: Implemented `src/main/ridgun/lib/io.rg` (106 functions, 4 types) and automated `src/test/ridgun/test io.rg` (`TS-IO-001`, `TS-IO-002`, `TS-PERF-001`). Verified with `stable check` and `stable test`.

## Files changed (keep current)
- `src/main/ridgun/lib/io.rg`
- `src/main/ridgun/lib/posix.rg`
- `src/test/ridgun/test io.rg`
- `docs/requirements/functional/io/FR-IO-001-io-error-types-and-timeout-descriptor-ops.md`
- `docs/requirements/functional/io/FR-IO-002-file-predicates-metadata-and-streams.md`
- `docs/tests/functional/io/TS-IO-001-io-error-types-and-timeout-descriptor-ops.md`
- `docs/tests/functional/io/TS-IO-002-file-predicates-metadata-and-streams.md`

## Verification performed (command → result, newest last)
- `stable format && stable check && stable test` → 6/6 modules checked (0 errors), 6/6 test suites passed (0 failures).

## Exact next actions
1. Start `TASK-0008` and implement `src/main/ridgun/lib/crypto.rg`, extend `src/main/ridgun/lib/argon2id.rg`, and automate `src/test/ridgun/test crypto.rg`.

## Decisions / open questions
- None (`ADR-0002`).

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
