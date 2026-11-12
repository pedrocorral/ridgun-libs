---
id: TASK-0016
title: Add real DNS resolution (/etc/hosts + UDP 53) in socket.ridgun and TCP HTTP/1.1 client in http.ridgun
status: completed
created: 2026-10-22
completed: 2026-10-22
requirements: [FR-SOCK-003, FR-SOCK-004, FR-HTTP-001, FR-POSIX-002]
tests: [TS-SOCK-003, TS-SOCK-004, TS-HTTP-001, TS-POSIX-002]
security: [VUL-INPUT-001]
context_files:
  - src/main/ridgun/lib/socket.ridgun
  - src/main/ridgun/lib/http.ridgun
  - src/test/ridgun/test socket.ridgun
  - src/test/ridgun/test http.ridgun
  - src/test/ridgun/test posix.ridgun
scope:
  - src/main/ridgun/lib/socket.ridgun
  - src/main/ridgun/lib/http.ridgun
  - src/test/ridgun/test socket.ridgun
  - src/test/ridgun/test http.ridgun
  - src/test/ridgun/test posix.ridgun
  - docs/requirements/api/sock/API-SOCK-001-socket-module-contract.md
  - docs/requirements/api/http/API-HTTP-001-http-module-contract.md
  - target/
owner: agent-001
claimed: 2026-10-22T11:50:40Z
claimed_by: agent gemini@solarfall
---
# TASK-0016 — Add real DNS resolution (/etc/hosts + UDP 53) in socket.ridgun and TCP HTTP/1.1 client in http.ridgun

## Goal (one sentence)
Implement real `/etc/hosts` + RFC 1035 UDP port 53 DNS resolution (`sys_resolve_ipv4`, `sock_resolve_host`, hostname `sys_tcp_connect`) in `socket.ridgun`, live TCP HTTP/1.1 client functions (`http_request_tcp`, `http_get`, `http_post`) in `http.ridgun`, and strengthened regression tests for real kernel fds, real `sys_kill` `SIGTERM`, and kernel wall-clock parity.

## Plan
- [x] Implement `/etc/hosts` lookup + `/etc/resolv.conf` nameserver discovery + RFC 1035 UDP DNS query (`AF_INET`, `SOCK_DGRAM` syscall 41 type 2) in `socket.ridgun` (`sys_resolve_ipv4`, `sock_resolve_host`, `sys_tcp_connect`).
- [x] Implement live TCP HTTP/1.1 client (`http_request_tcp`, `http_get`, `http_post`, and response accessors) in `http.ridgun`.
- [x] Add regression tests in `test posix.ridgun`, `test socket.ridgun`, and `test http.ridgun` verifying real kernel fds (`fcntl F_GETFD`), real `sys_kill` `SIGTERM` capture without process death, `sys_wall_time_ms` parity with `sys_call 201`, and live HTTP/1.1 over TCP.

## Progress log (append-only, newest last)
- 2026-10-22: Implemented real DNS resolution in `socket.ridgun`, TCP HTTP/1.1 client in `http.ridgun`, and regression tests in `test posix.ridgun`, `test socket.ridgun`, and `test http.ridgun`.

## Files changed (keep current)
- `src/main/ridgun/lib/socket.ridgun`
- `src/main/ridgun/lib/http.ridgun`
- `src/test/ridgun/test posix.ridgun`
- `src/test/ridgun/test socket.ridgun`
- `src/test/ridgun/test http.ridgun`
- `docs/requirements/api/sock/API-SOCK-001-socket-module-contract.md`
- `docs/requirements/api/http/API-HTTP-001-http-module-contract.md`

## Verification performed (command → result, newest last)
- `stable format && stable check && stable bundle && stable test` → 17/17 modules checked (0 errors), 17/17 test suites passed (0 failures)

## Exact next actions
1. Complete `TASK-0016`, validate AIX docs, and commit.

## Decisions / open questions
- None.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
