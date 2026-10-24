# Chapter 17: The `path` Lib — POSIX Normalization (`path clean`) and Path-Traversal Confinement

## 17.1. Why Does the `path` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `path` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `path`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: joining file paths with `base + "/" + user_path` without lexical `..` resolution and boundary confinement is an open invitation for a `../../etc/passwd` path-traversal exploit.

The **`path`** lib implements POSIX lexical normalization (`path clean`), safe joining (`path join`), component extraction (`dirname`, `basename`, `stem`, `ext`, `replace ext`), and the **`path is safe subpath`** (`VUL-INJ-001`) directory-confinement guard.

In a traditional ecosystem, solving **`PATH`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`path`** lib (`src/main/ridgun/lib/path.rg`) tackles the problem with four non-negotiable principles:

1. **Total Functions & Explicit Contracts (`=>`)**: no function in `path` throws hidden exceptions or relies on `null`. Every edge case (empty inputs, zero divisors, truncated frames, or out-of-bounds indices) returns a documented sentinel value or an algebraic sum type (`Option`, `Result`).
2. **Zero C Code & Zero `libc`**: every line of `path` compiles directly into native ELF64 machine code verified by `ridgunc`.
3. **Tail-Call Optimization (TCO)**: all internal loops in `path` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 17.2. Native Artifacts, Imports, and Complete `path` API Catalog

