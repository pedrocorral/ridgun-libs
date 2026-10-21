---
id: TASK-0009
title: Extend socket.rg with Solstice RGF-001 kernel-backed socket API and build all 7 .rglib/.so bundles
status: pending
created: 2026-10-21
completed:
requirements: [FR-SOCK-004, NFR-SEC-001]
tests: [TS-SOCK-004, TS-SEC-001]
security: [VUL-INJ-002, VUL-AUTHN-001, VUL-INPUT-001]
context_files: [docs/requirements/functional/sock/FR-SOCK-004-solstice-rgf001-kernel-sockets.md, docs/requirements/non-functional/NFR-SEC-001-baseline.md, docs/requirements/data-model/DM-Socket.md, docs/requirements/api/sock/API-SOCK-001-socket-module-contract.md, docs/tests/functional/sock/TS-SOCK-004-solstice-rgf001-kernel-sockets.md, docs/tests/non-functional/sec/TS-SEC-001-baseline.md, build.rg, src/main/ridgun/lib/socket.rg, src/test/ridgun/test_socket.rg]
scope: [build.rg, src/main/ridgun/lib/socket.rg, src/test/ridgun/test_socket.rg, docs/security/audits/AUDIT-2026-10-21-libs.md, docs/security/vulnerability-register.md]
owner:
claimed:
claimed_by:
policy:
---
# TASK-0009 — Extend `socket.rg` with Solstice `RGF-001` kernel-backed socket API and build all 7 `.rglib`/`.so` bundles

## Goal (one sentence)
Extend `src/main/ridgun/lib/socket.rg` with the Solstice `RGF-001` kernel-backed socket functions (`sys_tcp_listen`, `sys_unix_listen`, `sys_local_port`, `sys_accept`, `sys_tcp_connect`, `sys_unix_connect`, `sys_recv`, `sys_send`, `sys_shutdown_write`, `sys_close`), build all 7 libraries into `.rgc`, `.so`, and `.rglib` artifacts via `stable`, and complete the security and coverage audit.

## Plan
- [ ] Extend `src/main/ridgun/lib/socket.rg` with `RGF-001` status-tuple functions (`@implements FR-SOCK-004`, `@implements API-SOCK-001`).
- [ ] Automate `TS-SOCK-004` in `src/test/ridgun/test_socket.rg`.
- [ ] Update `build.rg` library packaging to compile all 7 modules (`socket`, `argon2id`, `crypto`, `posix`, `io`, `str`, `test`) into `.rgc`, `.so`, and `.rglib` artifacts, run `stable check && stable test`, update `AUDIT-2026-10-21-libs.md`, and run `aix docs validate && aix docs coverage`.

## Progress log (append-only, newest last)
- 2026-10-21: Task created and planned.

## Files changed (keep current)
-

## Verification performed (command → result, newest last)
-

## Exact next actions
1. Start `TASK-0009` after `TASK-0008`, implement `FR-SOCK-004`, build all 7 library bundles, and close out verification.

## Decisions / open questions
- None (`ADR-0002`).

## Definition of done checklist
- [ ] requirements referenced are `implemented`  - [ ] tests automated & green
- [ ] security entries updated  - [ ] docs INDEX updated  - [ ] coverage matrix regenerated
