---
id: FR-WS-001
title: Provide RFC 6455 WebSocket handshake accept-key computation, frame encoding/decoding, and XOR masking
type: functional
status: implemented
priority: must
domain: WS
depends_on: []
related: [ADR-0002, DM-WebSocket, API-WS-001, VUL-INPUT-001]
tests: [TS-WS-001]
---
# FR-WS-001 — Provide RFC 6455 WebSocket handshake accept-key computation, frame encoding/decoding, and XOR masking

## Statement
The `ws` library SHALL provide RFC 6455 opening handshake key derivation (`ws accept key` via pure-Ridgun SHA-1 + Base64), HTTP Upgrade request/response builders (`ws build upgrade request`, `ws build upgrade response`), XOR payload masking (`ws mask bytes`), and frame encoding/decoding (`ws encode frame`, `ws encode text`, `ws encode ping`, `ws encode pong`, `ws encode close`, `ws decode frame`).

## Rationale
Real-time bidirectional services over `socket.rg` and `http.rg` require RFC 6455 handshake validation and wire-level WebSocket framing.

## Acceptance criteria
- AC1: Given the RFC 6455 §1.3 test client key `"dGhlIHNhbXBsZSBub25jZQ=="`, when `ws accept key` is called, then it returns `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="`.
- AC2: Given text, binary, ping, pong, or close payloads (unmasked or masked with a 4-byte key, including 7-bit and 16-bit extended payload lengths), when `ws encode frame` and `ws decode frame` are called, then the decoded `WsFrame` reproduces `is_fin`, `ws_opcode`, `is_masked`, and unmasked payload bytes accurately.
- AC3: Given truncated frame bytes, when `ws decode frame` is called, then it returns `WsErr` without out-of-bounds reads.

## Actors & permissions
- Any Ridgun module importing `ws`.

## Constraints & edge cases
- Supports payload lengths `< 126` (7-bit) and `126..65535` (16-bit extended length).

## Data & privacy
- Pure in-memory byte framing in `RMM1`/`RMM2` regions.

## Security & observability notes
- Mitigates `VUL-INPUT-001` via explicit payload length bounds checks.

## Out of scope
- `permessage-deflate` compression extension.
