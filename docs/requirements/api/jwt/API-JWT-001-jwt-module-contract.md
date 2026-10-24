---
id: API-JWT-001
title: Public lib contract for jwt (jwt.rglib / libjwt.so)
status: approved
implements: [FR-JWT-001]
auth: none
---
# API-JWT-001 — Public lib contract for `jwt` (`jwt.rg`)

## Request
- Imported via `import jwt`.
- Public Types (see `DM-Jwt`):
  - `type JwtClaims = issuer: String, subject: String, expires_at: Int, not_before_at: Int, custom_json: String`
  - `type JwtRes = JwtOk String | JwtErr String`
  - `type JwtClaimsRes = JwtClaimsOk JwtClaims | JwtClaimsErr String`
- Signing & Verification (`HS256` HMAC-SHA256):
  - `jwt sign hs256 String String => String`
  - `jwt verify hs256 String String => JwtRes`
  - `jwt sign claims JwtClaims String => String`
  - `jwt verify claims String String Int => JwtClaimsRes`
  - `jwt decode payload String => JwtRes`
- Encrypted Authenticated Tokens (`ChaCha20-Poly1305` AEAD):
  - `jwt seal aead String String String => JwtRes`
  - `jwt open aead String String String => JwtRes`

## Responses
| Code | When | Body |
|---|---|---|
| `String` | `jwt sign hs256` / `jwt sign claims` | Compact `header.payload.signature` Base64url JWT |
| `JwtOk String` / `JwtClaimsOk JwtClaims` | Valid signature and unexpired claims | Decoded payload JSON or validated `JwtClaims` |
| `JwtErr String` / `JwtClaimsErr String` | Invalid signature, wrong algorithm, or expired token | Error reason |

## Rules
- Signature comparison is strictly constant-time (`constant_time_eq`).
