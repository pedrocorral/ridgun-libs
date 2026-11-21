# Chapter 08: The `json` Lib — Recursive RFC 8259 AST Parser, Pretty-Printer, and Dot-Path Queries

## 08.1. Why Does the `json` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `json` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `json`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: navigating deeply nested JSON in many statically typed languages means writing pages of boilerplate or chaining ten `.and_then()` calls just to read a single port number.

The **`json`** lib provides a full recursive-descent **RFC 8259** parser into the algebraic `JsonVal` ADT (`JsonNull`, `JsonBool`, `JsonInt`, `JsonStr`, `JsonArr`, `JsonObj`, `JsonErr`), compact and indented serializers (`json pretty`), and dot-path queries (`"server.http.port"`, `"users.0.name"`).

In a traditional ecosystem, solving **`JSON`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`json`** lib (`src/main/ridgun/lib/json.ridgun`) tackles the problem with four non-negotiable principles:

1. **Declare `import json` (or `import json as alias`) at the top of your file**: every lib defines its `module :: json` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
3. **Tail-Call Optimization (TCO)**: all internal loops in `json` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 08.2. Native Artifacts, Imports, and Complete `json` API Catalog

In `ridgun-libs`, **`json`** is a first-class **lib** located at `src/main/ridgun/lib/json.ridgun` (domain `JSON`). When built with `stable bundle`, it compiles into one native artifact:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/json.ridgunlib` | Portable distribution and direct `import json` resolution |

> Every lib declares its own namespace via `module :: json`: simply write `import json` (or `import json as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

### 08.2.1. Summary of `json` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `type JsonVal` | `JnNull | JnBool Bool | JnInt Int | JnStr String | JnArr [JsonVal] | JnObj [String JsonVal] | JnErr String` |
| `json parse / json parse with limits` | Parse raw JSON text into `JsonVal` and validate absence of `JsonErr` |
| `json stringify / json pretty` | Serialize `JsonVal` into compact or multi-line indented JSON |
| `json get path / json get str / json get int / json get bool` | Traverse nested objects and arrays via dot-separated paths (`"a.b.0.c"`) |

### 08.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/json.ridgun`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/json.ridgun` (`7` types, `0` operators, and `140` functions):

**Algebraic Data Types & Records (`type`) in `json`:**

