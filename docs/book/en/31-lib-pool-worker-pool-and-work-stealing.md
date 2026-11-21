# Chapter 31: The `pool` Lib — Agent Pools: Sharding by Key, Broadcast, and Non-Blocking Drain

## 31.1. Why Does the `pool` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `pool` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `pool`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: spawning a fresh thread or actor for every incoming request with no upper bound guarantees that a traffic spike will drive your server into Out-Of-Memory in seconds.

The **`pool`** lib groups a fixed number of agents into an `AgentPool`: `pool ask shard` sends each request to the agent chosen by its key, so the same key always reaches the same agent; `pool broadcast` sends one message to every agent; `pool drain all` collects, without blocking, the replies that are ready; and `pool shutdown` stops all of them.

In a traditional ecosystem, solving **`AGENT`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`pool`** lib (`src/main/ridgun/lib/pool.ridgun`) tackles the problem with four non-negotiable principles:

1. **Declare `import pool` (or `import pool as alias`) at the top of your file**: every lib defines its `module :: pool` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
3. **Tail-Call Optimization (TCO)**: all internal loops in `pool` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 31.2. Native Artifacts, Imports, and Complete `pool` API Catalog

In `ridgun-libs`, **`pool`** is a first-class **lib** located at `src/main/ridgun/lib/pool.ridgun` (domain `AGENT`). When built with `stable bundle`, it compiles into one native artifact:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/pool.ridgunlib` | Portable distribution and direct `import pool` resolution |

> Every lib declares its own namespace via `module :: pool`: simply write `import pool` (or `import pool as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

### 31.2.1. Summary of `pool` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `Pool / pool size / pool agents` | An `AgentPool` with a fixed number of agents, its size and its agents |
| `pool ask shard` | Request-reply with the agent chosen by key: the same key always reaches the same agent |
| `pool broadcast` | Send one message to every agent of the pool |
| `pool drain all / pool drain ready` | Collect the replies that are ready, without blocking |
| `pool shutdown` | Stop every agent of the pool |

### 31.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/pool.ridgun`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/pool.ridgun` (`1` types, `0` operators, and `15` functions):

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
| `7` | `fn :: pool send one Agent A` | `()` |
| `8` | `fn :: pool broadcast list [Agent] A` | `()` |
| `9` | `fn :: pool drain ready Agent` | `[B]` |
| `10` | `fn :: pool drain ready loop Agent [B]` | `[B]` |
| `11` | `fn :: pool drain step Agent Option [B]` | `[B]` |
| `12` | `fn :: pool drain all AgentPool` | `[B]` |
| `13` | `fn :: pool drain list [Agent] [B]` | `[B]` |
| `14` | `fn :: pool stop list [Agent]` | `()` |
| `15` | `fn :: pool shutdown AgentPool` | `()` |

---

## 31.3. Deep Dive into `pool`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `pool` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test pool.ridgun`.

### 31.3.1. Example 1: Core Tabular Workflow with `pool`

Notice how in Ridgun the `=` signs and transformation steps using `pool` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import pool

fn :: despachar a shard AgentPool Int String => String
      despachar a shard p hash_clave msg =
        pool ask shard p hash_clave msg
```

### 31.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `pool` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 38 libs in `ridgun-libs`:

```ridgun
import pool

fn :: difundir y cerrar AgentPool String => ()
      difundir y cerrar p evento =
        pool broadcast p evento
        pool shutdown p
