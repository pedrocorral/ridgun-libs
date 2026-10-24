# Chapter 30: The `agent` Lib — Native Actor Concurrency (`agent`, `send`, `receive`), KV Store, and Rate Limiter

## 1. Why Does the `agent` Lib Exist?

Let's be honest: sharing mutable state across threads with `Mutex`, `RwLock`, and condition variables is an endless factory of deadlocks and race conditions.

The **`agent`** lib builds on Ridgun's **Native Agent Model** (`agent`, `send ... to`, `receive from`, `try receive from`, `stop`) to provide isolated message-passing actors, a concurrent key-value store (`KvStore`), a token-bucket rate limiter (`RateBucket`), and supervision state machines (`AgentHealth`).

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`agent`** is a first-class **lib** located at `src/main/ridgun/lib/agent.rg` (domain `AGENT`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/agent.rglib` | Portable distribution and direct `import agent` resolution |
| **Compiled Archive** | `target/agent.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libagent.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import agent` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `agent`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `agent roundtrip / agent drain count` | Spawn native Ridgun actors (`agent`), exchange messages (`send ... to` / `receive from`), and stop cleanly |
| `kv store new / kv store apply` | Actor-ready immutable key-value store (`KvPut`, `KvGet`, `KvDelete`, `KvClear`) |
| `rate bucket new / rate bucket allow` | Token-bucket rate limiter returning updated bucket and `(allowed, remaining)` |
| `sup mark failed / sup should restart` | Supervision policy helpers tracking restart budgets (`max_restarts`) |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `agent`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import agent

fn :: probar actor nativo () => (Int, Int)
      probar actor nativo =
        eco = agent roundtrip 42
        vac = agent drain count [10, 20, 30]
        (eco, vac)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `agent` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import agent

fn :: aplicar limite peticion () => (Bool, Int)
      aplicar limite peticion =
        b0         = rate bucket new 10 2 1000
        (b1, res1) = rate bucket allow b0 1 1000
        rateresp allowed res1, rateobs remaining res1
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Zero shared mutable memory across actors: every message is transferred by value / Copy-on-Write and `stop` deterministically reclaims the actor's region.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_agent.rg`.
