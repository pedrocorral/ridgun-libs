---
id: DM-Json
title: Recursive JSON AST value and dot-path query models
status: approved
related: [FR-JSON-001, API-JSON-001, ADR-0002]
---
# DM-Json — Recursive JSON AST value and dot-path query models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| json_kind | String | `null`, `bool`, `int`, `str`, `arr`, `obj` | Variant tag of a parsed `JsonVal` node |
| dot_path | String | Non-empty dot-separated path (`a.b.0`) | Path expression for nested lookup and update |

## Relations
- Used by `json.rg` (`JsonVal`, `JsonRes`) for parsing, serializing, pretty-printing, and querying RFC 8259 JSON documents.

## Invariants
- `JsonStr` values decode and encode standard RFC 8259 escape sequences (`\"`, `\\`, `\/`, `\b`, `\f`, `\n`, `\r`, `\t`).
- `JsonObj` preserves key-value insertion order and returns deterministic serialization.

## Lifecycle
- Constructed via `json parse` or `Json*` constructors, queried/updated purely in `RMM1`/`RMM2` memory, and serialized via `json stringify` or `json pretty`.