```

### 31.3.3. Example 3: Actor Combinators (`agent ask`, `agent try ask`, `agent send batch`, `agent map batch`, `agent drain ready`), Sharded Pools, and Connection Reactor

In this hands-on walkthrough we thoroughly exercise how `pool` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test spec combinators pool and net agent => ()
      test spec combinators pool and net agent =
        w1 = agent (ag double worker)
        agent ask w1 21 -> assert int equals 42 "agent ask 21 -> 42"
        mb = agent map batch w1 [3, 5, 7]
        ag sum ints mb -> assert int equals 30 "agent map batch [3,5,7] -> [6,10,14] sum 30"
        agent send batch w1 [10, 20]
        rc = agent receive count w1 2
        ag sum ints rc -> assert int equals 60 "agent send batch + agent receive count -> 60"
        c_dr = new counter agent 100
        send 5 to c_dr
        send 10 to c_dr
        dr = agent drain ready c_dr
        ag sum ints dr -> assert int equals 220 "agent drain ready [105, 115] -> 220"
        agent stop all [w1, c_dr]
        is agent alive w1 -> assert false "w1 stopped by agent stop all"
        is agent alive c_dr -> assert false "c_dr stopped by agent stop all"

        s0 = new counter agent 0
        s1 = new counter agent 1000
        pl = Pool 2 [s0, s1]
        pool size pl -> assert int equals 2 "pool size 2"
        pool ask shard pl 0 5 -> assert int equals 5 "pool ask shard 0 -> 5"
        pool ask shard pl 1 7 -> assert int equals 1007 "pool ask shard 1 -> 1007"
        pool ask shard pl (0 - 3) 3 -> assert int equals 1010 "pool ask shard negative key -> shard 1"
        pool broadcast pl 10
        all_dr = pool drain all pl
        ag sum ints all_dr -> assert int equals 1035 "pool drain all [15, 1020] -> 1035"
        pool shutdown pl
        is agent alive s0 -> assert false "pool s0 stopped"
        is agent alive s1 -> assert false "pool s1 stopped"

        ca = agent (ag echo conn step) (CounterState 0)
        cb = agent (ag echo conn step) (CounterState 0)
        s_eof = conn feed payload (0 - 1) ca ""
        s_err = conn handle event (0 - 1) cb 8
        kept  = reactor sweep next s_eof (reactor sweep next s_err [])
        agent list len kept 0 -> assert int equals 0 "reactor sweep next prunes closed slots"
        is agent alive ca -> assert false "ca stopped on EOF"
        is agent alive cb -> assert false "cb stopped on POLLERR"
        cc = agent (ag echo conn step) (CounterState 0)
        reactor shutdown [ConnSlot (0 - 1) cc]
        assert false (is agent alive cc) "cc stopped on reactor shutdown"
```

### 31.3.4. Example 4: Agent Lifecycle (`is agent alive`, `agent status`, `stop agent`) and Isolated Stateful Counter Agent (`new counter agent`)

