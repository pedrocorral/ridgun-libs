---
id: TASK-0027
title: Implement diff.rg (LCS line diff & Unified Diff) and template.rg (Mustache template engine) libraries
status: pending
priority: must
owner: unassigned
implements: [FR-DIFF-001, API-DIFF-001, DM-Diff, FR-TMPL-001, API-TMPL-001, DM-Template]
tests: [TS-DIFF-001, TS-TMPL-001]
mitigates: [VUL-INPUT-001]
depends_on: []
scope:
  - src/main/ridgun/lib/diff.rg
  - src/main/ridgun/lib/template.rg
  - src/test/ridgun/test diff.rg
  - src/test/ridgun/test template.rg
  - build.rg
context_files:
  - docs/requirements/functional/diff/FR-DIFF-001-lcs-line-diff-and-unified-patch.md
  - docs/requirements/functional/tmpl/FR-TMPL-001-safe-mustache-template-engine.md
---
# TASK-0027 — Implement `diff.rg` (LCS line diff & Unified Diff) and `template.rg` (Mustache template engine) libraries

## Goal
Implement pure-Ridgun `diff.rg` and `template.rg`, their test suites (`test diff.rg`, `test template.rg`), update `README.md` with all 32 standard library modules, and build `.rglib`/`.so` bundles.
