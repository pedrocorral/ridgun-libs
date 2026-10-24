---
id: FR-JSON-001
title: Provide recursive RFC 8259 JSON AST parsing, serialization, pretty-printing, and dot-path queries
type: functional
status: implemented
priority: must
domain: JSON
depends_on: []
related: [ADR-0002, DM-Json, API-JSON-001, VUL-INPUT-001]
tests: [TS-JSON-001]
---
# FR-JSON-001 — Provide recursive RFC 8259 JSON AST parsing, serialization, pretty-printing, and dot-path queries

## Statement
The `json` library SHALL provide a recursive RFC 8259 JSON value ADT (`JsonVal = JsonNull | JsonBool Bool | JsonInt Int | JsonStr String | JsonArr [JsonVal] | JsonObj [(String, JsonVal)]`), parser (`json parse`), compact serializer (`json stringify`), indented pretty-printer (`json pretty`), and dot-path accessors (`json get path`, `json get str`, `json get int`, `json get bool`, `json set field`).

## Rationale
Complex configurations, REST/HTTP payloads, and structured messages require nested JSON objects and arrays beyond flat key extraction.

## Acceptance criteria
- AC1: Given valid JSON text containing nested objects, arrays, strings with escape sequences, integers, booleans, and `null`, when `json parse` is called, then it returns `JsonOk val` and `json stringify val` / `json pretty val indent` serialize it losslessly.
- AC2: Given a `JsonVal` tree and a dot-separated path `"user.roles.1"`, when `json get path`, `json get str`, `json get int`, or `json get bool` is called, then it traverses object keys and 0-based array indices and returns the matching node or typed default.
- AC3: Given malformed JSON input, when `json parse` is called, then it returns `JsonErr reason` without crashing.

## Actors & permissions
- Any Ridgun program or lib importing `json`.

## Constraints & edge cases
- Rejects unclosed strings, trailing garbage, and unbalanced brackets/braces.

## Data & privacy
- Pure in-memory AST in `RMM1`/`RMM2` regions.

## Security & observability notes
- Mitigates `VUL-INPUT-001` by safely escaping control characters and quotes during serialization.

## Out of scope
- Streaming SAX parser over gigabyte files.
