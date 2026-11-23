# Chapter 31: The `pool` Lib — A Bounded Pool of Worker Agents, and Routing by Key

## 31.1. Why Does the `pool` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `pool` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `pool`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: spawning a fresh thread or actor for every incoming request with no upper bound guarantees that a traffic spike will drive your server into Out-Of-Memory in seconds.

The **`pool`** lib runs jobs on a fixed number of worker agents, each with its own state (a database session, a counter, nothing): `pool submit` gives a job to an idle worker or refuses it at once when all are busy; `pool done fd` is a descriptor that becomes readable when a job ends, so a server waits on it together with its sockets and never polls; `pool collect` returns each result exactly once; `pool tagged` tells how many workers one client holds; and `pool drain` waits for the jobs in flight and stops the workers. It is the pool Solstice wrote by hand in its HTTP server. The lib also routes a message by key over a list of agents (`pool ask shard`).

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
| `pool start / pool capacity / pool busy / pool idle` | Start a pool of 1 to 64 workers with a worker function and a first state; its size and how many are busy or idle |
| `pool submit / pool refused` | Give a job to an idle worker, or get `-1` at once when all are busy; the number of jobs refused |
| `pool with waiting / pool submit or wait / pool waiting` | Let a job wait when every worker is busy, up to a set number of jobs; it goes to the first worker that ends |
| `pool done fd / pool collect` | A descriptor that is readable when a job ends, and the results of the jobs that ended, each exactly once |
| `pool tagged` | How many busy workers hold a tag, to keep one client from holding them all |
| `pool drain` | Take no more jobs, wait for the ones in flight and stop the workers |
| `pool of / pool size / pool is empty / pool agents` | An `AgentPool` with a fixed number of agents, its size and its agents |
| `pool ask shard / pool ask shard or` | Request-reply with the agent chosen by key: the same key always reaches the same agent |
| `pool broadcast` | Send one message to every agent of the pool |
| `pool drain all / pool drain ready` | Collect the replies that are ready, without blocking |
| `pool shutdown` | Stop every agent of the pool |

### 31.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/pool.ridgun`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/pool.ridgun` (`6` types, `0` operators, and `61` functions):

**Algebraic Data Types & Records (`type`) in `pool`:**

