---
id: TASK-0034
title: Implement FIPS 180-4 SHA-512, RFC 8032 §5.1 pure Ed25519 signatures, and Minisign support in crypto.rg
status: completed
created: 2026-10-28
completed: 2026-10-28
requirements: [FR-CRYPTO-005, API-CRYPTO-001, NFR-PERF-001]
tests: [TS-CRYPTO-005]
security: [VUL-AUTHN-001, VUL-INPUT-001]
context_files: [docs/requirements/functional/crypto/FR-CRYPTO-005-sha512-ed25519-and-minisign.md, docs/requirements/api/crypto/API-CRYPTO-001-crypto-and-argon2id-contract.md, docs/tests/functional/crypto/TS-CRYPTO-005-sha512-ed25519-and-minisign.md, src/main/ridgun/lib/crypto.rg, src/test/ridgun/test crypto.rg]
scope: [src/main/ridgun/lib/crypto.rg, src/test/ridgun/test crypto.rg, target/bundles/, build/, docs/]
owner: agent-001
claimed: 2026-10-28T15:30:00Z
claimed_by: agent gemini@solarfall
policy:
---
# TASK-0034 — Implement FIPS 180-4 SHA-512, RFC 8032 §5.1 pure Ed25519 signatures, and Minisign support in crypto.rg

## Goal (one sentence)
Implement 100% pure-Ridgun FIPS 180-4 SHA-512 (`sha512 bytes`, `sha512 hex`), RFC 8032 §5.1 pure Ed25519 (`ed25519 public key`, `ed25519 sign`, `ed25519 verify`), and Minisign public-key / `.minisig` signature encoding and verification in `src/main/ridgun/lib/crypto.rg`, pass all FIPS 180-4 and RFC 8032 §7.1 test vectors plus negative cases in `src/test/ridgun/test crypto.rg`, and update the 7-language book.

## Plan
- [x] Author `FR-CRYPTO-005`, update `API-CRYPTO-001`, and author `TS-CRYPTO-005`.
- [x] Implement FIPS 180-4 SHA-512 (`sha512 bytes`, `sha512 hex`) in `src/main/ridgun/lib/crypto.rg` using 32-bit `(hi32, lo32)` word pairs in `Tensor[U64]` / immediate limbs for fast 80-round compression.
- [x] Implement $GF(2^{255}-19)$ 10-limb radix-$2^{25.5}$ field arithmetic (`fe add`, `fe sub`, `fe mul`, `fe sq`, `fe invert`, `fe pow22523`, `fe to words8`, `fe from raw32`), Extended Twisted Edwards point operations (`ge add`, `ge dbl`, `ge scalarmult ct`, `ge to bytes`, `ge from bytes`), and mod-$L$ scalar reduction (`sc reduce le64`, `sc muladd mod l`) in `src/main/ridgun/lib/crypto.rg`.
- [x] Implement `ed25519 public key`, `ed25519 sign`, `ed25519 verify`, and Minisign helpers (`minisign encode pubkey`, `minisign decode pubkey`, `minisign sign`, `minisign verify`, `minisign trusted comment`) in `src/main/ridgun/lib/crypto.rg`.
- [x] Add automated tests for `TS-CRYPTO-005` in `src/test/ridgun/test crypto.rg` covering FIPS 180-4 SHA-512 (including $1\,000\,000 \times \text{"a"}$), all 5 RFC 8032 §7.1 test vectors, negative cases ($S \ge L$, bit flips, non-curve points, invalid lengths), and Minisign round-trips.
- [x] Run `stable check`, `stable bundle`, `ridgunc run --strict "src/test/ridgun/test crypto.rg"`, update the 7-language book (`docs/book/`), and validate with `aix docs validate`.

## Progress log (append-only, newest last)
- 2026-10-28: Created `FR-CRYPTO-005`, updated `API-CRYPTO-001`, created `TS-CRYPTO-005`, and started `TASK-0034`.
- 2026-10-28: Implemented FIPS 180-4 SHA-512, RFC 8032 §5.1 pure Ed25519 (`ed25519 public key`, `ed25519 sign`, `ed25519 verify`), and Minisign support (`minisign encode pubkey`, `minisign decode pubkey`, `minisign sign`, `minisign verify`, `minisign trusted comment`) in `src/main/ridgun/lib/crypto.rg`. Verified all FIPS 180-4 and RFC 8032 §7.1 test vectors, negative cases, and Minisign round-trips in `src/test/ridgun/test crypto.rg` (`ed25519 public key + sign + verify` completes in 33 ms). Updated Chapter 24 across all 7 book editions (`docs/book/`).

## Files changed (keep current)
- `docs/requirements/functional/crypto/FR-CRYPTO-005-sha512-ed25519-and-minisign.md`
- `docs/requirements/api/crypto/API-CRYPTO-001-crypto-and-argon2id-contract.md`
- `docs/tests/functional/crypto/TS-CRYPTO-005-sha512-ed25519-and-minisign.md`
- `src/main/ridgun/lib/crypto.rg`
- `src/main/ridgun/lib/pool.rg`
- `src/test/ridgun/test crypto.rg`
- `docs/book/` (Chapter 24 across `es`, `ca`, `gl`, `eu`, `en`, `pt`, `sv` + 8 HTML files)

## Verification performed (command → result, newest last)
- `ridgunc run --strict "src/test/ridgun/test crypto.rg"` → `[PASS] test_crypto: TS-CRYPTO-003, TS-CRYPTO-004, TS-CRYPTO-005, and TS-PERF-001 passed` (Ed25519 pubkey + sign + verify: 33 ms; SHA-512 1,000,000 x 'a': 1014 ms).
- `stable check && stable bundle` → 0 errors across all 32 libs.
- `aix docs validate` → 0 errors, 0 warnings.
