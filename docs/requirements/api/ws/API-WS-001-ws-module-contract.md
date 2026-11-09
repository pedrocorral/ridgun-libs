---
id: API-WS-001
title: Public lib contract for ws (ws.rglib / libws.so)
status: approved
implements: [FR-WS-001]
auth: none
---
# API-WS-001 — Public lib contract for `ws` (`ws.rg`)

## Request
- Imported via `import ws`.
- Public Types (see `DM-WebSocket`):
  - `type WsFrame = is_fin: Bool, ws_opcode: Int, is_masked: Bool, payload_bytes: Tensor[U8], payload_text: String`
  - `type WsRes = WsOk WsFrame Int | WsErr String`
- Handshake & HTTP Upgrade:
  - `ws accept key String => String`
  - `ws build upgrade request String String String => String`
  - `ws build upgrade response String => String`
- Frame Encoding, Decoding & Masking (bytes are `Tensor[U8]`, ADR-0010):
  - `ws mask bytes Tensor[U8] Tensor[U8] => Tensor[U8]`
  - `ws encode frame Bool Int Tensor[U8] Tensor[U8] => Tensor[U8]` (fin, opcode, masking key, payload)
  - `ws encode text String => Tensor[U8]`
  - `ws encode masked text String Tensor[U8] => Tensor[U8]`
  - `ws encode ping Tensor[U8] => Tensor[U8]`
  - `ws encode pong Tensor[U8] => Tensor[U8]`
  - `ws encode close Int => Tensor[U8]`
  - `ws decode frame Tensor[U8] => WsRes`

## Responses
| Code | When | Body |
|---|---|---|
| `String` | `ws accept key` | Base64-encoded SHA-1 `Sec-WebSocket-Accept` digest |
| `Tensor[U8]` | `ws encode*`, `ws mask bytes` | Wire-format RFC 6455 frame bytes, or the masked payload |
| `WsOk WsFrame Int` | `ws decode frame` | Decoded `WsFrame` and total bytes consumed |
| `WsErr String` | Truncated or invalid frame | Diagnostic error message |

## Rules
- `ws_opcode` constants: `1` (`TEXT`), `2` (`BINARY`), `8` (`CLOSE`), `9` (`PING`), `10` (`PONG`).
- A masking key shorter than 4 bytes means "no mask": `ws encode frame` writes an unmasked frame and `ws mask bytes` returns a copy of the payload. Only the first 4 bytes of a longer key are used.
- Payload lengths of 65536 bytes or more use the 64-bit extended length.
- `ws mask bytes` and `ws encode*` return a new `Tensor[U8]`; they never write into their arguments.
