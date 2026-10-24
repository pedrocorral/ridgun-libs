---
id: API-GLOB-001
title: Public lib contract for glob (glob.rglib / libglob.so)
status: approved
implements: [FR-GLOB-001]
auth: none
---
# API-GLOB-001 — Public lib contract for `glob` (`glob.rg`)

## Request
- Imported via `import glob`.
- Functions:
  - `glob match String String => Bool`, `glob match ci String String => Bool`
  - `glob filter String [String] => [String]`, `glob any match [String] String => Bool`

## Responses
| Code | When | Body |
|---|---|---|
| `Bool` / `[String]` | Pattern evaluation completed | Match boolean or filtered list of matching strings |

## Rules
- Adjacent `*` wildcards are collapsed to prevent catastrophic backtracking.
