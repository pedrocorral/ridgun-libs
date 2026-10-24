---
id: FR-CRYPTO-002
title: Provide Argon2id salt generation, auto-salted hashing, PHC parsing, rehash detection, raw key derivation, context pepper/AD, and OWASP presets
type: functional
status: implemented
priority: must
domain: CRYPTO
depends_on: [FR-CRYPTO-001]
related: [ADR-0001, VUL-AUTHN-001, VUL-INPUT-001]
tests: [TS-CRYPTO-002]
---
# FR-CRYPTO-002 — Provide Argon2id salt generation, auto-salted hashing, PHC parsing, rehash detection, raw key derivation, context pepper/AD, and OWASP presets

## Statement
The `argon2id` library SHALL provide cryptographic salt generation (`argon2id generate salt`), one-step auto-salted password hashing (`argon2id hash password`), PHC string parsing (`argon2id parse phc`), parameter upgrade detection (`argon2id needs rehash`), raw key derivation (`argon2id derive key`, `argon2id derive key hex`), optional RFC 9106 `secret` (pepper) and `associated_data` (`argon2id hash with context`, `argon2id verify with context`), and OWASP/RFC parameter presets (`argon2 interactive params`, `argon2 moderate params`, `argon2 sensitive params`).

## Rationale
Standard Argon2id libraries in other languages provide automatic salt generation, one-step password hashing, `needs_rehash` checks for seamless security upgrades, raw key derivation for symmetric encryption keys, and secret pepper / associated data support.

## Acceptance criteria
- AC1: Given a requested salt length (`>= 8` bytes), when `argon2id generate salt` or `argon2id hash password` is called, then it generates an unpredictable salt (mixing OS entropy `/dev/urandom` when available with process/time state) and produces a verifiable `$argon2id$v=19$...` PHC string.
- AC2: Given a PHC string and target `Argon2Params`, when `argon2id parse phc` or `argon2id needs rehash` is called, then `argon2id parse phc` extracts `Argon2Phc` (`params`, `salt_b64`, `tag_b64`) or returns `Argon2PhcErr` on malformed input, and `argon2id needs rehash` returns `True` if any parameter (`m_cost`, `t_cost`, `lanes`, `tag_len`) differs from the target policy (or if the PHC string is malformed) and `False` when they match.
- AC3: Given a password, salt, `Argon2Params` (including OWASP presets `argon2 interactive params`, `argon2 moderate params`, `argon2 sensitive params`), and optional `secret` (pepper) and `ad` (associated data), when `argon2id derive key`, `argon2id derive key hex`, or `argon2id hash with context` / `argon2id verify with context` is called, then raw key derivation returns the exact `tag_len` derived bytes/hex, and context-bound hashes verify only when the matching `secret` and `ad` are supplied.

## Actors & permissions
- Any Ridgun program or lib importing `argon2id`.

## Constraints & edge cases
- `argon2id generate salt` with `< 8` bytes must clamp to at least `16` bytes so generated salts never violate RFC 9106 minimum salt length.

## Data & privacy
- Secrets, peppers, and derived keys are never written to logs or files.

## Security & observability notes
- Mitigates `VUL-AUTHN-001` and `VUL-INPUT-001`.

## Out of scope
- Hardware HSM PKCS#11 offloading.
