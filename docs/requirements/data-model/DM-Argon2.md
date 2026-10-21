---
id: DM-Argon2
title: Argon2id parameters, PHC representation, and AEAD cryptographic material
status: approved
related: [FR-CRYPTO-001, FR-CRYPTO-002, FR-CRYPTO-003, FR-CRYPTO-004, ADR-0001, ADR-0002]
---
# DM-Argon2 — Argon2id parameters, PHC representation, and AEAD cryptographic material

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| m_cost | Int | `>= 8 * lanes` | Argon2id memory cost in KiB |
| t_cost | Int | `>= 1` | Argon2id number of passes / iterations |
| lanes | Int | `1..255` | Argon2id degree of parallelism (`p`) |
| tag_len | Int | `4..64` | Derived output tag length in bytes (`32` default) |
| version | Int | `19` (`0x13`) | RFC 9106 Argon2 version identifier |
| salt_b64 | String | Unpadded RFC 4648 Base64 (`>= 8` decoded bytes) | Salt segment in `$argon2id$v=19$...` |
| tag_b64 | String | Unpadded RFC 4648 Base64 (`>= 4` decoded bytes) | Tag segment in `$argon2id$v=19$...` |
| key_bytes | String | Raw byte string (`32` bytes for ChaCha20-Poly1305) | Symmetric key or HMAC key |
| nonce_bytes | String | Raw byte string (`12` bytes for ChaCha20-Poly1305) | RFC 8439 96-bit AEAD nonce |
| aad_bytes | String | Arbitrary raw byte string | Authenticated additional data (AAD) |
| status_code | Int | `0` (OK), `-7` (`INVALID`), `-12` (`AUTH_FAILED`) | Returned by `aead_open` |

## Relations
- Used across `argon2id.rg` (`Argon2Params`, `Argon2Res`, `Argon2BytesRes`, `Argon2Phc`, `Argon2PhcRes`) and `crypto.rg` (`argon2id_hash`, `argon2id_verify`, `aead_seal`, `aead_open`).

## Invariants
- `m_cost >= 8 * lanes`, `t_cost >= 1`, `lanes >= 1`, `tag_len >= 4`, and decoded salt length `>= 8` bytes.
- All tag comparisons (`Argon2id` PHC verification, `HMAC-SHA-256`, `Poly1305` 16-byte AEAD tag) execute in constant time (`ct_equal` / `constant time eq`).
- `aead_open` never releases unauthenticated plaintext when the 16-byte Poly1305 tag check fails (`(-12, "")`).

## Lifecycle
- Stateless in-memory value objects managed deterministically by Ridgun `RMM1`/`RMM2`.
