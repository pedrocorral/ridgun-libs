# ridgun-libs

Pure-Ridgun (`v0.9.16`) standard and system library suite. Every lib compiles to portable Ridgun library bundles (`.rglib` / `.rgc`) and native ELF64 shared objects (`.so`) using `stable` and `ridgunc` with zero C dependencies or `libc`.

---

## Overview

`ridgun-libs` provides **32 foundational libs** across **28 domains** for Ridgun applications, CLI utilities (`unix-tools`), and network servers (`Solstice`):

| Lib | Source | Bundles (`target/bundles/` & `target/`) | Domain | Summary |
|---|---|---|---|---|
| **`socket`** | `src/main/ridgun/lib/socket.rg` | `socket.rglib`, `socket.rgc`, `libsocket.so` | `SOCK` | High-level `Socket` ADT (`TCP`, `UDP`, `AF_UNIX`, framing, line I/O, CIDR, `/etc/hosts` + RFC 1035 UDP port 53 DNS resolution, polling) and Solstice `RGF-001` descriptor-based kernel socket API (`sys_resolve_ipv4`, `sys_tcp_listen`, `sys_tcp_listen_reuseport`, `sys_unix_listen`, `sys_accept`, `sys_tcp_connect`, `sys_unix_connect`, `sys_send`, `sys_recv`, `sys_shutdown_write`). |
| **`crypto`** | `src/main/ridgun/lib/crypto.rg` | `crypto.rglib`, `crypto.rgc`, `libcrypto.so` | `CRYPTO` | Raw byte/bitwise primitives (`RGF-019`), FIPS 180-4 SHA-256, RFC 2104 HMAC-SHA-256, constant-time equality (`ct_equal`), 100% in-process RFC 8018 PBKDF2-HMAC-SHA-256, 5-argument RFC 9106 Argon2id (`argon2id_hash`, `argon2id_verify`), and RFC 8439 ChaCha20-Poly1305 AEAD (`aead_seal`, `aead_open`). |
| **`argon2id`** | `src/main/ridgun/lib/argon2id.rg` | `argon2id.rglib`, `argon2id.rgc`, `libargon2id.so` | `CRYPTO` | 100% in-process pure-Ridgun RFC 9106 Argon2id PHC password hashing over native `Tensor[U64 * 8 * 16]` blocks, RFC 7693 Blake2b, OWASP parameter presets, pepper/associated-data context hashing, key derivation (`argon2id_derive_key`), and rehash detection (`argon2id_needs_rehash`). |
| **`posix`** | `src/main/ridgun/lib/posix.rg` | `posix.rglib`, `posix.rgc`, `libposix.so` | `POSIX` | 2-layer Platform Abstraction Layer (`SysOs`, `SysArch`), normalized open/poll/signal constants, `PollStatus` (`wait_fd`), `ProcStatus`, monotonic/wall clocks (`RGF-017`), signal watchers (`RGF-018`), CSPRNG (`sys_random_bytes`), and `RG-010` filesystem/process wrappers. |
| **`io`** | `src/main/ridgun/lib/io.rg` | `io.rglib`, `io.rgc`, `libio.so` | `IO` | Extensible `IoError` and `IoResult` ADTs, deadline-aware descriptor reads/writes (`io_read_with_timeout`, `read_fd ... timeout`, `write_fd ... timeout`), timeout-bounded command execution (`exec_with_timeout`), line streams, and file metadata predicates. |
| **`str`** | `src/main/ridgun/lib/str.rg` | `str.rglib`, `str.rgc`, `libstr.so` | `STR` | String search (`str_index_of`), trimming (`str_trim`, `str_trim_left`, `str_trim_right`), replacement (`str_replace`), splitting (`str_split`), ASCII case conversion (`str_to_upper`, `str_to_lower`), joining, repeating, and padding. |
| **`math`** | `src/main/ridgun/lib/math.rg` | `math.rglib`, `math.rgc`, `libmath.so` | `MATH` | Integer bounds (`math_abs`, `math_clamp`, `clamp x between lo and hi`), division-by-zero-safe rounding (`math_div_ceil`, `math_div_floor`, `math_div_euclid`, `math_mod_euclid`), powers/roots/logs (`math_pow`, `math_isqrt`, `math_ilog2`, `math_ilog10`), modular number theory (`math_gcd`, `math_lcm`, `math_mod_pow`, `math_mod_inv`, `math_is_prime`), combinatorics, and list statistics. |
| **`list`** | `src/main/ridgun/lib/list.rg` | `list.rglib`, `list.rgc`, `liblist.so` | `LIST` | `[Int]` and `[String]` indexing, slicing (`list_take`, `list_drop`, `list_slice`), reversal, ranges (`list_range`, `list_range_step`), search, deduplication, deterministic $O(N \log N)$ mergesort (`list_sort`, `list_str_sort`), and associative `[String String]` key-value maps (`kv_get`, `kv_put`, `kv_remove`, `kv_merge`). |
| **`codec`** | `src/main/ridgun/lib/codec.rg` | `codec.rglib`, `codec.rgc`, `libcodec.so` | `CODEC` | RFC 4648 Hex (`hex_encode`, `hex_decode`), Base64 (`base64_encode`, `base64_decode`), and URL-safe Base64url (`base64url_encode`, `base64url_decode`), RFC 3986 URL percent-encoding and query strings, and RFC 8259 lightweight JSON formatting and field extraction. |
| **`cli`** | `src/main/ridgun/lib/cli.rg` | `cli.rglib`, `cli.rgc`, `libcli.so` | `CLI` | Command-line flag (`--flag`, `-f`, bundled `-la`), option (`--key=val`, `--key val`, `-k val`), `--` end-of-options separator, positional/subcommand parser, and typed environment variable readers (`env_get_or`, `env_get_int_or`, `env_get_bool_or`). |
| **`path`** | `src/main/ridgun/lib/path.rg` | `path.rglib`, `path.rgc`, `libpath.so` | `PATH` | POSIX path normalization (`path_clean`), joining (`path_join`, `path_join_list`), component extraction (`path_dirname`, `path_basename`, `path_ext`, `path_stem`, `path_split`, `path_replace_ext`), and directory-traversal confinement (`path_is_safe_subpath`). |
| **`time`** | `src/main/ridgun/lib/time.rg` | `time.rglib`, `time.rgc`, `libtime.so` | `TIME` | Proleptic Gregorian UTC civil calendar conversion (`time_epoch_to_utc`, `time_utc_to_epoch`, `time_is_leap_year`, `time_days_in_month`, `time_day_of_week`), ISO-8601/RFC 3339 formatting and parsing (`time_format_iso8601`, `time_parse_iso8601`), human duration formatting (`time_format_duration_ms`), and exponential backoff (`time_backoff_ms`). |
| **`log`** | `src/main/ridgun/lib/log.rg` | `log.rglib`, `log.rgc`, `liblog.so` | `LOG` | Severity-filtered (`DEBUG`, `INFO`, `WARN`, `ERROR`) text and NDJSON structured logging (`log_format_text`, `log_format_json`, `log_should_emit`) with automatic secret redaction (`log_is_sensitive_key`, `log_redact_fields`). |
| **`glob`** | `src/main/ridgun/lib/glob.rg` | `glob.rglib`, `glob.rgc`, `libglob.so` | `GLOB` | Wildcard (`*`, `?`) and bracket character class (`[a-z]`, `[!0-9]`, `[^a-z]`) pattern matching (`glob_match`, `glob_match_ci`) and list filtering (`glob_filter`, `glob_any_match`). |
| **`uuid`** | `src/main/ridgun/lib/uuid.rg` | `uuid.rglib`, `uuid.rgc`, `libuuid.so` | `UUID` | RFC 9562 `UUIDv4` and time-ordered `UUIDv7` generation and validation (`uuid_v4`, `uuid_v7`, `uuid_v7_at`, `uuid_is_valid`, `uuid_version`), non-cryptographic checksums (`fnv1a_32`, `adler32`, `crc32`), and deterministic seeded PRNG (`prng_next`, `prng_range`). |
| **`http`** | `src/main/ridgun/lib/http.rg` | `http.rglib`, `http.rgc`, `libhttp.so` | `HTTP` | RFC 3986 URI parsing (`uri_parse`, `uri_scheme`, `uri_host`, `uri_port`, `uri_path`, `uri_query`), RFC 9112 HTTP/1.1 request/response wire formatting, parsing, and header inspection (`http_status_text`, `http_build_request`, `http_parse_request`, `http_build_response`, `http_parse_response`, `http_parse_headers`, `http_header_get`, `http_bearer_token`), and live kernel TCP HTTP/1.1 client (`http_request_tcp`, `http_get`, `http_post`). |
| **`agent`** | `src/main/ridgun/lib/agent.rg` | `agent.rglib`, `agent.rgc`, `libagent.so` | `AGENT` | Native actor concurrency (`agent`, `send ... to`, `receive from`, `try receive from`, `stop`), key-value actor store, token-bucket rate limiter, and supervision helpers. |
| **`pool`** | `src/main/ridgun/lib/pool.rg` | `pool.rglib`, `pool.rgc`, `libpool.so` | `AGENT` | Bounded worker pool and work-stealing actor task dispatcher. |
| **`net_agent`** | `src/main/ridgun/lib/net_agent.rg` | `net_agent.rglib`, `net_agent.rgc`, `libnet_agent.so` | `AGENT` | Socket connection actor supervisor and non-blocking event-loop bridge. |
| **`tensor`** | `src/main/ridgun/lib/tensor.rg` | `tensor.rglib`, `tensor.rgc`, `libtensor.so` | `TENSOR` | Multi-dimensional `Tensor[...]` views, slicing, elementwise reductions, and `BlaMka` 64-bit tensor primitives. |
| **`fmt`** | `src/main/ridgun/lib/fmt.rg` | `fmt.rglib`, `fmt.rgc`, `libfmt.so` | `FMT` | Configurable canonical 2D tabular Ridgun source formatter (`FmtConfig`) and multi-target syntax highlighter (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`). |
| **`json`** | `src/main/ridgun/lib/json.rg` | `json.rglib`, `json.rgc`, `libjson.so` | `JSON` | Recursive RFC 8259 `JsonVal` AST parser (`json_parse`), compact/pretty serializer (`json_stringify`, `json_pretty`), and dot-path queries (`json_get_path`, `json_get_str`, `json_get_int`, `json_get_bool`). |
| **`csv`** | `src/main/ridgun/lib/csv.rg` | `csv.rglib`, `csv.rgc`, `libcsv.so` | `CSV` | RFC 4180 state-machine CSV & TSV parser (`csv_parse`, `tsv_parse`, `csv_parse_table`), serializer (`csv_stringify`, `tsv_stringify`), and header-indexed column/row lookups. |
| **`ini`** | `src/main/ridgun/lib/ini.rg` | `ini.rglib`, `ini.rgc`, `libini.so` | `INI` | Sectioned INI and `.env` configuration parser (`ini_parse`, `dotenv_parse`), typed getters (`ini_get`, `ini_get_int`, `ini_get_bool`), setter (`ini_set`), and serializer (`ini_stringify`). |
| **`regex`** | `src/main/ridgun/lib/regex.rg` | `regex.rglib`, `regex.rgc`, `libregex.so` | `REGEX` | Linear-time $O(N \cdot M)$ Thompson NFA regular expression engine (`regex_match`, `regex_is_match`, `regex_find`, `regex_find_all`, `regex_replace`, `regex_replace_all`, `regex_split`, `regex_escape`) with ReDoS immunity. |
| **`btree`** | `src/main/ridgun/lib/btree.rg` | `btree.rglib`, `btree.rgc`, `libbtree.so` | `BTREE` | Persistent $O(\log N)$ weight-balanced `BTreeMap` (`btree_insert`, `btree_get`, `btree_remove`, `btree_range`), `BTreeSet` (`bset_union`, `bset_intersect`, `bset_diff`), and `MinHeap` priority queue. |
| **`jwt`** | `src/main/ridgun/lib/jwt.rg` | `jwt.rglib`, `jwt.rgc`, `libjwt.so` | `JWT` | RFC 7519 `HS256` JSON Web Tokens (`jwt_sign_hs256`, `jwt_verify_hs256`, `jwt_decode_unverified`) with constant-time MAC verification and `ChaCha20-Poly1305` encrypted tokens (`token_seal`, `token_open`). |
| **`ws`** | `src/main/ridgun/lib/ws.rg` | `ws.rglib`, `ws.rgc`, `libws.so` | `WS` | RFC 6455 WebSocket handshake (`ws_accept_key`, `ws_build_upgrade_request`, `ws_build_upgrade_response`), 16/64-bit length frame codec, and XOR payload masking (`ws_mask_payload`, `ws_encode_frame`, `ws_decode_frame`). |
| **`linalg`** | `src/main/ridgun/lib/linalg.rg` | `linalg.rglib`, `linalg.rgc`, `liblinalg.so` | `LINALG` | Typed `Tensor[Real]` linear algebra (`linalg_transpose`, `linalg_trace`, `linalg_diag`, `linalg_identity`, `linalg_dot`, `linalg_outer`, `linalg_matvec`, `linalg_matmul`), norms (`L1`, `L2`, `Linf`, Frobenius, `linalg_cosine_similarity`), Bareiss exact linear solver & determinant (`linalg_solve`, `linalg_det`), and neural activations (`linalg_relu`, `linalg_sigmoid`, `linalg_softmax`). |
| **`diff`** | `src/main/ridgun/lib/diff.rg` | `diff.rglib`, `diff.rgc`, `libdiff.so` | `DIFF` | Longest Common Subsequence (LCS) line diff (`diff_lines`, `diff_text`, `diff_edit_distance`, `diff_stats`), Unified Diff formatter (`diff_unified`), and lossless patch application (`diff_apply`). |
| **`template`** | `src/main/ridgun/lib/template.rg` | `template.rglib`, `template.rgc`, `libtemplate.so` | `TMPL` | Safe Mustache-style text template engine (`tmpl_render`, `tmpl_render_html`, `tmpl_render_latex`, `tmpl_render_with_escape`) with HTML/LaTeX auto-escaping, raw `{{{var}}}`, comments `{{! ... }}`, and nested `{{#sec}}`/`{{^sec}}` conditional sections. |
| **`test`** | `src/main/ridgun/lib/test.rg` | `test.rglib`, `test.rgc`, `libtest.so` | `TST` | Unit and functional test assertion primitives (`assert_equals`, `assert_int_equals`, `assert_str_eq`, `assert_true`, `assert_false`, `assert_eq`, `assert_not`, `assert_ok`). |

---

## Requirements & Toolchain

- **Compiler**: `ridgunc` (`v0.9.5+`, pure-Ridgun self-hosted ELF64 compiler)
- **Build & Test Runner**: `stable` (`build.rg`)
- **Supported Targets**: `Linux` (`X86_64`, `Arm64`) with cross-platform PAL dispatch (`Linux | MacOS | Windows`)

---

## Quick Start: Build, Check, Test & Bundle

Run all commands from the repository root:

```bash
# 1. Format all source and test files using canonical Ridgun tabular alignment
stable format

# 2. Type-check and statically analyze all 32 libs
stable check

# 3. Run all 30 automated test suites in src/test/ridgun/
stable test

# 4. Build all .rglib, .rgc, and native ELF64 .so bundles into target/ and target/bundles/
stable bundle
```

Expected output from `stable check` and `stable test`:
- `Checked 32 lib(s) — 0 errors.`
- `Passed 30/30 test suite(s) — 0 failures.`

---

## Library Reference & Usage Examples

### 1. `socket` — Networking, IPC & Kernel Sockets (`RGF-001`)

Provides both an immutable functional `Socket` state machine (`sock_tcp`, `sock_udp`, `sock_unix_stream`, length-prefixed frames, line I/O, CIDR matching) and the descriptor-based `RGF-001` TCP/Unix socket API:

```ridgun
import socket

fn :: run echo step => ()
      run echo step =
        -- Listen on an ephemeral loopback TCP port (port = 0)
        l_res = sys tcp listen "127.0.0.1" 0 16
        lfd   = sock fd l_res
        port  = sys local port lfd

        -- Connect client, accept peer, and exchange raw binary or text frames
        c_res = sys tcp connect "127.0.0.1" port 1000
        cfd   = sock fd c_res
        a_res = sys accept lfd 1000
        sfd   = sock accept fd a_res
        _     = sys send cfd "ping" 1000
        r_res = sys recv sfd 64 1000
        msg   = sock recv data r_res
        _     = sys shutdown write cfd
        _     = sys_close cfd
        _     = sys_close sfd
        _     = sys_close lfd
        echo msg
```

**RGF-001 Error Status Codes**:
| Status | Constant | Meaning |
|---|---|---|
| `0` | `OK` | Operation succeeded |
| `-1` | `EOF` | Clean peer shutdown (`0` bytes read after write-half close) |
| `-2` | `TIMEOUT` | Poll deadline expired before readiness |
| `-3` | `REFUSED` | Connection refused or Unix socket listener absent |
| `-4` | `RESET` | Broken pipe / connection reset by peer |
| `-5` | `ADDR_IN_USE` | Address or port already bound |
| `-6` | `PERMISSION` | Privileged port (`< 1024`) or permission denied |
| `-7` | `INVALID` | Invalid host, port, path traversal, or closed descriptor |

---

### 2. `crypto` & `argon2id` — Cryptography, Argon2id & ChaCha20-Poly1305 AEAD

Provides raw byte manipulation (`0..255`), 32-bit unsigned bitwise operations (`band`, `bor`, `bxor`, `shl`, `shr`), SHA-256, HMAC-SHA-256, PBKDF2-HMAC-SHA-256, RFC 9106 Argon2id PHC hashing, and RFC 8439 ChaCha20-Poly1305 AEAD:

```ridgun
import crypto

fn :: demo crypto => ()
      demo crypto =
        -- 1. SHA-256, HMAC-SHA-256 & PBKDF2-HMAC-SHA-256
        digest_hex = sha256 hex "abc"
        mac_bytes  = hmac sha256 "secret-key" "message"
        dk32       = pbkdf2 hmac sha256 "password" "salt" 1000 32

        -- 2. RFC 9106 Argon2id PHC Password Hashing (OWASP m=19456 KiB, t=2, p=1)
        phc = argon2id hash "correct horse battery staple" "0123456789abcdef" 19456 2 1
        ok  = argon2id verify "correct horse battery staple" phc

        -- 3. RFC 8439 ChaCha20-Poly1305 Authenticated Encryption (AEAD)
        key32       = sha256 bytes "32-byte-session-key-material"
        nonce12     = "0123456789ab"
        sealed      = aead seal key32 nonce12 "header-aad" "confidential payload"
        (rc, plain) = aead open key32 nonce12 "header-aad" sealed
        echo ok rc plain
```

---

### 3. `posix` & `io` — Platform Abstraction Layer (`PAL`) & Timeout I/O

Uses Ridgun `v0.9.5` compile-time target ADTs (`sys os => SysOs`, `sys arch => SysArch`) and lexical deadline quotas (`with timeout wait_ms do`):

```ridgun
import posix
import io

fn :: demo io => ()
      demo io =
        -- Non-blocking descriptor read bounded by a 250 ms lexical timeout quota
        res = io read with timeout 0 4096 250
        _   = echo (format io error (IoTimeout "read" 250))
        ()
```

---

### 4. `math`, `list`, `codec`, `str` & `cli` — Standard Data & CLI Libraries

```ridgun
import math
import list
import codec
import cli

fn :: demo std => ()
      demo std =
        -- math: modular exponentiation, modular inverse, and custom operator
        m_pow   = math mod pow 3 200 97
        m_inv   = math mod inv 3 11
        clamped = clamp 150 between 0 and 100

        -- list: O(N log N) mergesort and associative key-value map
        sorted  = list sort [42, 7, 19, 0, (0 - 5)]
        cfg     = kv put (kv put (kv empty) "host" "127.0.0.1") "port" "8080"

        -- codec: Base64, URL query strings, and lightweight JSON
        b64     = base64 encode "foobar"
        doc     = json object [("host", json quote (kv get cfg "host")), ("port", json int 8080)]
        port    = json get int doc "port" 80

        -- cli: flag and option extraction
        args    = ["serve", "-la", "--port=9090", "--", "app.rg"]
        has_all = cli has flag args "--all" "-a"
        cli_prt = cli get int opt args "--port" "-p" port
        echo m_pow m_inv clamped sorted b64 has_all cli_prt
```

---

### 5. `path`, `time`, `log`, `glob`, `uuid` & `http` — System, Web & Observability Libraries

```ridgun
import path
import time
import log
import glob
import uuid
import http

fn :: demo web sys => ()
      demo web sys =
        -- path: lexical cleaning, extension replacement, and traversal confinement
        clean_p = path replace ext (path join "/srv/www" "assets/../index.html") ".rg"
        safe_ok = path is safe subpath "/srv/www" "assets/logo.png"

        -- time: ISO-8601 UTC timestamps, human durations, and exponential backoff
        iso_ts  = time format iso8601 1792664400
        dur_str = time format duration ms 3661005
        wait_ms = time backoff ms 3 100 5000

        -- log: NDJSON structured logging with automatic secret redaction
        ndjson  = log format json "INFO" "request handled" [("req_id", uuid v4), ("api_key", "sk_live_999")]

        -- glob & uuid: wildcard filtering and CRC-32 checksums
        rg_list = glob filter "*.rg" ["main.rg", "README.md", "http.rg"]
        chk_crc = crc32 "123456789"

        -- http: RFC 3986 URI decomposition & HTTP/1.1 wire request construction
        host    = uri host "https://api.example.com:8443/v1/users?active=1"
        raw_req = http build request "GET" "/v1/users" [("Host", host)] ""
        echo clean_p safe_ok iso_ts dur_str wait_ms ndjson rg_list chk_crc raw_req
```

---

## Project Layout & Documentation (`AIX`)

All requirements, API contracts, data models, architectural decisions, security audits, and test specifications live under `docs/` and are validated by `aix docs validate`:

| Directory | Contents |
|---|---|
| `src/main/ridgun/lib/` | Pure-Ridgun source libs (`*.rg`) |
| `src/test/ridgun/` | Automated unit and functional test suites (`test_*.rg`) |
| `target/bundles/` | Compiled Ridgun library bundles (`*.rglib`) |
| `target/` | Compiled `.rgc` archives and native ELF64 shared objects (`lib*.so`) |
| `docs/book/` | Multi-language `ridgun-libs` book (`es`, `ca`, `gl`, `eu`, `en`, `pt`, `sv` — 32 chapters, `01`–`32`, one per lib, plus interactive `index.html`) |
| `docs/requirements/functional/` | Functional requirements (`FR-SOCK-*`, `FR-CRYPTO-*`, `FR-POSIX-*`, `FR-IO-*`, `FR-STR-*`, `FR-TST-*`, `FR-MATH-*`, `FR-LIST-*`, `FR-CODEC-*`, `FR-CLI-*`, `FR-PATH-*`, `FR-TIME-*`, `FR-LOG-*`, `FR-GLOB-*`, `FR-UUID-*`, `FR-HTTP-*`) |
| `docs/requirements/api/` | Public lib contracts (`API-*-001`) |
| `docs/requirements/decisions/` | Architecture Decision Records (`ADR-0001`, `ADR-0002`) |
| `docs/tests/` | Test specifications (`TS-*`) and generated traceability matrix (`coverage-matrix.md`) |
| `docs/security/` | Vulnerability register (`VULNERABILITY-INDEX.md`) and security audit reports |

Verify documentation and traceability at any time:

```bash
aix docs coverage && aix docs validate
```

---

## License

See [LICENSE](LICENSE) for license details.
