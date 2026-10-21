---
id: PRODUCT-PERSONAS
title: Personas
status: approved
---
# Personas
| Persona | Goals | Pain points | Key FRs |
|---|---|---|---|
| Ridgun Application & Server Developer | Import reliable networking (`socket`), cryptographic (`argon2id`, `crypto`), system (`posix`), I/O (`io`), string (`str`), and test (`test`) libraries via `stable` | Writing low-level socket framing, timeout-bounded `poll` I/O, RFC 9106 Argon2id, RFC 8439 ChaCha20-Poly1305, or string/file helpers from scratch | FR-SOCK-001..004, FR-CRYPTO-001..004, FR-POSIX-001..002, FR-IO-001..002, FR-STR-001, FR-TST-001 |
| Systems & Unix-Tools Developer | Build non-blocking CLI utilities and daemons on top of `posix.rglib` and `io.rglib` using `PollStatus`, `ProcStatus`, `IoError`, `IoResult`, and millisecond timeouts | Blocking indefinitely on descriptors or child processes without `sys poll` timeouts or structured `IoError` variants | FR-POSIX-001, FR-POSIX-002, FR-IO-001, FR-IO-002 |
| Security Reviewer | Audit deterministic memory management (`RMM1`/`RMM2`), constant-time tag verification (`ct_equal`, Poly1305, Argon2id), CSPRNG entropy, and input/path validation across all libraries | Timing side-channels on MAC/password/AEAD tag verification, weak nonces/salts, path traversal, or unbounded reads | FR-SOCK-001, FR-SOCK-004, FR-CRYPTO-001..004, FR-POSIX-002, FR-IO-001 |
