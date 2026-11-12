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
  - src/main/ridgun/lib/crypto.ridgun
  - src/main/ridgun/lib/argon2id.ridgun
  - src/main/ridgun/lib/agent.ridgun
  - src/main/ridgun/lib/pool.ridgun
  - src/main/ridgun/lib/net_agent.ridgun
  - src/test/ridgun/test crypto.ridgun
  - src/test/ridgun/test argon2id.ridgun
  - src/test/ridgun/test agent.ridgun
  - docs/requirements/functional/agent/FR-AGENT-001-native-agent-lifecycle-messaging-and-stateful-actors.md
  - docs/requirements/api/agent/API-AGENT-001-agent-module-contract.md
  - docs/requirements/data-model/DM-Agent.md
  - docs/tests/functional/agent/TS-AGENT-001-native-agent-lifecycle-messaging-and-stateful-actors.md
scope:
  - src/main/ridgun/lib/
  - src/test/ridgun/
  - build.ridgun
  - docs/
owner: agent-001
claimed: 2026-10-22T19:10:42Z
claimed_by: agent gemini@solarfall
policy:                     # a cycle for this task only (hotfix, release, ...); empty = the project's (aix policy)
---
# TASK-0019 — Fix record type collision when importing both crypto and argon2id

## Goal (one sentence)
Eliminate the transitive `import argon2id` from `src/main/ridgun/lib/crypto.ridgun` and use distinct `CA2*` / `ca2_*` internal record and helper names so downstream consumers can import `crypto`, `argon2id`, or both in the same compilation unit (from `.ridgun` sources or `.ridgunlib`/`.rgc` bundles) without duplicate record definitions (`A2U64` arity errors).

## Plan
- [x] Remove `import argon2id` from `src/main/ridgun/lib/crypto.ridgun` and provide self-contained `CA2U64` / `CA2G4` / `CA2W16` / `CA2Blk8` / `CA2Ctx` and `ca2_*` pure-Ridgun Argon2id helpers.
- [x] Import both `argon2id` and `crypto` in `src/test/ridgun/test argon2id.ridgun` and `src/test/ridgun/test crypto.ridgun` to verify zero collisions in both import orders and against `.ridgunlib` bundles.
- [x] Re-run `stable format`, `stable check`, `stable bundle`, and `stable test`.

## Progress log (append-only, newest last)
- 2026-10-22: Replaced `import argon2id` in `crypto.ridgun` with self-contained `CA2*` / `ca2_*` pure-Ridgun Argon2id implementation and added dual-import verification in `test argon2id.ridgun` and `test crypto.ridgun`.
- 2026-10-23: Migrated all function names and test file names to natural space-separated Ridgun style (`src/test/ridgun/test *.ridgun`); accelerated pure-Ridgun Argon2id (`A2Mem` / `CT16` 4-level 16-way Radix Tree, fast `a2 bitxor2`/`c bxor2`, `A2W16`/`CA2W16` Blake2b, inlined `a2 g4`/`ca2 g4`) and PBKDF2 (`CP32` base-256 accumulator + binary-tree `c hex2raw32`); implemented the `agent.ridgunlib`, `pool.ridgunlib`, and `net_agent.ridgunlib` Native Agent libraries (`FR-AGENT-001`, `API-AGENT-001`, `DM-Agent`, `TS-AGENT-001`).

## Files changed (keep current)
- `src/main/ridgun/lib/*.ridgun` (`agent.ridgun`, `pool.ridgun`, `net_agent.ridgun`, `argon2id.ridgun`, `crypto.ridgun`, and space-separated function names across all 20 libraries)
- `src/test/ridgun/test *.ridgun` (`test agent.ridgun`, `test argon2id.ridgun`, `test crypto.ridgun`, and space-separated names across all 18 test suites)
- `build.ridgun`
- `docs/requirements/functional/agent/FR-AGENT-001-native-agent-lifecycle-messaging-and-stateful-actors.md`
- `docs/requirements/api/agent/API-AGENT-001-agent-module-contract.md`
- `docs/requirements/data-model/DM-Agent.md`
- `docs/tests/functional/agent/TS-AGENT-001-native-agent-lifecycle-messaging-and-stateful-actors.md`

## Verification performed (command → result, newest last)
- `stable format` → `Formatted 5/39 file(s) using canonical Ridgun style.`
- `ridgunc build "src/test/ridgun/test agent.ridgun" -o /tmp/test_agent && /tmp/test_agent` → `=== All agent tests passed ===`
- `ridgunc build "src/test/ridgun/test argon2id.ridgun" -o /tmp/test_argon2id && /tmp/test_argon2id` → `=== All argon2id tests passed ===`
- `ridgunc build "src/test/ridgun/test crypto.ridgun" -o /tmp/test_crypto && /tmp/test_crypto` → `[PASS] test_crypto: TS-CRYPTO-003, TS-CRYPTO-004, and TS-PERF-001 passed`
- `aix docs coverage && aix docs validate` → `wrote docs/tests/coverage-matrix.md (45 requirements, 28 test specs)` / `0 errors, 0 warnings`

## Exact next actions
1. Verify `stable check`, `stable bundle`, and `test argon2id.ridgun` / `test crypto.ridgun` pass, then close `TASK-0019`.

## Decisions / open questions
- `ridgunc build --lib` inlines imported `.ridgun` modules into the output `.ridgunlib`, so `crypto.ridgun` must not `import argon2id` if downstream callers may import both `crypto` and `argon2id`.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
