# Chapter 07: The `codec` Lib — RFC 4648 Hex, Base64, Base64url, and URL Percent-Encoding

## 1. Why Does the `codec` Lib Exist?

Let's be honest: nothing breaks a web integration faster than mixing up standard Base64 (`+/=`) with unpadded URL-safe Base64url (`-_`) inside a JWT, or building query strings by naive string concatenation.

The **`codec`** lib implements **RFC 4648** (Hex, Base64, and URL-safe Base64url), **RFC 3986** (URL percent-encoding and `query encode` / `query decode`), and lightweight **RFC 8259 JSON** builders and field extractors.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`codec`** is a first-class **lib** located at `src/main/ridgun/lib/codec.rg` (domain `CODEC`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/codec.rglib` | Portable distribution and direct `import codec` resolution |
| **Compiled Archive** | `target/codec.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libcodec.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import codec` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `codec`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `hex encode / hex decode / hex is valid` | Lowercase RFC 4648 hexadecimal encoding and validated decoding |
| `base64 encode / base64 decode` | Standard RFC 4648 §4 Base64 with `=` padding |
| `base64url encode / base64url decode` | URL-safe RFC 4648 §5 Base64url (`-`, `_`, unpadded) |
| `url encode / url decode / query encode / query decode` | RFC 3986 percent-encoding and `k=v&...` query string round-trips |
| `json quote / json object / json get str / json get int` | Fast zero-AST JSON serialization and top-level key lookup |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `codec`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import codec

fn :: empaquetar parametros (usuario : String) (redir : String) => String
      empaquetar parametros usuario redir =
        token_b64 = base64url encode usuario
        query encode [("token", token_b64), ("next", redir)]
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `codec` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import codec

fn :: construir respuesta rapida (id : Int) (nombre : String) => (String, Int)
      construir respuesta rapida id nombre =
        doc = json object [("id", json int id), ("name", json quote nombre), ("ok", json bool True)]
        leido = json get int doc "id" 0
        (doc, leido)
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Deterministic rejection of malformed Hex or Base64 inputs (returning `""` with zero out-of-bounds reads) and exact $decode(encode(x)) == x$ round-trip fidelity.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_codec.rg`.
