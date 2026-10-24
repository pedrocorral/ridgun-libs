# Chapter 08: The `json` Lib — Recursive RFC 8259 AST Parser, Pretty-Printer, and Dot-Path Queries

## 1. Why Does the `json` Lib Exist?

Let's be honest: navigating deeply nested JSON in many statically typed languages means writing pages of boilerplate or chaining ten `.and_then()` calls just to read a single port number.

The **`json`** lib provides a full recursive-descent **RFC 8259** parser into the algebraic `JsonVal` ADT (`JnNull`, `JnBool`, `JnInt`, `JnStr`, `JnArr`, `JnObj`, `JnErr`), compact and indented serializers (`json pretty`), and dot-path queries (`"server.http.port"`, `"users.0.name"`).

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`json`** is a first-class **lib** located at `src/main/ridgun/lib/json.rg` (domain `JSON`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/json.rglib` | Portable distribution and direct `import json` resolution |
| **Compiled Archive** | `target/json.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libjson.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import json` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `json`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `type JsonVal` | `JnNull | JnBool Bool | JnInt Int | JnStr String | JnArr [JsonVal] | JnObj [String JsonVal] | JnErr String` |
| `json parse / json is ok` | Parse raw JSON text into `JsonVal` and validate absence of `JnErr` |
| `json stringify / json pretty` | Serialize `JsonVal` into compact or multi-line indented JSON |
| `json get path / json get str / json get int / json get bool` | Traverse nested objects and arrays via dot-separated paths (`"a.b.0.c"`) |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `json`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import json

fn :: leer config servidor (raw : String) => (String, Int, Bool)
      leer config servidor raw =
        doc  = json parse raw
        host = json get str doc "server.host" "127.0.0.1"
        port = json get int doc "server.port" 8080
        tls  = json get bool doc "server.tls.enabled" False
        (host, port, tls)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `json` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import json

fn :: construir manifiesto () => String
      construir manifiesto =
        nodo = JnObj [("app", JnStr "solstice"), ("workers", JnInt 8), ("tags", JnArr [JnStr "elf64", JnStr "rmm2"])]
        json pretty nodo 2
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Strict rejection of trailing garbage after the root value, full escape-sequence handling, and exception-free `JnErr` reporting.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_json.rg`.
