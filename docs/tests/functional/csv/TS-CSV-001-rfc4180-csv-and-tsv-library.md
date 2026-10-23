---
id: TS-CSV-001
title: Verify RFC 4180 CSV and TSV parsing, serialization, quoted-field escaping, and header-mapped lookup
level: unit
covers: [FR-CSV-001, API-CSV-001]
status: automated
automated_in: ["src/test/ridgun/test csv.rg"]
---
# TS-CSV-001 — Verify RFC 4180 CSV and TSV parsing, serialization, quoted-field escaping, and header-mapped lookup

## Preconditions / fixtures
- Pure-Ridgun `csv` and `test` modules (`src/main/ridgun/lib/csv.rg`, `src/main/ridgun/lib/test.rg`).

## Steps / inputs
1. Parse CSV and TSV text containing quoted commas, escaped quotes (`""`), and CRLF/LF newlines via `csv parse` and `tsv parse`.
2. Serialize row matrices via `csv stringify` and `tsv stringify` and verify round-trip equality.
3. Parse a headered `CsvTable` via `csv parse table` and verify `csv col`, `csv get by header`, and `csv row to map`.

## Expected results (map to acceptance criteria)
- AC1 → Quoted fields and escaped quotes parse into exact cell strings.
- AC2 → Serialized CSV/TSV round-trips through `csv parse` / `tsv parse`.
- AC3 → Header-based column and row map lookups return exact cell values.

## Not covered here (to avoid duplication)
- File I/O streaming (`TS-IO-001`).
