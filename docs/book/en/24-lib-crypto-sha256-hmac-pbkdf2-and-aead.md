# Chapter 24: The `crypto` Lib — SHA-256, HMAC, PBKDF2, Argon2id, and ChaCha20-Poly1305 AEAD

## 1. Why Does the `crypto` Lib Exist?

Let's be honest: comparing an HMAC tag with `==` opens the door to timing side-channel attacks, while linking `libssl.so` just to compute `SHA-256` or encrypt with `ChaCha20-Poly1305` ruins static binary portability.

The **`crypto`** lib implements in 100% pure Ridgun over pre-allocated `Tensor[Int]` state: raw byte/bitwise primitives (`RGF-019`), **FIPS 180-4 SHA-256**, **RFC 2104 HMAC-SHA-256**, constant-time equality (`ct equal`), midstate-accelerated **RFC 8018 PBKDF2-HMAC-SHA-256**, 5-argument **Argon2id**, and **RFC 8439 ChaCha20-Poly1305 AEAD** (`aead seal` / `aead open`).

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`crypto`** is a first-class **lib** located at `src/main/ridgun/lib/crypto.rg` (domain `CRYPTO`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/crypto.rglib` | Portable distribution and direct `import crypto` resolution |
| **Compiled Archive** | `target/crypto.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libcrypto.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import crypto` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `crypto`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `sha256 bytes / sha256 hex` | FIPS 180-4 32-byte binary digest or 64-char lowercase hex digest |
| `hmac sha256 / hmac sha256 hex / ct equal` | RFC 2104 keyed MAC and constant-time accumulator comparison |
| `pbkdf2 hmac sha256 : String -> String -> Int -> Int -> String` | RFC 8018 key derivation with precomputed inner/outer SHA-256 midstates |
| `argon2id hash / argon2id verify` | 5-argument RFC 9106 PHC password hashing and constant-time verification |
| `aead seal / aead open` | RFC 8439 ChaCha20-Poly1305 authenticated encryption and tag-verified decryption |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `crypto`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import crypto

fn :: cifrar mensaje sesion (secreto : String) (texto : String) => (Int, String)
      cifrar mensaje sesion secreto texto =
        key32   = sha256 bytes secreto
        nonce12 = "0123456789ab"
        aad     = "canal-autenticado"
        sellado = aead seal key32 nonce12 aad texto
        aead open key32 nonce12 aad sellado
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `crypto` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import crypto

fn :: verificar firma webhook (clave : String) (cuerpo : String) (firma_hex : String) => Bool
      verificar firma webhook clave cuerpo firma_hex =
        esperada = hmac sha256 hex clave cuerpo
        ct equal esperada firma_hex
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: `aead open` verifies the 16-byte Poly1305 authentication tag in constant time before releasing a single byte of plaintext (returning `(-1, "")` on tamper).
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_crypto.rg`.