```ridgun
type PoolMsg S J R = PoolMsg (S J => (S, R)) Int Int J
type PoolSlot S J R = ps_agent: (Agent (PoolMsg S J R) R), ps_busy: Bool, ps_index: Int, ps_tag: String
type PoolWait J = PoolWait J String
type WorkerPool S J R = wp_fn: (S J => (S, R)), wp_slots: [(PoolSlot S J R)], wp_done_r: Int, wp_done_w: Int, wp_refused: Int, wp_open: Bool, wp_waiting: [(PoolWait J)], wp_wait_max: Int
type PoolDone R = PoolDone Int String R
type AgentPool = Pool Int [Agent]
```

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: pool run S (PoolMsg S J R)` | `S R` |
| `2` | `fn :: pool new slots S Int Int` | `[PoolSlot S J R]` |
| `3` | `fn :: pool clamp workers Int` | `Int` |
| `4` | `fn :: pool started (S J` | `(S, R)) S Int (Int Int Int) => WorkerPool S J R` |
| `5` | `fn :: pool start Int (S J` | `(S, R)) S => WorkerPool S J R` |
| `6` | `fn :: pool slot count [(PoolSlot S J R)] Int` | `Int` |
| `7` | `fn :: pool busy count [(PoolSlot S J R)] Int` | `Int` |
| `8` | `fn :: pool capacity (WorkerPool S J R)` | `Int` |
| `9` | `fn :: pool busy (WorkerPool S J R)` | `Int` |
| `10` | `fn :: pool idle (WorkerPool S J R)` | `Int` |
| `11` | `fn :: pool refused (WorkerPool S J R)` | `Int` |
| `12` | `fn :: pool done fd (WorkerPool S J R)` | `Int` |
| `13` | `fn :: pool tag count [(PoolSlot S J R)] String Int` | `Int` |
| `14` | `fn :: pool tagged (WorkerPool S J R) String` | `Int` |
| `15` | `fn :: pool first idle [(PoolSlot S J R)]` | `Int` |
| `16` | `fn :: pool hand [(PoolSlot S J R)] (S J` | `(S, R)) Int Int J String => [PoolSlot S J R]` |
| `17` | `fn :: pool handed (PoolSlot S J R) (PoolMsg S J R) String` | `PoolSlot S J R` |
| `18` | `fn :: pool submit to (WorkerPool S J R) J String Int` | `Int (WorkerPool S J R)` |
| `19` | `fn :: pool submit (WorkerPool S J R) J String` | `Int (WorkerPool S J R)` |
| `20` | `fn :: pool wait count [(PoolWait J)] Int` | `Int` |
| `21` | `fn :: pool waiting (WorkerPool S J R)` | `Int` |
| `22` | `fn :: pool with waiting (WorkerPool S J R) Int` | `WorkerPool S J R` |
| `23` | `fn :: pool wait or refuse (WorkerPool S J R) J String` | `Int (WorkerPool S J R)` |
| `24` | `fn :: pool submit or wait to (WorkerPool S J R) J String Int` | `Int (WorkerPool S J R)` |
| `25` | `fn :: pool submit or wait (WorkerPool S J R) J String` | `Int (WorkerPool S J R)` |
| `26` | `fn :: pool second (Int (WorkerPool S J R))` | `WorkerPool S J R` |
| `27` | `fn :: pool feed (WorkerPool S J R)` | `WorkerPool S J R` |
| `28` | `fn :: pool feed from (WorkerPool S J R) [(PoolWait J)] Int` | `WorkerPool S J R` |
| `29` | `fn :: pool is ready PollStatus` | `Bool` |
| `30` | `fn :: pool take [(PoolSlot S J R)] Int [(PoolSlot S J R)] [(PoolDone R)]` | `[PoolSlot S J R] [PoolDone R]` |
| `31` | `fn :: pool take all [(PoolSlot S J R)] String Int [(PoolDone R)]` | `[PoolSlot S J R] [PoolDone R]` |
| `32` | `fn :: pool take next ([(PoolSlot S J R)] [(PoolDone R)]) String Int` | `[PoolSlot S J R] [PoolDone R]` |
| `33` | `fn :: pool collected (WorkerPool S J R) ([(PoolSlot S J R)] [(PoolDone R)])` | `[PoolDone R] (WorkerPool S J R)` |
| `34` | `fn :: pool collect (WorkerPool S J R) Int` | `[PoolDone R] (WorkerPool S J R)` |
| `35` | `fn :: pool stop slots [(PoolSlot S J R)]` | `()` |
| `36` | `fn :: pool closed (WorkerPool S J R) [(PoolDone R)]` | `[PoolDone R] (WorkerPool S J R)` |
| `37` | `fn :: pool drain until (WorkerPool S J R) Int [(PoolDone R)]` | `[PoolDone R] (WorkerPool S J R)` |
| `38` | `fn :: pool drain more ([(PoolDone R)] (WorkerPool S J R)) Int [(PoolDone R)]` | `[PoolDone R] (WorkerPool S J R)` |
| `39` | `fn :: pool drain (WorkerPool S J R) Int` | `[PoolDone R] (WorkerPool S J R)` |
| `40` | `fn :: pool count [Agent] Int` | `Int` |
| `41` | `fn :: pool of [Agent]` | `AgentPool` |
| `42` | `fn :: pool size AgentPool` | `Int` |
| `43` | `fn :: pool is empty AgentPool` | `Bool` |
| `44` | `fn :: pool agents AgentPool` | `[Agent]` |
| `45` | `fn :: pool get agent [Agent] Int` | `Agent` |
| `46` | `fn :: pool abs Int` | `Int` |
| `47` | `fn :: pool ask shard AgentPool Int A` | `B` |
| `48` | `fn :: pool ask at [Agent] Int Int A` | `B` |
| `49` | `fn :: pool stop empty A` | `B` |
| `50` | `fn :: pool ask shard or AgentPool Int A B` | `B` |
| `51` | `fn :: pool ask at or [Agent] Int Int A B` | `B` |
| `52` | `fn :: pool broadcast AgentPool A` | `()` |
| `53` | `fn :: pool send one Agent A` | `()` |
| `54` | `fn :: pool broadcast list [Agent] A` | `()` |
| `55` | `fn :: pool drain ready Agent` | `[B]` |
| `56` | `fn :: pool drain ready loop Agent [B]` | `[B]` |
| `57` | `fn :: pool drain step Agent Option [B]` | `[B]` |
| `58` | `fn :: pool drain all AgentPool` | `[B]` |
| `59` | `fn :: pool drain list [Agent] [B]` | `[B]` |
| `60` | `fn :: pool stop list [Agent]` | `()` |
| `61` | `fn :: pool shutdown AgentPool` | `()` |

---

## 31.3. Deep Dive into `pool`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `pool` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test pool.ridgun`.

