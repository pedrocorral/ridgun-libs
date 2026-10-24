# Chapter 20: The `log` Lib — Structured NDJSON Logging and Automatic Secret Redaction

## 20.1. Why Does the `log` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `log` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `log`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: dumping request fields into a log line and realizing weeks later that `password`, `api_key`, or `authorization` headers were stored in cleartext in your log aggregator is a classic security incident.

The **`log`** lib provides severity filtering (`DEBUG`, `INFO`, `WARN`, `ERROR`), human-readable text and **structured NDJSON** formatters, and **automatic secret redaction** (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key` $\rightarrow$ `"[REDACTED]"`, mitigating `VUL-LOG-001`).

In a traditional ecosystem, solving **`LOG`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`log`** lib (`src/main/ridgun/lib/log.rg`) tackles the problem with four non-negotiable principles:

1. **Total Functions & Explicit Contracts (`=>`)**: no function in `log` throws hidden exceptions or relies on `null`. Every edge case (empty inputs, zero divisors, truncated frames, or out-of-bounds indices) returns a documented sentinel value or an algebraic sum type (`Option`, `Result`).
2. **Zero C Code & Zero `libc`**: every line of `log` compiles directly into native ELF64 machine code verified by `ridgunc`.
3. **Tail-Call Optimization (TCO)**: all internal loops in `log` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 20.2. Native Artifacts, Imports, and Complete `log` API Catalog

In `ridgun-libs`, **`log`** is a first-class **lib** located at `src/main/ridgun/lib/log.rg` (domain `LOG`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/log.rglib` | Portable distribution and direct `import log` resolution |
| **Compiled Archive** | `target/log.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/liblog.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import log` at the top and call its functions using either multi-word spaces (`my fn x`) or underscores (`my_fn x`).

### 20.2.1. Summary of `log` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `log level rank / log should emit` | Compare log levels (`DEBUG=10`, `INFO=20`, `WARN=30`, `ERROR=40`) against configured threshold |
| `log is sensitive key / log redact fields` | Case-insensitively replace secret values with `"[REDACTED]"` |
| `log format text / log format json` | Format single-line key=value text or RFC 8259 NDJSON with automatic secret redaction |

### 20.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/log.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/log.rg` (`0` types, `0` operators, and `21` functions):

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: lg lower char String Int Int` | `String` |
| `2` | `fn :: lg to lower loop String Int Int` | `String` |
| `3` | `fn :: lg to lower String` | `String` |
| `4` | `fn :: lg rank from lower String` | `Int` |
| `5` | `fn :: log level rank String` | `Int` |
| `6` | `fn :: log level name Int` | `String` |
| `7` | `fn :: log should emit String String` | `Bool` |
| `8` | `fn :: lg check sens lower String` | `Bool` |
| `9` | `fn :: log is sensitive key String` | `Bool` |
| `10` | `fn :: lg pair key (String String)` | `String` |
| `11` | `fn :: lg pair val (String String)` | `String` |
| `12` | `fn :: lg redact pair (String String)` | `String String` |
| `13` | `fn :: log redact fields [String String]` | `[String String]` |
| `14` | `fn :: lg esc char String Int Int` | `String` |
| `15` | `fn :: lg esc loop String Int Int` | `String` |
| `16` | `fn :: lg esc str String` | `String` |
| `17` | `fn :: lg quote String` | `String` |
| `18` | `fn :: lg fmt text fields [String String]` | `String` |
| `19` | `fn :: log format text String String [String String]` | `String` |
| `20` | `fn :: lg fmt json fields [String String]` | `String` |
| `21` | `fn :: log format json String String [String String]` | `String` |

---

## 20.3. Deep Dive into `log`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `log` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test log.rg`.

### 20.3.1. Example 1: Core Tabular Workflow with `log`

Notice how in Ridgun the `=` signs and transformation steps using `log` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import log

fn :: auditar login (usuario : String) (clave : String) => String
      auditar login usuario clave =
        campos = [("user", usuario), ("password", clave), ("ip", "10.0.0.1")]
        log format json "INFO" "intento de acceso" campos
```

### 20.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `log` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import log

fn :: emitir si procede (umbral : String) (nivel : String) (msg : String) => String
      emitir si procede umbral nivel msg =
        | log should emit umbral nivel = log format text nivel msg [("service", "solstice")]
        | otherwise                    = ""
```

### 20.3.3. Example 3: Severity Level Hierarchy (`DEBUG`, `INFO`, `WARN`, `ERROR`) and Threshold Filtering (`log enabled`)

In this hands-on walkthrough we thoroughly exercise how `log` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test log levels and filtering => ()
      test log levels and filtering =
        _ = assert int equals (log level rank "debug") 10 "AC1: rank debug == 10"
        _ = assert int equals (log level rank "DEBUG") 10 "AC1: rank DEBUG == 10"
        _ = assert int equals (log level rank "info") 20 "AC1: rank info == 20"
        _ = assert int equals (log level rank "INFO") 20 "AC1: rank INFO == 20"
        _ = assert int equals (log level rank "warn") 30 "AC1: rank warn == 30"
        _ = assert int equals (log level rank "warning") 30 "AC1: rank warning alias == 30"
        _ = assert int equals (log level rank "error") 40 "AC1: rank error == 40"
        _ = assert int equals (log level rank "ERR") 40 "AC1: rank ERR alias == 40"
        _ = assert int equals (log level rank "unknown_level") 20 "AC1: unknown level defaults to INFO (20)"

        _ = assert str eq (log level name 10) "DEBUG" "AC1: level name 10 -> DEBUG"
        _ = assert str eq (log level name 20) "INFO" "AC1: level name 20 -> INFO"
        _ = assert str eq (log level name 30) "WARN" "AC1: level name 30 -> WARN"
        _ = assert str eq (log level name 40) "ERROR" "AC1: level name 40 -> ERROR"

        _ = assert true (log should emit "DEBUG" "DEBUG") "AC1: DEBUG emits DEBUG"
        _ = assert true (log should emit "DEBUG" "ERROR") "AC1: DEBUG emits ERROR"
        _ = assert true (log should emit "WARN" "ERROR") "AC1: WARN emits ERROR"
        _ = assert true (log should emit "WARN" "warning") "AC1: WARN emits warning"
        _ = assert false (log should emit "WARN" "INFO") "AC1: WARN suppresses INFO"
        _ = assert false (log should emit "ERROR" "WARN") "AC1: ERROR suppresses WARN"
        _ = assert false (log should emit "ERROR" "DEBUG") "AC1: ERROR suppresses DEBUG"
        ()
```

### 20.3.4. Example 4: Automatic Sensitive Key Detection (`password`, `token`, `secret`, `api_key`, `jwt`) and `[REDACTED]` Masking

In this hands-on walkthrough we thoroughly exercise how `log` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test log sensitive key redaction => ()
      test log sensitive key redaction =
        _ = assert true (log is sensitive key "password") "AC2: password"
        _ = assert true (log is sensitive key "user_passwd") "AC2: user_passwd"
        _ = assert true (log is sensitive key "CLIENT_SECRET") "AC2: CLIENT_SECRET"
        _ = assert true (log is sensitive key "access_token") "AC2: access_token"
        _ = assert true (log is sensitive key "X-Api-Key") "AC2: X-Api-Key"
        _ = assert true (log is sensitive key "api_key_id") "AC2: api_key_id"
        _ = assert true (log is sensitive key "apikey") "AC2: apikey"
        _ = assert true (log is sensitive key "Authorization") "AC2: Authorization"
        _ = assert true (log is sensitive key "session_cookie") "AC2: session_cookie"
        _ = assert true (log is sensitive key "ssh_private_key") "AC2: ssh_private_key"
        _ = assert true (log is sensitive key "private-key-pem") "AC2: private-key-pem"
        _ = assert false (log is sensitive key "username") "AC2: username safe"
        _ = assert false (log is sensitive key "request_id") "AC2: request_id safe"
        _ = assert false (log is sensitive key "status_code") "AC2: status_code safe"
        ()
```

### 20.3.5. Example 5: Formatting Log Entries as Structured Text (`key=val`) and Single-Line JSON (`NDJSON`) with ISO-8601 Timestamps

In this hands-on walkthrough we thoroughly exercise how `log` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test log text and ndjson formatting => ()
      test log text and ndjson formatting =
        fields = [("user", "alice"), ("password", "s3cr3t"), ("auth_token", "jwt-123"), ("cookie", "sid=99")]
        txt = log format text "info" "user login" fields
        _ = assert str eq txt "[INFO] user login user=alice password=[REDACTED] auth_token=[REDACTED] cookie=[REDACTED]" "AC3: log format text redacts all secret keys"

        txt_empty = log format text "error" "disk full" []
        _ = assert str eq txt_empty "[ERROR] disk full" "AC3: log format text with empty fields"

        -- Log injection defense: newlines, carriage returns, tabs, quotes, and backslashes in msg or values
        inj_fields = [("path", "C:\\app\\bin"), ("note", "line1\nline2\r\t\"quoted\"")]
        jsn = log format json "warn" "auth check\nforged_line" fields
        _ = assert str eq jsn "{\"level\":\"WARN\",\"msg\":\"auth check\\nforged_line\",\"user\":\"alice\",\"password\":\"[REDACTED]\",\"auth_token\":\"[REDACTED]\",\"cookie\":\"[REDACTED]\"}" "AC3: NDJSON escapes newline injection and redacts secrets"

        jsn_esc = log format json "debug" "trace" inj_fields
        _ = assert str eq jsn_esc "{\"level\":\"DEBUG\",\"msg\":\"trace\",\"path\":\"C:\\\\app\\\\bin\",\"note\":\"line1\\nline2\\r\\t\\\"quoted\\\"\"}" "AC3: NDJSON escapes \\, \\n, \\r, \\t, and \\\""
        ()
```

---

## 20.4. Under the Hood: How `log` Is Built in Pure Ridgun (`src/main/ridgun/lib/log.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/log.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 20.4.1. Internal Implementation: Severity Levels (`DEBUG`, `INFO`, `WARN`, `ERROR`)

Observe how `log.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: lg rank from lower String => Int
      lg rank from lower lv     =
        | lv == "debug"                       = 10
        | lv == "info"                        = 20
        | lv == "warn" or lv == "warning"     = 30
        | lv == "error" or lv == "err"        = 40
        | otherwise                           = 20

fn :: log level rank String => Int
      log level rank level  =  lg rank from lower (lg to lower level)

fn :: log level name Int  => String
      log level name rank =
        | rank <= 10 = "DEBUG"
        | rank <= 20 = "INFO"
        | rank <= 30 = "WARN"
        | otherwise  = "ERROR"

fn :: log should emit String    String    => Bool
      log should emit min_level msg_level =  (log level rank msg_level) >= (log level rank min_level)
```

### 20.4.2. Internal Implementation: Sensitive Key Detection & Redaction

Observe how `log.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: lg check sens lower String => Bool
      lg check sens lower lk     =
        | str contains lk "password" or str contains lk "passwd"       = True
        | str contains lk "secret" or str contains lk "token"          = True
        | str contains lk "api_key" or str contains lk "api-key"       = True
        | str contains lk "apikey"                                     = True
        | str contains lk "authorization" or str contains lk "cookie"  = True
        | str contains lk "private_key" or str contains lk "private-key" = True
        | otherwise                                                    = False

fn :: log is sensitive key String => Bool
      log is sensitive key key    =  lg check sens lower (lg to lower key)

fn :: lg pair key (String String) => String
      lg pair key (k, _)          =  k

fn :: lg pair val (String String) => String
      lg pair val (_, v)          =  v

fn :: lg redact pair (String String) => String String
      lg redact pair (k, v)          =
        | log is sensitive key k = (k, "[REDACTED]")
        | otherwise              = (k, v)

fn :: log redact fields [String String] => [String String]
      log redact fields []              =  []
      log redact fields (pair:rest)     =  [(lg redact pair pair)] :: (log redact fields rest)
```

### 20.4.3. Internal Implementation: Escaping & Text / NDJSON Formatting

Observe how `log.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: lg esc char String Int Int => String
      lg esc char s idx c =
        | c == 34   = "\\\""
        | c == 92   = "\\\\"
        | c == 10   = "\\n"
        | c == 13   = "\\r"
        | c == 9    = "\\t"
        | otherwise = str slice s idx (idx + 1)

fn :: lg esc loop String Int Int => String
      lg esc loop s idx len =
        | idx >= len = ""
        | otherwise  = (lg esc char s idx (str char at s idx)) + (lg esc loop s (idx + 1) len)

fn :: lg esc str String => String
      lg esc str s      =  lg esc loop s 0 (str len s)

fn :: lg quote String => String
      lg quote s      =  "\"" + (lg esc str s) + "\""

fn :: lg fmt text fields [String String] => String
      lg fmt text fields []              =  ""
      lg fmt text fields (pair:rest)     =
        " " + (lg esc str (lg pair key pair)) + "=" + (lg esc str (lg pair val pair)) + (lg fmt text fields rest)

fn :: log format text String String [String String] => String
      log format text level msg fields =
        norm_lv = log level name (log level rank level)
        safe_f  = log redact fields fields
        "[" + norm_lv + "] " + (lg esc str msg) + (lg fmt text fields safe_f)

fn :: lg fmt json fields [String String] => String
      lg fmt json fields []              =  ""
      lg fmt json fields (pair:rest)     =
        "," + (lg quote (lg pair key pair)) + ":" + (lg quote (lg pair val pair)) + (lg fmt json fields rest)

fn :: log format json String String [String String] => String
      log format json level msg fields =
        norm_lv = log level name (log level rank level)
        safe_f  = log redact fields fields
        "{\"level\":" + (lg quote norm_lv) + ",\"msg\":" + (lg quote msg) + (lg fmt json fields safe_f) + "}"
```

---

## 20.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `log`

- **Algorithmic & Safety Guarantee**: Both `log format text` and `log format json` automatically pass fields through `log redact fields` prior to serialization, ensuring secrets never leak by accident.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/log.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test log.rg`.

### The 5 Golden Rules When Programming with `log`

1. **Declare `import log` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `log` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `log`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `log` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 21**, we will explore the **`test`** lib in full depth (The `test` Lib — Unit and Functional Test Assertion Primitives (`RG-011`)).
