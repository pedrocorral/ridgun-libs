---
id: FR-CRYPTO-004
title: Provide Solstice RGF-015 RFC 9106 Argon2id 5-arg API and RFC 8439 ChaCha20-Poly1305 AEAD
type: functional
status: implemented
priority: must
domain: CRYPTO
depends_on: [FR-CRYPTO-001, FR-CRYPTO-002, FR-CRYPTO-003]
related: [ADR-0002, VUL-AUTHN-001, VUL-INPUT-001]
tests: [TS-CRYPTO-004]
---
# FR-CRYPTO-004 — Provide Solstice RGF-015 RFC 9106 Argon2id 5-arg API and RFC 8439 ChaCha20-Poly1305 AEAD

## Statement
The `crypto` and `argon2id` libraries SHALL provide the Solstice `RGF-015` 5-argument `argon2id_hash password salt m_kib t_iters p_lanes => String` and `argon2id_verify password phc => Bool` backed by 100% in-process pure-Ridgun RFC 7693 64-bit Blake2b / RFC 9106 Argon2id (`RG-043`, `RG-050`, `RG-051`), and RFC 8439 ChaCha20-Poly1305 authenticated encryption with associated data (`aead_seal key nonce aad plaintext => String` and `aead_open key nonce aad ciphertext_and_tag => Int String`).

## Rationale
Applications need both RFC 9106 Argon2id with the exact 5-argument `(password, salt, m_kib, t_iters, p_lanes)` and `(password, phc)` signature convention and RFC 8439 ChaCha20-Poly1305 authenticated encryption for encrypting tokens, session state, and storage blobs with tamper detection.

## Acceptance criteria
- AC1: Given a password, salt (`>= 8` bytes), `m_kib`, `t_iters`, and `p_lanes`, when `argon2id_hash password salt m_kib t_iters p_lanes` and `argon2id_verify password phc` are called, then `argon2id_hash` produces a valid `$argon2id$v=19$m=<m>,t=<t>,p=<p>$<salt_b64>$<hash_b64>` PHC string using RFC 7693 Blake2b + RFC 9106 Argon2id (matching RFC 9106 §5.3 test vector for `32 x 0x01` password and `16 x 0x02` salt when `secret`/`ad` are supplied, and deterministic PHC encoding for standard calls), and `argon2id_verify password phc` returns `True` for the matching password and `False` for a wrong password or corrupted PHC string in constant time.
- AC2: Given a 32-byte `key`, 12-byte `nonce`, `aad`, and `plaintext`, when `aead_seal key nonce aad plaintext` is called, then it encrypts `plaintext` with RFC 8439 ChaCha20 (counter starting at `1`, block `0` deriving the one-time Poly1305 key) and appends the 16-byte Poly1305 authentication tag (`str_len ct == str_len plaintext + 16`), matching the RFC 8439 §2.8.2 "Ladies and Gentlemen of the class of '99..." test vector bit-for-bit.
- AC3: Given a 32-byte `key`, 12-byte `nonce`, `aad`, and `ciphertext_and_tag`, when `aead_open key nonce aad ciphertext_and_tag` is called, then it verifies the 16-byte Poly1305 tag in constant time and returns `(0, plaintext)` when authentic, `(-12, "")` (`AUTH_FAILED`) if any byte of ciphertext, tag, nonce, key, or `aad` is modified, and `(-7, "")` (`INVALID`) if key (`!= 32`), nonce (`!= 12`), or ciphertext (`< 16`) length is invalid.

## Actors & permissions
- Any Ridgun module importing `crypto` or `argon2id`.

## Constraints & edge cases
- `aead_open` must never return partial or unauthenticated plaintext when the Poly1305 tag check fails (`(-12, "")`).
- Invalid key/nonce lengths in `aead_seal` return `""` and in `aead_open` return `(-7, "")`.

## Data & privacy
- Plaintext is zeroed/discarded on authentication failure; keys and nonces are never logged.

## Security & observability notes
- Mitigates `VUL-AUTHN-001` (RFC 9106 Argon2id + constant-time Poly1305/Argon2id verification) and `VUL-INPUT-001` (strict key/nonce/ciphertext length validation).

## Out of scope
- XChaCha20-Poly1305 24-byte nonces (can be layered via HChaCha20 if requested in the future).
