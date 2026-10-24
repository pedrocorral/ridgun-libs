---
id: FR-CRYPTO-001
title: Hash and verify passwords with Argon2id PHC strings
type: functional
status: implemented
priority: must
domain: CRYPTO
depends_on: []
related: [ADR-0001, VUL-AUTHN-001, VUL-INPUT-001]
tests: [TS-CRYPTO-001]
---
# FR-CRYPTO-001 — Hash and verify passwords with Argon2id PHC strings

## Statement
The `argon2id` library SHALL hash passwords into canonical PHC-formatted strings (`$argon2id$v=19$m=...,t=...,p=...$<salt_b64>$<hash_b64>`) according to RFC 9106 (Argon2id `y = 2`, version `0x13 = 19`, with internal Blake2b / `H'` compression) and verify passwords against PHC strings in constant time.

## Rationale
Applications need memory-hard password hashing and constant-time password verification in pure Ridgun with a simple PHC string API (`argon2id hash`, `argon2id verify`), keeping low-level Blake2b compression internal.

## Acceptance criteria
- AC1: Given valid RFC 9106 Argon2id parameters (`t_cost >= 1`, `lanes >= 1`, `m_cost >= 8 * lanes`, `tag_len >= 4`, `salt` `>= 8` bytes) and a password, when `argon2id hash` is invoked, then it executes internal Blake2b `H_0`/`H'` and Argon2id memory-matrix compression (`G`) and returns `Argon2Ok` with a canonical unpadded Base64 PHC string `$argon2id$v=19$m=<m>,t=<t>,p=<p>$<salt_b64>$<tag_b64>`.
- AC2: Given invalid Argon2id parameters (`t_cost < 1`, `lanes < 1`, `m_cost < 8 * lanes`, `tag_len < 4`, or `salt` shorter than 8 bytes), when `argon2id hash` is called, then it returns `Argon2Err` describing the invalid parameter without executing memory-matrix hashing.
- AC3: Given a valid `$argon2id$v=19$...` PHC string and a candidate password, when `argon2id verify` is called, then it returns `True` for the matching password and `False` for any non-matching password or malformed PHC string using constant-time comparison (`constant time eq`).

## Actors & permissions
- Any Ridgun program or lib importing `argon2id`.

## Constraints & edge cases
- PHC Base64 encoding and decoding must use standard RFC 4648 alphabet without `=` padding characters, as required by the PHC string format specification, and must never emit or accept a PHC string with an empty `<tag_b64>` segment (`RG-051`).
- Internal Blake2b and 64-bit word arithmetic remain 100% in-process pure-Ridgun implementation details of `argon2id` (`RG-050`, zero external subprocesses).

## Data & privacy
- Password and derived tag bytes are processed in-memory and never logged (`VUL-LOG-001` / `VUL-SECRET-001`).

## Security & observability notes
- Mitigates `VUL-AUTHN-001` (memory-hard Argon2id password hashing and constant-time tag verification) and `VUL-INPUT-001` (strict parameter & PHC string parsing).

## Out of scope
- Public standalone Blake2b module API or CLI executable.
