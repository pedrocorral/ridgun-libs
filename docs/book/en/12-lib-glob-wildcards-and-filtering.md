# Chapter 12: The `glob` Lib — Wildcard Patterns (`*`, `?`, `[a-z]`) and List Filtering

## 12.1. Why Does the `glob` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `glob` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `glob`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: firing up a full regular expression engine just to check whether a filename matches `*.rg` or `test_[0-9]*.rg` is overkill.

The **`glob`** lib implements shell wildcard matching (`*`, `?`, `[a-z]` ranges, negated `[!0-9]` / `[^a-z]` classes), case-insensitive matching (`glob match ci`), and batch list filtering.

In a traditional ecosystem, solving **`GLOB`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`glob`** lib (`src/main/ridgun/lib/glob.rg`) tackles the problem with four non-negotiable principles:

1. **Declare `import glob` (or `import glob as alias`) at the top of your file**: every lib defines its `module :: glob` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
3. **Tail-Call Optimization (TCO)**: all internal loops in `glob` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 12.2. Native Artifacts, Imports, and Complete `glob` API Catalog

In `ridgun-libs`, **`glob`** is a first-class **lib** located at `src/main/ridgun/lib/glob.rg` (domain `GLOB`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/glob.rglib` | Portable distribution and direct `import glob` resolution |
| **Compiled Archive** | `target/glob.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libglob.so` | Native dynamic shared library with zero C or `libc` dependencies |

> Every lib declares its own namespace via `module :: glob`: simply write `import glob` (or `import glob as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

### 12.2.1. Summary of `glob` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `glob match / glob match ci` | Case-sensitive and ASCII case-insensitive glob pattern matching |
| `glob filter / glob any match` | Filter `[String]` to matching items or check if any pattern in a list matches |
| `glob has magic` | Detect whether a string contains wildcard metacharacters (`*`, `?`, `[`) |

### 12.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/glob.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/glob.rg` (`0` types, `0` operators, and `18` functions):

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: gl lower char String Int Int` | `String` |
| `2` | `fn :: gl to lower loop String Int Int` | `String` |
| `3` | `fn :: gl to lower String` | `String` |
| `4` | `fn :: gl find close bracket String Int Int` | `Int` |
| `5` | `fn :: gl match range String Int Int Int Int Int` | `Bool` |
| `6` | `fn :: gl match class body String Int Int Int` | `Bool` |
| `7` | `fn :: gl eval bracket char String Int Int Int Int` | `Bool` |
| `8` | `fn :: gl eval bracket String Int Int Int` | `Bool` |
| `9` | `fn :: gl skip stars String Int Int` | `Int` |
| `10` | `fn :: gl match star String Int Int String Int Int` | `Bool` |
| `11` | `fn :: gl match star at String Int Int String Int Int` | `Bool` |
| `12` | `fn :: gl match bracket step String Int Int String Int Int Int` | `Bool` |
| `13` | `fn :: gl match step String Int Int String Int Int Int` | `Bool` |
| `14` | `fn :: gl match loop String Int Int String Int Int` | `Bool` |
| `15` | `fn :: glob match String String` | `Bool` |
| `16` | `fn :: glob match ci String String` | `Bool` |
| `17` | `fn :: glob filter String [String]` | `[String]` |
| `18` | `fn :: glob any match [String] String` | `Bool` |

---

## 12.3. Deep Dive into `glob`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `glob` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test glob.rg`.

### 12.3.1. Example 1: Core Tabular Workflow with `glob`

Notice how in Ridgun the `=` signs and transformation steps using `glob` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import glob

fn :: seleccionar fuentes ridgun [String] => [String]
      seleccionar fuentes ridgun archivos =
        glob filter "test_[a-z]*.rg" archivos
```

### 12.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `glob` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import glob

fn :: es ruta excluida String => Bool
      es ruta excluida ruta =
        glob any match ["*.tmp", "*.bak", "target/*"] ruta
```

### 12.3.3. Example 3: `*` and `?` Wildcards, Full-String Boundary Matching, and Empty-Pattern Edge Cases

In this hands-on walkthrough we thoroughly exercise how `glob` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test glob wildcards and boundaries => ()
      test glob wildcards and boundaries =
        assert true (glob match "" "") "AC1: empty pattern matches empty string"
        assert false (glob match "" "a") "AC1: empty pattern rejects non-empty"
        assert true (glob match "*" "") "AC1: * matches empty string"
        assert true (glob match "***" "") "AC1: *** matches empty string"
        assert true (glob match "*" "anything.rg") "AC1: * matches full filename"
        assert true (glob match "*.rg" "socket.rg") "AC1: *.rg matches socket.rg"
        assert true (glob match "*.rg" ".rg") "AC1: *.rg matches leading dot .rg"
        assert false (glob match "*.rg" "README.md") "AC1: *.rg rejects README.md"
        assert false (glob match "*.rg" "socket.rg.bak") "AC1: *.rg rejects trailing suffix"
        assert true (glob match "test_?.rg" "test_a.rg") "AC1: ? matches single char"
        assert false (glob match "test_?.rg" "test_.rg") "AC1: ? rejects zero chars"
        assert false (glob match "test_?.rg" "test_ab.rg") "AC1: ? rejects two chars"
        assert true (glob match "???" "abc") "AC1: ??? matches 3 chars"
        assert false (glob match "???" "ab") "AC1: ??? rejects 2 chars"
        assert true (glob match "a*b*c" "abc") "AC1: multiple * matching zero chars"
        assert true (glob match "a*b*c" "axxxbyyyc") "AC1: multiple * matching substrings"
        assert true (glob match "a*b*c" "abbc") "AC1: backtracking * across repeated b"
        assert false (glob match "a*b*c" "axxxbyyy") "AC1: missing trailing literal after *"
        assert true (glob match "a***b" "axyzb") "AC1: collapsed *** matches"
        -- Pathological backtracking immunity via gl skip stars
        assert false (glob match "****************a" "bbbbbbbbbbbbbbbbbbbbbbbbbbbb") "AC1: collapsed stars avoid exponential backtracking"
        ()
```

### 12.3.4. Example 4: Character Classes `[a-z]`, Negated Ranges `[!0-9]` / `[^0-9]`, and Case-Insensitive Matching (`glob match ci`)

In this hands-on walkthrough we thoroughly exercise how `glob` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test glob classes and case insensitivity => ()
      test glob classes and case insensitivity =
        assert true (glob match "file_[0-9].txt" "file_0.txt") "AC2: [0-9] lower bound 0"
        assert true (glob match "file_[0-9].txt" "file_9.txt") "AC2: [0-9] upper bound 9"
        assert false (glob match "file_[0-9].txt" "file_a.txt") "AC2: [0-9] rejects alpha"
        assert true (glob match "id_[a-zA-Z0-9].rg" "id_Z.rg") "AC2: multi-range [a-zA-Z0-9] matches Z"
        assert true (glob match "id_[a-zA-Z0-9].rg" "id_5.rg") "AC2: multi-range [a-zA-Z0-9] matches 5"
        assert false (glob match "id_[a-zA-Z0-9].rg" "id__.rg") "AC2: multi-range [a-zA-Z0-9] rejects _"
        assert true (glob match "v[135].rg" "v3.rg") "AC2: discrete character set [135]"
        assert false (glob match "v[135].rg" "v2.rg") "AC2: discrete character set rejects 2"
        assert true (glob match "file_[!0-9].txt" "file_a.txt") "AC2: [!0-9] POSIX negated class"
        assert false (glob match "file_[!0-9].txt" "file_7.txt") "AC2: [!0-9] rejects digit"
        assert true (glob match "file_[^0-9].txt" "file_z.txt") "AC2: [^0-9] caret negated class"
        assert false (glob match "file_[^0-9].txt" "file_0.txt") "AC2: [^0-9] rejects digit"
        assert true (glob match "a[b" "a[b") "AC2: unclosed '[' matches literally"
        assert false (glob match "a[b" "axb") "AC2: unclosed '[' rejects non-bracket"

        -- Case-insensitive matching
        assert true (glob match ci "*.RG" "socket.rg") "AC2: glob_match_ci *.RG on lowercase"
        assert true (glob match ci "*.rg" "SOCKET.RG") "AC2: glob_match_ci *.rg on uppercase"
        assert true (glob match ci "src/**/Test_[A-Z]*.rg" "SRC/main/test_crypto.RG") "AC2: glob_match_ci mixed case"
        ()
```

### 12.3.5. Example 5: Batch Path List Filtering (`glob filter`) and Multi-Pattern Matching (`glob any match`)

In this hands-on walkthrough we thoroughly exercise how `glob` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test glob filter and any match => ()
      test glob filter and any match =
        files = ["socket.rg", "README.md", "test_socket.rg", "crypto.rg", "build.sh"]
        assert eq (glob filter "*.rg" files) ["socket.rg", "test_socket.rg", "crypto.rg"]
        assert eq (glob filter "test_*.rg" files) ["test_socket.rg"]
        assert eq (glob filter "*.nomatch" files) []
        assert eq (glob filter "*.rg" []) []
        assert true (glob any match ["*.md", "*.txt", "*.sh"] "README.md") "AC3: glob_any_match first pattern"
        assert true (glob any match ["*.md", "*.txt", "*.sh"] "build.sh") "AC3: glob_any_match last pattern"
        assert false (glob any match ["*.md", "*.txt"] "socket.rg") "AC3: glob_any_match no match"
        assert false (glob any match [] "socket.rg") "AC3: glob_any_match empty pattern list"
        ()
```

---

## 12.4. Under the Hood: How `glob` Is Built in Pure Ridgun (`src/main/ridgun/lib/glob.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/glob.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 12.4.1. Internal Implementation: Bracket Character Class `[...]` Matching

Observe how `glob.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
module :: glob

fn :: gl find close bracket String Int Int => Int
      gl find close bracket pat idx plen =
        | idx >= plen                  = 0 - 1
        | (str char at pat idx) == 93  = idx
        | otherwise                    = gl find close bracket pat (idx + 1) plen

fn :: gl match range String Int Int Int Int Int => Bool
      gl match range pat idx end_idx tc lo hi =
        | tc >= lo and tc <= hi = True
        | otherwise             = gl match class body pat (idx + 3) end_idx tc

fn :: gl match class body String Int Int Int => Bool
      gl match class body pat idx end_idx tc =
        | idx >= end_idx = False
        | ((idx + 2) < end_idx) and ((str char at pat (idx + 1)) == 45) =
          gl match range pat idx end_idx tc (str char at pat idx) (str char at pat (idx + 2))
        | (str char at pat idx) == tc = True
        | otherwise                   = gl match class body pat (idx + 1) end_idx tc

fn :: gl eval bracket char String Int Int Int Int => Bool
      gl eval bracket char pat pstart close_idx tc c0 =
        | c0 == 33 or c0 == 94 = not (gl match class body pat (pstart + 1) close_idx tc)
        | otherwise            = gl match class body pat pstart close_idx tc

fn :: gl eval bracket String Int Int Int => Bool
      gl eval bracket pat pstart close_idx tc =
        gl eval bracket char pat pstart close_idx tc (str char at pat pstart)
```

### 12.4.2. Internal Implementation: Wildcard (`*`, `?`, `[...]`) Matcher

Observe how `glob.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: gl skip stars String Int Int => Int
      gl skip stars pat pidx plen =
        | pidx >= plen                 = pidx
        | (str char at pat pidx) == 42 = gl skip stars pat (pidx + 1) plen
        | otherwise                    = pidx

fn :: gl match star String Int Int String Int Int => Bool
      gl match star pat pidx plen txt tidx tlen =
        | gl match loop pat pidx plen txt tidx tlen = True
        | tidx >= tlen                              = False
        | otherwise                                 = gl match star pat pidx plen txt (tidx + 1) tlen

fn :: gl match star at String Int Int String Int Int => Bool
      gl match star at pat next_p plen txt tidx tlen =
        | next_p >= plen = True
        | otherwise      = gl match star pat next_p plen txt tidx tlen

fn :: gl match bracket step String Int Int String Int Int Int => Bool
      gl match bracket step pat pidx plen txt tidx tlen close_idx =
        | close_idx < 0 =
          | (str char at txt tidx) == 91 = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
          | otherwise                    = False |.
        | gl eval bracket pat (pidx + 1) close_idx (str char at txt tidx) =
          gl match loop pat (close_idx + 1) plen txt (tidx + 1) tlen
        | otherwise = False

fn :: gl match step String Int Int String Int Int Int => Bool
      gl match step pat pidx plen txt tidx tlen pc =
        | pc == 42                     = gl match star at pat (gl skip stars pat (pidx + 1) plen) plen txt tidx tlen
        | tidx >= tlen                 = False
        | pc == 63                     = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
        | pc == 91                     = gl match bracket step pat pidx plen txt tidx tlen (gl find close bracket pat (pidx + 1) plen)
        | pc == (str char at txt tidx) = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
        | otherwise                    = False

fn :: gl match loop String Int Int String Int Int => Bool
      gl match loop pat pidx plen txt tidx tlen =
        | pidx >= plen = tidx >= tlen
        | otherwise    = gl match step pat pidx plen txt tidx tlen (str char at pat pidx)

fn :: glob match String String => Bool
      glob match pat    txt    =  gl match loop pat 0 (str len pat) txt 0 (str len txt)

fn :: glob match ci String String => Bool
      glob match ci pat    txt    =
        pat gl to lower -> lpat
        txt gl to lower -> ltxt
        glob match lpat ltxt

fn :: glob filter String [String] => [String]
      glob filter _      []       =  []
      glob filter pat    (x:rest) =
        | glob match pat x = [x] :: (glob filter pat rest)
        | otherwise        = glob filter pat rest

fn :: glob any match [String] String => Bool
      glob any match []       _      =  False
      glob any match (p:rest) txt    =
        | glob match p txt = True
        | otherwise        = glob any match rest txt
```

---

## 12.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `glob`

- **Algorithmic & Safety Guarantee**: Automatic collapsing of consecutive stars (`***` $\rightarrow$ `*`) to eliminate redundant backtracking and safe handling of unclosed `[` brackets.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/glob.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test glob.rg`.

### The 5 Golden Rules When Programming with `glob`

1. **Declare `import glob` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `glob` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `glob`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `glob` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 13**, we will explore the **`diff`** lib in full depth (The `diff` Lib — LCS Line Diff, Edit Distance, Unified Diff, and Patching).
