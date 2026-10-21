---
id: NFR-PERF-001
title: Cryptographic hashing and poll-based timeout latency bounds
type: non-functional
status: approved
priority: must
related: [FR-CRYPTO-004, FR-SOCK-004, FR-POSIX-001, FR-IO-001, ADR-0002]
tests: [TS-PERF-001]
---
# NFR-PERF-001 — Cryptographic hashing and poll-based timeout latency bounds

## Statement
The `crypto` / `argon2id` library SHALL complete OWASP minimum Argon2id hashing (`m=19456` KiB, `t=2`, `p=1`) in under `1000` ms per call, and timeout-bounded `socket`, `posix`, and `io` operations (`timeout_ms > 0`) SHALL return within `timeout_ms + 250` ms when no readiness event occurs.

## Acceptance criteria
- AC1: Given `argon2id_hash "password" "saltsalt" 19456 2 1`, when executed in a compiled Ridgun test binary, then it returns a valid `$argon2id$v=19$m=19456,t=2,p=1$...` PHC string and `argon2id_verify` succeeds within a total wall-clock budget of `< 2000` ms (`< 1000` ms per hash).
- AC2: Given an idle pipe or socket descriptor and a `timeout_ms` deadline (e.g. `50` ms), when `wait fd`, `read fd`, or `sys_accept` / `sys_recv` is called, then it returns a timeout status (`PollTimeout`, `Timeout 50`, or `(-2, ...)`) after at least `40` ms and under `300` ms without blocking indefinitely.
