---
id: TASK-0001
title: Bootstrap project — vision, glossary, stack decision, layout
status: completed
created: 2026-09-04
completed: 2026-10-21
requirements: [FR-SOCK-001, FR-SOCK-002, FR-CRYPTO-001]
tests: [TS-SOCK-001, TS-SOCK-002, TS-CRYPTO-001]
security: [VUL-INJ-002, VUL-INPUT-001, VUL-AUTHN-001]
context_files: [docs/requirements/product/vision.md, docs/requirements/product/glossary.md, docs/requirements/decisions/ADR-0001-adopt-aix-and-choose-stack.md, docs/requirements/functional/sock/FR-SOCK-001-socket-address-and-lifecycle.md, docs/requirements/functional/sock/FR-SOCK-002-socket-data-transfer-and-framing.md, docs/requirements/functional/crypto/FR-CRYPTO-001-argon2id-phc-hashing-and-verification.md]
owner: agent-001
claimed: 2026-10-21T14:55:12Z
claimed_by: agent gemini@solarfall
---
# TASK-0001 — Bootstrap project

## Goal (one sentence)
Turn the kit into *this* project: vision, domains, stack decision, initial layout, register tagging.

## Plan
- [x] Interview the user; fill `vision.md`, `personas.md`, `glossary.md` (domain codes `SOCK`, `CRYPTO`).
- [x] Complete and accept `ADR-0001` (pure-Ridgun `v0.9.3` single-root `stable` library project).
- [x] Approve initial functional requirements (`FR-SOCK-001`, `FR-SOCK-002`, `FR-CRYPTO-001`) and plan tests (`TS-SOCK-001`, `TS-SOCK-002`, `TS-CRYPTO-001`).
- [x] Update `threat-model.md` with component tags (`socket.rg`, `argon2id.rg`).
- [x] Delete `example` domain docs once real domains exist.
- [x] Scaffold `build.rg` and library/test tasks (`TASK-0002`, `TASK-0003`) in `pending/next/`.
## Progress log (append-only, newest last)
- 2026-09-04: created by installer.
- 2026-10-21: completed product docs, `ADR-0001`, `threat-model.md`, approved `FR-SOCK-001`, `FR-SOCK-002`, `FR-CRYPTO-001`, planned `TS-SOCK-001`, `TS-SOCK-002`, `TS-CRYPTO-001`, scaffolded `build.rg`, and created `TASK-0002` and `TASK-0003`.
## Decisions / open questions
- Single root `stable` project (`ADR-0001`), library-only (no standalone CLI executables), Blake2b kept internal to `argon2id.rg`.
## Definition of done checklist
- [x] docs validated  - [x] STATE.md updated  - [x] first real tasks in `pending/next/`
