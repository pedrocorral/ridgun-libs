---
id: DM-Regex
title: Linear-time Thompson NFA regular expression and match span models
status: approved
related: [FR-REGEX-001, API-REGEX-001, ADR-0002]
---
# DM-Regex — Linear-time Thompson NFA regular expression and match span models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| pattern_str | String | Valid regular expression pattern | Compiled into a sequence of NFA state instructions |
| match_start | Int | `>= 0` | Inclusive 0-based start offset of a match |
| match_end | Int | `>= match_start` | Exclusive 0-based end offset of a match |

## Relations
- Used by `regex.rg` (`RegexMatch`) to execute $O(N \cdot M)$ regular expression matching, search, replacement, and splitting without catastrophic backtracking.

## Invariants
- Simulation tracks active state sets step-by-step per input character, bounding worst-case time complexity to $O(|pattern| \cdot |input|)$ and preventing ReDoS (`VUL-INPUT-001`).

## Lifecycle
- Executed in memory over input strings; `RegexMatch` records are reclaimed deterministically by `RMM1`/`RMM2`.
