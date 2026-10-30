---
id: TASK-0038
title: Add JsonNum decimal/exponent support, UTF-8 validation, json find field, and parser speedups in json
status: completed
created: 2026-10-30
completed: 2026-10-30
requirements: [FR-JSON-001, API-JSON-001, DM-Json]
tests: [TS-JSON-001]
security: [VUL-INPUT-001]
context_files:
  - src/main/ridgun/lib/json.rg
  - src/test/ridgun/test json.rg
  - docs/requirements/functional/json/FR-JSON-001-recursive-json-ast-and-path-queries.md
  - docs/requirements/api/json/API-JSON-001-json-module-contract.md
  - docs/requirements/data-model/DM-Json.md
  - docs/tests/functional/json/TS-JSON-001-recursive-json-ast-and-path-queries.md
scope:
  - src/main/ridgun/lib/json.rg
  - src/test/ridgun/test json.rg
  - docs/requirements/functional/json/FR-JSON-001-recursive-json-ast-and-path-queries.md
  - docs/requirements/api/json/API-JSON-001-json-module-contract.md
  - docs/requirements/data-model/DM-Json.md
  - docs/tests/functional/json/TS-JSON-001-recursive-json-ast-and-path-queries.md
owner: agent-001
claimed: 2026-10-30T12:20:37Z
claimed_by: agent gemini@solarfall
---
# TASK-0038 — Add JsonNum decimal/exponent support, UTF-8 validation, json find field, and parser speedups in json

## Goal (one sentence)
Preserve fractional and exponential JSON numbers via `JsonNum String` (`json num text`, `json get float`), reject invalid UTF-8 sequences in strings and keys per RFC 8259 §8.1, add `json find field` (`Option JsonVal`) and `json has field` to distinguish missing keys from `null`, and optimize `json parse` throughput.

## Plan
- [x] Update `FR-JSON-001`, `API-JSON-001`, `DM-Json`, and `TS-JSON-001`.
- [x] Implement `JsonNum String`, `json num text`, `json get float`, RFC 3629 UTF-8 validation in strings/keys, `json find field` (`Option JsonVal`), `json has field`, and parser fast paths in `src/main/ridgun/lib/json.rg`.
- [x] Add unit tests in `src/test/ridgun/test json.rg` and verify the Solstice repro in `/tmp/ridgun-lib/requirements/2026-10-30-json-repro/`.
- [x] Rebuild `json.rglib`, `json.rgc`, `libjson.so`, and sync `/home/gemini/.local/lib/ridgun/json.rglib`.

## Progress log (append-only, newest last)
- 2026-10-30: Created and started TASK-0038.
- 2026-10-30: Updated `FR-JSON-001`, `API-JSON-001`, `DM-Json`, and `TS-JSON-001`.
- 2026-10-30: Implemented `JsonNum String`, `json num text`, `json get float`, strict RFC 3629 UTF-8 validation in strings and keys, `json find field` (`Option JsonVal`), `json has field`, and $O(1)$ prepend + reverse list accumulators and unescaped ASCII string fast-paths in `src/main/ridgun/lib/json.rg`.
- 2026-10-30: Added unit tests in `src/test/ridgun/test json.rg`, synced `target/bundles/json.rglib`, `target/json.rgc`, `build/json.rglib`, `target/libjson.so`, and `/home/gemini/.local/lib/ridgun/json.rglib`, and verified all Solstice repro vectors and 100k-object benchmark (766 ms vs 1,836 ms).

## Files changed (keep current)
- `src/main/ridgun/lib/json.rg`
- `src/test/ridgun/test json.rg`
- `docs/requirements/functional/json/FR-JSON-001-recursive-json-ast-and-path-queries.md`
- `docs/requirements/api/json/API-JSON-001-json-module-contract.md`
- `docs/requirements/data-model/DM-Json.md`
- `docs/tests/functional/json/TS-JSON-001-recursive-json-ast-and-path-queries.md`
- `target/bundles/json.rglib`
- `target/json.rgc`
- `build/json.rglib`
- `target/libjson.so`

## Verification performed (command → result, newest last)
- `ridgunc run --strict "src/test/ridgun/test json.rg"` → `[PASS] test json: TS-JSON-001 (including RG-076, RG-077, RG-078) passed`
- `ridgunc run "src/test/ridgun/test jwt.rg"` → `[PASS] test jwt: TS-JWT-001 passed`
- Solstice repro (`2026-10-30-json-repro`) → `1.5 OK 1.5`, `-1.5 OK -1.5`, `1e3 OK 1e3`, `price 19.99 OK {"price":19.99}`, `raw 0xFF ERR invalid UTF-8 byte sequence in JSON string`, `overlong ERR invalid UTF-8 byte sequence in JSON string`
- 100,000 small objects benchmark (900 KB) → `OK count=100000` in `766 ms` (down from `1,836 ms`)
- `aix docs coverage && aix docs validate` → `0 errors, 0 warnings`

## Exact next actions
1. Mark `TASK-0038` as done and release agent seat.

## Decisions / open questions
- None.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
