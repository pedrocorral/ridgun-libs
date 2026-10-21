# non-functional/ — NFR-<CAT>-NNN
Read this when: designing, reviewing performance/security/accessibility, releasing. Skip when: trivial change inside a domain.

| Path | What | Read when |
|---|---|---|
| `NFR-SEC-001-baseline.md` | Apply the secure coding baseline to every component | Always (release gate) |
| `NFR-OBS-001-observability.md` | Structured diagnostic error formatting and deterministic test reporting | Any library error/diagnostic work |
| `NFR-PERF-001-crypto-and-io-latency.md` | Cryptographic hashing (`m=19456, t=2, p=1` `< 1 s`) and `poll` timeout latency bounds | Working on `crypto.rg`, `argon2id.rg`, `posix.rg`, `io.rg`, `socket.rg` |
