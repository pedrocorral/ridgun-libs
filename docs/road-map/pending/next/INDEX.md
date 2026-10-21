# road-map/pending/next/
Ordered by priority (top first).

| File | Task | Title | Requirements |
|---|---|---|---|
| `TASK-0005-implement-str-and-test-libraries.md` | `TASK-0005` | Implement `str.rg` library and extend `test.rg` with `RG-011` message-annotated assertions | `FR-STR-001`, `FR-TST-001` |
| `TASK-0006-implement-posix-library.md` | `TASK-0006` | Implement `posix.rg` library (`PollStatus`, `ProcStatus`, descriptors, clocks, signals, CSPRNG) | `FR-POSIX-001`, `FR-POSIX-002` |
| `TASK-0007-implement-io-library.md` | `TASK-0007` | Implement `io.rg` library (`IoError`, `IoResult`, timeout descriptor ops, file metadata, streams) | `FR-IO-001`, `FR-IO-002`, `NFR-PERF-001` |
| `TASK-0008-implement-crypto-and-aead-library.md` | `TASK-0008` | Implement `crypto.rg` and extend `argon2id.rg` (bytes, bitops, SHA-256, HMAC, PBKDF2, 5-arg Argon2id, ChaCha20-Poly1305 AEAD) | `FR-CRYPTO-003`, `FR-CRYPTO-004`, `NFR-PERF-001` |
| `TASK-0009-extend-socket-rgf001-and-build-bundles.md` | `TASK-0009` | Extend `socket.rg` with Solstice `RGF-001` kernel-backed socket API and build all 7 `.rglib`/`.so` bundles | `FR-SOCK-004`, `NFR-SEC-001` |
