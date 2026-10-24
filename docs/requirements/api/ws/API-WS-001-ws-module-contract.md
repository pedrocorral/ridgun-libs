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
  - `type WsFrame = is_fin: Bool, ws_opcode: Int, is_masked: Bool, payload_bytes: [Int], payload_text: String`
  - `type WsRes = WsOk WsFrame Int | WsErr String`
- Handshake & HTTP Upgrade:
  - `ws accept key String => String`
  - `ws build upgrade request String String String => String`
  - `ws build upgrade response String => String`
- Frame Encoding, Decoding & Masking:
  - `ws mask bytes [Int] [Int] => [Int]`
  - `ws encode frame Bool Int [Int] [Int] => [Int]`
  - `ws encode text String => [Int]`
  - `ws encode masked text String [Int] => [Int]`
  - `ws encode ping [Int] => [Int]`
  - `ws encode pong [Int] => [Int]`
  - `ws encode close Int => [Int]`
  - `ws decode frame [Int] => WsRes`

## Responses
| Code | When | Body |
|---|---|---|
| `String` | `ws accept key` | Base64-encoded SHA-1 `Sec-WebSocket-Accept` digest |
| `[Int]` | `ws encode*` | Wire-format RFC 6455 frame byte list |
| `WsOk WsFrame Int` | `ws decode frame` | Decoded `WsFrame` and total bytes consumed |
| `WsErr String` | Truncated or invalid frame | Diagnostic error message |

## Rules
- `ws_opcode` constants: `1` (`TEXT`), `2` (`BINARY`), `8` (`CLOSE`), `9` (`PING`), `10` (`PONG`).
