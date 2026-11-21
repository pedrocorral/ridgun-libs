---
id: FR-CRYPTO-007
title: Provide AES-256 and AES-256-GCM, and give the same results on the instructions of the processor and without them
type: functional
status: implemented
priority: must
domain: CRYPTO
depends_on: [FR-CRYPTO-003, FR-CRYPTO-006]
related: [ADR-0016, ADR-0014, API-CRYPTO-001, VUL-AUTHN-001, VUL-INPUT-001]
tests: [TS-CRYPTO-007]
---
# FR-CRYPTO-007 — Provide AES-256 and AES-256-GCM, and give the same results on the instructions of the processor and without them

## Statement
The `crypto` lib SHALL provide AES-256 block encryption and AES-256-GCM next to AES-128, and SHALL give the same result for SHA-256, PBKDF2-HMAC-SHA-256 and AES whether the program uses the SHA and AES instructions of the processor or the portable definitions.

## Rationale
The compiler no longer carries any cipher or hash: since ridgunc 1.0.51 a lib writes them as processor operations (`cpu op`), each with a portable definition (asked of libs on 2026-11-21, `cpu-op-para-libs.md`). AES-256 was asked for in the same note. A program must not depend on which processor it runs on.

## Acceptance criteria
- AC1: Given a 32-byte key and a 16-byte block, when `aes256 block` runs, then the result is the block of FIPS 197 Appendix C.3; a key or a block of another length gives `""`.
- AC2: Given a 32-byte key, a 12-byte nonce, associated data and a plaintext, when `aes256 gcm seal` runs, then the result is the ciphertext followed by the 16-byte tag of NIST SP 800-38D (test cases 13, 14 and 16 of McGrew and Viega); a key or a nonce of another length gives `""`.
- AC3: Given what `aes256 gcm seal` returned, when `aes256 gcm open` runs with the same key, nonce and associated data, then it returns `0` and the plaintext. With other associated data or one changed byte it returns `-12` and no plaintext; with a key or a nonce of another length, `-7`.
- AC4: Given SHA-256 of messages of every length from 0 to 300 bytes and of 70 000 bytes, PBKDF2-HMAC-SHA-256 with passwords and salts shorter and longer than a block, and AES-128 and AES-256 in block, counter and GCM use, when the program runs with `RIDGUN_CPU=2` (portable definitions), then every result is the same as without it.
- AC5: Given a message of 512 bytes or more, when `sha256 bytes` or `sha256 hex` runs, then the digest is computed on the processor operations and equals the digest of the runtime.

## Actors & permissions
- Any Ridgun program or lib importing `crypto`.

## Constraints & edge cases
- `sha256 bytes` and `sha256 hex` of messages shorter than 512 bytes use the SHA-256 of the runtime: with ridgunc 1.0.51 the fixed cost of preparing a message for the operations is larger than what the instructions save (`ADR-0016`).
- The variants of the operations exist for x86-64 only. On other processors the portable definitions run.
- The counter of GCM wraps at 2^32 blocks, as NIST SP 800-38D says.

## Data & privacy
- Keys and plaintexts are held in memory only for the call.

## Security & observability notes
- `VUL-AUTHN-001`: `aes256 gcm open` compares the tag in constant time and gives no plaintext before the tag is checked.
- `VUL-INPUT-001`: keys, nonces and blocks of the wrong length are refused.
- The table lookups of the portable AES definition are not constant-time; the variant on the AES instructions is.

## Out of scope
- AES-192, and modes other than counter and GCM.
- GHASH on processor operations: it needs 64-bit carry-less products, which the operations do not have yet.
