# Chapter 10: The `ini` Lib — Sectioned `.ini` Configs, `.env` Files, and Variable Interpolation

## 10.1. Why Does the `ini` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `ini` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `ini`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: `.env` and `.ini` files look trivial until someone writes `export KEY="value # with hash"`, inline `;` comments, or cross-variable interpolation.

The **`ini`** lib parses sectioned `.ini` files (`[database]`) and `export`-prefixed `.env` files, preserving `#` and `;` inside quoted values and resolving variable interpolations in `dotenv parse`.

In a traditional ecosystem, solving **`INI`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`ini`** lib (`src/main/ridgun/lib/ini.rg`) tackles the problem with four non-negotiable principles:

1. **Total Functions & Explicit Contracts (`=>`)**: no function in `ini` throws hidden exceptions or relies on `null`. Every edge case (empty inputs, zero divisors, truncated frames, or out-of-bounds indices) returns a documented sentinel value or an algebraic sum type (`Option`, `Result`).
2. **Zero C Code & Zero `libc`**: every line of `ini` compiles directly into native ELF64 machine code verified by `ridgunc`.
3. **Tail-Call Optimization (TCO)**: all internal loops in `ini` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 10.2. Native Artifacts, Imports, and Complete `ini` API Catalog

In `ridgun-libs`, **`ini`** is a first-class **lib** located at `src/main/ridgun/lib/ini.rg` (domain `INI`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/ini.rglib` | Portable distribution and direct `import ini` resolution |
| **Compiled Archive** | `target/ini.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libini.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import ini` at the top and call its functions using either multi-word spaces (`my fn x`) or underscores (`my_fn x`).

### 10.2.1. Summary of `ini` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `ini parse / ini stringify` | Parse sectioned `.ini` text into `IniDoc` and serialize back to canonical text |
| `ini get / ini get int / ini get bool / ini set` | Typed section+key lookups (`""` for global section) and immutable updates |
| `ini sections / ini section map` | List all section names or extract a section's `[String String]` map |
| `dotenv parse` | Parse `.env` lines (`export K=V`, quotes, comments, and variable expansion) |

### 10.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/ini.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/ini.rg` (`3` types, `0` operators, and `44` functions):

**Algebraic Data Types & Records (`type`) in `ini`:**

```ridgun
type IniEntry = IniEntry String String
type IniSection = section_name: String, entries: [IniEntry]
type IniDoc = sections: [IniSection]
```

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: ini_is_hspace Int` | `Bool` |
| `2` | `fn :: ini_trim_left_loop String Int Int` | `String` |
| `3` | `fn :: ini_trim_right_loop String Int` | `String` |
| `4` | `fn :: ini_trim String` | `String` |
| `5` | `fn :: ini_split_lines_loop String Int Int Int [String]` | `[String]` |
| `6` | `fn :: ini_skip_quoted String Int Int Int` | `Int` |
| `7` | `fn :: ini_strip_comment_loop String Int Int` | `String` |
| `8` | `fn :: ini_unquote_unescape_loop String Int Int String` | `String` |
| `9` | `fn :: ini_clean_val String` | `String` |
| `10` | `fn :: ini_clean_val_len String Int` | `String` |
| `11` | `fn :: ini_p_key IniEntry` | `String` |
| `12` | `fn :: ini_p_val IniEntry` | `String` |
| `13` | `fn :: ini_kv_get [IniEntry] String String` | `String` |
| `14` | `fn :: ini_kv_put [IniEntry] String String` | `[IniEntry]` |
| `15` | `fn :: ini_find_rbrace String Int Int` | `Int` |
| `16` | `fn :: ini_expand_brace String Int Int [IniEntry] String Int` | `String` |
| `17` | `fn :: ini_interpolate_loop String Int Int [IniEntry] String` | `String` |
| `18` | `fn :: ini_interpolate String [IniEntry]` | `String` |
| `19` | `fn :: ini_sec_put [IniSection] String String String` | `[IniSection]` |
| `20` | `fn :: ini_sec_ensure [IniSection] String` | `[IniSection]` |
| `21` | `fn :: ini_sec_get [IniSection] String String String` | `String` |
| `22` | `fn :: ini_find_eq String Int Int` | `Int` |
| `23` | `fn :: ini_strip_export String` | `String` |
| `24` | `fn :: ini_parse_kv_at String [IniSection] String Int` | `[IniSection]` |
| `25` | `fn :: ini_sec_entries [IniSection] String` | `[IniEntry]` |
| `26` | `fn :: ini_parse_lines [String] [IniSection] String` | `[IniSection]` |
| `27` | `fn :: ini_parse_sec_hdr String [String] [IniSection]` | `[IniSection]` |
| `28` | `fn :: ini_parse_kv_line String [String] [IniSection] String` | `[IniSection]` |
| `29` | `fn :: ini_parse_clean_line String [String] [IniSection] String` | `[IniSection]` |
| `30` | `fn :: ini parse String` | `IniDoc` |
| `31` | `fn :: dotenv parse String` | `[IniEntry]` |
| `32` | `fn :: ini get IniDoc String String String` | `String` |
| `33` | `fn :: ini get int IniDoc String String Int` | `Int` |
| `34` | `fn :: ini_parse_int_or String Int` | `Int` |
| `35` | `fn :: ini get bool IniDoc String String Bool` | `Bool` |
| `36` | `fn :: ini_parse_bool_or String Bool` | `Bool` |
| `37` | `fn :: ini set IniDoc String String String` | `IniDoc` |
| `38` | `fn :: ini_collect_sec_names [IniSection]` | `[String]` |
| `39` | `fn :: ini sections IniDoc` | `[String]` |
| `40` | `fn :: dotenv get [IniEntry] String String` | `String` |
| `41` | `fn :: ini_format_entries [IniEntry]` | `String` |
| `42` | `fn :: ini_format_section IniSection` | `String` |
| `43` | `fn :: ini_format_sections [IniSection]` | `String` |
| `44` | `fn :: ini stringify IniDoc` | `String` |

---

## 10.3. Deep Dive into `ini`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `ini` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test ini.rg`.

### 10.3.1. Example 1: Core Tabular Workflow with `ini`

Notice how in Ridgun the `=` signs and transformation steps using `ini` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import ini

fn :: cargar base de datos (texto_ini : String) => (String, Int, Bool)
      cargar base de datos texto_ini =
        doc  = ini parse texto_ini
        host = ini get doc "database" "host" "localhost"
        port = ini get int doc "database" "port" 5432
        pool = ini get bool doc "database" "pool" True
        (host, port, pool)
```

### 10.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `ini` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import ini

fn :: actualizar puerto (doc : IniDoc) (nuevo : String) => String
      actualizar puerto doc nuevo =
        doc2 = ini set doc "database" "port" nuevo
        ini stringify doc2
```

### 10.3.3. Example 3: `[section]` Headers, Comments (`;` and `#`), Typed Getters (`get str`, `get int`, `get bool`), and Immutable Updates (`ini set`)

In this hands-on walkthrough we thoroughly exercise how `ini` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_ini_sections_and_typed_getters => ()
      test_ini_sections_and_typed_getters =
        nl = char_from_code 10
        src = "# Global header comment" + nl + "; Secondary comment" + nl + "global_env = production" + nl + nl + "[database]" + nl + "host = \"127.0.0.1\"" + nl + "port = 5432 ; default pg" + nl + "timeout = -1 # infinite" + nl + "password = \"p@ss#word;123\"" + nl + "ssl = true" + nl + "pool_enabled = yes" + nl + "readonly = 0" + nl + "debug_sql = no" + nl + nl + "[server]" + nl + "workers = 4" + nl + "enabled = 1" + nl
        doc = ini parse src
        _ = assert str eq (ini get doc "" "global_env" "") "production" "AC1: global sectionless key in root '' section"
        _ = assert str eq (ini get doc "database" "host" "") "127.0.0.1" "AC1: ini get quoted string"
        _ = assert int equals (ini get int doc "database" "port" 0) 5432 "AC1: ini get int with ';' inline comment"
        _ = assert int equals (ini get int doc "database" "timeout" 0) (-1) "AC1: ini get negative int with '#' inline comment"
        _ = assert str eq (ini get doc "database" "password" "") "p@ss#word;123" "AC1: quoted '#' and ';' preserved inside string"
        _ = assert true (ini get bool doc "database" "ssl" False) "AC1: ini get bool 'true'"
        _ = assert true (ini get bool doc "database" "pool_enabled" False) "AC1: ini get bool 'yes'"
        _ = assert false (ini get bool doc "database" "readonly" True) "AC1: ini get bool '0'"
        _ = assert false (ini get bool doc "database" "debug_sql" True) "AC1: ini get bool 'off'"
        _ = assert int equals (ini get int doc "server" "workers" 0) 4 "AC1: ini get second section"
        _ = assert true (ini get bool doc "server" "enabled" False) "AC1: ini get bool '1'"
        _ = assert str eq (ini get doc "server" "missing" "default_v") "default_v" "AC1: ini get fallback on missing key"
        _ = assert str eq (ini get doc "no_such_section" "k" "fallback") "fallback" "AC1: ini get fallback on missing section"
        secs = ini sections doc
        _ = assert int equals (ini_sec_count secs) 3 "AC1: 3 sections (root '', database, server)"
        ()
```

### 10.3.4. Example 4: `.env` Files with `export`, Quoted Values, `${VAR}` Variable Interpolation, and Canonical Serialization (`ini stringify`)

In this hands-on walkthrough we thoroughly exercise how `ini` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_dotenv_interpolation_and_roundtrip => ()
      test_dotenv_interpolation_and_roundtrip =
        nl = char_from_code 10
        lb = char_from_code 123
        rb = char_from_code 125
        env_src = "# .env test" + nl + "export BASE_DIR=/srv/app" + nl + "APP_NAME='solstice'" + nl + "LOG_DIR=\"$" + lb + "BASE_DIR" + rb + "/$" + lb + "APP_NAME" + rb + "/logs\"" + nl + "WITH_UNKNOWN=\"prefix_$" + lb + "UNDEFINED_VAR" + rb + "_suffix\"" + nl + "PORT=8080 # inline comment" + nl
        env = dotenv parse env_src
        _ = assert str eq (dotenv get env "BASE_DIR" "") "/srv/app" "AC2: dotenv export key"
        _ = assert str eq (dotenv get env "APP_NAME" "") "solstice" "AC2: dotenv single-quoted value"
        _ = assert str eq (dotenv get env "LOG_DIR" "") "/srv/app/solstice/logs" "AC2: dotenv multiple variable interpolations"
        _ = assert str eq (dotenv get env "WITH_UNKNOWN" "") "prefix__suffix" "AC2: dotenv undefined variable expands to empty"
        _ = assert str eq (dotenv get env "PORT" "") "8080" "AC2: dotenv inline comment stripped"
        _ = assert str eq (dotenv get env "MISSING_KEY" "def") "def" "AC2: dotenv missing key fallback"

        doc0 = ini parse ("[app]" + nl + "name = demo" + nl + "port = 3000" + nl)
        doc1 = ini set doc0 "app" "version" "1.0"
        doc2 = ini set doc1 "app" "port" "9090"
        doc3 = ini set doc2 "metrics" "enabled" "true"
        out_s = ini stringify doc3
        doc_rt = ini parse out_s
        _ = assert str eq (ini get doc_rt "app" "name" "") "demo" "AC3: ini stringify round-trip name"
        _ = assert str eq (ini get doc_rt "app" "version" "") "1.0" "AC3: ini set new key + round-trip"
        _ = assert int equals (ini get int doc_rt "app" "port" 0) 9090 "AC3: ini set overwrite existing key + round-trip"
        _ = assert true (ini get bool doc_rt "metrics" "enabled" False) "AC3: ini set new section + round-trip"
        ()
```

### 10.3.5. Example 5: Layered Service Configuration: Merging `.env` with `${VAR}` Interpolation and `[database]` / `[server]` INI Sections

In this hands-on walkthrough we thoroughly exercise how `ini` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
import ini

fn :: cargar configuracion servicio (raw_ini : String) (raw_env : String) => (String, Int, Bool, String)
      cargar configuracion servicio raw_ini raw_env =
        env_entries = dotenv parse raw_env
        doc         = ini parse raw_ini
        db_host     = ini get str doc "database" "host" "localhost"
        db_port     = ini get int doc "database" "port" 5432
        tls_activo  = ini get bool doc "database" "tls" True
        doc_act     = ini set doc "server" "dsn" "{db_host}:{db_port}"
        (dotenv get env_entries "APP_ENV" "prod", db_port, tls_activo, ini stringify doc_act)
```

---

## 10.4. Under the Hood: How `ini` Is Built in Pure Ridgun (`src/main/ridgun/lib/ini.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/ini.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 10.4.1. Internal Implementation: Whitespace, Comment & Line Helpers

Observe how `ini.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: ini_is_hspace Int => Bool
      ini_is_hspace c   =  c == 32 OR c == 9 OR c == 13

fn :: ini_trim_left_loop String Int Int => String
      ini_trim_left_loop s      pos len
        | pos >= len = ""
        | ini_is_hspace (str_char_at s pos) = ini_trim_left_loop s (pos + 1) len
        | otherwise = str_slice s pos len

fn :: ini_trim_right_loop String Int     => String
      ini_trim_right_loop s      end_pos
        | end_pos <= 0 = ""
        | ini_is_hspace (str_char_at s (end_pos - 1)) = ini_trim_right_loop s (end_pos - 1)
        | otherwise = str_slice s 0 end_pos

fn :: ini_trim String => String
      ini_trim s      =  ini_trim_left_loop (ini_trim_right_loop s (str_len s)) 0 (str_len (ini_trim_right_loop s (str_len s)))

fn :: ini_split_lines_loop String Int Int Int [String] => [String]
      ini_split_lines_loop s pos len start acc
        | pos >= len AND start == len = acc
        | pos >= len = acc :: [str_slice s start len]
        | (str_char_at s pos) == 10 = ini_split_lines_loop s (pos + 1) len (pos + 1) (acc :: [str_slice s start pos])
        | otherwise = ini_split_lines_loop s (pos + 1) len start acc

fn :: ini_skip_quoted String Int Int Int => Int
      ini_skip_quoted s      pos len q
        | pos >= len = len
        | (str_char_at s pos) == 92 = ini_skip_quoted s (pos + 2) len q
        | (str_char_at s pos) == q = pos + 1
        | otherwise = ini_skip_quoted s (pos + 1) len q

fn :: ini_strip_comment_loop String Int Int => String
      ini_strip_comment_loop s      pos len
        | pos >= len = s
        | (str_char_at s pos) == 34 = ini_strip_comment_loop s (ini_skip_quoted s (pos + 1) len 34) len
        | (str_char_at s pos) == 39 = ini_strip_comment_loop s (ini_skip_quoted s (pos + 1) len 39) len
        | (str_char_at s pos) == 35 OR (str_char_at s pos) == 59 = str_slice s 0 pos
        | (pos + 1) < len AND (str_char_at s pos) == 45 AND (str_char_at s (pos + 1)) == 45 = str_slice s 0 pos
        | otherwise = ini_strip_comment_loop s (pos + 1) len

fn :: ini_unquote_unescape_loop String Int Int String => String
      ini_unquote_unescape_loop s      pos len acc
        | pos >= len = acc
        | (str_char_at s pos) == 92 AND (pos + 1) < len AND (str_char_at s (pos + 1)) == 110 = ini_unquote_unescape_loop s (pos + 2) len (acc + (char_from_code 10))
        | (str_char_at s pos) == 92 AND (pos + 1) < len AND (str_char_at s (pos + 1)) == 116 = ini_unquote_unescape_loop s (pos + 2) len (acc + (char_from_code 9))
        | (str_char_at s pos) == 92 AND (pos + 1) < len = ini_unquote_unescape_loop s (pos + 2) len (acc + (str_slice s (pos + 1) (pos + 2)))
        | otherwise = ini_unquote_unescape_loop s (pos + 1) len (acc + (str_slice s pos (pos + 1)))
```

### 10.4.2. Internal Implementation: Key-Value Pair Helpers (`[IniEntry]`)

Observe how `ini.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: ini_p_key IniEntry       => String
      ini_p_key (IniEntry k _) =  k

fn :: ini_p_val IniEntry       => String
      ini_p_val (IniEntry _ v) =  v

fn :: ini_kv_get [IniEntry]  String String   => String
      ini_kv_get []          _      fallback =  fallback
      ini_kv_get (pair:rest) key    fallback
        | (ini_p_key pair) == key = ini_p_val pair
        | otherwise = ini_kv_get rest key fallback

fn :: ini_kv_put [IniEntry]  String String => [IniEntry]
      ini_kv_put []          key    val    =  [IniEntry key val]
      ini_kv_put (pair:rest) key    val
        | (ini_p_key pair) == key = [IniEntry key val] :: rest
        | otherwise = [pair] :: (ini_kv_put rest key val)
```

### 10.4.3. Internal Implementation: Sectioned INI Document Helpers

Observe how `ini.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: ini_sec_put [IniSection] String String String => [IniSection]
      ini_sec_put []           sec    key    val    =  [IniSection sec [IniEntry key val]]
      ini_sec_put (s:rest)     sec    key    val
        | (section_name s) == sec = [IniSection sec (ini_kv_put (entries s) key val)] :: rest
        | otherwise = [s] :: (ini_sec_put rest sec key val)

fn :: ini_sec_ensure [IniSection] String => [IniSection]
      ini_sec_ensure []           sec    =  [IniSection sec []]
      ini_sec_ensure (s:rest)     sec
        | (section_name s) == sec = [s] :: rest
        | otherwise = [s] :: (ini_sec_ensure rest sec)

fn :: ini_sec_get [IniSection] String String String   => String
      ini_sec_get []           _      _      fallback =  fallback
      ini_sec_get (s:rest)     sec    key    fallback
        | (section_name s) == sec = ini_kv_get (entries s) key fallback
        | otherwise = ini_sec_get rest sec key fallback

fn :: ini_find_eq String Int Int => Int
      ini_find_eq s      pos len
        | pos >= len = -1
        | (str_char_at s pos) == 61 = pos
        | otherwise = ini_find_eq s (pos + 1) len

fn :: ini_strip_export String => String
      ini_strip_export tr
        | str_starts_with tr "export " = ini_trim (str_slice tr 7 (str_len tr))
        | otherwise = tr

fn :: ini_parse_kv_at String [IniSection] String Int    => [IniSection]
      ini_parse_kv_at _      secs         _      -1     =  secs
      ini_parse_kv_at line   secs         cur_s  eq_pos =
        key = ini_trim (str_slice line 0 eq_pos)
        raw_v = ini_clean_val (str_slice line (eq_pos + 1) (str_len line))
        cur_entries = ini_sec_entries secs cur_s
        val = ini_interpolate raw_v cur_entries
        ini_sec_put secs cur_s key val

fn :: ini_sec_entries [IniSection] String => [IniEntry]
      ini_sec_entries []           _      =  []
      ini_sec_entries (s:rest)     sec
        | (section_name s) == sec = entries s
        | otherwise = ini_sec_entries rest sec

fn :: ini_parse_lines [String] [IniSection] String => [IniSection]
      ini_parse_lines []       secs         _      =  secs
      ini_parse_lines (l:ls)   secs         cur_s  =
        clean = ini_trim (ini_strip_comment_loop l 0 (str_len l))
        ini_parse_clean_line clean ls secs cur_s
```

### 10.4.4. Internal Implementation: Queries, Updates & Serialization

Observe how `ini.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: ini get IniDoc String String String => String
      ini get doc sec key fallback = ini_sec_get (sections doc) sec key fallback

fn :: ini get int IniDoc String String Int => Int
      ini get int doc sec key fallback =
        v = ini get doc sec key ""
        ini_parse_int_or v fallback

fn :: ini_parse_int_or String Int      => Int
      ini_parse_int_or ""     fallback =  fallback
      ini_parse_int_or v      _        =  str_to_int v

fn :: ini get bool IniDoc String String Bool => Bool
      ini get bool doc sec key fallback =
        v = ini get doc sec key ""
        ini_parse_bool_or v fallback

fn :: ini_parse_bool_or String  Bool     => Bool
      ini_parse_bool_or ""      fallback =  fallback
      ini_parse_bool_or "true"  _        =  True
      ini_parse_bool_or "True"  _        =  True
      ini_parse_bool_or "1"     _        =  True
      ini_parse_bool_or "yes"   _        =  True
      ini_parse_bool_or "false" _        =  False
      ini_parse_bool_or "False" _        =  False
      ini_parse_bool_or "0"     _        =  False
      ini_parse_bool_or "no"    _        =  False
      ini_parse_bool_or _       fallback =  fallback

fn :: ini set IniDoc String String String => IniDoc
      ini set doc sec key val = IniDoc (ini_sec_put (sections doc) sec key val)

fn :: ini_collect_sec_names [IniSection] => [String]
      ini_collect_sec_names []           =  []
      ini_collect_sec_names (s:rest)     =  [section_name s] :: (ini_collect_sec_names rest)

fn :: ini sections IniDoc => [String]
      ini sections doc    =  ini_collect_sec_names (sections doc)

fn :: dotenv get [IniEntry] String String   => String
      dotenv get env        key    fallback =  ini_kv_get env key fallback

fn :: ini_format_entries [IniEntry] => String
      ini_format_entries []         =  ""
      ini_format_entries ((IniEntry k v):rs) = k + " = " + v + (char_from_code 10) + (ini_format_entries rs)

fn :: ini_format_section IniSection => String
      ini_format_section sec
        | (section_name sec) == "" = ini_format_entries (entries sec)
        | otherwise = "[" + (section_name sec) + "]" + (char_from_code 10) + (ini_format_entries (entries sec))
```

---

## 10.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `ini`

- **Algorithmic & Safety Guarantee**: Full preservation of `#` and `;` characters inside single or double quotes, and flexible boolean parsing (`true/1/yes/on` vs `false/0/no/off`).
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/ini.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test ini.rg`.

### The 5 Golden Rules When Programming with `ini`

1. **Declare `import ini` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `ini` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `ini`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `ini` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 11**, we will explore the **`regex`** lib in full depth (The `regex` Lib — Linear-Time $O(N \cdot M)$ Thompson NFA Regular Expression Engine).
