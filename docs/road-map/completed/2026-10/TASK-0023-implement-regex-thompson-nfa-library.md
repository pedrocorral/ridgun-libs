---
id: TASK-0023
title: Implement regex.rg linear-time Thompson NFA regular expression engine
status: completed
priority: must
owner: agent-001
implements: [FR-REGEX-001, API-REGEX-001, DM-Regex]
tests: [TS-REGEX-001]
mitigates: [VUL-INPUT-001]
depends_on: []
scope:
  - src/main/ridgun/lib/regex.rg
  - src/test/ridgun/test regex.rg
  - build.rg
context_files:
  - docs/requirements/functional/regex/FR-REGEX-001-linear-time-regular-expression-engine.md
  - docs/requirements/api/regex/API-REGEX-001-regex-module-contract.md
claimed: 2026-10-23T20:23:31Z
claimed_by: agent gemini@solarfall
---
# TASK-0023 — Implement `regex.rg` linear-time Thompson NFA regular expression engine

## Goal
Implement pure-Ridgun `regex.rg` supporting `.`, `*`, `+`, `?`, `|`, `(...)`, `[a-z]`, `[^...]`, `\d`, `\w`, `\s`, `^`, `$` with `regex match`, `regex is match`, `regex find`, `regex find all`, `regex replace`, `regex replace all`, and `regex split`, plus `test regex.rg` and `.rglib`/`.so` bundles.
