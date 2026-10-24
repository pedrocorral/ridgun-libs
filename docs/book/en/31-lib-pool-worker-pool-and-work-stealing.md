# Chapter 31: The `pool` Lib — Bounded Worker Pool, Round-Robin Dispatch, and Work-Stealing

## 1. Why Does the `pool` Lib Exist?

Let's be honest: spawning a fresh thread or actor for every incoming request with no upper bound guarantees that a traffic spike will drive your server into Out-Of-Memory in seconds.

The **`pool`** lib provides a bounded task dispatcher with **explicit backpressure** (`PoolAccept`, `PoolRejectFull`), balanced $K$-lane batch partitioning (`pool partition`), **work-stealing** queue rebalancing (`pool steal rebalance`), and parallel native-actor execution.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`pool`** is a first-class **lib** located at `src/main/ridgun/lib/pool.rg` (domain `AGENT`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/pool.rglib` | Portable distribution and direct `import pool` resolution |
| **Compiled Archive** | `target/pool.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libpool.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import pool` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `pool`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `pool new : Int -> Int -> PoolState` | Create a bounded pool with `workers` lanes and `max_queue` capacity |
| `pool submit : PoolState -> PoolTask -> (PoolState, PoolDecision)` | Enqueue a task round-robin or return `PoolRejectFull` when saturated |
| `pool partition / pool steal rebalance` | Split batches across $K$ workers and steal half of an overloaded queue for an idle worker |
| `pool map sum / pool parallel sum2` | Dispatch integer workloads across concurrent native `agent` workers |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `pool`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import pool

fn :: encolar con contrapresion () => (Int, Int)
      encolar con contrapresion =
        p0        = pool new 4 16
        tarea     = PoolTask 1 100 "indexar-bloque"
        (p1, dec) = pool submit p0 tarea
        (pool queued p1, pool accepted p1)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `pool` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import pool

fn :: sumar en paralelo () => Int
      sumar en paralelo =
        pool parallel sum2 [10, 20, 30] [40, 50, 60]
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Strictly bounded queue capacity (`queued <= max_queue`) to protect memory under load spikes and deterministic round-robin / work-stealing distribution.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_pool.rg`.
