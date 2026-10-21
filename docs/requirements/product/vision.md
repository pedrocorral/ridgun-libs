---
id: PRODUCT-VISION
title: Product vision
status: approved
---
# Vision

## Problem
Ridgun (`v0.9.3`) applications, servers, and system tools (`unix-tools`, `Solstice`) need reusable, pure-Ridgun standard and foundational libraries that compile to `.rgc`, `.rglib`, and ELF64 shared objects (`.so`) via `stable` and `ridgunc` without external C/Rust toolchains or `libc`.

## Solution in one paragraph
`ridgun-libs` provides a unified, zero-C suite of pure-Ridgun (`v0.9.5`) library modules under a single root `stable` project (`build.rg`, `src/main/ridgun/lib/*.rg`, `src/test/ridgun/test_*.rg`). The suite delivers 11 foundational libraries across 10 domains:
1. **`socket` (`SOCK`)**: Socket management library supporting TCP, UDP, and Unix domain sockets (`AF_UNIX`), including endpoint/CIDR/hostname validation, client/server lifecycle (`bind`, `listen`, `accept`, `connect`, `shutdown`, `close`), socket options/timeouts/polling, byte/string/framed I/O, and the Solstice `RGF-001` kernel-backed socket API (`sys_tcp_listen`, `sys_unix_listen`, `sys_local_port`, `sys_accept`, `sys_tcp_connect`, `sys_unix_connect`, `sys_recv`, `sys_send`, `sys_shutdown_write`, `sys_close`) with `(status, ...)` error tuples.
2. **`argon2id` & `crypto` (`CRYPTO`)**: Pure-Ridgun cryptographic suite providing raw byte/bit manipulation (`RGF-019`: `byte_str`, `bytes_from_list`, `bytes_to_list`, `band`, `bor`, `bxor`, `shl`, `shr`), SHA-256 (`sha256_bytes`, `sha256_hex`), HMAC-SHA-256 (`hmac_sha256`), constant-time equality (`ct_equal`), PBKDF2-HMAC-SHA-256 (`pbkdf2_hmac_sha256`), RFC 7693 Blake2b + RFC 9106 Argon2id password hashing and key derivation (`argon2id_hash`, `argon2id_verify`, OWASP presets, context pepper/AD, rehash detection), and RFC 8439 ChaCha20-Poly1305 AEAD (`aead_seal`, `aead_open`) (`RGF-015`).
3. **`posix` (`POSIX`)**: Typed POSIX descriptor, `poll`/`ppoll`, signal, clock, random, filesystem, and process library (`PollStatus`, `ProcStatus`, `poll in/out/err`, `sig term/kill/int/hup`, `wait fd`, `sys_time_ms`, `sys_monotonic_ms`, `sys_monotonic_ns`, `sys_sleep_ms`, `sys_signal_watch`, `sys_signal_wait`, `sys_random_bytes`, and `RG-010` `sys_*` wrappers).
4. **`io` (`IO`)**: High-level descriptor and file I/O library built on `posix`, exporting extensible `IoError` and `IoResult` ADTs (`format io error`), timeout-bounded descriptor I/O (`read fd ... timeout`, `write fd ... timeout`), timeout-bounded command execution (`exec with timeout`), stream/line helpers, and `RG-010` file metadata predicates (`append_file`, `file_exists`, `is_dir`, `is_file`, `is_symlink`, `file_size`, `file_mtime`, `file_mode`).
5. **`str` (`STR`)**: Pure-Ridgun string manipulation library (`RG-010`: `str_index_of`, `str_trim`, `str_replace`, `str_split`, `str_to_upper`, `str_to_lower` and space-separated Ridgun aliases).
6. **`test` (`TST`)**: Standard unit and functional test assertion library (`RG-011`: `assert_equals a b msg`, `assert_true cond msg`, and ergonomic aliases).
7. **`math` (`MATH`)**: Pure-Ridgun integer mathematics, rounding division, powers/roots/logarithms (`pow`, `isqrt`, `ilog2`, `ilog10`), modular number theory (`gcd`, `lcm`, `mod_pow`, `mod_inv`, primality), combinatorics (`factorial`, `ncr`, `fibonacci`), and list statistics (`sum`, `product`, `mean`, `median`, `min_list`, `max_list`).
8. **`list` (`LIST`)**: Pure-Ridgun list manipulation (`len`, `nth`, `take`, `drop`, `slice`, `reverse`, `range`, `contains`, `dedup`, $O(N \log N)$ mergesort) and associative `[(String, String)]` key-value map utilities (`kv_get`, `kv_put`, `kv_remove`, `kv_keys`, `kv_values`, `kv_merge`).
9. **`codec` (`CODEC`)**: Pure-Ridgun RFC 4648 Hex, Base64, and URL-safe Base64url encoding/decoding, RFC 3986 URL percent-encoding and query strings, and RFC 8259 lightweight JSON formatting, escaping, and field lookup.
10. **`cli` (`CLI`)**: Pure-Ridgun command-line argument parser (`--flag`, `-f`, `--key=val`, `--key val`, `--` separator, positionals, subcommands) and typed environment variable readers (`env_get_or`, `env_get_int_or`, `env_get_bool_or`).

## In scope / out of scope
- **In scope**: Pure-Ridgun reusable library modules (`src/main/ridgun/lib/*.rg`), `.rgc` / `.rglib` / `.so` artifacts built via `stable` and `ridgunc`, and comprehensive `stable test` suites (`src/test/ridgun/test_*.rg`).
- **Out of scope**: Standalone user-facing CLI applications (libraries only).

## Success metrics
- `stable check` passes with 0 typecheck or static analysis errors across all 11 library modules.
- `stable test` compiles and passes all 11 unit and functional test suites with 0 failures.
- `aix docs validate` and `aix docs coverage` pass with 0 errors, 0 warnings, and full requirement-to-test-to-code traceability (`@implements`, `@tests`, `@mitigates`).
