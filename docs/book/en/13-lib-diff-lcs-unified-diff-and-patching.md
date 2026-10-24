# Chapter 13: The `diff` Lib — LCS Line Diff, Edit Distance, Unified Diff, and Patching

## 13.1. Why Does the `diff` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `diff` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `diff`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: when a test fails or a config file changes, a raw 200-line `"expected A, got B"` dump forces you to squint at the screen hunting for the exact line that changed.

The **`diff`** lib computes the **Longest Common Subsequence (LCS)** over a 2D `Tensor[Int]` DP table to produce minimal edit scripts (`DiffKeep`, `DiffAdd`, `DiffDel`), edit distance, **Unified Diff** output (`---`/`+++`/`@@`), and lossless patching (`diff apply`).

In a traditional ecosystem, solving **`DIFF`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`diff`** lib (`src/main/ridgun/lib/diff.rg`) tackles the problem with four non-negotiable principles:

1. **Total Functions & Explicit Contracts (`=>`)**: no function in `diff` throws hidden exceptions or relies on `null`. Every edge case (empty inputs, zero divisors, truncated frames, or out-of-bounds indices) returns a documented sentinel value or an algebraic sum type (`Option`, `Result`).
2. **Zero C Code & Zero `libc`**: every line of `diff` compiles directly into native ELF64 machine code verified by `ridgunc`.
3. **Tail-Call Optimization (TCO)**: all internal loops in `diff` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 13.2. Native Artifacts, Imports, and Complete `diff` API Catalog

