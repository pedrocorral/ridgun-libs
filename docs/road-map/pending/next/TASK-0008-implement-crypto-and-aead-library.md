---
id: TASK-0008
title: Implement crypto.rg and extend argon2id.rg (bytes, bitops, SHA-256, HMAC, PBKDF2, 5-arg Argon2id, ChaCha20-Poly1305 AEAD)
status: pending
created: 2026-10-21
completed:
requirements: [FR-CRYPTO-003, FR-CRYPTO-004, NFR-PERF-001]
tests: [TS-CRYPTO-003, TS-CRYPTO-004, TS-PERF-001]
security: [VUL-AUTHN-001, VUL-INPUT-001]
context_files: [docs/requirements/functional/crypto/FR-CRYPTO-003-bytes-bitops-sha256-hmac-pbkdf2.md, docs/requirements/functional/crypto/FR-CRYPTO-004-solstice-argon2id-and-chacha20-poly1305-aead.md, docs/requirements/non-functional/NFR-PERF-001-crypto-and-io-latency.md, docs/requirements/data-model/DM-Argon2.md, docs/requirements/api/crypto/API-CRYPTO-001-crypto-and-argon2id-contract.md, docs/tests/functional/crypto/TS-CRYPTO-003-bytes-bitops-sha256-hmac-pbkdf2.md, docs/tests/functional/crypto/TS-CRYPTO-004-solstice-argon2id-and-chacha20-poly1305-aead.md, docs/tests/non-functional/perf/TS-PERF-001-argon2id-and-poll-timeout-bounds.md, src/main/ridgun/lib/argon2id.rg, src/main/ridgun/lib/crypto.rg, src/test/ridgun/test_argon2id.rg, src/test/ridgun/test_crypto.rg]
scope: [src/main/ridgun/lib/argon2id.rg, src/main/ridgun/lib/crypto.rg, src/test/ridgun/test_argon2id.rg, src/test/ridgun/test_crypto.rg]
owner:
claimed:
claimed_by:
policy:
---
# TASK-0008 — Implement `crypto.rg` and extend `argon2id.rg` (bytes, bitops, SHA-256, HMAC, PBKDF2, 5-arg Argon2id, ChaCha20-Poly1305 AEAD)

## Goal (one sentence)
Implement `src/main/ridgun/lib/crypto.rg` (`crypto.rglib` / `libcrypto.so`) and extend `src/main/ridgun/lib/argon2id.rg` with `RGF-019` byte/bitwise primitives, `sha256_bytes`, `sha256_hex`, `hmac_sha256`, `ct_equal`, `pbkdf2_hmac_sha256`, 5-arg `argon2id_hash`/`argon2id_verify`, and RFC 8439 ChaCha20-Poly1305 `aead_seal`/`aead_open` (`FR-CRYPTO-003`, `FR-CRYPTO-004`, `API-CRYPTO-001`, `NFR-PERF-001`).

## Plan
- [ ] Implement `byte_str`, `bytes_from_list`, `bytes_to_list`, `band`, `bor`, `bxor`, `shl`, `shr`, `sha256_bytes`, `sha256_hex`, `hmac_sha256`, `ct_equal`, and `pbkdf2_hmac_sha256` in `src/main/ridgun/lib/crypto.rg` (`@implements FR-CRYPTO-003`, `@implements API-CRYPTO-001`).
- [ ] Implement 5-arg `argon2id_hash` and `argon2id_verify` and RFC 8439 ChaCha20-Poly1305 `aead_seal` and `aead_open` in `src/main/ridgun/lib/crypto.rg` and `src/main/ridgun/lib/argon2id.rg` (`@implements FR-CRYPTO-004`, `@implements NFR-PERF-001`, `@mitigates VUL-AUTHN-001`, `@mitigates VUL-INPUT-001`).
- [ ] Automate `TS-CRYPTO-003`, `TS-CRYPTO-004`, and `TS-PERF-001` in `src/test/ridgun/test_crypto.rg` against official NIST/RFC test vectors and verify with `stable check` and `stable test`.

## Progress log (append-only, newest last)
- 2026-10-21: Task created and planned.

## Files changed (keep current)
-

## Verification performed (command → result, newest last)
-

## Exact next actions
1. Start `TASK-0008` after `TASK-0007` and implement `crypto.rg`, `argon2id.rg` extensions, and `test_crypto.rg`.

## Decisions / open questions
- None (`ADR-0002`).

## Definition of done checklist
- [ ] requirements referenced are `implemented`  - [ ] tests automated & green
- [ ] security entries updated  - [ ] docs INDEX updated  - [ ] coverage matrix regenerated
