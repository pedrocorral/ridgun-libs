# Chapter 05: The `tensor` Lib — Multi-Dimensional Tensors, Views, and Einstein Contraction

## 1. Why Does the `tensor` Lib Exist?

Let's be honest: in most languages you either suffer pointer-chasing nested lists or link a 200 MB C++/Fortran behemoth like NumPy or OpenBLAS.

The **`tensor`** lib wraps Ridgun's native `Tensor[...]` primitive with typed constructors (`Tensor[Int]`, `Tensor[Real]`, `Tensor[U64]`), zero-copy views (`reshape`, `slice`), Hadamard elementwise ops, Einstein summation contraction, and 64-bit `BlaMka` mixing.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`tensor`** is a first-class **lib** located at `src/main/ridgun/lib/tensor.rg` (domain `TENSOR`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/tensor.rglib` | Portable distribution and direct `import tensor` resolution |
| **Compiled Archive** | `target/tensor.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libtensor.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import tensor` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `tensor`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `tensor zeros int / tensor fill int / tensor zeros real` | Allocate contiguous 1D/2D `Tensor[Int]` and `Tensor[Real]` blocks |
| `tensor get 1d / tensor set 1d / tensor get 2d / tensor set 2d` | Functional Copy-on-Write (`with [i] = v`) element access and update |
| `tensor reshape 1d to 2d / tensor slice 1d` | Metadata-only descriptor views over shared tensor storage |
| `tensor add int / tensor mul int / tensor scale int` | Elementwise Hadamard addition, multiplication, and scalar scaling |
| `tensor dot int / tensor matmul int` | Einstein index contraction (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `u64 blamka g / u64 rotr` | 64-bit unsigned `U64` rotational mixing for cryptographic blocks |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `tensor`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import tensor

fn :: producto matricial tensor () => Tensor[Int]
      producto matricial tensor =
        a = tensor reshape 1d to 2d (tensor from list int [1, 2, 3, 4]) 2 2
        b = tensor reshape 1d to 2d (tensor from list int [5, 6, 7, 8]) 2 2
        tensor matmul int a b
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `tensor` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import tensor

fn :: energia vector (xs : [Int]) => (Int, Int)
      energia vector xs =
        v   = tensor from list int xs
        dot = tensor dot int v v
        mx  = tensor max int v
        (dot, mx)
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Contiguous 8-byte-aligned storage statically managed by RMM1/RMM2, $O(1)$ descriptor views without buffer duplication, and pure Copy-on-Write semantics.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_tensor.rg`.