```ridgun
type JsonField = JsonField String JsonVal
type JsonVal = JsonNull | JsonBool Bool | JsonInt Int | JsonNum String | JsonStr String | JsonArr [JsonVal] | JsonObj [JsonField]
type JsonRes = JsonOk JsonVal | JsonErr String
type JsonStep = JStepOk JsonVal Int | JStepErr String
type JsonArrStep = JArrOk [JsonVal] Int | JArrErr String
type JsonObjStep = JObjOk [JsonField] Int | JObjErr String
type JsonStrStep = JStrOk String Int | JStrErr String
```

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: j is ws Int` | `Bool` |
| `2` | `fn :: j is digit Int` | `Bool` |
| `3` | `fn :: j skip ws String Int Int` | `Int` |
| `4` | `fn :: j spaces loop Int String` | `String` |
| `5` | `fn :: j spaces Int` | `String` |
| `6` | `fn :: j raw byte ub Int` | `String` |
| `7` | `fn :: j raw byte Int` | `String` |
| `8` | `fn :: j sb append3 String String` | `String String String String` |
| `9` | `fn :: j sb append2 String String String` | `String String String String` |
| `10` | `fn :: j sb append1 String String String String` | `String String String String` |
| `11` | `fn :: j sb append String String String String String` | `String String String String` |
| `12` | `fn :: j sb finish String String String String` | `String` |
| `13` | `fn :: j rev vals loop [JsonVal] [JsonVal]` | `[JsonVal]` |
| `14` | `fn :: j rev vals [JsonVal]` | `[JsonVal]` |
| `15` | `fn :: j rev fields loop [JsonField] [JsonField]` | `[JsonField]` |
| `16` | `fn :: j rev fields [JsonField]` | `[JsonField]` |
| `17` | `fn :: j hex digit Int` | `Int` |
| `18` | `fn :: j combine hex4 Int Int Int Int` | `Int` |
| `19` | `fn :: j parse hex4 String Int Int` | `Int` |
| `20` | `fn :: j utf8 from cp Int` | `String` |
| `21` | `fn :: j hex2 lower Int` | `String` |
| `22` | `fn :: j esc special Int` | `String` |
| `23` | `fn :: j scan esc plain2 String Int Int Int` | `Int` |
| `24` | `fn :: j scan esc plain String Int Int` | `Int` |
| `25` | `fn :: j escape run String Int Int Int String String String String` | `String` |
| `26` | `fn :: j escape loop String Int Int String String String String` | `String` |
| `27` | `fn :: j escape str String` | `String` |
| `28` | `fn :: j unescape simple Int` | `String` |
| `29` | `fn :: j finish surrogate String Int Int Int Int String String String String` | `JsonStrStep` |
| `30` | `fn :: j parse u surrogate String Int Int Int String String String String` | `JsonStrStep` |
| `31` | `fn :: j dispatch u escape String Int Int Int String String String String` | `JsonStrStep` |
| `32` | `fn :: j parse u escape String Int Int String String String String` | `JsonStrStep` |
| `33` | `fn :: j finish simple escape String Int Int String String String String String` | `JsonStrStep` |
| `34` | `fn :: j parse escape char String Int Int Int String String String String` | `JsonStrStep` |
| `35` | `fn :: j parse escape String Int Int String String String String` | `JsonStrStep` |
| `36` | `fn :: j byte at String Int` | `Int` |
| `37` | `fn :: j is cont byte Int` | `Bool` |
| `38` | `fn :: j utf8 len2 Int Int` | `Int` |
| `39` | `fn :: j utf8 len3 Int Int Int` | `Int` |
| `40` | `fn :: j utf8 len4 Int Int Int Int` | `Int` |
| `41` | `fn :: j valid utf8 step String Int Int Int` | `Int` |
| `42` | `fn :: j parse utf8 seq String Int Int Int String String String String` | `JsonStrStep` |
| `43` | `fn :: j scan str plain2 String Int Int Int` | `Int` |
| `44` | `fn :: j scan str plain String Int Int` | `Int` |
| `45` | `fn :: j parse str char String Int Int Int String String String String` | `JsonStrStep` |
| `46` | `fn :: j parse str run String Int Int Int String String String String` | `JsonStrStep` |
| `47` | `fn :: j parse str loop String Int Int String String String String` | `JsonStrStep` |
| `48` | `fn :: j parse string fast String Int Int Int` | `JsonStrStep` |
| `49` | `fn :: j parse string String Int Int` | `JsonStrStep` |
| `50` | `fn :: j scan digits String Int Int` | `Int` |
| `51` | `fn :: j str cmp2 Int Int String String Int Int` | `Int` |
| `52` | `fn :: j str cmp loop String String Int Int` | `Int` |
| `53` | `fn :: j digits fit i64 len String Bool Int` | `Bool` |
| `54` | `fn :: j digits fit i64 String Bool` | `Bool` |
| `55` | `fn :: j parse pos digits loop String Int Int Int` | `Int` |
| `56` | `fn :: j parse neg digits loop String Int Int Int` | `Int` |
| `57` | `fn :: j parse i64 exact String Bool` | `Int` |
| `58` | `fn :: j scan exp after sign2 Int Int` | `Int` |
| `59` | `fn :: j scan exp after sign String Int Int` | `Int` |
| `60` | `fn :: j scan opt exp sign String Int Int Int` | `Int` |
| `61` | `fn :: j scan opt exp char String Int Int Int` | `Int` |
| `62` | `fn :: j scan opt exp String Int Int` | `Int` |
| `63` | `fn :: j scan opt frac2 String Int Int Int` | `Int` |
| `64` | `fn :: j scan opt frac String Int Int` | `Int` |
| `65` | `fn :: j parse pos range String Int Int Int` | `Int` |
| `66` | `fn :: j parse neg range String Int Int Int` | `Int` |
| `67` | `fn :: j parse i64 range String Int Int Bool` | `Int` |
| `68` | `fn :: j finish int digs String Bool Int` | `JsonStep` |
| `69` | `fn :: j finish int range String Int Int Bool Int` | `JsonStep` |
| `70` | `fn :: j finish num after frac String Int Int Bool Int Int` | `JsonStep` |
| `71` | `fn :: j finish num after int String Int Int Bool Int Int` | `JsonStep` |
| `72` | `fn :: j parse num int part2 String Int Int Bool Int Int Int` | `JsonStep` |
| `73` | `fn :: j parse num int part String Int Int Bool Int` | `JsonStep` |
| `74` | `fn :: j parse number String Int Int` | `JsonStep` |
| `75` | `fn :: j has field [JsonField] String` | `Bool` |
| `76` | `fn :: j parse val String Int Int Int` | `JsonStep` |
| `77` | `fn :: j parse val char String Int Int Int Int` | `JsonStep` |
| `78` | `fn :: j parse val at String Int Int Int` | `JsonStep` |
| `79` | `fn :: j wrap str step JsonStrStep` | `JsonStep` |
| `80` | `fn :: j parse arr open String Int Int Int` | `JsonStep` |
| `81` | `fn :: j parse arr first String Int Int Int` | `JsonStep` |
| `82` | `fn :: j finish arr step JsonArrStep` | `JsonStep` |
| `83` | `fn :: j parse arr items String Int Int Int [JsonVal]` | `JsonArrStep` |
| `84` | `fn :: j parse arr after item String Int Int [JsonVal] JsonStep` | `JsonArrStep` |
| `85` | `fn :: j parse arr delim String Int Int Int [JsonVal]` | `JsonArrStep` |
| `86` | `fn :: j parse obj open String Int Int Int` | `JsonStep` |
| `87` | `fn :: j parse obj first String Int Int Int` | `JsonStep` |
| `88` | `fn :: j finish obj step JsonObjStep` | `JsonStep` |
| `89` | `fn :: j parse obj fields String Int Int Int [JsonField]` | `JsonObjStep` |
| `90` | `fn :: j parse obj after key String Int Int [JsonField] JsonStrStep` | `JsonObjStep` |
| `91` | `fn :: j parse obj colon String Int Int Int String [JsonField]` | `JsonObjStep` |
| `92` | `fn :: j parse obj after val String Int Int String [JsonField] JsonStep` | `JsonObjStep` |
| `93` | `fn :: j parse obj delim String Int Int Int [JsonField]` | `JsonObjStep` |
| `94` | `fn :: j check eof String Int JsonStep` | `JsonRes` |
| `95` | `fn :: j check eof pos Int Int JsonVal` | `JsonRes` |
| `96` | `fn :: json parse with limits String Int Int` | `JsonRes` |
| `97` | `fn :: json parse String` | `JsonRes` |
| `98` | `fn :: j join arr loop [JsonVal] String String String String` | `String` |
| `99` | `fn :: j join arr [JsonVal]` | `String` |
| `100` | `fn :: j join obj loop [JsonField] String String String String` | `String` |
| `101` | `fn :: j join obj [JsonField]` | `String` |
| `102` | `fn :: j pos int to str Int String` | `String` |
| `103` | `fn :: j int to str Int` | `String` |
| `104` | `fn :: json stringify JsonVal` | `String` |
| `105` | `fn :: j pretty arr loop [JsonVal] Int Int String String String String` | `String` |
| `106` | `fn :: j pretty arr [JsonVal] Int Int` | `String` |
| `107` | `fn :: j pretty obj loop [JsonField] Int Int String String String String` | `String` |
| `108` | `fn :: j pretty obj [JsonField] Int Int` | `String` |
| `109` | `fn :: j pretty val JsonVal Int Int` | `String` |
| `110` | `fn :: json pretty JsonVal Int` | `String` |
| `111` | `fn :: j lookup field opt [JsonField] String` | `Option JsonVal` |
| `112` | `fn :: json find field JsonVal String` | `Option JsonVal` |
| `113` | `fn :: json has field JsonVal String` | `Bool` |
| `114` | `fn :: j find field [JsonField] String` | `JsonVal` |
| `115` | `fn :: json get field JsonVal String` | `JsonVal` |
| `116` | `fn :: j nth val [JsonVal] Int` | `JsonVal` |
| `117` | `fn :: json get index JsonVal Int` | `JsonVal` |
| `118` | `fn :: j split dots loop String Int Int Int [String]` | `[String]` |
| `119` | `fn :: j step path JsonVal String` | `JsonVal` |
| `120` | `fn :: j walk path JsonVal [String]` | `JsonVal` |
| `121` | `fn :: json get path JsonVal String` | `JsonVal` |
| `122` | `fn :: json num text JsonVal` | `String` |
| `123` | `fn :: j digit real Int` | `Real` |
| `124` | `fn :: j pow10 loop Int Real` | `Real` |
| `125` | `fn :: j apply exp Real Bool Int` | `Real` |
| `126` | `fn :: j parse real exp String Int Int Real Bool` | `Real` |
| `127` | `fn :: j parse real exp sign String Int Int Real` | `Real` |
| `128` | `fn :: j parse real frac loop String Int Int Real Real Real` | `Real` |
| `129` | `fn :: j parse real int loop String Int Int Real` | `Real` |
| `130` | `fn :: j parse real str String` | `Real` |
| `131` | `fn :: j unwrap float JsonVal Real` | `Real` |
| `132` | `fn :: json get float JsonVal String Real` | `Real` |
| `133` | `fn :: json get str JsonVal String String` | `String` |
| `134` | `fn :: j unwrap str JsonVal String` | `String` |
| `135` | `fn :: json get int JsonVal String Int` | `Int` |
| `136` | `fn :: j unwrap int JsonVal Int` | `Int` |
| `137` | `fn :: json get bool JsonVal String Bool` | `Bool` |
| `138` | `fn :: j unwrap bool JsonVal Bool` | `Bool` |
| `139` | `fn :: j put field [JsonField] String JsonVal` | `[JsonField]` |
| `140` | `fn :: json set field JsonVal String JsonVal` | `JsonVal` |

---

## 08.3. Deep Dive into `json`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `json` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test json.ridgun`.

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

