# Chapter 19: The `uuid` Lib — RFC 9562 `UUIDv4`/`UUIDv7`, Checksums (`CRC-32`), and PRNG

## 1. Why Does the `uuid` Lib Exist?

Let's be honest: using random `UUIDv4` values as database primary keys fragments B-Tree indexes, while rolling ad-hoc IDs without kernel CSPRNG entropy leads to collisions.

The **`uuid`** lib implements **RFC 9562 `UUIDv4`** (kernel CSPRNG) and time-ordered **`UUIDv7`** (48-bit millisecond prefix for B-Tree locality), fast checksums (**FNV-1a**, **Adler-32**, **IEEE 802.3 CRC-32**), and a deterministic seeded PRNG.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`uuid`** is a first-class **lib** located at `src/main/ridgun/lib/uuid.rg` (domain `UUID`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/uuid.rglib` | Portable distribution and direct `import uuid` resolution |
| **Compiled Archive** | `target/uuid.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libuuid.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import uuid` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `uuid`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `uuid v4 / uuid v7 / uuid v7 at` | Generate RFC 9562 v4 (random) and v7 (time-ordered) canonical 36-char UUIDs |
| `uuid is valid / uuid version` | Validate 8-4-4-4-12 layout and RFC 9562 variant bits (`8, 9, a, b`) |
| `fnv1a 32 / adler32 / crc32 / crc32 hex` | Fast 32-bit non-cryptographic hashes and checksums |
| `prng next / prng range` | Pure functional Linear Congruential PRNG for reproducible tests and simulations |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `uuid`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import uuid

fn :: generar ids ordenados () => (String, String, Bool)
      generar ids ordenados =
        id1 = uuid v7 at 1000
        id2 = uuid v7 at 2000
        ok  = (uuid is valid id1) and (id1 < id2)
        (id1, id2, ok)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `uuid` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import uuid

fn :: firmar paquete (payload : String) => (String, Int)
      firmar paquete payload =
         (crc32 hex payload, fnv1a 32 payload)
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: `uuid v7 at t1 < uuid v7 at t2` guarantees monotonically increasing lexicographical order over time, ideal for `btree` indexes and databases.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_uuid.rg`.
