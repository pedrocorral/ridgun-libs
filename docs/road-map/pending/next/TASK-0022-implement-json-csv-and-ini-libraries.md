---
id: TASK-0022
title: Implement json.rg, csv.rg, and ini.rg structured data and configuration libraries
status: pending
priority: must
owner: unassigned
implements: [FR-JSON-001, API-JSON-001, DM-Json, FR-CSV-001, API-CSV-001, DM-Csv, FR-INI-001, API-INI-001, DM-Ini]
tests: [TS-JSON-001, TS-CSV-001, TS-INI-001]
mitigates: [VUL-INPUT-001]
depends_on: []
scope:
  - src/main/ridgun/lib/json.rg
  - src/main/ridgun/lib/csv.rg
  - src/main/ridgun/lib/ini.rg
  - src/test/ridgun/test json.rg
  - src/test/ridgun/test csv.rg
  - src/test/ridgun/test ini.rg
  - build.rg
context_files:
  - docs/requirements/functional/json/FR-JSON-001-recursive-json-ast-and-path-queries.md
  - docs/requirements/functional/csv/FR-CSV-001-rfc4180-csv-and-tsv-library.md
  - docs/requirements/functional/ini/FR-INI-001-ini-and-dotenv-configuration-library.md
---
# TASK-0022 — Implement `json.rg`, `csv.rg`, and `ini.rg` structured data and configuration libraries

## Goal
Implement pure-Ridgun `json.rg` (recursive RFC 8259 `JsonVal` AST parser, serializer, pretty-printer, dot-path queries), `csv.rg` (RFC 4180 CSV/TSV parser, serializer, header-mapped lookup), and `ini.rg` (`.ini` and `.env` parser, `${VAR}` interpolation, serializer), along with their test suites and `.rglib`/`.so` bundles.