Every function in the `json` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 38 libs in `ridgun-libs`:

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
        is json ok res -> assert true "AC1: json parse nested object and array"
        val = unwrap json res

        compact = json stringify val
        compact -> assert str eq raw "AC1: json stringify lossless round-trip"

        pretty_s = json pretty val 2
        res2 = json parse pretty_s
        is json ok res2 -> assert true "AC1: json pretty output parses back cleanly"
        json stringify (unwrap json res2) -> assert str eq raw "AC1: json pretty round-trip equality"
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
        json stringify (unwrap json (json parse (lb + rb))) -> assert str eq (lb + rb) "AC1: empty object {}"
        json stringify (unwrap json (json parse "[]")) -> assert str eq "[]" "AC1: empty array []"
        json stringify (unwrap json (json parse ("  " + lb + "  " + rb + "  "))) -> assert str eq (lb + rb) "AC1: whitespace-padded empty object"
        is json null (unwrap json (json parse "null")) -> assert true "AC1: root null literal"
        json stringify (unwrap json (json parse "true")) -> assert str eq "true" "AC1: root true literal"
        json stringify (unwrap json (json parse "false")) -> assert str eq "false" "AC1: root false literal"
        json stringify (unwrap json (json parse "0")) -> assert str eq "0" "AC1: root zero integer"
        json stringify (unwrap json (json parse "-42000")) -> assert str eq "-42000" "AC1: root negative integer"

        esc_json = lb + "\"msg\":\"line1" + bs + "nline2" + bs + "t" + bs + bs + "slash\"" + rb
        esc_val = unwrap json (json parse esc_json)
        json get str esc_val "msg" "" -> assert str eq ("line1" + nl + "line2" + tab + bs + "slash") "AC1: unescape \\n, \\t, \\\\ in JSON strings"
        json stringify esc_val -> assert str eq esc_json "AC1: re-escape \\n, \\t, \\\\ on stringify"
        ()
```

### 08.3.5. Example 5: Deep Dot-Path Queries (`json get path`, `json get str/int/bool`) and Immutable Updates (`json set field`)

In this hands-on walkthrough we thoroughly exercise how `json` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test json dot path queries and updates => ()
      test json dot path queries and updates =
        lb = char from code 123
        rb = char from code 125
        raw = lb + "\"user\":" + lb + "\"name\":\"Ada\",\"age\":36,\"active\":true,\"roles\":[\"admin\",\"math\"],\"matrix\":[[10,20],[30,40]]" + rb + ",\"count\":-7,\"disabled\":false" + rb
        val = unwrap json (json parse raw)

        json get str val "user.name" "" -> assert str eq "Ada" "AC2: json get str dot path"
        json get int val "user.age" 0 -> assert int equals 36 "AC2: json get int dot path"
        json get int val "count" 0 -> assert int equals (-7) "AC2: json get int negative"
        json get bool val "user.active" False -> assert true "AC2: json get bool true"
        json get bool val "disabled" True -> assert false "AC2: json get bool false"
        json get str val "user.roles.0" "" -> assert str eq "admin" "AC2: json get str array index 0"
        json get str val "user.roles.1" "" -> assert str eq "math" "AC2: json get str array index 1"
        json get int val "user.matrix.1.0" 0 -> assert int equals 30 "AC2: nested 2D array index user.matrix.1.0"
        json get int val "user.matrix.1.1" 0 -> assert int equals 40 "AC2: nested 2D array index user.matrix.1.1"
        json get str val "user.roles.99" "oob" -> assert str eq "oob" "AC2: out-of-bounds array index fallback"
        json get str val "user.missing.deep" "fallback" -> assert str eq "fallback" "AC2: missing deep dot-path fallback"

        updated = json set field val "version" (JsonInt 2)
        json get int updated "version" 0 -> assert int equals 2 "AC2: json set field adds new key"
        overwritten = json set field updated "count" (JsonInt 99)
        json get int overwritten "count" 0 -> assert int equals 99 "AC2: json set field overwrites existing key"
        ()
```

### 08.3.6. Example 6: Safe Detection of Malformed JSON Inputs (`JsonErr`) Without Panics or Exceptions

