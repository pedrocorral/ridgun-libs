# Chapter 32: The `net_agent` Lib — Socket Connection Actor Supervisor and Non-Blocking Event Bridge

## 1. Why Does the `net_agent` Lib Exist?

Let's be honest: in a real server like **Solstice**, accepting TCP connections is the easy part; the hard part is enforcing max concurrent clients, reaping idle zombie connections, and bridging `ppoll` readiness into actor messages without leaking file descriptors.

The **`net_agent`** lib closes the loop of `ridgun-libs` by uniting **`posix`**, **`socket`**, and **`agent`**: it manages supervised connection tables (`NetSupervisor`), enforces concurrency limits (`max_conns`), reaps idle peers (`net evict idle`), bridges kernel descriptor readiness into typed actor events (`NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout`, `NetEvError`), and provides an end-to-end supervised TCP echo step (`net tcp echo step`).

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`net_agent`** is a first-class **lib** located at `src/main/ridgun/lib/net_agent.rg` (domain `AGENT`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/net_agent.rglib` | Portable distribution and direct `import net_agent` resolution |
| **Compiled Archive** | `target/net_agent.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libnet_agent.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import net_agent` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `net_agent`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `net supervisor new : Int -> Int -> NetSupervisor` | Create a connection supervisor with `max_conns` and `idle_timeout_ms` |
| `net register conn / net record rx / net record tx / net close conn` | Register accepted sockets, track byte counters/activity timestamps, and close peers |
| `net evict idle : NetSupervisor -> Int -> (NetSupervisor, [Int])` | Close and evict connections idle longer than `idle_timeout_ms`, returning evicted FDs |
| `net poll fd : Int -> Bool -> Int -> NetEvent` | Non-blocking `wait fd` bridge emitting `NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout`, or `NetEvError` |
| `net tcp echo step : String -> Int -> (Int, String)` | End-to-end loopback TCP listen/connect/accept/supervise/echo verification step |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `net_agent`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import net_agent

fn :: supervisar clientes () => (Int, [Int])
      supervisar clientes =
        s0        = net supervisor new 100 5000
        (s1, _)   = net register conn s0 10 "10.0.0.1" 51000 1000
        (s2, _)   = net register conn s1 11 "10.0.0.2" 51001 6500
        (s3, exp) = net evict idle s2 7000
        (net active count s3, exp)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `net_agent` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import net_agent

fn :: probar puente tcp supervisado () => (Int, String)
      probar puente tcp supervisado =
        net tcp echo step "ping-supervisado" 1000
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Automatic protection against descriptor exhaustion (`max_conns`), deterministic eviction of idle peers, and guaranteed socket cleanup in `net tcp echo step`.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_net_agent.rg`.
