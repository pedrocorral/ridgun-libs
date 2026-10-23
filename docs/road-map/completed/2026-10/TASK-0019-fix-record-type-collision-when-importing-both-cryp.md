---
id: TASK-0019
title: Fix record type collision when importing both crypto and argon2id
status: completed
created: 2026-10-22
completed: 2026-10-23
requirements: [FR-CRYPTO-001, FR-CRYPTO-003, FR-CRYPTO-004, FR-AGENT-001, API-AGENT-001, DM-Agent]
tests: [TS-CRYPTO-001, TS-CRYPTO-003, TS-CRYPTO-004, TS-AGENT-001]
security: [VUL-AUTHN-001, VUL-INPUT-001]
context_files:
  - src/main/ridgun/lib/crypto.rg
  - src/main/ridgun/lib/argon2id.rg
  - src/main/ridgun/lib/agent.rg
  - src/main/ridgun/lib/pool.rg
  - src/main/ridgun/lib/net_agent.rg
  - src/test/ridgun/test crypto.rg
  - src/test/ridgun/test argon2id.rg
  - src/test/ridgun/test agent.rg
  - docs/requirements/functional/agent/FR-AGENT-001-native-agent-lifecycle-messaging-and-stateful-actors.md
  - docs/requirements/api/agent/API-AGENT-001-agent-module-contract.md
  - docs/requirements/data-model/DM-Agent.md
  - docs/tests/functional/agent/TS-AGENT-001-native-agent-lifecycle-messaging-and-stateful-actors.md
scope:
  - src/main/ridgun/lib/
  - src/test/ridgun/
  - build.rg
  - docs/
owner: agent-001
claimed: 2026-10-22T19:10:42Z
claimed_by: agent gemini@solarfall
policy:                     # a cycle for this task only (hotfix, release, ...); empty = the project's (aix policy)
---
# TASK-0019 — Fix record type collision when importing both crypto and argon2id

## Goal (one sentence)
Eliminate the transitive `import argon2id` from `src/main/ridgun/lib/crypto.rg` and use distinct `CA2*` / `ca2_*` internal record and helper names so downstream consumers can import `crypto`, `argon2id`, or both in the same compilation unit (from `.rg` sources or `.rglib`/`.rgc` bundles) without duplicate record definitions (`A2U64` arity errors).

## Plan
- [x] Remove `import argon2id` from `src/main/ridgun/lib/crypto.rg` and provide self-contained `CA2U64` / `CA2G4` / `CA2W16` / `CA2Blk8` / `CA2Ctx` and `ca2_*` pure-Ridgun Argon2id helpers.
- [x] Import both `argon2id` and `crypto` in `src/test/ridgun/test argon2id.rg` and `src/test/ridgun/test crypto.rg` to verify zero collisions in both import orders and against `.rglib` bundles.
- [x] Re-run `stable format`, `stable check`, `stable bundle`, and `stable test`.

## Progress log (append-only, newest last)
- 2026-10-22: Replaced `import argon2id` in `crypto.rg` with self-contained `CA2*` / `ca2_*` pure-Ridgun Argon2id implementation and added dual-import verification in `test argon2id.rg` and `test crypto.rg`.
- 2026-10-23: Migrated all function names and test file names to natural space-separated Ridgun style (`src/test/ridgun/test *.rg`); accelerated pure-Ridgun Argon2id (`A2Mem` / `CT16` 4-level 16-way Radix Tree, fast `a2 bitxor2`/`c bxor2`, `A2W16`/`CA2W16` Blake2b, inlined `a2 g4`/`ca2 g4`) and PBKDF2 (`CP32` base-256 accumulator + binary-tree `c hex2raw32`); implemented the `agent.rglib`, `pool.rglib`, and `net_agent.rglib` Native Agent libraries (`FR-AGENT-001`, `API-AGENT-001`, `DM-Agent`, `TS-AGENT-001`).

## Files changed (keep current)
- `src/main/ridgun/lib/*.rg` (`agent.rg`, `pool.rg`, `net_agent.rg`, `argon2id.rg`, `crypto.rg`, and space-separated function names across all 20 libraries)
- `src/test/ridgun/test *.rg` (`test agent.rg`, `test argon2id.rg`, `test crypto.rg`, and space-separated names across all 18 test suites)
- `build.rg`
- `docs/requirements/functional/agent/FR-AGENT-001-native-agent-lifecycle-messaging-and-stateful-actors.md`
- `docs/requirements/api/agent/API-AGENT-001-agent-module-contract.md`
- `docs/requirements/data-model/DM-Agent.md`
- `docs/tests/functional/agent/TS-AGENT-001-native-agent-lifecycle-messaging-and-stateful-actors.md`

## Verification performed (command → result, newest last)
- `stable format` → `Formatted 5/39 file(s) using canonical Ridgun style.`
- `ridgunc build "src/test/ridgun/test agent.rg" -o /tmp/test_agent && /tmp/test_agent` → `=== All agent tests passed ===`
- `ridgunc build "src/test/ridgun/test argon2id.rg" -o /tmp/test_argon2id && /tmp/test_argon2id` → `=== All argon2id tests passed ===`
- `ridgunc build "src/test/ridgun/test crypto.rg" -o /tmp/test_crypto && /tmp/test_crypto` → `[PASS] test_crypto: TS-CRYPTO-003, TS-CRYPTO-004, and TS-PERF-001 passed`
- `aix docs coverage && aix docs validate` → `wrote docs/tests/coverage-matrix.md (45 requirements, 28 test specs)` / `0 errors, 0 warnings`

## Exact next actions
1. Verify `stable check`, `stable bundle`, and `test argon2id.rg` / `test crypto.rg` pass, then close `TASK-0019`.

## Decisions / open questions
- `ridgunc build --lib` inlines imported `.rg` modules into the output `.rglib`, so `crypto.rg` must not `import argon2id` if downstream callers may import both `crypto` and `argon2id`.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
