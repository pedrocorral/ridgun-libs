# Chapter 12: The `glob` Lib — Wildcard Patterns (`*`, `?`, `[a-z]`) and List Filtering

## 1. Why Does the `glob` Lib Exist?

Let's be honest: firing up a full regular expression engine just to check whether a filename matches `*.rg` or `test_[0-9]*.rg` is overkill.

The **`glob`** lib implements shell wildcard matching (`*`, `?`, `[a-z]` ranges, negated `[!0-9]` / `[^a-z]` classes), case-insensitive matching (`glob match ci`), and batch list filtering.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`glob`** is a first-class **lib** located at `src/main/ridgun/lib/glob.rg` (domain `GLOB`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/glob.rglib` | Portable distribution and direct `import glob` resolution |
| **Compiled Archive** | `target/glob.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libglob.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import glob` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `glob`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `glob match / glob match ci` | Case-sensitive and ASCII case-insensitive glob pattern matching |
| `glob filter / glob any match` | Filter `[String]` to matching items or check if any pattern in a list matches |
| `glob has magic` | Detect whether a string contains wildcard metacharacters (`*`, `?`, `[`) |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `glob`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import glob

fn :: seleccionar fuentes ridgun (archivos : [String]) => [String]
      seleccionar fuentes ridgun archivos =
        glob filter "test_[a-z]*.rg" archivos
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `glob` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import glob

fn :: es ruta excluida (ruta : String) => Bool
      es ruta excluida ruta =
        glob any match ["*.tmp", "*.bak", "target/*"] ruta
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Automatic collapsing of consecutive stars (`***` $\rightarrow$ `*`) to eliminate redundant backtracking and safe handling of unclosed `[` brackets.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_glob.rg`.
