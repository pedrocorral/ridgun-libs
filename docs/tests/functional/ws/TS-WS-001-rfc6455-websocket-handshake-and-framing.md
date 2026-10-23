---
id: TS-WS-001
title: Verify RFC 6455 WebSocket handshake accept-key computation, frame encoding/decoding, and XOR masking
level: unit
covers: [FR-WS-001, API-WS-001]
status: automated
automated_in: ["src/test/ridgun/test ws.rg"]
---
# TS-WS-001 — Verify RFC 6455 WebSocket handshake accept-key computation, frame encoding/decoding, and XOR masking

## Preconditions / fixtures
- Pure-Ridgun `ws` and `test` modules (`src/main/ridgun/lib/ws.rg`, `src/main/ridgun/lib/test.rg`).

## Steps / inputs
1. Call `ws accept key "dGhlIHNhbXBsZSBub25jZQ=="` and verify it equals `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="` (RFC 6455 §1.3); verify `ws build upgrade request` and `ws build upgrade response`.
2. Encode unmasked and masked `TEXT`, `PING`, `PONG`, and `CLOSE` frames (including 16-bit extended length $\ge 126$ bytes) via `ws encode*` and decode via `ws decode frame`.
3. Pass truncated frame byte lists to `ws decode frame` and verify `WsErr`.

## Expected results (map to acceptance criteria)
- AC1 → RFC 6455 SHA-1 + Base64 `Sec-WebSocket-Accept` key matches the official specification vector.
- AC2 → Masked and unmasked frames encode and decode losslessly.
- AC3 → Truncated frames return `WsErr` safely.

## Not covered here (to avoid duplication)
- Kernel TCP socket transport (`TS-SOCK-001`).
