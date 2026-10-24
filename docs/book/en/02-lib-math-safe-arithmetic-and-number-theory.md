# Chapter 02: The `math` Lib — Safe Division, Number Theory, and Statistics

## 1. Why Does the `math` Lib Exist?

Let's be honest: an unexpected division by zero in production or the `%` operator returning negative remainders in C or Java has crashed more services than anyone likes to admit.

The **`math`** lib provides total division primitives safe against `d == 0` (`div ceil`, `div floor`, `div euclid`, `mod euclid`), $O(\log E)$ modular exponentiation and inverse, integer roots/logs, combinatorics, primality testing, and the `clamp x between lo and hi` mixfix operator.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`math`** is a first-class **lib** located at `src/main/ridgun/lib/math.rg` (domain `MATH`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/math.rglib` | Portable distribution and direct `import math` resolution |
| **Compiled Archive** | `target/math.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libmath.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import math` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `math`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `math abs / math sign / math min / math max` | Magnitude, sign (`-1, 0, 1`), and extrema |
| `clamp x between lo and hi` | Mixfix operator (`op ::`) clamping `x` into `[lo, hi]` |
| `math div ceil / math div floor / math div euclid / math mod euclid` | Division-by-zero-safe rounding and non-negative Euclidean remainder |
| `math pow / math isqrt / math ilog2 / math ilog10` | $O(\log E)$ power, Newton integer square root, and integer logarithms |
| `math gcd / math lcm / math mod pow / math mod inv / math is prime` | Euclidean GCD/LCM, modular arithmetic, and $6k \pm 1$ primality |
| `math sum / math mean floor / math median floor / math variance floor` | Overflow-safe combinatorics (`nCr`) and integer list statistics |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `math`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import math

fn :: verificar clave modular (base : Int) (primo : Int) => (Int, Int, Bool)
      verificar clave modular base primo =
        es_p = math is prime primo
        pot  = math mod pow base (primo - 1) primo
        inv  = math mod inv base primo
        (pot, inv, es_p)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `math` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import math

fn :: calcular paginas y cuota (items : Int) (por_pag : Int) (uso : Int) => (Int, Int)
      calcular paginas y cuota items por_pag uso =
        pags  = math div ceil items por_pag
        cuota = clamp uso between 0 and 100
        (pags, cuota)
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Total arithmetic functions (returning `0` on `<= 0` divisors instead of raising `SIGFPE`), free of floating-point rounding drift.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_math.rg`.
