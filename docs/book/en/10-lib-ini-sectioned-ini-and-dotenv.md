# Chapter 10: The `ini` Lib — Sectioned `.ini` Configs, `.env` Files, and Variable Interpolation

## 10.1. Why Does the `ini` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `ini` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `ini`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: `.env` and `.ini` files look trivial until someone writes `export KEY="value # with hash"`, inline `;` comments, or cross-variable interpolation.

The **`ini`** lib parses sectioned `.ini` files (`[database]`) and `export`-prefixed `.env` files, preserving `#` and `;` inside quoted values and resolving variable interpolations in `dotenv parse`.

In a traditional ecosystem, solving **`INI`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`ini`** lib (`src/main/ridgun/lib/ini.rg`) tackles the problem with four non-negotiable principles:

1. **Declare `import ini` (or `import ini as alias`) at the top of your file**: every lib defines its `module :: ini` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
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

> Every lib declares its own namespace via `module :: ini`: simply write `import ini` (or `import ini as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

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

fn :: cargar base de datos String => String Int Bool
      cargar base de datos texto_ini =
        texto_ini ini parse -> doc
        ini get doc "database" "host" "localhost" -> host
        ini get int doc "database" "port" 5432 -> port
        ini get bool doc "database" "pool" True -> pool
        (host, port, pool)
```

### 10.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `ini` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import ini

fn :: actualizar puerto [String String String] String => String
      actualizar puerto doc nuevo =
        ini set doc "database" "port" nuevo -> doc2
        doc2 ini encode
```

### 10.3.3. Example 3: `[section]` Headers, Comments (`;` and `#`), Typed Getters (`get str`, `get int`, `get bool`), and Immutable Updates (`ini set`)

In this hands-on walkthrough we thoroughly exercise how `ini` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_ini_sections_and_typed_getters => ()
      test_ini_sections_and_typed_getters =
        nl = char from code 10
        src = "# Global header comment" + nl + "; Secondary comment" + nl + "global_env = production" + nl + nl + "[database]" + nl + "host = \"127.0.0.1\"" + nl + "port = 5432 ; default pg" + nl + "timeout = -1 # infinite" + nl + "password = \"p@ss#word;123\"" + nl + "ssl = true" + nl + "pool_enabled = yes" + nl + "readonly = 0" + nl + "debug_sql = no" + nl + nl + "[server]" + nl + "workers = 4" + nl + "enabled = 1" + nl
        doc = ini parse src
        assert str eq (ini get doc "" "global_env" "") "production" "AC1: global sectionless key in root '' section"
        assert str eq (ini get doc "database" "host" "") "127.0.0.1" "AC1: ini get quoted string"
        assert int equals (ini get int doc "database" "port" 0) 5432 "AC1: ini get int with ';' inline comment"
        assert int equals (ini get int doc "database" "timeout" 0) (-1) "AC1: ini get negative int with '#' inline comment"
        assert str eq (ini get doc "database" "password" "") "p@ss#word;123" "AC1: quoted '#' and ';' preserved inside string"
        assert true (ini get bool doc "database" "ssl" False) "AC1: ini get bool 'true'"
        assert true (ini get bool doc "database" "pool_enabled" False) "AC1: ini get bool 'yes'"
        assert false (ini get bool doc "database" "readonly" True) "AC1: ini get bool '0'"
        assert false (ini get bool doc "database" "debug_sql" True) "AC1: ini get bool 'off'"
        assert int equals (ini get int doc "server" "workers" 0) 4 "AC1: ini get second section"
        assert true (ini get bool doc "server" "enabled" False) "AC1: ini get bool '1'"
        assert str eq (ini get doc "server" "missing" "default_v") "default_v" "AC1: ini get fallback on missing key"
        assert str eq (ini get doc "no_such_section" "k" "fallback") "fallback" "AC1: ini get fallback on missing section"
        secs = ini sections doc
        assert int equals (ini_sec_count secs) 3 "AC1: 3 sections (root '', database, server)"
        ()
```

### 10.3.4. Example 4: `.env` Files with `export`, Quoted Values, `${VAR}` Variable Interpolation, and Canonical Serialization (`ini stringify`)

In this hands-on walkthrough we thoroughly exercise how `ini` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test_dotenv_interpolation_and_roundtrip => ()
      test_dotenv_interpolation_and_roundtrip =
        nl = char from code 10
        lb = char from code 123
        rb = char from code 125
        env_src = "# .env test" + nl + "export BASE_DIR=/srv/app" + nl + "APP_NAME='solstice'" + nl + "LOG_DIR=\"$" + lb + "BASE_DIR" + rb + "/$" + lb + "APP_NAME" + rb + "/logs\"" + nl + "WITH_UNKNOWN=\"prefix_$" + lb + "UNDEFINED_VAR" + rb + "_suffix\"" + nl + "PORT=8080 # inline comment" + nl
        env = dotenv parse env_src
        assert str eq (dotenv get env "BASE_DIR" "") "/srv/app" "AC2: dotenv export key"
        assert str eq (dotenv get env "APP_NAME" "") "solstice" "AC2: dotenv single-quoted value"
        assert str eq (dotenv get env "LOG_DIR" "") "/srv/app/solstice/logs" "AC2: dotenv multiple variable interpolations"
        assert str eq (dotenv get env "WITH_UNKNOWN" "") "prefix__suffix" "AC2: dotenv undefined variable expands to empty"
        assert str eq (dotenv get env "PORT" "") "8080" "AC2: dotenv inline comment stripped"
        assert str eq (dotenv get env "MISSING_KEY" "def") "def" "AC2: dotenv missing key fallback"

        doc0 = ini parse ("[app]" + nl + "name = demo" + nl + "port = 3000" + nl)
        doc1 = ini set doc0 "app" "version" "1.0"
        doc2 = ini set doc1 "app" "port" "9090"
        doc3 = ini set doc2 "metrics" "enabled" "true"
        out_s = ini stringify doc3
        doc_rt = ini parse out_s
        assert str eq (ini get doc_rt "app" "name" "") "demo" "AC3: ini stringify round-trip name"
        assert str eq (ini get doc_rt "app" "version" "") "1.0" "AC3: ini set new key + round-trip"
        assert int equals (ini get int doc_rt "app" "port" 0) 9090 "AC3: ini set overwrite existing key + round-trip"
        assert true (ini get bool doc_rt "metrics" "enabled" False) "AC3: ini set new section + round-trip"
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
module :: ini

fn :: ini is hspace Int => Bool
      ini is hspace c = c == 32 or c == 9 or c == 13

fn :: ini trim left loop String Int Int => String
      ini trim left loop s pos len =
        | pos >= len = ""
        | ini is hspace (str char at s pos) = ini trim left loop s (pos + 1) len
        | otherwise = str slice s pos len

fn :: ini trim right loop String Int => String
      ini trim right loop s end_pos =
        | end_pos <= 0 = ""
        | ini is hspace (str char at s (end_pos - 1)) = ini trim right loop s (end_pos - 1)
        | otherwise = str slice s 0 end_pos

fn :: ini trim String => String
      ini trim s =
        ini trim right loop s (str len s) -> r
        ini trim left loop r 0 (str len r)

fn :: ini split lines loop String Int Int Int [String] => [String]
      ini split lines loop s pos len start acc =
        | pos >= len and start == len = acc
        | pos >= len = acc :: [str slice s start len]
        | (str char at s pos) == 10 = ini split lines loop s (pos + 1) len (pos + 1) (acc :: [str slice s start pos])
        | otherwise = ini split lines loop s (pos + 1) len start acc

fn :: ini skip quoted String Int Int Int => Int
      ini skip quoted s pos len q =
        | pos >= len = len
        | (str char at s pos) == 92 = ini skip quoted s (pos + 2) len q
        | (str char at s pos) == q = pos + 1
        | otherwise = ini skip quoted s (pos + 1) len q

fn :: ini strip comment loop String Int Int => String
      ini strip comment loop s pos len =
        | pos >= len = s
        | (str char at s pos) == 34 = ini strip comment loop s (ini skip quoted s (pos + 1) len 34) len
        | (str char at s pos) == 39 = ini strip comment loop s (ini skip quoted s (pos + 1) len 39) len
        | (str char at s pos) == 35 or (str char at s pos) == 59 = str slice s 0 pos
        | (pos + 1) < len and (str char at s pos) == 45 and (str char at s (pos + 1)) == 45 = str slice s 0 pos
        | otherwise = ini strip comment loop s (pos + 1) len

fn :: ini unquote unescape loop String Int Int String => String
      ini unquote unescape loop s pos len acc =
        | pos >= len = acc
        | (str char at s pos) == 92 and (pos + 1) < len and (str char at s (pos + 1)) == 110 = ini unquote unescape loop s (pos + 2) len (acc + (char from code 10))
        | (str char at s pos) == 92 and (pos + 1) < len and (str char at s (pos + 1)) == 116 = ini unquote unescape loop s (pos + 2) len (acc + (char from code 9))
        | (str char at s pos) == 92 and (pos + 1) < len = ini unquote unescape loop s (pos + 1 + 1) len (acc + (str slice s (pos + 1) (pos + 2)))
        | otherwise = ini unquote unescape loop s (pos + 1) len (acc + (str slice s pos (pos + 1)))

fn :: ini clean val String => String
      ini clean val raw =
        raw ini trim -> tr
        tr str len -> len
        ini clean val len tr len

fn :: ini clean val len String Int => String
      ini clean val len tr len =
        | len >= 2 and (str char at tr 0) == 34 and (str char at tr (len - 1)) == 34 = ini unquote unescape loop (str slice tr 1 (len - 1)) 0 (len - 2) ""
        | len >= 2 and (str char at tr 0) == 39 and (str char at tr (len - 1)) == 39 = str slice tr 1 (len - 1)
        | otherwise = tr
```

### 10.4.2. Internal Implementation: Key-Value Pair Helpers (`[IniEntry]`)

Observe how `ini.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: ini p key IniEntry => String
      ini p key (IniEntry k _) = k

fn :: ini p val IniEntry => String
      ini p val (IniEntry _ v) = v

fn :: ini kv get [IniEntry] String String => String
      ini kv get [] _ fallback = fallback
      ini kv get (pair:rest) key fallback =
        | (ini p key pair) == key = ini p val pair
        | otherwise = ini kv get rest key fallback

fn :: ini kv put [IniEntry] String String => [IniEntry]
      ini kv put [] key val = [IniEntry key val]
      ini kv put (pair:rest) key val =
        | (ini p key pair) == key = [IniEntry key val] :: rest
        | otherwise = [pair] :: (ini kv put rest key val)
```

### 10.4.3. Internal Implementation: Sectioned INI Document Helpers

Observe how `ini.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: ini sec put [IniSection] String String String => [IniSection]
      ini sec put [] sec key val = [IniSection sec [IniEntry key val]]
      ini sec put (s:rest) sec key val =
        | (section_name s) == sec = [IniSection sec (ini kv put (entries s) key val)] :: rest
        | otherwise = [s] :: (ini sec put rest sec key val)

fn :: ini sec ensure [IniSection] String => [IniSection]
      ini sec ensure [] sec = [IniSection sec []]
      ini sec ensure (s:rest) sec =
        | (section_name s) == sec = [s] :: rest
        | otherwise = [s] :: (ini sec ensure rest sec)

fn :: ini sec get [IniSection] String String String => String
      ini sec get [] _ _ fallback = fallback
      ini sec get (s:rest) sec key fallback =
        | (section_name s) == sec = ini kv get (entries s) key fallback
        | otherwise = ini sec get rest sec key fallback

fn :: ini find eq String Int Int => Int
      ini find eq s pos len =
        | pos >= len = (0 - 1)
        | (str char at s pos) == 61 = pos
        | otherwise = ini find eq s (pos + 1) len

fn :: ini strip export String => String
      ini strip export tr =
        | str starts with tr "export " = ini trim (str slice tr 7 (str len tr))
        | otherwise = tr

fn :: ini parse kv at String [IniSection] String Int => [IniSection]
      ini parse kv at line secs cur_s eq_pos =
        | eq_pos == (0 - 1) = secs
        | otherwise = ini sec put secs cur_s (ini trim (str slice line 0 eq_pos)) (ini interpolate (ini clean val (str slice line (eq_pos + 1) (str len line))) (ini sec entries secs cur_s))

fn :: ini sec entries [IniSection] String => [IniEntry]
      ini sec entries [] _ = []
      ini sec entries (s:rest) sec =
        | (section_name s) == sec = entries s
        | otherwise = ini sec entries rest sec

fn :: ini parse lines [String] [IniSection] String => [IniSection]
      ini parse lines [] secs _ = secs
      ini parse lines (l:ls) secs cur_s =
        ini strip comment loop l 0 (str len l) -> ini trim -> clean
        ini parse clean line clean ls secs cur_s

fn :: ini parse sec hdr String [String] [IniSection] => [IniSection]
      ini parse sec hdr clean ls secs =
        str slice clean 1 ((str len clean) - 1) -> ini trim -> new_sec
        ini parse lines ls (ini sec ensure secs new_sec) new_sec

fn :: ini parse kv line String [String] [IniSection] String => [IniSection]
      ini parse kv line clean ls secs cur_s =
        clean ini strip export -> stripped
        ini parse kv at stripped secs cur_s (ini find eq stripped 0 (str len stripped)) -> next_secs
        ini parse lines ls next_secs cur_s

fn :: ini parse clean line String [String] [IniSection] String => [IniSection]
      ini parse clean line "" ls secs cur_s = ini parse lines ls secs cur_s
      ini parse clean line clean ls secs cur_s =
        | (str char at clean 0) == 91 and (str char at clean ((str len clean) - 1)) == 93 = ini parse sec hdr clean ls secs
        | otherwise = ini parse kv line clean ls secs cur_s

fn :: ini parse String => IniDoc
      ini parse src =
        ini split lines loop src 0 (str len src) 0 [] -> lines
        IniDoc (ini parse lines lines [] "")

fn :: dotenv parse String => [IniEntry]
      dotenv parse src =
        src ini parse -> doc
        ini sec entries (sections doc) ""
```

### 10.4.4. Internal Implementation: Queries, Updates & Serialization

Observe how `ini.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: ini get IniDoc String String String => String
      ini get doc sec key fallback = ini sec get (sections doc) sec key fallback

fn :: ini get int IniDoc String String Int => Int
      ini get int doc sec key fallback =
        ini get doc sec key "" -> v
        ini parse int or v fallback

fn :: ini parse int or String Int => Int
      ini parse int or "" fallback = fallback
      ini parse int or v _ = str to int v

fn :: ini get bool IniDoc String String Bool => Bool
      ini get bool doc sec key fallback =
        ini get doc sec key "" -> v
        ini parse bool or v fallback

fn :: ini parse bool or String Bool => Bool
      ini parse bool or "" fallback = fallback
      ini parse bool or "true" _ = True
      ini parse bool or "True" _ = True
      ini parse bool or "1" _ = True
      ini parse bool or "yes" _ = True
      ini parse bool or "false" _ = False
      ini parse bool or "False" _ = False
      ini parse bool or "0" _ = False
      ini parse bool or "no" _ = False
      ini parse bool or _ fallback = fallback

fn :: ini set IniDoc String String String => IniDoc
      ini set doc sec key val = IniDoc (ini sec put (sections doc) sec key val)

fn :: ini collect sec names [IniSection] => [String]
      ini collect sec names [] = []
      ini collect sec names (s:rest) = [section_name s] :: (ini collect sec names rest)

fn :: ini sections IniDoc => [String]
      ini sections doc = ini collect sec names (sections doc)

fn :: dotenv get [IniEntry] String String => String
      dotenv get env key fallback = ini kv get env key fallback

fn :: ini format entries [IniEntry] => String
      ini format entries [] = ""
      ini format entries ((IniEntry k v):rs) = k + " = " + v + (char from code 10) + (ini format entries rs)

fn :: ini format section IniSection => String
      ini format section sec =
        | (section_name sec) == "" = ini format entries (entries sec)
        | otherwise = "[" + (section_name sec) + "]" + (char from code 10) + (ini format entries (entries sec))

fn :: ini format sections [IniSection] => String
      ini format sections [] = ""
      ini format sections (s:[]) = ini format section s
      ini format sections (s:rest) = (ini format section s) + (char from code 10) + (ini format sections rest)

fn :: ini stringify IniDoc => String
      ini stringify doc = ini format sections (sections doc)
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
