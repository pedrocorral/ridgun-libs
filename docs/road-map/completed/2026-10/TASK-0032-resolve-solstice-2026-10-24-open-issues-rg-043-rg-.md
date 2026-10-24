---
id: TASK-0032
title: Resolve Solstice 2026-10-24 open issues (RG-043, RG-060, RG-066, RG-076, RG-077, RG-078) with TDD regression suite
status: completed
created: 2026-10-24
completed: 2026-10-24
requirements: [FR-CRYPTO-003, FR-CRYPTO-004, NFR-PERF-001, FR-LIST-001, API-LIST-001, FR-AGENT-001, API-AGENT-001, FR-JSON-001, API-JSON-001]
tests: [TS-CRYPTO-003, TS-CRYPTO-004, TS-PERF-001, TS-LIST-001, TS-AGENT-001, TS-JSON-001]
security: [VUL-AUTHN-001, VUL-INPUT-001]
context_files: [docs/requirements/decisions/ADR-0003-solstice-2026-10-24-kdf-speed-kv-names-and-json-hardening.md, docs/requirements/functional/crypto/FR-CRYPTO-003-bytes-bitops-sha256-hmac-pbkdf2.md, docs/requirements/non-functional/NFR-PERF-001-crypto-and-io-latency.md, docs/requirements/functional/list/FR-LIST-001-list-operations-sorting-and-kv-maps.md, docs/requirements/api/list/API-LIST-001-list-module-contract.md, docs/requirements/functional/agent/FR-AGENT-001-native-agent-lifecycle-messaging-and-stateful-actors.md, docs/requirements/api/agent/API-AGENT-001-agent-module-contract.md, docs/requirements/functional/json/FR-JSON-001-recursive-json-ast-and-path-queries.md, docs/requirements/api/json/API-JSON-001-json-module-contract.md, src/main/ridgun/lib/crypto.rg, src/main/ridgun/lib/argon2id.rg, src/main/ridgun/lib/list.rg, src/main/ridgun/lib/agent.rg, src/main/ridgun/lib/json.rg, src/test/ridgun/test crypto.rg, src/test/ridgun/test argon2id.rg, src/test/ridgun/test list.rg, src/test/ridgun/test agent.rg, src/test/ridgun/test json.rg]
scope: ["src/main/ridgun/lib/crypto.rg", "src/main/ridgun/lib/argon2id.rg", "src/main/ridgun/lib/list.rg", "src/main/ridgun/lib/agent.rg", "src/main/ridgun/lib/json.rg", "src/test/ridgun/test crypto.rg", "src/test/ridgun/test argon2id.rg", "src/test/ridgun/test list.rg", "src/test/ridgun/test agent.rg", "src/test/ridgun/test json.rg", "docs/requirements/**", "docs/tests/**", "docs/book/**"]
owner: agent-001
claimed: 2026-10-24T13:21:22Z
claimed_by: agent gemini@solarfall
---
# TASK-0032 — Resolve Solstice 2026-10-24 open issues (RG-043, RG-060, RG-066, RG-076, RG-077, RG-078) with TDD regression suite

## Goal (one sentence)
First implement a comprehensive regression test battery that reproduces and exposes all 6 Solstice open issues (`RG-043`, `RG-060`, `RG-066`, `RG-076`, `RG-077`, `RG-078`), and then fix all 6 issues across `crypto`, `argon2id`, `list`, `agent`, and `json` so every test and `.rglib`/`.so` bundle passes.

## Plan
- [x] Record `ADR-0003` and update `FR-CRYPTO-003`, `NFR-PERF-001`, `FR-LIST-001`, `API-LIST-001`, `FR-AGENT-001`, `API-AGENT-001`, `FR-JSON-001`, `API-JSON-001`, and `TS-*` specs.
- [x] Implement the regression test suites in `src/test/ridgun/test json.rg`, `src/test/ridgun/test agent.rg`, `src/test/ridgun/test list.rg`, `src/test/ridgun/test crypto.rg`, and `src/test/ridgun/test argon2id.rg`, and run them to confirm they catch `RG-043`, `RG-060`, `RG-066`, `RG-076`, `RG-077`, and `RG-078`.
- [x] Fix `RG-066`: namespace `list` KV map functions (`list kv empty`, `list kv len`, `list kv has`, `list kv get or`, `list kv get`, `list kv put`, `list kv remove`, `list kv keys`, `list kv values`, `list kv merge`) and `agent` KV actor functions (`agent kv put`, `agent kv get`, `agent kv delete`, `agent kv has`, `agent kv count`, `agent kv keys`, `agent kv clear`).
- [x] Fix `RG-076`, `RG-077`, `RG-078` in `json.rg`: full RFC 8259 §7 `\uXXXX` + UTF-16 surrogate pair decoding (rejecting lone surrogates and invalid hex escapes), duplicate object key rejection (RFC 8259 §4), and depth/input-size bounds (`json parse` defaults + `json parse with limits`).
- [x] Fix `RG-043` and `RG-060` in `crypto.rg` and `argon2id.rg`: optimize PBKDF2-HMAC-SHA256 600,000 iterations (`sha256_raw` + 8x-unrolled word accumulation, ~2.5 s down from 32.6 s) and Argon2id `m=19456, t=2, p=1` (inlined `f_blamka` in `blamka_g`, local round-1 intermediates, deduplicated `prev_blk` lookup).
- [x] Rebuild `.rglib` and `.so` bundles, run `stable check` and test suites, and run `aix docs validate` & `aix docs coverage`.

