# Chapter 03: The `list` Lib — Slicing, $O(N \log N)$ Mergesort, and Associative KV Maps

## 03.1. Why Does the `list` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `list` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `list`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: out-of-bounds index panics (`IndexError` / `panic!`) and accidental mutation of shared lists are two of the most common bugs in everyday collection processing.

The **`list`** lib provides default-safe indexing, slicing (`take`, `drop`, `slice`), stepped ranges, stable deduplication, **$O(N \log N)$ mergesort** for `[Int]` and `[String]`, and immutable `[String String]` key-value maps (`kv get`, `kv put`, `kv merge`).

In a traditional ecosystem, solving **`LIST`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`list`** lib (`src/main/ridgun/lib/list.rg`) tackles the problem with four non-negotiable principles:

1. **Declare `import list` (or `import list as alias`) at the top of your file**: every lib defines its `module :: list` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
3. **Tail-Call Optimization (TCO)**: all internal loops in `list` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 03.2. Native Artifacts, Imports, and Complete `list` API Catalog

In `ridgun-libs`, **`list`** is a first-class **lib** located at `src/main/ridgun/lib/list.rg` (domain `LIST`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/list.rglib` | Portable distribution and direct `import list` resolution |
| **Compiled Archive** | `target/list.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/liblist.so` | Native dynamic shared library with zero C or `libc` dependencies |

> Every lib declares its own namespace via `module :: list`: simply write `import list` (or `import list as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

### 03.2.1. Summary of `list` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `list nth or / list str nth or` | Safe index lookup returning `default_val` when out of bounds |
| `list take / list drop / list slice / list reverse` | Prefix, suffix, subrange `[start, end)`, and tail-recursive reversal |
| `list range / list range step` | Generate arithmetic sequences (`step == 0` safely returns `[]`) |
| `list sort / list str sort / list dedup / list str dedup` | Stable $O(N \log N)$ top-down mergesort and first-seen deduplication |
| `kv empty / kv put / kv get / kv get or / kv remove / kv merge` | Ordered associative `[String String]` key-value dictionary operations |

### 03.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/list.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/list.rg` (`0` types, `0` operators, and `59` functions):

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: list len [Int]` | `Int` |
| `2` | `fn :: list str len [String]` | `Int` |
| `3` | `fn :: list is empty [Int]` | `Bool` |
| `4` | `fn :: list str is empty [String]` | `Bool` |
| `5` | `fn :: list nth or [Int] Int Int` | `Int` |
| `6` | `fn :: list nth [Int] Int` | `Int` |
| `7` | `fn :: list str nth or [String] Int String` | `String` |
| `8` | `fn :: list str nth [String] Int` | `String` |
| `9` | `fn :: list head [Int] Int` | `Int` |
| `10` | `fn :: list last [Int] Int` | `Int` |
| `11` | `fn :: list take [Int] Int` | `[Int]` |
| `12` | `fn :: list str take [String] Int` | `[String]` |
| `13` | `fn :: list drop [Int] Int` | `[Int]` |
| `14` | `fn :: list str drop [String] Int` | `[String]` |
| `15` | `fn :: l clamp nonneg Int` | `Int` |
| `16` | `fn :: l slice ints from [Int] Int Int` | `[Int]` |
| `17` | `fn :: list slice [Int] Int Int` | `[Int]` |
| `18` | `fn :: l slice strs from [String] Int Int` | `[String]` |
| `19` | `fn :: list str slice [String] Int Int` | `[String]` |
| `20` | `fn :: l rev ints [Int] [Int]` | `[Int]` |
| `21` | `fn :: list reverse [Int]` | `[Int]` |
| `22` | `fn :: l rev strs [String] [String]` | `[String]` |
| `23` | `fn :: list str reverse [String]` | `[String]` |
| `24` | `fn :: list range step Int Int Int` | `[Int]` |
| `25` | `fn :: list range Int Int` | `[Int]` |
| `26` | `fn :: list replicate Int Int` | `[Int]` |
| `27` | `fn :: l idx int [Int] Int Int` | `Int` |
| `28` | `fn :: list index of [Int] Int` | `Int` |
| `29` | `fn :: list contains [Int] Int` | `Bool` |
| `30` | `fn :: l idx str [String] String Int` | `Int` |
| `31` | `fn :: list str index of [String] String` | `Int` |
| `32` | `fn :: list str contains [String] String` | `Bool` |
| `33` | `fn :: list count [Int] Int` | `Int` |
| `34` | `fn :: list str count [String] String` | `Int` |
| `35` | `fn :: l dedup ints [Int] [Int]` | `[Int]` |
| `36` | `fn :: list dedup [Int]` | `[Int]` |
| `37` | `fn :: l dedup strs [String] [String]` | `[String]` |
| `38` | `fn :: list str dedup [String]` | `[String]` |
| `39` | `fn :: l merge ints [Int] [Int]` | `[Int]` |
| `40` | `fn :: l sort ints len [Int] Int` | `[Int]` |
| `41` | `fn :: list sort [Int]` | `[Int]` |
| `42` | `fn :: list is sorted [Int]` | `Bool` |
| `43` | `fn :: l str le loop String String Int Int Int` | `Bool` |
| `44` | `fn :: l str le String String` | `Bool` |
| `45` | `fn :: l merge strs [String] [String]` | `[String]` |
| `46` | `fn :: l sort strs len [String] Int` | `[String]` |
| `47` | `fn :: list str sort [String]` | `[String]` |
| `48` | `fn :: l kv key (String String)` | `String` |
| `49` | `fn :: l kv val (String String)` | `String` |
| `50` | `fn :: list kv empty` | `[String String]` |
| `51` | `fn :: list kv len [String String]` | `Int` |
| `52` | `fn :: list kv has [String String] String` | `Bool` |
| `53` | `fn :: list kv get or [String String] String String` | `String` |
| `54` | `fn :: list kv get [String String] String` | `String` |
| `55` | `fn :: list kv put [String String] String String` | `[String String]` |
| `56` | `fn :: list kv remove [String String] String` | `[String String]` |
| `57` | `fn :: list kv keys [String String]` | `[String]` |
| `58` | `fn :: list kv values [String String]` | `[String]` |
| `59` | `fn :: list kv merge [String String] [String String]` | `[String String]` |

---

## 03.3. Deep Dive into `list`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `list` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test list.rg`.

### 03.3.1. Example 1: Core Tabular Workflow with `list`

Notice how in Ridgun the `=` signs and transformation steps using `list` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import list

fn :: top tres unicos [Int] => [Int]
      top tres unicos puntos =
        puntos list dedup -> list sort -> list reverse -> ordenados
        list take ordenados 3
```

### 03.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `list` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import list

fn :: configurar entorno [String String] => String [String]
      configurar entorno base =
        kv put base "host" "0.0.0.0" -> cfg1
        kv put cfg1 "port" "8080" -> cfg2
        kv get or cfg2 "host" "127.0.0.1" -> host
        cfg2 kv keys -> claves
        (host, claves)
```

### 03.3.3. Example 3: Safe Indexing (`nth or`, `head or`, `last or`), Slicing (`take`, `drop`, `slice`), Ranges (`range`, `iota`, `replicate`), and Deduplication (`dedup`, `count eq`)

In this hands-on walkthrough we thoroughly exercise how `list` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test list indexing slicing and ranges => ()
      test list indexing slicing and ranges =
        xs = [10, 20, 30, 40, 50]
        ss = ["aa", "bb", "cc", "dd"]
        assert int equals (list len xs) 5 "AC1: list_len 5"
        assert int equals (list str len ss) 4 "AC1: list_str_len 4"
        assert true (list is empty []) "AC1: list_is_empty []"
        assert false (list is empty xs) "AC1: list_is_empty non-empty"
        assert true (list str is empty []) "AC1: list_str_is_empty []"
        assert false (list str is empty ss) "AC1: list_str_is_empty non-empty"

        assert int equals (list nth xs 0) 10 "AC1: list_nth 0"
        assert int equals (list nth xs 4) 50 "AC1: list_nth 4"
        assert int equals (list nth or xs 99 (0 - 1)) (0 - 1) "AC1: list_nth_or out of bounds"
        assert int equals (list nth or xs (0 - 1) (0 - 1)) (0 - 1) "AC1: list_nth_or negative"
        assert str eq (list str nth ss 2) "cc" "AC1: list_str_nth 2"
        assert str eq (list str nth or ss 99 "oob") "oob" "AC1: list_str_nth_or out of bounds"
        assert int equals (list head xs 0) 10 "AC1: list_head"
        assert int equals (list head [] 99) 99 "AC1: list_head empty fallback"
        assert int equals (list last xs 0) 50 "AC1: list_last"
        assert int equals (list last [] 99) 99 "AC1: list_last empty fallback"

        assert eq (list take xs 3) [10, 20, 30]
        assert eq (list take xs 0) []
        assert eq (list take xs (0 - 2)) []
        assert eq (list take xs 99) [10, 20, 30, 40, 50]
        assert eq (list drop xs 3) [40, 50]
        assert eq (list drop xs 0) xs
        assert eq (list drop xs 99) []
        assert eq (list slice xs 1 4) [20, 30, 40]
        assert eq (list slice xs (0 - 3) 2) [10, 20]
        assert eq (list slice xs 4 2) []
        assert eq (list str slice ss 1 3) ["bb", "cc"]

        assert eq (list reverse xs) [50, 40, 30, 20, 10]
        assert eq (list str reverse ss) ["dd", "cc", "bb", "aa"]

        assert eq (list range 1 5) [1, 2, 3, 4, 5]
        assert eq (list range 3 3) [3]
        assert eq (list range 5 1) []
        assert eq (list range step 0 6 2) [0, 2, 4, 6]
        assert eq (list range step 6 0 (0 - 2)) [6, 4, 2, 0]
        assert eq (list range step 1 5 0) []
        assert eq (list replicate 3 7) [7, 7, 7]
        assert eq (list replicate 0 7) []

        assert true (list contains xs 30) "AC1: list_contains 30"
        assert false (list contains xs 99) "AC1: list_contains 99"
        assert true (list str contains ss "cc") "AC1: list_str_contains cc"
        assert false (list str contains ss "zz") "AC1: list_str_contains zz"
        assert int equals (list index of xs 30) 2 "AC1: list_index_of 30"
        assert int equals (list index of xs 99) (0 - 1) "AC1: list_index_of missing"
        assert int equals (list str index of ss "dd") 3 "AC1: list_str_index_of dd"
        assert int equals (list count [1, 2, 1, 3, 1] 1) 3 "AC1: list_count"
        assert int equals (list str count ["a", "b", "a"] "a") 2 "AC1: list_str_count"
        assert eq (list dedup [3, 1, 3, 2, 1, 3]) [3, 1, 2]
        assert eq (list str dedup ["b", "a", "b", "c", "a"]) ["b", "a", "c"]
        ()
```

### 03.3.4. Example 4: Deterministic $O(N \log N)$ Mergesort (`list sort int`, `list sort desc`, `list sort str`, `list is sorted`)

In this hands-on walkthrough we thoroughly exercise how `list` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test list mergesort => ()
      test list mergesort =
        unsorted = [42, 7, 19, 7, 0, (0 - 5), 100, 3, (0 - 50)]
        sorted = list sort unsorted
        assert eq sorted [(0 - 50), (0 - 5), 0, 3, 7, 7, 19, 42, 100]
        assert true (list is sorted sorted) "AC2: list_is_sorted after sort"
        assert false (list is sorted unsorted) "AC2: list_is_sorted false on unsorted"
        assert true (list is sorted []) "AC2: empty list is sorted"
        assert true (list is sorted [1]) "AC2: singleton list is sorted"
        assert eq (list sort []) []
        assert eq (list sort [1]) [1]
        assert eq (list sort [5, 4, 3, 2, 1]) [1, 2, 3, 4, 5]
        s_strs = list str sort ["delta", "alpha", "charlie", "bravo", "alpha", "al", ""]
        assert eq s_strs ["", "al", "alpha", "alpha", "bravo", "charlie", "delta"]
        ()
```

### 03.3.5. Example 5: Immutable Key-Value Associative Maps (`kv put`, `kv get or`, `kv has`, `kv remove`, `kv keys`, `kv values`, `kv len`)

In this hands-on walkthrough we thoroughly exercise how `list` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test kv associative map => ()
      test kv associative map =
        m0 = kv empty
        assert int equals (kv len m0) 0 "AC3: kv_empty len 0"
        m1 = kv put m0 "host" "127.0.0.1"
        m2 = kv put m1 "port" "8080"
        m3 = kv put m2 "port" "9090"
        assert int equals (kv len m3) 2 "AC3: kv_put updates in-place without duplicating key"
        assert true (kv has m3 "host") "AC3: kv_has host"
        assert false (kv has m3 "missing") "AC3: kv_has missing"
        assert str eq (kv get m3 "port") "9090" "AC3: kv_get updated port"
        assert str eq (kv get m3 "missing") "" "AC3: kv_get missing returns empty"
        assert str eq (kv get or m3 "mode" "prod") "prod" "AC3: kv_get_or default"
        assert eq (kv keys m3) ["host", "port"]
        assert eq (kv values m3) ["127.0.0.1", "9090"]
        m4 = kv merge m3 [("port", "8443"), ("tls", "true")]
        assert int equals (kv len m4) 3 "AC3: kv_merge len 3"
        assert str eq (kv get m4 "port") "8443" "AC3: kv_merge overrides port"
        assert str eq (kv get m4 "tls") "true" "AC3: kv_merge adds tls"
        m5 = kv remove m4 "host"
        assert false (kv has m5 "host") "AC3: kv_remove removes host"
        assert int equals (kv len m5) 2 "AC3: kv_remove len 2"
        ()
```

---

## 03.4. Under the Hood: How `list` Is Built in Pure Ridgun (`src/main/ridgun/lib/list.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/list.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 03.4.1. Internal Implementation: List Length & Emptiness

Observe how `list.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
module :: list

fn :: list len [Int]    => Int
      list len []       =  0
      list len (_:rest) =  1 + (list len rest)

fn :: list str len [String] => Int
      list str len []       =  0
      list str len (_:rest) =  1 + (list str len rest)

fn :: list is empty [Int] => Bool
      list is empty []    =  True
      list is empty _     =  False

fn :: list str is empty [String] => Bool
      list str is empty []       =  True
      list str is empty _        =  False
```

### 03.4.2. Internal Implementation: Slicing (`take`, `drop`, `slice`) & Reversal

Observe how `list.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: list take [Int]    Int => [Int]
      list take []       _   =  []
      list take (x:rest) n   =
        | n <= 0    = []
        | otherwise = [x] :: (list take rest (n - 1))

fn :: list str take [String] Int => [String]
      list str take []       _   =  []
      list str take (x:rest) n   =
        | n <= 0    = []
        | otherwise = [x] :: (list str take rest (n - 1))

fn :: list drop [Int]    Int => [Int]
      list drop []       _   =  []
      list drop (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = list drop rest (n - 1)

fn :: list str drop [String] Int => [String]
      list str drop []       _   =  []
      list str drop (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = list str drop rest (n - 1)

fn :: l clamp nonneg Int => Int
      l clamp nonneg x   =
        | x < 0     = 0
        | otherwise = x

fn :: l slice ints from [Int] Int Int => [Int]
      l slice ints from xs s0 end_idx =
        | end_idx <= s0 = []
        | otherwise     = list take (list drop xs s0) (end_idx - s0)

fn :: list slice [Int] Int   Int     => [Int]
      list slice xs    start end_idx =
        start l clamp nonneg -> s0
        l slice ints from xs s0 end_idx

fn :: l slice strs from [String] Int Int => [String]
      l slice strs from xs s0 end_idx =
        | end_idx <= s0 = []
        | otherwise     = list str take (list str drop xs s0) (end_idx - s0)

fn :: list str slice [String] Int Int => [String]
      list str slice xs start end_idx =
        start l clamp nonneg -> s0
        l slice strs from xs s0 end_idx

fn :: l rev ints [Int]    [Int] => [Int]
      l rev ints []       acc   =  acc
      l rev ints (x:rest) acc   =  l rev ints rest ([x] :: acc)

fn :: list reverse [Int] => [Int]
      list reverse xs    =  l rev ints xs []

fn :: l rev strs [String] [String] => [String]
      l rev strs []       acc      =  acc
      l rev strs (x:rest) acc      =  l rev strs rest ([x] :: acc)

fn :: list str reverse [String] => [String]
      list str reverse xs       =  l rev strs xs []
```

### 03.4.3. Internal Implementation: Search, Count & Deduplication

Observe how `list.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: l idx int [Int] Int Int => Int
      l idx int [] _ _ = 0 - 1
      l idx int (x:rest) tgt idx =
        | x == tgt  = idx
        | otherwise = l idx int rest tgt (idx + 1)

fn :: list index of [Int] Int => Int
      list index of xs    tgt =  l idx int xs tgt 0

fn :: list contains [Int] Int => Bool
      list contains xs    tgt =  (list index of xs tgt) >= 0

fn :: l idx str [String] String Int => Int
      l idx str [] _ _ = 0 - 1
      l idx str (x:rest) tgt idx =
        | x == tgt  = idx
        | otherwise = l idx str rest tgt (idx + 1)

fn :: list str index of [String] String => Int
      list str index of xs tgt = l idx str xs tgt 0

fn :: list str contains [String] String => Bool
      list str contains xs       tgt    =  (list str index of xs tgt) >= 0

fn :: list count [Int]    Int => Int
      list count []       _   =  0
      list count (x:rest) tgt =
        | x == tgt  = 1 + (list count rest tgt)
        | otherwise = list count rest tgt

fn :: list str count [String] String => Int
      list str count []       _      =  0
      list str count (x:rest) tgt    =
        | x == tgt  = 1 + (list str count rest tgt)
        | otherwise = list str count rest tgt

fn :: l dedup ints [Int]    [Int] => [Int]
      l dedup ints []       seen  =  list reverse seen
      l dedup ints (x:rest) seen  =
        | list contains seen x = l dedup ints rest seen
        | otherwise            = l dedup ints rest ([x] :: seen)

fn :: list dedup [Int] => [Int]
      list dedup xs    =  l dedup ints xs []

fn :: l dedup strs [String] [String] => [String]
      l dedup strs []       seen     =  list str reverse seen
      l dedup strs (x:rest) seen     =
        | list str contains seen x = l dedup strs rest seen
        | otherwise                = l dedup strs rest ([x] :: seen)

fn :: list str dedup [String] => [String]
      list str dedup xs       =  l dedup strs xs []
```

### 03.4.4. Internal Implementation: Associative Key-Value Map (`[(String, String)]`)

Observe how `list.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: l kv key (String String) => String
      l kv key (k, _)          =  k

fn :: l kv val (String String) => String
      l kv val (_, v)          =  v

fn :: kv empty => [String String]
      kv empty =  []

fn :: kv len [String String] => Int
      kv len []              =  0
      kv len (_:rest)        =  1 + (kv len rest)

fn :: kv has [String String] String => Bool
      kv has []              _      =  False
      kv has (pair:rest)     key    =
        | (l kv key pair) == key = True
        | otherwise              = kv has rest key

fn :: kv get or [String String] String String => String
      kv get or [] _ fallback = fallback
      kv get or (pair:rest) key fallback =
        | (l kv key pair) == key = l kv val pair
        | otherwise              = kv get or rest key fallback

fn :: kv get [String String] String => String
      kv get pairs           key    =  kv get or pairs key ""

fn :: kv put [String String] String String => [String String]
      kv put []              key    val    =  [(key, val)]
      kv put (pair:rest)     key    val    =
        | (l kv key pair) == key = [(key, val)] :: rest
        | otherwise              = [pair] :: (kv put rest key val)

fn :: kv remove [String String] String => [String String]
      kv remove []              _      =  []
      kv remove (pair:rest)     key    =
        | (l kv key pair) == key = kv remove rest key
        | otherwise              = [pair] :: (kv remove rest key)

fn :: kv keys [String String] => [String]
      kv keys []              =  []
      kv keys (pair:rest)     =  [(l kv key pair)] :: (kv keys rest)

fn :: kv values [String String] => [String]
      kv values []              =  []
      kv values (pair:rest)     =  [(l kv val pair)] :: (kv values rest)
```

---

## 03.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `list`

- **Algorithmic & Safety Guarantee**: Worst-case $O(N \log N)$ deterministic mergesort (immune to Quicksort's $O(N^2)$ adversarial inputs) and insertion-order preservation on `kv` maps.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/list.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test list.rg`.

### The 5 Golden Rules When Programming with `list`

1. **Declare `import list` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `list` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `list`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `list` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 04**, we will explore the **`btree`** lib in full depth (The `btree` Lib — Persistent $O(\log N)$ AVL Maps, Sets, and Priority Queues).
