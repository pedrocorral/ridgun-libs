# road-map/pending/next/
Ordered by priority (top first).

| File | Task | Title | Requirements |
|---|---|---|---|
| `TASK-0005-implement-str-and-test-libraries.md` | `TASK-0005` | Implement `str.rg` library and extend `test.rg` with `RG-011` message-annotated assertions | `FR-STR-001`, `FR-TST-001` |
| `TASK-0006-implement-posix-library.md` | `TASK-0006` | Implement `posix.rg` library (`PollStatus`, `ProcStatus`, descriptors, clocks, signals, CSPRNG) | `FR-POSIX-001`, `FR-POSIX-002` |
| `TASK-0007-implement-io-library.md` | `TASK-0007` | Implement `io.rg` library (`IoError`, `IoResult`, timeout descriptor ops, file metadata, streams) | `FR-IO-001`, `FR-IO-002`, `NFR-PERF-001` |
| `TASK-0008-implement-crypto-and-aead-library.md` | `TASK-0008` | Implement `crypto.rg` and extend `argon2id.rg` (bytes, bitops, SHA-256, HMAC, PBKDF2, 5-arg Argon2id, ChaCha20-Poly1305 AEAD) | `FR-CRYPTO-003`, `FR-CRYPTO-004`, `NFR-PERF-001` |
| `TASK-0009-extend-socket-rgf001-and-build-bundles.md` | `TASK-0009` | Extend `socket.rg` with Solstice `RGF-001` kernel-backed socket API and build all 7 `.rglib`/`.so` bundles | `FR-SOCK-004`, `NFR-SEC-001` |
| `TASK-0022-implement-json-csv-and-ini-libraries.md` | `TASK-0022` | Implement `json.rg`, `csv.rg`, and `ini.rg` structured data and configuration libraries | `FR-JSON-001`, `FR-CSV-001`, `FR-INI-001` |
| `TASK-0023-implement-regex-thompson-nfa-library.md` | `TASK-0023` | Implement `regex.rg` linear-time Thompson NFA regular expression engine | `FR-REGEX-001` |
| `TASK-0024-implement-btree-map-set-and-minheap-library.md` | `TASK-0024` | Implement `btree.rg` $O(\log N)$ balanced tree Map, Set, and `MinHeap` priority queue library | `FR-BTREE-001` |
| `TASK-0025-implement-jwt-and-ws-protocol-libraries.md` | `TASK-0025` | Implement `jwt.rg` (`HS256` & AEAD tokens) and `ws.rg` (RFC 6455 WebSocket) libraries | `FR-JWT-001`, `FR-WS-001` |
| `TASK-0026-implement-linalg-tensor-library.md` | `TASK-0026` | Implement `linalg.rg` typed `Tensor[Real]` linear algebra, norms, solver, and neural activations library | `FR-LINALG-001` |
| `TASK-0027-implement-diff-and-template-libraries.md` | `TASK-0027` | Implement `diff.rg` (LCS line diff & Unified Diff) and `template.rg` (Mustache template engine) libraries | `FR-DIFF-001`, `FR-TMPL-001` |