In this hands-on walkthrough we thoroughly exercise how `pool` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test agent lifecycle and counter => ()
      test agent lifecycle and counter =
        format agent status AgentRunning -> assert str eq "running" "format AgentRunning"
        format agent status AgentStopped -> assert str eq "stopped" "format AgentStopped"
        format agent status (AgentTimedOut 250) -> assert str eq "timeout after 250 ms" "format AgentTimedOut"
        format agent status (AgentFailed "boom") -> assert str eq "failed: boom" "format AgentFailed"
        format agent reply (ReplyInt 42) -> assert str eq "42" "format ReplyInt"
        format agent reply (ReplyStr "ok") -> assert str eq "ok" "format ReplyStr"
        format agent reply (ReplyBool True) -> assert str eq "true" "format ReplyBool True"
        format agent reply (ReplyBool False) -> assert str eq "false" "format ReplyBool False"
        format agent reply ReplyEmpty -> assert str eq "agent outbox empty" "format ReplyEmpty"
        format agent reply ReplyStopped -> assert str eq "agent stopped" "format ReplyStopped"
        format agent reply (ReplyTimeout 50) -> assert str eq "agent timeout after 50 ms" "format ReplyTimeout"
        format agent reply (ReplyError "bad") -> assert str eq "agent error: bad" "format ReplyError"

        c   = new counter agent 10
        is agent alive c -> assert ok
        format agent status (agent status c) -> assert str eq "running" "counter running"
        format agent reply (try poll int c) -> assert str eq "agent outbox empty" "empty outbox before send"
        counter get c -> assert eq 10
        counter add c 5 -> assert eq 15
        counter add c 7 -> assert eq 22
        format agent reply (ask int c 8) -> assert str eq "30" "ask int 8 -> 30"
        format agent reply (ask int with timeout c 12 200) -> assert str eq "42" "ask int with timeout -> 42"
        counter reset c -> assert eq 0
        counter get c -> assert eq 0
        bs  = ask batch int c [1, 2, 3, 4]
        ag sum ints bs -> assert eq 20

        c2  = new counter agent 100
        rel = relay int c c2 5
        format agent reply rel -> assert str eq "115" "relay int c (10+5=15) -> c2 (100+15=115)"

        st1 = stop agent c
        format agent status st1 -> assert str eq "stopped" "stop agent returns AgentStopped"
        is agent alive c -> assert eq False
        format agent status (agent status c) -> assert str eq "stopped" "agent status after stop"
        format agent reply (ask int c 1) -> assert str eq "agent stopped" "ask int after stop"
        format agent reply (try poll int c) -> assert str eq "agent stopped" "try poll int after stop"
        format agent reply (ask int with timeout c 1 50) -> assert str eq "agent stopped" "ask int with timeout after stop"
        format agent reply (relay int c c2 1) -> assert str eq "agent stopped" "relay int after stop"
        c0  = new counter agent 0
        counter get c0 -> assert int equals 0 "counter 0 initial"
        counter add c0 3 -> assert int equals 3 "counter 0 add 3"
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
        is agent alive lg -> assert ok
        format agent reply (try poll str lg) -> assert str eq "agent outbox empty" "log empty outbox"
        log read lg -> assert str eq "" "initial log empty"
        log append lg "alpha" -> assert str eq "alpha" "log append alpha"
        log append lg "beta" -> assert str eq "alpha\nbeta" "log append beta"
        format agent reply (ask str with timeout lg "gamma" 200) -> assert str eq "alpha\nbeta\ngamma" "ask str with timeout gamma"
        log read lg -> assert str eq "alpha\nbeta\ngamma" "log read"
        log clear lg -> assert str eq "" "log clear"
        log read lg -> assert str eq "" "log read after clear"
        b   = ask batch str lg ["one", "two"]
        ag join strs b -> assert str eq "one|one\ntwo" "ask batch str"
        lg2 = new log agent ":"
        format agent reply (relay str lg lg2 "three") -> assert str eq "one\ntwo\nthree" "relay str"
        stop agent lg
        stop agent lg2
        format agent reply (ask str lg "x") -> assert str eq "agent stopped" "ask str after stop"

        kv  = new kv agent
        is agent alive kv -> assert ok
        agent kv count kv -> assert int equals 0 "agent kv count 0"
        agent kv has kv "host" -> assert false "agent kv has host false"
        agent kv put kv "host" "127.0.0.1" -> assert str eq "127.0.0.1" "agent kv put host"
        agent kv put kv "port" "8080" -> assert str eq "8080" "agent kv put port"
        agent kv count kv -> assert int equals 2 "agent kv count 2"
        agent kv has kv "host" -> assert ok
        agent kv has kv "port" -> assert ok
        agent kv get kv "host" -> assert str eq "127.0.0.1" "agent kv get host"
        agent kv get kv "port" -> assert str eq "8080" "agent kv get port"
        agent kv keys kv -> assert str eq "host,port" "agent kv keys"
        agent kv put kv "port" "9090" -> assert str eq "9090" "agent kv overwrite port"
        agent kv get kv "port" -> assert str eq "9090" "agent kv get updated port"
        agent kv count kv -> assert int equals 2 "agent kv count after overwrite"
        agent kv delete kv "host" -> assert str eq "127.0.0.1" "agent kv delete host"
        agent kv has kv "host" -> assert false "agent kv has host after delete"
        agent kv count kv -> assert int equals 1 "agent kv count 1"
        agent kv clear kv -> assert str eq "" "agent kv clear"
        agent kv count kv -> assert int equals 0 "agent kv count after clear"
        stop agent kv
        is agent alive kv -> assert false "kv stopped"

        -- RG-066: verify `list kv *` works in the same file that imports `agent`
        lm  = list kv put (list kv empty) "k" "v"
        list kv get lm "k" -> assert str eq "v" "RG-066: list kv get in test agent.ridgun"
        ()
