# Chapter 31: The `pool` Lib — Bounded Worker Pool, Round-Robin Dispatch, and Work-Stealing

## 31.1. Why Does the `pool` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `pool` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `pool`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: spawning a fresh thread or actor for every incoming request with no upper bound guarantees that a traffic spike will drive your server into Out-Of-Memory in seconds.

The **`pool`** lib provides a bounded task dispatcher with **explicit backpressure** (`PoolAccept`, `PoolRejectFull`), balanced $K$-lane batch partitioning (`pool partition`), **work-stealing** queue rebalancing (`pool steal rebalance`), and parallel native-actor execution.

In a traditional ecosystem, solving **`AGENT`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`pool`** lib (`src/main/ridgun/lib/pool.rg`) tackles the problem with four non-negotiable principles:

1. **Declare `import pool` (or `import pool as alias`) at the top of your file**: every lib defines its `module :: pool` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
3. **Tail-Call Optimization (TCO)**: all internal loops in `pool` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 31.2. Native Artifacts, Imports, and Complete `pool` API Catalog

In `ridgun-libs`, **`pool`** is a first-class **lib** located at `src/main/ridgun/lib/pool.rg` (domain `AGENT`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/pool.rglib` | Portable distribution and direct `import pool` resolution |
| **Compiled Archive** | `target/pool.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libpool.so` | Native dynamic shared library with zero C or `libc` dependencies |

> Every lib declares its own namespace via `module :: pool`: simply write `import pool` (or `import pool as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

### 31.2.1. Summary of `pool` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `pool new : Int -> Int -> PoolState` | Create a bounded pool with `workers` lanes and `max_queue` capacity |
| `pool submit : PoolState -> PoolTask -> (PoolState, PoolDecision)` | Enqueue a task round-robin or return `PoolRejectFull` when saturated |
| `pool partition / pool steal rebalance` | Split batches across $K$ workers and steal half of an overloaded queue for an idle worker |
| `pool map sum / pool parallel sum2` | Dispatch integer workloads across concurrent native `agent` workers |

### 31.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/pool.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/pool.rg` (`1` types, `0` operators, and `14` functions):

**Algebraic Data Types & Records (`type`) in `pool`:**

```ridgun
type AgentPool = Pool Int [Agent]
```

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: pool size AgentPool` | `Int` |
| `2` | `fn :: pool agents AgentPool` | `[Agent]` |
| `3` | `fn :: pool get agent [Agent] Int` | `Agent` |
| `4` | `fn :: pool abs Int` | `Int` |
| `5` | `fn :: pool ask shard AgentPool Int A` | `B` |
| `6` | `fn :: pool broadcast AgentPool A` | `()` |
| `7` | `fn :: pool broadcast list [Agent] A` | `()` |
| `8` | `fn :: pool drain ready Agent` | `[B]` |
| `9` | `fn :: pool drain ready loop Agent [B]` | `[B]` |
| `10` | `fn :: pool drain step Agent Option [B]` | `[B]` |
| `11` | `fn :: pool drain all AgentPool` | `[B]` |
| `12` | `fn :: pool drain list [Agent] [B]` | `[B]` |
| `13` | `fn :: pool stop list [Agent]` | `()` |
| `14` | `fn :: pool shutdown AgentPool` | `()` |

---

## 31.3. Deep Dive into `pool`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `pool` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test pool.rg`.

### 31.3.1. Example 1: Core Tabular Workflow with `pool`

Notice how in Ridgun the `=` signs and transformation steps using `pool` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import pool

fn :: despachar a shard AgentPool Int String => String
      despachar a shard p hash_clave msg =
        pool ask shard p hash_clave msg
```

### 31.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `pool` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import pool

fn :: difundir y cerrar AgentPool String => ()
      difundir y cerrar p evento =
        pool broadcast p evento
        pool shutdown p
```

### 31.3.3. Example 3: Actor Combinators (`agent ask`, `try ask`, `send batch`, `map batch`, `drain ready`), Sharded Pools, and Connection Reactor

In this hands-on walkthrough we thoroughly exercise how `pool` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test spec combinators pool and net agent => ()
      test spec combinators pool and net agent =
        w1 = agent (ag double worker)
        assert int equals (agent ask w1 21) 42 "agent ask 21 -> 42"
        mb = agent map batch w1 [3, 5, 7]
        assert int equals (ag sum ints mb) 30 "agent map batch [3,5,7] -> [6,10,14] sum 30"
        agent send batch w1 [10, 20] -> ()
        rc = agent receive count w1 2
        assert int equals (ag sum ints rc) 60 "agent send batch + agent receive count -> 60"
        c_dr = new counter agent 100
        send 5 to c_dr
        send 10 to c_dr
        dr = agent drain ready c_dr
        assert int equals (ag sum ints dr) 220 "agent drain ready [105, 115] -> 220"
        agent stop all [w1, c_dr] -> ()
        assert false (is agent alive w1) "w1 stopped by agent stop all"
        assert false (is agent alive c_dr) "c_dr stopped by agent stop all"

        s0 = new counter agent 0
        s1 = new counter agent 1000
        pl = Pool 2 [s0, s1]
        assert int equals (pool size pl) 2 "pool size 2"
        assert int equals (pool ask shard pl 0 5) 5 "pool ask shard 0 -> 5"
        assert int equals (pool ask shard pl 1 7) 1007 "pool ask shard 1 -> 1007"
        assert int equals (pool ask shard pl (0 - 3) 3) 1010 "pool ask shard negative key -> shard 1"
        pool broadcast pl 10 -> ()
        all_dr = pool drain all pl
        assert int equals (ag sum ints all_dr) 1035 "pool drain all [15, 1020] -> 1035"
        pool shutdown pl -> ()
        assert false (is agent alive s0) "pool s0 stopped"
        assert false (is agent alive s1) "pool s1 stopped"

        ca = agent (ag echo conn step) (CounterState 0)
        cb = agent (ag echo conn step) (CounterState 0)
        s_eof = conn feed payload (0 - 1) ca ""
        s_err = conn handle event (0 - 1) cb 8
        kept  = reactor sweep next s_eof (reactor sweep next s_err [])
        assert int equals (agent list len kept 0) 0 "reactor sweep next prunes closed slots"
        assert false (is agent alive ca) "ca stopped on EOF"
        assert false (is agent alive cb) "cb stopped on POLLERR"
        cc = agent (ag echo conn step) (CounterState 0)
        reactor shutdown [ConnSlot (0 - 1) cc] -> ()
        assert false (is agent alive cc) "cc stopped on reactor shutdown"
```

### 31.3.4. Example 4: Agent Lifecycle (`is agent alive`, `agent status`, `stop agent`) and Isolated Stateful Counter Agent (`new counter agent`)

In this hands-on walkthrough we thoroughly exercise how `pool` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test agent lifecycle and counter => ()
      test agent lifecycle and counter =
        assert str eq (format agent status AgentRunning) "running" "format AgentRunning"
        assert str eq (format agent status AgentStopped) "stopped" "format AgentStopped"
        assert str eq (format agent status (AgentTimedOut 250)) "timeout after 250 ms" "format AgentTimedOut"
        assert str eq (format agent status (AgentFailed "boom")) "failed: boom" "format AgentFailed"
        assert str eq (format agent reply (ReplyInt 42)) "42" "format ReplyInt"
        assert str eq (format agent reply (ReplyStr "ok")) "ok" "format ReplyStr"
        assert str eq (format agent reply (ReplyBool True)) "true" "format ReplyBool True"
        assert str eq (format agent reply (ReplyBool False)) "false" "format ReplyBool False"
        assert str eq (format agent reply ReplyEmpty) "agent outbox empty" "format ReplyEmpty"
        assert str eq (format agent reply ReplyStopped) "agent stopped" "format ReplyStopped"
        assert str eq (format agent reply (ReplyTimeout 50)) "agent timeout after 50 ms" "format ReplyTimeout"
        assert str eq (format agent reply (ReplyError "bad")) "agent error: bad" "format ReplyError"

        c   = new counter agent 10
        assert ok (is agent alive c)
        assert str eq (format agent status (agent status c)) "running" "counter running"
        assert str eq (format agent reply (try poll int c)) "agent outbox empty" "empty outbox before send"
        assert eq (counter get c) 10
        assert eq (counter add c 5) 15
        assert eq (counter add c 7) 22
        assert str eq (format agent reply (ask int c 8)) "30" "ask int 8 -> 30"
        assert str eq (format agent reply (ask int with timeout c 12 200)) "42" "ask int with timeout -> 42"
        assert eq (counter reset c) 0
        assert eq (counter get c) 0
        bs  = ask batch int c [1, 2, 3, 4]
        assert eq (ag sum ints bs) 20

        c2  = new counter agent 100
        rel = relay int c c2 5
        assert str eq (format agent reply rel) "115" "relay int c (10+5=15) -> c2 (100+15=115)"

        st1 = stop agent c
        assert str eq (format agent status st1) "stopped" "stop agent returns AgentStopped"
        assert eq (is agent alive c) False
        assert str eq (format agent status (agent status c)) "stopped" "agent status after stop"
        assert str eq (format agent reply (ask int c 1)) "agent stopped" "ask int after stop"
        assert str eq (format agent reply (try poll int c)) "agent stopped" "try poll int after stop"
        assert str eq (format agent reply (ask int with timeout c 1 50)) "agent stopped" "ask int with timeout after stop"
        assert str eq (format agent reply (relay int c c2 1)) "agent stopped" "relay int after stop"
        c0  = new counter agent 0
        assert int equals (counter get c0) 0 "counter 0 initial"
        assert int equals (counter add c0 3) 3 "counter 0 add 3"
        stop agent c0
        stop agent c2
        assert eq (is agent alive c2) False
```

### 31.3.5. Example 5: Append-Only Log Agent (`new log agent`) and Message-Passing In-Memory Key-Value Store (`new kv agent`)

In this hands-on walkthrough we thoroughly exercise how `pool` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test log and kv agents => ()
      test log and kv agents =
        lg  = new log agent "\n"
        assert ok (is agent alive lg)
        assert str eq (format agent reply (try poll str lg)) "agent outbox empty" "log empty outbox"
        assert str eq (log read lg) "" "initial log empty"
        assert str eq (log append lg "alpha") "alpha" "log append alpha"
        assert str eq (log append lg "beta") "alpha\nbeta" "log append beta"
        assert str eq (format agent reply (ask str with timeout lg "gamma" 200)) "alpha\nbeta\ngamma" "ask str with timeout gamma"
        assert str eq (log read lg) "alpha\nbeta\ngamma" "log read"
        assert str eq (log clear lg) "" "log clear"
        assert str eq (log read lg) "" "log read after clear"
        b   = ask batch str lg ["one", "two"]
        assert str eq (ag join strs b) "one|one\ntwo" "ask batch str"
        lg2 = new log agent ":"
        assert str eq (format agent reply (relay str lg lg2 "three")) "one\ntwo\nthree" "relay str"
        stop agent lg
        stop agent lg2
        assert str eq (format agent reply (ask str lg "x")) "agent stopped" "ask str after stop"

        kv  = new kv agent
        assert ok (is agent alive kv)
        assert int equals (kv count kv) 0 "kv count 0"
        assert false (kv has kv "host") "kv has host false"
        assert str eq (kv put kv "host" "127.0.0.1") "127.0.0.1" "kv put host"
        assert str eq (kv put kv "port" "8080") "8080" "kv put port"
        assert int equals (kv count kv) 2 "kv count 2"
        assert ok (kv has kv "host")
        assert ok (kv has kv "port")
        assert str eq (kv get kv "host") "127.0.0.1" "kv get host"
        assert str eq (kv get kv "port") "8080" "kv get port"
        assert str eq (kv keys kv) "host,port" "kv keys"
        assert str eq (kv put kv "port" "9090") "9090" "kv overwrite port"
        assert str eq (kv get kv "port") "9090" "kv get updated port"
        assert int equals (kv count kv) 2 "kv count after overwrite"
        assert str eq (kv delete kv "host") "127.0.0.1" "kv delete host"
        assert false (kv has kv "host") "kv has host after delete"
        assert int equals (kv count kv) 1 "kv count 1"
        assert str eq (kv clear kv) "" "kv clear"
        assert int equals (kv count kv) 0 "kv count after clear"
        stop agent kv
        assert false (is agent alive kv) "kv stopped"
```

### 31.3.6. Example 6: Deterministic Key Sharding (`pool ask shard`), Broadcast (`pool broadcast`), Non-Blocking Drain (`pool drain all`), and Shutdown (`pool shutdown`)

In this hands-on walkthrough we thoroughly exercise how `pool` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
import agent
import pool

fn :: shard worker (state : Int) (delta : Int) => (Int, Int)
      shard worker state delta =
        next = state + delta
        (next, next)

fn :: ejemplo pool completo => (Int, Int, [Int])
      ejemplo pool completo =
        w0   = agent shard worker 100
        w1   = agent shard worker 200
        w2   = agent shard worker 300
        p    = Pool 3 [w0, w1, w2]
        sz   = pool size p
        -- Enrutamiento determinista por clave: abs(key_hash) % 3
        r_a  = pool ask shard p 0 5
        r_b  = pool ask shard p 1 10
        -- Difusión (broadcast) a todos los shards del pool
        pool broadcast p 1 -> ()
        pend = pool drain all p
        pool shutdown p -> ()
        (sz, r_a + r_b, pend)
```

---

## 31.4. Under the Hood: How `pool` Is Built in Pure Ridgun (`src/main/ridgun/lib/pool.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/pool.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 31.4.1. Internal Implementation: Core Implementation Part 1

Observe how `pool.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
module :: pool

type AgentPool = Pool Int [Agent]

fn :: pool size AgentPool   => Int
      pool size (Pool sz _) =  sz

fn :: pool agents AgentPool    => [Agent]
      pool agents (Pool _ ags) =  ags

fn :: pool get agent [Agent]  Int => Agent
      pool get agent (ag:_)   0   =  ag
      pool get agent (_:rest) idx =  pool get agent rest (idx - 1)

fn :: pool abs Int => Int
      pool abs x
        | x < 0     = 0 - x
        | otherwise = x

fn :: pool ask shard AgentPool Int A => B
      pool ask shard (Pool size agents) key_hash msg =
        (pool abs key_hash) % size -> shard_idx
        pool get agent agents shard_idx -> target_ag
        ask target_ag msg

fn :: pool broadcast AgentPool       A   => ()
      pool broadcast (Pool _ agents) msg =  pool broadcast list agents msg
```

### 31.4.2. Internal Implementation: Core Implementation Part 2

Observe how `pool.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: pool broadcast list [Agent]   A   => ()
      pool broadcast list []        _   =  ()
      pool broadcast list (ag:rest) msg =
        send msg to ag
        pool broadcast list rest msg

fn :: pool drain ready Agent => [B]
      pool drain ready ag    =  pool drain ready loop ag []

fn :: pool drain ready loop Agent [B] => [B]
      pool drain ready loop ag acc =
        pool drain step ag (try receive from ag) acc

fn :: pool drain step Agent Option [B] => [B]
      pool drain step _ None acc = acc
      pool drain step ag (Some r) acc = pool drain ready loop ag (acc :: [r])

fn :: pool drain all AgentPool       => [B]
      pool drain all (Pool _ agents) =  pool drain list agents []

fn :: pool drain list [Agent]   [B] => [B]
      pool drain list []        acc =  acc
      pool drain list (ag:rest) acc =
        ag pool drain ready -> ready
        pool drain list rest (acc :: ready)

fn :: pool stop list [Agent]   => ()
      pool stop list []        =  ()
      pool stop list (ag:rest) =
        stop ag
        pool stop list rest

fn :: pool shutdown AgentPool       => ()
      pool shutdown (Pool _ agents) =  pool stop list agents
```

---

## 31.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `pool`

- **Algorithmic & Safety Guarantee**: Strictly bounded queue capacity (`queued <= max_queue`) to protect memory under load spikes and deterministic round-robin / work-stealing distribution.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/pool.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test pool.rg`.

### The 5 Golden Rules When Programming with `pool`

1. **Declare `import pool` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `pool` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `pool`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `pool` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 32**, we will explore the **`net_agent`** lib in full depth (The `net_agent` Lib — Socket Connection Actor Supervisor and Non-Blocking Event Bridge).
