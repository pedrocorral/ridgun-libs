---
id: TS-SOCK-001
title: Verify socket address validation, options, and TCP/UDP/Unix lifecycle
level: unit
covers: [FR-SOCK-001]
status: automated
automated_in: [src/test/ridgun/test_socket.rg]
---
# TS-SOCK-001 — Verify socket address validation, options, and TCP/UDP/Unix lifecycle

## Preconditions / fixtures
- Pure-Ridgun `socket` module (`src/main/ridgun/lib/socket.rg`).

## Steps / inputs
1. Parse and construct IPv4 (`127.0.0.1:8080`), IPv6 (`[::1]:9090`), and Unix domain (`/tmp/rg_sock_test.sock`) addresses; pass invalid octets (`999.0.0.1`), invalid ports (`0`, `70000`), and unsafe Unix paths (`../bad`, `/tmp/a;b`).
2. Create TCP, TCP6, UDP, UDP6, Unix stream, and Unix datagram sockets; apply valid socket options (`reuse_addr: True`, `keep_alive: True`, `timeout_ms: 2500`) and negative timeout (`-10`).
3. Bind and listen on a server socket, connect a client socket, accept on the server socket, verify `is_open`, `is_listening`, `is_connected` flags, and close both sockets (`sock close`), verifying subsequent operations on closed sockets return `SockErr`.

## Expected results (map to acceptance criteria)
- AC1 → Valid IPv4, IPv6, and Unix endpoints return `SockAddrOk`; invalid octets, out-of-range ports, and unsafe paths return `SockErr`.
- AC2 → Valid options update socket configuration; negative timeout returns `SockErr`.
- AC3 → `sock bind` → `sock listen` → `sock connect` → `sock accept` transitions endpoints to connected state, and `sock close` marks handles closed and rejects further use.

## Not covered here (to avoid duplication)
- see `TS-SOCK-002` for byte/string stream I/O, datagram `send to`/`recv from`, and length-prefixed/line-delimited framing.