### 31.3.1. Example 1: Core Tabular Workflow with `pool`

Notice how in Ridgun the `=` signs and transformation steps using `pool` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import pool

fn :: doblar Int Int => Int Int
      doblar hechos n =  (hechos + 1, n * 2)

fn :: enviar y recoger => Int
      enviar y recoger =
        p0          = pool start 4 (doblar) 0
        quien, p1   = pool submit p0 21 "cliente-a"
        hechos, p2  = pool collect p1 1000
        resto, p3   = pool drain p2 1000
        pool refused p3
```

### 31.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `pool` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 38 libs in `ridgun-libs`:

```ridgun
import pool

fn :: entregado (Int (WorkerPool Int Int Int)) => String (WorkerPool Int Int Int)
      entregado (k, p) =  ("trabajador {k}", p)

fn :: aceptar o rechazar (WorkerPool Int Int Int) Int String => String (WorkerPool Int Int Int)
      aceptar o rechazar p trabajo cliente =
        | (pool tagged p cliente) >= 2 = ("demasiadas peticiones de " + cliente, p)
        | (pool idle p) == 0           = ("ocupado", p)
        | otherwise                    = entregado (pool submit p trabajo cliente)
```

### 31.3.3. Example 3: Deterministic Key Sharding (`pool ask shard`), Broadcast (`pool broadcast`), Non-Blocking Drain (`pool drain all`), and Shutdown (`pool shutdown`)

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

### 31.3.4. Example 4: Routing by Key (`pool ask shard`): Same Key, Same Agent; Keys in Turn, Agents in Turn; Broadcast and Shutdown

In this hands-on walkthrough we thoroughly exercise how `pool` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test pool routing by key => ()
      test pool routing by key =
        a0 = new counter agent 0
        a1 = new counter agent 1000
        a2 = new counter agent 2000
        pl = Pool 3 [a0, a1, a2]
        pool size pl -> assert int equals 3 "pool size 3"
        agent list len (pool agents pl) 0 -> assert int equals 3 "pool agents holds the 3 agents"
        pool ask shard pl 0 1 -> assert int equals 1 "key 0 -> agent 0"
        pool ask shard pl 1 1 -> assert int equals 1001 "key 1 -> agent 1"
        pool ask shard pl 2 1 -> assert int equals 2001 "key 2 -> agent 2"
        pool ask shard pl 3 1 -> assert int equals 2 "key 3 -> agent 0 again: keys in turn visit the agents in turn"
        pool ask shard pl 7 1 -> assert int equals 1002 "key 7 -> agent 1"
        pool ask shard pl 7 1 -> assert int equals 1003 "the same key always reaches the same agent"
        pool ask shard pl (0 - 2) 1 -> assert int equals 2002 "negative key -> agent abs(key) % size"
        agent list len (pool drain all pl) 0 -> assert int equals 0 "pool drain all with nothing ready -> []"
        pool broadcast pl 100
        counter get a0 -> assert int equals 102 "broadcast reached agent 0"
        counter get a1 -> assert int equals 1103 "broadcast reached agent 1"
        counter get a2 -> assert int equals 2102 "broadcast reached agent 2"
        one = Pool 1 [new counter agent 5]
        pool ask shard one 12345 1 -> assert int equals 6 "a pool of one agent takes every key"
        pool shutdown one
        pool shutdown pl
        is agent alive a0 -> assert false "pool shutdown stops agent 0"
        is agent alive a2 -> assert false "pool shutdown stops agent 2"
```

