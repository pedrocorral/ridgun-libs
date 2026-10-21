---
id: CONFLICT-0001
title: Solstice runtime requirements (/tmp/ridgun-lib/requirements) vs initial ridgun-libs specs and code
status: resolved
date: 2026-10-21
affects: [FR-SOCK-001, FR-SOCK-002, FR-SOCK-003, FR-SOCK-004, FR-CRYPTO-001, FR-CRYPTO-002, FR-CRYPTO-003, FR-CRYPTO-004, FR-POSIX-001, FR-POSIX-002, FR-IO-001, FR-IO-002, FR-STR-001, FR-TST-001, src/main/ridgun/lib/socket.rg, src/main/ridgun/lib/argon2id.rg, src/main/ridgun/lib/crypto.rg, src/main/ridgun/lib/posix.rg, src/main/ridgun/lib/io.rg, src/main/ridgun/lib/str.rg, src/main/ridgun/lib/test.rg]
adr: ADR-0002
---
# CONFLICT-0001 — Solstice runtime requirements (`/tmp/ridgun-lib/requirements`) vs initial `ridgun-libs` specs and code

## Conflict
| Requirement says (`/tmp/ridgun-lib/requirements/` & `/tmp/ridgun_posix_io_library_spec.md`) | Code / initial `docs/requirements/` did | Impact of resolution |
|---|---|---|
| **Error & handle convention (`requirements.md`) + `posix.rglib` / `io.rglib` ADTs**: Fallible Solstice calls return `(status, ...)` tuples and integer handles (`Int`), while `posix.rglib` and `io.rglib` define `PollStatus`, `ProcStatus`, `IoError`, and `IoResult`. | `socket.rg` and `argon2id.rg` only had `FR-SOCK-001..003` and `FR-CRYPTO-001..002`. | Expand `ridgun-libs` to provide `posix`, `io`, `str`, `crypto`, `argon2id`, `socket`, and `test` covering both specs. |
| **Sockets (`RGF-001`)**: `sys_tcp_listen`, `sys_unix_listen`, `sys_local_port`, `sys_accept`, `sys_tcp_connect`, `sys_unix_connect`, `sys_recv`, `sys_send`, `sys_shutdown_write`, `sys_close`. | `socket.rg` implemented `FR-SOCK-001..003`. | Add `FR-SOCK-004` (`TS-SOCK-004`) to `socket.rg` for `RGF-001` functions and status tuples. |
| **Crypto & Bytes (`RGF-015`, `RGF-019`)**: `byte_str`, `bytes_from_list`, `bytes_to_list`, `band`, `bor`, `bxor`, `shl`, `shr`, `sha256_bytes`, `sha256_hex`, `hmac_sha256`, `ct_equal`, `pbkdf2_hmac_sha256`, `argon2id_hash` (5-arg RFC 9106), `argon2id_verify` (`pwd, phc`), `aead_seal`, `aead_open` (ChaCha20-Poly1305). | `argon2id.rg` implemented `FR-CRYPTO-001..002`. | Add `FR-CRYPTO-003` and `FR-CRYPTO-004` (`TS-CRYPTO-003`, `TS-CRYPTO-004`) in `crypto.rg` and `argon2id.rg`. |
| **POSIX, I/O, String, Test (`ridgun_posix_io_library_spec.md`, `RG-010`, `RG-011`, `RGF-014`, `RGF-017`, `RGF-018`)**: Dedicated `posix`, `io`, `str`, and `test` libraries. | Only `test.rg` existed with 2-arg `assert equals`. | Document and implement `FR-POSIX-001..002`, `FR-IO-001..002`, `FR-STR-001`, and `FR-TST-001`. |

## Options and consequences
- **A. Align and expand `ridgun-libs` to cover all 7 libraries (`socket`, `argon2id`, `crypto`, `posix`, `io`, `str`, `test`) with full AIX documentation**: Document every domain, requirement, test spec, data field, and security threat first, then implement and verify all libraries.

## Human decision
Approved Option A: Document everything thoroughly first (`SOCK`, `CRYPTO`, `POSIX`, `IO`, `STR`, `TEST`), then implement the libraries and test suites.

## Resolution evidence (ADR, commits, tests)
- Recorded in `ADR-0002` (`docs/requirements/decisions/ADR-0002-adopt-solstice-and-posix-io-specs.md`).
