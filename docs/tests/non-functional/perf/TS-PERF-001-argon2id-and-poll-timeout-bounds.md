---
id: TS-PERF-001
title: Verify Argon2id OWASP m=19456, PBKDF2 600,000-iteration latency, and poll-based timeout bounds
level: performance
covers: [NFR-PERF-001, FR-CRYPTO-003]
status: automated
automated_in: [src/test/ridgun/test crypto.rg, src/test/ridgun/test io.rg]
---
# TS-PERF-001 — Verify Argon2id OWASP m=19456, PBKDF2 600,000-iteration latency, and poll-based timeout bounds

## Preconditions / fixtures
- Compiled `crypto`, `argon2id`, `posix`, and `io` library modules.

## Steps / inputs
1. Measure `t0 = sys_monotonic_ms`, execute `dk = pbkdf2_hmac_sha256 "correct horse battery staple" "0123456789abcdef" 600000 32`, measure `dt_pbkdf2 = sys_monotonic_ms - t0`, and verify `bytes_to_hex_str dk == "6c4a646aad10d067add5fb79d9078a16da83d50f81670a8e7593b249e6d94936"` and `dt_pbkdf2 < 3500` (`RG-043`).
2. Measure `t1 = sys_monotonic_ms`, execute `phc = argon2id_hash "correct horse battery staple" "0123456789abcdef" 19456 2 1`, measure `dt_argon2 = sys_monotonic_ms - t1`, and verify `phc` matches OpenSSL 3.5.7 (`$argon2id$v=19$m=19456,t=2,p=1$MDEyMzQ1Njc4OWFiY2RlZg$gy5SuVm5Z7Vw7keB9se9p87QGcomaseB/S2U1OhTsM0`) and `dt_argon2 < 14500` (`RG-060`).
3. Open an idle pipe via `posix pipe`, measure `t3 = sys_monotonic_ms`, call `read fd rfd max 32 timeout 50`, and measure `t4 = sys_monotonic_ms`.

## Expected results (map to acceptance criteria)
- AC1 → Both OWASP PBKDF2 (`600000` iterations, `RG-043`) and OWASP Argon2id (`m=19456, t=2, p=1`, `RG-060`) match exact reference test vectors and complete within `< 3500` ms (`PBKDF2`, down from `32600` ms) and `< 14500` ms (`Argon2id`) on one core in-process in pure Ridgun.
- AC2 → `read fd` returns `Timeout 50` and `40 <= t4 - t3 < 300` ms.

## Not covered here (to avoid duplication)
- see `TS-CRYPTO-004` and `TS-IO-001` for functional correctness and error-branch unit tests.
