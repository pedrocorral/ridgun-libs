---
id: API-SOCK-001
title: Public module contract for socket (socket.rglib / libsocket.so)
status: approved
implements: [FR-SOCK-001, FR-SOCK-002, FR-SOCK-003, FR-SOCK-004]
auth: none
---
# API-SOCK-001 — Public module contract for `socket` (`socket.rg`)

## Request
- Imported via `import socket`.
- Inputs (see `DM-Socket`): `host` (`String`), `port` (`Int`), `path` (`String`), `timeout_ms` (`Int`), `max_bytes` (`Int`), `sock_id` / `fd` (`Int`).
- High-level ADT signatures:
  - `ipv4 addr String Int => SockAddrRes`, `ipv6 addr String Int => SockAddrRes`, `unix addr String => SockAddrRes`, `parse ipv4 endpoint String => SockAddrRes`
  - `sock tcp () => Socket`, `sock tcp6 () => Socket`, `sock udp () => Socket`, `sock udp6 () => Socket`, `sock unix stream () => Socket`, `sock unix dgram () => Socket`
  - `sock set options Socket SockOpts => SockRes`, `sock set timeout Socket Int => SockRes`, `sock set tcp nodelay Socket Bool => SockRes`, `sock set broadcast Socket Bool => SockRes`, `sock set buf sizes Socket Int Int => SockRes`
  - `sock bind Socket SockAddr => SockRes`, `sock listen Socket Int => SockRes`, `sock connect Socket SockAddr => SockRes`, `sock accept Socket => SockPairRes`, `sock shutdown Socket String => SockRes`, `sock close Socket => Socket`
  - `sock send bytes Socket [Int] => SockRes`, `sock recv bytes Socket Int => SockBytesRes`, `sock send str Socket String => SockRes`, `sock recv str Socket Int => SockStrRes`, `sock send all Socket [Int] => SockRes`, `sock recv exact Socket Int => SockBytesRes`
  - `sock send to Socket SockAddr [Int] => SockRes`, `sock recv from Socket Int => SockDgramRes`
  - `sock send frame Socket String => SockRes`, `sock recv frame Socket Int => SockStrRes`, `sock send line Socket String => SockRes`, `sock recv line Socket Int => SockStrRes`
  - `sock local addr Socket => SockAddrRes`, `sock peer addr Socket => SockAddrRes`, `sock poll Socket => SockPoll`, `is valid hostname String => Bool`, `sock resolve host String Int => SockAddrRes`, `ip in cidr String String => Bool`
- Solstice `RGF-001` status-tuple signatures:
  - `sys_resolve_ipv4 String => (Int, String)`
  - `sys_tcp_listen String Int Int => (Int, Int)`
  - `sys_unix_listen String Int => (Int, Int)`
  - `sys_local_port Int => Int`
  - `sys_accept Int Int => (Int, Int, String)`
  - `sys_tcp_connect String Int Int => (Int, Int)`
  - `sys_unix_connect String Int => (Int, Int)`
  - `sys_recv Int Int Int => (Int, String)`
  - `sys_send Int String Int => (Int, Int)`
  - `sys_shutdown_write Int => Int`
  - `sys_close Int => Int`

## Responses
| Code | When | Body |
|---|---|---|
| `0` / `SockOk` | Operation succeeded | `(0, fd)` / `(0, data)` / `(0, written)` / `SockOk s` |
| `-1` | End of stream (`EOF`) | `(-1, "")` |
| `-2` | Poll or operation deadline expired (`TIMEOUT`) | `(-2, -1)` / `(-2, "")` / `(-2, -1, "")` |
| `-3` | Connection refused (`ECONNREFUSED`) | `(-3, -1)` |
| `-4` | Connection reset (`ECONNRESET` / `EPIPE`) | `(-4, -1)` / `(-4, "")` |
| `-5` | Address already in use (`EADDRINUSE`) | `(-5, -1)` |
| `-6` | Permission denied (`EACCES` / `EPERM`) | `(-6, -1)` |
| `-7` / `SockErr` | Invalid host, port, path, fd, or argument (`EINVAL` / `EBADF`) | `(-7, -1)` / `SockErr msg` |

## Rules
- All blocking `sys_*` operations with `timeout_ms >= 0` poll descriptor readiness before kernel I/O so stalled peers never hang the process.
- `sys_tcp_listen` sets `SO_REUSEADDR` before `bind`.
