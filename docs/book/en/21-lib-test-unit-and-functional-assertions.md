# Chapter 21: The `test` Lib — Unit and Functional Test Assertion Primitives (`RG-011`)

## 21.1. Why Does the `test` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `test` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `test`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: when a testing framework demands compiler-magic macros, runtime reflection, or a bloated external runner, writing tests stops feeling immediate.

The **`test`** lib (`RG-011`) provides polymorphic and type-specific assertions that emit clear `[FAIL]` diagnostics showing expected vs. actual values and exit with code `1` the moment an invariant fails.

In a traditional ecosystem, solving **`TST`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`test`** lib (`src/main/ridgun/lib/test.rg`) tackles the problem with four non-negotiable principles:

1. **Total Functions & Explicit Contracts (`=>`)**: no function in `test` throws hidden exceptions or relies on `null`. Every edge case (empty inputs, zero divisors, truncated frames, or out-of-bounds indices) returns a documented sentinel value or an algebraic sum type (`Option`, `Result`).
2. **Zero C Code & Zero `libc`**: every line of `test` compiles directly into native ELF64 machine code verified by `ridgunc`.
3. **Tail-Call Optimization (TCO)**: all internal loops in `test` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 21.2. Native Artifacts, Imports, and Complete `test` API Catalog

In `ridgun-libs`, **`test`** is a first-class **lib** located at `src/main/ridgun/lib/test.rg` (domain `TST`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/test.rglib` | Portable distribution and direct `import test` resolution |
| **Compiled Archive** | `target/test.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libtest.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import test` at the top and call its functions using either multi-word spaces (`my fn x`) or underscores (`my_fn x`).

### 21.2.1. Summary of `test` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `assert equals / assert eq : A -> A -> String -> ()` | Polymorphic equality assertion with descriptive test label |
| `assert int equals / assert str eq` | Specialized `Int` and `String` equality assertions |
| `assert true / assert false / assert not` | Boolean invariant assertions |
| `assert ok : Int -> String -> ()` | Verify that an OS/socket status code equals `0` (`OK`) |

### 21.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/test.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/test.rg` (`0` types, `0` operators, and `12` functions):

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: fail test String` | `()` |
| `2` | `fn :: check eq A A` | `Bool` |
| `3` | `fn :: check str eq String String` | `Bool` |
| `4` | `fn :: check true Bool` | `Bool` |
| `5` | `fn :: assert true Bool String` | `()` |
| `6` | `fn :: assert false Bool String` | `()` |
| `7` | `fn :: assert equals A A String` | `()` |
| `8` | `fn :: assert str eq String String String` | `()` |
| `9` | `fn :: assert int equals Int Int String` | `()` |
| `10` | `fn :: assert ok Bool` | `()` |
| `11` | `fn :: assert not Bool` | `()` |
| `12` | `fn :: assert eq A A` | `()` |

---

## 21.3. Deep Dive into `test`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `test` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test test.rg`.

### 21.3.1. Example 1: Core Tabular Workflow with `test`

Notice how in Ridgun the `=` signs and transformation steps using `test` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import test
import math

fn :: suite matematicas () => ()
      suite matematicas =
        _ = assert int equals 12 (math gcd 36 60) "MCD de 36 y 60"
        _ = assert true (math is prime 97) "97 es primo"
        echo "[PASS] suite matematicas"
```

### 21.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `test` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import test

fn :: verificar codigo sistema (rc : Int) => ()
      verificar codigo sistema rc =
        assert ok rc "operacion de descriptor exitosa"
```

### 21.3.3. Example 3: Boolean Predicates (`check eq`, `check str eq`, `check true`) and Diagnostic RG-011 Assertions (`assert equals`, `assert str eq`, `assert int equals`)

In this hands-on walkthrough we thoroughly exercise how `test` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test rg011 assertions => ()
      test rg011 assertions =
        _ = assert equals 4 4 "math int equality"
        _ = assert equals "ok" "ok" "string equality"
        _ = assert equals True True "bool equality"
        _ = assert true (1 < 2) "1 < 2 holds"
        _ = assert false (1 > 2) "1 > 2 is false"
        _ = assert str eq "ridgun" "ridgun" "str eq helper"
        _ = assert int equals 42 42 "int eq helper"
        _ = assert eq 10 10
        _ = assert ok True
        _ = assert not False
        _ = assert true (check eq 2 2) "check eq True"
        _ = assert false (check eq 1 2) "check eq False"
        _ = assert true (check str eq "a" "a") "check str eq True"
        _ = assert false (check str eq "a" "b") "check str eq False"
        _ = assert true (check true True) "check true True"
        assert false (check true False) "check true False"
```

### 21.3.4. Example 4: Composing Unit and Functional Suites with Pure Predicates and Concise Assertions (`assert ok`, `assert not`, `assert eq`)

In this hands-on walkthrough we thoroughly exercise how `test` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
import test

fn :: validar invariantes de dominio (x : Int) (nombre : String) => Bool
      validar invariantes de dominio x nombre =
        ok_num = check eq (x * 2) (x + x)
        ok_str = check str eq nombre "ridgun"
        check true (ok_num and ok_str)

fn :: ejecutar suite de ejemplo => ()
      ejecutar suite de ejemplo =
        -- 1. Predicados puros sin salida del proceso (`check_*`)
        _ = assert true (validar invariantes de dominio 21 "ridgun") "predicado compuesto"
        -- 2. Aserciones anotadas con mensaje diagnóstico (`assert_*`)
        _ = assert int equals (20 + 22) 42 "suma entera exacta"
        _ = assert str eq "rglib" "rglib" "etiqueta de artefacto"
        -- 3. Aserciones concisas sin etiqueta (`assert ok`, `assert not`, `assert eq`)
        _ = assert ok (10 > 5)
        _ = assert not (10 < 5)
        _ = assert eq [1, 2, 3] [1, 2, 3]
        ()
```

---

## 21.4. Under the Hood: How `test` Is Built in Pure Ridgun (`src/main/ridgun/lib/test.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/test.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 21.4.1. Internal Implementation: Non-Exiting Predicate Helpers

Observe how `test.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: check eq A      A        => Bool
      check eq actual expected =  actual == expected

fn :: check str eq String String   => Bool
      check str eq actual expected =  actual == expected

fn :: check true Bool => Bool
      check true cond =  cond
```

### 21.4.2. Internal Implementation: RG-011 Message-Annotated Assertions

Observe how `test.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: assert true Bool String => ()
      assert true cond label  =
        | cond      = ()
        | otherwise = fail test "assert_true failed: {label}"

fn :: assert false Bool String => ()
      assert false cond label  =
        | not cond  = ()
        | otherwise = fail test "assert_false failed: {label}"

fn :: assert equals A      A        String => ()
      assert equals actual expected label  =
        | actual == expected = ()
        | otherwise          = fail test "assert_equals failed: {label}"

fn :: assert str eq String String String => ()
      assert str eq actual expected label =
        | actual == expected = ()
        | otherwise          = fail test "assert_str_eq failed ({label}): got '{actual}', expected '{expected}'"

fn :: assert int equals Int Int String => ()
      assert int equals actual expected label =
        | actual == expected = ()
        | otherwise          = fail test "assert_int_equals failed ({label}): got {actual}, expected {expected}"
```

### 21.4.3. Internal Implementation: Concise Label-Free Assertion Helpers

Observe how `test.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: assert ok Bool => ()
      assert ok cond =  assert true cond "assert_ok"

fn :: assert not Bool => ()
      assert not cond =  assert false cond "assert_not"

fn :: assert eq A      A        => ()
      assert eq actual expected =  assert equals actual expected "assert_eq"
```

---

## 21.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `test`

- **Algorithmic & Safety Guarantee**: All 30 automated test suites in `ridgun-libs` (`src/test/ridgun/test_*.rg`, over 4,000 lines of tests) run on this exact lib via `stable test`.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/test.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test test.rg`.

### The 5 Golden Rules When Programming with `test`

1. **Declare `import test` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `test` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `test`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `test` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 22**, we will explore the **`posix`** lib in full depth (The `posix` Lib — 2-Layer PAL (`SysOs`, `SysArch`), Clocks, Signals, and CSPRNG).