In this hands-on walkthrough we thoroughly exercise how `json` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test json malformed inputs => ()
      test json malformed inputs =
        lb = char from code 123
        rb = char from code 125
        is json ok (json parse "") -> assert false "AC3: reject empty input"
        is json ok (json parse "   ") -> assert false "AC3: reject whitespace-only input"
        is json ok (json parse (lb + "\"unclosed\":1")) -> assert false "AC3: reject unclosed object"
        is json ok (json parse "[1, 2, 3") -> assert false "AC3: reject unclosed array"
        is json ok (json parse "\"unterminated string") -> assert false "AC3: reject unterminated string"
        is json ok (json parse (lb + "unquoted: 1" + rb)) -> assert false "AC3: reject unquoted object key"
        is json ok (json parse (lb + "\"k\" 1" + rb)) -> assert false "AC3: reject missing colon in object"
        is json ok (json parse "[1, 2] trailing") -> assert false "AC3: reject trailing garbage token"
        is json ok (json parse "tru") -> assert false "AC3: reject truncated boolean literal"
        is json ok (json parse "nul") -> assert false "AC3: reject truncated null literal"
        ()
```

### 08.3.7. Example 7: `\uXXXX` Escapes, UTF-16 Surrogate Pairs, and Rejection of Lone Surrogates (`RG-076`)

In this hands-on walkthrough we thoroughly exercise how `json` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test rg076 unicode escapes and surrogates => ()
      test rg076 unicode escapes and surrogates =
        lb = char from code 123
        rb = char from code 125
        bs = char from code 92
        q  = char from code 34

        -- Solstice exact repro: {"title":"a\u00e9\"b"} -> "aé\"b" (UTF-8 C3 A9)
        repro_in  = lb + q + "title" + q + ":" + q + "a" + bs + "u00e9" + bs + q + "b" + q + rb
        repro_res = json parse repro_in
        is json ok repro_res -> assert true "RG-076: parse \\u00e9 escape succeeds"
        repro_str = json get str (unwrap json repro_res) "title" "-"
        repro_str -> assert str eq ("aé" + q + "b") "RG-076: \\u00e9 decoded to UTF-8 é (C3 A9)"
        str len repro_str -> assert int equals 5 "RG-076: byte length of 'aé\"b' is 5"

        -- 1-byte (\u0041 -> 'A'), 2-byte (\u00E9 -> 'é'), 3-byte (\u20AC -> '€') BMP escapes
        bmp_in  = lb + q + "k" + q + ":" + q + bs + "u0041-" + bs + "u00E9-" + bs + "u20AC" + q + rb
        bmp_res = json parse bmp_in
        is json ok bmp_res -> assert true "RG-076: BMP 1/2/3-byte \\uXXXX escapes parse"
        json get str (unwrap json bmp_res) "k" "" -> assert str eq "A-é-€" "RG-076: BMP \\u0041, \\u00E9, \\u20AC decoded"

        -- Surrogate pair (\uD83D\uDE00 -> U+1F600 '😀', 4-byte UTF-8 F0 9F 98 80)
        emo_in  = lb + q + "emoji" + q + ":" + q + bs + "uD83D" + bs + "uDE00" + q + rb
        emo_res = json parse emo_in
        is json ok emo_res -> assert true "RG-076: UTF-16 surrogate pair \\uD83D\\uDE00 parses"
        emo_str = json get str (unwrap json emo_res) "emoji" ""
        emo_str -> assert str eq "😀" "RG-076: surrogate pair decoded to 😀 (U+1F600)"
        str len emo_str -> assert int equals 4 "RG-076: 😀 is 4 UTF-8 bytes"

        -- Lone surrogates and malformed \uXXXX must return JsonErr (RFC 8259 §7)
        lone_hi   = lb + q + "bad" + q + ":" + q + bs + "uD83D" + q + rb
        lone_lo   = lb + q + "bad" + q + ":" + q + bs + "uDE00" + q + rb
        hi_non_lo = lb + q + "bad" + q + ":" + q + bs + "uD83D" + bs + "u0041" + q + rb
        hi_text   = lb + q + "bad" + q + ":" + q + bs + "uD83Dabc" + q + rb
        short_hex = lb + q + "bad" + q + ":" + q + bs + "u00e" + q + rb
        bad_hex   = lb + q + "bad" + q + ":" + q + bs + "u00g1" + q + rb
        is json ok (json parse lone_hi) -> assert false "RG-076: reject lone high surrogate \\uD83D"
        is json ok (json parse lone_lo) -> assert false "RG-076: reject lone low surrogate \\uDE00"
        is json ok (json parse hi_non_lo) -> assert false "RG-076: reject high surrogate followed by non-surrogate \\u0041"
        is json ok (json parse hi_text) -> assert false "RG-076: reject high surrogate followed by plain text"
        is json ok (json parse short_hex) -> assert false "RG-076: reject truncated \\u00e escape"
        is json ok (json parse bad_hex) -> assert false "RG-076: reject non-hex \\u00g1 escape"
        ()
```

### 08.3.8. Example 8: Duplicate Object Keys Rejected in Each Object Scope (`RG-077`)

In this hands-on walkthrough we thoroughly exercise how `json` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test rg077 duplicate object keys => ()
      test rg077 duplicate object keys =
        lb = char from code 123
        rb = char from code 125
        bs = char from code 92
        q  = char from code 34

        -- Solstice exact repro: {"title":"a","title":"b"} -> must be JsonErr
        dup_top = lb + "\"title\":\"a\",\"title\":\"b\"" + rb
        is json ok (json parse dup_top) -> assert false "RG-077: reject duplicate top-level key 'title'"

        -- Duplicate key inside nested object -> must be JsonErr
        dup_nested = lb + "\"meta\":" + lb + "\"k\":1,\"k\":2" + rb + rb
        is json ok (json parse dup_nested) -> assert false "RG-077: reject duplicate key in nested object"

        -- Duplicate key disguised via \uXXXX escape ({"a":1,"\u0061":2}) -> must be JsonErr
        dup_escaped = lb + q + "a" + q + ":1," + q + bs + "u0061" + q + ":2" + rb
        is json ok (json parse dup_escaped) -> assert false "RG-077: reject duplicate key after \\u0061 unescaping"

        -- Same key name in distinct sibling/nested objects remains valid!
        distinct_scopes = lb + "\"meta\":" + lb + "\"title\":\"x\"" + rb + ",\"title\":\"y\"" + rb
        res_ok = json parse distinct_scopes
        is json ok res_ok -> assert true "RG-077: allow same key name in different object scopes"
        json get str (unwrap json res_ok) "title" "-" -> assert str eq "y" "RG-077: top-level key 'title' is 'y'"
        ()
