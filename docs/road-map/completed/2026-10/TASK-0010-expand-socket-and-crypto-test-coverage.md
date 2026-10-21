---
id: TASK-0010
title: Expand comprehensive edge-case test coverage for socket, crypto, and argon2id libraries
status: completed
created: 2026-10-21
completed: 2026-10-21
requirements: [FR-SOCK-001, FR-SOCK-002, FR-SOCK-003, FR-SOCK-004, FR-CRYPTO-001, FR-CRYPTO-002, FR-CRYPTO-003, FR-CRYPTO-004, NFR-SEC-001]
tests: [TS-SOCK-001, TS-SOCK-002, TS-SOCK-003, TS-SOCK-004, TS-CRYPTO-001, TS-CRYPTO-002, TS-CRYPTO-003, TS-CRYPTO-004, TS-SEC-001]
security: [VUL-INJ-002, VUL-AUTHN-001, VUL-INPUT-001]
context_files: [build.rg, src/main/ridgun/lib/socket.rg, src/main/ridgun/lib/crypto.rg, src/main/ridgun/lib/argon2id.rg, src/test/ridgun/test_socket.rg, src/test/ridgun/test_crypto.rg, src/test/ridgun/test_argon2id.rg]
scope: [build.rg, src/main/ridgun/lib/socket.rg, src/test/ridgun/test_socket.rg, src/test/ridgun/test_crypto.rg, src/test/ridgun/test_argon2id.rg]
owner: agent-001
claimed: 2026-10-21T20:06:47Z
claimed_by: agent gemini@solarfall
---
# TASK-0010 — Expand comprehensive edge-case test coverage for `socket`, `crypto`, and `argon2id` libraries

## Goal (one sentence)
Expand `src/test/ridgun/test_socket.rg`, `src/test/ridgun/test_crypto.rg`, and `src/test/ridgun/test_argon2id.rg` to thoroughly cover all boundary, negative, multi-message, raw binary, and cryptographic edge cases across `socket.rg`, `crypto.rg`, and `argon2id.rg`.

## Plan
- [x] Expand `src/test/ridgun/test_socket.rg` to cover all socket families (`sock tcp6`, `sock udp6`, `sock unix stream`, `sock unix dgram`), full option validation (`sock set options`), shutdown modes (`rd`, `wr`, `rdwr`, invalid), multi-client accept queue, partial/chunked `sys_recv`, raw binary (`0..255`) + ChaCha20-Poly1305 AEAD ciphertext transport over `sys_send`/`sys_recv`, `sys_send` after `sys_shutdown_write` (`-4` `RESET`), privileged port rejection (`-6` `PERMISSION`), closed-fd operations (`-7` `INVALID`), `sys_recv` timeout (`-2` `TIMEOUT`), and Unix connect refusal (`-3` `REFUSED`).
- [x] Expand `src/test/ridgun/test_crypto.rg` to cover full 256-byte (`0..255`) round-trip, negative/overflow byte normalization (`byte str -1`, `byte str 256`), negative shift amounts (`shl 1 -1`, `shr 1 -1`), empty-string SHA-256 (`e3b0c442...`), HMAC-SHA-256 with key > 64 bytes (RFC 4231 Test Case 6/7), multi-block PBKDF2 (`dk_len = 64`), invalid PBKDF2 parameters (`iterations = 0`, `dk_len = 0`), 5-arg `argon2id_hash` invalid parameter rejection (`m < 8*p`, `t < 1`, short salt), and ChaCha20-Poly1305 AEAD edge cases (empty plaintext, empty AAD, >64B multi-block plaintext, modified ciphertext byte, modified nonce byte, truncated ciphertext `< 16` bytes, invalid nonce length).
- [x] Expand `src/test/ridgun/test_argon2id.rg` to cover `default argon2 params`, `t_cost`/`lanes`/`tag_len` parameter upgrade detection in `argon2id needs rehash`, `argon2id derive key` invalid parameter rejection, and `argon2id hash ctx` invalid parameter rejection.

## Progress log (append-only, newest last)
- 2026-10-21: Created `TASK-0010` to expand edge-case coverage across `socket`, `crypto`, and `argon2id`.
- 2026-10-21: Upgraded `send_to_tx_base`, `consume_rx_fd`, and `sock_lstat_size` in `src/main/ridgun/lib/socket.rg` so `sys_send`/`sys_recv` use raw descriptor I/O (`sys_open` with `O_TRUNC=577` + `sys_read_fd`/`sys_write_fd`) and preserve binary octets (`0..255`) and exact `max_bytes` chunking.
- 2026-10-21: Updated `task bundle` in `build.rg` to write per-module `.rglib` bundles to `target/bundles/` so `stable test` never duplicates module definitions in `target/`.
- 2026-10-21: Expanded `src/test/ridgun/test_socket.rg`, `src/test/ridgun/test_crypto.rg`, and `src/test/ridgun/test_argon2id.rg` and verified `7/7` test suites pass.

## Files changed (keep current)
- `build.rg`
- `src/main/ridgun/lib/socket.rg`
- `src/test/ridgun/test_socket.rg`
- `src/test/ridgun/test_crypto.rg`
- `src/test/ridgun/test_argon2id.rg`

## Verification performed (command → result, newest last)
- `stable format && stable check && stable bundle && stable test` → `Checked 7 module(s) — 0 errors; Passed 7/7 test suite(s) — 0 failures.`
- `aix docs coverage && aix docs validate` → `0 errors, 0 warnings`

## Exact next actions
1. Task complete.

## Decisions / open questions
- None.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
