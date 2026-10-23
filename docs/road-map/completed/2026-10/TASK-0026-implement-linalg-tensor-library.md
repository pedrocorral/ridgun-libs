---
id: TASK-0026
title: Implement linalg.rg typed Tensor linear algebra, norms, linear solver, and neural activations library
status: completed
priority: must
owner: agent-001
implements: [FR-LINALG-001, API-LINALG-001, DM-Linalg]
tests: [TS-LINALG-001]
mitigates: [VUL-INPUT-001]
depends_on: []
scope:
  - src/main/ridgun/lib/linalg.rg
  - src/test/ridgun/test linalg.rg
  - build.rg
context_files:
  - docs/requirements/functional/linalg/FR-LINALG-001-tensor-linear-algebra-and-activations.md
  - docs/requirements/api/linalg/API-LINALG-001-linalg-module-contract.md
claimed: 2026-10-23T20:37:54Z
claimed_by: agent gemini@solarfall
---
# TASK-0026 — Implement `linalg.rg` typed Tensor linear algebra, norms, linear solver, and neural activations library

## Goal
Implement pure-Ridgun `linalg.rg` over `Tensor[Real * r * c]` and `Tensor[Real * n]`, `test linalg.rg`, and `.rglib`/`.so` bundles.
