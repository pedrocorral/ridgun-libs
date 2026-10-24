# Chapter 13: The `diff` Lib — LCS Line Diff, Edit Distance, Unified Diff, and Patching

## 1. Why Does the `diff` Lib Exist?

Let's be honest: when a test fails or a config file changes, a raw 200-line `"expected A, got B"` dump forces you to squint at the screen hunting for the exact line that changed.

The **`diff`** lib computes the **Longest Common Subsequence (LCS)** over a 2D `Tensor[Int]` DP table to produce minimal edit scripts (`DiffKeep`, `DiffAdd`, `DiffDel`), edit distance, **Unified Diff** output (`---`/`+++`/`@@`), and lossless patching (`diff apply`).

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`diff`** is a first-class **lib** located at `src/main/ridgun/lib/diff.rg` (domain `DIFF`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/diff.rglib` | Portable distribution and direct `import diff` resolution |
| **Compiled Archive** | `target/diff.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libdiff.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import diff` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `diff`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `type DiffOp` | `DiffKeep String | DiffDel String | DiffAdd String` |
| `diff lines / diff text` | Compute minimal LCS edit script between `[String]` lists or multiline strings |
| `diff edit distance / diff stats` | Minimal insertion+deletion distance and `(kept, added, deleted)` counts |
| `diff format / diff unified` | Render compact `+ / - /  ` lines or standard Unified Diff with headers |
| `diff apply / diff apply text` | Reconstruct the target document losslessly from an edit script |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `diff`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import diff

fn :: auditar cambio (antes : String) (despues : String) => (Int, String)
      auditar cambio antes despues =
        dist   = diff edit distance ( ["host=localhost", "port=8080"] ) ( ["host=0.0.0.0", "port=8080"] )
        parche = diff unified "config.old" "config.new" antes despues
        (dist, parche)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `diff` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import diff

fn :: verificar parche (orig : [String]) (nuevo : [String]) => [String]
      verificar parche orig nuevo =
        ops = diff lines orig nuevo
        diff apply ops
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Guaranteed mathematical identity $diff\_edit\_distance(a, b) == |a| + |b| - 2 \cdot LCS(a, b)$ and lossless reconstruction `diff apply (diff lines a b) == b`.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_diff.rg`.
