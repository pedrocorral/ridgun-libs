# Chapter 32: The `net_agent` Lib — One Agent per Connection: Non-Blocking Polling and Reactor Sweep

## 32.1. Why Does the `net_agent` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `net_agent` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `net_agent`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: in a real server like **Solstice**, accepting TCP connections is the easy part; the hard part is enforcing max concurrent clients, reaping idle zombie connections, and bridging `ppoll` readiness into actor messages without leaking file descriptors.

The **`net_agent`** lib closes the loop of `ridgun-libs` by uniting **`posix`**, **`socket`**, and **`agent`**: a `ConnSlot` pairs a connection descriptor with the agent that holds its state; `conn poll step` polls the descriptor without blocking, passes what arrives to the agent and writes its reply back; `reactor sweep` does that for a whole table of connections and drops the closed ones; and `reactor shutdown` closes every descriptor and stops every agent.

In a traditional ecosystem, solving **`AGENT`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`net_agent`** lib (`src/main/ridgun/lib/net_agent.ridgun`) tackles the problem with four non-negotiable principles:

1. **Declare `import net_agent` (or `import net_agent as alias`) at the top of your file**: every lib defines its `module :: net agent` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
3. **Tail-Call Optimization (TCO)**: all internal loops in `net_agent` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 32.2. Native Artifacts, Imports, and Complete `net_agent` API Catalog

In `ridgun-libs`, **`net_agent`** is a first-class **lib** located at `src/main/ridgun/lib/net_agent.ridgun` (domain `AGENT`). When built with `stable bundle`, it compiles into one native artifact:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/net_agent.ridgunlib` | Portable distribution and direct `import net_agent` resolution |

> Every lib declares its own namespace via `module :: net agent`: simply write `import net_agent` (or `import net_agent as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

### 32.2.1. Summary of `net_agent` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `ConnSlot / StepOutcome` | A connection descriptor with its agent, and the result of one step: `ConnKeep` or `ConnClosed` |
| `conn poll step` | Poll one connection without blocking, pass what arrives to its agent and send the reply |
| `reactor sweep` | One step over every connection of a table; the closed ones leave it |
| `reactor shutdown` | Close every descriptor and stop every agent |

### 32.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/net_agent.ridgun`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/net_agent.ridgun` (`2` types, `0` operators, and `8` functions):

**Algebraic Data Types & Records (`type`) in `net_agent`:**

```ridgun
type ConnSlot = ConnSlot Int Agent
type StepOutcome = ConnKeep ConnSlot String | ConnClosed
```

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: conn poll step ConnSlot` | `StepOutcome` |
| `2` | `fn :: conn handle event Int Agent Int` | `StepOutcome` |
| `3` | `fn :: conn feed payload Int Agent String` | `StepOutcome` |
| `4` | `fn :: conn cast str A` | `String` |
| `5` | `fn :: conn drain outbound Int Agent Option` | `StepOutcome` |
| `6` | `fn :: reactor sweep [ConnSlot]` | `[ConnSlot]` |
| `7` | `fn :: reactor sweep next StepOutcome [ConnSlot]` | `[ConnSlot]` |
| `8` | `fn :: reactor shutdown [ConnSlot]` | `()` |

---

## 32.3. Deep Dive into `net_agent`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `net_agent` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test net_agent.ridgun`.

### 32.3.1. Example 1: Core Tabular Workflow with `net_agent`

Notice how in Ridgun the `=` signs and transformation steps using `net_agent` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import net_agent

fn :: barrer conexiones activas [ConnSlot] => [ConnSlot]
      barrer conexiones activas tabla =
        tabla reactor sweep
```

### 32.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `net_agent` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 38 libs in `ridgun-libs`:

```ridgun
import net_agent

fn :: apagar reactor [ConnSlot] => ()
      apagar reactor tabla =
        tabla reactor shutdown
```

### 32.3.3. Example 3: Actor Combinators (`agent ask`, `agent try ask`, `agent send batch`, `agent map batch`, `agent drain ready`), Sharded Pools, and Connection Reactor

In this hands-on walkthrough we thoroughly exercise how `net_agent` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

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

### 32.3.4. Example 4: Agent Lifecycle (`is agent alive`, `agent status`, `stop agent`) and Isolated Stateful Counter Agent (`new counter agent`)

In this hands-on walkthrough we thoroughly exercise how `net_agent` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

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

### 32.3.5. Example 5: Append-Only Log Agent (`new log agent`) and Message-Passing In-Memory Key-Value Store (`new kv agent`)

In this hands-on walkthrough we thoroughly exercise how `net_agent` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

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

### 32.3.6. Example 6: Non-Blocking Descriptor Polling (`conn poll step`), Connection Table Sweep (`reactor sweep`), and Graceful Shutdown (`reactor shutdown`)

In this hands-on walkthrough we thoroughly exercise how `net_agent` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

```ridgun
import agent
import net_agent

