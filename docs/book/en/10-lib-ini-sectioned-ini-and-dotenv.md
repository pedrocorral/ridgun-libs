# Chapter 10: The `ini` Lib — Sectioned `.ini` Configs, `.env` Files, and Variable Interpolation

## 1. Why Does the `ini` Lib Exist?

Let's be honest: `.env` and `.ini` files look trivial until someone writes `export KEY="value # with hash"`, inline `;` comments, or cross-variable interpolation.

The **`ini`** lib parses sectioned `.ini` files (`[database]`) and `export`-prefixed `.env` files, preserving `#` and `;` inside quoted values and resolving variable interpolations in `dotenv parse`.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`ini`** is a first-class **lib** located at `src/main/ridgun/lib/ini.rg` (domain `INI`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/ini.rglib` | Portable distribution and direct `import ini` resolution |
| **Compiled Archive** | `target/ini.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libini.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import ini` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `ini`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `ini parse / ini stringify` | Parse sectioned `.ini` text into `IniDoc` and serialize back to canonical text |
| `ini get / ini get int / ini get bool / ini set` | Typed section+key lookups (`""` for global section) and immutable updates |
| `ini sections / ini section map` | List all section names or extract a section's `[String String]` map |
| `dotenv parse` | Parse `.env` lines (`export K=V`, quotes, comments, and variable expansion) |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `ini`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import ini

fn :: cargar base de datos (texto_ini : String) => (String, Int, Bool)
      cargar base de datos texto_ini =
        doc  = ini parse texto_ini
        host = ini get doc "database" "host" "localhost"
        port = ini get int doc "database" "port" 5432
        pool = ini get bool doc "database" "pool" True
        (host, port, pool)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `ini` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import ini

fn :: actualizar puerto (doc : IniDoc) (nuevo : String) => String
      actualizar puerto doc nuevo =
        doc2 = ini set doc "database" "port" nuevo
        ini stringify doc2
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Full preservation of `#` and `;` characters inside single or double quotes, and flexible boolean parsing (`true/1/yes/on` vs `false/0/no/off`).
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_ini.rg`.
