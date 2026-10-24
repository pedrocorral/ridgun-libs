# Chapter 07: The `codec` Lib — RFC 4648 Hex, Base64, Base64url, and URL Percent-Encoding

## 07.1. Why Does the `codec` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `codec` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `codec`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: nothing breaks a web integration faster than mixing up standard Base64 (`+/=`) with unpadded URL-safe Base64url (`-_`) inside a JWT, or building query strings by naive string concatenation.

The **`codec`** lib implements **RFC 4648** (Hex, Base64, and URL-safe Base64url), **RFC 3986** (URL percent-encoding and `query encode` / `query decode`), and lightweight **RFC 8259 JSON** builders and field extractors.

In a traditional ecosystem, solving **`CODEC`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`codec`** lib (`src/main/ridgun/lib/codec.rg`) tackles the problem with four non-negotiable principles:

1. **Total Functions & Explicit Contracts (`=>`)**: no function in `codec` throws hidden exceptions or relies on `null`. Every edge case (empty inputs, zero divisors, truncated frames, or out-of-bounds indices) returns a documented sentinel value or an algebraic sum type (`Option`, `Result`).
2. **Zero C Code & Zero `libc`**: every line of `codec` compiles directly into native ELF64 machine code verified by `ridgunc`.
3. **Tail-Call Optimization (TCO)**: all internal loops in `codec` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 07.2. Native Artifacts, Imports, and Complete `codec` API Catalog