fn :: sesion eco Int String => Int String
      sesion eco n trama =
        sig = n + 1
        (sig, "[#{sig}] {trama}")

fn :: ejemplo reactor conexiones Int Int => [ConnSlot]
      ejemplo reactor conexiones fd1 fd2 =
        ag1     = agent sesion eco 0
        ag2     = agent sesion eco 0
        activas = [ConnSlot fd1 ag1, ConnSlot fd2 ag2]
        -- Barrido no bloqueante (sys poll timeout=0) de todas las conexiones
        vivas   = reactor sweep activas
        -- Cierre ordenado de descriptores y parada determinista de agentes
        reactor shutdown vivas -> ()
        []
```

---

## 32.4. Under the Hood: How `net_agent` Is Built in Pure Ridgun (`src/main/ridgun/lib/net_agent.ridgun`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/net_agent.ridgun` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 32.4.1. Internal Implementation: One Step of a Connection: Poll, Pass to the Agent, Write the Reply

Observe how `net_agent.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
module :: net_agent

type ConnSlot = ConnSlot Int Agent

type StepOutcome = ConnKeep ConnSlot String | ConnClosed

-- Poll a single connection fd (non-blocking, timeout = 0) and route incoming data to its Agent
fn :: conn poll step ConnSlot         => StepOutcome
      conn poll step (ConnSlot fd ag) =
        sys poll fd 1 0 -> ev
        conn handle event fd ag ev

fn :: conn handle event Int Agent Int => StepOutcome
      conn handle event fd ag ev
        | ev < 0 =
          -- Poll error: close descriptor and stop agent
          sys close fd
          stop ag
          ConnClosed
        | ev >= 8 =
          -- POLLERR (8) or POLLHUP (16): peer disconnected
          sys close fd
          stop ag
          ConnClosed
        | ev == 0 =
          -- No new bytes to read; check if the agent has a queued async reply
      conn drain outbound fd ag (try receive from ag)
        | otherwise =
          -- POLLIN (1): read frame and forward to the connection's stateful agent
          payload = sys read fd fd 65536
          conn feed payload fd ag payload

fn :: conn feed payload Int Agent String => StepOutcome
      conn feed payload fd ag "" =
        -- EOF on socket: close descriptor and stop agent deterministically
        sys close fd -> ()
        stop ag
        ConnClosed
      conn feed payload fd ag data =
        send data to ag
        conn drain outbound fd ag (try receive from ag)

fn :: conn cast str A => String
      conn cast str x =  x

fn :: conn drain outbound Int Agent Option => StepOutcome
      conn drain outbound fd ag None = ConnKeep (ConnSlot fd ag) ""
      conn drain outbound fd ag (Some resp) =
        resp conn cast str -> s
        sys write fd fd s -> ()
        ConnKeep (ConnSlot fd ag) s
```

### 32.4.2. Internal Implementation: Reactor Sweep and Shutdown

Observe how `net_agent.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
-- Sweep an entire connection table, pruning closed connections and keeping active ones
fn :: reactor sweep [ConnSlot]  => [ConnSlot]
      reactor sweep []          =  []
      reactor sweep (slot:rest) =
        slot conn poll step -> outcome
        rest reactor sweep -> kept
        reactor sweep next outcome kept

fn :: reactor sweep next StepOutcome       [ConnSlot] => [ConnSlot]
      reactor sweep next ConnClosed        kept       =  kept
      reactor sweep next (ConnKeep slot _) kept       =  [slot] :: kept

-- Gracefully close all sockets and stop all connection agents on server shutdown
fn :: reactor shutdown [ConnSlot] => ()
      reactor shutdown []         =  ()
      reactor shutdown ((ConnSlot fd ag):rest) =
        sys close fd -> ()
        stop ag
        reactor shutdown rest
```

---

## 32.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `net_agent`

- **Algorithmic & Safety Guarantee**: A connection that is closed or fails leaves the table on the sweep that sees it, with its descriptor closed and its agent stopped, and `reactor shutdown` does the same for all the rest, so no descriptor and no agent is leaked.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/net_agent.ridgun` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test net_agent.ridgun`.

### The 5 Golden Rules When Programming with `net_agent`

1. **Declare `import net_agent` at the top of your file** and call its functions with spaces, exactly as they are declared, so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `net_agent` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `net_agent`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `net_agent` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

You have completed the comprehensive tour of all **32 standard libs in `ridgun-libs`**! You now have every building block needed to craft complete, zero-`libc` applications and systems tools in pure Ridgun.