### 31.3.5. Example 5: Jobs Go to Idle Workers, a Full Pool Refuses at Once, and Results Are Collected without Polling

In this hands-on walkthrough we thoroughly exercise how `pool` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test pool takes jobs and refuses when full => ()
      test pool takes jobs and refuses when full =
        p0 = pool start 3 (tw work) 0
        pool capacity p0 -> assert int equals 3 "a pool of 3 workers"
        pool busy p0 -> assert int equals 0 "no worker is busy at the start"
        pool idle p0 -> assert int equals 3 "the three are idle"
        (pool done fd p0) >= 0 -> assert true "the pool has a descriptor to wait on"
        k1, p1 = pool submit p0 300 "a"
        k2, p2 = pool submit p1 300 "a"
        k3, p3 = pool submit p2 300 "b"
        k1 -> assert int equals 0 "the first job goes to worker 0"
        k2 -> assert int equals 1 "the second to worker 1"
        k3 -> assert int equals 2 "the third to worker 2"
        pool busy p3 -> assert int equals 3 "the three workers are busy"
        t0 = sys monotonic ms
        k4, p4 = pool submit p3 300 "c"
        k4 -> assert int equals (0 - 1) "a fourth job is refused"
        ((sys monotonic ms) - t0) < 100 -> assert true "and refused at once, without waiting"
        pool refused p4 -> assert int equals 1 "the pool counts the refused job"
        pool tagged p4 "a" -> assert int equals 2 "two busy workers hold the tag a"
        pool tagged p4 "b" -> assert int equals 1 "one holds the tag b"
        pool tagged p4 "c" -> assert int equals 0 "none holds the tag of the refused job"

        t1 = sys monotonic ms
        none, p5 = pool collect p4 0
        pd count none 0 -> assert int equals 0 "collect without waiting: nothing has ended"
        ((sys monotonic ms) - t1) < 100 -> assert true "and it returns at once"
        t2 = sys monotonic ms
        none2, p6 = pool collect p5 50
        pd count none2 0 -> assert int equals 0 "collect with 50 ms: still nothing"
        ((sys monotonic ms) - t2) >= 40 -> assert true "after waiting about 50 ms"

        is ready (wait fd (pool done fd p6) (poll in) 2000) -> assert true "the pool's descriptor is readable when a job ends"
        got, p7 = collect all p6 3 10 []
        pd count got 0 -> assert int equals 3 "the three results are collected"
        pd slots sum got 0 -> assert int equals 3 "one from each worker: 0 + 1 + 2"
        pd results sum got 0 -> assert int equals 900000 "each result is its own job on a fresh state"
        pd tagged got "a" 0 -> assert int equals 2 "two results carry the tag a"
        pd tagged got "b" 0 -> assert int equals 1 "one carries the tag b"
        pool busy p7 -> assert int equals 0 "every worker is idle again"
        pool tagged p7 "a" -> assert int equals 0 "and no tag is held"
        late, p8 = pool collect p7 0
        pd count late 0 -> assert int equals 0 "a result is never returned twice"

        -- AC6 and AC1: jobs that end in another order keep their own results, and a worker keeps its state
        ka, p9  = pool submit p8 200 "slow"
        kb, p10 = pool submit p9 20 "fast"
        ka -> assert int equals 0 "the slow job goes to worker 0"
        kb -> assert int equals 1 "the fast job to worker 1"
        first, p11 = collect all p10 1 10 []
        pd tag (pd first first) -> assert str eq "fast" "the fast job ends first"
        pd slot (pd first first) -> assert int equals 1 "and comes from worker 1"
        pd result (pd first first) -> assert int equals 20001 "with its own result; worker 1 had done one job before"
        second, p12 = collect all p11 1 10 []
        pd tag (pd first second) -> assert str eq "slow" "the slow job ends later"
        pd result (pd first second) -> assert int equals 200001 "with its own result; worker 0 had done one job before"

        -- AC7: drain
        kx, p13 = pool submit p12 100 "x"
        ky, p14 = pool submit p13 100 "y"
        drained, p15 = pool drain p14 2000
        pd count drained 0 -> assert int equals 2 "drain returns the results of the two jobs in flight"
        pd results sum drained 0 -> assert int equals 200004 "workers 0 and 1 had done two jobs each: 100002 + 100002"
        pool busy p15 -> assert int equals 0 "nothing runs after the drain"
        kz, p16 = pool submit p15 10 "z"
        kz -> assert int equals (0 - 1) "a drained pool takes no more jobs"
        pool done fd p16 -> assert int equals (0 - 1) "and its descriptor is closed"
        ()
