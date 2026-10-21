---
id: DM-Socket
title: Socket handle, address, options, and poll readiness models
status: approved
related: [FR-SOCK-001, FR-SOCK-002, FR-SOCK-003, FR-SOCK-004, ADR-0001, ADR-0002]
---
# DM-Socket — Socket handle, address, options, and poll readiness models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| sock_id | Int | `>= 0` | Socket handle or OS descriptor identifier |
| family | String | `"inet"`, `"inet6"`, `"unix"` | Socket address family |
| sock_type | String | `"stream"`, `"dgram"` | Transport semantics |
| host | String | Valid IPv4, IPv6, or RFC 1123 hostname | Empty for `AF_UNIX` |
| port | Int | `0..65535` | `0` allowed for ephemeral bind in `sys_tcp_listen` |
| path | String | Non-empty, no `..` traversal or shell metacharacters | Used by `AF_UNIX` endpoints |
| timeout_ms | Int | `-1` (infinite), `0` (non-blocking), `> 0` (deadline) | Rejects `< -1` in `sys_*` and `< 0` in `SockOpts` |
| reuse_addr | Bool | `True` / `False` | `SO_REUSEADDR` option flag |
| keep_alive | Bool | `True` / `False` | `SO_KEEPALIVE` option flag |
| non_blocking | Bool | `True` / `False` | `O_NONBLOCK` mode flag |
| tcp_nodelay | Bool | `True` / `False` | `TCP_NODELAY` option flag |
| broadcast | Bool | `True` / `False` | `SO_BROADCAST` option flag |
| rcvbuf | Int | `> 0` | `SO_RCVBUF` size in bytes |
| sndbuf | Int | `> 0` | `SO_SNDBUF` size in bytes |
| is_open | Bool | `True` / `False` | Handle open state |
| is_listening | Bool | `True` / `False` | Passive listener state |
| is_connected | Bool | `True` / `False` | Active stream state |
| can_read | Bool | `True` / `False` | Receive half open (`SHUT_RD` not applied) |
| can_write | Bool | `True` / `False` | Send half open (`SHUT_WR` not applied) |
| readable | Bool | `True` / `False` | Poll readiness for read/accept |
| writable | Bool | `True` / `False` | Poll readiness for write |
| has_error | Bool | `True` / `False` | Poll error or closed state |
| status_code | Int | `0`, `-1`..`-8`, `-99` | Solstice `RGF-001` status tuple code |

## Relations
- Consumed by `socket.rg` high-level ADT API (`SockAddr`, `SockOpts`, `Socket`, `SockPoll`, `SockRes`, `SockBytesRes`, `SockStrRes`, `SockDatagram`) and `RGF-001` status-tuple functions (`sys_tcp_listen`, `sys_unix_listen`, `sys_accept`, `sys_tcp_connect`, `sys_unix_connect`, `sys_recv`, `sys_send`, `sys_shutdown_write`, `sys_close`).

## Invariants
- A closed socket (`is_open == False`) rejects all bind, listen, accept, connect, send, recv, and shutdown operations.
- `AF_UNIX` paths never contain `..` traversal segments or shell metacharacters.
- Receive operations enforce `max_bytes > 0`.

## Lifecycle
- `Created` → `Bound` → `Listening` (server) or `Connected` (client/accepted peer) → `HalfClosed` (`SHUT_RD` / `SHUT_WR`) → `Closed`.
