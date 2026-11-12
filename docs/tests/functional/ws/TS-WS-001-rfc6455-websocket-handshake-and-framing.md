---
id: TS-WS-001
title: Verify RFC 6455 WebSocket handshake accept-key computation, frame encoding/decoding, and XOR masking
level: unit
covers: [FR-WS-001, API-WS-001]
status: automated
automated_in: ["src/test/ridgun/test ws.ridgun"]
---
# TS-WS-001 — Verify RFC 6455 WebSocket handshake accept-key computation, frame encoding/decoding, and XOR masking

## Preconditions / fixtures
- Pure-Ridgun `ws` and `test` modules (`src/main/ridgun/lib/ws.ridgun`, `src/main/ridgun/lib/test.ridgun`).

## Steps / inputs
1. Call `ws accept key "dGhlIHNhbXBsZSBub25jZQ=="` and verify it equals `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="` (RFC 6455 §1.3); verify `ws build upgrade request` and `ws build upgrade response`.
2. Encode unmasked and masked `TEXT`, `PING`, `PONG`, and `CLOSE` frames (including 16-bit extended length $\ge 126$ bytes) via `ws encode*` and decode via `ws decode frame`. Frames and payloads are `Tensor[U8]` (ADR-0010).
3. Pass truncated frames (`Tensor[U8]`) to `ws decode frame` and verify `WsErr`, including a truncated 64-bit length, a 64-bit length with the most significant bit set, and a 64-bit length larger than the frame.
4. Encode a 70,000-byte `BINARY` payload that holds bytes 0, 128 and 255, unmasked and masked: verify the length code 127, the big-endian 64-bit length, the bytes consumed, and that the decoded payload equals the input byte for byte.

## Expected results (map to acceptance criteria)
- AC1 → RFC 6455 SHA-1 + Base64 `Sec-WebSocket-Accept` key matches the official specification vector.
- AC2 → Masked and unmasked frames (7-bit, 16-bit and 64-bit lengths) encode and decode losslessly.
- AC3 → Truncated frames return `WsErr` safely.

## Not covered here (to avoid duplication)
- Kernel TCP socket transport (`TS-SOCK-001`).
