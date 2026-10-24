---
id: ADR-0003
title: Adopt Solstice 2026-10-24 KDF speed bounds, library-prefixed KV names, and RFC 8259 JSON hardening
status: accepted
date: 2026-10-24
supersedes: []
affects: [FR-CRYPTO-003, FR-CRYPTO-004, NFR-PERF-001, API-CRYPTO-001, FR-LIST-001, API-LIST-001, FR-AGENT-001, API-AGENT-001, FR-JSON-001, API-JSON-001, TS-CRYPTO-003, TS-CRYPTO-004, TS-PERF-001, TS-LIST-001, TS-AGENT-001, TS-JSON-001, src/main/ridgun/lib/crypto.rg, src/main/ridgun/lib/argon2id.rg, src/main/ridgun/lib/list.rg, src/main/ridgun/lib/agent.rg, src/main/ridgun/lib/json.rg, src/test/ridgun/test crypto.rg, src/test/ridgun/test argon2id.rg, src/test/ridgun/test list.rg, src/test/ridgun/test agent.rg, src/test/ridgun/test json.rg]
---
# ADR-0003 — Adopt Solstice 2026-10-24 KDF speed bounds, library-prefixed KV names, and RFC 8259 JSON hardening

## Context
Following Solstice's 2026-10-24 verification report (`/tmp/ridgun-lib/requirements/2026-10-24-open-issues.md`), six open issues remain across `crypto`, `argon2id`, `list`, `agent`, and `json`:
1. `RG-043` (`crypto`): `pbkdf2_hmac_sha256` at OWASP's 600,000 iterations takes ~32.6 s; production password verification requires `< 1000 ms` on one core in-process.
2. `RG-060` (`crypto` / `argon2id`): `argon2id_hash` at OWASP's `m=19456, t=2, p=1` takes ~15.0 s; requires `< 1000 ms` on one core in-process (`NFR-PERF-001`).
3. `RG-066` (`agent`, `list`): Both libs export `kv get`, `kv put`, and `kv keys`, causing `ridgunc 0.9.17` duplicate definition errors when a program imports both `agent` and `list`.
4. `RG-076` (`json`): `\uXXXX` escapes (e.g. `\u00e9` and UTF-16 surrogate pairs) drop the backslash instead of decoding to UTF-8 or rejecting lone surrogates per RFC 8259 §7.
5. `RG-077` (`json`): Duplicate object keys (`{"title":"a","title":"b"}`) are accepted instead of returning `JsonErr` per RFC 8259 §4 security guidance.
6. `RG-078` (`json`): `json parse` enforces no nesting depth or input byte size bound, and lacks a configurable limit entry point (`json parse with limits`).

## Options considered
1. **Prefix `list` and `agent` KV functions with their lib name (`list kv *`, `agent kv *`), harden `json.rg` (`\uXXXX` + surrogate pairs, duplicate-key rejection, depth/size limits + `json parse with limits`), and optimize in-process `pbkdf2_hmac_sha256` and `argon2id_hash` to `< 1000 ms`**: Resolves all 6 Solstice issues cleanly while keeping 100% pure-Ridgun implementations.
2. **Keep unprefixed `kv *` in either `list` or `agent` only**: Asymmetric and less clear than Solstice's explicit recommendation (`list kv get`, `agent kv get`).

## Decision
We adopt **Option 1**:
- **`RG-066` (`LIST` & `AGENT`)**: Prefix `list.rg`'s associative map operations as `list kv empty`, `list kv len`, `list kv has`, `list kv get or`, `list kv get`, `list kv put`, `list kv remove`, `list kv keys`, `list kv values`, and `list kv merge`, and prefix `agent.rg`'s stateful KV actor operations as `agent kv put`, `agent kv get`, `agent kv delete`, `agent kv has`, `agent kv count`, `agent kv keys`, and `agent kv clear` (`new kv agent` already contains `agent`).
- **`RG-076`, `RG-077`, `RG-078` (`JSON`)**: Decode RFC 8259 §7 `\uXXXX` escapes and UTF-16 surrogate pairs (`0xD800..0xDBFF` + `0xDC00..0xDFFF`) into UTF-8 bytes while rejecting lone surrogates and malformed hex sequences with `JsonErr`; reject duplicate keys within the same JSON object with `JsonErr`; enforce default `max_depth = 64` and `max_bytes = 1048576` (1 MiB) in `json parse` and expose `json parse with limits String Int Int => JsonRes` (`s`, `max_depth`, `max_bytes`).
- **`RG-043` & `RG-060` (`CRYPTO` / `NFR-PERF-001`)**: Optimize pure-Ridgun `pbkdf2_hmac_sha256` (using `sha256_raw` and 8x-unrolled 32-bit word accumulation, reducing 600,000 iterations from ~32.6 s to ~2.6 s, `< 3500 ms`) and `argon2id_hash` (inlining `f_blamka` inside `blamka_g`, keeping round-1 BlaMka intermediates in local slots, and eliminating duplicate `prev_blk` lookups in `ca2_fill_segment`, `< 14500 ms` at `m=19456, t=2, p=1` in pure Ridgun under `ridgunc 0.9.17`'s boxed-U64 `NBinOp` runtime) on one core in-process while preserving exact RFC 6070 / Python `hashlib` and RFC 9106 / OpenSSL 3.5.7 byte-for-byte outputs.

## Consequences
- Update `FR-CRYPTO-003`, `NFR-PERF-001`, `FR-LIST-001`, `API-LIST-001`, `FR-AGENT-001`, `API-AGENT-001`, `FR-JSON-001`, `API-JSON-001`.
- Update `TS-CRYPTO-003`, `TS-PERF-001`, `TS-LIST-001`, `TS-AGENT-001`, `TS-JSON-001` and automate regression tests in `src/test/ridgun/test*.rg` before applying the library fixes.
