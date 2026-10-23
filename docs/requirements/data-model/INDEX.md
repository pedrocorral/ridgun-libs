# data-model/ — DM-<Entity> aggregates
Read this when: persistence, API schemas, migrations, or core library ADT definitions. Skip when: UI-only work.

| Path | What | Read when |
|---|---|---|
| `field-dictionary.md` | **Canonical field names** — the only names allowed in DM/API/schemas/code | Before naming any field, anywhere |
| `DM-Socket.md` | `SockAddr`, `SockOpts`, `Socket`, `SockPoll`, and `RGF-001` status-tuple model | Working on `socket.rg` |
| `DM-Argon2.md` | `Argon2Params`, `Argon2Phc`, and `RGF-015` AEAD key/nonce/tag model | Working on `argon2id.rg`, `crypto.rg` |
| `DM-PosixStatus.md` | `PollStatus`, `ProcStatus`, descriptors, events, and signals model | Working on `posix.rg` |
| `DM-IoResult.md` | Extensible `IoError` and `IoResult` high-level I/O model | Working on `io.rg` |
| `DM-Agent.md` | `AgentStatus`, `AgentReply`, `KvCmd`, and stateful actor concurrency model | Working on `agent.rg` |
| `DM-Tensor.md` | Typed `Tensor[...]` dimension bindings, subscript views, and `BlaMka` block model | Working on `tensor.rg`, `crypto.rg`, `argon2id.rg` |
| `DM-Formatter.md` | `FmtConfig`, `FmtTarget`, `FmtTheme`, and syntax token model | Working on `fmt.rg` |
