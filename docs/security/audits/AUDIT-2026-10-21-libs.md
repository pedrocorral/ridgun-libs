---
id: AUDIT-2026-10-21-libs
skill: security-audit
date: 2026-10-21
scope: [src/main/ridgun/lib/socket.rg, src/main/ridgun/lib/argon2id.rg]
result: pass
---
# Audit — socket and argon2id libraries — 2026-10-21

## Method (what was checked, tools run)
- Executed `aix code security src` (`0` findings across 17 rule categories).
- Reviewed endpoint validation in `src/main/ridgun/lib/socket.rg` (`is safe unix path`, `is valid ipv4`, `is valid ipv6`, `is valid port`, `sock recv frame` / `sock recv line` `max_bytes` bounds).
- Reviewed RFC 9106 parameter validation (`validate argon2 params`) and constant-time tag comparison (`constant time bytes eq`, `constant time eq`) in `src/main/ridgun/lib/argon2id.rg`.
- Executed negative test cases in `src/test/ridgun/test_socket.rg` and `src/test/ridgun/test_argon2id.rg` via `stable test`.

## Findings
| VUL id | Asset / threat | Impact | Likelihood rationale | Control | Verification method | Evidence | Status before → after | Residual risk |
|---|---|---|---|---|---|---|---|---|
| VUL-INJ-002 | Unix socket path traversal / shell metacharacter injection | High | Low: strict path whitelist and metacharacter rejection | `is safe unix path` rejects `..`, `;`, `\|`, `&`, `$`, `` ` ``, spaces, and lengths outside `2..108` | Automated unit test (`TS-SOCK-001`) | `src/test/ridgun/test_socket.rg` (`test_sock_address_and_lifecycle`) | expected → mitigated | Low |
| VUL-INPUT-001 | Unbounded socket frame/buffer read or invalid Argon2id parameters | Medium | Low: explicit `max_bytes` & RFC 9106 parameter bounds | `sock recv frame`/`sock recv line` enforce `max_bytes`; `validate argon2 params` enforces `m >= 8*p`, `t >= 1`, `salt >= 8` | Automated unit tests (`TS-SOCK-001`, `TS-SOCK-002`, `TS-CRYPTO-001`) | `src/test/ridgun/test_socket.rg`, `src/test/ridgun/test_argon2id.rg` | expected → mitigated | Low |
| VUL-AUTHN-001 | Weak password hashing or timing side-channel in tag comparison | High | Low: memory-hard Argon2id + constant-time XOR accumulator | `argon2id hash` & `constant time bytes eq` in `src/main/ridgun/lib/argon2id.rg` | Automated unit test (`TS-CRYPTO-001`) | `src/test/ridgun/test_argon2id.rg` (`test_argon2id_phc_hashing_and_verification`) | expected → mitigated | Low |

## New vulnerabilities discovered (added to register)
- None.

## Follow-ups (tasks created)
- None.
