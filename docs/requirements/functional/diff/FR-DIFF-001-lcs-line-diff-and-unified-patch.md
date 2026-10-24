---
id: FR-DIFF-001
title: Provide Longest Common Subsequence line diff, Unified Diff formatting, and patch application
type: functional
status: implemented
priority: must
domain: DIFF
depends_on: []
related: [ADR-0002, DM-Diff, API-DIFF-001, VUL-INPUT-001]
tests: [TS-DIFF-001]
---
# FR-DIFF-001 — Provide Longest Common Subsequence line diff, Unified Diff formatting, and patch application

## Statement
The `diff` library SHALL provide Longest Common Subsequence (LCS) line comparison (`diff lines`, `diff text`, `diff edit distance`), Unified Diff rendering (`diff unified`), diff statistics (`diff stats`), and patch application (`diff apply`).

## Rationale
Test runners, code formatters, and version/configuration inspection tools need structured line-by-line diffs and standard Unified Diff output.

## Acceptance criteria
- AC1: Given original text `old_s` and modified text `new_s`, when `diff text old_s new_s` is called, then it returns a minimal `[DiffEdit]` sequence of `DiffEqual`, `DiffDelete`, and `DiffInsert` operations with accurate 1-based line numbers.
- AC2: Given `old_s`, `new_s`, and file labels, when `diff unified old_label new_label old_s new_s` is called, then it produces Unified Diff output with `---`, `+++`, `@@`, and ` `/`+`/`-` prefixed lines.
- AC3: Given `old_s` and the `[DiffEdit]` list from `diff text old_s new_s`, when `diff apply edits` is called, then it reconstructs `new_s` exactly.

## Actors & permissions
- Any Ridgun program or lib importing `diff`.

## Constraints & edge cases
- Identical inputs yield zero insertions/deletions (`diff has changes edits == False`).

## Data & privacy
- Pure in-memory LCS dynamic programming in `RMM1`/`RMM2` regions.

## Security & observability notes
- Mitigates `VUL-INPUT-001`.

## Out of scope
- Binary delta compression.