```

### 31.3.6. Example 6: From 1 to 64 Workers

In this hands-on walkthrough we thoroughly exercise how `pool` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test pool size limits => ()
      test pool size limits =
        one = pool start 0 (tw work) 0
        pool capacity one -> assert int equals 1 "fewer than 1 worker gives 1"
        _, o2 = pool drain one 100
        many = pool start 100 (tw work) 0
        pool capacity many -> assert int equals 64 "more than 64 workers gives 64"
        _, m2 = pool drain many 100
        pool capacity m2 -> assert int equals 0 "a drained pool has no workers"
        ()
```

### 31.3.7. Example 7: Routing by Key on an Empty List, and the Real Size of a List

In this hands-on walkthrough we thoroughly exercise how `pool` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test pool routing edge cases => ()
      test pool routing edge cases =
        none = pool of []
        pool is empty none -> assert true "a list with no agents is empty"
        pool size none -> assert int equals 0 "and its size is 0"
        pool ask shard or none 3 1 (0 - 1) -> assert int equals (0 - 1) "pool ask shard or gives its default when there is nobody to ask"
        a = new counter agent 0
        b = new counter agent 1000
        two = Pool 5 [a, b]
        pool size two -> assert int equals 2 "the size is the number of agents, whatever number was written"
        pool ask shard two 3 1 -> assert int equals 1001 "key 3 over two agents reaches agent 1"
        pool ask shard or two 4 1 (0 - 1) -> assert int equals 1 "key 4 reaches agent 0, also with a default"
        pool is empty two -> assert false "a list with agents is not empty"
        pool shutdown two
        ()
