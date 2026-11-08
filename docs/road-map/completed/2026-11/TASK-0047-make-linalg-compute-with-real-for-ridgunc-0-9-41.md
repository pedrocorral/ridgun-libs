---
id: TASK-0047
title: Make linalg compute with Real for ridgunc 0.9.41
status: completed
created: 2026-11-07
completed: 2026-11-07
requirements: [FR-LINALG-001, FR-TENSOR-001, API-LINALG-001, DM-Linalg]  # FR-*/NFR-* this task delivers or touches
tests: [TS-LINALG-001, TS-TENSOR-001]  # TS-* to automate
security: []                # VUL-* to address
context_files: [docs/requirements/decisions/ADR-0008-linalg-computes-with-real.md, src/main/ridgun/lib/linalg.rg, src/main/ridgun/lib/tensor.rg]  # THE ONLY files an agent must read to work on this task
scope: [src/main/ridgun/lib/linalg.rg, src/main/ridgun/lib/tensor.rg, "src/test/ridgun/test linalg.rg", "src/test/ridgun/test tensor.rg", docs/requirements]  # paths/globs this task will change (aix task start warns when two going-on tasks overlap)
owner: agent-001
claimed: 2026-11-07T21:59:26Z
claimed_by: claude claude@solarfall
policy:                     # a cycle for this task only (hotfix, release, ...); empty = the project's (aix policy)
---
# TASK-0047 — Make linalg compute with Real for ridgunc 0.9.41

## Goal (one sentence)
`linalg` and `test tensor.rg` compile and pass with ridgunc 0.9.41, with real-valued linear algebra instead of integers stored in `Real` tensors (ADR-0008).
## Plan
- [x] ADR-0008: linalg computes with Real (user decision 2026-11-07)
- [x] Rewrite linalg.rg with Real scalars, `linalg sqrt` (Newton) and `linalg exp` (range reduction + Taylor), Gaussian elimination with partial pivoting for det and solve
- [x] `tensor matmul` with explicit loops (`@` on Real returns zeros in 0.9.41); `linalg matmul` calls it
- [x] Rewrite test linalg.rg (relative tolerance 1e-12) and the matmul test in test tensor.rg
- [x] Update FR-LINALG-001, API-LINALG-001, DM-Linalg, TS-LINALG-001, FR-TENSOR-001 AC3
- [x] Report the `@` fault to the compiler team (/tmp/ridgun-compiler/2026-11-07/tensor-from-list-longitud.md)
## Progress log (append-only, newest last)
- 2026-11-07: With 0.9.41, test linalg and test tensor did not build (Int stored in Real tensors, 51 errors in linalg). User chose real Real math. Rewrote linalg and the tests; both suites pass.
## Files changed (keep current)
- src/main/ridgun/lib/linalg.rg, src/main/ridgun/lib/tensor.rg
- src/test/ridgun/test linalg.rg, src/test/ridgun/test tensor.rg
- docs/requirements/decisions/ADR-0008-linalg-computes-with-real.md, decisions/INDEX.md
- FR-LINALG-001, API-LINALG-001, DM-Linalg, TS-LINALG-001, FR-TENSOR-001
## Verification performed (command → result, newest last)
- ridgunc check --strict linalg.rg / tensor.rg → 0 errors
- test linalg.rg → [PASS] TS-LINALG-001; test tensor.rg → [PASS] TS-TENSOR-001
- all 34 suites with ridgunc 0.9.41 → rc=0; strict check of 36 libs → 0 errors; aix docs validate → 0 errors; coverage matrix regenerated
## Exact next actions
1. Return `linalg matmul` / `tensor matmul` to `a_ik @ b_kj` once the compiler fixes `@` on Real.
## Decisions / open questions
- ADR-0008. arm64 has no Real in 0.9.41: linalg is x86_64-only until then.
## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
