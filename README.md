# ridgun-libs

🌐 **Website and downloads: [ridgun.com](https://ridgun.com)**

Pure-Ridgun standard and system library suite. Every lib compiles to portable Ridgun library bundles (`.ridgunlib` / `.rgc`) and native ELF64 shared objects (`.so`) using `stable` and `ridgunc` with zero C dependencies or `libc`.

---

## Overview

`ridgun-libs` provides **37 foundational libs** across **34 domains** for Ridgun applications, CLI utilities (`unix-tools`), and network servers (`Solstice`):

| Lib | Source | Bundles (`target/bundles/` & `target/`) | Domain | Summary |
|---|---|---|---|---|
| **`socket`** | `src/main/ridgun/lib/socket.ridgun` | `socket.ridgunlib`, `socket.rgc`, `libsocket.so` | `SOCK` | High-level `Socket` ADT (`TCP`, `UDP`, `AF_UNIX`, framing, line I/O, CIDR, `/etc/hosts` + RFC 1035 UDP port 53 DNS resolution, polling) and Solstice `RGF-001` descriptor-based kernel socket API (`sys resolve ipv4`, `sys tcp listen`, `sys tcp listen reuseport`, `sys unix listen`, `sys accept`, `sys tcp connect`, `sys unix connect`, `sys send`, `sys recv`, `sys shutdown write`). |
| **`crypto`** | `src/main/ridgun/lib/crypto.ridgun` | `crypto.ridgunlib`, `crypto.rgc`, `libcrypto.so` | `CRYPTO` | Raw byte/bitwise primitives (`RGF-019`), FIPS 180-4 SHA-256, RFC 2104 HMAC-SHA-256, constant-time equality (`ct equal`), 100% in-process RFC 8018 PBKDF2-HMAC-SHA-256, 5-argument RFC 9106 Argon2id (`argon2id hash`, `argon2id verify`), and RFC 8439 ChaCha20-Poly1305 AEAD (`aead seal`, `aead open`). |
| **`argon2id`** | `src/main/ridgun/lib/argon2id.ridgun` | `argon2id.ridgunlib`, `argon2id.rgc`, `libargon2id.so` | `CRYPTO` | 100% in-process pure-Ridgun RFC 9106 Argon2id PHC password hashing over native `Tensor[U64 * 8 * 16]` blocks, RFC 7693 Blake2b, OWASP parameter presets, pepper/associated-data context hashing, key derivation (`argon2id derive key`), and rehash detection (`argon2id needs rehash`). |
| **`posix`** | `src/main/ridgun/lib/posix.ridgun` | `posix.ridgunlib`, `posix.rgc`, `libposix.so` | `POSIX` | 2-layer Platform Abstraction Layer (`SysOs`, `SysArch`), normalized open/poll/signal constants, `PollStatus` (`wait fd`), `ProcStatus`, monotonic/wall clocks (`RGF-017`), signal watchers (`RGF-018`), CSPRNG (`sys random bytes`), and `RG-010` filesystem/process wrappers. |
| **`io`** | `src/main/ridgun/lib/io.ridgun` | `io.ridgunlib`, `io.rgc`, `libio.so` | `IO` | Extensible `IoError` and `IoResult` ADTs, deadline-aware descriptor reads/writes (`io read with timeout`, `read fd … max … timeout …`, `write fd … data … timeout …`), timeout-bounded command execution (`exec with timeout`), line streams, and file metadata predicates. |
| **`str`** | `src/main/ridgun/lib/str.ridgun` | `str.ridgunlib`, `str.rgc`, `libstr.so` | `STR` | String search (`str index of`), trimming (`str trim`, `str trim left`, `str trim right`), replacement (`str replace`), splitting (`str split`), ASCII case conversion (`str to upper`, `str to lower`), joining, repeating, and padding. |
| **`math`** | `src/main/ridgun/lib/math.ridgun` | `math.ridgunlib`, `math.rgc`, `libmath.so` | `MATH` | Integer bounds (`math abs`, `math clamp`, `clamp x between lo and hi`), division-by-zero-safe rounding (`math div ceil`, `math div floor`, `math div euclid`, `math mod euclid`), powers/roots/logs (`math pow`, `math isqrt`, `math ilog2`, `math ilog10`), modular number theory (`math gcd`, `math lcm`, `math mod pow`, `math mod inv`, `math is prime`), combinatorics, and list statistics. |
| **`list`** | `src/main/ridgun/lib/list.ridgun` | `list.ridgunlib`, `list.rgc`, `liblist.so` | `LIST` | `[Int]` and `[String]` indexing, slicing (`list str take`, `list str drop`, `list slice`), reversal, ranges (`list range`, `list range step`), search, deduplication, deterministic $O(N \log N)$ mergesort (`list sort`, `list str sort`), and associative `[String String]` key-value maps (`list kv get`, `list kv put`, `list kv remove`, `list kv merge`). |
| **`hashmap`** | `src/main/ridgun/lib/hashmap.ridgun` | `hashmap.ridgunlib`, `hashmap.rgc`, `libhashmap.so` | `HASHMAP` | Mutable `String`-keyed `HashMap V` with open addressing (`hashmap empty`, `hashmap put`, `hashmap get`, `hashmap has`, `hashmap add`, `hashmap size`, `hashmap pairs`); `put` and `add` update the map in place and return it. |
| **`codec`** | `src/main/ridgun/lib/codec.ridgun` | `codec.ridgunlib`, `codec.rgc`, `libcodec.so` | `CODEC` | RFC 4648 Hex (`hex encode`, `hex decode`), Base64 (`base64 encode`, `base64 decode`), and URL-safe Base64url (`base64url encode`, `base64url decode`), RFC 3986 URL percent-encoding and query strings, and RFC 8259 lightweight JSON formatting and field extraction. |
| **`cli`** | `src/main/ridgun/lib/cli.ridgun` | `cli.ridgunlib`, `cli.rgc`, `libcli.so` | `CLI` | Command-line flag (`--flag`, `-f`, bundled `-la`), option (`--key=val`, `--key val`, `-k val`), `--` end-of-options separator, positional/subcommand parser, and typed environment variable readers (`env get or`, `env get int or`, `env get bool or`). |
| **`path`** | `src/main/ridgun/lib/path.ridgun` | `path.ridgunlib`, `path.rgc`, `libpath.so` | `PATH` | POSIX path normalization (`path clean`), joining (`path join`, `path join list`), component extraction (`path dirname`, `path basename`, `path ext`, `path stem`, `path split`, `path replace ext`), and directory-traversal confinement (`path is safe subpath`). |
| **`time`** | `src/main/ridgun/lib/time.ridgun` | `time.ridgunlib`, `time.rgc`, `libtime.so` | `TIME` | Proleptic Gregorian UTC civil calendar conversion (`time epoch to utc`, `time utc to epoch`, `time is leap year`, `time days in month`, `time day of week`), ISO-8601/RFC 3339 formatting and parsing (`time format iso8601`, `time parse iso8601`), human duration formatting (`time format duration ms`), and exponential backoff (`time backoff ms`). |
| **`locale`** | `src/main/ridgun/lib/locale.ridgun` | `locale.ridgunlib`, `locale.rgc`, `liblocale.so` | `LOCALE` | Locale lookup and normalization (`lookup locale`, `normalize locale`), CLDR plural categories (`plural category`, `plural index`), month and weekday names, and localized date, number and decimal formatting (`format date`, `format datetime`, `format int`, `format decimal`). |
| **`log`** | `src/main/ridgun/lib/log.ridgun` | `log.ridgunlib`, `log.rgc`, `liblog.so` | `LOG` | Severity-filtered (`DEBUG`, `INFO`, `WARN`, `ERROR`) text and NDJSON structured logging (`log format text`, `log format json`, `log should emit`) with automatic secret redaction (`log is sensitive key`, `log redact fields`). |
| **`glob`** | `src/main/ridgun/lib/glob.ridgun` | `glob.ridgunlib`, `glob.rgc`, `libglob.so` | `GLOB` | Wildcard (`*`, `?`) and bracket character class (`[a-z]`, `[!0-9]`, `[^a-z]`) pattern matching (`glob match`, `glob match ci`) and list filtering (`glob filter`, `glob any match`). |
| **`uuid`** | `src/main/ridgun/lib/uuid.ridgun` | `uuid.ridgunlib`, `uuid.rgc`, `libuuid.so` | `UUID` | RFC 9562 `UUIDv4` and time-ordered `UUIDv7` generation and validation (`uuid v4`, `uuid v7`, `uuid v7 at`, `uuid is valid`, `uuid version`), non-cryptographic checksums (`fnv1a 32`, `adler32`, `crc32`), and deterministic seeded PRNG (`prng next`, `prng range`). |
| **`http`** | `src/main/ridgun/lib/http.ridgun` | `http.ridgunlib`, `http.rgc`, `libhttp.so` | `HTTP` | RFC 3986 URI parsing (`uri parse`, `uri scheme`, `uri host`, `uri port`, `uri path`, `uri query`), RFC 9112 HTTP/1.1 request/response wire formatting, parsing, and header inspection (`http status text`, `http build request`, `http parse request`, `http build response`, `http parse response`, `http parse headers`, `http header get`, `http bearer token`), and live kernel TCP HTTP/1.1 client (`http request tcp`, `http get`, `http post`). |
| **`tls`** | `src/main/ridgun/lib/tls.ridgun` | `tls.ridgunlib`, `tls.rgc`, `libtls.so` | `TLS` | Pure-Ridgun TLS 1.3 client (`tls connect`, `tls connect host`, `tls send`, `tls recv`, `tls close`) with certificate-chain and hostname verification (`tls verify chain`), ALPN, configurable roots and timeouts (`tls defaults`, `tls with roots`, `tls with alpn`, `tls with timeout`), and typed `TlsError` results. |
| **`mail`** | `src/main/ridgun/lib/mail.ridgun` | `mail.ridgunlib`, `mail.rgc`, `libmail.so` | `MAIL` | RFC 5322 message building and rendering (`mail message`, `mail with html`, `mail add to`, `mail render`), RFC 2047 header encoding, address validation, and SMTP delivery with STARTTLS/TLS and authentication (`smtp config`, `smtp with tls`, `smtp with auth`, `smtp send`). |
| **`agent`** | `src/main/ridgun/lib/agent.ridgun` | `agent.ridgunlib`, `agent.rgc`, `libagent.so` | `AGENT` | Native actor concurrency (`agent`, `send ... to`, `receive from`, `try receive from`, `stop`), key-value actor store, token-bucket rate limiter, and supervision helpers. |
| **`pool`** | `src/main/ridgun/lib/pool.ridgun` | `pool.ridgunlib`, `pool.rgc`, `libpool.so` | `AGENT` | Bounded worker pool and work-stealing actor task dispatcher. |
| **`net_agent`** | `src/main/ridgun/lib/net_agent.ridgun` | `net_agent.ridgunlib`, `net_agent.rgc`, `libnet_agent.so` | `AGENT` | Socket connection actor supervisor and non-blocking event-loop bridge. |
| **`tensor`** | `src/main/ridgun/lib/tensor.ridgun` | `tensor.ridgunlib`, `tensor.rgc`, `libtensor.so` | `TENSOR` | Multi-dimensional `Tensor[...]` views, slicing, elementwise reductions, and `BlaMka` 64-bit tensor primitives. |
| **`fmt`** | `src/main/ridgun/lib/fmt.ridgun` | `fmt.ridgunlib`, `fmt.rgc`, `libfmt.so` | `FMT` | Configurable canonical 2D tabular Ridgun source formatter (`FmtConfig`) and multi-target syntax highlighter (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`). |
| **`json`** | `src/main/ridgun/lib/json.ridgun` | `json.ridgunlib`, `json.rgc`, `libjson.so` | `JSON` | Recursive RFC 8259 `JsonVal` AST parser (`json parse`), compact/pretty serializer (`json stringify`, `json pretty`), and dot-path queries (`json get path`, `json get str`, `json get int`, `json get bool`). |
| **`csv`** | `src/main/ridgun/lib/csv.ridgun` | `csv.ridgunlib`, `csv.rgc`, `libcsv.so` | `CSV` | RFC 4180 state-machine CSV & TSV parser (`csv parse`, `tsv parse`, `csv parse table`), serializer (`csv stringify`, `tsv stringify`), and header-indexed column/row lookups. |
| **`ini`** | `src/main/ridgun/lib/ini.ridgun` | `ini.ridgunlib`, `ini.rgc`, `libini.so` | `INI` | Sectioned INI and `.env` configuration parser (`ini parse`, `dotenv parse`), typed getters (`ini get`, `ini get int`, `ini get bool`), setter (`ini set`), and serializer (`ini stringify`). |
| **`regex`** | `src/main/ridgun/lib/regex.ridgun` | `regex.ridgunlib`, `regex.rgc`, `libregex.so` | `REGEX` | Linear-time $O(N \cdot M)$ Thompson NFA regular expression engine (`regex match`, `regex is match`, `regex find`, `regex find all`, `regex replace`, `regex replace all`, `regex split`) with ReDoS immunity. |
| **`btree`** | `src/main/ridgun/lib/btree.ridgun` | `btree.ridgunlib`, `btree.rgc`, `libbtree.so` | `BTREE` | Persistent $O(\log N)$ weight-balanced `BTreeMap` (`btree put`, `btree get`, `btree remove`, `btree keys`), `BTreeSet` (`bset union`, `bset intersect`, `bset diff`), and `MinHeap` priority queue. |
| **`jwt`** | `src/main/ridgun/lib/jwt.ridgun` | `jwt.ridgunlib`, `jwt.rgc`, `libjwt.so` | `JWT` | RFC 7519 `HS256` JSON Web Tokens (`jwt sign hs256`, `jwt verify hs256`), registered-claim validation (`jwt sign claims`, `jwt verify claims`) with constant-time MAC verification, and `ChaCha20-Poly1305` encrypted tokens (`jwt seal aead`, `jwt open aead`). |
| **`ws`** | `src/main/ridgun/lib/ws.ridgun` | `ws.ridgunlib`, `ws.rgc`, `libws.so` | `WS` | RFC 6455 WebSocket handshake (`ws accept key`, `ws build upgrade request`, `ws build upgrade response`), 16/64-bit length frame codec, and XOR payload masking (`ws mask bytes`, `ws encode frame`, `ws decode frame`). |
| **`linalg`** | `src/main/ridgun/lib/linalg.ridgun` | `linalg.ridgunlib`, `linalg.rgc`, `liblinalg.so` | `LINALG` | Typed `Tensor[Real]` linear algebra (`linalg transpose`, `linalg trace`, `linalg diag`, `linalg identity`, `linalg dot`, `linalg outer`, `linalg matvec`, `linalg matmul`), norms (`L1`, `L2`, `Linf`, Frobenius, `linalg cosine similarity`), Bareiss exact linear solver & determinant (`linalg solve`, `linalg det`), and neural activations (`linalg relu`, `linalg sigmoid`, `linalg softmax`). |
| **`diff`** | `src/main/ridgun/lib/diff.ridgun` | `diff.ridgunlib`, `diff.rgc`, `libdiff.so` | `DIFF` | Longest Common Subsequence (LCS) line diff (`diff lines`, `diff text`, `diff edit distance`, `diff stats`), Unified Diff formatter (`diff unified`), and lossless patch application (`diff apply`). |
| **`template`** | `src/main/ridgun/lib/template.ridgun` | `template.ridgunlib`, `template.rgc`, `libtemplate.so` | `TMPL` | Safe Mustache-style text template engine (`tmpl render`, `tmpl render html`, `tmpl render latex`, `tmpl render with escape`) with HTML/LaTeX auto-escaping, raw `{{{var}}}`, comments `{{! ... }}`, and nested `{{#sec}}`/`{{^sec}}` conditional sections. |
| **`ai`** | `src/main/ridgun/lib/ai.ridgun` | `ai.ridgunlib`, `ai.rgc`, `libai.so` | `AI` | LLM conversations and `<think>` handling (`ai new conv`, `ai add user`, `ai trim context`), tool definitions and call validation (`ai tool`, `ai validate tool call`), OpenAI, Anthropic and Ollama request/response codecs, SSE streaming (`ai stream step`), structured JSON output (`ai extract json`, `ai validate json schema`), and bounded ReAct steps (`ai policy`, `ai step`). |
| **`test`** | `src/main/ridgun/lib/test.ridgun` | `test.ridgunlib`, `test.rgc`, `libtest.so` | `TST` | Unit and functional test assertion primitives (`assert equals`, `assert int equals`, `assert str eq`, `assert true`, `assert false`, `assert eq`, `assert not`, `assert ok`). |

---

## Requirements & Toolchain

- **Compiler**: `ridgunc` 1.0.9 or later (pure-Ridgun self-hosted compiler)
- **Build & Test Runner**: `stable` 1.0.9 or later (`build.ridgun`)
- **Supported Targets**: `Linux` (`X86_64`, `Arm64`) with cross-platform PAL dispatch (`Linux | MacOS | Windows`)

---

## Quick Start: Build, Check, Test & Bundle

Run all commands from the repository root:

```bash
# 1. Format all source and test files using canonical Ridgun tabular alignment
stable format

# 2. Type-check and statically analyze all 37 libs
stable check

# 3. Run all 35 automated test suites in src/test/ridgun/
stable test

# 4. Build all .ridgunlib, .rgc, and native ELF64 .so bundles into target/ and target/bundles/
stable bundle
```

Expected output from `stable check` and `stable test`:
- `Checked 37 module(s) — 0 errors.`
- `Passed 35/35 test suite(s) — 0 failures.`

---

## Library Reference & Usage Examples

### 1. `socket` — Networking, IPC & Kernel Sockets (`RGF-001`)

Provides both an immutable functional `Socket` state machine (`sock tcp`, `sock udp`, `sock unix stream`, length-prefixed frames, line I/O, CIDR matching) and the descriptor-based `RGF-001` TCP/Unix socket API:

```ridgun
import socket
import posix

fn :: run echo step => ()
      run echo step =
        -- Listen on an ephemeral loopback TCP port (port = 0)
        lfd  = sock fd (sys tcp listen "127.0.0.1" 0 16)
        port = sys local port lfd

        -- Connect a client, accept the peer and exchange a message
        cfd = sock fd (sys tcp connect "127.0.0.1" port 1000)
        sfd = sock accept fd (sys accept lfd 1000)
        sys send cfd "ping" 1000
        msg = sock recv data (sys recv sfd 64 1000)
        sys shutdown write cfd
        posix close cfd
        posix close sfd
        posix close lfd
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
import argon2id

fn :: show opened (Int String) => String
      show opened (rc, plain)  =  "rc={rc} plain={plain}"

fn :: demo crypto => ()
      demo crypto =
        -- 1. SHA-256, HMAC-SHA-256 and PBKDF2-HMAC-SHA-256
        digest_hex = sha256 hex "abc"
        mac        = hmac sha256 "secret-key" "message"
        dk32       = pbkdf2 hmac sha256 "password" "salt" 1000 32

        -- 2. RFC 9106 Argon2id PHC password hashing (OWASP: m=19456 KiB, t=2, p=1)
        phc = argon2id hash "correct horse battery staple" "0123456789abcdef" 19456 2 1
        ok  = argon2id verify "correct horse battery staple" phc

        -- 3. RFC 8439 ChaCha20-Poly1305 authenticated encryption (AEAD)
        key32  = sha256 bytes "32-byte-session-key-material"
        nonce  = "0123456789ab"
        sealed = aead seal key32 nonce "header-aad" "confidential payload"
        opened = aead open key32 nonce "header-aad" sealed
        echo digest_hex ok (show opened opened)
```

---

### 3. `posix` & `io` — Platform Abstraction Layer (`PAL`) & Timeout I/O

Uses compile-time target ADTs (`sys os => SysOs`, `sys arch => SysArch`) and lexical deadline quotas (`with timeout wait_ms do`):

```ridgun
import posix
import io

fn :: demo io => ()
      demo io =
        -- Read a file; the read is bounded by a 250 ms deadline (`with timeout`)
        res = io read with timeout "/etc/hostname" 250
        echo (format io result res)
        echo (format io error (Timeout 250))
```

---

### 4. `math`, `list`, `hashmap`, `codec` & `cli` — Standard Data & CLI Libraries

```ridgun
import math
import list
import hashmap
import codec
import cli

fn :: demo std => ()
      demo std =
        -- math: modular exponentiation, modular inverse and a mixfix operator
        m_pow   = math mod pow 3 200 97
        m_inv   = math mod inv 3 11
        clamped = clamp 150 between 0 and 100

        -- list: O(N log N) merge sort
        sorted = list sort [42, 7, 19, 0, (0 - 5)]

        -- hashmap: String-keyed map
        cfg = hashmap empty -> hashmap put _ "host" "127.0.0.1" -> hashmap put _ "port" "8080"

        -- codec: Base64, JSON building and field extraction
        b64  = base64 encode "foobar"
        doc  = json object [("host", json quote (hashmap get cfg "host" "")), ("port", json int 8080)]
        port = codec json get int doc "port" 80

        -- cli: flag and option extraction
        args    = ["serve", "-la", "--port=9090", "--", "app.ridgun"]
        has_all = cli has flag args "--all" "-a"
        cli_prt = cli get int opt args "--port" "-p" port
        echo m_pow m_inv clamped sorted b64 port has_all cli_prt
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
        clean_p = path replace ext (path join "/srv/www" "assets/../index.html") ".ridgun"
        safe_ok = path is safe subpath "/srv/www" "assets/logo.png"

        -- time: ISO-8601 UTC timestamps, human durations, and exponential backoff
        iso_ts  = time format iso8601 1792664400
        dur_str = time format duration ms 3661005
        wait_ms = time backoff ms 3 100 5000

        -- log: NDJSON structured logging with automatic secret redaction
        ndjson  = log format json "INFO" "request handled" [("req_id", uuid v4), ("api_key", "sk_live_999")]

        -- glob & uuid: wildcard filtering and CRC-32 checksums
        rg_list = glob filter "*.ridgun" ["main.ridgun", "README.md", "http.ridgun"]
        chk_crc = crc32 "123456789"

        -- http: RFC 3986 URI decomposition & HTTP/1.1 wire request construction
        host    = uri host "https://api.example.com:8443/v1/users?active=1"
        raw_req = http build request "GET" "/v1/users" [("Host", host)] ""
        echo clean_p safe_ok iso_ts dur_str wait_ms ndjson rg_list chk_crc raw_req
```

---

## Project Layout & Documentation

All requirements, API contracts, data models, architectural decisions, security audits, and test specifications live under `docs/`:

| Directory | Contents |
|---|---|
| `src/main/ridgun/lib/` | Pure-Ridgun source libs (`*.ridgun`) |
| `src/test/ridgun/` | Automated unit and functional test suites (`test *.ridgun`) |
| `target/bundles/` | Compiled Ridgun library bundles (`*.ridgunlib`) |
| `target/` | Compiled `.rgc` archives and native ELF64 shared objects (`lib*.so`) |
| `docs/book/` | Multi-language `ridgun-libs` book (`es`, `ca`, `gl`, `eu`, `en`, `pt`, `sv`, `it` — 34 chapters, `01`–`34`, plus interactive `index.html`) |
| `docs/requirements/functional/` | Functional requirements (`FR-*`), one folder per lib |
| `docs/requirements/api/` | Public lib contracts (`API-*-001`) |
| `docs/requirements/decisions/` | Architecture Decision Records (`ADR-*`) |
| `docs/tests/` | Test specifications (`TS-*`) and generated traceability matrix (`coverage-matrix.md`) |
| `docs/security/` | Vulnerability register (`VULNERABILITY-INDEX.md`) and security audit reports |

---

## License

See [LICENSE](LICENSE) for license details.
