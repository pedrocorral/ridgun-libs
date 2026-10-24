---
id: API-JSON-001
title: Public lib contract for json (json.rglib / libjson.so)
status: approved
implements: [FR-JSON-001]
auth: none
---
# API-JSON-001 — Public lib contract for `json` (`json.rg`)

## Request
- Imported via `import json`.
- Public Types (see `DM-Json`):
  - `type JsonVal = JsonNull | JsonBool Bool | JsonInt Int | JsonStr String | JsonArr [JsonVal] | JsonObj [JsonField]`
  - `type JsonRes = JsonOk JsonVal | JsonErr String`
- Parsing & Serialization:
  - `json parse String => JsonRes` (enforces default `max_depth = 64`, `max_bytes = 1048576`)
  - `json parse with limits String Int Int => JsonRes` (`s`, `max_depth`, `max_bytes`)
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
| `JsonOk JsonVal` | Valid RFC 8259 JSON input within depth/size limits and with unique object keys | Parsed `JsonVal` AST |
| `JsonErr String` | Malformed JSON syntax, lone surrogate, duplicate object key, or depth/size limit exceeded | Diagnostic error message |
| `String` | `json stringify` or `json pretty` | Compact or indented JSON text |

## Rules
- `json parse` and `json parse with limits` decode RFC 8259 §7 `\uXXXX` and UTF-16 surrogate pairs to UTF-8, reject lone surrogates (`RG-076`), reject duplicate object keys (`RG-077`), and enforce maximum nesting depth and input byte size (`RG-078`).
- `json get path` splits `dot_path` on `.` and traverses both `JsonObj` keys and `JsonArr` integer indices, returning `JsonNull` when not found.
