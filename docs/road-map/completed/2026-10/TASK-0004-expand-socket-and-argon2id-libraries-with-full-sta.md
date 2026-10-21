---
id: TASK-0004
title: Expand socket and argon2id libraries with full standard functionality
status: completed
created: 2026-10-21
completed: 2026-10-21
requirements: [FR-SOCK-003, FR-CRYPTO-002]
tests: [TS-SOCK-003, TS-CRYPTO-002]
security: [VUL-INPUT-001, VUL-AUTHN-001]
context_files: [build.rg, docs/requirements/functional/sock/FR-SOCK-003-advanced-socket-ops-dns-cidr-and-polling.md, docs/requirements/functional/crypto/FR-CRYPTO-002-argon2id-key-derivation-salting-and-rehash.md, docs/tests/functional/sock/TS-SOCK-003-advanced-socket-ops-dns-cidr-and-polling.md, docs/tests/functional/crypto/TS-CRYPTO-002-argon2id-key-derivation-salting-and-rehash.md, src/main/ridgun/lib/socket.rg, src/main/ridgun/lib/argon2id.rg, src/test/ridgun/test_socket.rg, src/test/ridgun/test_argon2id.rg]
owner: agent-001
claimed: 2026-10-21T16:43:41Z
claimed_by: agent gemini@solarfall
---
# TASK-0004 — Expand socket and argon2id libraries with full standard functionality

## Goal (one sentence)
Expand `socket.rg` and `argon2id.rg` with standard library capabilities (`FR-SOCK-003`, `FR-CRYPTO-002`) and automate `TS-SOCK-003` and `TS-CRYPTO-002`.

## Plan
- [x] Add `sock shutdown`, `sock local addr`, `sock peer addr`, `sock send all`, `sock recv exact`, `sock poll`, `tcp_nodelay`, `broadcast`, `rcvbuf`/`sndbuf`, DNS hostname validation/resolution (`is valid hostname`, `sock resolve host`), and IPv4 CIDR matching (`ip in cidr`) to `src/main/ridgun/lib/socket.rg` (`FR-SOCK-003`).
- [x] Add `argon2id generate salt`, `argon2id hash password`, `argon2id parse phc`, `argon2id needs rehash`, `argon2id derive key`, `argon2id derive key hex`, `argon2id hash ctx`, `argon2id verify ctx`, and OWASP parameter presets (`argon2 interactive params`, `argon2 moderate params`, `argon2 sensitive params`) to `src/main/ridgun/lib/argon2id.rg` (`FR-CRYPTO-002`).
- [x] Automate `TS-SOCK-003` and `TS-CRYPTO-002` in `src/test/ridgun/test_socket.rg` and `src/test/ridgun/test_argon2id.rg`, verify with `stable check` and `stable test`, and build `.rgc`, `.so`, and `.rglib` artifacts.

## Progress log (append-only, newest last)
- 2026-10-21: created task.
- 2026-10-21: implemented `FR-SOCK-003` and `FR-CRYPTO-002`, automated `TS-SOCK-003` and `TS-CRYPTO-002`, verified `stable check` (3/3 modules, 0 errors) and `stable test` (2/2 suites passed), and built `.rgc`, `.so`, and `.rglib` library artifacts.

## Decisions / open questions
- Placed `.rglib` bundles in `target/bundles/` so `ridgunc` does not double-load `target/<mod>.rglib` and `src/main/ridgun/lib/<mod>.rg` during `stable test`.

## Definition of done checklist
- [x] `stable check` & `stable test` green  - [x] `@implements`/`@tests`/`@mitigates` markers in place  - [x] `aix docs validate` 0 errors