In `ridgun-libs`, **`codec`** is a first-class **lib** located at `src/main/ridgun/lib/codec.rg` (domain `CODEC`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/codec.rglib` | Portable distribution and direct `import codec` resolution |
| **Compiled Archive** | `target/codec.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libcodec.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import codec` at the top and call its functions using either multi-word spaces (`my fn x`) or underscores (`my_fn x`).

### 07.2.1. Summary of `codec` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `hex encode / hex decode / hex is valid` | Lowercase RFC 4648 hexadecimal encoding and validated decoding |
| `base64 encode / base64 decode` | Standard RFC 4648 §4 Base64 with `=` padding |
| `base64url encode / base64url decode` | URL-safe RFC 4648 §5 Base64url (`-`, `_`, unpadded) |
| `url encode / url decode / query encode / query decode` | RFC 3986 percent-encoding and `k=v&...` query string round-trips |
| `json quote / json object / json get str / json get int` | Fast zero-AST JSON serialization and top-level key lookup |

### 07.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/codec.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/codec.rg` (`0` types, `0` operators, and `86` functions):

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: cd raw byte ub Int` | `String` |
| `2` | `fn :: cd raw byte Int` | `String` |
| `3` | `fn :: cd hex lut Int` | `String` |
| `4` | `fn :: cd hex up lut Int` | `String` |
| `5` | `fn :: cd b64 lut Int` | `String` |
| `6` | `fn :: cd b64url lut Int` | `String` |
| `7` | `fn :: cd index of loop String String Int Int Int` | `Int` |
| `8` | `fn :: cd index of String String` | `Int` |
| `9` | `fn :: cd split char loop String Int Int Int Int` | `[String]` |
| `10` | `fn :: cd hex val Int` | `Int` |
| `11` | `fn :: cd valid hex loop String Int Int` | `Bool` |
| `12` | `fn :: cd is valid hex len String Int` | `Bool` |
| `13` | `fn :: is valid hex String` | `Bool` |
| `14` | `fn :: cd hex enc byte Int` | `String` |
| `15` | `fn :: cd hex enc loop String Int Int` | `String` |
| `16` | `fn :: hex encode String` | `String` |
| `17` | `fn :: cd hex dec loop String Int Int` | `String` |
| `18` | `fn :: hex decode String` | `String` |
| `19` | `fn :: cd b64 char String Int` | `String` |
| `20` | `fn :: cd b64 pad suffix String Bool` | `String` |
| `21` | `fn :: cd b64 enc step String Int String Bool Int` | `String` |
| `22` | `fn :: cd b64 enc rem String Int String Bool` | `String` |
| `23` | `fn :: base64 encode String` | `String` |
| `24` | `fn :: base64url encode String` | `String` |
| `25` | `fn :: cd b64 val Int` | `Int` |
| `26` | `fn :: cd strip b64 pad String Int` | `String` |
| `27` | `fn :: cd valid b64 body String Int Int` | `Bool` |
| `28` | `fn :: cd valid b64 raw String Int` | `Bool` |
| `29` | `fn :: is valid base64 String` | `Bool` |
| `30` | `fn :: cd b64 dec step String Int Int Int` | `String` |
| `31` | `fn :: cd b64 dec loop String Int Int` | `String` |
| `32` | `fn :: base64 decode String` | `String` |
| `33` | `fn :: base64url decode String` | `String` |
| `34` | `fn :: cd is unreserved Int` | `Bool` |
| `35` | `fn :: cd pct byte Int` | `String` |
| `36` | `fn :: cd url enc char String Int Int` | `String` |
| `37` | `fn :: cd url enc loop String Int Int` | `String` |
| `38` | `fn :: url encode String` | `String` |
| `39` | `fn :: cd url dec pct String Int Int Int Int` | `String` |
| `40` | `fn :: cd url dec at String Int Int Int` | `String` |
| `41` | `fn :: cd url dec loop String Int Int` | `String` |
| `42` | `fn :: url decode String` | `String` |
| `43` | `fn :: cd pair key (String String)` | `String` |
| `44` | `fn :: cd pair val (String String)` | `String` |
| `45` | `fn :: query string encode [String String]` | `String` |
| `46` | `fn :: cd parse kv at String Int` | `String String` |
| `47` | `fn :: cd parse kv item String` | `String String` |
| `48` | `fn :: cd parse qs list [String]` | `[String String]` |
| `49` | `fn :: cd strip leading q String` | `String` |
| `50` | `fn :: cd decode clean qs String` | `[String String]` |
| `51` | `fn :: query string decode String` | `[String String]` |
| `52` | `fn :: cd json esc code String Int Int` | `String` |
| `53` | `fn :: cd json esc loop String Int Int` | `String` |
| `54` | `fn :: json escape String` | `String` |
| `55` | `fn :: cd json unesc next String Int Int Int` | `String` |
| `56` | `fn :: cd json unesc loop String Int Int` | `String` |
| `57` | `fn :: json unescape String` | `String` |
| `58` | `fn :: json quote String` | `String` |
| `59` | `fn :: json int Int` | `String` |
| `60` | `fn :: json bool Bool` | `String` |
| `61` | `fn :: json null` | `String` |
| `62` | `fn :: cd join json items [String]` | `String` |
| `63` | `fn :: json array [String]` | `String` |
| `64` | `fn :: cd join json pairs [String String]` | `String` |
| `65` | `fn :: json object [String String]` | `String` |
| `66` | `fn :: cd quote pair vals [String String]` | `[String String]` |
| `67` | `fn :: json str object [String String]` | `String` |
| `68` | `fn :: cd is json ws Int` | `Bool` |
| `69` | `fn :: cd skip key sep String Int Int` | `Int` |
| `70` | `fn :: cd scan json str end String Int Int` | `Int` |
| `71` | `fn :: cd is tok delim Int` | `Bool` |
| `72` | `fn :: cd scan json tok end String Int Int` | `Int` |
| `73` | `fn :: cd extract json str vend String Int Int` | `String` |
| `74` | `fn :: cd extract json str vstart String Int` | `String` |
| `75` | `fn :: cd extract json str kpos String String Int` | `String` |
| `76` | `fn :: json get str String String` | `String` |
| `77` | `fn :: cd is signed int loop String Int Int` | `Bool` |
| `78` | `fn :: cd is valid int len String Int` | `Bool` |
| `79` | `fn :: cd is valid int str String` | `Bool` |
| `80` | `fn :: cd raw tok vstart String Int` | `String` |
| `81` | `fn :: cd raw tok kpos String String Int` | `String` |
| `82` | `fn :: cd raw json token String String` | `String` |
| `83` | `fn :: cd parse tok int String Int` | `Int` |
| `84` | `fn :: json get int String String Int` | `Int` |
| `85` | `fn :: cd parse tok bool String Bool` | `Bool` |
| `86` | `fn :: json get bool String String Bool` | `Bool` |

---

## 07.3. Deep Dive into `codec`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `codec` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test codec.rg`.

### 07.3.1. Example 1: Core Tabular Workflow with `codec`

Notice how in Ridgun the `=` signs and transformation steps using `codec` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import codec

fn :: empaquetar parametros (usuario : String) (redir : String) => String
      empaquetar parametros usuario redir =
        token_b64 = base64url encode usuario
        query encode [("token", token_b64), ("next", redir)]
```

### 07.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `codec` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import codec

fn :: construir respuesta rapida (id : Int) (nombre : String) => (String, Int)
      construir respuesta rapida id nombre =
        doc = json object [("id", json int id), ("name", json quote nombre), ("ok", json bool True)]
        leido = json get int doc "id" 0
        (doc, leido)
```

### 07.3.3. Example 3: RFC 4648 Hexadecimal, Standard Base64, and URL-Safe Base64url Encoding & Decoding

In this hands-on walkthrough we thoroughly exercise how `codec` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test rfc4648 hex and base64 => ()
      test rfc4648 hex and base64 =
        -- 1. Hexadecimal RFC 4648 test vectors & negative validation
        _ = assert str eq (hex encode "") "" "hex_encode empty"
        _ = assert str eq (hex encode "foobar") "666f6f626172" "hex_encode foobar"
        _ = assert str eq (hex decode "666f6f626172") "foobar" "hex_decode lowercase"
        _ = assert str eq (hex decode "666F6F626172") "foobar" "hex_decode uppercase"
        _ = assert true (is valid hex "deadBEEF09") "is_valid_hex valid"
        _ = assert false (is valid hex "abc") "is_valid_hex odd length"
        _ = assert false (is valid hex "deadZZ") "is_valid_hex invalid chars"
        _ = assert str eq (hex decode "abc") "" "hex_decode odd -> empty"

        -- 2. Base64 & Base64url RFC 4648 test vectors
        _ = assert str eq (base64 encode "") "" "b64 empty"
        _ = assert str eq (base64 encode "f") "Zg==" "b64 f"
        _ = assert str eq (base64 encode "fo") "Zm8=" "b64 fo"
        _ = assert str eq (base64 encode "foo") "Zm9v" "b64 foo"
        _ = assert str eq (base64 encode "foob") "Zm9vYg==" "b64 foob"
        _ = assert str eq (base64 encode "fooba") "Zm9vYmE=" "b64 fooba"
        _ = assert str eq (base64 encode "foobar") "Zm9vYmFy" "b64 foobar"
        _ = assert str eq (base64 decode "Zg==") "f" "b64 dec f"
        _ = assert str eq (base64 decode "Zm8=") "fo" "b64 dec fo"
        _ = assert str eq (base64 decode "Zm9v") "foo" "b64 dec foo"
        _ = assert str eq (base64 decode "Zm9vYg==") "foob" "b64 dec foob"
        _ = assert str eq (base64 decode "Zm9vYmE=") "fooba" "b64 dec fooba"
        _ = assert str eq (base64 decode "Zm9vYmFy") "foobar" "b64 dec foobar"
        _ = assert str eq (base64url encode "foob") "Zm9vYg" "b64url nopad"
        _ = assert str eq (base64url decode "Zm9vYg") "foob" "b64url dec"
        _ = assert false (is valid base64 "A") "invalid base64 len%4==1"
        _ = assert false (is valid base64 "Zm$v") "invalid base64 char"
        _ = assert str eq (base64 decode "Zm$v") "" "invalid base64 -> empty"

        -- 3. LIB-8: Binary-safe decoding for raw octets >= 0x80 and 0x00
        raw4 = hex decode "c800ff41"
        _    = assert int equals (str len raw4) 4 "str_len (hex_decode c800ff41) == 4"
        _    = assert int equals (str char at raw4 0) 200 "raw4[0] == 0xc8"
        _    = assert int equals (str char at raw4 1) 0 "raw4[1] == 0x00"
        _    = assert int equals (str char at raw4 2) 255 "raw4[2] == 0xff"
        _    = assert int equals (str char at raw4 3) 65 "raw4[3] == 0x41"
        _    = assert str eq (hex encode raw4) "c800ff41" "hex_encode raw4 == c800ff41"
        _    = check binary roundtrip loop 10
        ()
```

### 07.3.4. Example 4: RFC 3986 Percent-Encoding (`url encode`, `url decode`) and Query Strings (`query encode`, `query get`)

In this hands-on walkthrough we thoroughly exercise how `codec` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test rfc3986 url and query strings => ()
      test rfc3986 url and query strings =
        raw = "hello world&x=1+2%"
        enc = url encode raw
        _   = assert str eq enc "hello%20world%26x%3D1%2B2%25" "url_encode"
        _   = assert str eq (url decode enc) raw "url_decode roundtrip"
        _   = assert str eq (url decode "a+b%20c") "a b c" "url_decode plus as space"
        qs  = query string encode [("q", "ridgun libs"), ("page", "2")]
        _   = assert str eq qs "q=ridgun%20libs&page=2" "query_string_encode"
        dec = query string decode ("?" + qs)
        _   = assert eq dec [("q", "ridgun libs"), ("page", "2")]
        ()
```

### 07.3.5. Example 5: RFC 8259 Lightweight JSON Escaping & Field Extraction (`json escape`, `json unescape`, `json encode kv`, `json get str/int/bool`)

In this hands-on walkthrough we thoroughly exercise how `codec` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test rfc8259 lightweight json => ()
      test rfc8259 lightweight json =
        esc = json escape "line1\n\"quoted\"\\tab\t"
        _   = assert str eq esc "line1\\n\\\"quoted\\\"\\\\tab\\t" "json_escape"
        _   = assert str eq (json unescape esc) "line1\n\"quoted\"\\tab\t" "json_unescape"
        doc = json object [("service", json quote "solstice"), ("port", json int 8443), ("tls", json bool True), ("extra", json null)]
        _   = assert str eq doc "{\"service\":\"solstice\",\"port\":8443,\"tls\":true,\"extra\":null}" "json_object"
        _   = assert str eq (json get str doc "service") "solstice" "json_get_str"
        _   = assert str eq (json get str doc "missing") "" "json_get_str missing"
        _   = assert int equals (json get int doc "port" 80) 8443 "json_get_int"
        _   = assert int equals (json get int doc "missing" 80) 80 "json_get_int fallback"
        _   = assert int equals (json get int doc "service" 80) 80 "json_get_int non-int fallback"
        _   = assert true (json get bool doc "tls" False) "json_get_bool"
        _   = assert false (json get bool doc "missing" False) "json_get_bool fallback"
        arr = json array [json int 1, json int 2, json quote "three"]
        _   = assert str eq arr "[1,2,\"three\"]" "json_array"
        s_o = json str object [("k1", "v1"), ("k2", "v\"2")]
        _   = assert str eq (json get str s_o "k2") "v\"2" "json_str_object escaped roundtrip"
        ()
```

---

## 07.4. Under the Hood: How `codec` Is Built in Pure Ridgun (`src/main/ridgun/lib/codec.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/codec.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 07.4.1. Internal Implementation: RFC 4648 Hexadecimal Encoding & Decoding

Observe how `codec.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: cd hex val Int => Int
      cd hex val c   =
        | c >= 48 and c <= 57  = c - 48
        | c >= 65 and c <= 70  = (c - 65) + 10
        | c >= 97 and c <= 102 = (c - 97) + 10
        | otherwise            = 0 - 1

fn :: cd valid hex loop String Int Int => Bool
      cd valid hex loop s idx len =
        | idx >= len                           = True
        | (cd hex val (str char at s idx)) < 0 = False
        | otherwise                            = cd valid hex loop s (idx + 1) len

fn :: cd is valid hex len String Int => Bool
      cd is valid hex len s n =
        | (n % 2) != 0 = False
        | otherwise    = cd valid hex loop s 0 n

fn :: is valid hex String => Bool
      is valid hex s      =  cd is valid hex len s (str len s)

fn :: cd hex enc byte Int => String
      cd hex enc byte b   =
        ub  = ((b % 256) + 256) % 256
        hi  = ub / 16
        lo  = ub % 16
        tbl = cd hex lut 0
        (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1))

fn :: cd hex enc loop String Int Int => String
      cd hex enc loop s idx len =
        | idx >= len = ""
        | otherwise  = (cd hex enc byte (str char at s idx)) + (cd hex enc loop s (idx + 1) len)

fn :: hex encode String => String
      hex encode s      =  cd hex enc loop s 0 (str len s)

fn :: cd hex dec loop String Int Int => String
      cd hex dec loop s idx len =
        | idx >= len = ""
        | otherwise =
          hi = cd hex val (str char at s idx)
          lo = cd hex val (str char at s (idx + 1))
          (cd raw byte ((hi * 16) + lo)) + (cd hex dec loop s (idx + 2) len)

fn :: hex decode String => String
      hex decode s      =
        | not (is valid hex s) = ""
        | otherwise            = cd hex dec loop s 0 (str len s)
```

### 07.4.2. Internal Implementation: RFC 4648 Standard Base64 & URL-Safe Base64url

Observe how `codec.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: cd b64 char String Int => String
      cd b64 char tbl    idx =
        i = idx % 64
        str slice tbl i (i + 1)

fn :: cd b64 pad suffix String Bool => String
      cd b64 pad suffix suffix True = suffix
      cd b64 pad suffix _ False = ""

fn :: cd b64 enc step String Int String Bool Int => String
      cd b64 enc step s idx tbl pad rem =
        | rem <= 0 = ""
        | rem == 1 =
          b0   = str char at s idx
          out2 = (cd b64 char tbl (b0 / 4)) + (cd b64 char tbl ((b0 % 4) * 16))
          out2 + (cd b64 pad suffix "==" pad)
        | rem == 2 =
          b0   = str char at s idx
          b1   = str char at s (idx + 1)
          n    = (b0 * 256) + b1
          out3 = (cd b64 char tbl (n / 1024)) + (cd b64 char tbl ((n / 16) % 64)) + (cd b64 char tbl ((n % 16) * 4))
          out3 + (cd b64 pad suffix "=" pad)
        | otherwise =
          b0   = str char at s idx
          b1   = str char at s (idx + 1)
          b2   = str char at s (idx + 2)
          n    = (b0 * 65536) + (b1 * 256) + b2
          out4 = (cd b64 char tbl (n / 262144)) + (cd b64 char tbl ((n / 4096) % 64)) + (cd b64 char tbl ((n / 64) % 64)) + (cd b64 char tbl (n % 64))
          out4 + (cd b64 enc rem s (idx + 3) tbl pad)

fn :: cd b64 enc rem String Int String Bool => String
      cd b64 enc rem s idx tbl pad = cd b64 enc step s idx tbl pad ((str len s) - idx)

fn :: base64 encode String => String
      base64 encode s      =  cd b64 enc rem s 0 (cd b64 lut 0) True

fn :: base64url encode String => String
      base64url encode s      =  cd b64 enc rem s 0 (cd b64url lut 0) False

fn :: cd b64 val Int => Int
      cd b64 val c   =
        | c >= 65 and c <= 90  = c - 65
        | c >= 97 and c <= 122 = (c - 97) + 26
        | c >= 48 and c <= 57  = (c - 48) + 52
        | c == 43 or c == 45   = 62
        | c == 47 or c == 95   = 63
        | otherwise            = 0 - 1
```

### 07.4.3. Internal Implementation: RFC 3986 URL Percent-Encoding & Query Strings

Observe how `codec.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: cd is unreserved Int => Bool
      cd is unreserved c   =
        | c >= 65 and c <= 90                        = True
        | c >= 97 and c <= 122                       = True
        | c >= 48 and c <= 57                        = True
        | c == 45 or c == 95 or c == 46 or c == 126  = True
        | otherwise                                  = False

fn :: cd pct byte Int => String
      cd pct byte b   =
        ub  = ((b % 256) + 256) % 256
        hi  = ub / 16
        lo  = ub % 16
        tbl = cd hex up lut 0
        "%" + (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1))

fn :: cd url enc char String Int Int => String
      cd url enc char s idx c =
        | cd is unreserved c = str slice s idx (idx + 1)
        | otherwise          = cd pct byte c

fn :: cd url enc loop String Int Int => String
      cd url enc loop s idx len =
        | idx >= len = ""
        | otherwise  = (cd url enc char s idx (str char at s idx)) + (cd url enc loop s (idx + 1) len)

fn :: url encode String => String
      url encode s      =  cd url enc loop s 0 (str len s)

fn :: cd url dec pct String Int Int Int Int => String
      cd url dec pct s idx len hi lo =
        | hi >= 0 and lo >= 0 = (cd raw byte ((hi * 16) + lo)) + (cd url dec loop s (idx + 3) len)
        | otherwise           = "%" + (cd url dec loop s (idx + 1) len)

fn :: cd url dec at String Int Int Int => String
      cd url dec at s idx len c =
        | c == 43                     = " " + (cd url dec loop s (idx + 1) len)
        | c == 37 and (idx + 2) < len = cd url dec pct s idx len (cd hex val (str char at s (idx + 1))) (cd hex val (str char at s (idx + 2)))
        | otherwise                   = (str slice s idx (idx + 1)) + (cd url dec loop s (idx + 1) len)

fn :: cd url dec loop String Int Int => String
      cd url dec loop s idx len =
        | idx >= len = ""
        | otherwise  = cd url dec at s idx len (str char at s idx)

fn :: url decode String => String
      url decode s      =  cd url dec loop s 0 (str len s)

fn :: cd pair key (String String) => String
      cd pair key (k, _)          =  k
```

### 07.4.4. Internal Implementation: RFC 8259 Lightweight JSON Formatting & Field Extraction

Observe how `codec.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: cd json esc code String Int Int => String
      cd json esc code s idx c =
        | c == 34   = "\\\""
        | c == 92   = "\\\\"
        | c == 10   = "\\n"
        | c == 13   = "\\r"
        | c == 9    = "\\t"
        | otherwise = str slice s idx (idx + 1)

fn :: cd json esc loop String Int Int => String
      cd json esc loop s idx len =
        | idx >= len = ""
        | otherwise  = (cd json esc code s idx (str char at s idx)) + (cd json esc loop s (idx + 1) len)

fn :: json escape String => String
      json escape s      =  cd json esc loop s 0 (str len s)

fn :: cd json unesc next String Int Int Int => String
      cd json unesc next s idx len nc =
        | nc == 34  = "\"" + (cd json unesc loop s (idx + 2) len)
        | nc == 92  = "\\" + (cd json unesc loop s (idx + 2) len)
        | nc == 110 = "\n" + (cd json unesc loop s (idx + 2) len)
        | nc == 114 = "\r" + (cd json unesc loop s (idx + 2) len)
        | nc == 116 = "\t" + (cd json unesc loop s (idx + 2) len)
        | otherwise = (str slice s (idx + 1) (idx + 2)) + (cd json unesc loop s (idx + 2) len)

fn :: cd json unesc loop String Int Int => String
      cd json unesc loop s idx len =
        | idx >= len                                    = ""
        | (str char at s idx) == 92 and (idx + 1) < len = cd json unesc next s idx len (str char at s (idx + 1))
        | otherwise                                     = (str slice s idx (idx + 1)) + (cd json unesc loop s (idx + 1) len)

fn :: json unescape String => String
      json unescape s      =  cd json unesc loop s 0 (str len s)

fn :: json quote String => String
      json quote s      =  "\"" + (json escape s) + "\""

fn :: json int Int => String
      json int n   =  int to str n

fn :: json bool Bool  => String
      json bool True  =  "true"
      json bool False =  "false"

fn :: json null => String
      json null =  "null"
```

---

## 07.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `codec`

- **Algorithmic & Safety Guarantee**: Deterministic rejection of malformed Hex or Base64 inputs (returning `""` with zero out-of-bounds reads) and exact $decode(encode(x)) == x$ round-trip fidelity.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/codec.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test codec.rg`.

### The 5 Golden Rules When Programming with `codec`

1. **Declare `import codec` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `codec` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `codec`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `codec` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 08**, we will explore the **`json`** lib in full depth (The `json` Lib — Recursive RFC 8259 AST Parser, Pretty-Printer, and Dot-Path Queries).