```

### 08.3.9. Example 9: Depth and Size Limits against Hostile Payloads (`json parse with limits`, `RG-078`)

In this hands-on walkthrough we thoroughly exercise how `json` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test rg078 depth and size limits => ()
      test rg078 depth and size limits =
        -- Default depth limit (64): 32 nested arrays succeed, 80 nested arrays fail
        ok_32   = nested brackets 32
        deep_80 = nested brackets 80
        is json ok (json parse ok_32) -> assert true "RG-078: 32 nested arrays within default depth limit"
        is json ok (json parse deep_80) -> assert false "RG-078: 80 nested arrays exceed default depth limit (64)"

        -- Custom per-endpoint limits via `json parse with limits`
        is json ok (json parse with limits (nested brackets 5) 5 1024) -> assert true "RG-078: depth 5 allowed when max_depth=5"
        is json ok (json parse with limits (nested brackets 6) 5 1024) -> assert false "RG-078: depth 6 rejected when max_depth=5"

        -- Input size limit via `json parse with limits`
        big_str = "\"" + (repeat str "abcdefghij" 20) + "\""
        is json ok (json parse with limits big_str 64 500) -> assert true "RG-078: 202-byte payload allowed when max_bytes=500"
        is json ok (json parse with limits big_str 64 100) -> assert false "RG-078: 202-byte payload rejected when max_bytes=100"
        ()
```

### 08.3.10. Example 10: Lossless Decimal Numbers (`json num text`, `json get float`), Strict UTF-8 Validation, and Field Lookup

In this hands-on walkthrough we thoroughly exercise how `json` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test json numbers utf8 and find field => ()
      test json numbers utf8 and find field =
        lb = char from code 123
        rb = char from code 125
        q  = char from code 34

        -- 1. Fractional and exponential numbers preserved via JsonNum
        json stringify (unwrap json (json parse "1.5")) -> assert str eq "1.5" "AC1: 1.5 preserved losslessly"
        json stringify (unwrap json (json parse "-1.5")) -> assert str eq "-1.5" "AC1: -1.5 preserved losslessly"
        json stringify (unwrap json (json parse "1e3")) -> assert str eq "1e3" "AC1: 1e3 preserved losslessly"
        price_raw = lb + "\"price\":19.99,\"qty\":3" + rb
        price_val = unwrap json (json parse price_raw)
        json stringify price_val -> assert str eq price_raw "AC1: {\"price\":19.99,\"qty\":3} round-trips losslessly"
        json num text (json get field price_val "price") -> assert str eq "19.99" "AC2: json num text returns 19.99"
        json num text (json get field price_val "qty") -> assert str eq "3" "AC2: json num text on JsonInt returns 3"
        (json get float price_val "price" 0.0) > 19.98 and (json get float price_val "price" 0.0) < 20.0 -> assert true "AC2: json get float parses 19.99"
        (json get float (unwrap json (json parse "-1.5")) "" 0.0) == (0.0 - 1.5) -> assert true "AC2: json get float parses -1.5"
        (json get float (unwrap json (json parse "1e3")) "" 0.0) == 1000.0 -> assert true "AC2: json get float parses 1e3"
        (json get float price_val "qty" 0.0) == 3.0 -> assert true "AC2: json get float converts JsonInt 3 to 3.0"

        -- 2. Strict UTF-8 validation in strings and keys (RFC 8259 §8.1)
        b_ff = j raw byte 255
        b_c0 = j raw byte 192
        b_af = j raw byte 175
        b_ed = j raw byte 237
        b_a0 = j raw byte 160
        b_80 = j raw byte 128
        b_f4 = j raw byte 244
        b_90 = j raw byte 144
        is json ok (json parse (q + b_ff + q)) -> assert false "AC3: reject stray 0xFF byte in JSON string"
        is json ok (json parse (q + b_c0 + b_af + q)) -> assert false "AC3: reject overlong 0xC0 0xAF UTF-8 in JSON string"
        is json ok (json parse (q + b_ed + b_a0 + b_80 + q)) -> assert false "AC3: reject UTF-8-encoded surrogate 0xED 0xA0 0x80"
        is json ok (json parse (q + b_f4 + b_90 + b_80 + b_80 + q)) -> assert false "AC3: reject > U+10FFFF 0xF4 0x90 0x80 0x80"
        is json ok (json parse (lb + q + b_c0 + b_af + q + ":1" + rb)) -> assert false "AC3: reject invalid UTF-8 in object key"

        -- 3. Distinguish missing field (None) from null field (Some JsonNull)
        null_obj = unwrap json (json parse (lb + "\"a\":null" + rb))
        is opt some (json find field null_obj "b") -> assert false "AC2: json find field returns None for missing field"
        is opt some null (json find field null_obj "a") -> assert true "AC2: json find field returns Some JsonNull for null field"
        json has field null_obj "b" -> assert false "AC2: json has field returns False for missing field"
        json has field null_obj "a" -> assert true "AC2: json has field returns True for null field"
        ()
```

---

## 08.4. Under the Hood: How `json` Is Built in Pure Ridgun (`src/main/ridgun/lib/json.ridgun`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/json.ridgun` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 08.4.1. Internal Implementation: Whitespace, Raw Byte & Character Helpers

