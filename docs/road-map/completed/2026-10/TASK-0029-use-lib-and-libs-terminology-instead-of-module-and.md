---
id: TASK-0029
title: Use lib and libs terminology instead of module and modules across README and docs
status: completed
created: 2026-10-24
completed: 2026-10-24
requirements: []
tests: []
security: []
context_files:
  - README.md
  - docs/requirements/product/vision.md
scope:
  - README.md
  - docs/requirements/
  - src/main/ridgun/lib/
owner: agent-001
claimed: 2026-10-24T08:24:57Z
claimed_by: agent gemini@solarfall
---
# TASK-0029 — Use `lib` and `libs` terminology instead of `module` and `modules` across README and docs

## Goal (one sentence)
Standardise terminology across `README.md`, `docs/requirements/`, and `STATE.md` so each of the 32 elements of `ridgun-libs` is called a **lib** (reserving the word `module` for other purposes).
## Plan
- [x] Update `README.md` (`Lib` table header, descriptions, and `stable check` summary).
- [x] Update `docs/requirements/product/vision.md`, `docs/requirements/api/`, and `docs/requirements/functional/` to refer to `lib` / `libs` rather than `module` / `modules`.
- [x] Regenerate `docs/tests/coverage-matrix.md` and validate with `aix docs validate`.
## Progress log (append-only, newest last)
- 2026-10-24: Updated `README.md`, `docs/requirements/product/vision.md`, `docs/requirements/api/`, `docs/requirements/functional/`, and `STATE.md` to use `lib`/`libs`.
## Files changed (keep current)
- `README.md`
- `docs/requirements/product/vision.md`
- `docs/requirements/api/`
- `docs/requirements/functional/`
## Verification performed (command → result, newest last)
- `aix docs coverage --write && aix docs validate` → `0 errors, 0 warnings`
## Exact next actions
1. Mark `TASK-0029` done and commit.
## Decisions / open questions
- None.
## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
