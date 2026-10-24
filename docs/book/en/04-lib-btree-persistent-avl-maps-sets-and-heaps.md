# Chapter 04: The `btree` Lib — Persistent $O(\log N)$ AVL Maps, Sets, and Priority Queues

## 1. Why Does the `btree` Lib Exist?

Let's be honest: mutable hash tables are vulnerable to hash-flooding (HashDoS), cannot answer ordered range queries cleanly, and cannot be safely shared across concurrent actors without cloning or locking.

The **`btree`** lib implements three persistent $O(\log N)$ functional data structures with structural sharing: **`BTreeMap`** (self-balancing AVL tree), **`BTreeSet`** (ordered set algebra), and **`MinHeap`** (leftist priority queue).

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`btree`** is a first-class **lib** located at `src/main/ridgun/lib/btree.rg` (domain `BTREE`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/btree.rglib` | Portable distribution and direct `import btree` resolution |
| **Compiled Archive** | `target/btree.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libbtree.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import btree` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `btree`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `btree empty / btree insert / btree get / btree remove` | Persistent $O(\log N)$ AVL dictionary lookup, insertion, and deletion |
| `btree min key / btree max key / btree range` | Ordered extrema and range query `[lo, hi]` |
| `bset from list / bset union / bset intersect / bset diff` | Ordered set operations (`BTreeSet`) and subset predicate |
| `heap empty / heap push / heap peek / heap pop / heap sort` | Leftist `MinHeap` priority queue with $O(\log N)$ merge |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `btree`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import btree

fn :: consultar rango precios () => [String String]
      consultar rango precios =
        t0 = btree empty
        t1 = btree insert t0 "item:10" "Teclado"
        t2 = btree insert t1 "item:20" "Monitor"
        t3 = btree insert t2 "item:30" "Raton"
        btree range t3 "item:10" "item:25"
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `btree` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import btree

fn :: despachar urgente () => (Int, String)
      despachar urgente =
        h0 = heap empty
        h1 = heap push h0 50 "backup-nocturno"
        h2 = heap push h1 10 "alerta-seguridad"
        h3 = heap push h2 30 "rotar-logs"
        heap peek h3
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Strict AVL balance invariant (`|height_l - height_r| <= 1`), complete HashDoS immunity, $O(\log N + K)$ range queries, and $O(\log N)$ leftist heap merging.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_btree.rg`.
