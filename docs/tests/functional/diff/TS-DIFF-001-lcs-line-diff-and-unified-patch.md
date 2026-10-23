---
id: TS-DIFF-001
title: Verify Longest Common Subsequence line diff, Unified Diff formatting, and patch application
level: unit
covers: [FR-DIFF-001, API-DIFF-001]
status: planned
automated_in: []
---
# TS-DIFF-001 — Verify Longest Common Subsequence line diff, Unified Diff formatting, and patch application

## Preconditions / fixtures
- Pure-Ridgun `diff` and `test` modules (`src/main/ridgun/lib/diff.rg`, `src/main/ridgun/lib/test.rg`).

## Steps / inputs
1. Compute `diff text old_s new_s`, `diff edit distance`, `diff has changes`, and `diff stats` on multi-line documents.
2. Render `diff unified "a/file.rg" "b/file.rg" old_s new_s` and verify `---`, `+++`, `@@`, and `+`/`-` lines.
3. Reconstruct `new_s` via `diff apply edits` and verify exact equality with `new_s`.

## Expected results (map to acceptance criteria)
- AC1 → `diff text` computes minimal LCS edit scripts and accurate line numbers.
- AC2 → `diff unified` formats valid Unified Diff headers and hunks.
- AC3 → `diff apply` reconstructs modified text losslessly.

## Not covered here (to avoid duplication)
- File I/O operations (`TS-IO-001`).
