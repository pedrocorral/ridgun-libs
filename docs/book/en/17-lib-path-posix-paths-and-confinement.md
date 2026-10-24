# Chapter 17: The `path` Lib — POSIX Normalization (`path clean`) and Path-Traversal Confinement

## 1. Why Does the `path` Lib Exist?

Let's be honest: joining file paths with `base + "/" + user_path` without lexical `..` resolution and boundary confinement is an open invitation for a `../../etc/passwd` path-traversal exploit.

The **`path`** lib implements POSIX lexical normalization (`path clean`), safe joining (`path join`), component extraction (`dirname`, `basename`, `stem`, `ext`, `replace ext`), and the **`path is safe subpath`** (`VUL-INJ-001`) directory-confinement guard.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`path`** is a first-class **lib** located at `src/main/ridgun/lib/path.rg` (domain `PATH`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/path.rglib` | Portable distribution and direct `import path` resolution |
| **Compiled Archive** | `target/path.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libpath.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import path` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `path`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `path clean / path join / path join list` | Collapse `//`, `.`, and `..` lexically and join path segments |
| `path dirname / path basename / path split` | Split a path into parent directory and final filename component |
| `path ext / path stem / path replace ext` | Extract or swap file extensions (correctly treating `.bashrc` as stem `.bashrc`, ext `""`) |
| `path is safe subpath : String -> String -> Bool` | Verify `rel` stays strictly inside `base_dir` and has no NUL bytes |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `path`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import path

fn :: resolver archivo estatico (raiz : String) (peticion : String) => (Bool, String)
      resolver archivo estatico raiz peticion =
        seguro = path is safe subpath raiz peticion
        ruta   = path join raiz peticion
        (seguro, ruta)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `path` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import path

fn :: cambiar salida a objeto (fuente : String) => (String, String, String)
      cambiar salida a objeto fuente =
        dir = path dirname fuente
        nom = path stem fuente
        obj = path replace ext (path clean fuente) ".rglib"
        (dir, nom, obj)
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: `path is safe subpath` rejects absolute paths, NUL bytes, and any `..` sequence that attempts to escape `base_dir` or bleed into a sibling prefix (`/srv/www-secret`).
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_path.rg`.
