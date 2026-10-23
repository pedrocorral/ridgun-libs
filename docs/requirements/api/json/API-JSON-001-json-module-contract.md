---
id: API-JSON-001
title: Public module contract for json (json.rglib / libjson.so)
status: approved
implements: [FR-JSON-001]
auth: none
---
# API-JSON-001 — Public module contract for `json` (`json.rg`)

## Request
- Imported via `import json`.
- Public Types (see `DM-Json`):
  - `type JsonVal = JsonNull | JsonBool Bool | JsonInt Int | JsonStr String | JsonArr [JsonVal] | JsonObj [(String, JsonVal)]`
  - `type JsonRes = JsonOk JsonVal | JsonErr String`
- Parsing & Serialization:
  - `json parse String => JsonRes`
  - `json stringify JsonVal => String`
  - `json pretty JsonVal Int => String`
- Queries & Mutation:
  - `json get field JsonVal String => JsonVal`
  - `json get index JsonVal Int => JsonVal`
  - `json get path JsonVal String => JsonVal`
  - `json get str JsonVal String String => String`
  - `json get int JsonVal String Int => Int`
  - `json get bool JsonVal String Bool => Bool`
  - `json set field JsonVal String JsonVal => JsonVal`

## Responses
| Code | When | Body |
|---|---|---|
| `JsonOk JsonVal` | Valid RFC 8259 JSON input | Parsed `JsonVal` AST |
| `JsonErr String` | Malformed JSON syntax | Diagnostic error message |
| `String` | `json stringify` or `json pretty` | Compact or indented JSON text |

## Rules
- `json get path` splits `dot_path` on `.` and traverses both `JsonObj` keys and `JsonArr` integer indices, returning `JsonNull` when not found.