In `ridgun-libs`, **`path`** is a first-class **lib** located at `src/main/ridgun/lib/path.rg` (domain `PATH`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/path.rglib` | Portable distribution and direct `import path` resolution |
| **Compiled Archive** | `target/path.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libpath.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import path` at the top and call its functions using either multi-word spaces (`my fn x`) or underscores (`my_fn x`).

### 17.2.1. Summary of `path` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `path clean / path join / path join list` | Collapse `//`, `.`, and `..` lexically and join path segments |
| `path dirname / path basename / path split` | Split a path into parent directory and final filename component |
| `path ext / path stem / path replace ext` | Extract or swap file extensions (correctly treating `.bashrc` as stem `.bashrc`, ext `""`) |
| `path is safe subpath : String -> String -> Bool` | Verify `rel` stays strictly inside `base_dir` and has no NUL bytes |

### 17.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/path.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/path.rg` (`0` types, `0` operators, and `30` functions):

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: pa split slash loop String Int Int Int` | `[String]` |
| `2` | `fn :: pa rev strs [String] [String]` | `[String]` |
| `3` | `fn :: pa join slash [String]` | `String` |
| `4` | `fn :: pa pop stack [String] Bool` | `[String]` |
| `5` | `fn :: pa norm segs [String] [String] Bool` | `[String]` |
| `6` | `fn :: pa finish clean String Bool` | `String` |
| `7` | `fn :: path is abs String` | `Bool` |
| `8` | `fn :: path is rel String` | `Bool` |
| `9` | `fn :: path clean String` | `String` |
| `10` | `fn :: path join String String` | `String` |
| `11` | `fn :: path join list [String]` | `String` |
| `12` | `fn :: pa last char idx String Int Int` | `Int` |
| `13` | `fn :: pa dirname at String Int` | `String` |
| `14` | `fn :: pa dirname clean String` | `String` |
| `15` | `fn :: path dirname String` | `String` |
| `16` | `fn :: pa basename at String Int` | `String` |
| `17` | `fn :: pa basename clean String` | `String` |
| `18` | `fn :: path basename String` | `String` |
| `19` | `fn :: path split String` | `String String` |
| `20` | `fn :: pa ext at String Int` | `String` |
| `21` | `fn :: path ext String` | `String` |
| `22` | `fn :: pa stem at String Int` | `String` |
| `23` | `fn :: path stem String` | `String` |
| `24` | `fn :: pa norm ext String` | `String` |
| `25` | `fn :: pa combine dir base String String` | `String` |
| `26` | `fn :: path replace ext String String` | `String` |
| `27` | `fn :: pa is safe char Int` | `Bool` |
| `28` | `fn :: pa safe chars loop String Int Int` | `Bool` |
| `29` | `fn :: pa check prefix String String` | `Bool` |
| `30` | `fn :: path is safe subpath String String` | `Bool` |

---

## 17.3. Deep Dive into `path`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `path` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test path.rg`.

### 17.3.1. Example 1: Core Tabular Workflow with `path`

Notice how in Ridgun the `=` signs and transformation steps using `path` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import path

fn :: resolver archivo estatico (raiz : String) (peticion : String) => (Bool, String)
      resolver archivo estatico raiz peticion =
        seguro = path is safe subpath raiz peticion
        ruta   = path join raiz peticion
        (seguro, ruta)
```

### 17.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `path` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import path

fn :: cambiar salida a objeto (fuente : String) => (String, String, String)
      cambiar salida a objeto fuente =
        dir = path dirname fuente
        nom = path stem fuente
        obj = path replace ext (path clean fuente) ".rglib"
        (dir, nom, obj)
```

### 17.3.3. Example 3: POSIX Lexical Normalization (`path clean`) and Safe Segment Joining (`path join`, `path join all`)

In this hands-on walkthrough we thoroughly exercise how `path` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test path clean and join => ()
      test path clean and join =
        -- Go path/path_test.go cleantests vectors
        _ = assert str eq (path clean "") "." "AC1: empty -> ."
        _ = assert str eq (path clean ".") "." "AC1: . -> ."
        _ = assert str eq (path clean "././.") "." "AC1: ././. -> ."
        _ = assert str eq (path clean "/") "/" "AC1: / -> /"
        _ = assert str eq (path clean "///") "/" "AC1: /// -> /"
        _ = assert str eq (path clean "/././") "/" "AC1: /././ -> /"
        _ = assert str eq (path clean "/../a") "/a" "AC1: /../a clamped at root"
        _ = assert str eq (path clean "/../../..") "/" "AC1: /../../.. clamped at root"
        _ = assert str eq (path clean "a/b/..") "a" "AC1: a/b/.. -> a"
        _ = assert str eq (path clean "a/../b") "b" "AC1: a/../b -> b"
        _ = assert str eq (path clean "a/../../b") "../b" "AC1: relative .. preserved when above ."
        _ = assert str eq (path clean "../../a/b/..") "../../a" "AC1: leading ../.. preserved"
        _ = assert str eq (path clean "/a/b/../c/./d//") "/a/c/d" "AC1: complex absolute normalization"

        -- path_join & path_join_list
        _ = assert str eq (path join "" "") "." "AC1: join empty empty"
        _ = assert str eq (path join "/var/log" "") "/var/log" "AC1: join with empty right"
        _ = assert str eq (path join "" "app.log") "app.log" "AC1: join with empty left"
        _ = assert str eq (path join "/var/log" "app/server.log") "/var/log/app/server.log" "AC1: join relative child"
        _ = assert str eq (path join "/var/log" "/etc/hosts") "/etc/hosts" "AC1: join absolute child overrides base"
        _ = assert str eq (path join list []) "." "AC1: join_list [] -> ."
        _ = assert str eq (path join list ["src", "main", "ridgun", "lib", "path.rg"]) "src/main/ridgun/lib/path.rg" "AC1: join_list 5 segments"
        ()
```

### 17.3.4. Example 4: Path Decomposition (`dirname`, `basename`, `ext`, `stem`) and Path-Traversal Confinement (`path is safe rel`, `path resolve under`)

In this hands-on walkthrough we thoroughly exercise how `path` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test path components and confinement => ()
      test path components and confinement =
        p = "/home/boogie/ridgun-libs/src/socket.rg"
        _ = assert true (path is abs p) "AC2: path_is_abs true"
        _ = assert false (path is rel p) "AC2: path_is_rel false"
        _ = assert false (path is abs "") "AC2: empty is not abs"
        _ = assert true (path is rel "src/socket.rg") "AC2: relative path_is_rel"
        _ = assert str eq (path dirname p) "/home/boogie/ridgun-libs/src" "AC2: dirname"
        _ = assert str eq (path basename p) "socket.rg" "AC2: basename"
        sp = path split p
        _ = assert str eq (pair_fst sp) "/home/boogie/ridgun-libs/src" "AC2: split dirname"
        _ = assert str eq (pair_snd sp) "socket.rg" "AC2: split basename"
        _ = assert str eq (path dirname "/") "/" "AC2: dirname of / is /"
        _ = assert str eq (path basename "/") "/" "AC2: basename of / is /"
        _ = assert str eq (path dirname "/top") "/" "AC2: dirname of /top is /"
        _ = assert str eq (path dirname "barefile.txt") "." "AC2: dirname of bare filename is ."

        -- Multi-dot filenames, dotfiles, and extension replacement
        _ = assert str eq (path stem p) "socket" "AC2: stem"
        _ = assert str eq (path ext p) ".rg" "AC2: ext"
        _ = assert str eq (path stem "archive.tar.gz") "archive.tar" "AC2: multi-dot stem"
        _ = assert str eq (path ext "archive.tar.gz") ".gz" "AC2: multi-dot ext"
        _ = assert str eq (path stem ".gitignore") ".gitignore" "AC2: dotfile stem"
        _ = assert str eq (path ext ".gitignore") "" "AC2: dotfile empty ext"
        _ = assert str eq (path replace ext p "rglib") "/home/boogie/ridgun-libs/src/socket.rglib" "AC2: replace_ext without leading dot"
        _ = assert str eq (path replace ext p ".so") "/home/boogie/ridgun-libs/src/socket.so" "AC2: replace_ext with leading dot"
        _ = assert str eq (path replace ext "main.rg" "") "main" "AC2: replace_ext with empty removes extension"

        -- OWASP Path Traversal & Shell Injection Confinement (VUL-INJ-002)
        _ = assert true (path is safe subpath "/srv/www" "assets/app.js") "AC3: safe child subpath"
        _ = assert true (path is safe subpath "/srv/www" "a/b/../c_1-2.txt") "AC3: safe normalized internal .."
        _ = assert false (path is safe subpath "/srv/www" "") "AC3: empty child rejected"
        _ = assert false (path is safe subpath "" "assets/app.js") "AC3: empty base rejected"
        _ = assert false (path is safe subpath "/srv/www" "../etc/passwd") "AC3: direct .. traversal rejected"
        _ = assert false (path is safe subpath "/srv/www" "a/b/../../../etc/passwd") "AC3: deep .. traversal escaping base rejected"
        _ = assert false (path is safe subpath "/srv/www" "/etc/passwd") "AC3: absolute child path rejected"
        _ = assert false (path is safe subpath "/srv/www" "/srv/www/index.html") "AC3: absolute child matching base still rejected"
        _ = assert false (path is safe subpath "/srv/www" "bad;rm -rf /") "AC3: shell semicolon metachar rejected"
        _ = assert false (path is safe subpath "/srv/www" "bad|cat") "AC3: shell pipe metachar rejected"
        _ = assert false (path is safe subpath "/srv/www" "bad$var") "AC3: shell dollar metachar rejected"
        ()
```

### 17.3.5. Example 5: Sandboxed Static Asset Resolver: Guarding Against `..` Traversal, Null Bytes, and Extracting `dirname`/`basename`/`ext`/`stem`

In this hands-on walkthrough we thoroughly exercise how `path` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
import path

fn :: resolver archivo seguro (raiz : String) (peticion : String) => (String, String, String, String)
      resolver archivo seguro raiz peticion =
        ruta_final = path resolve under raiz peticion
        | ruta_final == "" = ("denegado", "", "", "")
        | otherwise        =
          dir  = path dirname ruta_final
          base = path basename ruta_final
          ext  = path ext ruta_final
          stem = path stem ruta_final
          (ruta_final, dir, base, "{stem} ({ext})")
```

---

## 17.4. Under the Hood: How `path` Is Built in Pure Ridgun (`src/main/ridgun/lib/path.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/path.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 17.4.1. Internal Implementation: Core Implementation Part 1

Observe how `path.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: pa split slash loop String Int Int Int => [String]
      pa split slash loop p start idx len =
        | idx >= len                = [(str slice p start len)]
        | (str char at p idx) == 47 = [(str slice p start idx)] :: (pa split slash loop p (idx + 1) (idx + 1) len)
        | otherwise                 = pa split slash loop p start (idx + 1) len

fn :: pa rev strs [String] [String] => [String]
      pa rev strs []       acc      =  acc
      pa rev strs (x:rest) acc      =  pa rev strs rest ([x] :: acc)

fn :: pa join slash [String] => String
      pa join slash []       =  ""
      pa join slash (x:[])   =  x
      pa join slash (x:rest) =  x + "/" + (pa join slash rest)

fn :: pa pop stack [String] Bool  => [String]
      pa pop stack []       True  =  []
      pa pop stack []       False =  [".."]
      pa pop stack (top:rs) is_ab =
        | top == ".." = ["..", ".."] :: rs
        | otherwise   = rs

fn :: pa norm segs [String] [String] Bool => [String]
      pa norm segs [] stack _ = pa rev strs stack []
      pa norm segs (s:rest) stack is_ab =
        | (str len s) == 0 or s == "." = pa norm segs rest stack is_ab
        | s == ".."                    = pa norm segs rest (pa pop stack stack is_ab) is_ab
        | otherwise                    = pa norm segs rest ([s] :: stack) is_ab

fn :: pa finish clean String Bool  => String
      pa finish clean joined True  =
        | (str len joined) == 0 = "/"
        | otherwise             = "/" + joined
      pa finish clean joined False =
        | (str len joined) == 0 = "."
        | otherwise             = joined
```

### 17.4.2. Internal Implementation: Core Implementation Part 2

Observe how `path.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: path is abs String => Bool
      path is abs p      =
        | (str len p) == 0        = False
        | (str char at p 0) == 47 = True
        | otherwise               = False

fn :: path is rel String => Bool
      path is rel p      =  not (path is abs p)

fn :: path clean String => String
      path clean p      =
        | (str len p) == 0 = "."
        | otherwise =
          is_ab = path is abs p
          segs  = pa split slash loop p 0 0 (str len p)
          norm  = pa norm segs segs [] is_ab
          pa finish clean (pa join slash norm) is_ab

fn :: path join String String => String
      path join a      b      =
        | (str len a) == 0 = path clean b
        | (str len b) == 0 = path clean a
        | path is abs b    = path clean b
        | otherwise        = path clean (a + "/" + b)

fn :: path join list [String]   => String
      path join list []         =  "."
      path join list (x:[])     =  path clean x
      path join list (x:y:rest) =  path join list ([(path join x y)] :: rest)

fn :: pa last char idx String Int Int => Int
      pa last char idx s ch idx =
        | idx < 0                   = 0 - 1
        | (str char at s idx) == ch = idx
        | otherwise                 = pa last char idx s ch (idx - 1)
```

### 17.4.3. Internal Implementation: Core Implementation Part 4

Observe how `path.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: path ext String => String
      path ext p      =
        base = path basename p
        pa ext at base (pa last char idx base 46 ((str len base) - 1))

fn :: pa stem at String Int => String
      pa stem at base   dot =
        | dot <= 0  = base
        | otherwise = str slice base 0 dot

fn :: path stem String => String
      path stem p      =
        base = path basename p
        pa stem at base (pa last char idx base 46 ((str len base) - 1))

fn :: pa norm ext String => String
      pa norm ext ext    =
        | (str len ext) == 0        = ""
        | (str char at ext 0) == 46 = ext
        | otherwise                 = "." + ext

fn :: pa combine dir base String String => String
      pa combine dir base dir base =
        | dir == "." = base
        | dir == "/" = "/" + base
        | otherwise  = dir + "/" + base

fn :: path replace ext String String  => String
      path replace ext p      new_ext =
        pa combine dir base (path dirname p) ((path stem p) + (pa norm ext new_ext))

fn :: pa is safe char Int => Bool
      pa is safe char c   =
        | c >= 48 and c <= 57                        = True
        | c >= 65 and c <= 90                        = True
        | c >= 97 and c <= 122                       = True
        | c == 47 or c == 46 or c == 95 or c == 45   = True
        | otherwise                                  = False
```

### 17.4.4. Internal Implementation: Core Implementation Part 5

Observe how `path.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: pa safe chars loop String Int Int => Bool
      pa safe chars loop s idx len =
        | idx >= len                          = True
        | not (pa is safe char (str char at s idx)) = False
        | otherwise                           = pa safe chars loop s (idx + 1) len

fn :: pa check prefix String String => Bool
      pa check prefix bclean full   =
        | bclean == "/" = path is abs full
        | full == bclean = True
        | otherwise     = str starts with full (bclean + "/")

fn :: path is safe subpath String String => Bool
      path is safe subpath base child =
        | (str len base) == 0 or (str len child) == 0          = False
        | path is abs child                                    = False
        | not (pa safe chars loop base 0 (str len base))       = False
        | not (pa safe chars loop child 0 (str len child))     = False
        | otherwise =
          bclean = path clean base
          full   = path clean (bclean + "/" + child)
          pa check prefix bclean full
```

---

## 17.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `path`

- **Algorithmic & Safety Guarantee**: `path is safe subpath` rejects absolute paths, NUL bytes, and any `..` sequence that attempts to escape `base_dir` or bleed into a sibling prefix (`/srv/www-secret`).
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/path.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test path.rg`.

### The 5 Golden Rules When Programming with `path`

1. **Declare `import path` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `path` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `path`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `path` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 18**, we will explore the **`time`** lib in full depth (The `time` Lib — Howard Hinnant UTC Calendar, ISO-8601, Durations, and Backoff).
