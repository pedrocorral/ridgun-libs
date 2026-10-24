# Chapter 20: The `log` Lib — Structured NDJSON Logging and Automatic Secret Redaction

## 1. Why Does the `log` Lib Exist?

Let's be honest: dumping request fields into a log line and realizing weeks later that `password`, `api_key`, or `authorization` headers were stored in cleartext in your log aggregator is a classic security incident.

The **`log`** lib provides severity filtering (`DEBUG`, `INFO`, `WARN`, `ERROR`), human-readable text and **structured NDJSON** formatters, and **automatic secret redaction** (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key` $\rightarrow$ `"[REDACTED]"`, mitigating `VUL-LOG-001`).

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`log`** is a first-class **lib** located at `src/main/ridgun/lib/log.rg` (domain `LOG`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/log.rglib` | Portable distribution and direct `import log` resolution |
| **Compiled Archive** | `target/log.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/liblog.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import log` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `log`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `log level rank / log should emit` | Compare log levels (`DEBUG=10`, `INFO=20`, `WARN=30`, `ERROR=40`) against configured threshold |
| `log is sensitive key / log redact fields` | Case-insensitively replace secret values with `"[REDACTED]"` |
| `log format text / log format json` | Format single-line key=value text or RFC 8259 NDJSON with automatic secret redaction |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `log`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import log

fn :: auditar login (usuario : String) (clave : String) => String
      auditar login usuario clave =
        campos = [("user", usuario), ("password", clave), ("ip", "10.0.0.1")]
        log format json "INFO" "intento de acceso" campos
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `log` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import log

fn :: emitir si procede (umbral : String) (nivel : String) (msg : String) => String
      emitir si procede umbral nivel msg =
        | log should emit umbral nivel = log format text nivel msg [("service", "solstice")]
        | otherwise                    = ""
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Both `log format text` and `log format json` automatically pass fields through `log redact fields` prior to serialization, ensuring secrets never leak by accident.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_log.rg`.
