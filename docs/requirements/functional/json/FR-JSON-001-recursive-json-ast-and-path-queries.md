---
id: FR-JSON-001
title: Provide recursive RFC 8259 JSON AST parsing, serialization, pretty-printing, and dot-path queries
type: functional
status: implemented
priority: must
domain: JSON
depends_on: []
related: [ADR-0002, ADR-0003, DM-Json, API-JSON-001, VUL-INPUT-001]
tests: [TS-JSON-001]
---
# FR-JSON-001 — Provide recursive RFC 8259 JSON AST parsing, serialization, pretty-printing, and dot-path queries

## Statement
The `json` library SHALL provide a recursive RFC 8259 JSON value ADT (`JsonVal = JsonNull | JsonBool Bool | JsonInt Int | JsonNum String | JsonStr String | JsonArr [JsonVal] | JsonObj [JsonField]`), parser (`json parse` with default depth/size limits and `json parse with limits`), compact serializer (`json stringify`), indented pretty-printer (`json pretty`), field existence/lookup helpers (`json find field`, `json has field`, `json num text`), and dot-path accessors (`json get path`, `json get str`, `json get int`, `json get float`, `json get bool`, `json set field`).

## Rationale
Complex configurations, REST/HTTP payloads, and structured messages require nested JSON objects and arrays beyond flat key extraction, with exact preservation of fractional/exponential numbers (`JsonNum`), strict RFC 8259 §7/§8.1 unicode escape and UTF-8 validation, explicit distinction between absent and `null` fields, duplicate-key rejection, and resource limits against denial-of-service inputs.

## Acceptance criteria
- AC1: Given valid JSON text containing nested objects, arrays, strings with standard and `\uXXXX` / UTF-16 surrogate pair escape sequences (`RG-076`), 64-bit integers (`JsonInt`), fractional or exponential numbers (`JsonNum` preserving exact lexeme text and convertible via `json num text` / `json get float`), booleans, and `null`, when `json parse` is called, then it returns `JsonOk val`, decodes `\uXXXX` and surrogate pairs to exact UTF-8 bytes, and `json stringify val` / `json pretty val indent` serialize it losslessly.
- AC2: Given a `JsonVal` tree and a field key or dot-separated path `"user.roles.1"`, when `json find field` (`None` when absent, `Some JsonNull` when `null`), `json has field`, `json get field`, `json get path`, `json get str`, `json get int`, `json get float`, or `json get bool` is called, then it traverses object keys and 0-based array indices and returns the matching node or typed default.
- AC3: Given malformed or adversarial JSON input — including invalid UTF-8 byte sequences in strings or keys (stray continuation/high bytes, overlong encodings such as `0xC0 0xAF`, UTF-8-encoded surrogates `0xED 0xA0..0xBF`, or codepoints above `U+10FFFF`, RFC 8259 §8.1), invalid/truncated `\uXXXX` escapes, lone UTF-16 surrogates (`0xD800..0xDFFF`, `RG-076`), duplicate keys in the same JSON object (`RG-077`), or inputs exceeding `max_depth` (default `64`) or `max_bytes` (default `1048576`, or custom limits via `json parse with limits`, `RG-078`) — when `json parse` or `json parse with limits` is called, then it returns `JsonErr reason` without crashing.

## Actors & permissions
- Any Ridgun program or lib importing `json`.

## Constraints & edge cases
- Rejects unclosed strings, trailing garbage, unbalanced brackets/braces, lone UTF-16 surrogates, duplicate object keys, and inputs exceeding nesting depth or byte length limits.

## Data & privacy
- Pure in-memory AST in `RMM1`/`RMM2` regions.

## Security & observability notes
- Mitigates `VUL-INPUT-001` by safely escaping control characters and quotes during serialization, rejecting ambiguous duplicate object keys (`RG-077`), and bounding recursion depth and input size (`RG-078`).

## Out of scope
- Streaming SAX parser over gigabyte files.
