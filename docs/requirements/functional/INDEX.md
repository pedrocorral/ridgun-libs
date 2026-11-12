# functional/ — FR-<DOMAIN>-NNN, one folder per domain
Read this when: working on a domain. Skip when: the domain is not yours.

| Path | What | Read when |
|---|---|---|
| `sock/` | Socket management library (`FR-SOCK-001`..`FR-SOCK-004`) | Working on `socket.ridgun` |
| `crypto/` | Cryptographic & Argon2id libraries (`FR-CRYPTO-001`..`FR-CRYPTO-006`) | Working on `argon2id.ridgun`, `crypto.ridgun` |
| `posix/` | POSIX system, descriptor, poll, clock, signal & random library (`FR-POSIX-001`, `FR-POSIX-002`) | Working on `posix.ridgun` |
| `io/` | High-level timeout-bounded I/O & file metadata library (`FR-IO-001`, `FR-IO-002`) | Working on `io.ridgun` |
| `str/` | String manipulation library (`FR-STR-001`) | Working on `str.ridgun` |
| `tst/` | Test assertion library (`FR-TST-001`) | Working on `test.ridgun` |
| `math/` | Integer mathematics, number theory, combinatorics & statistics library (`FR-MATH-001`) | Working on `math.ridgun` |
| `list/` | List manipulation, $O(N \log N)$ mergesort & associative key-value map library (`FR-LIST-001`) | Working on `list.ridgun` |
| `hashmap/` | String-keyed hash map library with constant amortized time (`FR-HASHMAP-001`) | Working on `hashmap.ridgun` |
| `codec/` | Hex, Base64/Base64url, URL percent-encoding & lightweight JSON library (`FR-CODEC-001`) | Working on `codec.ridgun` |
| `cli/` | Command-line flag/option/positional parser & typed environment library (`FR-CLI-001`) | Working on `cli.ridgun` |
| `path/` | Cross-platform path normalization, component extraction & safe confinement library (`FR-PATH-001`) | Working on `path.ridgun` |
| `time/` | UTC civil calendar, ISO-8601/RFC 3339 formatting/parsing, durations & backoff library (`FR-TIME-001`) | Working on `time.ridgun` |
| `log/` | Level-filtered text & NDJSON structured logging with secret redaction library (`FR-LOG-001`) | Working on `log.ridgun` |
| `glob/` | Wildcard (`*`, `?`, `[...]`) & path pattern matching library (`FR-GLOB-001`) | Working on `glob.ridgun` |
| `uuid/` | RFC 9562 UUIDv4/UUIDv7, CRC32/FNV-1a/Adler32 checksums & seeded PRNG library (`FR-UUID-001`) | Working on `uuid.ridgun` |
| `http/` | RFC 3986 URI & RFC 9112 HTTP/1.1 request/response parser and builder library (`FR-HTTP-001`) | Working on `http.ridgun` |
| `agent/` | Native Agent Model lifecycle, timeout-bounded messaging, batch dispatch & stateful actors library (`FR-AGENT-001`) | Working on `agent.ridgun` |
| `tensor/` | Typed `Tensor[...]` dimension inspection, subscript row/column views, bitwise Hadamard ops & Einstein contraction library (`FR-TENSOR-001`) | Working on `tensor.ridgun` |
| `fmt/` | Configurable 2D Ridgun source code formatter & multi-target syntax highlighting library (`FR-FMT-001`) | Working on `fmt.ridgun` |
| `json/` | Recursive RFC 8259 JSON AST parser, serializer, pretty-printer & dot-path query library (`FR-JSON-001`) | Working on `json.ridgun` |
| `csv/` | RFC 4180 CSV & TSV parser, serializer & header-mapped lookup library (`FR-CSV-001`) | Working on `csv.ridgun` |
| `ini/` | INI sectioned configuration & `.env` interpolation library (`FR-INI-001`) | Working on `ini.ridgun` |
| `regex/` | Linear-time Thompson NFA regular expression engine (`FR-REGEX-001`) | Working on `regex.ridgun` |
| `btree/` | $O(\log N)$ balanced binary search tree (`BTreeMap`, `BTreeSet`) & `MinHeap` library (`FR-BTREE-001`) | Working on `btree.ridgun` |
| `jwt/` | RFC 7519 `HS256` JWT & ChaCha20-Poly1305 AEAD token library (`FR-JWT-001`) | Working on `jwt.ridgun` |
| `ws/` | RFC 6455 WebSocket handshake, framing & XOR masking library (`FR-WS-001`) | Working on `ws.ridgun` |
| `linalg/` | Typed `Tensor[Real]` linear algebra, norms, Gaussian solver & neural activations library (`FR-LINALG-001`) | Working on `linalg.ridgun` |
| `diff/` | Longest Common Subsequence line diff, Unified Diff & patch library (`FR-DIFF-001`) | Working on `diff.ridgun` |
| `tmpl/` | Mustache-style text template engine with HTML/LaTeX auto-escaping (`FR-TMPL-001`) | Working on `template.ridgun` |
| `ai/` | AI agent conversations, `<think>` separation, tool schemas, OpenAI/Anthropic/Ollama JSON & SSE codecs, structured outputs, ReAct loop, security guardrails, mini-RAG, handoffs & MCP (`FR-AI-001`) | Working on `ai.ridgun` |
| `locale/` | CLDR locale data library for cardinal plural rules, UTC date/datetime formatting, number formatting & language autonyms (`FR-LOCALE-001`) | Working on `locale.ridgun` |
| `tls/` | RFC 8446 TLS 1.3 & RFC 5246 TLS 1.2 (ECDHE + AEAD) client protocol & X.509 certificate verification library (`FR-TLS-001`) | Working on `tls.ridgun` |
| `mail/` | RFC 5322 email composition & RFC 5321/6409/8314/3207/4954 SMTP client over TLS library (`FR-MAIL-001`) | Working on `mail.ridgun` |
