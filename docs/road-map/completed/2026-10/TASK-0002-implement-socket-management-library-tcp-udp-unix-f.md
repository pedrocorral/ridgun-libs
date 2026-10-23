---
id: TASK-0002
title: Implement socket management library (TCP, UDP, Unix, framing)
status: completed
created: 2026-10-21
completed: 2026-10-21
requirements: [FR-SOCK-001, FR-SOCK-002]
tests: [TS-SOCK-001, TS-SOCK-002]
security: [VUL-INJ-002, VUL-INPUT-001]
context_files: [build.rg, docs/requirements/functional/sock/FR-SOCK-001-socket-address-and-lifecycle.md, docs/requirements/functional/sock/FR-SOCK-002-socket-data-transfer-and-framing.md, docs/tests/functional/sock/TS-SOCK-001-socket-address-and-lifecycle.md, docs/tests/functional/sock/TS-SOCK-002-socket-data-transfer-and-framing.md, src/main/ridgun/lib/socket.rg, src/test/ridgun/test socket.rg]
owner: agent-001
claimed: 2026-10-21T16:11:52Z
claimed_by: agent gemini@solarfall
---
# TASK-0002 — Implement socket management library (TCP, UDP, Unix, framing)

## Goal (one sentence)
Implement `src/main/ridgun/lib/socket.rg` and `src/test/ridgun/test socket.rg` covering `FR-SOCK-001` and `FR-SOCK-002` (`TS-SOCK-001`, `TS-SOCK-002`).

## Plan
- [x] Implement IPv4, IPv6, and Unix domain address parsing and strict validation (`FR-SOCK-001` AC1, `@mitigates VUL-INJ-002`, `@mitigates VUL-INPUT-001`).
- [x] Implement socket creation (`sock tcp`, `sock tcp6`, `sock udp`, `sock udp6`, `sock unix stream`, `sock unix dgram`), options/timeouts, and `bind`/`listen`/`accept`/`connect`/`close` (`FR-SOCK-001` AC2, AC3).
- [x] Implement byte/string send and receive, datagram `send to`/`recv from`, and 4-byte length-prefixed & line-delimited framing (`FR-SOCK-002` AC1, AC2, AC3).
- [x] Write automated tests in `src/test/ridgun/test socket.rg` (`@tests TS-SOCK-001`, `@tests TS-SOCK-002`) and verify with `stable check` and `stable test`.

## Progress log (append-only, newest last)
- 2026-10-21: created task.
- 2026-10-21: implemented `src/main/ridgun/lib/socket.rg`, `src/main/ridgun/lib/test.rg`, and `src/test/ridgun/test socket.rg`; `stable check` and `stable test` passed (0 errors, 1/1 suite passed).

## Decisions / open questions
- Avoided using logical operator keywords (`or`, `and`, `not`, `xor`) as words in multi-word `fn ::` declarations and ensured distinct record field indices.

## Definition of done checklist
- [x] `stable check` & `stable test` green  - [x] `@implements`/`@tests`/`@mitigates` markers in place  - [x] `aix docs validate` 0 errors
