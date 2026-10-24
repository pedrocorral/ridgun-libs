# Chapter 11: The `regex` Lib — Linear-Time $O(N \cdot M)$ Thompson NFA Regular Expression Engine

## 1. Why Does the `regex` Lib Exist?

Let's be honest: backtracking regex engines have caused famous global outages (at Cloudflare, StackOverflow, and countless APIs) the moment a pattern like `(a+)+b` meets thirty `a`s and explodes into $O(2^N)$ exponential time.

The **`regex`** lib compiles patterns (`.`, `*`, `+`, `?`, `|`, `()`, `[a-z]`, `[^...]`, `^`, `$`, `\d`, `\w`, `\s`) into a **Thompson Non-Deterministic Finite Automaton (NFA)** and steps the active state set in strict **$O(N \cdot M)$ linear time**, making **ReDoS attacks mathematically impossible**.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`regex`** is a first-class **lib** located at `src/main/ridgun/lib/regex.rg` (domain `REGEX`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/regex.rglib` | Portable distribution and direct `import regex` resolution |
| **Compiled Archive** | `target/regex.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libregex.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import regex` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `regex`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `regex match / regex is match` | Full-string match and unanchored substring search in $O(N \cdot M)$ |
| `regex find / regex find all` | Extract the first or all non-overlapping matching substrings |
| `regex replace / regex replace all` | Replace the first or all regex matches with a replacement string |
| `regex split / regex escape` | Split text by a regex delimiter and escape metacharacters |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `regex`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import regex

fn :: extraer codigos postales (texto : String) => [String]
      extraer codigos postales texto =
        regex find all "\\d+" texto
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `regex` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import regex

fn :: censurar telefonos (comentario : String) => (Bool, String)
      censurar telefonos comentario =
        tiene = regex is match "\\d+-\\d+" comentario
        limpio = regex replace all "\\d+-\\d+" comentario "[TELEFONO]"
        (tiene, limpio)
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Lockstep NFA state-set simulation with zero stack-overflow risk and guaranteed $O(N \cdot M)$ runtime even on pathological `(a+)+b` inputs.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_regex.rg`.
