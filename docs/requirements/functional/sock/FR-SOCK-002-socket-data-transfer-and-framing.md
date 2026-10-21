---
id: FR-SOCK-002
title: Transfer bytes, strings, datagrams, and framed messages over sockets
type: functional
status: implemented
priority: must
domain: SOCK
depends_on: [FR-SOCK-001]
related: [ADR-0001, VUL-INPUT-001]
tests: [TS-SOCK-002]
---
# FR-SOCK-002 — Transfer bytes, strings, datagrams, and framed messages over sockets

## Statement
The `socket` library SHALL send and receive raw byte lists (`[Int]`), UTF-8 strings (`String`), UDP/Unix datagrams, and length-prefixed or line-delimited framed messages over connected or bound sockets.

## Rationale
Applications require reliable stream and datagram payload exchange without manual byte-framing bugs or unbounded buffer reads.

## Acceptance criteria
- AC1: Given a connected TCP or Unix stream socket pair, when the sender transmits raw bytes (`sock send bytes`) or a string (`sock send str`), then the receiver reads the exact byte sequence (`sock recv bytes`) or UTF-8 string (`sock recv str`) up to the requested maximum byte limit.
- AC2: Given a bound UDP or Unix datagram socket, when a datagram is sent to a target endpoint (`sock send to`), then `sock recv from` returns the payload along with the sender's `SockAddr`.
- AC3: Given a stream socket, when messages are exchanged using 4-byte big-endian length-prefixed framing (`sock send frame` / `sock recv frame`) or newline framing (`sock send line` / `sock recv line`), then complete messages are reconstructed accurately and frames exceeding the declared maximum size limit return `SockErr`.

## Actors & permissions
- Any Ridgun module importing `socket`.

## Constraints & edge cases
- Byte values outside `0..255` are masked or rejected cleanly; maximum receive/frame length (`max_bytes`) is enforced to prevent unbounded memory growth.

## Data & privacy
- Payloads are held in memory only for the duration of the call and managed deterministically by Ridgun `RMM1`/`RMM2`.

## Security & observability notes
- Mitigates `VUL-INPUT-001` by enforcing explicit `max_bytes` bounds on receive and frame decoding operations.

## Out of scope
- Application-layer HTTP/1.1 or HTTP/2 parsing.