```

### 31.3.8. Example 8: Jobs That Wait for a Worker, up to a Set Number, and Run in the Order They Came

In this hands-on walkthrough we thoroughly exercise how `pool` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
fn :: test pool jobs that wait for a worker => ()
      test pool jobs that wait for a worker =
        n0 = pool start 1 (tw work) 0
        pool waiting n0 -> assert int equals 0 "a new pool has no job waiting"
        ka, n1 = pool submit or wait n0 100 ""
        kb, n2 = pool submit or wait n1 100 ""
        ka -> assert int equals 0 "with an idle worker the job goes to it"
        kb -> assert int equals (0 - 1) "a pool as it starts lets no job wait: the second is refused"
        pool refused n2 -> assert int equals 1 "and counted"
        dn, n3 = pool drain n2 2000
        pd count dn 0 -> assert int equals 1 "the one job ran"
        pool waiting (pool with waiting n0 (0 - 5)) -> assert int equals 0 "room under 0 is no room"

        p0 = pool with waiting (pool start 2 (tw work) 0) 2
        k1, p1 = pool submit or wait p0 100 "a"
        k2, p2 = pool submit or wait p1 110 "a"
        t0 = sys monotonic ms
        k3, p3 = pool submit or wait p2 120 "b"
        k4, p4 = pool submit or wait p3 130 "b"
        k5, p5 = pool submit or wait p4 140 "c"
        ((sys monotonic ms) - t0) < 100 -> assert true "waiting or refusing takes no time: the call never waits"
        k1 -> assert int equals 0 "the first job goes to worker 0"
        k2 -> assert int equals 1 "the second to worker 1"
        k3 -> assert int equals (0 - 2) "every worker is busy: the third waits"
        k4 -> assert int equals (0 - 2) "and the fourth"
        k5 -> assert int equals (0 - 1) "there is room for two: the fifth is refused"
        pool waiting p5 -> assert int equals 2 "two jobs wait"
        pool busy p5 -> assert int equals 2 "two run"
        pool refused p5 -> assert int equals 1 "one was refused"
        pool tagged p5 "b" -> assert int equals 0 "a job that waits holds no worker"
        k6, p6 = pool submit p5 150 "d"
        k6 -> assert int equals (0 - 1) "pool submit never lets a job wait"
        pool waiting p6 -> assert int equals 2 "and the two that wait are still there"
        got, p7 = collect all p6 4 40 []
        pd count got 0 -> assert int equals 4 "the two that ran and the two that waited all end"
        pd ms sum got 0 -> assert int equals 460 "each of the four ran once: 100 + 110 + 120 + 130"
        pd tagged got "b" 0 -> assert int equals 2 "the jobs that waited keep their tag"
        pool waiting p7 -> assert int equals 0 "nothing waits any more"
        pool busy p7 -> assert int equals 0 "and nothing runs"
        k7, p8 = pool submit or wait p7 20 ""
        k7 >= 0 -> assert true "with idle workers again a job goes straight to one"
        d7, p9 = pool drain p8 2000
        pd count d7 0 -> assert int equals 1 "it ends"

        -- the order: with one worker the jobs that wait run in the order they came
        o0 = pool with waiting (pool start 1 (tw work) 0) 3
        j1, o1 = pool submit or wait o0 30 "first"
        j2, o2 = pool submit or wait o1 30 "second"
        j3, o3 = pool submit or wait o2 30 "third"
        j4, o4 = pool submit or wait o3 30 "fourth"
        od, o5 = pool drain o4 3000
        pd count od 0 -> assert int equals 4 "a drain waits for the jobs that wait too"
        pd results sum od 0 -> assert int equals 120006 "the worker did them one after another: 30000 x 4 + 0 + 1 + 2 + 3"
        pd tagged od "fourth" 0 -> assert int equals 1 "the last one ran"
        pool waiting o5 -> assert int equals 0 "nothing waits in a drained pool"
        j5, o6 = pool submit or wait o5 10 ""
        j5 -> assert int equals (0 - 1) "a drained pool refuses, it does not let a job wait"

        -- a drain that runs out of time does not run the jobs that still wait
        s0 = pool with waiting (pool start 1 (tw work) 0) 3
        x1, s1 = pool submit or wait s0 300 ""
        x2, s2 = pool submit or wait s1 300 ""
        x3, s3 = pool submit or wait s2 300 ""
        t1 = sys monotonic ms
        sd, s4 = pool drain s3 100
        ((sys monotonic ms) - t1) < 1500 -> assert true "the drain ends at its time limit"
        (pd count sd 0) < 3 -> assert true "and the jobs that still waited were not run"
        pool waiting s4 -> assert int equals 0 "they wait no more"
```

---

## 31.4. Under the Hood: How `pool` Is Built in Pure Ridgun (`src/main/ridgun/lib/pool.ridgun`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/pool.ridgun` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 31.4.1. Internal Implementation: Worker pool (FR-POOL-001 AC1 to AC7)

