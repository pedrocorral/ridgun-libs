# functional/ — FR-<DOMAIN>-NNN, one folder per domain
Read this when: working on a domain. Skip when: the domain is not yours.

| Path | What | Read when |
|---|---|---|
| `sock/` | Socket management library (`FR-SOCK-001`..`FR-SOCK-004`) | Working on `socket.rg` |
| `crypto/` | Cryptographic & Argon2id libraries (`FR-CRYPTO-001`..`FR-CRYPTO-005`) | Working on `argon2id.rg`, `crypto.rg` |
| `posix/` | POSIX system, descriptor, poll, clock, signal & random library (`FR-POSIX-001`, `FR-POSIX-002`) | Working on `posix.rg` |
| `io/` | High-level timeout-bounded I/O & file metadata library (`FR-IO-001`, `FR-IO-002`) | Working on `io.rg` |
| `str/` | String manipulation library (`FR-STR-001`) | Working on `str.rg` |
| `tst/` | Test assertion library (`FR-TST-001`) | Working on `test.rg` |
| `math/` | Integer mathematics, number theory, combinatorics & statistics library (`FR-MATH-001`) | Working on `math.rg` |
| `list/` | List manipulation, $O(N \log N)$ mergesort & associative key-value map library (`FR-LIST-001`) | Working on `list.rg` |
| `codec/` | Hex, Base64/Base64url, URL percent-encoding & lightweight JSON library (`FR-CODEC-001`) | Working on `codec.rg` |
| `cli/` | Command-line flag/option/positional parser & typed environment library (`FR-CLI-001`) | Working on `cli.rg` |
| `path/` | Cross-platform path normalization, component extraction & safe confinement library (`FR-PATH-001`) | Working on `path.rg` |
| `time/` | UTC civil calendar, ISO-8601/RFC 3339 formatting/parsing, durations & backoff library (`FR-TIME-001`) | Working on `time.rg` |
| `log/` | Level-filtered text & NDJSON structured logging with secret redaction library (`FR-LOG-001`) | Working on `log.rg` |
| `glob/` | Wildcard (`*`, `?`, `[...]`) & path pattern matching library (`FR-GLOB-001`) | Working on `glob.rg` |
| `uuid/` | RFC 9562 UUIDv4/UUIDv7, CRC32/FNV-1a/Adler32 checksums & seeded PRNG library (`FR-UUID-001`) | Working on `uuid.rg` |
| `http/` | RFC 3986 URI & RFC 9112 HTTP/1.1 request/response parser and builder library (`FR-HTTP-001`) | Working on `http.rg` |
| `agent/` | Native Agent Model lifecycle, timeout-bounded messaging, batch dispatch & stateful actors library (`FR-AGENT-001`) | Working on `agent.rg` |
| `tensor/` | Typed `Tensor[...]` dimension inspection, subscript row/column views, bitwise Hadamard ops & Einstein contraction library (`FR-TENSOR-001`) | Working on `tensor.rg` |
| `fmt/` | Configurable 2D Ridgun source code formatter & multi-target syntax highlighting library (`FR-FMT-001`) | Working on `fmt.rg` |
| `json/` | Recursive RFC 8259 JSON AST parser, serializer, pretty-printer & dot-path query library (`FR-JSON-001`) | Working on `json.rg` |
| `csv/` | RFC 4180 CSV & TSV parser, serializer & header-mapped lookup library (`FR-CSV-001`) | Working on `csv.rg` |
| `ini/` | INI sectioned configuration & `.env` interpolation library (`FR-INI-001`) | Working on `ini.rg` |
| `regex/` | Linear-time Thompson NFA regular expression engine (`FR-REGEX-001`) | Working on `regex.rg` |
| `btree/` | $O(\log N)$ balanced binary search tree (`BTreeMap`, `BTreeSet`) & `MinHeap` library (`FR-BTREE-001`) | Working on `btree.rg` |
| `jwt/` | RFC 7519 `HS256` JWT & ChaCha20-Poly1305 AEAD token library (`FR-JWT-001`) | Working on `jwt.rg` |
| `ws/` | RFC 6455 WebSocket handshake, framing & XOR masking library (`FR-WS-001`) | Working on `ws.rg` |
| `linalg/` | Typed `Tensor[Real]` linear algebra, norms, Gaussian solver & neural activations library (`FR-LINALG-001`) | Working on `linalg.rg` |
| `diff/` | Longest Common Subsequence line diff, Unified Diff & patch library (`FR-DIFF-001`) | Working on `diff.rg` |
| `tmpl/` | Mustache-style text template engine with HTML/LaTeX auto-escaping (`FR-TMPL-001`) | Working on `template.rg` |
