# Chapter 09: The `csv` Lib — RFC 4180 CSV/TSV State-Machine Parser and Header-Indexed Tables

## 1. Why Does the `csv` Lib Exist?

Let's be honest: everyone thinks parsing CSV is just `str split line ","`... until a quoted field shows up containing a comma, doubled quotes `""`, or an embedded `\r\n` newline right in the middle of a cell.

The **`csv`** lib implements a full **RFC 4180** state-machine parser for CSV and TSV, smart-quoting serializers, and the `CsvTable` ADT for header-indexed column and row lookups.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`csv`** is a first-class **lib** located at `src/main/ridgun/lib/csv.rg` (domain `CSV`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/csv.rglib` | Portable distribution and direct `import csv` resolution |
| **Compiled Archive** | `target/csv.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libcsv.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import csv` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `csv`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `csv parse / tsv parse / csv parse with` | Parse CSV/TSV text (including multiline quoted fields and `""` escapes) into `[[String]]` |
| `csv stringify / tsv stringify` | Serialize `[[String]]` quoting only cells that contain delimiters, quotes, or newlines |
| `csv parse table / csv get cell / csv col` | Header-indexed `CsvTable` lookup by `(row_idx, col_name)` or full column extraction |
| `csv row to kv / csv table to kv list` | Convert tabular rows into `[String String]` dictionaries keyed by header |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `csv`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import csv

fn :: extraer columna precios (raw_csv : String) => ([String], String)
      extraer columna precios raw_csv =
        tabla   = csv parse table raw_csv
        precios = csv col tabla "precio"
        primero = csv get cell tabla 0 "producto" "desconocido"
        (precios, primero)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `csv` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import csv

fn :: exportar informe () => String
      exportar informe =
        filas = [["id", "nota"], ["1", "Contiene, coma"], ["2", "Dijo "hola""]]
        csv stringify filas
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Exact handling of `\r\n` and `\n` both inside and outside quotes, and lossless round-trips on `csv parse (csv stringify rows)`.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_csv.rg`.