Observe how `json.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
module :: json

fn :: j is ws Int => Bool
      j is ws c   =  c == 32 or c == 9 or c == 10 or c == 13

fn :: j is digit Int => Bool
      j is digit c   =  c >= 48 and c <= 57

fn :: j skip ws String Int Int => Int
      j skip ws s pos len =
        | pos >= len                    = len
        | j is ws (str char at s pos) = j skip ws s (pos + 1) len
        | otherwise                     = pos

fn :: j spaces loop Int String => String
      j spaces loop n   acc    =
        | n <= 0    = acc
        | otherwise = j spaces loop (n - 1) (acc + " ")

fn :: j spaces Int => String
      j spaces n   =  j spaces loop n ""

fn :: j raw byte ub Int => String
      j raw byte ub ub  =
        | ub >= 1 and ub <= 127 = char from code ub
        | ub == 0 = str slice (sha256 raw "00679") 0 1
        | otherwise =
          idx = (ub - 128) * 5
          lut = "0056400101002080010000179000010024100109003430040100361007870009100353001870030400471000870020200071002360012501171004140236900275001810016001398004440080400017005250027000314001400024700004006350015700183005940027600207007720028400601003400038000839006850084900617003060113500277000320006900483000580019200151008700008500193000100057000070002880002600326006460038800018009190028900103006000043900073011700038900628007210077300074004740006000041001410019900066003680001900383001730005700558000670024500065002030031900000008250001100128001360034900030003750039600228002380008400618005900031800062001770087900076002570009600034002200001600161"
          str slice (sha256 raw (str slice lut idx (idx + 5))) 0 1

fn :: j raw byte Int => String
      j raw byte b   =  j raw byte ub (((b % 256) + 256) % 256)

fn :: j sb append3 String String => String String String String
      j sb append3 n2     c3     =
        | (str len n2) < 65536 = ("", "", n2, c3)
        | otherwise            = ("", "", "", c3 + n2)

fn :: j sb append2 String String String => String String String String
      j sb append2 n1 c2 c3 =
        | (str len n1) < 8192 = ("", n1, c2, c3)
        | otherwise           = j sb append3 (c2 + n1) c3

fn :: j sb append1 String String String String => String String String String
      j sb append1 n0 c1 c2 c3 =
        | (str len n0) < 512 = (n0, c1, c2, c3)
        | otherwise          = j sb append2 (c1 + n0) c2 c3

fn :: j sb append String String String String String => String String String String
      j sb append chunk c0 c1 c2 c3 =
        j sb append1 (c0 + chunk) c1 c2 c3

fn :: j sb finish String String String String => String
      j sb finish c0 c1 c2 c3 = ((c3 + c2) + c1) + c0

fn :: j rev vals loop [JsonVal] [JsonVal] => [JsonVal]
      j rev vals loop [] acc = acc
      j rev vals loop (x:xs) acc = j rev vals loop xs ([x] :: acc)

fn :: j rev vals [JsonVal] => [JsonVal]
      j rev vals []        =  []
      j rev vals xs        =  j rev vals loop xs []

fn :: j rev fields loop [JsonField] [JsonField] => [JsonField]
      j rev fields loop [] acc = acc
      j rev fields loop (x:xs) acc = j rev fields loop xs ([x] :: acc)

fn :: j rev fields [JsonField] => [JsonField]
      j rev fields []          =  []
      j rev fields xs          =  j rev fields loop xs []
```

### 08.4.2. Internal Implementation: RFC 8259 §6 Number Parsing (No Leading Zeroes, 64-Bit Overflow Check, Fraction & Exponent)

Observe how `json.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: j scan digits String Int Int => Int
      j scan digits s pos len =
        | pos >= len                      = len
        | j is digit (str char at s pos) = j scan digits s (pos + 1) len
        | otherwise                       = pos

fn :: j str cmp2 Int Int String String Int Int => Int
      j str cmp2 ca cb a b idx len =
        | ca < cb   = 0 - 1
        | ca > cb   = 1
        | otherwise = j str cmp loop a b (idx + 1) len

fn :: j str cmp loop String String Int Int => Int
      j str cmp loop a b idx len =
        | idx >= len = 0
        | otherwise  = j str cmp2 (str char at a idx) (str char at b idx) a b idx len

fn :: j digits fit i64 len String Bool Int => Bool
      j digits fit i64 len digs is_neg dlen =
        | dlen < 19 = True
        | dlen > 19 = False
        | is_neg    = (j str cmp loop digs "9223372036854775808" 0 19) <= 0
        | otherwise = (j str cmp loop digs "9223372036854775807" 0 19) <= 0

fn :: j digits fit i64 String Bool => Bool
      j digits fit i64 digs is_neg =
        j digits fit i64 len digs is_neg (str len digs)

fn :: j parse pos digits loop String Int Int Int => Int
      j parse pos digits loop digs idx dlen acc =
        | idx >= dlen = acc
        | otherwise   = j parse pos digits loop digs (idx + 1) dlen ((acc * 10) + ((str char at digs idx) - 48))

fn :: j parse neg digits loop String Int Int Int => Int
      j parse neg digits loop digs idx dlen acc =
        | idx >= dlen = acc
        | otherwise   = j parse neg digits loop digs (idx + 1) dlen ((acc * 10) - ((str char at digs idx) - 48))

fn :: j parse i64 exact String Bool => Int
      j parse i64 exact digs is_neg =
        | is_neg    = j parse neg digits loop digs 0 (str len digs) 0
        | otherwise = j parse pos digits loop digs 0 (str len digs) 0

fn :: j scan exp after sign2 Int Int => Int
      j scan exp after sign2 pos end_e =
        | end_e <= pos = 0 - 1
        | otherwise    = end_e

fn :: j scan exp after sign String Int Int => Int
      j scan exp after sign s pos len =
        | pos >= len = 0 - 1
        | otherwise  = j scan exp after sign2 pos (j scan digits s pos len)

fn :: j scan opt exp sign String Int Int Int => Int
      j scan opt exp sign s pos len sc =
        | sc == 43 or sc == 45 = j scan exp after sign s (pos + 2) len
        | otherwise            = j scan exp after sign s (pos + 1) len

fn :: j scan opt exp char String Int Int Int => Int
      j scan opt exp char s pos len c =
        | c != 101 and c != 69 = pos
        | (pos + 1) >= len     = 0 - 1
        | otherwise            = j scan opt exp sign s pos len (str char at s (pos + 1))

fn :: j scan opt exp String Int Int => Int
      j scan opt exp s pos len =
        | pos >= len = pos
        | otherwise  = j scan opt exp char s pos len (str char at s pos)

fn :: j scan opt frac2 String Int Int Int => Int
      j scan opt frac2 s pos len end_f =
        | end_f <= (pos + 1) = 0 - 1
        | otherwise          = j scan opt exp s end_f len

fn :: j scan opt frac String Int Int => Int
      j scan opt frac s pos len =
        | pos >= len                = pos
        | (str char at s pos) != 46 = j scan opt exp s pos len
        | (pos + 1) >= len          = 0 - 1
        | otherwise                 = j scan opt frac2 s pos len (j scan digits s (pos + 1) len)

fn :: j parse pos range String Int Int Int => Int
      j parse pos range s idx end_p acc =
        | idx >= end_p = acc
        | otherwise    = j parse pos range s (idx + 1) end_p ((acc * 10) + ((str char at s idx) - 48))

fn :: j parse neg range String Int Int Int => Int
      j parse neg range s idx end_p acc =
        | idx >= end_p = acc
        | otherwise    = j parse neg range s (idx + 1) end_p ((acc * 10) - ((str char at s idx) - 48))

fn :: j parse i64 range String Int Int Bool => Int
      j parse i64 range s int_start int_end is_neg =
        | is_neg    = j parse neg range s int_start int_end 0
        | otherwise = j parse pos range s int_start int_end 0

fn :: j finish int digs String Bool Int => JsonStep
      j finish int digs digs is_neg int_end =
        | not (j digits fit i64 digs is_neg) = JStepErr "JSON integer overflows 64-bit signed range"
        | otherwise                          = JStepOk (JsonInt (j parse i64 exact digs is_neg)) int_end

fn :: j finish int range String Int Int Bool Int => JsonStep
      j finish int range s int_start int_end is_neg dlen =
        | dlen < 19 = JStepOk (JsonInt (j parse i64 range s int_start int_end is_neg)) int_end
        | dlen > 19 = JStepErr "JSON integer overflows 64-bit signed range"
        | otherwise = j finish int digs (str slice s int_start int_end) is_neg int_end

fn :: j finish num after frac String Int Int Bool Int Int => JsonStep
      j finish num after frac s start_pos int_start is_neg int_end end_pos =
        | end_pos < 0       = JStepErr "invalid fraction or exponent in JSON number"
        | end_pos > int_end = JStepOk (JsonNum (str slice s start_pos end_pos)) end_pos
        | otherwise         = j finish int range s int_start int_end is_neg (int_end - int_start)

fn :: j finish num after int String Int Int Bool Int Int => JsonStep
      j finish num after int s start_pos int_start is_neg int_end len =
        j finish num after frac s start_pos int_start is_neg int_end (j scan opt frac s int_end len)

fn :: j parse num int part2 String Int Int Bool Int Int Int => JsonStep
      j parse num int part2 s start_pos int_start is_neg len c0 int_end =
        | int_end <= int_start                   = JStepErr "expected digits in JSON number"
        | c0 == 48 and int_end > (int_start + 1) = JStepErr "leading zero not permitted in JSON number"
        | otherwise                              = j finish num after int s start_pos int_start is_neg int_end len

fn :: j parse num int part String Int Int Bool Int => JsonStep
      j parse num int part s start_pos int_start is_neg len =
        | int_start >= len = JStepErr "expected digits in JSON number"
        | otherwise        = j parse num int part2 s start_pos int_start is_neg len (str char at s int_start) (j scan digits s int_start len)

fn :: j parse number String Int Int => JsonStep
      j parse number s pos len =
        | (str char at s pos) == 45 = j parse num int part s pos (pos + 1) True len
        | otherwise                 = j parse num int part s pos pos False len
```

