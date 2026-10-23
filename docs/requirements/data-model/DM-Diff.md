---
id: DM-Diff
title: Longest Common Subsequence line diff edit script and Unified Diff models
status: approved
related: [FR-DIFF-001, API-DIFF-001, ADR-0002]
---
# DM-Diff — Longest Common Subsequence line diff edit script and Unified Diff models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| diff_op | String | `equal`, `insert`, `delete` | Edit script operation kind (`DiffEdit` ADT) |
| old_line_no | Int | `>= 0` | 1-based line index in original text (`0` for insertions) |
| new_line_no | Int | `>= 0` | 1-based line index in modified text (`0` for deletions) |

## Relations
- Used by `diff.rg` (`DiffEdit`) to compute LCS line diffs, render Unified Diff text, and apply edit scripts to reconstruct target documents.

## Invariants
- Applying the edit script `diff apply old_text edits` reproduces `new_text` byte-for-byte.

## Lifecycle
- Computed and formatted in `RMM1`/`RMM2` memory.
