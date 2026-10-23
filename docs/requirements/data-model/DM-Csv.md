---
id: DM-Csv
title: RFC 4180 CSV and TSV tabular document models
status: approved
related: [FR-CSV-001, API-CSV-001, ADR-0002]
---
# DM-Csv — RFC 4180 CSV and TSV tabular document models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| delimiter_char | String | Single ASCII character (`,` or `\t`) | Field separator character |
| has_headers | Bool | `True` or `False` | Whether row 0 is treated as column header names |

## Relations
- Used by `csv.rg` (`CsvTable`) to parse, query, and serialize RFC 4180 CSV and TSV tables.

## Invariants
- Fields containing `delimiter_char`, `"`, `\r`, or `\n` are enclosed in double quotes `"` with internal quotes doubled (`""`).

## Lifecycle
- Parsed from raw text via `csv parse` / `tsv parse` or constructed from rows and serialized via `csv stringify` / `tsv stringify`.
