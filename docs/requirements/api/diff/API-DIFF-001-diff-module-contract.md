---
id: API-DIFF-001
title: Public module contract for diff (diff.rglib / libdiff.so)
status: implemented
implements: [FR-DIFF-001]
auth: none
---
# API-DIFF-001 — Public module contract for `diff` (`diff.rg`)

## Request
- Imported via `import diff`.
- Public Types (see `DM-Diff`):
  - `type DiffEdit = diff_op: String, line_text: String, old_line_no: Int, new_line_no: Int`
  - `type DiffStats = equal_count: Int, insert_count: Int, delete_count: Int`
- Line Diff, Unified Diff & Patching:
  - `diff lines [String] [String] => [DiffEdit]`
  - `diff text String String => [DiffEdit]`
  - `diff edit distance String String => Int`
  - `diff has changes [DiffEdit] => Bool`
  - `diff stats [DiffEdit] => DiffStats`
  - `diff unified String String String String => String`
  - `diff apply [DiffEdit] => String`

## Responses
| Code | When | Body |
|---|---|---|
| `[DiffEdit]` | `diff lines` / `diff text` | Minimal LCS edit script |
| `String` | `diff unified` / `diff apply` | Unified Diff text or reconstructed target document |
| `DiffStats` | `diff stats` | Counts of unchanged, inserted, and deleted lines |

## Rules
- `diff_op` is `"equal"`, `"insert"`, or `"delete"`.
