---
id: TS-PERF-001
title: Verify Argon2id OWASP m=19456 latency and poll-based timeout bounds
level: performance
covers: [NFR-PERF-001]
status: planned
automated_in: [src/test/ridgun/test_crypto.rg, src/test/ridgun/test_io.rg]
---
# TS-PERF-001 — Verify Argon2id OWASP m=19456 latency and poll-based timeout bounds

## Preconditions / fixtures
- Compiled `crypto`, `argon2id`, `posix`, and `io` library modules.

## Steps / inputs
1. Measure `t1 = sys_monotonic_ms ()`, execute `phc = argon2id_hash "password" "saltsalt" 19456 2 1` and `ok = argon2id_verify "password" phc`, and measure `t2 = sys_monotonic_ms ()`.
2. Open an idle pipe via `posix pipe`, measure `t3 = sys_monotonic_ms ()`, call `read fd rfd max 32 timeout 50`, and measure `t4 = sys_monotonic_ms ()`.

## Expected results (map to acceptance criteria)
- AC1 → `ok == True` and `t2 - t1 < 2000` ms.
- AC2 → `read fd` returns `Timeout 50` and `40 <= t4 - t3 < 300` ms.

## Not covered here (to avoid duplication)
- see `TS-CRYPTO-004` and `TS-IO-001` for functional correctness and error-branch unit tests.
