---
id: TS-SOCK-003
title: Verify socket shutdown, local/peer addr, exact I/O, poll, extended options, DNS hostnames, and CIDR matching
level: unit
covers: [FR-SOCK-003]
status: automated
automated_in: [src/test/ridgun/test socket.rg]
---
# TS-SOCK-003 — Verify socket shutdown, local/peer addr, exact I/O, poll, extended options, DNS hostnames, and CIDR matching

## Preconditions / fixtures
- Pure-Ridgun `socket` module (`src/main/ridgun/lib/socket.rg`).

## Steps / inputs
1. Connect a socket pair, inspect `sock local addr` and `sock peer addr`, check `sock poll` before and after transferring bytes, and test `sock shutdown` (`"rd"`, `"wr"`, `"rdwr"`), verifying writes fail after `"wr"` shutdown and reads fail after `"rd"` shutdown.
2. Send bytes with `sock send all` and read with `sock recv exact` both when enough bytes are buffered and when fewer bytes than requested are present.
3. Configure `sock set tcp nodelay`, `sock set broadcast`, and `sock set buf sizes` (valid and `<= 0` invalid sizes); validate and resolve hostnames (`"localhost"`, `"api.example.com"`, invalid `"-bad..host"`); evaluate `ip in cidr` on `"192.168.1.42"` against `"192.168.1.0/24"` and `"10.0.0.0/8"`.

## Expected results (map to acceptance criteria)
- AC1 → `sock shutdown` disables the specified direction(s) and rejects further reads/writes on shut directions.
- AC2 → `sock local addr`, `sock peer addr`, `sock poll`, `sock send all`, and `sock recv exact` return accurate addresses, readiness flags, and exact byte slices (or `SockBytesErr` on short buffer).
- AC3 → Extended socket options, hostname validation/resolution, and IPv4 CIDR prefix matching behave as specified and reject invalid inputs.

## Not covered here (to avoid duplication)
- see `TS-SOCK-001` and `TS-SOCK-002` for basic address parsing, connection setup, and framing.
