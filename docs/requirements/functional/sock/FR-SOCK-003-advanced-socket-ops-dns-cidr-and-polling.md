---
id: FR-SOCK-003
title: Provide socket half-close shutdown, address inspection, exact I/O, polling, extended options, DNS hostnames, and CIDR matching
type: functional
status: implemented
priority: must
domain: SOCK
depends_on: [FR-SOCK-001, FR-SOCK-002]
related: [ADR-0001, VUL-INPUT-001]
tests: [TS-SOCK-003]
---
# FR-SOCK-003 — Provide socket half-close shutdown, address inspection, exact I/O, polling, extended options, DNS hostnames, and CIDR matching

## Statement
The `socket` library SHALL support half-close shutdown (`sock shutdown` for `"rd"`, `"wr"`, `"rdwr"`), endpoint inspection (`sock local addr`, `sock peer addr`), guaranteed buffer I/O (`sock send all`, `sock recv exact`), readiness polling (`sock poll`), extended socket options (`tcp_nodelay`, `broadcast`, `rcvbuf`, `sndbuf`), DNS hostname resolution (`is valid hostname`, `sock resolve host`), and IPv4 CIDR subnet matching (`ip in cidr`).

## Rationale
Standard networking libraries in production languages provide half-close semantics, exact byte reads, readiness polling, socket buffer/Nagle tuning, hostname resolution, and CIDR filtering in addition to basic `connect`/`send`/`recv`.

## Acceptance criteria
- AC1: Given an open connected socket, when `sock shutdown` is called with `"rd"`, `"wr"`, or `"rdwr"`, then subsequent reads on a read-shut socket or writes on a write-shut socket fail with `SockBytesErr` / `SockErr`, while the remaining direction stays operational until `sock close`.
- AC2: Given a bound or connected socket, when `sock local addr`, `sock peer addr`, `sock poll`, `sock send all`, or `sock recv exact` is called, then `sock local addr` and `sock peer addr` return the bound/remote `SockAddr`, `sock poll` reports `SockPoll` (`readable`, `writable`, `has_error`), and `sock recv exact` returns `SockBytesOk` only when the exact requested byte count is available (returning `SockBytesErr` on short read).
- AC3: Given extended options (`sock set tcp nodelay`, `sock set broadcast`, `sock set buf sizes`), a hostname (`localhost` or RFC 1123 domain), or an IPv4 CIDR block (`192.168.1.0/24`), when validated or evaluated, then invalid buffer sizes (`<= 0`) or malformed hostnames/CIDRs are rejected, `sock resolve host` maps known/valid hostnames to `SockAddr`, and `ip in cidr` accurately matches IPv4 addresses against `/0..32` prefix masks.

## Actors & permissions
- Any Ridgun module importing `socket`.

## Constraints & edge cases
- `ip in cidr` must reject invalid IPv4 strings or prefix lengths outside `0..32`.

## Data & privacy
- In-memory state only.

## Security & observability notes
- Mitigates `VUL-INPUT-001` by validating buffer sizes, shutdown modes, RFC 1123 hostnames, and CIDR prefix bounds.

## Out of scope
- Recursive external UDP DNS wire packets.
