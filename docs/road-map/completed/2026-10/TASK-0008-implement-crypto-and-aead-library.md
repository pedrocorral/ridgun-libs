---
id: TASK-0008
title: Implement crypto.ridgun and extend argon2id.ridgun (bytes, bitops, SHA-256, HMAC, PBKDF2, 5-arg Argon2id, ChaCha20-Poly1305 AEAD)
status: completed
created: 2026-10-21
completed: 2026-10-21
requirements: [FR-CRYPTO-003, FR-CRYPTO-004, NFR-PERF-001]
tests: [TS-CRYPTO-003, TS-CRYPTO-004, TS-PERF-001]
security: [VUL-AUTHN-001, VUL-INPUT-001]
context_files: [docs/requirements/functional/crypto/FR-CRYPTO-003-bytes-bitops-sha256-hmac-pbkdf2.md, docs/requirements/functional/crypto/FR-CRYPTO-004-solstice-argon2id-and-chacha20-poly1305-aead.md, docs/requirements/non-functional/NFR-PERF-001-crypto-and-io-latency.md, docs/requirements/data-model/DM-Argon2.md, docs/requirements/api/crypto/API-CRYPTO-001-crypto-and-argon2id-contract.md, docs/tests/functional/crypto/TS-CRYPTO-003-bytes-bitops-sha256-hmac-pbkdf2.md, docs/tests/functional/crypto/TS-CRYPTO-004-solstice-argon2id-and-chacha20-poly1305-aead.md, docs/tests/non-functional/perf/TS-PERF-001-argon2id-and-poll-timeout-bounds.md, src/main/ridgun/lib/argon2id.ridgun, src/main/ridgun/lib/crypto.ridgun, src/test/ridgun/test argon2id.ridgun, src/test/ridgun/test crypto.ridgun]
scope: [src/main/ridgun/lib/argon2id.ridgun, src/main/ridgun/lib/crypto.ridgun, src/test/ridgun/test argon2id.ridgun, src/test/ridgun/test crypto.ridgun]
owner: agent-001
claimed: 2026-10-21T19:07:38Z
claimed_by: agent gemini@solarfall
---
# TASK-0008 — Implement `crypto.ridgun` and extend `argon2id.ridgun` (bytes, bitops, SHA-256, HMAC, PBKDF2, 5-arg Argon2id, ChaCha20-Poly1305 AEAD)

## Goal (one sentence)
Implement `src/main/ridgun/lib/crypto.ridgun` (`crypto.ridgunlib` / `libcrypto.so`) and extend `src/main/ridgun/lib/argon2id.ridgun` with `RGF-019` byte/bitwise primitives, `sha256_bytes`, `sha256_hex`, `hmac_sha256`, `ct_equal`, `pbkdf2_hmac_sha256`, 5-arg `argon2id_hash`/`argon2id_verify`, and RFC 8439 ChaCha20-Poly1305 `aead_seal`/`aead_open` (`FR-CRYPTO-003`, `FR-CRYPTO-004`, `API-CRYPTO-001`, `NFR-PERF-001`).

## Plan
- [x] Implement `byte_str`, `bytes_from_list`, `bytes_to_list`, `band`, `bor`, `bxor`, `shl`, `shr`, `sha256_bytes`, `sha256_hex`, `hmac_sha256`, `ct_equal`, and `pbkdf2_hmac_sha256` in `src/main/ridgun/lib/crypto.ridgun` (`@implements FR-CRYPTO-003`, `@implements API-CRYPTO-001`).
- [x] Implement 5-arg `argon2id_hash` and `argon2id_verify` and RFC 8439 ChaCha20-Poly1305 `aead_seal` and `aead_open` in `src/main/ridgun/lib/crypto.ridgun` and `src/main/ridgun/lib/argon2id.ridgun` (`@implements FR-CRYPTO-004`, `@implements NFR-PERF-001`, `@mitigates VUL-AUTHN-001`, `@mitigates VUL-INPUT-001`).
- [x] Automate `TS-CRYPTO-003`, `TS-CRYPTO-004`, and `TS-PERF-001` in `src/test/ridgun/test crypto.ridgun` against official NIST/RFC test vectors and verify with `stable check` and `stable test`.

## Progress log (append-only, newest last)
- 2026-10-21: Task created and planned.
- 2026-10-21: Implemented `src/main/ridgun/lib/crypto.ridgun` (96 functions), extended `src/main/ridgun/lib/argon2id.ridgun` with 5-arg `argon2id_hash`, and automated `TS-CRYPTO-003`, `TS-CRYPTO-004`, and `TS-PERF-001` in `src/test/ridgun/test crypto.ridgun`. Also updated `posix.ridgun` and `io.ridgun` (`io read with timeout`) to match `/tmp/ridgun_posix_io_library_spec.md` §3.1/§3.2.

## Files changed (keep current)
- `src/main/ridgun/lib/crypto.ridgun`
- `src/main/ridgun/lib/argon2id.ridgun`
- `src/test/ridgun/test crypto.ridgun`
- `src/main/ridgun/lib/posix.ridgun`
- `src/main/ridgun/lib/io.ridgun`
- `src/test/ridgun/test posix.ridgun`
- `src/test/ridgun/test io.ridgun`

## Verification performed (command → result, newest last)
- `stable format && stable check && stable test` → `Checked 7 module(s) — 0 errors; Passed 7/7 test suite(s) — 0 failures.`

## Exact next actions
1. Start `TASK-0009` (`socket.ridgun` `RGF-001` TCP/Unix syscalls & full `.rgc`/`.so`/`.ridgunlib` packaging).

## Decisions / open questions
- None (`ADR-0002`).

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
