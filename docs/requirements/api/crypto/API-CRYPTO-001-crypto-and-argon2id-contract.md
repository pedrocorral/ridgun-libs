---
id: API-CRYPTO-001
title: Public lib contract for argon2id and crypto (argon2id.ridgunlib, crypto.ridgunlib)
status: approved
implements: [FR-CRYPTO-001, FR-CRYPTO-002, FR-CRYPTO-003, FR-CRYPTO-004, FR-CRYPTO-005, FR-CRYPTO-006]
auth: none
---
# API-CRYPTO-001 — Public lib contract for `argon2id` & `crypto` (`argon2id.ridgun`, `crypto.ridgun`)

## Request
- Imported via `import argon2id` and/or `import crypto`.
- Inputs (see `DM-Argon2`): `m_cost` (`Int`), `t_cost` (`Int`), `lanes` (`Int`), `tag_len` (`Int`), `key_bytes` (`String`), `nonce_bytes` (`String`), `aad_bytes` (`String`).
- Byte data (`ADR-0010`): a byte sequence that is not a whole `String` is a `Tensor[U8]` (one byte per element, values `0..255`). Lists of `Int` are only used to convert list literals.
- Raw Byte & Bitwise API (`RGF-019` in `crypto.ridgun`):
  - `byte_str Int => String`, `bytes_from_list [Int] => String` (values taken modulo 256), `bytes_to_list String => [Int]`: built on `Tensor[U8]` with `tensor to str`, `tensor from str` and `tensor to list`
  - `bytes to hex str String => String`, `hex to byte str String => String`, `bitxor byte strings String String => String`, `byte slice String Int Int => String`
  - `bytes list to hex Tensor[U8] => String`, `hex str to bytes String => Tensor[U8]`, `bitxor byte lists Tensor[U8] Tensor[U8] => Tensor[U8]`
  - `band Int Int => Int`, `bor Int Int => Int`, `bxor Int Int => Int`, `shl Int Int => Int`, `shr Int Int => Int`
- Digest, MAC, Constant-Time & PBKDF2 API (`RGF-015` in `crypto.ridgun`):
  - `sha256_bytes String => String`, `sha256_hex String => String`
  - `sha1 bytes String => String` (20 raw bytes), `sha1 hex String => String` (40 hex characters); only for protocols that require SHA-1 (`FR-CRYPTO-003`)
  - `hmac_sha256 String String => String`
  - `ct_equal String String => Bool`
  - `pbkdf2_hmac_sha256 String String Int Int => String`
- Argon2id API (`argon2id.ridgun` & `crypto.ridgun` — `FR-CRYPTO-001..004`, `RGF-015`):
  - `argon2id_hash String String Int Int Int => String` (Solstice 5-arg PHC hash)
  - `argon2id_verify String String => Bool` (Solstice constant-time PHC verify)
  - `argon2id hash String String Argon2Params => Argon2Res` (ADT API)
  - `argon2id verify String String => Bool` (natural-space alias)
  - `argon2id generate salt Int => String`, `argon2id hash password String Argon2Params => Argon2Res`
  - `argon2id parse phc String => Argon2PhcRes`, `argon2id needs rehash String Argon2Params => Bool`
  - `argon2id derive key String String Argon2Params => Argon2KeyRes` (`Argon2KeyOk Tensor[U8] | Argon2KeyErr String`), `argon2id derive key hex String String Argon2Params => Argon2Res`
  - `argon2id hash ctx String String String String Argon2Params => Argon2Res` (`pwd salt secret ad params`), `argon2id verify ctx String String String String => Bool` (`pwd phc secret ad`)
  - `argon2id hash bytes String Tensor[U8] Argon2Params => Argon2Res` (raw salt bytes)
  - `derive raw tag Tensor[U8] Tensor[U8] Argon2Params => Tensor[U8]`, `derive raw tag ctx Tensor[U8] Tensor[U8] String String Argon2Params => Tensor[U8]` (raw password, raw salt → raw tag)
  - `bytes to hex Tensor[U8] => String`, `b64 encode nopad Tensor[U8] => String`, `b64 decode nopad String => Tensor[U8]`, `constant time bytes eq Tensor[U8] Tensor[U8] => Bool`, `constant time eq String String => Bool`
  - `argon2 default params () => Argon2Params`, `argon2 interactive params () => Argon2Params`, `argon2 moderate params () => Argon2Params`, `argon2 sensitive params () => Argon2Params`
- Argon2id & Blake2b `BlaMka` Tensor Block Compression API (`crypto.ridgun`):
  - `f blamka U64 U64 => U64`
  - `blamka g U64 U64 U64 U64 => U64 U64 U64 U64`
  - `blamka p16 Tensor[U64 * 16] => ()`
  - `compress block Tensor[U64 * 8 * 16] Tensor[U64 * 8 * 16] => Tensor[U64 * 8 * 16]`
