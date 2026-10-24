# Chapter 21: The `test` Lib — Unit and Functional Test Assertion Primitives (`RG-011`)

## 1. Why Does the `test` Lib Exist?

Let's be honest: when a testing framework demands compiler-magic macros, runtime reflection, or a bloated external runner, writing tests stops feeling immediate.

The **`test`** lib (`RG-011`) provides polymorphic and type-specific assertions that emit clear `[FAIL]` diagnostics showing expected vs. actual values and exit with code `1` the moment an invariant fails.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`test`** is a first-class **lib** located at `src/main/ridgun/lib/test.rg` (domain `TST`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/test.rglib` | Portable distribution and direct `import test` resolution |
| **Compiled Archive** | `target/test.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libtest.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import test` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `test`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `assert equals / assert eq : A -> A -> String -> ()` | Polymorphic equality assertion with descriptive test label |
| `assert int equals / assert str eq` | Specialized `Int` and `String` equality assertions |
| `assert true / assert false / assert not` | Boolean invariant assertions |
| `assert ok : Int -> String -> ()` | Verify that an OS/socket status code equals `0` (`OK`) |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `test`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import test
import math

fn :: suite matematicas () => ()
      suite matematicas =
        _ = assert int equals 12 (math gcd 36 60) "MCD de 36 y 60"
        _ = assert true (math is prime 97) "97 es primo"
        echo "[PASS] suite matematicas"
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `test` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import test

fn :: verificar codigo sistema (rc : Int) => ()
      verificar codigo sistema rc =
        assert ok rc "operacion de descriptor exitosa"
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: All 30 automated test suites in `ridgun-libs` (`src/test/ridgun/test_*.rg`, over 4,000 lines of tests) run on this exact lib via `stable test`.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_test.rg`.
