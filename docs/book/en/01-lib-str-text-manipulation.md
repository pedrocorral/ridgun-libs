# Chapter 01: The `str` Lib — Text Manipulation, Search, and Tabular Padding

## 01.1. Why Does the `str` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `str` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `str`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: manipulating strings in C with `strtok` and `strncpy` is a minefield of buffer overflows and null pointers, while in higher-level languages you often pull in external packages just to pad tabular output or repeat a delimiter in $O(\log N)$.

The **`str`** lib provides pure, immutable primitives for searching, trimming, splitting, joining, ASCII case conversion, $O(\log N)$ binary-doubling repetition, and column padding.

In a traditional ecosystem, solving **`STR`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`str`** lib (`src/main/ridgun/lib/str.ridgun`) tackles the problem with four non-negotiable principles:

1. **Declare `import str` (or `import str as alias`) at the top of your file**: every lib defines its `module :: str` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
3. **Tail-Call Optimization (TCO)**: all internal loops in `str` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 01.2. Native Artifacts, Imports, and Complete `str` API Catalog

In `ridgun-libs`, **`str`** is a first-class **lib** located at `src/main/ridgun/lib/str.ridgun` (domain `STR`). When built with `stable bundle`, it compiles into one native artifact:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/str.ridgunlib` | Portable distribution and direct `import str` resolution |

> Every lib declares its own namespace via `module :: str`: simply write `import str` (or `import str as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

### 01.2.1. Summary of `str` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `str index of : String -> String -> Int` | First index of needle in haystack (`-1` if absent / empty needle `0`) |
| `str contains / str starts with / str ends with` | `Bool` substring, prefix, and suffix predicates |
| `str trim / str trim left / str trim right` | Strip ASCII whitespace (` `, `\t`, `\n`, `\r`) |
| `str split / str split chars / str join` | Split into `[String]` and join lists with a separator |
| `str replace / str to upper / str to lower` | Non-overlapping replacement and ASCII case conversion |
| `str repeat / str pad left / str pad right` | $O(\log N)$ repetition and fixed-width column padding |

### 01.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/str.ridgun`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/str.ridgun` (`0` types, `0` operators, and `37` functions):

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: is ascii space Int` | `Bool` |
| `2` | `fn :: is ascii lower Int` | `Bool` |
| `3` | `fn :: is ascii upper Int` | `Bool` |
| `4` | `fn :: to upper code Int` | `Int` |
| `5` | `fn :: to lower code Int` | `Int` |
| `6` | `fn :: str index of from String String Int Int Int` | `Int` |
| `7` | `fn :: str index of String String` | `Int` |
| `8` | `fn :: str ends with step String String Int Int` | `Bool` |
| `9` | `fn :: str ends with String String` | `Bool` |
| `10` | `fn :: str is empty String` | `Bool` |
| `11` | `fn :: first non space idx String Int Int` | `Int` |
| `12` | `fn :: last non space end String Int` | `Int` |
| `13` | `fn :: str trim left String` | `String` |
| `14` | `fn :: str trim right String` | `String` |
| `15` | `fn :: str trim slice String Int Int` | `String` |
| `16` | `fn :: str trim String` | `String` |
| `17` | `fn :: str is blank String` | `Bool` |
| `18` | `fn :: str replace step String String String Int` | `String` |
| `19` | `fn :: str replace String String String` | `String` |
| `20` | `fn :: str split chars String Int Int [String]` | `[String]` |
| `21` | `fn :: str split onech loop String Int Int Int Int [String]` | `[String]` |
| `22` | `fn :: str split loop String String Int Int Int Int Int [String]` | `[String]` |
| `23` | `fn :: str split step String String Int Int` | `[String]` |
| `24` | `fn :: str split String String` | `[String]` |
| `25` | `fn :: str case fill Tensor[U8] Int Bool` | `Tensor[U8]` |
| `26` | `idem :: str upper table` | `Tensor[U8]` |
| `27` | `idem :: str lower table` | `Tensor[U8]` |
| `28` | `fn :: str case map Tensor[U8 * n] Tensor[U8]` | `Tensor[U8 * n]` |
| `29` | `fn :: str to upper String` | `String` |
| `30` | `fn :: str to lower String` | `String` |
| `31` | `fn :: str repeat loop String Int String` | `String` |
| `32` | `fn :: str repeat String Int` | `String` |
| `33` | `fn :: pad fill unit String` | `String` |
| `34` | `fn :: str pad left step String Int String Int` | `String` |
| `35` | `fn :: str pad left String Int String` | `String` |
| `36` | `fn :: str pad right step String Int String Int` | `String` |
| `37` | `fn :: str pad right String Int String` | `String` |

---

## 01.3. Deep Dive into `str`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `str` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test str.ridgun`.

