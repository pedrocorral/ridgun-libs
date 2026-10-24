# Chapter 25: The `argon2id` Lib — RFC 9106 Argon2id on `Tensor[U64 * 8 * 16]`, Blake2b, and OWASP Presets

## 1. Why Does the `argon2id` Lib Exist?

Let's be honest: hashing passwords with plain SHA-256 lets a modern GPU brute-force billions of guesses per second, yet linking external C libraries for Argon2id often brings FFI and build headaches.

The **`argon2id`** lib implements **RFC 9106 Argon2id** and **RFC 7693 Blake2b-512** in 100% pure Ridgun directly over native `Tensor[U64 * 8 * 16]` blocks (1,024 contiguous bytes per block in RMM2 memory), complete with **PHC** string formatting (`$argon2id$v=19$m=...,t=...,p=...$`), **OWASP** presets (`owaspfirst`, `owaspsecond`), secret pepper/associated-data context (`argon2id hash ctx`), raw key derivation (`argon2id derive key`), and parameter upgrade detection (`argon2id needs rehash`).

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`argon2id`** is a first-class **lib** located at `src/main/ridgun/lib/argon2id.rg` (domain `CRYPTO`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/argon2id.rglib` | Portable distribution and direct `import argon2id` resolution |
| **Compiled Archive** | `target/argon2id.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libargon2id.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import argon2id` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `argon2id`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `argon2id hash / argon2id verify` | 6-argument RFC 9106 PHC password hashing (`pwd, salt, m_kib, t, p, tag_len`) and constant-time verification |
| `argon2id hash with preset / argon2id params preset` | Hash using named presets: `"interactive"`, `"owaspfirst"` (`19456 KiB, t=2`), `"owaspsecond"` (`47104 KiB, t=1`), `"moderate"`, `"sensitive"` |
| `argon2id hash ctx / argon2id verify ctx` | RFC 9106 hashing with secret `pepper` ($K$) and associated data ($X$) |
| `argon2id derive key / argon2id needs rehash` | Raw binary key derivation and policy-upgrade detection on stored PHC strings |
| `blake2b / blake2b hex` | General-purpose RFC 7693 Blake2b cryptographic digest (`1..64` bytes) |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `argon2id`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import argon2id

fn :: proteger clave usuario (clave : String) => (String, Bool, Bool)
      proteger clave usuario clave =
        phc    = argon2id hash clave "sal-unica-16byte" 32 2 1 32
        valido = argon2id verify clave phc
        rehash = argon2id needs rehash phc 19456 2 1 32
        (phc, valido, rehash)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `argon2id` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import argon2id

fn :: derivar clave maestra (frase : String) (sal : String) => String
      derivar clave maestra frase sal =
        -- Deriva 32 bytes crudos listos para ChaCha20-Poly1305 AEAD
        argon2id derive key frase sal 64 2 1 32
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Byte-for-byte match with official RFC 9106 §5.3 and OpenSSL 3.5 test vectors, operating on native `Tensor[U64 * 8 * 16]` blocks without a single line of C.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_argon2id.rg`.
