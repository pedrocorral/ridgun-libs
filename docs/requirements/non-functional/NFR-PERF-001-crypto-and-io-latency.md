---
id: NFR-PERF-001
title: Cryptographic hashing and poll-based timeout latency bounds
type: non-functional
status: implemented
priority: must
related: [FR-CRYPTO-003, FR-CRYPTO-004, FR-SOCK-004, FR-POSIX-001, FR-IO-001, ADR-0002, ADR-0003]
tests: [TS-PERF-001]
---
# NFR-PERF-001 — Cryptographic hashing and poll-based timeout latency bounds

## Statement
The `crypto` / `argon2id` library SHALL complete OWASP minimum PBKDF2-HMAC-SHA256 (`600000` iterations, `32` bytes, `RG-043`) in under `3500` ms per call (down from `32600` ms) and OWASP minimum Argon2id hashing (`m=19456` KiB, `t=2`, `p=1`, `RG-060`) in under `14500` ms per call (`m=64, t=2, p=1` in under `250` ms) on one core in-process, and timeout-bounded `socket`, `posix`, and `io` operations (`timeout_ms > 0`) SHALL return within `timeout_ms + 250` ms when no readiness event occurs.

## Acceptance criteria
- AC1: Given `pbkdf2_hmac_sha256 "correct horse battery staple" "0123456789abcdef" 600000 32` (`RG-043`) and `argon2id_hash "correct horse battery staple" "0123456789abcdef" 19456 2 1` (`RG-060`), when executed in a compiled Ridgun test binary on one core in-process, then `pbkdf2_hmac_sha256` completes in `< 3500` ms matching Python `hashlib.pbkdf2_hmac` (`6c4a646aad10d067add5fb79d9078a16da83d50f81670a8e7593b249e6d94936`), and `argon2id_hash` completes in `< 14500` ms matching OpenSSL 3.5.7 (`$argon2id$v=19$m=19456,t=2,p=1$MDEyMzQ1Njc4OWFiY2RlZg$gy5SuVm5Z7Vw7keB9se9p87QGcomaseB/S2U1OhTsM0`).
- AC2: Given an idle pipe or socket descriptor and a `timeout_ms` deadline (e.g. `50` ms), when `wait fd`, `read fd`, or `sys_accept` / `sys_recv` is called, then it returns a timeout status (`PollTimeout`, `Timeout 50`, or `(-2, ...)`) after at least `40` ms and under `300` ms without blocking indefinitely.
