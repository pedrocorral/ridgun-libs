---
id: API-CSV-001
title: Public lib contract for csv (csv.rglib / libcsv.so)
status: approved
implements: [FR-CSV-001]
auth: none
---
# API-CSV-001 — Public lib contract for `csv` (`csv.rg`)

## Request
- Imported via `import csv`.
- Public Types (see `DM-Csv`):
  - `type CsvTable = headers: [String], rows: [[String]], delimiter_char: String, has_headers: Bool`
- Parsing & Serialization:
  - `csv parse String => [[String]]`
  - `tsv parse String => [[String]]`
  - `csv parse with delim String String => [[String]]`
  - `csv parse table String Bool => CsvTable`
  - `csv stringify [[String]] => String`
  - `tsv stringify [[String]] => String`
  - `csv stringify with delim [[String]] String => String`
- Column & Header Lookup:
  - `csv col [[String]] Int => [String]`
  - `csv get by header CsvTable Int String => String`
  - `csv row to map [String] [String] => [(String, String)]`

## Responses
| Code | When | Body |
|---|---|---|
| `[[String]]` | `csv parse` / `tsv parse` | List of parsed rows and unescaped cell strings |
| `CsvTable` | `csv parse table` | Structured table with separated headers and data rows |
| `String` | `csv stringify` / `tsv stringify` | RFC 4180 formatted CSV/TSV text |

## Rules
- Cells containing the delimiter, `"`, `\r`, or `\n` are automatically quoted and escaped (`""`).