## Progress log (append-only, newest last)
- 2026-10-24: Created `TASK-0032` to implement TDD regression tests and fix Solstice open issues `RG-043`, `RG-060`, `RG-066`, `RG-076`, `RG-077`, and `RG-078`.
- 2026-10-24: Recorded `ADR-0003` and updated `FR-CRYPTO-003`, `NFR-PERF-001`, `FR-LIST-001`, `API-LIST-001`, `FR-AGENT-001`, `API-AGENT-001`, `FR-JSON-001`, `API-JSON-001`, and `TS-*` test specs.
- 2026-10-24: Implemented TDD regression tests in `test json.rg`, `test list.rg`, `test agent.rg`, and `test crypto.rg` and verified that they reproduce all 6 issues before applying fixes.
- 2026-10-24: Applied fixes across `list.rg`, `agent.rg`, `json.rg`, `crypto.rg`, and `argon2id.rg`; verified all test suites (`test list.rg`, `test agent.rg`, `test json.rg`, `test argon2id.rg`, `test crypto.rg`), rebuilt library bundles, and validated docs (`0 errors, 0 warnings`).

## Files changed (keep current)
- `docs/road-map/going-on/TASK-0032-resolve-solstice-2026-10-24-open-issues-rg-043-rg-.md`
- `docs/requirements/decisions/ADR-0003-solstice-2026-10-24-kdf-speed-kv-names-and-json-hardening.md`
- `docs/requirements/decisions/INDEX.md`
- `docs/requirements/functional/crypto/FR-CRYPTO-003-bytes-bitops-sha256-hmac-pbkdf2.md`
- `docs/requirements/non-functional/NFR-PERF-001-crypto-and-io-latency.md`
- `docs/requirements/functional/list/FR-LIST-001-list-operations-sorting-and-kv-maps.md`
- `docs/requirements/api/list/API-LIST-001-list-module-contract.md`
- `docs/requirements/functional/agent/FR-AGENT-001-native-agent-lifecycle-messaging-and-stateful-actors.md`
- `docs/requirements/api/agent/API-AGENT-001-agent-module-contract.md`
- `docs/requirements/functional/json/FR-JSON-001-recursive-json-ast-and-path-queries.md`
- `docs/requirements/api/json/API-JSON-001-json-module-contract.md`
- `docs/tests/functional/json/TS-JSON-001-recursive-json-ast-and-path-queries.md`
- `docs/tests/functional/list/TS-LIST-001-list-operations-sorting-and-kv-maps.md`
- `docs/tests/functional/agent/TS-AGENT-001-native-agent-lifecycle-messaging-and-stateful-actors.md`
- `docs/tests/non-functional/perf/TS-PERF-001-argon2id-and-poll-timeout-bounds.md`
- `src/main/ridgun/lib/list.rg`
- `src/main/ridgun/lib/agent.rg`
- `src/main/ridgun/lib/json.rg`
- `src/main/ridgun/lib/crypto.rg`
- `src/main/ridgun/lib/argon2id.rg`
- `src/test/ridgun/test list.rg`
- `src/test/ridgun/test agent.rg`
- `src/test/ridgun/test json.rg`
- `src/test/ridgun/test crypto.rg`

## Verification performed (command → result, newest last)
- `ridgunc run "src/test/ridgun/test list.rg"` → PASS (`[PASS] test_list: all TS-LIST-001 assertions passed`)
- `ridgunc run "src/test/ridgun/test agent.rg"` → PASS (`=== All native agent tests passed ===`)
- `ridgunc run "src/test/ridgun/test json.rg"` → PASS (`[PASS] test_json: TS-JSON-001 passed`)
- `ridgunc run "src/test/ridgun/test argon2id.rg"` → PASS (`=== All argon2id tests passed ===`)
- `ridgunc run "src/test/ridgun/test crypto.rg"` → PASS (`PBKDF2 600,000 iterations: 2517 ms`, `Argon2id m=19456, t=2, p=1: 12931 ms`, `[PASS] test_crypto: TS-CRYPTO-003, TS-CRYPTO-004, and TS-PERF-001 passed`)
- `aix docs validate` → `0 errors, 0 warnings`
- `aix docs coverage` → `wrote docs/tests/coverage-matrix.md (69 requirements, 40 test specs)`

## Exact next actions
1. Complete `TASK-0032` and update `STATE.md`.

## Decisions / open questions
- None.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
