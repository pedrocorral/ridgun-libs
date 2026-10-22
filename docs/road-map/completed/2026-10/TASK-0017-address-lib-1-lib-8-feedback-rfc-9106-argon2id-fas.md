---
id: TASK-0017
title: Address LIB-1..LIB-9 feedback: RFC 9106 Argon2id, fast PBKDF2, CSPRNG salt, getrandom check, binary-safe codec, O(log n) str_repeat
status: completed
created: 2026-10-22
completed: 2026-10-22
requirements: [FR-CRYPTO-001, FR-CRYPTO-002, FR-CRYPTO-003, FR-CRYPTO-004, FR-POSIX-002, FR-CODEC-001, FR-STR-001, NFR-PERF-001, API-CRYPTO-001]
tests: [TS-CRYPTO-001, TS-CRYPTO-002, TS-CRYPTO-003, TS-CRYPTO-004, TS-PERF-001, TS-POSIX-002, TS-CODEC-001, TS-STR-001]
security: [VUL-AUTHN-001, VUL-INPUT-001]
context_files: [src/main/ridgun/lib/argon2id.rg, src/main/ridgun/lib/crypto.rg, src/main/ridgun/lib/posix.rg, src/main/ridgun/lib/codec.rg, src/main/ridgun/lib/str.rg]
scope: [src/main/ridgun/lib/argon2id.rg, src/main/ridgun/lib/crypto.rg, src/main/ridgun/lib/posix.rg, src/main/ridgun/lib/codec.rg, src/main/ridgun/lib/str.rg, src/test/ridgun/test_argon2id.rg, src/test/ridgun/test_crypto.rg, src/test/ridgun/test_codec.rg, src/test/ridgun/test_str.rg]
owner: agent-001
claimed: 2026-10-22T12:13:23Z
claimed_by: agent gemini@solarfall
---
# TASK-0017 — Address LIB-1..LIB-9 feedback: RFC 9106 Argon2id, fast PBKDF2, CSPRNG salt, getrandom check, binary-safe codec, O(log n) str_repeat

## Goal (one sentence)
Resolve all 9 findings (`LIB-1` through `LIB-9`) reported in `/tmp/ridgun-lib/requirements/2026-10-22-password-hashing-and-random.md` across `argon2id.rg`, `crypto.rg`, `posix.rg`, `codec.rg`, and `str.rg` with exact RFC 9106 / OpenSSL / libsodium test vectors.

## Plan
- [x] Fix `LIB-6` in `posix.rg`: check `getrandom(2)` (`sys_call 318`) return value, retry on `EINTR` (`-4`), loop on partial reads, and return `(-99, "")` on error.
- [x] Fix `LIB-8` in `codec.rg`: make `hex_decode`, `base64_decode`, `base64url_decode`, and `url_decode` binary-safe (`0..255` raw single-byte strings via `cd_raw_byte`).
- [x] Fix `LIB-9` in `str.rg`: implement `str_repeat` via binary exponentiation (doubling) in $O(\log n)$ steps / linear byte copy.
- [x] Fix `LIB-1`, `LIB-2`, `LIB-3`, `LIB-4`, `LIB-5`, `LIB-7` in `argon2id.rg` and `crypto.rg`: exact RFC 9106 v0x13 Argon2id (`< 30 ms` for `m=19456, t=2, p=1`), fast PBKDF2 (`< 80 ms` for 600,000 iterations), non-colliding `import crypto` + `import argon2id`, OS CSPRNG raw byte salt in `argon2id_generate_salt`, OWASP (`19456` KiB) and RFC 9106 §4 (`65536` KiB) presets, and fixed `(password, phc)` argument order in `argon2id_verify`.
- [x] Add regression tests for `LIB-1`..`LIB-9` in `test_argon2id.rg`, `test_crypto.rg`, `test_codec.rg`, and `test_str.rg`.

## Progress log (append-only, newest last)
- 2026-10-22: Implemented LIB-1..LIB-9 fixes across `posix.rg`, `codec.rg`, `str.rg`, `crypto.rg`, and `argon2id.rg`, and added RFC 9106 §5.3 + OpenSSL 3.5 + Solstice RGF-015 acceptance vectors.

## Files changed (keep current)
- `src/main/ridgun/lib/argon2id.rg`
- `src/main/ridgun/lib/crypto.rg`
- `src/main/ridgun/lib/posix.rg`
- `src/main/ridgun/lib/codec.rg`
- `src/main/ridgun/lib/str.rg`
- `src/test/ridgun/test_argon2id.rg`
- `src/test/ridgun/test_crypto.rg`
- `src/test/ridgun/test_codec.rg`
- `src/test/ridgun/test_str.rg`

## Verification performed (command → result, newest last)
- `stable format && stable check && stable bundle && stable test` → 17/17 modules checked, 17/17 bundles built, 17/17 test suites green (including Solstice RGF-015 acceptance test, RFC 9106 §5.3 official vector, OpenSSL 3.5 vectors, 600k PBKDF2, CSPRNG salt, binary-safe codec roundtrips, and linear `str_repeat`).

## Exact next actions
1. None (task complete).

## Decisions / open questions
- None.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
