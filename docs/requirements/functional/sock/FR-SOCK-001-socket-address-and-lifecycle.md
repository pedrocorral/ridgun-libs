---
id: FR-SOCK-001
title: Manage TCP, UDP, and Unix socket addresses, options, and lifecycle
type: functional
status: implemented
priority: must
domain: SOCK
depends_on: []
related: [ADR-0001, VUL-INJ-002, VUL-INPUT-001]
tests: [TS-SOCK-001]
---
# FR-SOCK-001 — Manage TCP, UDP, and Unix socket addresses, options, and lifecycle

## Statement
The `socket` library SHALL validate TCP/UDP IPv4/IPv6 and Unix domain (`AF_UNIX`) socket endpoints, configure socket options and timeouts, and manage client/server socket lifecycle (`create`, `bind`, `listen`, `accept`, `connect`, and `close`).

## Rationale
Applications using `ridgun-libs` need a safe, unified Ridgun API to open, configure, bind, listen, accept, connect, and deterministically close TCP, UDP, and Unix domain sockets with strict endpoint validation.

## Acceptance criteria
- AC1: Given an IPv4, IPv6, or Unix domain endpoint specification, when the caller parses or constructs a `SockAddr`, then valid IPv4 (`a.b.c.d` with octets `0..255` and port `1..65535`), IPv6 (`::1`, bracketed `[addr]:port`), and safe Unix socket paths return `SockAddrOk`, and invalid hosts, out-of-range ports (`< 1` or `> 65535`), or unsafe paths (`..` traversal or shell metacharacters) return `SockErr`.
- AC2: Given a created socket (`sock tcp`, `sock tcp6`, `sock udp`, `sock udp6`, `sock unix stream`, or `sock unix dgram`), when options (`reuse_addr`, `keep_alive`, `non_blocking`, `timeout_ms`) are applied via `sock set options` or `sock set timeout`, then negative timeouts are rejected and valid options update the socket configuration.
- AC3: Given a server socket bound and listening on a TCP or Unix stream endpoint (`sock bind`, `sock listen`), when a client socket connects (`sock connect`) and the server accepts (`sock accept`), then both endpoints transition to connected state and `sock close` deterministically releases resources and marks the socket closed.

## Actors & permissions
- Any Ridgun program or lib importing `socket`.

## Constraints & edge cases
- Operations on an already-closed socket handle must fail deterministically with `SockErr` rather than panicking.
- Unix socket paths must reject path traversal (`..`), empty paths, and shell/control characters.

## Data & privacy
- No persistent PII; Unix domain socket files in temporary directories are unlinked on close when owned by the server.

## Security & observability notes
- Mitigates `VUL-INJ-002` (strict endpoint/path validation) and `VUL-INPUT-001` (bounded port and timeout validation).

## Out of scope
- TLS/mTLS handshake encryption (handled by a separate future TLS module).
