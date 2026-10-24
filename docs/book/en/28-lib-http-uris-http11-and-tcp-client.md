# Chapter 28: The `http` Lib — RFC 3986 URIs, RFC 9112 HTTP/1.1 Wire Codec, and Live TCP Client

## 1. Why Does the `http` Lib Exist?

Let's be honest: failing to strip `\r\n` from HTTP header values invites CRLF header-injection attacks, while linking `libcurl` just to make a clean HTTP/1.1 `GET` or `POST` call is massive overkill.

The **`http`** lib implements **RFC 3986 URI** parsing, **RFC 9112 HTTP/1.1** request/response wire formatting and parsing with automatic CRLF sanitization (`VUL-INJ-002`) and `Content-Length` injection, `Bearer` token extraction, and a **live kernel-TCP HTTP/1.1 client** (`http get`, `http post`, `http request tcp`).

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`http`** is a first-class **lib** located at `src/main/ridgun/lib/http.rg` (domain `HTTP`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/http.rglib` | Portable distribution and direct `import http` resolution |
| **Compiled Archive** | `target/http.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libhttp.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import http` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `http`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `uri parse / uri scheme / uri host / uri port / uri path / uri query` | Decompose RFC 3986 URIs with automatic default ports (`80` for `http`, `443` for `https`) |
| `http build request / http parse request` | Format and parse HTTP/1.1 wire requests with CRLF header sanitization |
| `http build response / http parse response` | Format and parse HTTP/1.1 wire responses with status reason phrases |
| `http header get / http bearer token` | Case-insensitive header lookup and `Authorization: Bearer <token>` extraction |
| `http get / http post / http request tcp` | Execute live HTTP/1.1 calls over kernel TCP sockets with `timeout_ms` |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `http`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import http

fn :: inspeccionar endpoint (url : String) => (String, Int, String, String)
      inspeccionar endpoint url =
        host = uri host url
        port = uri port url
        path = uri path url
        wire = http build request "GET" path [("Host", host)] ""
        (host, port, path, wire)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `http` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import http

fn :: extraer credenciales (raw_req : String) => (String, String)
      extraer credenciales raw_req =
        (metodo, ruta, _, hdrs_raw, _) = http parse request raw_req
        hdrs = http parse headers hdrs_raw
        tok  = http bearer token hdrs
        (metodo + " " + ruta, tok)
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Automatic stripping of `\r` and `\n` across all header keys and values (`http sanitize header`) to prevent HTTP response-splitting attacks.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_http.rg`.
