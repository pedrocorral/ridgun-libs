---
id: DM-WebSocket
title: RFC 6455 WebSocket handshake and frame models
status: approved
related: [FR-WS-001, API-WS-001, ADR-0002, ADR-0010]
---
# DM-WebSocket — RFC 6455 WebSocket handshake and frame models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| ws_opcode | Int | `1` (Text), `2` (Binary), `8` (Close), `9` (Ping), `10` (Pong) | 4-bit RFC 6455 frame opcode |
| is_fin | Bool | `True` or `False` | `FIN` bit (`0x80` in byte 0) |
| is_masked | Bool | `True` or `False` | `MASK` bit (`0x80` in byte 1) |
| payload_bytes | Tensor[U8] | Length = payload length | Unmasked payload bytes (ADR-0010) |
| payload_text | String | Payload bytes unchanged when `ws_opcode` is `1`, otherwise `""` | Text frames only |

## Relations
- Used by `ws.rg` (`WsFrame`, `WsRes`) for RFC 6455 opening handshake key derivation (`Sec-WebSocket-Accept`) and frame serialization/parsing.

## Invariants
- `Sec-WebSocket-Accept` is computed as `Base64(SHA-1(client_key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))`.
- Masked client-to-server frames apply `payload[i] xor mask_key[i % 4]`.

## Lifecycle
- Frames are encoded to and decoded from `Tensor[U8]` byte buffers (ADR-0010) in `RMM1`/`RMM2` regions.