### 08.4.3. Internal Implementation: Serialization & Pretty-Printing

Observe how `json.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: j join arr loop [JsonVal] String String String String => String
      j join arr loop [] c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j join arr loop (v:vs) c0 c1 c2 c3 =
        n0, n1, n2, n3 = j sb append ("," + (json stringify v)) c0 c1 c2 c3
        j join arr loop vs n0 n1 n2 n3

fn :: j join arr [JsonVal] => String
      j join arr []        =  ""
      j join arr (v:vs)    =  j join arr loop vs (json stringify v) "" "" ""

fn :: j join obj loop [JsonField] String String String String => String
      j join obj loop [] c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j join obj loop ((JsonField k v):rest) c0 c1 c2 c3 =
        item = "," + (j escape str k) + ":" + (json stringify v)
        n0, n1, n2, n3 = j sb append item c0 c1 c2 c3
        j join obj loop rest n0 n1 n2 n3

fn :: j join obj [JsonField] => String
      j join obj []          =  ""
      j join obj ((JsonField k v):rest) =
        first = (j escape str k) + ":" + (json stringify v)
        j join obj loop rest first "" "" ""

fn :: j pos int to str Int String => String
      j pos int to str n acc =
        | n <= 0    = acc
        | otherwise = j pos int to str (n / 10) ((char from code (48 + (n % 10))) + acc)

fn :: j int to str Int => String
      j int to str n   =
        | n == 0         = "0"
        | n > 0          = j pos int to str n ""
        | n > (0 - 10)   = "-" + (char from code (48 + (0 - n)))
        | otherwise      = "-" + (j pos int to str (0 - (n / 10)) (char from code (48 + (0 - (n % 10)))))

fn :: json stringify JsonVal          => String
      json stringify JsonNull         =  "null"
      json stringify (JsonBool True)  =  "true"
      json stringify (JsonBool False) =  "false"
      json stringify (JsonInt n)      =  j int to str n
      json stringify (JsonNum raw)    =  raw
      json stringify (JsonStr s)      =  j escape str s
      json stringify (JsonArr items)  =  "[" + (j join arr items) + "]"
      json stringify (JsonObj fields) =  (char from code 123) + (j join obj fields) + (char from code 125)

fn :: j pretty arr loop [JsonVal] Int Int String String String String => String
      j pretty arr loop [] _ _ c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j pretty arr loop (v:vs) ind cur c0 c1 c2 c3 =
        item = "," + (char from code 10) + (j spaces (cur + ind)) + (j pretty val v ind (cur + ind))
        n0, n1, n2, n3 = j sb append item c0 c1 c2 c3
        j pretty arr loop vs ind cur n0 n1 n2 n3

fn :: j pretty arr [JsonVal] Int Int => String
      j pretty arr [] _ _ = ""
      j pretty arr (v:vs) ind cur =
        first = (j spaces (cur + ind)) + (j pretty val v ind (cur + ind))
        j pretty arr loop vs ind cur first "" "" ""

fn :: j pretty obj loop [JsonField] Int Int String String String String => String
      j pretty obj loop [] _ _ c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j pretty obj loop ((JsonField k v):rest) ind cur c0 c1 c2 c3 =
        item = "," + (char from code 10) + (j spaces (cur + ind)) + (j escape str k) + ": " + (j pretty val v ind (cur + ind))
        n0, n1, n2, n3 = j sb append item c0 c1 c2 c3
        j pretty obj loop rest ind cur n0 n1 n2 n3

fn :: j pretty obj [JsonField] Int Int => String
      j pretty obj [] _ _ = ""
      j pretty obj ((JsonField k v):rest) ind cur =
        first = (j spaces (cur + ind)) + (j escape str k) + ": " + (j pretty val v ind (cur + ind))
        j pretty obj loop rest ind cur first "" "" ""

fn :: j pretty val JsonVal Int Int => String
      j pretty val (JsonArr []) _ _ = "[]"
      j pretty val (JsonArr items) ind cur =
        nl = char from code 10
        "[" + nl + (j pretty arr items ind cur) + nl + (j spaces cur) + "]"
      j pretty val (JsonObj []) _ _ = (char from code 123) + (char from code 125)
      j pretty val (JsonObj fields) ind cur =
        nl = char from code 10
        (char from code 123) + nl + (j pretty obj fields ind cur) + nl + (j spaces cur) + (char from code 125)
      j pretty val v _ _ = json stringify v

fn :: json pretty JsonVal Int => String
      json pretty val     ind =  j pretty val val ind 0
```