### 01.3.1. Example 1: Core Tabular Workflow with `str`

Notice how in Ridgun the `=` signs and transformation steps using `str` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import str

fn :: normalizar cabecera String => String
      normalizar cabecera raw =
        raw str trim -> str to lower -> limpia
        limpia str split " " -> partes
        str join partes "-" -> slug
        str pad right slug 24 "."
```

### 01.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `str` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 38 libs in `ridgun-libs`:

```ridgun
import str

fn :: dominio desde String Int => String
      dominio desde correo pos =
        | pos < 0   = "sin-dominio"
        | otherwise = str replace (str to lower correo) "@" " en "

fn :: extraer dominio String => String
      extraer dominio correo =
        dominio desde correo (str index of correo "@")
```

### 01.3.3. Example 3: Substring Search (`str index of`), Suffixes (`str ends with`), and Emptiness/Blank Predicates

In this hands-on walkthrough we thoroughly exercise how `str` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test str search and predicates => ()
      test str search and predicates =
        str index of "hello world" "world" -> assert equals 6 "AC1: index_of world"
        str index of "hello world" "hello" -> assert equals 0 "AC1: index_of hello at 0"
        str index of "ababa" "aba" -> assert equals 0 "AC1: index_of returns first occurrence"
        str index of "hello" "xyz" -> assert equals (0 - 1) "AC1: index_of missing"
        str index of "short" "much_longer_needle" -> assert equals (0 - 1) "AC1: needle longer than haystack -> -1"
        str index of "" "a" -> assert equals (0 - 1) "AC1: non-empty needle in empty haystack -> -1"
        str index of "" "" -> assert equals 0 "AC1: empty needle in empty haystack -> 0"
        str index of "abc" "" -> assert equals 0 "AC1: empty needle -> 0"

        str ends with "archive.ridgunlib" ".ridgunlib" -> assert true "AC1: ends_with true"
        str ends with "exact" "exact" -> assert true "AC1: ends_with full string"
        str ends with "any" "" -> assert true "AC1: ends_with empty suffix true"
        str ends with "archive.ridgun" ".ridgunlib" -> assert false "AC1: ends_with false"
        str ends with "short" "longer_suffix" -> assert false "AC1: ends_with suffix longer than string"

        str is empty "" -> assert true "AC1: is_empty true"
        str is empty " " -> assert false "AC1: space is not empty"
        str is blank "" -> assert true "AC1: empty is blank"
        str is blank "   \t\n\r " -> assert true "AC1: whitespace-only is blank"
        str is blank "  x " -> assert false "AC1: non-whitespace is not blank"
        ()
```

### 01.3.4. Example 4: Whitespace Trimming (`trim`, `str trim left`, `str trim right`), Replacement (`str replace`), Splitting (`str split`), and Joining (`str join`)

In this hands-on walkthrough we thoroughly exercise how `str` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test str trim replace and split => ()
      test str trim replace and split =
        str trim "  \thi\n\r " -> assert equals "hi" "AC2: str_trim mixed ASCII whitespace"
        str trim "   \t\r\n" -> assert equals "" "AC2: str_trim all whitespace -> empty"
        str trim "" -> assert equals "" "AC2: str_trim empty -> empty"
        str trim "no_ws" -> assert equals "no_ws" "AC2: str_trim no whitespace"
        str trim left "  abc  " -> assert equals "abc  " "AC2: str_trim_left"
        str trim right "  abc  " -> assert equals "  abc" "AC2: str_trim_right"

        str replace "a-b-c" "-" "_" -> assert equals "a_b_c" "AC2: str_replace single char"
        str replace "aaaa" "aa" "b" -> assert equals "bb" "AC2: str_replace non-overlapping left-to-right"
        str replace "Hello,World" "World" "" -> assert equals "Hello," "AC2: str_replace deletion to empty"
        str replace "abc" "" "x" -> assert equals "abc" "AC2: str_replace empty old leaves string unchanged"
        str replace "abc" "z" "y" -> assert equals "abc" "AC2: str_replace absent needle"

        str split "a,b,c" "," -> assert equals ["a", "b", "c"] "AC2: str_split comma"
        str split "a,,b," "," -> assert equals ["a", "", "b", ""] "AC2: str_split consecutive and trailing delim"
        str split ",a" "," -> assert equals ["", "a"] "AC2: str_split leading delim"
        str split "a::b::c" "::" -> assert equals ["a", "b", "c"] "AC2: str_split multi-char delimiter"
        str split "ab" "" -> assert equals ["a", "b"] "AC2: str_split empty delim splits chars"
        str split "" "" -> assert equals [] "AC2: str_split empty string with empty delim -> []"

        str join [] "::" -> assert equals "" "AC2: str_join empty list"
        str join ["only"] "::" -> assert equals "only" "AC2: str_join singleton"
        str join ["alpha", "beta", "gamma"] "::" -> assert equals "alpha::beta::gamma" "AC2: str_join 3 items"
        ()