Observe how `pool.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
module :: pool

-- A fixed number of worker agents, each with its own state. A job goes to an idle worker or is refused.
-- When a worker ends a job it writes its number to a pipe, so the caller waits on a descriptor and never polls.

-- What a worker gets: the function to run, its own number, the write end of the pipe and the job.
-- Inside a `type` the pair of the result is written `(S, R)` (ridgunc 1.0.51 does not read `S R` there).
type PoolMsg S J R = PoolMsg (S J => (S, R)) Int Int J

-- One worker: its agent, whether it runs a job, its number and the tag of that job.
type PoolSlot S J R = ps_agent: (Agent (PoolMsg S J R) R), ps_busy: Bool, ps_index: Int, ps_tag: String

-- A job that waits for a worker, with its tag.
type PoolWait J = PoolWait J String

-- wp_done_r / wp_done_w: the pipe the workers report on. wp_open: False once the pool is drained.
-- wp_waiting: the jobs that wait for a worker, in the order they came. wp_wait_max: how many may wait (0: none).
type WorkerPool S J R = wp_fn: (S J => (S, R)), wp_slots: [(PoolSlot S J R)], wp_done_r: Int, wp_done_w: Int, wp_refused: Int, wp_open: Bool, wp_waiting: [(PoolWait J)], wp_wait_max: Int

-- A job that ended: the worker that ran it, its tag and its result.
type PoolDone R = PoolDone Int String R

-- The worker: runs the job on its state, tells the pool it has ended, and answers the result.
-- The number written is the worker's number plus 1, so it is never the byte 0.
fn :: pool run S (PoolMsg S J R) => S R
      pool run st (PoolMsg f slot done job) =
        st2, r = f st job
        posix write done (char from code (slot + 1)) -> ()
        (st2, r)

fn :: pool new slots S Int Int => [PoolSlot S J R]
      pool new slots s0 i n =
        | i >= n    = []
        | otherwise = [PoolSlot (agent (pool run) s0) False i ""] :: (pool new slots s0 (i + 1) n)

fn :: pool clamp workers Int => Int
      pool clamp workers n =
        | n < 1     = 1
        | n > 64    = 64
        | otherwise = n

fn :: pool started (S J => (S, R)) S Int (Int Int Int) => WorkerPool S J R
      pool started f s0 n (rc, r, w) =
        | rc != 0   = WorkerPool f [] (0 - 1) (0 - 1) 0 False [] 0
        | otherwise = WorkerPool f (pool new slots s0 0 n) r w 0 True [] 0

-- A pool of `n` workers (1 to 64) that run `f`, each starting from the state `s0`.
fn :: pool start Int (S J => (S, R)) S => WorkerPool S J R
      pool start n f s0 =  pool started f s0 (pool clamp workers n) posix pipe

fn :: pool slot count [(PoolSlot S J R)] Int => Int
      pool slot count []       n =  n
      pool slot count (_:rest) n =  pool slot count rest (n + 1)

fn :: pool busy count [(PoolSlot S J R)] Int => Int
      pool busy count []       n =  n
      pool busy count (s:rest) n =
        | ps_busy s = pool busy count rest (n + 1)
        | otherwise = pool busy count rest n

fn :: pool capacity (WorkerPool S J R) => Int
      pool capacity p =  pool slot count (wp_slots p) 0

fn :: pool busy (WorkerPool S J R) => Int
      pool busy p =  pool busy count (wp_slots p) 0

fn :: pool idle (WorkerPool S J R) => Int
      pool idle p =  (pool capacity p) - (pool busy p)

fn :: pool refused (WorkerPool S J R) => Int
      pool refused p =  wp_refused p

-- The descriptor that is readable when a job has ended (-1 when the pool could not start).
fn :: pool done fd (WorkerPool S J R) => Int
      pool done fd p =  wp_done_r p

fn :: pool tag count [(PoolSlot S J R)] String Int => Int
      pool tag count []       _   n =  n
      pool tag count (s:rest) tag n =
        | (ps_busy s) and (ps_tag s) == tag = pool tag count rest tag (n + 1)
        | otherwise                         = pool tag count rest tag n

-- Busy workers whose job was submitted with `tag`.
fn :: pool tagged (WorkerPool S J R) String => Int
      pool tagged p tag =  pool tag count (wp_slots p) tag 0

-- The number of the first idle worker, or -1.
fn :: pool first idle [(PoolSlot S J R)] => Int
      pool first idle []       =  0 - 1
      pool first idle (s:rest) =
        | ps_busy s = pool first idle rest
        | otherwise = ps_index s

-- Hands the job to worker `k` and marks it busy with the tag.
fn :: pool hand [(PoolSlot S J R)] (S J => (S, R)) Int Int J String => [PoolSlot S J R]
      pool hand []       _ _ _ _   _   =  []
      pool hand (s:rest) f w k job tag =
        | (ps_index s) == k = [pool handed s (PoolMsg f k w job) tag] :: rest
        | otherwise         = [s] :: (pool hand rest f w k job tag)

fn :: pool handed (PoolSlot S J R) (PoolMsg S J R) String => PoolSlot S J R
      pool handed s m tag =
        send m to (ps_agent s)
        s with ps_busy = True, ps_tag = tag

fn :: pool submit to (WorkerPool S J R) J String Int => Int (WorkerPool S J R)
      pool submit to p job tag k =
        | k < 0     = (0 - 1, p with wp_refused = ((wp_refused p) + 1))
        | otherwise = (k, p with wp_slots = (pool hand (wp_slots p) (wp_fn p) (wp_done_w p) k job tag))

-- Gives the job to an idle worker: the answer is the number of that worker, or -1 when every worker
-- is busy or the pool was drained, and the pool to use from now on. It never waits.
fn :: pool submit (WorkerPool S J R) J String => Int (WorkerPool S J R)
      pool submit p job tag =
        | not (wp_open p) = (0 - 1, p with wp_refused = ((wp_refused p) + 1))
        | otherwise       = pool submit to p job tag (pool first idle (wp_slots p))
```

