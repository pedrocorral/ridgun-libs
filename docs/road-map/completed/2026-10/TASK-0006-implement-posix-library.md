---
id: TASK-0006
title: Implement posix.rg library (PollStatus, ProcStatus, descriptors, clocks, signals, CSPRNG)
status: completed
created: 2026-10-21
completed: 2026-10-21
requirements: [FR-POSIX-001, FR-POSIX-002]
tests: [TS-POSIX-001, TS-POSIX-002]
security: [VUL-INJ-002, VUL-INPUT-001]
context_files: [docs/requirements/functional/posix/FR-POSIX-001-descriptors-poll-signals-and-processes.md, docs/requirements/functional/posix/FR-POSIX-002-filesystem-clocks-signals-and-random.md, docs/requirements/data-model/DM-PosixStatus.md, docs/requirements/api/posix/API-POSIX-001-posix-module-contract.md, docs/tests/functional/posix/TS-POSIX-001-descriptors-poll-signals-and-processes.md, docs/tests/functional/posix/TS-POSIX-002-filesystem-clocks-signals-and-random.md, src/main/ridgun/lib/posix.rg, src/test/ridgun/test_posix.rg]
scope: [src/main/ridgun/lib/posix.rg, src/test/ridgun/test_posix.rg]
owner: agent-001
claimed: 2026-10-21T18:40:33Z
claimed_by: agent gemini@solarfall
---
# TASK-0006 — Implement `posix.rg` library (`PollStatus`, `ProcStatus`, descriptors, clocks, signals, CSPRNG)

## Goal (one sentence)
Implement `src/main/ridgun/lib/posix.rg` (`posix.rglib` / `libposix.so`) providing `PollStatus`, `ProcStatus`, `poll`/`sig`/`open` constants, `wait fd`, pipes, filesystem/process wrappers, monotonic clocks, signal watching, and CSPRNG random bytes (`FR-POSIX-001`, `FR-POSIX-002`, `API-POSIX-001`).

## Plan
- [x] Implement `PollStatus`, `ProcStatus`, `poll in/out/err`, `sig *`, `o *`, `wait fd`, `posix open/close/read/write/pipe/kill` in `src/main/ridgun/lib/posix.rg` (`@implements FR-POSIX-001`, `@implements API-POSIX-001`).
- [x] Implement `RG-010` filesystem/process functions, `RGF-017` clocks (`sys_time_ms`, `sys_monotonic_ms`, `sys_monotonic_ns`, `sys_sleep_ms`), `RGF-018` signals (`sys_signal_watch`, `sys_signal_wait`), and `RGF-014` `sys_random_bytes` in `src/main/ridgun/lib/posix.rg` (`@implements FR-POSIX-002`).
- [x] Automate `TS-POSIX-001` and `TS-POSIX-002` in `src/test/ridgun/test_posix.rg` and verify with `stable check` and `stable test`.

## Progress log (append-only, newest last)
- 2026-10-21: Task created and planned.
- 2026-10-21: Implemented `src/main/ridgun/lib/posix.rg` (100 functions, 2 ADTs) and automated `src/test/ridgun/test_posix.rg` (`TS-POSIX-001`, `TS-POSIX-002`). Verified with `stable check` and `stable test`.

## Files changed (keep current)
- `src/main/ridgun/lib/posix.rg`
- `src/test/ridgun/test_posix.rg`
- `docs/requirements/functional/posix/FR-POSIX-001-descriptors-poll-signals-and-processes.md`
- `docs/requirements/functional/posix/FR-POSIX-002-filesystem-clocks-signals-and-random.md`
- `docs/tests/functional/posix/TS-POSIX-001-descriptors-poll-signals-and-processes.md`
- `docs/tests/functional/posix/TS-POSIX-002-filesystem-clocks-signals-and-random.md`

## Verification performed (command → result, newest last)
- `stable format && stable check && stable test` → 5/5 modules checked (0 errors), 5/5 test suites passed (0 failures).

## Exact next actions
1. Start `TASK-0007` and implement `src/main/ridgun/lib/io.rg` and `src/test/ridgun/test_io.rg`.

## Decisions / open questions
- None (`ADR-0002`).

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
