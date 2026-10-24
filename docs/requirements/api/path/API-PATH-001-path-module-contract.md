---
id: API-PATH-001
title: Public lib contract for path (path.rglib / libpath.so)
status: approved
implements: [FR-PATH-001]
auth: none
---
# API-PATH-001 — Public lib contract for `path` (`path.rg`)

## Request
- Imported via `import path`.
- Functions:
  - `path clean String => String`, `path join String String => String`, `path join list [String] => String`
  - `path dirname String => String`, `path basename String => String`, `path ext String => String`, `path stem String => String`, `path replace ext String String => String`
  - `path is abs String => Bool`, `path is rel String => Bool`, `path split String => (String, String)`
  - `path is safe subpath String String => Bool`

## Responses
| Code | When | Body |
|---|---|---|
| `String` / `Bool` / `(String, String)` | Path operation completed | Normalized path, component, or confinement boolean |

## Rules
- All functions are pure and deterministic across platforms.
