# Chapter 01: The `str` Lib — Text Manipulation, Search, and Tabular Padding

## 1. Why Does the `str` Lib Exist?

Let's be honest: manipulating strings in C with `strtok` and `strncpy` is a minefield of buffer overflows and null pointers, while in higher-level languages you often pull in external packages just to pad tabular output or repeat a delimiter in $O(\log N)$.

The **`str`** lib provides pure, immutable primitives for searching, trimming, splitting, joining, ASCII case conversion, $O(\log N)$ binary-doubling repetition, and column padding.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`str`** is a first-class **lib** located at `src/main/ridgun/lib/str.rg` (domain `STR`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/str.rglib` | Portable distribution and direct `import str` resolution |
| **Compiled Archive** | `target/str.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libstr.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import str` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `str`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `str index of : String -> String -> Int` | First index of needle in haystack (`-1` if absent / empty needle `0`) |
| `str contains / str starts with / str ends with` | `Bool` substring, prefix, and suffix predicates |
| `str trim / str trim left / str trim right` | Strip ASCII whitespace (` `, `\t`, `\n`, `\r`) |
| `str split / str lines / str words / str join` | Split into `[String]` and join lists with a separator |
| `str replace / str to upper / str to lower` | Non-overlapping replacement and ASCII case conversion |
| `str repeat / str pad left / str pad right` | $O(\log N)$ repetition and fixed-width column padding |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `str`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import str

fn :: normalizar cabecera (raw : String) => String
      normalizar cabecera raw =
        limpia = str to lower (str trim raw)
        partes = str words limpia
        slug   = str join partes "-"
        str pad right slug 24 "."
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `str` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import str

fn :: extraer dominio (correo : String) => String
      extraer dominio correo =
        pos = str index of correo "@"
        | pos < 0   = "sin-dominio"
        | otherwise =
          partes = str split correo "@"
          str replace (str to lower correo) "@" " en "
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: $O(\log N)$ repetition via binary string doubling, safe handling of empty needles, and zero in-place mutation.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_str.rg`.