### 08.4.4. Internal Implementation: Dot-Path Queries & Field Updates

Observe how `json.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: j lookup field opt [JsonField] String => Option JsonVal
      j lookup field opt [] _ = None
      j lookup field opt ((JsonField k v):fs) key =
        | k == key  = Some v
        | otherwise = j lookup field opt fs key

fn :: json find field JsonVal          String => Option JsonVal
      json find field (JsonObj fields) key    =  j lookup field opt fields key
      json find field _                _      =  None

fn :: json has field JsonVal          String => Bool
      json has field (JsonObj fields) key    =  j has field fields key
      json has field _                _      =  False

fn :: j find field [JsonField] String => JsonVal
      j find field []          _      =  JsonNull
      j find field ((JsonField k v):fs) key =
        | k == key  = v
        | otherwise = j find field fs key

fn :: json get field JsonVal          String => JsonVal
      json get field (JsonObj fields) key    =  j find field fields key
      json get field _                _      =  JsonNull

fn :: j nth val [JsonVal] Int => JsonVal
      j nth val []        _   =  JsonNull
      j nth val (v:vs)    idx =
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

fn :: json num text JsonVal       => String
      json num text (JsonNum raw) =  raw
      json num text (JsonInt n)   =  j int to str n
      json num text _             =  ""

fn :: j digit real Int => Real
      j digit real 48  =  0.0
      j digit real 49  =  1.0
      j digit real 50  =  2.0
      j digit real 51  =  3.0
      j digit real 52  =  4.0
      j digit real 53  =  5.0
      j digit real 54  =  6.0
      j digit real 55  =  7.0
      j digit real 56  =  8.0
      j digit real 57  =  9.0
      j digit real _   =  0.0

fn :: j pow10 loop Int Real => Real
      j pow10 loop e   acc  =
        | e <= 0    = acc
        | otherwise = j pow10 loop (e - 1) (acc * 10.0)

fn :: j apply exp Real Bool Int => Real
      j apply exp val exp_neg exp_n =
        | exp_n <= 0 = val
        | exp_neg    = val / (j pow10 loop exp_n 1.0)
        | otherwise  = val * (j pow10 loop exp_n 1.0)

fn :: j parse real exp String Int Int Real Bool => Real
      j parse real exp s pos len base exp_neg =
        exp_n = j parse pos range s pos len 0
        j apply exp base exp_neg exp_n

fn :: j parse real exp sign String Int Int Real => Real
      j parse real exp sign s pos len base =
        | pos >= len                = base
        | (str char at s pos) == 45 = j parse real exp s (pos + 1) len base True
        | (str char at s pos) == 43 = j parse real exp s (pos + 1) len base False
        | otherwise                 = j parse real exp s pos len base False

fn :: j parse real frac loop String Int Int Real Real Real => Real
      j parse real frac loop s pos len int_v frac_v div_v =
        | pos >= len = int_v + (frac_v / div_v)
        | j is digit (str char at s pos) =
      j parse real frac loop s (pos + 1) len int_v ((frac_v * 10.0) + (j digit real (str char at s pos))) (div_v * 10.0)
        | (str char at s pos) == 101 or (str char at s pos) == 69 =
          j parse real exp sign s (pos + 1) len (int_v + (frac_v / div_v))
        | otherwise = int_v + (frac_v / div_v)

fn :: j parse real int loop String Int Int Real => Real
      j parse real int loop s pos len acc =
        | pos >= len = acc
        | j is digit (str char at s pos) =
      j parse real int loop s (pos + 1) len ((acc * 10.0) + (j digit real (str char at s pos)))
        | (str char at s pos) == 46 =
          j parse real frac loop s (pos + 1) len acc 0.0 1.0
        | (str char at s pos) == 101 or (str char at s pos) == 69 =
      j parse real exp sign s (pos + 1) len acc
        | otherwise = acc

fn :: j parse real str String => Real
      j parse real str ""     =  0.0
      j parse real str s      =
        | (str char at s 0) == 45 = 0.0 - (j parse real int loop s 1 (str len s) 0.0)
        | otherwise               = j parse real int loop s 0 (str len s) 0.0

fn :: j unwrap float JsonVal       Real     => Real
      j unwrap float (JsonNum raw) _        =  j parse real str raw
      j unwrap float (JsonInt n)   _        =  j parse real str (j int to str n)
      j unwrap float _             fallback =  fallback

fn :: json get float JsonVal String Real => Real
      json get float val dot_path fallback =
        json get path val dot_path -> target
        j unwrap float target fallback

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
      j put field [] key new_val = [JsonField key new_val]
      j put field ((JsonField k v):fs) key new_val =
        | k == key  = [JsonField key new_val] :: fs
        | otherwise = [JsonField k v] :: (j put field fs key new_val)

fn :: json set field JsonVal String JsonVal => JsonVal
      json set field (JsonObj fields) key new_val = JsonObj (j put field fields key new_val)
      json set field _ key new_val = JsonObj [JsonField key new_val]
```

---

## 08.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `json`

- **Algorithmic & Safety Guarantee**: Strict rejection of trailing garbage after the root value, full escape-sequence handling, and exception-free `JsonErr` reporting.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/json.ridgun` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test json.ridgun`.

### The 5 Golden Rules When Programming with `json`

1. **Declare `import json` at the top of your file** and call its functions with spaces, exactly as they are declared, so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `json` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `json`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `json` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 09**, we will explore the **`csv`** lib in full depth (The `csv` Lib — RFC 4180 CSV/TSV State-Machine Parser and Header-Indexed Tables).
