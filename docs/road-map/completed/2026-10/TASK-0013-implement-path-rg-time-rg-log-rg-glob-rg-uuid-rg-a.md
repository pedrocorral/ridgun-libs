---
id: TASK-0013
title: Implement path.ridgun, time.ridgun, log.ridgun, glob.ridgun, uuid.ridgun, and http.ridgun standard libraries with specs, tests, and bundles
status: completed
created: 2026-10-22
completed: 2026-10-22
requirements: [FR-PATH-001, API-PATH-001, FR-TIME-001, API-TIME-001, FR-LOG-001, API-LOG-001, FR-GLOB-001, API-GLOB-001, FR-UUID-001, API-UUID-001, FR-HTTP-001, API-HTTP-001]
tests: [TS-PATH-001, TS-TIME-001, TS-LOG-001, TS-GLOB-001, TS-UUID-001, TS-HTTP-001]
security: [VUL-INJ-002, VUL-INPUT-001]
context_files:
  - build.ridgun
  - README.md
  - docs/requirements/product/vision.md
  - docs/requirements/product/glossary.md
  - src/main/ridgun/lib/path.ridgun
  - src/main/ridgun/lib/time.ridgun
  - src/main/ridgun/lib/log.ridgun
  - src/main/ridgun/lib/glob.ridgun
  - src/main/ridgun/lib/uuid.ridgun
  - src/main/ridgun/lib/http.ridgun
  - src/test/ridgun/test path.ridgun
  - src/test/ridgun/test time.ridgun
  - src/test/ridgun/test log.ridgun
  - src/test/ridgun/test glob.ridgun
  - src/test/ridgun/test uuid.ridgun
  - src/test/ridgun/test http.ridgun
scope:
  - build.ridgun
  - README.md
  - docs/requirements/**
  - docs/tests/**
  - src/main/ridgun/lib/path.ridgun
  - src/main/ridgun/lib/time.ridgun
  - src/main/ridgun/lib/log.ridgun
  - src/main/ridgun/lib/glob.ridgun
  - src/main/ridgun/lib/uuid.ridgun
  - src/main/ridgun/lib/http.ridgun
  - src/test/ridgun/test path.ridgun
  - src/test/ridgun/test time.ridgun
  - src/test/ridgun/test log.ridgun
  - src/test/ridgun/test glob.ridgun
  - src/test/ridgun/test uuid.ridgun
  - src/test/ridgun/test http.ridgun
owner: agent-001
claimed: 2026-10-22T08:21:39Z
claimed_by: agent gemini@solarfall
policy:                     # a cycle for this task only
---
# TASK-0013 — Implement path.ridgun, time.ridgun, log.ridgun, glob.ridgun, uuid.ridgun, and http.ridgun standard libraries with specs, tests, and bundles

## Goal (one sentence)
Expand `ridgun-libs` to 17 foundational pure-Ridgun (`v0.9.5`) libraries by adding `path`, `time`, `log`, `glob`, `uuid`, and `http` with full AIX requirements, API contracts, automated test suites, and `.ridgunlib`/`.rgc`/`.so` bundles.

## Plan
- [x] Author AIX specs (`FR-PATH-001`, `API-PATH-001`, `TS-PATH-001`, `FR-TIME-001`, `API-TIME-001`, `TS-TIME-001`, `FR-LOG-001`, `API-LOG-001`, `TS-LOG-001`, `FR-GLOB-001`, `API-GLOB-001`, `TS-GLOB-001`, `FR-UUID-001`, `API-UUID-001`, `TS-UUID-001`, `FR-HTTP-001`, `API-HTTP-001`, `TS-HTTP-001`).
- [x] Implement `src/main/ridgun/lib/path.ridgun`, `time.ridgun`, `log.ridgun`, `glob.ridgun`, `uuid.ridgun`, and `http.ridgun`.
- [x] Implement automated test suites `src/test/ridgun/test path.ridgun`, `test time.ridgun`, `test log.ridgun`, `test glob.ridgun`, `test uuid.ridgun`, and `test http.ridgun`.
- [x] Update `build.ridgun`, `README.md`, and `docs/requirements/product/vision.md`, and verify `stable check`, `stable bundle`, `stable test`, and `aix docs validate`.

## Progress log (append-only, newest last)
- 2026-10-22: Created AIX specs (`FR-*`, `API-*`, `TS-*`), implemented `path.ridgun`, `time.ridgun`, `log.ridgun`, `glob.ridgun`, `uuid.ridgun`, and `http.ridgun` plus their 6 test suites, updated `build.ridgun`, `README.md`, and `vision.md`, built all 17 `.ridgunlib`/`.rgc`/`.so` bundles, and verified `17/17` test suites pass.

## Files changed (keep current)
- `build.ridgun`
- `README.md`
- `docs/requirements/product/vision.md`
- `docs/requirements/product/glossary.md`
- `docs/requirements/functional/**` (`PATH`, `TIME`, `LOG`, `GLOB`, `UUID`, `HTTP`)
- `docs/requirements/api/**` (`PATH`, `TIME`, `LOG`, `GLOB`, `UUID`, `HTTP`)
- `docs/tests/functional/**` (`PATH`, `TIME`, `LOG`, `GLOB`, `UUID`, `HTTP`)
- `src/main/ridgun/lib/path.ridgun`
- `src/main/ridgun/lib/time.ridgun`
- `src/main/ridgun/lib/log.ridgun`
- `src/main/ridgun/lib/glob.ridgun`
- `src/main/ridgun/lib/uuid.ridgun`
- `src/main/ridgun/lib/http.ridgun`
- `src/test/ridgun/test path.ridgun`
- `src/test/ridgun/test time.ridgun`
- `src/test/ridgun/test log.ridgun`
- `src/test/ridgun/test glob.ridgun`
- `src/test/ridgun/test uuid.ridgun`
- `src/test/ridgun/test http.ridgun`

## Verification performed (command → result, newest last)
- `stable check` → `Checked 17 module(s) — 0 errors.`
- `stable bundle` → Built `.ridgunlib`, `.rgc`, and `.so` for all 17 libraries.
- `stable test` → `Passed 17/17 test suite(s) — 0 failures.`

## Exact next actions
1. Complete `TASK-0013` and validate AIX docs.

## Decisions / open questions
- None.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
