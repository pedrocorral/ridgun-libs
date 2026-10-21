---
id: FR-SOCK-004
title: Provide Solstice RGF-001 kernel-backed TCP and Unix socket API with status tuples and timeouts
type: functional
status: approved
priority: must
domain: SOCK
depends_on: [FR-SOCK-001, FR-SOCK-002, FR-SOCK-003]
related: [ADR-0002, VUL-INJ-002, VUL-INPUT-001]
tests: [TS-SOCK-004]
---
# FR-SOCK-004 — Provide Solstice RGF-001 kernel-backed TCP and Unix socket API with status tuples and timeouts

## Statement
The `socket` library SHALL provide the Solstice `RGF-001` TCP IPv4 (`AF_INET`) and Unix domain (`AF_UNIX`) stream socket functions (`sys_tcp_listen`, `sys_unix_listen`, `sys_local_port`, `sys_accept`, `sys_tcp_connect`, `sys_unix_connect`, `sys_recv`, `sys_send`, `sys_shutdown_write`, and `sys_close`) returning `(status, ...)` error tuples (`0` = OK, `-1` = `EOF`, `-2` = `TIMEOUT`, `-3` = `REFUSED`, `-4` = `RESET`, `-5` = `ADDR_IN_USE`, `-6` = `PERMISSION`, `-7` = `INVALID`, `-8` = `LIMIT`, `-99` = `OTHER`) with millisecond timeouts.

## Rationale
Downstream server and network applications (such as Solstice) require non-blocking, timeout-bounded Linux socket primitives using integer handles (`fd`) and canonical `(status, ...)` return tuples.

## Acceptance criteria
- AC1: Given a bind host/port (`127.0.0.1`, port `0` or explicit port) or a Unix domain socket path, when `sys_tcp_listen host port backlog` or `sys_unix_listen path backlog` is called, then it sets `SO_REUSEADDR` (for TCP), binds and listens on the endpoint, returns `(0, listener_fd)` (or `(-5, -1)` on `EADDRINUSE`, `(-6, -1)` on `EACCES`, `(-7, -1)` on invalid input), and `sys_local_port listener_fd` returns the assigned TCP port (`> 0` even when bound to port `0`).
- AC2: Given a listening TCP or Unix socket `listener_fd`, when `sys_tcp_connect host port timeout_ms` or `sys_unix_connect path timeout_ms` and `sys_accept listener_fd timeout_ms` are called, then a client connection succeeds with `(0, client_fd)` and `sys_accept` returns `(0, conn_fd, peer_str)`, while connecting to an unbound port returns `(-3, -1)` (`REFUSED`) and accepting with no pending client expires after `timeout_ms` returning `(-2, -1, "")` (`TIMEOUT`).
- AC3: Given a connected socket pair `(client_fd, conn_fd)`, when `sys_send fd data timeout_ms`, `sys_recv fd max_bytes timeout_ms`, `sys_shutdown_write fd`, and `sys_close fd` are called, then `sys_send` writes bytes and returns `(0, n_written)`, `sys_recv` reads up to `max_bytes` returning `(0, bytes)` (or `(-2, "")` on timeout, `(-1, "")` on clean EOF after `sys_shutdown_write` or `sys_close`), and `sys_close` releases the descriptor returning `0`.

## Actors & permissions
- Any Ridgun module importing `socket`.

## Constraints & edge cases
- `timeout_ms`: `-1` waits forever, `0` is non-blocking poll, `> 0` waits at most `timeout_ms` milliseconds via `sys poll` (`ppoll`).
- `sys_unix_listen` removes a stale socket path only when safe and rejects path traversal (`..`).

## Data & privacy
- Socket payloads are held in transient buffers only.

## Security & observability notes
- Mitigates `VUL-INJ-002` (Unix path validation) and `VUL-INPUT-001` (bounded `max_bytes` and `timeout_ms`).

## Out of scope
- Raw `AF_PACKET` sockets.
