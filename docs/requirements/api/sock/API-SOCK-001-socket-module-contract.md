---
id: API-SOCK-001
title: Public lib contract for socket (socket.ridgunlib / libsocket.so)
status: approved
implements: [FR-SOCK-001, FR-SOCK-002, FR-SOCK-003, FR-SOCK-004]
related: [ADR-0010]
auth: none
---
# API-SOCK-001 — Public lib contract for `socket` (`socket.ridgun`)

## Request
- Imported via `import socket`.
- Inputs (see `DM-Socket`): `host` (`String`), `port` (`Int`), `path` (`String`), `timeout_ms` (`Int`), `max_bytes` (`Int`), `sock_id` / `fd` (`Int`).
- High-level ADT signatures:
  - `ipv4 addr String Int => SockAddrRes`, `ipv6 addr String Int => SockAddrRes`, `unix addr String => SockAddrRes`, `parse ipv4 endpoint String => SockAddrRes`
  - `sock tcp () => Socket`, `sock tcp6 () => Socket`, `sock udp () => Socket`, `sock udp6 () => Socket`, `sock unix stream () => Socket`, `sock unix dgram () => Socket`
  - `sock set options Socket SockOpts => SockRes`, `sock set timeout Socket Int => SockRes`, `sock set tcp nodelay Socket Bool => SockRes`, `sock set broadcast Socket Bool => SockRes`, `sock set buf sizes Socket Int Int => SockRes`
  - `sock bind Socket SockAddr => SockRes`, `sock listen Socket Int => SockRes`, `sock connect Socket SockAddr => SockRes`, `sock accept Socket => SockPairRes`, `sock shutdown Socket String => SockRes`, `sock close Socket => Socket`
  - Bytes are `Tensor[U8]` (`ADR-0010`): `type SockRecvBytesRes = SockBytesOk Socket Tensor[U8] | SockBytesErr String`, `type SockRecvFromRes = SockFromOk Socket Tensor[U8] SockAddr | SockFromErr String`.
  - `sock send bytes Socket Tensor[U8] => SockRes`, `sock recv bytes Socket Int => SockRecvBytesRes`, `sock send str Socket String => SockRes`, `sock recv str Socket Int => SockRecvStrRes`, `sock send all Socket Tensor[U8] => SockRes`, `sock recv exact Socket Int => SockRecvBytesRes`
  - `sock send to Socket Tensor[U8] SockAddr => SockRes`, `sock recv from Socket Int => SockRecvFromRes`
  - `sock send frame Socket Tensor[U8] => SockRes`, `sock recv frame Socket Int => SockRecvBytesRes`, `sock send line Socket String => SockRes`, `sock recv line Socket Int => SockRecvStrRes`
  - `encode be32 Int => Tensor[U8]`, `decode be32 Tensor[U8] => Int` (`-1` for fewer than 4 bytes)
  - Removed with `ADR-0010`: `str to byte list`, `byte list to str`, `int list len`, `take ints`, `drop ints`, `all valid bytes` (use `tensor from str` / `tensor to str`).
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
- Kernel arguments (`sockaddr_in`, `sockaddr_un`, option values, `socklen_t`) are `Tensor[U8]` values passed straight to `sys call`; no memfd buffer is used (`ADR-0010`).
- `sys send` keeps the payload in one `Tensor[U8]`; after a partial `sendto` it rebuilds the tensor from the bytes not yet sent.
- On x86-64 the TCP functions use the runtime's `net …` operations; status codes are the same on every architecture (`ADR-0013`).
