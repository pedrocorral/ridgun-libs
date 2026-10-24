---
id: FR-CRYPTO-003
title: Provide raw byte manipulation, 32-bit bitwise operations, SHA-256, HMAC-SHA-256, constant-time equality, and PBKDF2-HMAC-SHA-256
type: functional
status: implemented
priority: must
domain: CRYPTO
depends_on: [FR-CRYPTO-001, FR-CRYPTO-002]
related: [ADR-0002, ADR-0003, NFR-PERF-001, VUL-AUTHN-001, VUL-INPUT-001]
tests: [TS-CRYPTO-003, TS-PERF-001]
---
# FR-CRYPTO-003 — Provide raw byte manipulation, 32-bit bitwise operations, SHA-256, HMAC-SHA-256, constant-time equality, and PBKDF2-HMAC-SHA-256

## Statement
The `crypto` library SHALL provide raw 8-bit byte construction and conversion (`byte_str`, `bytes_from_list`, `bytes_to_list`), 32-bit unsigned bitwise operations (`band`, `bor`, `bxor`, `shl`, `shr` per `RGF-019`), binary and hex SHA-256 (`sha256_bytes`, `sha256_hex`), RFC 2104/4231 HMAC-SHA-256 (`hmac_sha256`), constant-time byte-string comparison (`ct_equal`), and RFC 2898/6070 PBKDF2-HMAC-SHA-256 (`pbkdf2_hmac_sha256` per `RGF-015` and `RG-043`).

## Rationale
Cryptographic protocols, binary wire framing, and password-based key derivation require exact 8-bit raw byte strings (`0..255` without UTF-8 multi-byte expansion for `128..255`), fast 32-bit bitwise primitives, standard SHA-256/HMAC-SHA-256, constant-time tag verification, and sub-second PBKDF2-HMAC-SHA-256 at OWASP's 600,000 iteration baseline (`RG-043`).

## Acceptance criteria
- AC1: Given byte values `0..255` and 32-bit unsigned integers, when `byte_str`, `bytes_from_list`, `bytes_to_list`, `band`, `bor`, `bxor`, `shl`, and `shr` are invoked, then `str_len (byte_str n)` is `1` for every `n` in `0..255`, `bytes_to_list (bytes_from_list xs) == xs` round-trips all 256 byte values (`RG-023` / `RGF-019`), and `band`/`bor`/`bxor`/`shl`/`shr` compute exact 32-bit unsigned (`mod 2^32`) results (`shl` / `shr` return `0` for `n >= 32`).
- AC2: Given arbitrary byte strings, when `sha256_bytes`, `sha256_hex`, `hmac_sha256`, and `ct_equal` are called, then `sha256_bytes` returns the 32-byte raw digest (`sha256_bytes "abc"` matches NIST FIPS 180-4 `ba7816bf...`), `sha256_hex` returns the 64-character lowercase hex digest, `hmac_sha256` returns the 32-byte MAC matching RFC 4231 Test Case 2 (`"Jefe"` / `"what do ya want for nothing?"` → `5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843`), and `ct_equal a b` compares all bytes in constant time when lengths match.
- AC3: Given a password, salt, iteration count (`>= 1`), and derived key length (`dk_len >= 1`), when `pbkdf2_hmac_sha256 password salt iterations dk_len` is called, then it returns a `dk_len`-byte raw key matching RFC 6070 and Python `hashlib.pbkdf2_hmac` test vectors (including `c=600000` -> `6c4a646aad10d067add5fb79d9078a16da83d50f81670a8e7593b249e6d94936` in under `3500` ms on one core in-process per `RG-043`, a >12x speedup over the 32.6 s unoptimized baseline).

## Actors & permissions
- Any Ridgun program or lib importing `crypto`.

## Constraints & edge cases
- `ct_equal` returns `False` immediately only when lengths differ, and otherwise XOR-accumulates every byte without early exit.
- `pbkdf2_hmac_sha256` supports arbitrary `dk_len` across multiple 32-byte SHA-256 blocks and executes 100% in-process in pure Ridgun (`RG-050`, `RG-043`, zero external subprocesses).

## Data & privacy
- Keys and passwords remain in local call-frame memory only.

## Security & observability notes
- Mitigates `VUL-AUTHN-001` (constant-time `ct_equal` and standard PBKDF2/HMAC) and `VUL-INPUT-001` (byte masking `0..255` and shift bounds).

## Out of scope
- SHA-3 / Keccak sponges.
