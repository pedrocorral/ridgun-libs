---
id: TS-SOCK-002
title: Verify socket byte/string transfer, datagrams, and framed messages
level: unit
covers: [FR-SOCK-002]
status: automated
automated_in: [src/test/ridgun/test socket.ridgun]
---
# TS-SOCK-002 — Verify socket byte/string transfer, datagrams, and framed messages

## Preconditions / fixtures
- Connected TCP/Unix stream socket pairs and bound UDP/Unix datagram sockets from `socket.ridgun`.

## Steps / inputs
1. Send UTF-8 strings (`"hello ridgun"`) and raw bytes as a `Tensor[U8]` holding `0, 128, 255, 10, 0` over connected stream sockets and read them back with `sock recv str`, `sock recv bytes` (3 bytes) and `sock recv exact` (2 bytes). Check `encode be32` / `decode be32` round trips `4278255360`, `encode be32 258` is `[0, 0, 1, 2]`, and `decode be32` of 2 bytes is `-1` (`ADR-0010`).
2. Send UDP and Unix datagrams using `sock send to` and receive them using `sock recv from`, checking both payload and sender `SockAddr`.
3. Send length-prefixed frames (`sock send frame`, payloads `10, 20, 30, 40` and `255, 0, 128`) and newline-delimited lines (`sock send line`) and receive them with `sock recv frame` and `sock recv line`, including a frame whose length exceeds `max_bytes`.

## Expected results (map to acceptance criteria)
- AC1 → Stream `sock recv bytes` and `sock recv str` return the exact transmitted bytes (including `0`, `128`, `255`) and strings bounded by `max_bytes`.
- AC2 → Datagram `sock recv from` returns the transmitted payload and sender `SockAddr`.
- AC3 → Framed and line-delimited messages round-trip losslessly, and frames exceeding `max_bytes` return `SockErr`.

## Not covered here (to avoid duplication)
- see `TS-SOCK-001` for address parsing, option validation, and connection lifecycle.
