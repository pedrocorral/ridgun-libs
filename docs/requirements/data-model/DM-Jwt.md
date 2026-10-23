---
id: DM-Jwt
title: RFC 7519 JSON Web Token and encrypted token claim models
status: approved
related: [FR-JWT-001, API-JWT-001, ADR-0002]
---
# DM-Jwt — RFC 7519 JSON Web Token and encrypted token claim models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| issuer | String | Non-empty string or `""` | Standard JWT `iss` claim |
| subject | String | Non-empty string or `""` | Standard JWT `sub` claim |
| expires_at | Int | `>= 0` (UTC epoch seconds) | Standard JWT `exp` expiration timestamp |
| not_before_at | Int | `>= 0` (UTC epoch seconds) | Standard JWT `nbf` not-before timestamp |

## Relations
- Used by `jwt.rg` (`JwtClaims`, `JwtRes`) alongside `crypto.rg` (`hmac_sha256`, `aead_chacha20_poly1305_encrypt`/`decrypt`) and `codec.rg` (`base64url`).

## Invariants
- Signature verification compares the expected and received Base64url HMAC-SHA256 tags in constant time (`constant_time_eq`) and rejects `alg: none` (`VUL-AUTHN-001`).
- Temporal validation enforces `now >= not_before_at` and `now < expires_at` when `expires_at > 0`.

## Lifecycle
- Constructed, signed, verified, and decoded purely in `RMM1`/`RMM2` memory.
