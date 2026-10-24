# Chapter 26: The `jwt` Lib — RFC 7519 `HS256` JSON Web Tokens and ChaCha20-Poly1305 Encrypted Tokens

## 1. Why Does the `jwt` Lib Exist?

Let's be honest: the JWT ecosystem is notorious for `"alg":"none"` signature-bypass bugs and for developers stuffing confidential data into a standard JWT while forgetting that its payload is merely Base64url-encoded, not encrypted.

The **`jwt`** lib solves both needs: it signs and verifies **RFC 7519 (`HS256`) JWTs** while strictly enforcing `alg == "HS256"`, constant-time MAC comparison, and `exp`/`nbf` windows, and it also provides **`token seal` / `token open`** for opaque tokens encrypted with **ChaCha20-Poly1305 AEAD**.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`jwt`** is a first-class **lib** located at `src/main/ridgun/lib/jwt.rg` (domain `JWT`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/jwt.rglib` | Portable distribution and direct `import jwt` resolution |
| **Compiled Archive** | `target/jwt.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libjwt.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import jwt` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `jwt`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `type JwtResult` | `JwtOk JsonVal | JwtExpired | JwtNotYetValid | JwtBadSignature | JwtMalformed` |
| `jwt sign hs256 / jwt verify hs256` | Sign `JsonVal` claims and verify signature + `alg == "HS256"` + `exp`/`nbf` |
| `jwt claims / jwt get str / jwt get int` | Build standard `(sub, iss, iat, exp)` claims and query verified payloads |
| `token seal / token open` | Encrypt and authenticate opaque JSON tokens via ChaCha20-Poly1305 AEAD |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `jwt`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import jwt
import json

fn :: emitir y verificar sesion (secreto : String) => (String, String)
      emitir y verificar sesion secreto =
        claims = jwt claims "user-42" "solstice" 1700000000 1700003600
        tok    = jwt sign hs256 secreto claims
        res    = jwt verify hs256 secreto tok 1700001000
        sub    = jwt get str res "sub" "anonimo"
        (tok, sub)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `jwt` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import jwt
import json

fn :: sellar token confidencial (clave : String) => JwtResult
      sellar token confidencial clave =
        datos = JnObj [("rol", JnStr "root"), ("pin", JnInt 9988)]
        sobre = token seal clave "nonce-12byte" datos
        token open clave sobre
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Complete immunity to `"alg":"none"` downgrade attacks (any header where `alg != "HS256"` returns `JwtBadSignature`) and constant-time MAC verification.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_jwt.rg`.
