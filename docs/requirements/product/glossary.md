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

Domain codes are UPPERCASE, ≤ 8 chars, and name folders in `functional/`, `api/`, and `docs/tests/*/`.
