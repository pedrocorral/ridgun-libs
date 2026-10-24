---
id: FR-CSV-001
title: Provide RFC 4180 CSV and TSV parsing, serialization, quoted-field escaping, and header-mapped lookup
type: functional
status: implemented
priority: must
domain: CSV
depends_on: []
related: [ADR-0002, DM-Csv, API-CSV-001, VUL-INPUT-001]
tests: [TS-CSV-001]
---
# FR-CSV-001 — Provide RFC 4180 CSV and TSV parsing, serialization, quoted-field escaping, and header-mapped lookup

## Statement
The `csv` library SHALL provide RFC 4180 CSV and TSV parsing (`csv parse`, `tsv parse`, `csv parse table`), serialization (`csv stringify`, `tsv stringify`), column extraction (`csv col`), and header-mapped cell lookup (`csv get by header`, `csv row to map`).

## Rationale
Data import/export, reporting, and tabular benchmarks require RFC 4180 handling of embedded commas, quotes (`""`), and newlines.

## Acceptance criteria
- AC1: Given RFC 4180 CSV or TSV text with unquoted and double-quoted fields containing commas, tabs, and escaped double quotes (`""`), when `csv parse` or `tsv parse` is called, then it returns the exact `[[String]]` matrix of rows and cells.
- AC2: Given a `[[String]]` matrix of rows, when `csv stringify` or `tsv stringify` is called, then fields containing delimiters, quotes, or newlines are properly quoted and round-trip through `csv parse` / `tsv parse`.
- AC3: Given a table with a header row, when `csv get by header` or `csv row to map` is called, then it maps column names to row values accurately.

## Actors & permissions
- Any Ridgun program or lib importing `csv`.

## Constraints & edge cases
- Handles both `\n` and `\r\n` line endings and ignores trailing newline at EOF.

## Data & privacy
- Pure in-memory processing in `RMM1`/`RMM2` regions.

## Security & observability notes
- Mitigates `VUL-INPUT-001` via strict quote escaping.

## Out of scope
- Binary Excel `.xlsx` archives.
