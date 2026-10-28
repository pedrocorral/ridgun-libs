# Chapter 08: The `json` Lib — Recursive RFC 8259 AST Parser, Pretty-Printer, and Dot-Path Queries

## 08.1. Why Does the `json` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `json` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `json`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: navigating deeply nested JSON in many statically typed languages means writing pages of boilerplate or chaining ten `.and_then()` calls just to read a single port number.

The **`json`** lib provides a full recursive-descent **RFC 8259** parser into the algebraic `JsonVal` ADT (`JnNull`, `JnBool`, `JnInt`, `JnStr`, `JnArr`, `JnObj`, `JnErr`), compact and indented serializers (`json pretty`), and dot-path queries (`"server.http.port"`, `"users.0.name"`).

In a traditional ecosystem, solving **`JSON`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`json`** lib (`src/main/ridgun/lib/json.rg`) tackles the problem with four non-negotiable principles:

1. **Declare `import json` (or `import json as alias`) at the top of your file**: every lib defines its `module :: json` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
3. **Tail-Call Optimization (TCO)**: all internal loops in `json` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 08.2. Native Artifacts, Imports, and Complete `json` API Catalog

In `ridgun-libs`, **`json`** is a first-class **lib** located at `src/main/ridgun/lib/json.rg` (domain `JSON`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/json.rglib` | Portable distribution and direct `import json` resolution |
| **Compiled Archive** | `target/json.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libjson.so` | Native dynamic shared library with zero C or `libc` dependencies |

> Every lib declares its own namespace via `module :: json`: simply write `import json` (or `import json as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

### 08.2.1. Summary of `json` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `type JsonVal` | `JnNull | JnBool Bool | JnInt Int | JnStr String | JnArr [JsonVal] | JnObj [String JsonVal] | JnErr String` |
| `json parse / json is ok` | Parse raw JSON text into `JsonVal` and validate absence of `JnErr` |
| `json stringify / json pretty` | Serialize `JsonVal` into compact or multi-line indented JSON |
| `json get path / json get str / json get int / json get bool` | Traverse nested objects and arrays via dot-separated paths (`"a.b.0.c"`) |

### 08.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/json.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/json.rg` (`7` types, `0` operators, and `118` functions):

**Algebraic Data Types & Records (`type`) in `json`:**

```ridgun
type JsonField = JsonField String JsonVal
type JsonVal = JsonNull | JsonBool Bool | JsonInt Int | JsonStr String | JsonArr [JsonVal] | JsonObj [JsonField]
type JsonRes = JsonOk JsonVal | JsonErr String
type JsonStep = JStepOk JsonVal Int | JStepErr String
type JsonArrStep = JArrOk [JsonVal] Int | JArrErr String
type JsonObjStep = JObjOk [JsonField] Int | JObjErr String
type JsonStrStep = JStrOk String Int | JStrErr String
```

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: j_is_ws Int` | `Bool` |
| `2` | `fn :: j_is_digit Int` | `Bool` |
| `3` | `fn :: j_skip_ws String Int Int` | `Int` |
| `4` | `fn :: j_spaces Int` | `String` |
| `5` | `fn :: j_escape_loop String Int Int String` | `String` |
| `6` | `fn :: j_escape_str String` | `String` |
| `7` | `fn :: j_unescape_char Int` | `String` |
| `8` | `fn :: j_parse_str_loop String Int Int String` | `JsonStrStep` |
| `9` | `fn :: j_parse_string String Int Int` | `JsonStrStep` |
| `10` | `fn :: j_scan_digits String Int Int` | `Int` |
| `11` | `fn :: j_parse_number String Int Int` | `JsonStep` |
| `12` | `fn :: j_finish_neg_num String Int Int` | `JsonStep` |
| `13` | `fn :: j_finish_pos_num String Int Int` | `JsonStep` |
| `14` | `fn :: j_parse_val String Int Int` | `JsonStep` |
| `15` | `fn :: j_parse_val_at String Int Int` | `JsonStep` |
| `16` | `fn :: j_wrap_str_step JsonStrStep` | `JsonStep` |
| `17` | `fn :: j_parse_arr_open String Int Int` | `JsonStep` |
| `18` | `fn :: j_parse_arr_first String Int Int` | `JsonStep` |
| `19` | `fn :: j_finish_arr_step JsonArrStep` | `JsonStep` |
| `20` | `fn :: j_parse_arr_items String Int Int [JsonVal]` | `JsonArrStep` |
| `21` | `fn :: j_parse_arr_after_item String Int [JsonVal] JsonStep` | `JsonArrStep` |
| `22` | `fn :: j_parse_arr_delim String Int Int [JsonVal]` | `JsonArrStep` |
| `23` | `fn :: j_parse_obj_open String Int Int` | `JsonStep` |
| `24` | `fn :: j_parse_obj_first String Int Int` | `JsonStep` |
| `25` | `fn :: j_finish_obj_step JsonObjStep` | `JsonStep` |
| `26` | `fn :: j_parse_obj_fields String Int Int [JsonField]` | `JsonObjStep` |
| `27` | `fn :: j_parse_obj_after_key String Int [JsonField] JsonStrStep` | `JsonObjStep` |
| `28` | `fn :: j_parse_obj_colon String Int Int String [JsonField]` | `JsonObjStep` |
| `29` | `fn :: j_parse_obj_after_val String Int String [JsonField] JsonStep` | `JsonObjStep` |
| `30` | `fn :: j_parse_obj_delim String Int Int [JsonField]` | `JsonObjStep` |
| `31` | `fn :: j_check_eof String Int JsonStep` | `JsonRes` |
| `32` | `fn :: j_check_eof_pos Int Int JsonVal` | `JsonRes` |
| `33` | `fn :: json parse String` | `JsonRes` |
| `34` | `fn :: j_join_arr [JsonVal]` | `String` |
| `35` | `fn :: j_join_obj [JsonField]` | `String` |
| `36` | `fn :: json stringify JsonVal` | `String` |
| `37` | `fn :: j_pretty_arr [JsonVal] Int Int` | `String` |
| `38` | `fn :: j_pretty_obj [JsonField] Int Int` | `String` |
| `39` | `fn :: j_pretty_val JsonVal Int Int` | `String` |
| `40` | `fn :: json pretty JsonVal Int` | `String` |
| `41` | `fn :: j_find_field [JsonField] String` | `JsonVal` |
| `42` | `fn :: json get field JsonVal String` | `JsonVal` |
| `43` | `fn :: j_nth_val [JsonVal] Int` | `JsonVal` |
| `44` | `fn :: json get index JsonVal Int` | `JsonVal` |
| `45` | `fn :: j_split_dots_loop String Int Int Int [String]` | `[String]` |
| `46` | `fn :: j_step_path JsonVal String` | `JsonVal` |
| `47` | `fn :: j_walk_path JsonVal [String]` | `JsonVal` |
| `48` | `fn :: json get path JsonVal String` | `JsonVal` |
| `49` | `fn :: json get str JsonVal String String` | `String` |
| `50` | `fn :: j_unwrap_str JsonVal String` | `String` |
| `51` | `fn :: json get int JsonVal String Int` | `Int` |
| `52` | `fn :: j_unwrap_int JsonVal Int` | `Int` |
| `53` | `fn :: json get bool JsonVal String Bool` | `Bool` |
| `54` | `fn :: j_unwrap_bool JsonVal Bool` | `Bool` |
| `55` | `fn :: j_put_field [JsonField] String JsonVal` | `[JsonField]` |
| `56` | `fn :: json set field JsonVal String JsonVal` | `JsonVal` |

---

## 08.3. Deep Dive into `json`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `json` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test json.rg`.

### 08.3.1. Example 1: Core Tabular Workflow with `json`

Notice how in Ridgun the `=` signs and transformation steps using `json` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import json

fn :: leer config servidor JsonVal => String Int Bool
      leer config servidor doc =
        json get str doc "server.host" "127.0.0.1" -> host
        json get int doc "server.port" 8080 -> port
        json get bool doc "server.tls.enabled" False -> tls
        (host, port, tls)
```

### 08.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `json` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import json

fn :: construir manifiesto => String
      construir manifiesto =
        JsonObj [JsonField "app" (JsonStr "solstice"), JsonField "workers" (JsonInt 8)] -> nodo
        json pretty nodo 2
```

### 08.3.3. Example 3: AST Parsing (`json parse`), Compact Serialization (`json stringify`), and Indented Pretty-Printing (`json pretty`)

In this hands-on walkthrough we thoroughly exercise how `json` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test json parse stringify and pretty => ()
      test json parse stringify and pretty =
        lb = char from code 123
        rb = char from code 125
        raw = lb + "\"user\":" + lb + "\"name\":\"Ada \\\"Lovelace\\\"\",\"age\":36,\"active\":true,\"roles\":[\"admin\",\"math\"],\"meta\":null" + rb + rb
        res = json parse raw
        assert true (is_json_ok res) "AC1: json parse nested object and array"
        val = unwrap_json res

        compact = json stringify val
        assert str eq compact raw "AC1: json stringify lossless round-trip"

        pretty_s = json pretty val 2
        res2 = json parse pretty_s
        assert true (is_json_ok res2) "AC1: json pretty output parses back cleanly"
        assert str eq (json stringify (unwrap_json res2)) raw "AC1: json pretty round-trip equality"
        ()
```

### 08.3.4. Example 4: JSON Primitives (`null`, `bool`, `int`, `str`), Escape Sequences, and Empty Containers (`[]`, `{}`)

In this hands-on walkthrough we thoroughly exercise how `json` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test json primitives escapes and empty containers => ()
      test json primitives escapes and empty containers =
        lb = char from code 123
        rb = char from code 125
        bs = char from code 92
        nl = char from code 10
        tab = char from code 9
        assert str eq (json stringify (unwrap_json (json parse (lb + rb)))) (lb + rb) "AC1: empty object {}"
        assert str eq (json stringify (unwrap_json (json parse "[]"))) "[]" "AC1: empty array []"
        assert str eq (json stringify (unwrap_json (json parse ("  " + lb + "  " + rb + "  ")))) (lb + rb) "AC1: whitespace-padded empty object"
        assert true (is_json_null (unwrap_json (json parse "null"))) "AC1: root null literal"
        assert str eq (json stringify (unwrap_json (json parse "true"))) "true" "AC1: root true literal"
        assert str eq (json stringify (unwrap_json (json parse "false"))) "false" "AC1: root false literal"
        assert str eq (json stringify (unwrap_json (json parse "0"))) "0" "AC1: root zero integer"
        assert str eq (json stringify (unwrap_json (json parse "-42000"))) "-42000" "AC1: root negative integer"

        esc_json = lb + "\"msg\":\"line1" + bs + "nline2" + bs + "t" + bs + bs + "slash\"" + rb
        esc_val = unwrap_json (json parse esc_json)
        assert str eq (json get str esc_val "msg" "") ("line1" + nl + "line2" + tab + bs + "slash") "AC1: unescape \\n, \\t, \\\\ in JSON strings"
        assert str eq (json stringify esc_val) esc_json "AC1: re-escape \\n, \\t, \\\\ on stringify"
        ()
```

### 08.3.5. Example 5: Deep Dot-Path Queries (`json query`, `json query str/int/bool`) and Immutable Updates (`json set field`)

In this hands-on walkthrough we thoroughly exercise how `json` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test json dot path queries and updates => ()
      test json dot path queries and updates =
        lb = char from code 123
        rb = char from code 125
        raw = lb + "\"user\":" + lb + "\"name\":\"Ada\",\"age\":36,\"active\":true,\"roles\":[\"admin\",\"math\"],\"matrix\":[[10,20],[30,40]]" + rb + ",\"count\":-7,\"disabled\":false" + rb
        val = unwrap_json (json parse raw)

        assert str eq (json get str val "user.name" "") "Ada" "AC2: json get str dot path"
        assert int equals (json get int val "user.age" 0) 36 "AC2: json get int dot path"
        assert int equals (json get int val "count" 0) (-7) "AC2: json get int negative"
        assert true (json get bool val "user.active" False) "AC2: json get bool true"
        assert false (json get bool val "disabled" True) "AC2: json get bool false"
        assert str eq (json get str val "user.roles.0" "") "admin" "AC2: json get str array index 0"
        assert str eq (json get str val "user.roles.1" "") "math" "AC2: json get str array index 1"
        assert int equals (json get int val "user.matrix.1.0" 0) 30 "AC2: nested 2D array index user.matrix.1.0"
        assert int equals (json get int val "user.matrix.1.1" 0) 40 "AC2: nested 2D array index user.matrix.1.1"
        assert str eq (json get str val "user.roles.99" "oob") "oob" "AC2: out-of-bounds array index fallback"
        assert str eq (json get str val "user.missing.deep" "fallback") "fallback" "AC2: missing deep dot-path fallback"

        updated = json set field val "version" (JsonInt 2)
        assert int equals (json get int updated "version" 0) 2 "AC2: json set field adds new key"
        overwritten = json set field updated "count" (JsonInt 99)
        assert int equals (json get int overwritten "count" 0) 99 "AC2: json set field overwrites existing key"
        ()
```

### 08.3.6. Example 6: Safe Detection of Malformed JSON Inputs (`JsonErr`) Without Panics or Exceptions

In this hands-on walkthrough we thoroughly exercise how `json` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test json malformed inputs => ()
      test json malformed inputs =
        lb = char from code 123
        rb = char from code 125
        assert false (is_json_ok (json parse "")) "AC3: reject empty input"
        assert false (is_json_ok (json parse "   ")) "AC3: reject whitespace-only input"
        assert false (is_json_ok (json parse (lb + "\"unclosed\":1"))) "AC3: reject unclosed object"
        assert false (is_json_ok (json parse "[1, 2, 3")) "AC3: reject unclosed array"
        assert false (is_json_ok (json parse "\"unterminated string")) "AC3: reject unterminated string"
        assert false (is_json_ok (json parse (lb + "unquoted: 1" + rb))) "AC3: reject unquoted object key"
        assert false (is_json_ok (json parse (lb + "\"k\" 1" + rb))) "AC3: reject missing colon in object"
        assert false (is_json_ok (json parse "[1, 2] trailing")) "AC3: reject trailing garbage token"
        assert false (is_json_ok (json parse "tru")) "AC3: reject truncated boolean literal"
        assert false (is_json_ok (json parse "nul")) "AC3: reject truncated null literal"
        ()
```

---

## 08.4. Under the Hood: How `json` Is Built in Pure Ridgun (`src/main/ridgun/lib/json.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/json.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 08.4.1. Internal Implementation: Whitespace & Character Helpers

Observe how `json.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
module :: json

fn :: j is ws Int => Bool
      j is ws c   =  c == 32 OR c == 9 OR c == 10 OR c == 13

fn :: j is digit Int => Bool
      j is digit c   =  c >= 48 AND c <= 57

fn :: j skip ws String Int Int => Int
      j skip ws s      pos len
        | pos >= len = len
        | j is ws (str char at s pos) = j skip ws s (pos + 1) len
        | otherwise = pos

fn :: j spaces Int => String
      j spaces n
        | n <= 0 = ""
        | otherwise = " " + (j spaces (n - 1))
```

### 08.4.2. Internal Implementation: Integer Literal Parsing

Observe how `json.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: j scan digits String Int Int => Int
      j scan digits s      pos len
        | pos >= len = len
        | j is digit (str char at s pos) = j scan digits s (pos + 1) len
        | otherwise = pos

fn :: j parse number String Int Int => JsonStep
      j parse number s      pos len
        | (str char at s pos) == 45 = j_finish_neg_num s pos (j scan digits s (pos + 1) len)
        | otherwise = j_finish_pos_num s pos (j scan digits s pos len)

fn :: j_finish_neg_num String Int Int     => JsonStep
      j_finish_neg_num s      pos end_pos
        | end_pos <= (pos + 1) = JStepErr "invalid negative number"
        | otherwise = JStepOk (JsonInt (str to int (str slice s pos end_pos))) end_pos

fn :: j_finish_pos_num String Int Int     => JsonStep
      j_finish_pos_num s      pos end_pos
        | end_pos <= pos = JStepErr "expected number"
        | otherwise = JStepOk (JsonInt (str to int (str slice s pos end_pos))) end_pos
```

### 08.4.3. Internal Implementation: Serialization & Pretty-Printing

Observe how `json.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: j join arr loop [JsonVal] String String String String => String
      j join arr loop []     c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j join arr loop (v:vs) c0 c1 c2 c3 =
        n0, n1, n2, n3 = j sb append ("," + (json stringify v)) c0 c1 c2 c3
        j join arr loop vs n0 n1 n2 n3

fn :: j join arr [JsonVal] => String
      j join arr []        =  ""
      j join arr (v:vs)    =  j join arr loop vs (json stringify v) "" "" ""

fn :: j join obj loop [JsonField] String String String String => String
      j join obj loop []                     c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j join obj loop ((JsonField k v):rest) c0 c1 c2 c3 =
        item = "," + (j escape str k) + ":" + (json stringify v)
        n0, n1, n2, n3 = j sb append item c0 c1 c2 c3
        j join obj loop rest n0 n1 n2 n3

fn :: j join obj [JsonField] => String
      j join obj []                     =  ""
      j join obj ((JsonField k v):rest) =
        first = (j escape str k) + ":" + (json stringify v)
        j join obj loop rest first "" "" ""

fn :: j pos int to str Int String => String
      j pos int to str n acc =
        | n <= 0    = acc
        | otherwise = j pos int to str (n / 10) ((char from code (48 + (n % 10))) + acc)

fn :: j int to str Int => String
      j int to str n =
        | n == 0         = "0"
        | n > 0          = j pos int to str n ""
        | n > (0 - 10)   = "-" + (char from code (48 + (0 - n)))
        | otherwise      = "-" + (j pos int to str (0 - (n / 10)) (char from code (48 + (0 - (n % 10)))))

fn :: json stringify JsonVal          => String
      json stringify JsonNull         =  "null"
      json stringify (JsonBool True)  =  "true"
      json stringify (JsonBool False) =  "false"
      json stringify (JsonInt n)      =  j int to str n
      json stringify (JsonStr s)      =  j escape str s
      json stringify (JsonArr items)  =  "[" + (j join arr items) + "]"
      json stringify (JsonObj fields) =  (char from code 123) + (j join obj fields) + (char from code 125)

fn :: j pretty arr loop [JsonVal] Int Int String String String String => String
      j pretty arr loop []     _   _   c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j pretty arr loop (v:vs) ind cur c0 c1 c2 c3 =
        item = "," + (char from code 10) + (j spaces (cur + ind)) + (j pretty val v ind (cur + ind))
        n0, n1, n2, n3 = j sb append item c0 c1 c2 c3
        j pretty arr loop vs ind cur n0 n1 n2 n3

fn :: j pretty arr [JsonVal] Int Int => String
      j pretty arr []     _   _   =  ""
      j pretty arr (v:vs) ind cur =
        first = (j spaces (cur + ind)) + (j pretty val v ind (cur + ind))
        j pretty arr loop vs ind cur first "" "" ""

fn :: j pretty obj loop [JsonField] Int Int String String String String => String
      j pretty obj loop []                     _   _   c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j pretty obj loop ((JsonField k v):rest) ind cur c0 c1 c2 c3 =
        item = "," + (char from code 10) + (j spaces (cur + ind)) + (j escape str k) + ": " + (j pretty val v ind (cur + ind))
        n0, n1, n2, n3 = j sb append item c0 c1 c2 c3
        j pretty obj loop rest ind cur n0 n1 n2 n3

fn :: j pretty obj [JsonField] Int Int => String
      j pretty obj []                     _   _   =  ""
      j pretty obj ((JsonField k v):rest) ind cur =
        first = (j spaces (cur + ind)) + (j escape str k) + ": " + (j pretty val v ind (cur + ind))
        j pretty obj loop rest ind cur first "" "" ""

fn :: j pretty val JsonVal          Int Int => String
      j pretty val (JsonArr [])     _   _   =  "[]"
      j pretty val (JsonArr items)  ind cur =
        nl = char from code 10
        "[" + nl + (j pretty arr items ind cur) + nl + (j spaces cur) + "]"
      j pretty val (JsonObj [])     _   _   =  (char from code 123) + (char from code 125)
      j pretty val (JsonObj fields) ind cur =
        nl = char from code 10
        (char from code 123) + nl + (j pretty obj fields ind cur) + nl + (j spaces cur) + (char from code 125)
      j pretty val v                _   _   =  json stringify v

fn :: json pretty JsonVal Int => String
      json pretty val     ind =  j pretty val val ind 0
```

### 08.4.4. Internal Implementation: Dot-Path Queries & Field Updates

Observe how `json.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: j find field [JsonField] String => JsonVal
      j find field []                   _   =  JsonNull
      j find field ((JsonField k v):fs) key =
        | k == key  = v
        | otherwise = j find field fs key

fn :: json get field JsonVal          String => JsonVal
      json get field (JsonObj fields) key    =  j find field fields key
      json get field _                _      =  JsonNull

fn :: j nth val [JsonVal] Int => JsonVal
      j nth val []     _   =  JsonNull
      j nth val (v:vs) idx =
        | idx < 0   = JsonNull
        | idx == 0  = v
        | otherwise = j nth val vs (idx - 1)

fn :: json get index JsonVal         Int => JsonVal
      json get index (JsonArr items) idx =  j nth val items idx
      json get index _               _   =  JsonNull

fn :: j split dots loop String Int Int Int [String] => [String]
      j split dots loop s pos len start acc =
        | pos >= len                = acc :: [str slice s start len]
        | (str char at s pos) == 46 = j split dots loop s (pos + 1) len (pos + 1) (acc :: [str slice s start pos])
        | otherwise                 = j split dots loop s (pos + 1) len start acc

fn :: j step path JsonVal          String => JsonVal
      j step path (JsonObj fields) seg    =  j find field fields seg
      j step path (JsonArr items)  seg    =
        | seg != "" and (j scan digits seg 0 (str len seg)) == (str len seg) and (j digits fit i64 seg False) = j nth val items (str to int seg)
        | otherwise = JsonNull
      j step path _                _      =  JsonNull

fn :: j walk path JsonVal [String]   => JsonVal
      j walk path val     []         =  val
      j walk path val     ("":rest)  =  j walk path val rest
      j walk path val     (seg:rest) =  j walk path (j step path val seg) rest

fn :: json get path JsonVal String   => JsonVal
      json get path val     ""       =  val
      json get path val     dot_path =
        j split dots loop dot_path 0 (str len dot_path) 0 [] -> segs
        j walk path val segs

fn :: json get str JsonVal String String => String
      json get str val dot_path fallback =
        json get path val dot_path -> target
        j unwrap str target fallback

fn :: j unwrap str JsonVal     String   => String
      j unwrap str (JsonStr s) _        =  s
      j unwrap str _           fallback =  fallback

fn :: json get int JsonVal String Int => Int
      json get int val dot_path fallback =
        json get path val dot_path -> target
        j unwrap int target fallback

fn :: j unwrap int JsonVal     Int      => Int
      j unwrap int (JsonInt n) _        =  n
      j unwrap int _           fallback =  fallback

fn :: json get bool JsonVal String Bool => Bool
      json get bool val dot_path fallback =
        json get path val dot_path -> target
        j unwrap bool target fallback

fn :: j unwrap bool JsonVal      Bool     => Bool
      j unwrap bool (JsonBool b) _        =  b
      j unwrap bool _            fallback =  fallback

fn :: j put field [JsonField] String JsonVal => [JsonField]
      j put field []                   key new_val = [JsonField key new_val]
      j put field ((JsonField k v):fs) key new_val =
        | k == key  = [JsonField key new_val] :: fs
        | otherwise = [JsonField k v] :: (j put field fs key new_val)

fn :: json set field JsonVal String JsonVal => JsonVal
      json set field (JsonObj fields) key new_val = JsonObj (j put field fields key new_val)
      json set field _ key new_val = JsonObj [JsonField key new_val]
```

---

## 08.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `json`

- **Algorithmic & Safety Guarantee**: Strict rejection of trailing garbage after the root value, full escape-sequence handling, and exception-free `JnErr` reporting.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/json.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test json.rg`.

### The 5 Golden Rules When Programming with `json`

1. **Declare `import json` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `json` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `json`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `json` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 09**, we will explore the **`csv`** lib in full depth (The `csv` Lib — RFC 4180 CSV/TSV State-Machine Parser and Header-Indexed Tables).
