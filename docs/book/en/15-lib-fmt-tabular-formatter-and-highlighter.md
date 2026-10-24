# Chapter 15: The `fmt` Lib — Canonical 2D Tabular Formatter and 9-Target Syntax Highlighter

## 1. Why Does the `fmt` Lib Exist?

Let's be honest: the beauty of Ridgun lies in its crisp tabular columns (`::`, `=`, `|`, `->`, `--`), but aligning spaces by hand or exporting syntax-highlighted code to ANSI terminals, HTML, and LaTeX without a dedicated engine is tedious.

The **`fmt`** lib is Ridgun's official 2D tabular formatter and lexical syntax highlighter: it aligns `fn ::` headers, equations, `|` guards, and `--` comments, and renders into **9 output targets** (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`).

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`fmt`** is a first-class **lib** located at `src/main/ridgun/lib/fmt.rg` (domain `FMT`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/fmt.rglib` | Portable distribution and direct `import fmt` resolution |
| **Compiled Archive** | `target/fmt.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libfmt.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import fmt` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `fmt`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `fmt source / fmt source with` | Format raw Ridgun source code using canonical 2D tabular column alignment |
| `fmt check` | Return `True` if source code already matches canonical `fmt source` layout |
| `fmt render / fmt render with` | Format and highlight source into any of the 9 `FmtTarget` backends |
| `fmt tokenize line` | Tokenize a Ridgun line into `TokKeyword`, `TokType`, `TokOperator`, `TokString`, `TokNumber`, `TokComment` |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `fmt`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import fmt

fn :: formatear y verificar (codigo : String) => (String, Bool)
      formatear y verificar codigo =
        limpio = fmt source codigo
        es_ok  = fmt check limpio
        (limpio, es_ok)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `fmt` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import fmt

fn :: exportar bloque html (codigo : String) => String
      exportar bloque html codigo =
        fmt render codigo FmtHtmlCss
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Strict idempotence (`fmt source (fmt source s) == fmt source s`) and 100% preservation of semantic tokens.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_fmt.rg`.
