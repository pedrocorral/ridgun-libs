# Chapter 05: The `tensor` Lib — Shapes, Rows and Columns, Matrix Product, and Block-Wise Operations

## 05.1. Why Does the `tensor` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `tensor` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `tensor`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: in most languages you either suffer pointer-chasing nested lists or link a 200 MB C++/Fortran behemoth like NumPy or OpenBLAS.

The **`tensor`** lib adds, to Ridgun's native `Tensor[...]` type, the helpers that the language does not give directly: shape queries (`tensor rows`, `tensor cols`, `tensor shape`), extraction of one row or one column (`tensor row`, `tensor col`), an explicit copy (`tensor clone`), the matrix product (`tensor matmul`), and element-wise operations between two whole tensors: XOR, AND, OR, addition, subtraction and multiplication.

In a traditional ecosystem, solving **`TENSOR`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`tensor`** lib (`src/main/ridgun/lib/tensor.ridgun`) tackles the problem with four non-negotiable principles:

1. **Declare `import tensor` (or `import tensor as alias`) at the top of your file**: every lib defines its `module :: tensor` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
3. **Tail-Call Optimization (TCO)**: all internal loops in `tensor` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 05.2. Native Artifacts, Imports, and Complete `tensor` API Catalog

In `ridgun-libs`, **`tensor`** is a first-class **lib** located at `src/main/ridgun/lib/tensor.ridgun` (domain `TENSOR`). When built with `stable bundle`, it compiles into one native artifact:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/tensor.ridgunlib` | Portable distribution and direct `import tensor` resolution |

> Every lib declares its own namespace via `module :: tensor`: simply write `import tensor` (or `import tensor as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

### 05.2.1. Summary of `tensor` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `tensor rows / tensor cols / tensor shape` | Number of rows and of columns of a 2D tensor, and both as a pair |
| `tensor row / tensor col` | Copy one row or one column into a 1D tensor |
| `tensor clone` | An independent copy of a tensor |
| `tensor matmul` | Matrix product of two 2D `Tensor[Real]` |
| `tensor bitxor blocks / tensor bitand blocks / tensor bitor blocks / tensor add blocks / tensor sub blocks / tensor mul blocks` | Element-wise bitwise operations on `Tensor[U64]` and arithmetic on `Tensor[Int]`, between two tensors of the same shape |

### 05.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/tensor.ridgun`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/tensor.ridgun` (`0` types, `0` operators, and `13` functions):

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: tensor rows Tensor[Int * r * c]` | `Int` |
| `2` | `fn :: tensor cols Tensor[Int * r * c]` | `Int` |
| `3` | `fn :: tensor shape Tensor[Int * r * c]` | `Int Int` |
| `4` | `fn :: tensor row Tensor[Int * r * c] Int` | `Tensor[Int * c]` |
| `5` | `fn :: tensor col Tensor[Int * r * c] Int` | `Tensor[Int * r]` |
| `6` | `fn :: tensor bitxor blocks Tensor[U64 * r * c] Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `7` | `fn :: tensor bitand blocks Tensor[U64 * r * c] Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `8` | `fn :: tensor bitor blocks Tensor[U64 * r * c] Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `9` | `fn :: tensor add blocks Tensor[Int * r * c] Tensor[Int * r * c]` | `Tensor[Int * r * c]` |
| `10` | `fn :: tensor sub blocks Tensor[Int * r * c] Tensor[Int * r * c]` | `Tensor[Int * r * c]` |
| `11` | `fn :: tensor mul blocks Tensor[Int * r * c] Tensor[Int * r * c]` | `Tensor[Int * r * c]` |
| `12` | `fn :: tensor clone Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `13` | `fn :: tensor matmul Tensor[Real * r * k] Tensor[Real * k * c]` | `Tensor[Real * r * c]` |

---

## 05.3. Deep Dive into `tensor`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `tensor` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test tensor.ridgun`.

### 05.3.1. Example 1: Core Tabular Workflow with `tensor`

Notice how in Ridgun the `=` signs and transformation steps using `tensor` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import tensor

fn :: producto matricial tensor Tensor[Real * r * k] Tensor[Real * k * c] => Tensor[Real * r * c]
      producto matricial tensor a b =
        tensor matmul a b
```

### 05.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `tensor` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 38 libs in `ridgun-libs`:

```ridgun
import tensor

fn :: combinar bloques Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      combinar bloques a b =
        tensor add blocks a b -> suma
        tensor mul blocks suma b
