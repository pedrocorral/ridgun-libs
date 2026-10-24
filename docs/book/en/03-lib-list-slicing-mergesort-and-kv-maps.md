# Chapter 03: The `list` Lib — Slicing, $O(N \log N)$ Mergesort, and Associative KV Maps

## 1. Why Does the `list` Lib Exist?

Let's be honest: out-of-bounds index panics (`IndexError` / `panic!`) and accidental mutation of shared lists are two of the most common bugs in everyday collection processing.

The **`list`** lib provides default-safe indexing, slicing (`take`, `drop`, `slice`), stepped ranges, stable deduplication, **$O(N \log N)$ mergesort** for `[Int]` and `[String]`, and immutable `[String String]` key-value maps (`kv get`, `kv put`, `kv merge`).

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`list`** is a first-class **lib** located at `src/main/ridgun/lib/list.rg` (domain `LIST`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/list.rglib` | Portable distribution and direct `import list` resolution |
| **Compiled Archive** | `target/list.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/liblist.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import list` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `list`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `list nth or / list str nth or` | Safe index lookup returning `default_val` when out of bounds |
| `list take / list drop / list slice / list reverse` | Prefix, suffix, subrange `[start, end)`, and tail-recursive reversal |
| `list range / list range step` | Generate arithmetic sequences (`step == 0` safely returns `[]`) |
| `list sort / list str sort / list dedup / list str dedup` | Stable $O(N \log N)$ top-down mergesort and first-seen deduplication |
| `kv empty / kv put / kv get / kv get or / kv remove / kv merge` | Ordered associative `[String String]` key-value dictionary operations |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `list`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import list

fn :: top tres unicos (puntos : [Int]) => [Int]
      top tres unicos puntos =
        unicos    = list dedup puntos
        ordenados = list reverse (list sort unicos)
        list take ordenados 3
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `list` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import list

fn :: configurar entorno (base : [String String]) => (String, [String])
      configurar entorno base =
        cfg1 = kv put base "host" "0.0.0.0"
        cfg2 = kv put cfg1 "port" "8080"
        host = kv get or cfg2 "host" "127.0.0.1"
        (host, kv keys cfg2)
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Worst-case $O(N \log N)$ deterministic mergesort (immune to Quicksort's $O(N^2)$ adversarial inputs) and insertion-order preservation on `kv` maps.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_list.rg`.
