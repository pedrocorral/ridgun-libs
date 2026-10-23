---
id: PRODUCT-GLOSSARY
title: Glossary and domain codes
status: approved
---
# Glossary

| Term | Definition | Domain code |
|---|---|---|
| Socket Library | Pure-Ridgun networking and IPC socket management (`TCP`, `UDP`, `Unix` domain sockets, options, framing, byte/string I/O, and `RGF-001` `sys_*` status-tuple socket primitives) | SOCK |
| Cryptographic Library | Pure-Ridgun byte/bitwise primitives (`RGF-019`), SHA-256, HMAC-SHA-256, PBKDF2-HMAC-SHA-256, RFC 7693 Blake2b, RFC 9106 Argon2id (`argon2id` + `crypto`), and RFC 8439 ChaCha20-Poly1305 AEAD (`RGF-015`) | CRYPTO |
| POSIX System Library | Typed Linux/POSIX descriptor wrappers, `PollStatus` (`ppoll`), `ProcStatus`, open flags, signal numbers & watchers (`RGF-018`), wall/monotonic clocks (`RGF-017`), CSPRNG (`RGF-014`), and filesystem/process calls (`RG-010`) | POSIX |
| High-Level I/O Library | Extensible `IoError` and `IoResult` types, timeout-guarded descriptor reads/writes (`read fd`, `write fd`), timeout-guarded command execution (`exec with timeout`), line streams, and file metadata predicates (`RG-010`) | IO |
| String Library | Pure-Ridgun string searching, trimming, replacement, splitting, and ASCII case conversion (`RG-010`: `str_index_of`, `str_trim`, `str_replace`, `str_split`, `str_to_upper`, `str_to_lower`) | STR |
| Test Assertion Library | Pure-Ridgun test runner assertion helpers (`RG-011`: `assert_equals`, `assert_true`, `assert_false`) | TST |
| Mathematics Library | Pure-Ridgun integer arithmetic, rounding division, powers/roots/logarithms, modular number theory (`gcd`, `lcm`, `mod_pow`, `mod_inv`, primality), combinatorics, and list statistics | MATH |
| List & Key-Value Collection Library | Pure-Ridgun list manipulation (`len`, `nth`, `take`, `drop`, `slice`, `reverse`, `range`, `dedup`, $O(N \log N)$ mergesort) and associative `[(String, String)]` key-value map utilities | LIST |
| Encoding & Lightweight JSON Library | Pure-Ridgun RFC 4648 Hex/Base64/Base64url, RFC 3986 URL percent-encoding and query strings, and RFC 8259 JSON escaping, formatting, and key extraction | CODEC |
| Command-Line & Environment Library | Pure-Ridgun CLI flag/option/positional argument parser (`--flag`, `-f`, `--key=val`, `--`) and typed environment variable readers (`env_get_or`, `env_get_int_or`, `env_get_bool_or`) | CLI |
| Path Manipulation & Confinement Library | Pure-Ridgun cross-platform path joining, normalization (`path_clean`), component extraction (`dirname`, `basename`, `stem`, `ext`), and anti-traversal confinement (`path_is_safe_subpath`) | PATH |
| Date, Time & Calendar Library | Pure-Ridgun civil UTC calendar conversions (`epoch_sec` <-> `Y/M/D h:m:s`), ISO-8601 / RFC 3339 formatting and parsing, leap-year/day-of-week helpers, human duration formatting, and exponential backoff | TIME |
| Structured Logging Library | Pure-Ridgun level-filtered logging (`DEBUG`..`ERROR`), human-readable and NDJSON structured formatting, and automatic secret/token redaction (`[REDACTED]`) | LOG |
| Glob & Wildcard Pattern Library | Pure-Ridgun shell wildcard (`*`, `?`, `[a-z]`, `[!a-z]`) and multi-extension path matching (`glob_match`, `glob_filter`) | GLOB |
| UUID, Checksum & Deterministic PRNG Library | Pure-Ridgun RFC 9562 UUIDv4/UUIDv7 generation and validation, FNV-1a / Adler-32 / CRC-32 checksums, and seeded deterministic PRNG (`prng_next`, `prng_range`) | UUID |
| URI & HTTP/1.1 Protocol Library | Pure-Ridgun RFC 3986 URI parsing (`scheme`, `host`, `port`, `path`, `query`) and RFC 9112 HTTP/1.1 request/response building, parsing, headers, and status reason phrases | HTTP |
| Agent Concurrency Library | Pure-Ridgun Native Agent Model (`Agent In Out`, `agent`, `send ... to`, `receive from`, `try receive from`, `stop`, `agent alive`) lifecycle, request-reply, timeout-bounded polling, batch dispatch, relay, and stateful Counter, Log, and Key-Value agents | AGENT |
| Typed Tensor & Linear Algebra Library | Pure-Ridgun first-class typed tensors (`Tensor[Int * r * c]`, `Tensor[U64 * r * c]`, `Tensor[Real * r * c]`, `Tensor[Byte * n]`), dimension-binding patterns, subscript row/column views (`m_(r,)`, `m_(,c)`), in-place `map f in`, bitwise Hadamard operations (`a_ij xor b_ij`), and Einstein matrix contraction (`a_ik @ b_kj`) | TENSOR |
| Source Code Formatter & Rich Syntax Highlighter Library | Pure-Ridgun configurable 2D tabular source formatter (generalising `stable format`) and optional lexical syntax highlighter emitting Plain Text, ANSI 16-color TTY, 24-bit TrueColor, Inline HTML, CSS-class HTML, Markdown, Pango Markup, LaTeX, and RTF | FMT |
| Full JSON AST & Path Query Library | Pure-Ridgun RFC 8259 recursive `JsonVal` AST parser, serializer, indented pretty-printer, and dot-path lookup/mutation library (`json.rg`) | JSON |
| CSV & Tabular Data Library | Pure-Ridgun RFC 4180 CSV/TSV parser, writer, quoted-field handling, and header-mapped row lookup library (`csv.rg`) | CSV |
| INI & Dotenv Configuration Library | Pure-Ridgun `.env` and sectioned `.ini` configuration parser, serializer, and `${VAR}` interpolation library (`ini.rg`) | INI |
| Linear-Time Regular Expression Library | Pure-Ridgun Thompson NFA regular expression engine (`.`, `*`, `+`, `?`, alternation, `[...]`, `\d`, `\w`, `\s`, `^`, `$`) with match, search, replace, and split (`regex.rg`) | REGEX |
| Balanced Tree Map, Set & Heap Library | Pure-Ridgun persistent $O(\log N)$ balanced binary search tree (`BTreeMap`, `BTreeSet`) and priority queue (`MinHeap`) library (`btree.rg`) | BTREE |
| JSON Web Token & Authenticated Token Library | Pure-Ridgun RFC 7519 JWT (`HS256` HMAC-SHA256) and ChaCha20-Poly1305 encrypted token signing, constant-time verification, and claim validation library (`jwt.rg`) | JWT |
| WebSocket Protocol Library | Pure-Ridgun RFC 6455 WebSocket handshake (`Sec-WebSocket-Accept`), frame encoding/decoding (`TEXT`, `BINARY`, `PING`, `PONG`, `CLOSE`), and XOR payload masking library (`ws.rg`) | WS |
| Tensor Linear Algebra & Activations Library | Pure-Ridgun `Tensor[Real * r * c]` matrix transpose, trace, $L_1$/$L_2$/$L_\infty$ norms, outer product, row normalization, Gaussian elimination (`linalg solve`), and neural activations (`relu`, `sigmoid`, `softmax`) library (`linalg.rg`) | LINALG |
| Unified Diff & Patch Library | Pure-Ridgun Longest Common Subsequence (LCS) line diff, Unified Diff (`---`, `+++`, `@@`) formatter, and patch applier library (`diff.rg`) | DIFF |
| Safe Text Template Engine Library | Pure-Ridgun Mustache-style `{{var}}` template renderer with HTML/LaTeX auto-escaping, conditional sections `{{#key}}...{{/key}}`, and inverted sections `{{^key}}...{{/key}}` (`template.rg`) | TMPL |

Domain codes are UPPERCASE, ≤ 8 chars, and name folders in `functional/`, `api/`, and `docs/tests/*/`.
