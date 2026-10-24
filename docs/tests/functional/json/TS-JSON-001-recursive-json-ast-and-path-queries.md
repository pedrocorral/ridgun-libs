---
id: TS-JSON-001
title: Verify recursive RFC 8259 JSON AST parsing, serialization, pretty-printing, and dot-path queries
level: unit
covers: [FR-JSON-001, API-JSON-001]
status: automated
automated_in: ["src/test/ridgun/test json.rg"]
---
# TS-JSON-001 — Verify recursive RFC 8259 JSON AST parsing, serialization, pretty-printing, and dot-path queries

## Preconditions / fixtures
- Pure-Ridgun `json` and `test` modules (`src/main/ridgun/lib/json.rg`, `src/main/ridgun/lib/test.rg`).

## Steps / inputs
1. Parse nested JSON containing objects, arrays, escaped strings (including RFC 8259 §7 `\uXXXX` BMP escapes such as `\u00e9` -> `é` and UTF-16 surrogate pairs such as `\uD83D\uDE00` -> `😀`, `RG-076`), integers, booleans, and `null`; verify `json parse`, `json stringify`, and `json pretty` round-trip accurately.
2. Query nested fields and array elements using `json get path`, `json get str`, `json get int`, `json get bool`, and update fields via `json set field`.
3. Pass invalid or adversarial JSON inputs: unclosed string, trailing comma/brace mismatch, invalid/truncated `\uXXXX` escapes, lone high or low UTF-16 surrogates (`\uD800`, `\uDC00`, `\uD83D\u0041`, `RG-076`), duplicate object keys (`{"title":"a","title":"b"}` and duplicate keys after `\uXXXX` unescaping, `RG-077`), and inputs exceeding nesting depth (`> 64` default or custom `json parse with limits`) or input byte size (`RG-078`); verify `JsonErr` is returned in all cases.

## Expected results (map to acceptance criteria)
- AC1 → Nested `JsonVal` trees and `\uXXXX` / surrogate-pair escapes parse to exact UTF-8 and serialize losslessly.
- AC2 → Dot-path queries (`"user.roles.1"`) return exact values or defaults.
- AC3 → Malformed JSON, lone surrogates (`RG-076`), duplicate object keys (`RG-077`), and over-depth/over-size inputs (`RG-078`) return `JsonErr` safely.

## Not covered here (to avoid duplication)
- Flat JSON helpers in `codec.rg` (`TS-CODEC-001`).
