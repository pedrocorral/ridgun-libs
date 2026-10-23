---
id: TS-JSON-001
title: Verify recursive RFC 8259 JSON AST parsing, serialization, pretty-printing, and dot-path queries
level: unit
covers: [FR-JSON-001, API-JSON-001]
status: planned
automated_in: []
---
# TS-JSON-001 — Verify recursive RFC 8259 JSON AST parsing, serialization, pretty-printing, and dot-path queries

## Preconditions / fixtures
- Pure-Ridgun `json` and `test` modules (`src/main/ridgun/lib/json.rg`, `src/main/ridgun/lib/test.rg`).

## Steps / inputs
1. Parse nested JSON containing objects, arrays, escaped strings, integers, booleans, and `null`; verify `json parse`, `json stringify`, and `json pretty` round-trip accurately.
2. Query nested fields and array elements using `json get path`, `json get str`, `json get int`, `json get bool`, and update fields via `json set field`.
3. Pass invalid JSON inputs (unclosed string, trailing comma/brace mismatch); verify `JsonErr` is returned.

## Expected results (map to acceptance criteria)
- AC1 → Nested `JsonVal` trees parse and serialize losslessly.
- AC2 → Dot-path queries (`"user.roles.1"`) return exact values or defaults.
- AC3 → Malformed JSON returns `JsonErr` safely.

## Not covered here (to avoid duplication)
- Flat JSON helpers in `codec.rg` (`TS-CODEC-001`).
