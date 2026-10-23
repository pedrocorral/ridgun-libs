---
id: TASK-0014
title: Fix socket /tmp multi-user fd collision and posix sys_wall_time_ms real kernel epoch clock
status: completed
created: 2026-10-22
completed: 2026-10-22
requirements: [FR-SOCK-004, API-SOCK-001, FR-POSIX-002, API-POSIX-001]
tests: [TS-SOCK-004, TS-POSIX-002]
security: [VUL-INPUT-001]
context_files:
  - src/main/ridgun/lib/socket.rg
  - src/main/ridgun/lib/posix.rg
  - src/main/ridgun/lib/crypto.rg
  - src/main/ridgun/lib/uuid.rg
  - src/test/ridgun/test posix.rg
  - README.md
scope:
  - src/main/ridgun/lib/socket.rg
  - src/main/ridgun/lib/posix.rg
  - src/main/ridgun/lib/crypto.rg
  - src/main/ridgun/lib/uuid.rg
  - src/test/ridgun/test posix.rg
  - README.md
owner: agent-001
claimed: 2026-10-22T09:00:18Z
claimed_by: agent gemini@solarfall
policy:                     # a cycle for this task only
---
# TASK-0014 — Fix socket /tmp multi-user fd collision and posix sys_wall_time_ms real kernel epoch clock

## Goal (one sentence)
Eliminate `/tmp` sticky-bit multi-user descriptor file collisions in `socket.rg` (by scoping descriptor files with `{pid}_{fd}` and listener registries with `{uid}`) and replace the hardcoded 2025 base in `posix.rg` (`sys_wall_time_ms`) with real Linux kernel epoch seconds (`sys_call 201` `__NR_time`) calibrated against monotonic `sys_time_ms`.

## Plan
- [x] Namespace `socket.rg` descriptor files in `/tmp` by `{pid}_{fd}` and listener files by `{uid}` (`sys_getuid`), and export tuple accessor helpers (`sock_rc`, `sock_fd`, `sock_accept_fd`, `sock_recv_data`).
- [x] Update `sys_wall_time_ms` in `posix.rg` and `uuid_v7` in `uuid.rg` to query real kernel wall-clock epoch time (`sys_call 201 0 0 0 0 0 0`) instead of the hardcoded October 2025 constant (`1761070000000`).
- [x] Rebuild `.rglib`, `.rgc`, and `.so` bundles and verify all 17 test suites pass.

## Progress log (append-only, newest last)
- 2026-10-22: Namespaced `/tmp/rg_sock_fd_{pid}_{fd}.*` and `/tmp/rg_sock_tcp_{uid}_{port}.*` in `socket.rg`, updated `sys_wall_time_ms` in `posix.rg` to calibrate against Linux syscall `201` (`__NR_time`), rebuilt bundles, and verified `17/17` test suites pass.

## Files changed (keep current)
- `src/main/ridgun/lib/socket.rg`
- `src/main/ridgun/lib/posix.rg`
- `src/main/ridgun/lib/crypto.rg`
- `src/main/ridgun/lib/uuid.rg`
- `src/test/ridgun/test posix.rg`
- `README.md`

## Verification performed (command → result, newest last)
- `stable check` → `Checked 17 module(s) — 0 errors.`
- `stable test` → `Passed 17/17 test suite(s) — 0 failures.`

## Exact next actions
1. Complete `TASK-0014` and commit.

## Decisions / open questions
- None.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
