---
id: ADR-0002
title: Adopt Solstice runtime requirements and POSIX/IO library specifications across ridgun-libs
status: accepted
date: 2026-10-21
supersedes: []
affects: [FR-SOCK-001, FR-SOCK-002, FR-SOCK-003, FR-SOCK-004, FR-CRYPTO-001, FR-CRYPTO-002, FR-CRYPTO-003, FR-CRYPTO-004, FR-POSIX-001, FR-POSIX-002, FR-IO-001, FR-IO-002, FR-STR-001, FR-TST-001, TS-SOCK-004, TS-CRYPTO-003, TS-CRYPTO-004, TS-POSIX-001, TS-POSIX-002, TS-IO-001, TS-IO-002, TS-STR-001, TS-TST-001, src/main/ridgun/lib/socket.rg, src/main/ridgun/lib/argon2id.rg, src/main/ridgun/lib/crypto.rg, src/main/ridgun/lib/posix.rg, src/main/ridgun/lib/io.rg, src/main/ridgun/lib/str.rg, src/main/ridgun/lib/test.rg]
---
# ADR-0002 — Adopt Solstice runtime requirements and POSIX/IO library specifications across ridgun-libs

## Context
Following the review of `/tmp/ridgun-lib/requirements/` (Solstice runtime and standard library requirements: `RGF-001`, `RGF-014`..`RGF-019`, `RG-010`, `RG-011`) and `/tmp/ridgun_posix_io_library_spec.md` (Ridgun `v0.9.3` `posix.rglib` and `io.rglib` specification using Layer 1 kernel primitives `sys open`, `sys close`, `sys read fd`, `sys write fd`, `sys poll`, `sys kill`, `sys call`), `CONFLICT-0001` recorded the gap between our initial `socket.rg` / `argon2id.rg` / `test.rg` modules and the full suite of libraries needed by downstream Ridgun applications (`posix`, `io`, `str`, `crypto`, `socket`, `argon2id`, `test`).

## Options considered
1. **Expand `ridgun-libs` into a complete 7-module library suite (`socket`, `argon2id`, `crypto`, `posix`, `io`, `str`, `test`) that satisfies both the high-level typed Ridgun APIs and the exact Solstice / `posix.rglib` / `io.rglib` contracts**: Keep all existing `FR-SOCK-001..003` and `FR-CRYPTO-001..002` capabilities while adding `FR-SOCK-004`, `FR-CRYPTO-003..004`, `FR-POSIX-001..002`, `FR-IO-001..002`, `FR-STR-001`, and `FR-TST-001`.
2. **Maintain only the original `socket` and `argon2id` modules**: Leaves downstream projects without `posix`, `io`, `str`, `crypto` (ChaCha20-Poly1305, HMAC-SHA256, PBKDF2, byte/bit ops), and `test`.

## Decision
We adopt **Option 1** (`CONFLICT-0001` resolved):
- **`SOCK` (`src/main/ridgun/lib/socket.rg`)**: Preserve `FR-SOCK-001..003` and add `FR-SOCK-004` providing the Solstice `RGF-001` kernel-backed socket API (`sys_tcp_listen`, `sys_unix_listen`, `sys_local_port`, `sys_accept`, `sys_tcp_connect`, `sys_unix_connect`, `sys_recv`, `sys_send`, `sys_shutdown_write`, `sys_close`) with `(status, ...)` error tuples (`0`, `-1`..`-12`, `-99`) and millisecond timeouts via `sys poll` and `sys call`.
- **`CRYPTO` (`src/main/ridgun/lib/argon2id.rg` & `src/main/ridgun/lib/crypto.rg`)**: Preserve `FR-CRYPTO-001..002` and add `FR-CRYPTO-003` (byte manipulation and 32-bit unsigned bitwise operations `RGF-019`: `byte_str`, `bytes_from_list`, `bytes_to_list`, `band`, `bor`, `bxor`, `shl`, `shr`, plus `sha256_bytes`, `sha256_hex`, `hmac_sha256`, `ct_equal`, `pbkdf2_hmac_sha256`) and `FR-CRYPTO-004` (RFC 9106 64-bit Blake2b `argon2id_hash` 5-arg / `argon2id_verify` `(pwd, phc)` and RFC 8439 ChaCha20-Poly1305 `aead_seal` / `aead_open` `RGF-015`).
- **`POSIX` (`src/main/ridgun/lib/posix.rg`)**: Add `FR-POSIX-001` (typed descriptor wrappers, `PollStatus = PollReady Int | PollTimeout | PollError Int`, `ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int`, `poll in/out/err`, `sig term/kill/int/hup/usr1/usr2`, `wait fd` over `sys poll`, open flags, pipe/process helpers) and `FR-POSIX-002` (filesystem & process wrappers `RG-010`, monotonic/wall clocks `RGF-017` `sys_time_ms`, `sys_monotonic_ms`, `sys_monotonic_ns`, `sys_sleep_ms`, signal watching `RGF-018` `sys_signal_watch`, `sys_signal_wait`, and CSPRNG `RGF-014` `sys_random_bytes`).
- **`IO` (`src/main/ridgun/lib/io.rg`)**: Add `FR-IO-001` (extensible `IoError = Timeout Int | Eof | SysErr Int String | NotFound String`, `IoResult = String | Int | IoError`, `format io error`, `read fd` / `read fd after poll` with timeout, `write fd` with timeout, and `exec with timeout`) and `FR-IO-002` (high-level file predicates and metadata `RG-010`: `append_file`, `file_exists`, `is_dir`, `is_file`, `is_symlink`, `file_size`, `file_mtime`, `file_mode`, stream line helpers).
- **`STR` (`src/main/ridgun/lib/str.rg`)**: Add `FR-STR-001` (`RG-010` string utilities: `str_index_of`, `str_trim`, `str_replace`, `str_split`, `str_to_upper`, `str_to_lower`, plus natural-space Ridgun aliases).
- **`TEST` (`src/main/ridgun/lib/test.rg`)**: Add `FR-TST-001` (`RG-011` test assertion library exporting both 3-arg `assert_equals a b msg` / 2-arg `assert_true cond msg` and 2-arg/1-arg helpers).

## Consequences
- Requirements to update/create: `PRODUCT-VISION`, `PRODUCT-GLOSSARY`, `PRODUCT-PERSONAS`, `DATA-FIELD-DICTIONARY`, `FR-SOCK-004`, `FR-CRYPTO-003`, `FR-CRYPTO-004`, `FR-POSIX-001`, `FR-POSIX-002`, `FR-IO-001`, `FR-IO-002`, `FR-STR-001`, `FR-TST-001`.
- Tests to create: `TS-SOCK-004`, `TS-CRYPTO-003`, `TS-CRYPTO-004`, `TS-POSIX-001`, `TS-POSIX-002`, `TS-IO-001`, `TS-IO-002`, `TS-STR-001`, `TS-TST-001`.
- Code to create/update: `src/main/ridgun/lib/posix.rg`, `src/main/ridgun/lib/io.rg`, `src/main/ridgun/lib/str.rg`, `src/main/ridgun/lib/crypto.rg`, `src/main/ridgun/lib/argon2id.rg`, `src/main/ridgun/lib/socket.rg`, `src/main/ridgun/lib/test.rg`, and corresponding `src/test/ridgun/test_*.rg`.