```

### 01.3.5. Example 5: ASCII Case Conversion (`str to upper`, `str to lower`), $O(\log N)$ Binary Repetition (`str repeat`), and Column Padding (`str pad left`, `str pad right`)

In this hands-on walkthrough we thoroughly exercise how `str` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test str case repeat and padding => ()
      test str case repeat and padding =
        str to upper "Abc! 123 xyz" -> assert equals "ABC! 123 XYZ" "AC3: str_to_upper"
        str to lower "Abc! 123 XYZ" -> assert equals "abc! 123 xyz" "AC3: str_to_lower"
        str to upper "" -> assert equals "" "AC3: str_to_upper empty"

        str repeat "ab" 3 -> assert equals "ababab" "AC3: str_repeat 3"
        str repeat "ab" 1 -> assert equals "ab" "AC3: str_repeat 1"
        str repeat "ab" 0 -> assert equals "" "AC3: str_repeat 0"
        str repeat "ab" (0 - 5) -> assert equals "" "AC3: str_repeat negative -> empty"
        str repeat "" 100 -> assert equals "" "AC3: str_repeat empty string -> empty"

        t0 = sys monotonic ms
        r64k = str repeat "x" 65536
        r256k = str repeat "x" 262144
        t1 = sys monotonic ms
        r8m = str repeat "x" 8000000
        str len r64k -> assert equals 65536 "AC3: str_repeat 65536 length"
        str len r256k -> assert equals 262144 "AC3: str_repeat 262144 length"
        str len r8m -> assert equals 8000000 "AC3: RG-052 str_repeat 8000000 exact length without 1 MiB cap"
        (t1 - t0) < 200 -> assert true "AC3: LIB-9 str_repeat 64k+256k in < 200 ms"

        str pad left "7" 3 "0" -> assert equals "007" "AC3: str_pad_left"
        str pad right "7" 3 "0" -> assert equals "700" "AC3: str_pad_right"
        str pad left "7" 4 "" -> assert equals "   7" "AC3: str_pad_left empty pad_ch defaults to space"
        str pad left "7" 4 "xyz" -> assert equals "xxx7" "AC3: str_pad_left uses first char of pad_ch"
        str pad left "1234" 3 "0" -> assert equals "1234" "AC3: str_pad_left already wider than width"
        str pad right "1234" 3 "0" -> assert equals "1234" "AC3: str_pad_right already wider than width"
        ()
```

---

## 01.4. Under the Hood: How `str` Is Built in Pure Ridgun (`src/main/ridgun/lib/str.ridgun`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/str.ridgun` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 01.4.1. Internal Implementation: ASCII Classification Helpers

Observe how `str.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
module :: str

fn :: is ascii space Int  => Bool
      is ascii space code =
        code == 32 or code == 9 or code == 10 or code == 13

fn :: is ascii lower Int  => Bool
      is ascii lower code =  code >= 97 and code <= 122

fn :: is ascii upper Int  => Bool
      is ascii upper code =  code >= 65 and code <= 90

fn :: to upper code Int  => Int
      to upper code code =
        | is ascii lower code = code - 32
        | otherwise           = code

fn :: to lower code Int  => Int
      to lower code code =
        | is ascii upper code = code + 32
        | otherwise           = code
```

### 01.4.2. Internal Implementation: Whitespace Trimming

