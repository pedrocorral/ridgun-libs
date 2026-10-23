---
id: TASK-0009
title: Extend socket.rg with Solstice RGF-001 kernel-backed socket API and build all 7 .rglib/.so bundles
status: completed
created: 2026-10-21
completed: 2026-10-21
requirements: [FR-SOCK-004, NFR-SEC-001]
tests: [TS-SOCK-004, TS-SEC-001]
security: [VUL-INJ-002, VUL-AUTHN-001, VUL-INPUT-001]
context_files: [docs/requirements/functional/sock/FR-SOCK-004-solstice-rgf001-kernel-sockets.md, docs/requirements/non-functional/NFR-SEC-001-baseline.md, docs/requirements/data-model/DM-Socket.md, docs/requirements/api/sock/API-SOCK-001-socket-module-contract.md, docs/tests/functional/sock/TS-SOCK-004-solstice-rgf001-kernel-sockets.md, docs/tests/non-functional/sec/TS-SEC-001-baseline.md, build.rg, src/main/ridgun/lib/socket.rg, src/test/ridgun/test socket.rg]
scope: [build.rg, src/main/ridgun/lib/socket.rg, src/test/ridgun/test socket.rg, docs/security/audits/AUDIT-2026-10-21-libs.md, docs/security/vulnerability-register.md]
owner: agent-001
claimed: 2026-10-21T19:39:25Z
claimed_by: agent gemini@solarfall
---
# TASK-0009 — Extend `socket.rg` with Solstice `RGF-001` kernel-backed socket API and build all 7 `.rglib`/`.so` bundles

## Goal (one sentence)
Extend `src/main/ridgun/lib/socket.rg` with the Solstice `RGF-001` kernel-backed socket functions (`sys_tcp_listen`, `sys_unix_listen`, `sys_local_port`, `sys_accept`, `sys_tcp_connect`, `sys_unix_connect`, `sys_recv`, `sys_send`, `sys_shutdown_write`, `sys_close`), build all 7 libraries into `.rgc`, `.so`, and `.rglib` artifacts via `stable`, and complete the security and coverage audit.

## Plan
- [x] Extend `src/main/ridgun/lib/socket.rg` with `RGF-001` status-tuple functions (`@implements FR-SOCK-004`, `@implements API-SOCK-001`).
- [x] Automate `TS-SOCK-004` in `src/test/ridgun/test socket.rg`.
- [x] Update `build.rg` library packaging to compile all 7 modules (`socket`, `argon2id`, `crypto`, `posix`, `io`, `str`, `test`) into `.rgc`, `.so`, and `.rglib` artifacts, run `stable check && stable test`, update `AUDIT-2026-10-21-libs.md`, and run `aix docs validate && aix docs coverage`.

## Progress log (append-only, newest last)
- 2026-10-21: Task created and planned.
- 2026-10-21: Implemented `RGF-001` TCP/Unix descriptor socket API (`sys_tcp_listen`, `sys_unix_listen`, `sys_local_port`, `sys_accept`, `sys_tcp_connect`, `sys_unix_connect`, `sys_recv`, `sys_send`, `sys_shutdown_write`) in `src/main/ridgun/lib/socket.rg`, automated `TS-SOCK-004` in `src/test/ridgun/test socket.rg`, added `task bundle` in `build.rg`, and compiled all 7 libraries into `.rgc`, `.so`, and `.rglib` bundles.

## Files changed (keep current)
- `build.rg`
- `src/main/ridgun/lib/socket.rg`
- `src/test/ridgun/test socket.rg`
- `docs/security/audits/AUDIT-2026-10-21-libs.md`

## Verification performed (command → result, newest last)
- `stable format && stable check && stable test` → `Checked 7 module(s) — 0 errors; Passed 7/7 test suite(s) — 0 failures.`
- `stable bundle` → `Built .rglib, .rgc, and .so artifacts for socket, argon2id, crypto, posix, io, str, and test.`

## Exact next actions
1. All planned tasks (`TASK-0001`..`TASK-0009`) are complete.

## Decisions / open questions
- None (`ADR-0002`).

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