```

### 31.3.6. Example 6: Deterministic Key Sharding (`pool ask shard`), Broadcast (`pool broadcast`), Non-Blocking Drain (`pool drain all`), and Shutdown (`pool shutdown`)

In this hands-on walkthrough we thoroughly exercise how `pool` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
import agent
import pool

fn :: shard worker Int Int => Int Int
      shard worker state delta =
        next = state + delta
        (next, next)

fn :: ejemplo pool completo => Int Int [Int]
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

## 31.4. Under the Hood: How `pool` Is Built in Pure Ridgun (`src/main/ridgun/lib/pool.ridgun`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/pool.ridgun` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 31.4.1. Internal Implementation: Pool Size, Agent Selection, and Request-Reply by Key

Observe how `pool.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
module :: pool

type AgentPool = Pool Int [Agent]

fn :: pool size AgentPool   => Int
      pool size (Pool sz _) =  sz

fn :: pool agents AgentPool    => [Agent]
      pool agents (Pool _ ags) =  ags

-- Look up the i-th agent in a pool (0-indexed)
fn :: pool get agent [Agent]  Int => Agent
      pool get agent (ag:_)   0   =  ag
      pool get agent (_:rest) idx =  pool get agent rest (idx - 1)

fn :: pool abs Int => Int
      pool abs x
        | x < 0     = 0 - x
        | otherwise = x

-- Route a message to a deterministic shard `key_hash % size` and return the reply via `ask`
fn :: pool ask shard AgentPool Int A => B
      pool ask shard (Pool size agents) key_hash msg =
        (pool abs key_hash) % size -> shard_idx
        pool get agent agents shard_idx -> target_ag
        ask target_ag msg
```

### 31.4.2. Internal Implementation: Broadcast, Non-Blocking Drain, and Shutdown

Observe how `pool.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
-- Broadcast a message to every agent in the pool (e.g. configuration reload or tick)
fn :: pool broadcast AgentPool       A   => ()
      pool broadcast (Pool _ agents) msg =  pool broadcast list agents msg

fn :: pool send one Agent A => ()
      pool send one ag    m =
        send m to ag

fn :: pool broadcast list [Agent]   A   => ()
      pool broadcast list []        _   =  ()
      pool broadcast list (ag:rest) msg =
        pool send one ag msg -> ()
        pool broadcast list rest msg

fn :: pool drain ready Agent => [B]
      pool drain ready ag    =  pool drain ready loop ag []

fn :: pool drain ready loop Agent [B] => [B]
      pool drain ready loop ag acc =
        pool drain step ag (try receive from ag) acc

fn :: pool drain step Agent Option [B] => [B]
      pool drain step _ None acc = acc
      pool drain step ag (Some r) acc = pool drain ready loop ag (acc :: [r])

-- Drain all ready responses across all shards in the pool (non-blocking)
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

-- Stop all agents in the pool and reclaim their isolated state
fn :: pool shutdown AgentPool       => ()
      pool shutdown (Pool _ agents) =  pool stop list agents
```

---

## 31.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `pool`

- **Algorithmic & Safety Guarantee**: The number of agents is fixed when the pool is built, so the memory of the pool is bounded, and routing by `abs(key) % size` is deterministic: the same key always reaches the same agent.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/pool.ridgun` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test pool.ridgun`.

### The 5 Golden Rules When Programming with `pool`

1. **Declare `import pool` at the top of your file** and call its functions with spaces, exactly as they are declared, so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `pool` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `pool`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `pool` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 32**, we will explore the **`net_agent`** lib in full depth (The `net_agent` Lib — Socket Connection Actor Supervisor and Non-Blocking Event Bridge).
