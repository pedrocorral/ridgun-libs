---
id: TS-SOCK-002
title: Verify socket byte/string transfer, datagrams, and framed messages
level: unit
covers: [FR-SOCK-002]
status: automated
automated_in: [src/test/ridgun/test_socket.rg]
---
# TS-SOCK-002 — Verify socket byte/string transfer, datagrams, and framed messages

## Preconditions / fixtures
- Connected TCP/Unix stream socket pairs and bound UDP/Unix datagram sockets from `socket.rg`.

## Steps / inputs
1. Send raw byte lists (`[72, 105, 33]`) and UTF-8 strings (`"hello ridgun"`) over connected stream sockets and read them back with `sock recv bytes` and `sock recv str`.
2. Send UDP and Unix datagrams using `sock send to` and receive them using `sock recv from`, checking both payload and sender `SockAddr`.
3. Send length-prefixed frames (`sock send frame`) and newline-delimited lines (`sock send line`) and receive them with `sock recv frame` and `sock recv line`, including a frame whose length exceeds `max_bytes`.

## Expected results (map to acceptance criteria)
- AC1 → Stream `sock recv bytes` and `sock recv str` return the exact transmitted bytes and strings bounded by `max_bytes`.
- AC2 → Datagram `sock recv from` returns the transmitted payload and sender `SockAddr`.
- AC3 → Framed and line-delimited messages round-trip losslessly, and frames exceeding `max_bytes` return `SockErr`.

## Not covered here (to avoid duplication)
- see `TS-SOCK-001` for address parsing, option validation, and connection lifecycle.
