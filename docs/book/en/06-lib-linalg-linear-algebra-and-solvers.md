# Chapter 06: The `linalg` Lib — `Tensor[Real]` Linear Algebra, Bareiss Solver, and Activations

## 1. Why Does the `linalg` Lib Exist?

Let's be honest: when you need cosine similarity for embeddings, an exact $A x = b$ linear solver, or a numerically stable `softmax` layer inside a lightweight service, you shouldn't have to ship 400 MB of PyTorch or LAPACK.

The **`linalg`** lib builds numerical linear algebra directly on native `Tensor[Real]`: transpose, trace, identity, inner/outer products, Einstein-contracted `matvec` and `matmul`, norms ($L_1, L_2, L_\infty$, Frobenius), partial-pivoting **Bareiss/Gaussian** determinant and $A x = b$ solver, plus neural activations (`relu`, `sigmoid`, `softmax`).

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`linalg`** is a first-class **lib** located at `src/main/ridgun/lib/linalg.rg` (domain `LINALG`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/linalg.rglib` | Portable distribution and direct `import linalg` resolution |
| **Compiled Archive** | `target/linalg.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/liblinalg.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import linalg` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `linalg`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `linalg vec from list / linalg mat from lists` | Construct 1D and 2D `Tensor[Real]` from Ridgun lists |
| `linalg transpose / linalg trace / linalg diag / linalg identity` | Structural matrix transforms and identity constructors |
| `linalg dot / linalg outer / linalg matvec / linalg matmul` | Einstein contraction (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `linalg norm l1 / linalg norm l2 / linalg cosine similarity` | Vector/matrix norms, normalization, and cosine similarity |
| `linalg det / linalg solve` | Exact division-free Bareiss determinant and partial-pivoting $A x = b$ solver (`Option[Tensor[Real]]`) |
| `linalg relu / linalg sigmoid / linalg softmax` | Max-shifted numerically stable neural layer activations |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `linalg`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import linalg

fn :: resolver sistema lineal () => Option[Tensor[Real]]
      resolver sistema lineal =
        -- Resuelve 2x + y = 5, x + 3y = 10 -> x = 1.0, y = 3.0
        a = linalg mat from lists [[2.0, 1.0], [1.0, 3.0]]
        b = linalg vec from list [5.0, 10.0]
        linalg solve a b
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `linalg` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import linalg

fn :: puntuar embeddings () => (Real, Tensor[Real])
      puntuar embeddings =
        q     = linalg vec from list [1.0, 2.0, 3.0]
        d     = linalg vec from list [1.0, 2.0, 3.0]
        sim   = linalg cosine similarity q d
        probs = linalg softmax q
        (sim, probs)
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Singular matrices cleanly return `None` in `linalg solve` (no silent `NaN` propagation), and `linalg softmax` shifts by the maximum logit before exponentiating to prevent overflow.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_linalg.rg`.
