---
id: TASK-0027
title: Implement diff.ridgun (LCS line diff & Unified Diff) and template.ridgun (Mustache template engine) libraries
status: completed
priority: must
owner: agent-001
implements: [FR-DIFF-001, API-DIFF-001, DM-Diff, FR-TMPL-001, API-TMPL-001, DM-Template]
tests: [TS-DIFF-001, TS-TMPL-001]
mitigates: [VUL-INPUT-001]
depends_on: []
scope:
  - src/main/ridgun/lib/diff.ridgun
  - src/main/ridgun/lib/template.ridgun
  - src/test/ridgun/test diff.ridgun
  - src/test/ridgun/test template.ridgun
  - build.ridgun
context_files:
  - docs/requirements/functional/diff/FR-DIFF-001-lcs-line-diff-and-unified-patch.md
  - docs/requirements/functional/tmpl/FR-TMPL-001-safe-mustache-template-engine.md
claimed: 2026-10-23T21:26:13Z
claimed_by: agent gemini@solarfall
---
# TASK-0027 — Implement `diff.ridgun` (LCS line diff & Unified Diff) and `template.ridgun` (Mustache template engine) libraries

## Goal
Implement pure-Ridgun `diff.ridgun` and `template.ridgun`, their test suites (`test diff.ridgun`, `test template.ridgun`), update `README.md` with all 32 standard library modules, and build `.ridgunlib`/`.so` bundles.
