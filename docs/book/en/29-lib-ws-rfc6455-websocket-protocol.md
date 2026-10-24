# Chapter 29: The `ws` Lib — RFC 6455 WebSocket Handshake, 16/64-Bit Frame Codec, and XOR Masking

## 1. Why Does the `ws` Lib Exist?

Let's be honest: the WebSocket protocol (RFC 6455) combines a SHA-1 + Base64 upgrade handshake with variable-length binary framing (7-bit, 16-bit, or 64-bit) and mandatory client-to-server 4-byte XOR payload masking.

The **`ws`** lib implements full **RFC 6455** in pure Ridgun: `Sec-WebSocket-Accept` derivation (including a self-contained RFC 3174 SHA-1 solely for the handshake GUID), `101 Switching Protocols` HTTP upgrade builders, 7/16/64-bit `WsFrame` wire encoding/decoding, symmetric 4-byte XOR masking, and text/ping/pong/close frame constructors.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`ws`** is a first-class **lib** located at `src/main/ridgun/lib/ws.rg` (domain `WS`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/ws.rglib` | Portable distribution and direct `import ws` resolution |
| **Compiled Archive** | `target/ws.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libws.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import ws` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `ws`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `ws accept key : String -> String` | Compute RFC 6455 §1.3 `Sec-WebSocket-Accept` from `Sec-WebSocket-Key` |
| `ws build upgrade request / ws build upgrade response` | Format HTTP/1.1 WebSocket upgrade handshake messages |
| `ws encode frame / ws decode frame` | Encode and decode `WsFrame` (`fin`, `opcode`, `masked`, `mask_key`, `payload`) |
| `ws text frame / ws ping frame / ws pong frame / ws close frame` | High-level frame constructors and close-code extractors (`1000` normal closure) |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `ws`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import ws

fn :: negociar y enviar (client_key : String) => (String, String)
      negociar y enviar client_key =
        resp  = ws build upgrade response client_key
        trama = ws encode frame (ws text frame "hola-tiempo-real" False "")
        (resp, trama)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `ws` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import ws

fn :: decodificar trama cliente (clave4 : String) (msg : String) => String
      decodificar trama cliente clave4 msg =
        wire = ws encode frame (ws text frame msg True clave4)
        res  = ws decode frame wire
        ws frame payload res
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Exact match with the official RFC 6455 handshake vector (`"dGhlIHNhbXBsZSBub25jZQ=="` $\rightarrow$ `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="`) and automatic XOR unmasking in `ws decode frame`.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_ws.rg`.
