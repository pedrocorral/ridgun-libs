# data-model/ — DM-<Entity> aggregates
Read this when: persistence, API schemas, migrations, or core library ADT definitions. Skip when: UI-only work.

| Path | What | Read when |
|---|---|---|
| `field-dictionary.md` | **Canonical field names** — the only names allowed in DM/API/schemas/code | Before naming any field, anywhere |
| `DM-Socket.md` | `SockAddr`, `SockOpts`, `Socket`, `SockPoll`, and `RGF-001` status-tuple model | Working on `socket.ridgun` |
| `DM-Argon2.md` | `Argon2Params`, `Argon2Phc`, and `RGF-015` AEAD key/nonce/tag model | Working on `argon2id.ridgun`, `crypto.ridgun` |
| `DM-PosixStatus.md` | `PollStatus`, `ProcStatus`, descriptors, events, and signals model | Working on `posix.ridgun` |
| `DM-IoResult.md` | Extensible `IoError` and `IoResult` high-level I/O model | Working on `io.ridgun` |
| `DM-Agent.md` | `AgentStatus`, `AgentReply`, `KvCmd`, and stateful actor concurrency model | Working on `agent.ridgun` |
| `DM-Tensor.md` | Typed `Tensor[...]` dimension bindings, subscript views, and `BlaMka` block model | Working on `tensor.ridgun`, `crypto.ridgun`, `argon2id.ridgun` |
| `DM-Formatter.md` | `FmtConfig`, `FmtTarget`, `FmtTheme`, and syntax token model | Working on `fmt.ridgun` |
| `DM-Json.md` | Recursive `JsonVal` AST and dot-path query model | Working on `json.ridgun` |
| `DM-Csv.md` | RFC 4180 CSV/TSV tabular document model | Working on `csv.ridgun` |
| `DM-Ini.md` | INI sectioned configuration and `.env` model | Working on `ini.ridgun` |
| `DM-Regex.md` | Linear-time Thompson NFA regular expression and match span model | Working on `regex.ridgun` |
| `DM-Btree.md` | Balanced binary search tree (`BTreeMap`, `BTreeSet`) and `MinHeap` model | Working on `btree.ridgun` |
| `DM-Jwt.md` | RFC 7519 JWT and encrypted token claims model | Working on `jwt.ridgun` |
| `DM-WebSocket.md` | RFC 6455 WebSocket handshake and frame model | Working on `ws.ridgun` |
| `DM-Linalg.md` | Typed `Tensor[Real]` linear algebra, norms, solver, and activations model | Working on `linalg.ridgun` |
| `DM-HashMap.md` | Compact open-addressing hash map on tensors (`HashMap V`) | Working on `hashmap.ridgun` |
| `DM-Diff.md` | LCS line diff edit script and Unified Diff model | Working on `diff.ridgun` |
| `DM-Template.md` | Safe Mustache-style text template and auto-escaping model | Working on `template.ridgun` |
| `DM-Ai.md` | AI agent messages, conversations, tool schemas, SSE stream accumulators, ReAct policy, mini-RAG documents, and MCP protocol model | Working on `ai.ridgun` |
| `DM-Locale.md` | CLDR `LocaleSpec` and `LocaleDatePatterns` model | Working on `locale.ridgun` |
| `DM-Tls.md` | TLS client `TlsConfig`, `TlsConn`, `TlsError`, and `TlsResult` model | Working on `tls.ridgun` |
| `DM-Mail.md` | RFC 5322 `MailMessage`, `MailResult`, `SmtpConfig`, `SmtpError`, and `SmtpResult` model | Working on `mail.ridgun` |