- ChaCha20-Poly1305 AEAD API (`RGF-015` in `crypto.ridgun`; the building blocks `le32 at Tensor[U8] Int => Int`, `chacha20 block Tensor[U8] Tensor[U8] Int => Tensor[U8]`, `chacha20 bitxor Tensor[U8] Tensor[U8] Int Tensor[U8] => Tensor[U8]` and `poly1305 aead mac Tensor[U8] Tensor[U8] Tensor[U8] => Tensor[U8]` work on `Tensor[U8]`):
  - `aead_seal String String String String => String` (`key` 32 B, `nonce` 12 B, `aad`, `plaintext` → `ciphertext || 16-byte tag`)
  - `aead_open String String String String => (Int, String)` (`(0, plaintext)` on valid tag, `(-12, "")` on tag mismatch, `(-7, "")` on invalid key/nonce length)
- FIPS 180-4 SHA-512, RFC 8032 §5.1 Ed25519 & Minisign API (`FR-CRYPTO-005` in `crypto.ridgun`):
  - `sha512 bytes String => String` (64-byte raw SHA-512 digest)
  - `sha512 hex String => String` (128-char lowercase hex SHA-512 digest)
  - `ed25519 public key String => String` (32-byte seed → 32-byte compressed public key, or `""` if `str len seed != 32`)
  - `ed25519 sign String String => String` (32-byte seed, message → 64-byte signature `R || S`, or `""` if `str len seed != 32`)
  - `ed25519 verify String String String => Bool` (32-byte public key, message, 64-byte signature → `True` if valid with $0 \le S < L$, `False` otherwise)
  - `minisign encode pubkey String String => String` (8-byte `key_id`, 32-byte `pubkey` → Minisign public-key text)
  - `minisign decode pubkey String => String String` (Minisign public-key text or `RW...` line → `(key_id, pubkey_32b)`, or `("", "")` on error)
  - `minisign sign String String String String String => String` (`seed` 32 B, `key_id` 8 B, `msg`, `untrusted_comment`, `trusted_comment` → 4-line `.minisig` text)
  - `minisign verify String String String => Bool` (`pubkey_text`, `msg`, `minisig_text` → `True` if both payload signature and trusted-comment global signature verify)
  - `minisign trusted comment String => String` (`minisig_text` → extracted trusted comment string)
- SHA-384, HKDF, X25519, AES-128-GCM, ECDHE/ECDSA P-256/P-384, RSA & X.509 API (`FR-CRYPTO-006` in `crypto.ridgun`):
  - `sha384 bytes String => String`, `sha384 hex String => String`, `hmac sha384 String String => String`
  - `hkdf extract String String => String`, `hkdf expand String String Int => String`
  - `hkdf extract sha384 String String => String`, `hkdf expand sha384 String String Int => String`
  - `hkdf expand label String String String Int => String`, `derive secret String String String => String`
  - `x25519 String String => String`, `x25519 public key String => String`
  - `aes128 block String String => String`, `aes128 gcm seal String String String String => String`, `aes128 gcm open String String String String => Int String`
  - `p256 public key String => String`, `p256 ecdh String String => String`
  - `ecdsa p256 verify String String String => Bool`, `ecdsa p256 verify sha256 String String String => Bool`
  - `ecdsa p384 verify String String String => Bool`, `ecdsa p384 verify sha384 String String String => Bool`
  - `rsa mod exp String String String => String`, `rsa verify pkcs1 String String String String String => Bool`, `rsa verify pss String String String String String => Bool`
  - `type X509Cert = tbs_der: String, issuer_der: String, subject_der: String, issuer_cn: String, subject_cn: String, not_before_at: Int, not_after_at: Int, key_alg: String, pubkey_bytes: String, rsa_exp_bytes: String, sig_alg: String, sig_bytes: String, san_dns: [String], is_ca: Bool, key_usage_bits: Int, has_server_auth: Bool`
  - `pem decode blocks String String => [String]`, `asn1 parse tlv String Int => Bool Int Int Int Int`
  - `x509 parse cert String => Bool X509Cert`, `x509 match hostname X509Cert String => Bool`, `x509 verify cert sig X509Cert X509Cert => Bool`

## Responses
| Code | When | Body |
|---|---|---|
| `0` / `Argon2Ok` / `True` | Valid parameters, matching password, or authentic AEAD tag | `(0, plaintext)` / `Argon2Ok phc` / `True` |
| `-7` / `Argon2Err` | Invalid parameter, key length (`!= 32`), or nonce length (`!= 12`) | `(-7, "")` / `Argon2Err reason` |
| `-12` / `False` | Authentication tag mismatch (`AUTH_FAILED`) | `(-12, "")` / `False` |

## Rules
- All tag verifications (`ct_equal`, `argon2id_verify`, `aead_open`) run in constant time.
- `aead_open` never returns partial or unauthenticated plaintext on `-12`.