### 31.4.2. Internal Implementation: Routing by key over a list of agents (FR-POOL-001 AC8)

Observe how `pool.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
type AgentPool = Pool Int [Agent]

fn :: pool count [Agent]  Int => Int
      pool count []       n   =  n
      pool count (_:rest) n   =  pool count rest (n + 1)

-- A pool of the agents of a list.
fn :: pool of [Agent] => AgentPool
      pool of ags     =  Pool (pool count ags 0) ags

-- The number of agents the pool holds (the list decides, not the number written in `Pool n agents`).
fn :: pool size AgentPool    => Int
      pool size (Pool _ ags) =  pool count ags 0

fn :: pool is empty AgentPool => Bool
      pool is empty pl        =  (pool size pl) == 0

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

-- Routes a message to agent `abs(key) % n`, n being the number of agents of the pool, and returns its reply.
-- A pool with no agents has nobody to ask: the program stops with a message. `pool ask shard or` does not stop.
fn :: pool ask shard AgentPool Int A => B
      pool ask shard (Pool _ agents) key_hash msg =
        pool ask at agents (pool count agents 0) key_hash msg

fn :: pool ask at [Agent] Int Int A => B
      pool ask at agents n key_hash msg =
        | n <= 0    = pool stop empty msg
        | otherwise = ask (pool get agent agents ((pool abs key_hash) % n)) msg

fn :: pool stop empty A => B
      pool stop empty msg =
        echo "pool ask shard: the pool has no agents"
        sys exit 1
        pool stop empty msg

-- The same, or `default` when the pool has no agents.
fn :: pool ask shard or AgentPool Int A B => B
      pool ask shard or (Pool _ agents) key_hash msg default =
        pool ask at or agents (pool count agents 0) key_hash msg default

fn :: pool ask at or [Agent] Int Int A B => B
      pool ask at or agents n key_hash msg default =
        | n <= 0    = default
        | otherwise = ask (pool get agent agents ((pool abs key_hash) % n)) msg

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

- **Algorithmic & Safety Guarantee**: At most `worker_count` jobs run at once (1 to 64) and nothing is queued, so the memory of the pool is bounded; every result is returned exactly once and with its own job, and only the thread of the caller talks to the workers.
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

In **Chapter 32**, we will explore the **`net_agent`** lib in full depth (The `net_agent` Lib — Many Connections in One Loop That Waits for None).