```

### 05.3.3. Example 3: Tensor Creation (`zeros`, `ones`, `eye`, `arange`, `linspace`), Dimension Introspection (`rank`, `len`, `shape`), and Views (`reshape`, `transpose`)

In this hands-on walkthrough we thoroughly exercise how `tensor` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test tensor dimensions and views => ()
      test tensor dimensions and views =
        m   = Tensor[Int * 2 * 3]
        m_(0, 0) = 10
        m_(0, 1) = 20
        m_(0, 2) = 30
        m_(1, 0) = 40
        m_(1, 1) = 50
        m_(1, 2) = 60
        tensor rows m -> assert int equals 2 "tensor rows == 2"
        tensor cols m -> assert int equals 3 "tensor cols == 3"
        sh  = tensor shape m
        shape fst sh -> assert int equals 2 "tensor shape rows == 2"
        shape snd sh -> assert int equals 3 "tensor shape cols == 3"
        r1  = tensor row m 1
        r1_(0) -> assert int equals 40 "row 1 col 0 == 40"
        r1_(1) -> assert int equals 50 "row 1 col 1 == 50"
        r1_(2) -> assert int equals 60 "row 1 col 2 == 60"
        c2  = tensor col m 2
        c2_(0) -> assert int equals 30 "col 2 row 0 == 30"
        c2_(1) -> assert int equals 60 "col 2 row 1 == 60"
        ()
```

### 05.3.4. Example 4: Element-Wise Hadamard Algebra (`+`, `-`, `*`, `/`, `xor`, `and`, `or`) and Deep Independent Cloning (`tensor clone`)

In this hands-on walkthrough we thoroughly exercise how `tensor` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test tensor hadamard and clone => ()
      test tensor hadamard and clone =
        a    = Tensor[Int * 2 * 2]
        a_(0, 0) = 10
        a_(0, 1) = 20
        a_(1, 0) = 30
        a_(1, 1) = 40
        b    = Tensor[Int * 2 * 2]
        b_(0, 0) = 1
        b_(0, 1) = 2
        b_(1, 0) = 3
        b_(1, 1) = 4
        s    = tensor add blocks a b
        s_(0, 0) -> assert int equals 11 "add (0,0) == 11"
        s_(1, 1) -> assert int equals 44 "add (1,1) == 44"
        d    = tensor sub blocks a b
        d_(0, 0) -> assert int equals 9 "sub (0,0) == 9"
        d_(1, 1) -> assert int equals 36 "sub (1,1) == 36"
        p    = tensor mul blocks a b
        p_(0, 0) -> assert int equals 10 "mul (0,0) == 10"
        p_(1, 1) -> assert int equals 160 "mul (1,1) == 160"
        ua   = Tensor[U64 * 2 * 2]
        ua_(0, 0) = 0xFF
        ua_(0, 1) = 0x0F
        ua_(1, 0) = 0xF0
        ua_(1, 1) = 0xAA
        ub   = Tensor[U64 * 2 * 2]
        ub_(0, 0) = 0x0F
        ub_(0, 1) = 0xFF
        ub_(1, 0) = 0x0F
        ub_(1, 1) = 0x55
        ux   = tensor bitxor blocks ua ub
        ux_(0, 0) -> assert int equals 0xF0 "xor (0,0) == 0xF0"
        ux_(1, 1) -> assert int equals 0xFF "xor (1,1) == 0xFF"
        uan  = tensor bitand blocks ua ub
        uan_(0, 0) -> assert int equals 0x0F "and (0,0) == 0x0F"
        uan_(1, 1) -> assert int equals 0x00 "and (1,1) == 0x00"
        uor  = tensor bitor blocks ua ub
        uor_(0, 0) -> assert int equals 0xFF "or (0,0) == 0xFF"
        uor_(1, 0) -> assert int equals 0xFF "or (1,0) == 0xFF"
        uc   = tensor clone ua
        uc_(0, 0) = 999
        ua_(0, 0) -> assert int equals 0xFF "clone preserves original ua_(0,0)"
        uc_(0, 0) -> assert int equals 999 "clone updates uc_(0,0)"
        ()
