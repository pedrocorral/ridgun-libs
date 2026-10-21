---
id: TASK-0006
title: Implement posix.rg library (PollStatus, ProcStatus, descriptors, clocks, signals, CSPRNG)
status: pending
created: 2026-10-21
completed:
requirements: [FR-POSIX-001, FR-POSIX-002]
tests: [TS-POSIX-001, TS-POSIX-002]
security: [VUL-INJ-002, VUL-INPUT-001]
context_files: [docs/requirements/functional/posix/FR-POSIX-001-descriptors-poll-signals-and-processes.md, docs/requirements/functional/posix/FR-POSIX-002-filesystem-clocks-signals-and-random.md, docs/requirements/data-model/DM-PosixStatus.md, docs/requirements/api/posix/API-POSIX-001-posix-module-contract.md, docs/tests/functional/posix/TS-POSIX-001-descriptors-poll-signals-and-processes.md, docs/tests/functional/posix/TS-POSIX-002-filesystem-clocks-signals-and-random.md, src/main/ridgun/lib/posix.rg, src/test/ridgun/test_posix.rg]
scope: [src/main/ridgun/lib/posix.rg, src/test/ridgun/test_posix.rg]
owner:
claimed:
claimed_by:
policy:
---
# TASK-0006 — Implement `posix.rg` library (`PollStatus`, `ProcStatus`, descriptors, clocks, signals, CSPRNG)

## Goal (one sentence)
Implement `src/main/ridgun/lib/posix.rg` (`posix.rglib` / `libposix.so`) providing `PollStatus`, `ProcStatus`, `poll`/`sig`/`open` constants, `wait fd`, pipes, filesystem/process wrappers, monotonic clocks, signal watching, and CSPRNG random bytes (`FR-POSIX-001`, `FR-POSIX-002`, `API-POSIX-001`).

## Plan
- [ ] Implement `PollStatus`, `ProcStatus`, `poll in/out/err`, `sig *`, `o *`, `wait fd`, `posix open/close/read/write/pipe/kill` in `src/main/ridgun/lib/posix.rg` (`@implements FR-POSIX-001`, `@implements API-POSIX-001`).
- [ ] Implement `RG-010` filesystem/process functions, `RGF-017` clocks (`sys_time_ms`, `sys_monotonic_ms`, `sys_monotonic_ns`, `sys_sleep_ms`), `RGF-018` signals (`sys_signal_watch`, `sys_signal_wait`), and `RGF-014` `sys_random_bytes` in `src/main/ridgun/lib/posix.rg` (`@implements FR-POSIX-002`).
- [ ] Automate `TS-POSIX-001` and `TS-POSIX-002` in `src/test/ridgun/test_posix.rg` and verify with `stable check` and `stable test`.

## Progress log (append-only, newest last)
- 2026-10-21: Task created and planned.

## Files changed (keep current)
-

## Verification performed (command → result, newest last)
-

## Exact next actions
1. Start `TASK-0006` after `TASK-0005` and implement `posix.rg` and `test_posix.rg`.

## Decisions / open questions
- None (`ADR-0002`).

## Definition of done checklist
- [ ] requirements referenced are `implemented`  - [ ] tests automated & green
- [ ] security entries updated  - [ ] docs INDEX updated  - [ ] coverage matrix regenerated
