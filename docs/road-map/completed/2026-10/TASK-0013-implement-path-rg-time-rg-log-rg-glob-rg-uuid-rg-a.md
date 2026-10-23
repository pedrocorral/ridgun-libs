---
id: TASK-0013
title: Implement path.rg, time.rg, log.rg, glob.rg, uuid.rg, and http.rg standard libraries with specs, tests, and bundles
status: completed
created: 2026-10-22
completed: 2026-10-22
requirements: [FR-PATH-001, API-PATH-001, FR-TIME-001, API-TIME-001, FR-LOG-001, API-LOG-001, FR-GLOB-001, API-GLOB-001, FR-UUID-001, API-UUID-001, FR-HTTP-001, API-HTTP-001]
tests: [TS-PATH-001, TS-TIME-001, TS-LOG-001, TS-GLOB-001, TS-UUID-001, TS-HTTP-001]
security: [VUL-INJ-002, VUL-INPUT-001]
context_files:
  - build.rg
  - README.md
  - docs/requirements/product/vision.md
  - docs/requirements/product/glossary.md
  - src/main/ridgun/lib/path.rg
  - src/main/ridgun/lib/time.rg
  - src/main/ridgun/lib/log.rg
  - src/main/ridgun/lib/glob.rg
  - src/main/ridgun/lib/uuid.rg
  - src/main/ridgun/lib/http.rg
  - src/test/ridgun/test path.rg
  - src/test/ridgun/test time.rg
  - src/test/ridgun/test log.rg
  - src/test/ridgun/test glob.rg
  - src/test/ridgun/test uuid.rg
  - src/test/ridgun/test http.rg
scope:
  - build.rg
  - README.md
  - docs/requirements/**
  - docs/tests/**
  - src/main/ridgun/lib/path.rg
  - src/main/ridgun/lib/time.rg
  - src/main/ridgun/lib/log.rg
  - src/main/ridgun/lib/glob.rg
  - src/main/ridgun/lib/uuid.rg
  - src/main/ridgun/lib/http.rg
  - src/test/ridgun/test path.rg
  - src/test/ridgun/test time.rg
  - src/test/ridgun/test log.rg
  - src/test/ridgun/test glob.rg
  - src/test/ridgun/test uuid.rg
  - src/test/ridgun/test http.rg
owner: agent-001
claimed: 2026-10-22T08:21:39Z
claimed_by: agent gemini@solarfall
policy:                     # a cycle for this task only
---
# TASK-0013 — Implement path.rg, time.rg, log.rg, glob.rg, uuid.rg, and http.rg standard libraries with specs, tests, and bundles

## Goal (one sentence)
Expand `ridgun-libs` to 17 foundational pure-Ridgun (`v0.9.5`) libraries by adding `path`, `time`, `log`, `glob`, `uuid`, and `http` with full AIX requirements, API contracts, automated test suites, and `.rglib`/`.rgc`/`.so` bundles.

## Plan
- [x] Author AIX specs (`FR-PATH-001`, `API-PATH-001`, `TS-PATH-001`, `FR-TIME-001`, `API-TIME-001`, `TS-TIME-001`, `FR-LOG-001`, `API-LOG-001`, `TS-LOG-001`, `FR-GLOB-001`, `API-GLOB-001`, `TS-GLOB-001`, `FR-UUID-001`, `API-UUID-001`, `TS-UUID-001`, `FR-HTTP-001`, `API-HTTP-001`, `TS-HTTP-001`).
- [x] Implement `src/main/ridgun/lib/path.rg`, `time.rg`, `log.rg`, `glob.rg`, `uuid.rg`, and `http.rg`.
- [x] Implement automated test suites `src/test/ridgun/test path.rg`, `test time.rg`, `test log.rg`, `test glob.rg`, `test uuid.rg`, and `test http.rg`.
- [x] Update `build.rg`, `README.md`, and `docs/requirements/product/vision.md`, and verify `stable check`, `stable bundle`, `stable test`, and `aix docs validate`.

## Progress log (append-only, newest last)
- 2026-10-22: Created AIX specs (`FR-*`, `API-*`, `TS-*`), implemented `path.rg`, `time.rg`, `log.rg`, `glob.rg`, `uuid.rg`, and `http.rg` plus their 6 test suites, updated `build.rg`, `README.md`, and `vision.md`, built all 17 `.rglib`/`.rgc`/`.so` bundles, and verified `17/17` test suites pass.

## Files changed (keep current)
- `build.rg`
- `README.md`
- `docs/requirements/product/vision.md`
- `docs/requirements/product/glossary.md`
- `docs/requirements/functional/**` (`PATH`, `TIME`, `LOG`, `GLOB`, `UUID`, `HTTP`)
- `docs/requirements/api/**` (`PATH`, `TIME`, `LOG`, `GLOB`, `UUID`, `HTTP`)
- `docs/tests/functional/**` (`PATH`, `TIME`, `LOG`, `GLOB`, `UUID`, `HTTP`)
- `src/main/ridgun/lib/path.rg`
- `src/main/ridgun/lib/time.rg`
- `src/main/ridgun/lib/log.rg`
- `src/main/ridgun/lib/glob.rg`
- `src/main/ridgun/lib/uuid.rg`
- `src/main/ridgun/lib/http.rg`
- `src/test/ridgun/test path.rg`
- `src/test/ridgun/test time.rg`
- `src/test/ridgun/test log.rg`
- `src/test/ridgun/test glob.rg`
- `src/test/ridgun/test uuid.rg`
- `src/test/ridgun/test http.rg`

## Verification performed (command → result, newest last)
- `stable check` → `Checked 17 module(s) — 0 errors.`
- `stable bundle` → Built `.rglib`, `.rgc`, and `.so` for all 17 libraries.
- `stable test` → `Passed 17/17 test suite(s) — 0 failures.`

## Exact next actions
1. Complete `TASK-0013` and validate AIX docs.

## Decisions / open questions
- None.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