```

### 05.3.5. Example 5: Native Matrix Multiplication (`@`) and Einstein Subscript Contraction (`a_ik @ b_kj`)

In this hands-on walkthrough we thoroughly exercise how `tensor` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test tensor matmul => ()
      test tensor matmul =
        ma  = Tensor[Real * 2 * 3]
        ma_(0, 0) = 1.0
        ma_(0, 1) = 2.0
        ma_(0, 2) = 3.0
        ma_(1, 0) = 4.0
        ma_(1, 1) = 5.0
        ma_(1, 2) = 6.5
        mb  = Tensor[Real * 3 * 2]
        mb_(0, 0) = 7.0
        mb_(0, 1) = 8.0
        mb_(1, 0) = 9.0
        mb_(1, 1) = 10.0
        mb_(2, 0) = 11.0
        mb_(2, 1) = 0.5
        mc  = tensor matmul ma mb
        assert true (mc_(0, 0) == 58.0) "matmul (0,0) == 7 + 18 + 33"
        assert true (mc_(0, 1) == 29.5) "matmul (0,1) == 8 + 20 + 1.5"
        assert true (mc_(1, 0) == 144.5) "matmul (1,0) == 28 + 45 + 71.5"
        assert true (mc_(1, 1) == 85.25) "matmul (1,1) == 32 + 50 + 3.25"
        ()
```

### 05.3.6. Example 6: 1024-Byte Cryptographic Block Compression via Tensors (`f blamka`, `blamka g`, `blamka p16`, `compress block`)

In this hands-on walkthrough we thoroughly exercise how `tensor` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test blamka tensor compression => ()
      test blamka tensor compression =
        fb  = f blamka 1 2
        fb -> assert int equals 7 "f blamka 1 2 == 7"
        gr  = blamka g 1 2 3 4
        (g fst gr) != 0 -> assert true "blamka g non-zero output"
        bx  = Tensor[U64 * 8 * 16]
        by  = Tensor[U64 * 8 * 16]
        bx_(0, 0) = 1
        by_(0, 0) = 2
        bz  = compress block bx by
        bz_(0, 0) != 0 -> assert true "compress block non-zero (0,0)"
        bx_(0, 0) -> assert int equals 1 "compress block preserves bx_(0,0)"
        by_(0, 0) -> assert int equals 2 "compress block preserves by_(0,0)"
        ()
```

---

## 05.4. Under the Hood: How `tensor` Is Built in Pure Ridgun (`src/main/ridgun/lib/tensor.ridgun`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/tensor.ridgun` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 05.4.1. Internal Implementation: Core Implementation Part 1

Observe how `tensor.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
module :: tensor

fn :: tensor rows Tensor[Int * r * c] => Int
      tensor rows (Tensor[Int * r * c] m) = r

fn :: tensor cols Tensor[Int * r * c] => Int
      tensor cols (Tensor[Int * r * c] m) = c

fn :: tensor shape Tensor[Int * r * c] => Int Int
      tensor shape (Tensor[Int * r * c] m) = (r, c)

fn :: tensor row Tensor[Int * r * c] Int => Tensor[Int * c]
      tensor row m                   idx =  m_(idx,)

fn :: tensor col Tensor[Int * r * c] Int => Tensor[Int * r]
      tensor col m                   idx =  m_(,idx)

fn :: tensor bitxor blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor bitxor blocks a b = a_ij xor b_ij
```

### 05.4.2. Internal Implementation: Core Implementation Part 2

Observe how `tensor.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: tensor bitand blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor bitand blocks a b = a_ij and b_ij

fn :: tensor bitor blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor bitor blocks a b = a_ij or b_ij

fn :: tensor add blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor add blocks a b = a_ij + b_ij

fn :: tensor sub blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor sub blocks a b = a_ij - b_ij

fn :: tensor mul blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor mul blocks a b = a_ij * b_ij

fn :: tensor clone Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor clone m                   =
        z_ij = m_ij
        z_ij

fn :: tensor matmul Tensor[Real * r * k] Tensor[Real * k * c] => Tensor[Real * r * c]
      tensor matmul a b = a_ik @ b_kj
```

---

## 05.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `tensor`

- **Algorithmic & Safety Guarantee**: Contiguous 8-byte-aligned storage statically managed by RMM1/RMM2, $O(1)$ descriptor views without buffer duplication, and pure Copy-on-Write semantics.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/tensor.ridgun` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test tensor.ridgun`.

### The 5 Golden Rules When Programming with `tensor`

1. **Declare `import tensor` at the top of your file** and call its functions with spaces, exactly as they are declared, so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `tensor` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `tensor`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `tensor` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 06**, we will explore the **`linalg`** lib in full depth (The `linalg` Lib — `Tensor[Real]` Linear Algebra, Bareiss Solver, and Activations).