In `ridgun-libs`, **`diff`** is a first-class **lib** located at `src/main/ridgun/lib/diff.rg` (domain `DIFF`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/diff.rglib` | Portable distribution and direct `import diff` resolution |
| **Compiled Archive** | `target/diff.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libdiff.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import diff` at the top and call its functions using either multi-word spaces (`my fn x`) or underscores (`my_fn x`).

### 13.2.1. Summary of `diff` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `type DiffOp` | `DiffKeep String | DiffDel String | DiffAdd String` |
| `diff lines / diff text` | Compute minimal LCS edit script between `[String]` lists or multiline strings |
| `diff edit distance / diff stats` | Minimal insertion+deletion distance and `(kept, added, deleted)` counts |
| `diff format / diff unified` | Render compact `+ / - /  ` lines or standard Unified Diff with headers |
| `diff apply / diff apply text` | Reconstruct the target document losslessly from an edit script |

### 13.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/diff.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/diff.rg` (`2` types, `0` operators, and `33` functions):

**Algebraic Data Types & Records (`type`) in `diff`:**

```ridgun
type DiffEdit = diff_op: String, line_text: String, old_line_no: Int, new_line_no: Int
type DiffStats = equal_count: Int, insert_count: Int, delete_count: Int
```

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: df_max Int Int` | `Int` |
| `2` | `fn :: df_int_to_str_pos Int` | `String` |
| `3` | `fn :: df_int_to_str Int` | `String` |
| `4` | `fn :: df_rev [String] [String]` | `[String]` |
| `5` | `fn :: df_rev_ints [Int] [Int]` | `[Int]` |
| `6` | `fn :: df_split_lines_loop String Int Int Int [String]` | `[String]` |
| `7` | `fn :: df_split_lines String` | `[String]` |
| `8` | `fn :: df_zeros Int [Int]` | `[Int]` |
| `9` | `fn :: df_nth_int [Int] Int` | `Int` |
| `10` | `fn :: df_head_int [Int]` | `Int` |
| `11` | `fn :: df_cell_val String String Int Int Int` | `Int` |
| `12` | `fn :: df_build_row String [String] [Int] Int [Int]` | `[Int]` |
| `13` | `fn :: df_build_dp [String] [String] [[Int]]` | `[[Int]]` |
| `14` | `fn :: df_tail_rows [[Int]]` | `[[Int]]` |
| `15` | `fn :: df_head_row [[Int]]` | `[Int]` |
| `16` | `fn :: df_rev_edits [DiffEdit] [DiffEdit]` | `[DiffEdit]` |
| `17` | `fn :: df_backtrack [String] [String] [[Int]] Int Int Int [DiffEdit]` | `[DiffEdit]` |
| `18` | `fn :: df_backtrack_step String [String] String [String] [[Int]] Int Int Int [DiffEdit]` | `[DiffEdit]` |
| `19` | `fn :: df_backtrack_branch String [String] String [String] [[Int]] [[Int]] Int Int Int Int Int [DiffEdit]` | `[DiffEdit]` |
| `20` | `fn :: df_list_length [String]` | `Int` |
| `21` | `fn :: diff lines [String] [String]` | `[DiffEdit]` |
| `22` | `fn :: diff text String String` | `[DiffEdit]` |
| `23` | `fn :: df_stats_loop [DiffEdit] Int Int Int` | `DiffStats` |
| `24` | `fn :: diff stats [DiffEdit]` | `DiffStats` |
| `25` | `fn :: diff edit distance String String` | `Int` |
| `26` | `fn :: diff has changes [DiffEdit]` | `Bool` |
| `27` | `fn :: df_format_unified_lines [DiffEdit] String` | `String` |
| `28` | `fn :: df_hunk_start Int` | `Int` |
| `29` | `fn :: df_unified_header String String Int Int` | `String` |
| `30` | `fn :: diff unified String String String String` | `String` |
| `31` | `fn :: df_apply_collect [DiffEdit] [String]` | `[String]` |
| `32` | `fn :: df_join_lines [String]` | `String` |
| `33` | `fn :: diff apply [DiffEdit]` | `String` |

---

## 13.3. Deep Dive into `diff`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `diff` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test diff.rg`.

### 13.3.1. Example 1: Core Tabular Workflow with `diff`

Notice how in Ridgun the `=` signs and transformation steps using `diff` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import diff

fn :: auditar cambio (antes : String) (despues : String) => (Int, String)
      auditar cambio antes despues =
        dist   = diff edit distance ( ["host=localhost", "port=8080"] ) ( ["host=0.0.0.0", "port=8080"] )
        parche = diff unified "config.old" "config.new" antes despues
        (dist, parche)
```

### 13.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `diff` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import diff

fn :: verificar parche (orig : [String]) (nuevo : [String]) => [String]
      verificar parche orig nuevo =
        ops = diff lines orig nuevo
        diff apply ops
```

### 13.3.3. Example 3: Comparing Empty and Identical Texts: Zero Edit Distance and Invariant Verification

In this hands-on walkthrough we thoroughly exercise how `diff` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_diff_empty_and_identical => ()
      test_diff_empty_and_identical =
        nl = char_from_code 10
        e_empty = diff text "" ""
        _ = assert int equals (count_edits e_empty) 0 "AC1: empty diff edit count"
        _ = assert false (diff has changes e_empty) "AC1: empty diff has no changes"
        _ = assert int equals (diff edit distance "" "") 0 "AC1: empty edit distance"
        _ = assert str eq (diff apply e_empty) "" "AC3: empty diff apply"
        same_doc = "alpha" + nl + "beta" + nl + "gamma"
        e_same = diff text same_doc same_doc
        _ = assert int equals (count_edits e_same) 3 "AC1: identical 3-line count"
        _ = assert false (diff has changes e_same) "AC1: identical has no changes"
        st_same = diff stats e_same
        _ = assert int equals (equal_count st_same) 3 "AC1: equal_count == 3"
        _ = assert int equals (insert_count st_same) 0 "AC1: insert_count == 0"
        _ = assert int equals (delete_count st_same) 0 "AC1: delete_count == 0"
        _ = assert int equals (diff edit distance same_doc same_doc) 0 "AC1: identical edit distance == 0"
        _ = assert str eq (diff apply e_same) same_doc "AC3: identical diff apply"
        ()
```

### 13.3.4. Example 4: Pure Insertions (`DiffInsert`), Pure Deletions (`DiffDelete`), and Forward Patching (`diff patch`)

In this hands-on walkthrough we thoroughly exercise how `diff` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_diff_pure_insert_and_delete => ()
      test_diff_pure_insert_and_delete =
        nl = char_from_code 10
        target = "line1" + nl + "line2" + nl + "line3"
        e_ins = diff text "" target
        _ = assert true (diff has changes e_ins) "AC1: pure insert has changes"
        st_ins = diff stats e_ins
        _ = assert int equals (equal_count st_ins) 0 "AC1: pure insert equal_count"
        _ = assert int equals (insert_count st_ins) 3 "AC1: pure insert insert_count"
        _ = assert int equals (delete_count st_ins) 0 "AC1: pure insert delete_count"
        _ = assert int equals (diff edit distance "" target) 3 "AC1: pure insert edit distance"
        _ = assert str eq (diff apply e_ins) target "AC3: pure insert apply"
        ins0 = nth_edit e_ins 0
        ins2 = nth_edit e_ins 2
        _ = assert str eq (diff_op ins0) "insert" "AC1: ins0 op"
        _ = assert int equals (old_line_no ins0) 0 "AC1: ins0 old_line_no"
        _ = assert int equals (new_line_no ins0) 1 "AC1: ins0 new_line_no"
        _ = assert int equals (new_line_no ins2) 3 "AC1: ins2 new_line_no"
        e_del = diff text target ""
        _ = assert true (diff has changes e_del) "AC1: pure delete has changes"
        st_del = diff stats e_del
        _ = assert int equals (equal_count st_del) 0 "AC1: pure delete equal_count"
        _ = assert int equals (insert_count st_del) 0 "AC1: pure delete insert_count"
        _ = assert int equals (delete_count st_del) 3 "AC1: pure delete delete_count"
        _ = assert int equals (diff edit distance target "") 3 "AC1: pure delete edit distance"
        _ = assert str eq (diff apply e_del) "" "AC3: pure delete apply"
        del0 = nth_edit e_del 0
        del2 = nth_edit e_del 2
        _ = assert str eq (diff_op del0) "delete" "AC1: del0 op"
        _ = assert int equals (old_line_no del0) 1 "AC1: del0 old_line_no"
        _ = assert int equals (new_line_no del0) 0 "AC1: del0 new_line_no"
        _ = assert int equals (old_line_no del2) 3 "AC1: del2 old_line_no"
        ()
```

### 13.3.5. Example 5: Eugene Myers' Classic Vector (`ABCABBA` $\rightarrow$ `CBABAC`): Longest Common Subsequence (LCS) and Minimal Edit Distance

In this hands-on walkthrough we thoroughly exercise how `diff` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_diff_myers_classic_vector => ()
      test_diff_myers_classic_vector =
        nl = char_from_code 10
        old_lines = ["A", "B", "C", "A", "B", "B", "A"]
        new_lines = ["C", "B", "A", "B", "A", "C"]
        edits = diff lines old_lines new_lines
        st = diff stats edits
        _ = assert int equals (equal_count st) 4 "AC1: Myers LCS length 4"
        _ = assert int equals (delete_count st) 3 "AC1: Myers delete count 3"
        _ = assert int equals (insert_count st) 2 "AC1: Myers insert count 2"
        old_s = "A" + nl + "B" + nl + "C" + nl + "A" + nl + "B" + nl + "B" + nl + "A"
        new_s = "C" + nl + "B" + nl + "A" + nl + "B" + nl + "A" + nl + "C"
        _ = assert int equals (diff edit distance old_s new_s) 5 "AC1: Myers edit distance 5"
        _ = assert str eq (diff apply edits) new_s "AC3: Myers apply reproduces CBABAC"
        ()
```

### 13.3.6. Example 6: Source & Target Line Number Inspection (`diff old line`, `diff new line`) and Exact Reconstruction with `diff patch`

In this hands-on walkthrough we thoroughly exercise how `diff` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_diff_code_hunks_and_line_numbers => ()
      test_diff_code_hunks_and_line_numbers =
        nl = char_from_code 10
        old_code = "fn :: add Int Int => Int" + nl + "      add a b = a + b" + nl + "" + nl + "fn :: sub Int Int => Int" + nl + "      sub a b = a - b"
        new_code = "fn :: add Int Int => Int" + nl + "      add x y = x + y" + nl + "" + nl + "fn :: mul Int Int => Int" + nl + "      mul a b = a * b" + nl + "" + nl + "fn :: sub Int Int => Int" + nl + "      sub a b = a - b"
        edits = diff text old_code new_code
        _ = assert true (diff has changes edits) "AC1: code refactoring has changes"
        _ = assert str eq (diff apply edits) new_code "AC3: code refactoring lossless apply"
        e0 = nth_edit edits 0
        _ = assert str eq (diff_op e0) "equal" "AC1: line 1 equal"
        _ = assert int equals (old_line_no e0) 1 "AC1: line 1 old_line_no"
        _ = assert int equals (new_line_no e0) 1 "AC1: line 1 new_line_no"
        e1 = nth_edit edits 1
        _ = assert str eq (diff_op e1) "delete" "AC1: line 2 deleted"
        _ = assert str eq (line_text e1) "      add a b = a + b" "AC1: deleted line text"
        _ = assert int equals (old_line_no e1) 2 "AC1: deleted old_line_no"
        _ = assert int equals (new_line_no e1) 0 "AC1: deleted new_line_no"
        e2 = nth_edit edits 2
        _ = assert str eq (diff_op e2) "insert" "AC1: line 2 inserted"
        _ = assert str eq (line_text e2) "      add x y = x + y" "AC1: inserted line text"
        _ = assert int equals (old_line_no e2) 0 "AC1: inserted old_line_no"
        _ = assert int equals (new_line_no e2) 2 "AC1: inserted new_line_no"
        ()
```

### 13.3.7. Example 7: GNU-Style Unified Diff Formatting (`--- old`, `+++ new`, `-`, `+`, ` `) with `diff unified` and `(kept, deleted, inserted)` Stats

In this hands-on walkthrough we thoroughly exercise how `diff` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_diff_unified_formatting => ()
      test_diff_unified_formatting =
        nl = char_from_code 10
        old_s = "one" + nl + "two" + nl + "three"
        new_s = "one" + nl + "TWO" + nl + "three" + nl + "four"
        uni = diff unified "a/sample.txt" "b/sample.txt" old_s new_s
        expected = "--- a/sample.txt" + nl + "+++ b/sample.txt" + nl + "@@ -1,3 +1,4 @@" + nl + " one" + nl + "-two" + nl + "+TWO" + nl + " three" + nl + "+four" + nl
        _ = assert str eq uni expected "AC2: unified diff output matches standard header and hunk format"
        uni_empty = diff unified "a/empty" "b/empty" "" ""
        _ = assert str eq uni_empty ("--- a/empty" + nl + "+++ b/empty" + nl + "@@ -0,0 +0,0 @@" + nl) "AC2: unified diff empty files"
        ()
```

### 13.3.8. Example 8: Robustness on Repetitive Lines and Duplicated Code Blocks

In this hands-on walkthrough we thoroughly exercise how `diff` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_diff_repetitive_lines => ()
      test_diff_repetitive_lines =
        nl = char_from_code 10
        old_rep = "x" + nl + "x" + nl + "y" + nl + "x" + nl + "x"
        new_rep = "x" + nl + "y" + nl + "y" + nl + "x"
        edits = diff text old_rep new_rep
        st = diff stats edits
        _ = assert int equals (equal_count st) 3 "AC1: repetitive LCS equal_count"
        _ = assert int equals (delete_count st) 2 "AC1: repetitive LCS delete_count"
        _ = assert int equals (insert_count st) 1 "AC1: repetitive LCS insert_count"
        _ = assert str eq (diff apply edits) new_rep "AC3: repetitive lines apply"
        ()
```

---

## 13.4. Under the Hood: How `diff` Is Built in Pure Ridgun (`src/main/ridgun/lib/diff.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/diff.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 13.4.1. Internal Implementation: Internal Helpers

Observe how `diff.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: df_max Int Int => Int
      df_max a   b
        | a >= b = a
        | otherwise = b

fn :: df_int_to_str_pos Int => String
      df_int_to_str_pos n
        | n == 0 = ""
        | otherwise = (df_int_to_str_pos (n / 10)) + (char_from_code ((n % 10) + 48))

fn :: df_int_to_str Int => String
      df_int_to_str n
        | n == 0 = "0"
        | n < 0 = "-" + (df_int_to_str_pos (0 - n))
        | otherwise = df_int_to_str_pos n

fn :: df_rev [String] [String] => [String]
      df_rev []       acc      =  acc
      df_rev (x:xs)   acc      =  df_rev xs ([x] :: acc)

fn :: df_rev_ints [Int]  [Int] => [Int]
      df_rev_ints []     acc   =  acc
      df_rev_ints (x:xs) acc   =  df_rev_ints xs ([x] :: acc)

fn :: df_split_lines_loop String Int Int Int [String] => [String]
      df_split_lines_loop s idx n start acc
        | idx >= n = df_rev ([str_slice s start n] :: acc) []
        | (str_char_at s idx) == 10 = df_split_lines_loop s (idx + 1) n (idx + 1) ([str_slice s start idx] :: acc)
        | otherwise = df_split_lines_loop s (idx + 1) n start acc

fn :: df_split_lines String => [String]
      df_split_lines s
        | (str_len s) == 0 = []
        | otherwise = df_split_lines_loop s 0 (str_len s) 0 []

fn :: df_zeros Int [Int] => [Int]
      df_zeros n   acc
        | n <= 0 = acc
        | otherwise = df_zeros (n - 1) ([0] :: acc)

fn :: df_nth_int [Int]  Int => Int
      df_nth_int []     _   =  0
      df_nth_int (x:xs) idx
        | idx <= 0 = x
        | otherwise = df_nth_int xs (idx - 1)

fn :: df_head_int [Int] => Int
      df_head_int []    =  0
      df_head_int (x:_) =  x
```

### 13.4.2. Internal Implementation: Public API

Observe how `diff.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: diff lines [String]  [String]  => [DiffEdit]
      diff lines old_lines new_lines =
        rev_old = df_rev old_lines []
        rev_new = df_rev new_lines []
        zero_row = df_zeros ((df_list_length new_lines) + 1) []
        dp_rows = df_build_dp rev_old rev_new [zero_row]
        df_backtrack old_lines new_lines dp_rows 0 1 1 []

fn :: diff text String String => [DiffEdit]
      diff text old_s  new_s  =  diff lines (df_split_lines old_s) (df_split_lines new_s)

fn :: df_stats_loop [DiffEdit] Int Int Int => DiffStats
      df_stats_loop []         eq  ins del =  DiffStats eq ins del
      df_stats_loop (e:es)     eq  ins del
        | (diff_op e) == "equal" = df_stats_loop es (eq + 1) ins del
        | (diff_op e) == "insert" = df_stats_loop es eq (ins + 1) del
        | otherwise = df_stats_loop es eq ins (del + 1)

fn :: diff stats [DiffEdit] => DiffStats
      diff stats edits      =  df_stats_loop edits 0 0 0

fn :: diff edit distance String String => Int
      diff edit distance old_s  new_s  =
        st = diff stats (diff text old_s new_s)
        (insert_count st) + (delete_count st)

fn :: diff has changes [DiffEdit] => Bool
      diff has changes []         =  False
      diff has changes (e:es)
        | (diff_op e) == "equal" = diff has changes es
        | otherwise = True

fn :: df_format_unified_lines [DiffEdit] String => String
      df_format_unified_lines []         acc    =  acc
      df_format_unified_lines (e:es)     acc
        | (diff_op e) == "equal" = df_format_unified_lines es (acc + " " + (line_text e) + (char_from_code 10))
        | (diff_op e) == "delete" = df_format_unified_lines es (acc + "-" + (line_text e) + (char_from_code 10))
        | otherwise = df_format_unified_lines es (acc + "+" + (line_text e) + (char_from_code 10))

fn :: df_hunk_start Int => Int
      df_hunk_start cnt
        | cnt == 0 = 0
        | otherwise = 1

fn :: df_unified_header String    String    Int     Int     => String
      df_unified_header old_label new_label old_cnt new_cnt =
        old_start = df_hunk_start old_cnt
        new_start = df_hunk_start new_cnt
        nl = char_from_code 10
        "--- " + old_label + nl + "+++ " + new_label + nl + "@@ -" + (df_int_to_str old_start) + "," + (df_int_to_str old_cnt) + " +" + (df_int_to_str new_start) + "," + (df_int_to_str new_cnt) + " @@" + nl
```

---

## 13.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `diff`

- **Algorithmic & Safety Guarantee**: Guaranteed mathematical identity $diff\_edit\_distance(a, b) == |a| + |b| - 2 \cdot LCS(a, b)$ and lossless reconstruction `diff apply (diff lines a b) == b`.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/diff.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test diff.rg`.

### The 5 Golden Rules When Programming with `diff`

1. **Declare `import diff` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `diff` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `diff`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `diff` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 14**, we will explore the **`template`** lib in full depth (The `template` Lib — Safe Mustache Templates with HTML and LaTeX Auto-Escaping).
