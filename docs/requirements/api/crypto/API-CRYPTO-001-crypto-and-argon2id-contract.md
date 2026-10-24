---
id: API-CRYPTO-001
title: Public lib contract for argon2id and crypto (argon2id.rglib, crypto.rglib)
status: approved
implements: [FR-CRYPTO-001, FR-CRYPTO-002, FR-CRYPTO-003, FR-CRYPTO-004]
auth: none
---
# API-CRYPTO-001 — Public lib contract for `argon2id` & `crypto` (`argon2id.rg`, `crypto.rg`)

## Request
- Imported via `import argon2id` and/or `import crypto`.
- Inputs (see `DM-Argon2`): `m_cost` (`Int`), `t_cost` (`Int`), `lanes` (`Int`), `tag_len` (`Int`), `key_bytes` (`String`), `nonce_bytes` (`String`), `aad_bytes` (`String`).
- Raw Byte & Bitwise API (`RGF-019` in `crypto.rg`):
  - `byte_str Int => String`, `bytes_from_list [Int] => String`, `bytes_to_list String => [Int]`
  - `band Int Int => Int`, `bor Int Int => Int`, `bxor Int Int => Int`, `shl Int Int => Int`, `shr Int Int => Int`
- Digest, MAC, Constant-Time & PBKDF2 API (`RGF-015` in `crypto.rg`):
  - `sha256_bytes String => String`, `sha256_hex String => String`
  - `hmac_sha256 String String => String`
  - `ct_equal String String => Bool`
  - `pbkdf2_hmac_sha256 String String Int Int => String`
- Argon2id API (`argon2id.rg` & `crypto.rg` — `FR-CRYPTO-001..004`, `RGF-015`):
  - `argon2id_hash String String Int Int Int => String` (Solstice 5-arg PHC hash)
  - `argon2id_verify String String => Bool` (Solstice constant-time PHC verify)
  - `argon2id hash String String Argon2Params => Argon2Res` (ADT API)
  - `argon2id verify String String => Bool` (natural-space alias)
  - `argon2id generate salt Int => String`, `argon2id hash password String Argon2Params => Argon2Res`
  - `argon2id parse phc String => Argon2PhcRes`, `argon2id needs rehash String Argon2Params => Bool`
  - `argon2id derive key String String Argon2Params => Argon2BytesRes`, `argon2id derive key hex String String Argon2Params => Argon2Res`
  - `argon2id hash with context String String [Int] [Int] Argon2Params => Argon2Res`, `argon2id verify with context String [Int] [Int] String => Bool`
  - `argon2 default params () => Argon2Params`, `argon2 interactive params () => Argon2Params`, `argon2 moderate params () => Argon2Params`, `argon2 sensitive params () => Argon2Params`
- Argon2id & Blake2b `BlaMka` Tensor Block Compression API (`crypto.rg`):
  - `f blamka U64 U64 => U64`
  - `blamka g U64 U64 U64 U64 => U64 U64 U64 U64`
  - `blamka p16 Tensor[U64 * 16] => ()`
  - `compress block Tensor[U64 * 8 * 16] Tensor[U64 * 8 * 16] => Tensor[U64 * 8 * 16]`
- ChaCha20-Poly1305 AEAD API (`RGF-015` in `crypto.rg`):
  - `aead_seal String String String String => String` (`key` 32 B, `nonce` 12 B, `aad`, `plaintext` → `ciphertext || 16-byte tag`)
  - `aead_open String String String String => (Int, String)` (`(0, plaintext)` on valid tag, `(-12, "")` on tag mismatch, `(-7, "")` on invalid key/nonce length)

## Responses
| Code | When | Body |
|---|---|---|
| `0` / `Argon2Ok` / `True` | Valid parameters, matching password, or authentic AEAD tag | `(0, plaintext)` / `Argon2Ok phc` / `True` |
| `-7` / `Argon2Err` | Invalid parameter, key length (`!= 32`), or nonce length (`!= 12`) | `(-7, "")` / `Argon2Err reason` |
| `-12` / `False` | Authentication tag mismatch (`AUTH_FAILED`) | `(-12, "")` / `False` |

## Rules
- All tag verifications (`ct_equal`, `argon2id_verify`, `aead_open`) run in constant time.
- `aead_open` never returns partial or unauthenticated plaintext on `-12`.