Observe how `str.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: first non space idx String Int Int => Int
      first non space idx s idx len =
        | idx >= len                         = len
        | is ascii space (str char at s idx) = first non space idx s (idx + 1) len
        | otherwise                          = idx

fn :: last non space end String Int => Int
      last non space end s end =
        | end <= 0                                 = 0
        | is ascii space (str char at s (end - 1)) = last non space end s (end - 1)
        | otherwise                                = end

fn :: str trim left String => String
      str trim left s      =
        s str len -> len
        first non space idx s 0 len -> start
        str slice s start len

fn :: str trim right String => String
      str trim right s      =
        s str len -> len
        last non space end s len -> end
        str slice s 0 end

fn :: str trim slice String Int Int => String
      str trim slice s start end =
        | start >= end = ""
        | otherwise    = str slice s start end

fn :: str trim String => String
      str trim s      =
        s str len -> len
        first non space idx s 0 len -> start
        last non space end s len -> end
        str trim slice s start end

fn :: str is blank String => Bool
      str is blank s      =  s str trim -> str is empty
```

### 01.4.3. Internal Implementation: String Splitting & Joining

Observe how `str.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: str split chars String Int Int [String] => [String]
      str split chars s idx slen acc =
        | idx >= slen = acc
        | otherwise   = str split chars s (idx + 1) slen (acc :: [str slice s idx (idx + 1)])

fn :: str split onech loop String Int Int Int Int [String] => [String]
      str split onech loop s d0 pos slen seg_start acc =
        | pos >= slen = acc :: [str slice s seg_start slen]
        | (str char at s pos) == d0 =
          seg = str slice s seg_start pos
          str split onech loop s d0 (pos + 1) slen (pos + 1) (acc :: [seg])
        | otherwise =
          str split onech loop s d0 (pos + 1) slen seg_start acc

fn :: str split loop String String Int Int Int Int Int [String] => [String]
      str split loop s delim d0 pos slen dlen seg_start acc =
        | pos + dlen > slen = acc :: [str slice s seg_start slen]
        | (str char at s pos) == d0 and (str slice s pos (pos + dlen)) == delim =
          seg = str slice s seg_start pos
          str split loop s delim d0 (pos + dlen) slen dlen (pos + dlen) (acc :: [seg])
        | otherwise =
          str split loop s delim d0 (pos + 1) slen dlen seg_start acc

fn :: str split step String String Int Int => [String]
      str split step s delim slen dlen =
        | dlen == 0 = str split chars s 0 slen []
        | dlen == 1 = str split onech loop s (str char at delim 0) 0 slen 0 []
        | otherwise = str split loop s delim (str char at delim 0) 0 slen dlen 0 []

fn :: str split String String => [String]
      str split s      delim  =
        str split step s delim (str len s) (str len delim)

-- `str join [String] String => String` is the compiler prelude's (ridgunc 0.9.55).
```

### 01.4.4. Internal Implementation: Repetition & Padding

Observe how `str.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: str repeat loop String Int String => String
      str repeat loop cur n acc =
        | n <= 0       = acc
        | (n % 2) == 1 = str repeat loop (cur + cur) (n / 2) (acc + cur)
        | otherwise    = str repeat loop (cur + cur) (n / 2) acc

fn :: str repeat String Int => String
      str repeat s      n   =
        | n <= 0 or (str len s) == 0 = ""
        | otherwise                  = str repeat loop s n ""

fn :: pad fill unit String => String
      pad fill unit pad_ch =
        | (str len pad_ch) == 0 = " "
        | otherwise             = str slice pad_ch 0 1

fn :: str pad left step String Int String Int => String
      str pad left step s width pad_ch slen =
        | slen >= width = s
        | otherwise     = (str repeat (pad fill unit pad_ch) (width - slen)) + s

fn :: str pad left String Int String => String
      str pad left s width pad_ch =
        str pad left step s width pad_ch (str len s)

fn :: str pad right step String Int String Int => String
      str pad right step s width pad_ch slen =
        | slen >= width = s
        | otherwise     = s + (str repeat (pad fill unit pad_ch) (width - slen))

fn :: str pad right String Int String => String
      str pad right s width pad_ch =
        str pad right step s width pad_ch (str len s)
```

---

## 01.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `str`

- **Algorithmic & Safety Guarantee**: $O(\log N)$ repetition via binary string doubling, safe handling of empty needles, and zero in-place mutation.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/str.ridgun` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test str.ridgun`.

### The 5 Golden Rules When Programming with `str`

1. **Declare `import str` at the top of your file** and call its functions with spaces, exactly as they are declared, so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `str` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `str`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `str` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 02**, we will explore the **`math`** lib in full depth (The `math` Lib — Safe Division, Number Theory, and Statistics).
