---
id: TS-SOCK-004
title: Verify Solstice RGF-001 kernel-backed TCP and Unix socket API, status tuples, and timeouts
level: unit
covers: [FR-SOCK-004, API-SOCK-001]
status: automated
automated_in: [src/test/ridgun/test socket.rg]
---
# TS-SOCK-004 — Verify Solstice RGF-001 kernel-backed TCP and Unix socket API, status tuples, and timeouts

## Preconditions / fixtures
- Pure-Ridgun `socket` module (`src/main/ridgun/lib/socket.rg`).

## Steps / inputs
1. Call `sys_tcp_listen "127.0.0.1" 0 16` and `sys_local_port lfd`; verify `status == 0`, `lfd >= 0`, and `port > 0`. Also call `sys_tcp_listen_reuseport "127.0.0.1" port 16` on two descriptors on the same port and verify both bind/listen with `status == 0` (`SO_REUSEPORT`). Call `sys_unix_listen "/tmp/rg_sock_rgf001.sock" 8` and verify `status == 0`.
2. Call `sys_accept lfd 50` with no client connecting and verify it returns `(-2, -1, "")` (`TIMEOUT`). Call `sys_tcp_connect "127.0.0.1" 1 200` on an unused port and verify it returns `(-3, -1)` (`REFUSED`).
3. Connect to `port` via `sys_tcp_connect "127.0.0.1" port 1000`, accept via `sys_accept lfd 1000`, send `"ping\n"` via `sys_send cfd "ping\n" 1000`, receive via `sys_recv sfd 64 1000`, call `sys_shutdown_write cfd`, verify `sys_recv sfd 64 1000` returns `(-1, "")` (`EOF`), and close all descriptors via `sys_close`. Also send an 8 MiB payload with `sys_send cfd big_payload 1000` while the peer does not read (`RG-049`) and verify it times out in ~1000 ms returning `(-2, bytes_sent_so_far)`. Repeat over `AF_UNIX` (`sys_unix_connect`).

## Expected results (map to acceptance criteria)
- AC1 → `sys_tcp_listen` and `sys_unix_listen` return `(0, lfd)` and `sys_local_port lfd` returns the ephemeral port `> 0`.
- AC2 → `sys_accept` with no client times out with `(-2, -1, "")`; `sys_tcp_connect` on a closed port returns `(-3, -1)`; valid TCP and Unix connects return `(0, cfd)` and `(0, sfd, peer)`.
- AC3 → `sys_send` and `sys_recv` exchange exact bytes, `sys_shutdown_write` causes peer `sys_recv` to return `(-1, "")` (`EOF`), and `sys_close` returns `0`.

## Not covered here (to avoid duplication)
- see `TS-SOCK-001`..`TS-SOCK-003` for `SockAddr` record API, framing, DNS hostnames, and CIDR matching.
