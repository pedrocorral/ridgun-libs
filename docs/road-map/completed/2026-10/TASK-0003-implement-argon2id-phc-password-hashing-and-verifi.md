---
id: TASK-0003
title: Implement Argon2id PHC password hashing and verification library
status: completed
created: 2026-10-21
completed: 2026-10-21
requirements: [FR-CRYPTO-001]
tests: [TS-CRYPTO-001]
security: [VUL-AUTHN-001, VUL-INPUT-001]
context_files: [build.rg, docs/requirements/functional/crypto/FR-CRYPTO-001-argon2id-phc-hashing-and-verification.md, docs/tests/functional/crypto/TS-CRYPTO-001-argon2id-phc-hashing-and-verification.md, src/main/ridgun/lib/argon2id.rg, src/test/ridgun/test_argon2id.rg]
owner: agent-001
claimed: 2026-10-21T16:20:49Z
claimed_by: agent gemini@solarfall
---
# TASK-0003 — Implement Argon2id PHC password hashing and verification library

## Goal (one sentence)
Implement `src/main/ridgun/lib/argon2id.rg` and `src/test/ridgun/test_argon2id.rg` covering `FR-CRYPTO-001` (`TS-CRYPTO-001`).

## Plan
- [x] Implement internal 32-bit/64-bit modular arithmetic, Blake2b `H'` variable-length hashing, and BlaMka `G` block compression inside `src/main/ridgun/lib/argon2id.rg`.
- [x] Implement RFC 9106 Argon2id (`y = 2`, `v = 19`) memory-matrix compression, parameter validation, unpadded Base64 PHC encoding (`$argon2id$v=19$m=...,t=...,p=...$<salt>$<tag>`), and constant-time verification (`FR-CRYPTO-001` AC1, AC2, AC3, `@mitigates VUL-AUTHN-001`, `@mitigates VUL-INPUT-001`).
- [x] Write automated tests in `src/test/ridgun/test_argon2id.rg` (`@tests TS-CRYPTO-001`) and verify with `stable check` and `stable test`.

## Progress log (append-only, newest last)
- 2026-10-21: created task.
- 2026-10-21: implemented `src/main/ridgun/lib/argon2id.rg` and `src/test/ridgun/test_argon2id.rg`; verified `stable check` (3 modules, 0 errors), `stable test` (2/2 suites passed), and `AUDIT-2026-10-21-libs.md`.

## Decisions / open questions
- Kept Blake2b/`H'` internal to `argon2id.rg` per user decision.

## Definition of done checklist
- [x] `stable check` & `stable test` green  - [x] `@implements`/`@tests`/`@mitigates` markers in place  - [x] `aix docs validate` 0 errors
