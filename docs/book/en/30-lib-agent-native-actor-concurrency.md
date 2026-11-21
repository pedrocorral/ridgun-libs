# Chapter 30: The `agent` Lib — Native Actor Concurrency (`agent`, `send`, `receive`), Request-Reply Combinators, and Counter, Log and Key-Value Agents

## 30.1. Why Does the `agent` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `agent` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `agent`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: sharing mutable state across threads with `Mutex`, `RwLock`, and condition variables is an endless factory of deadlocks and race conditions.

The **`agent`** lib builds on Ridgun's **Native Agent Model** (`agent`, `send ... to`, `receive from`, `try receive from`, `stop`) to provide request-reply combinators, blocking, non-blocking or bounded by a timeout (`agent ask`, `agent try ask`, `ask int with timeout`), batch dispatch and draining (`agent send batch`, `agent map batch`, `agent drain ready`), lifecycle inspection (`is agent alive`, `agent status`, `stop agent`), and three ready-made stateful agents: a counter, an append-only log and an in-memory key-value store.

In a traditional ecosystem, solving **`AGENT`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`agent`** lib (`src/main/ridgun/lib/agent.ridgun`) tackles the problem with four non-negotiable principles:

1. **Declare `import agent` (or `import agent as alias`) at the top of your file**: every lib defines its `module :: agent` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
3. **Tail-Call Optimization (TCO)**: all internal loops in `agent` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 30.2. Native Artifacts, Imports, and Complete `agent` API Catalog

In `ridgun-libs`, **`agent`** is a first-class **lib** located at `src/main/ridgun/lib/agent.ridgun` (domain `AGENT`). When built with `stable bundle`, it compiles into one native artifact:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/agent.ridgunlib` | Portable distribution and direct `import agent` resolution |

> Every lib declares its own namespace via `module :: agent`: simply write `import agent` (or `import agent as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

### 30.2.1. Summary of `agent` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `agent ask / agent try ask / ask int / ask str / ask int with timeout / ask str with timeout` | Request-reply with an agent: blocking, non-blocking or bounded by a timeout |
| `agent send batch / agent map batch / agent receive count / agent drain ready / relay int / relay str` | Send a batch of messages, collect the replies and relay a result from one agent to another |
| `is agent alive / agent status / stop agent / agent stop all` | Lifecycle inspection and orderly stop, with a typed `AgentStatus` |
| `new counter agent / counter add / counter get / counter reset` | A counter kept inside an agent |
| `new log agent / log append / log read / log clear` | An append-only log kept inside an agent |
| `new kv agent / agent kv put / agent kv get / agent kv delete / agent kv has / agent kv count / agent kv keys / agent kv clear` | An in-memory key-value store kept inside an agent |

### 30.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/agent.ridgun`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/agent.ridgun` (`7` types, `0` operators, and `65` functions):

**Algebraic Data Types & Records (`type`) in `agent`:**

```ridgun
type AgentStatus = AgentRunning | AgentStopped | AgentTimedOut Int | AgentFailed String
type AgentReply  = ReplyInt Int | ReplyStr String | ReplyBool Bool | ReplyEmpty | ReplyStopped | ReplyTimeout Int | ReplyError String
type CounterState = cnt_val: Int
type KvCmd        = KvPut String String | KvGet String | KvDel String | KvHas String | KvCount | KvKeys | KvClear
type KvEntry      = kv_k: String, kv_v: String
type KvState      = kv_size: Int, kv_items: [KvEntry]
type LogState     = log_sep: String, log_buf: String
```

| # | Function / Signature (`fn ::`) | Return Type |
|---|---|---|
| `1` | `fn :: format agent status AgentStatus` | `String` |
| `2` | `fn :: format agent reply AgentReply` | `String` |
| `3` | `fn :: is agent alive (Agent A B)` | `Bool` |
| `4` | `fn :: agent status (Agent A B)` | `AgentStatus` |
| `5` | `fn :: stop agent (Agent A B)` | `AgentStatus` |
| `6` | `fn :: agent stop all [Agent]` | `()` |
| `7` | `fn :: agent ask Agent A` | `B` |
| `8` | `fn :: agent try ask Agent A` | `Option` |
| `9` | `fn :: agent send batch Agent [A]` | `()` |
| `10` | `fn :: agent receive count Agent Int` | `[B]` |
| `11` | `fn :: agent receive count loop Agent Int [B]` | `[B]` |
| `12` | `fn :: agent map batch Agent [A]` | `[B]` |
| `13` | `fn :: agent list len [A] Int` | `Int` |
| `14` | `fn :: agent drain ready Agent` | `[B]` |
| `15` | `fn :: agent drain ready loop Agent [B]` | `[B]` |
| `16` | `fn :: agent drain step Agent Option [B]` | `[B]` |
| `17` | `fn :: ag cast opt A` | `B` |
| `18` | `fn :: ag unwrap try int (Option Int)` | `AgentReply` |
| `19` | `fn :: ag unwrap try str (Option String)` | `AgentReply` |
| `20` | `fn :: ask int (Agent Int Int) Int` | `AgentReply` |
| `21` | `fn :: ask str (Agent String String) String` | `AgentReply` |
| `22` | `fn :: try poll int (Agent A Int)` | `AgentReply` |
| `23` | `fn :: try poll str (Agent A String)` | `AgentReply` |
| `24` | `fn :: ag poll int step (Agent Int Int) (Option Int) Int Int` | `AgentReply` |
| `25` | `fn :: ag wait int loop (Agent Int Int) Int Int` | `AgentReply` |
| `26` | `fn :: ask int with timeout (Agent Int Int) Int Int` | `AgentReply` |
| `27` | `fn :: ag poll str step (Agent String String) (Option String) Int Int` | `AgentReply` |
| `28` | `fn :: ag wait str loop (Agent String String) Int Int` | `AgentReply` |
| `29` | `fn :: ask str with timeout (Agent String String) String Int` | `AgentReply` |
| `30` | `fn :: ask batch int (Agent Int Int) [Int]` | `[Int]` |
| `31` | `fn :: ask batch str (Agent String String) [String]` | `[String]` |
| `32` | `fn :: relay int (Agent Int Int) (Agent Int Int) Int` | `AgentReply` |
| `33` | `fn :: relay str (Agent String String) (Agent String String) String` | `AgentReply` |
| `34` | `fn :: ag counter step CounterState Int` | `CounterState Int` |
| `35` | `fn :: new counter agent Int` | `Agent Int Int` |
| `36` | `fn :: counter add (Agent Int Int) Int` | `Int` |
| `37` | `fn :: counter get (Agent Int Int)` | `Int` |
| `38` | `fn :: counter reset (Agent Int Int)` | `Int` |
| `39` | `fn :: ag log join String String String` | `String` |
| `40` | `fn :: ag log step LogState String` | `LogState String` |
| `41` | `fn :: new log agent String` | `Agent String String` |
| `42` | `fn :: log append (Agent String String) String` | `String` |
| `43` | `fn :: log read (Agent String String)` | `String` |
| `44` | `fn :: log clear (Agent String String)` | `String` |
| `45` | `fn :: ag kv lookup [KvEntry] String` | `String` |
| `46` | `fn :: ag kv exists [KvEntry] String` | `Bool` |
| `47` | `fn :: ag kv put list [KvEntry] String String` | `[KvEntry]` |
| `48` | `fn :: ag kv del list [KvEntry] String` | `[KvEntry]` |
| `49` | `fn :: ag kv len [KvEntry]` | `Int` |
| `50` | `fn :: ag kv keys join String String` | `String` |
| `51` | `fn :: ag kv keys str [KvEntry]` | `String` |
| `52` | `fn :: ag kv has str Bool` | `String` |
| `53` | `fn :: ag kv next state KvState KvCmd` | `KvState` |
| `54` | `fn :: ag kv next reply KvState KvCmd` | `String` |
| `55` | `fn :: ag kv step KvState KvCmd` | `KvState String` |
| `56` | `fn :: new kv agent` | `Agent KvCmd String` |
| `57` | `fn :: ag kv call (Agent KvCmd String) KvCmd` | `String` |
| `58` | `fn :: agent kv put (Agent KvCmd String) String String` | `String` |
| `59` | `fn :: agent kv get (Agent KvCmd String) String` | `String` |
| `60` | `fn :: agent kv delete (Agent KvCmd String) String` | `String` |
| `61` | `fn :: agent kv has (Agent KvCmd String) String` | `Bool` |
| `62` | `fn :: ag parse int String` | `Int` |
| `63` | `fn :: agent kv count (Agent KvCmd String)` | `Int` |
| `64` | `fn :: agent kv keys (Agent KvCmd String)` | `String` |
| `65` | `fn :: agent kv clear (Agent KvCmd String)` | `String` |

---

## 30.3. Deep Dive into `agent`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `agent` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test agent.ridgun`.

### 30.3.1. Example 1: Core Tabular Workflow with `agent`

Notice how in Ridgun the `=` signs and transformation steps using `agent` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import agent

fn :: probar contador actor => Int Int
      probar contador actor =
        10 new counter agent -> ag
        counter add ag 32 -> v1
        ag counter get -> v2
        ag stop agent -> ()
        (v1, v2)
```

### 30.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `agent` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 38 libs in `ridgun-libs`:

```ridgun
import agent

fn :: consultar almacen kv => String Int
      consultar almacen kv =
        new kv agent -> kv
        agent kv put kv "modo" "produccion" -> ()
        agent kv get kv "modo" -> modo
        agent kv count kv -> total
        stop agent kv -> ()
        (modo, total)
```

### 30.3.3. Example 3: Actor Combinators (`agent ask`, `agent try ask`, `agent send batch`, `agent map batch`, `agent drain ready`), Sharded Pools, and Connection Reactor

In this hands-on walkthrough we thoroughly exercise how `agent` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

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

### 30.3.4. Example 4: Agent Lifecycle (`is agent alive`, `agent status`, `stop agent`) and Isolated Stateful Counter Agent (`new counter agent`)

In this hands-on walkthrough we thoroughly exercise how `agent` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

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

### 30.3.5. Example 5: Append-Only Log Agent (`new log agent`) and Message-Passing In-Memory Key-Value Store (`new kv agent`)

In this hands-on walkthrough we thoroughly exercise how `agent` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

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

---

## 30.4. Under the Hood: How `agent` Is Built in Pure Ridgun (`src/main/ridgun/lib/agent.ridgun`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/agent.ridgun` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 30.4.1. Internal Implementation: Status & Reply Formatting

Observe how `agent.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
module :: agent

fn :: format agent status AgentStatus        => String
      format agent status AgentRunning       =  "running"
      format agent status AgentStopped       =  "stopped"
      format agent status (AgentTimedOut ms) =  "timeout after {ms} ms"
      format agent status (AgentFailed   msg) = "failed: {msg}"

fn :: format agent reply AgentReply        => String
      format agent reply (ReplyInt     n)  =  int to str n
      format agent reply (ReplyStr     s)  =  s
      format agent reply (ReplyBool True)  =  "true"
      format agent reply (ReplyBool False) =  "false"
      format agent reply ReplyEmpty        =  "agent outbox empty"
      format agent reply ReplyStopped      =  "agent stopped"
      format agent reply (ReplyTimeout ms) =  "agent timeout after {ms} ms"
      format agent reply (ReplyError  msg) =  "agent error: {msg}"
```

### 30.4.2. Internal Implementation: Core Combinators (`agent ask`, `agent try ask`, `agent send batch`, `agent receive count`, `agent map batch`, `agent drain ready`)

Observe how `agent.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: agent ask Agent A   => B
      agent ask ag    msg =  ask ag msg

fn :: agent try ask Agent A   => Option
      agent try ask ag    msg =
        send msg to ag
        try receive from ag

fn :: agent send batch Agent [A]      => ()
      agent send batch _     []       =  ()
      agent send batch ag    (m:rest) =
        send m to ag
        agent send batch ag rest

fn :: agent receive count Agent Int   => [B]
      agent receive count ag    count =  agent receive count loop ag count []

fn :: agent receive count loop Agent Int [B] => [B]
      agent receive count loop ag count acc
        | count <= 0 = acc
        | otherwise =
          r = receive from ag
          agent receive count loop ag (count - 1) (acc :: [r])

fn :: agent map batch Agent [A]  => [B]
      agent map batch ag    msgs =
        agent list len msgs 0 -> n
        agent send batch ag msgs -> ()
        agent receive count ag n

fn :: agent list len [A]    Int => Int
      agent list len []     acc =  acc
      agent list len (_:xs) acc =  agent list len xs (acc + 1)

fn :: agent drain ready Agent => [B]
      agent drain ready ag    =  agent drain ready loop ag []

fn :: agent drain ready loop Agent [B] => [B]
      agent drain ready loop ag acc =
        agent drain step ag (try receive from ag) acc

fn :: agent drain step Agent Option [B] => [B]
      agent drain step _ None acc = acc
      agent drain step ag (Some r) acc = agent drain ready loop ag (acc :: [r])
```

### 30.4.3. Internal Implementation: Stateful Counter Agent (`new counter agent`, `counter add`, `counter get`, `counter reset`)

Observe how `agent.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: ag counter step CounterState Int   => CounterState Int
      ag counter step st           delta =
        | delta == (0 - 999999999) = (CounterState 0, 0)
        | otherwise                =
          nxt = (cnt_val st) + delta
          (CounterState nxt, nxt)

fn :: new counter agent Int  => Agent Int Int
      new counter agent init =  agent (ag counter step) (CounterState init)

fn :: counter add (Agent Int Int) Int   => Int
      counter add ag              delta =
        | not (agent alive ag) = 0
        | otherwise            =
          send delta to ag
          receive from ag

fn :: counter get (Agent Int Int) => Int
      counter get ag              =  counter add ag 0

fn :: counter reset (Agent Int Int) => Int
      counter reset ag              =  counter add ag (0 - 999999999)
```

### 30.4.4. Internal Implementation: Stateful In-Memory Key-Value Agent (`new kv agent`, `agent kv put`, `agent kv get`, `agent kv delete`, `agent kv has`, `agent kv count`, `agent kv keys`, `agent kv clear`)

Observe how `agent.ridgun` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

```ridgun
fn :: ag kv lookup [KvEntry] String => String
      ag kv lookup []        _      =  ""
      ag kv lookup (e:rest)  key    =
        | (kv_k e) == key = kv_v e
        | otherwise       = ag kv lookup rest key

fn :: ag kv exists [KvEntry] String => Bool
      ag kv exists []        _      =  False
      ag kv exists (e:rest)  key    =
        | (kv_k e) == key = True
        | otherwise       = ag kv exists rest key

fn :: ag kv put list [KvEntry] String String => [KvEntry]
      ag kv put list [] key val = [KvEntry key val]
      ag kv put list (e:rest) key val =
        | (kv_k e) == key = [KvEntry key val] :: rest
        | otherwise       = [e] :: (ag kv put list rest key val)

fn :: ag kv del list [KvEntry] String => [KvEntry]
      ag kv del list [] _ = []
      ag kv del list (e:rest) key =
        | (kv_k e) == key = rest
        | otherwise       = [e] :: (ag kv del list rest key)

fn :: ag kv len [KvEntry] => Int
      ag kv len []        =  0
      ag kv len (_:rest)  =  1 + (ag kv len rest)

fn :: ag kv keys join String String => String
      ag kv keys join k rest_s =
        | (str len rest_s) == 0 = k
        | otherwise             = k + "," + rest_s

fn :: ag kv keys str [KvEntry] => String
      ag kv keys str []        =  ""
      ag kv keys str (e:rest)  =  ag kv keys join (kv_k e) (ag kv keys str rest)

fn :: ag kv has str Bool  => String
      ag kv has str True  =  "1"
      ag kv has str False =  "0"

fn :: ag kv next state KvState KvCmd => KvState
      ag kv next state st (KvPut key val) =
        p2 = ag kv put list (kv_items st) key val
        KvState (ag kv len p2) p2
      ag kv next state st (KvGet _) = st
      ag kv next state st (KvDel key) =
        p2 = ag kv del list (kv_items st) key
        KvState (ag kv len p2) p2
      ag kv next state st (KvHas _) = st
      ag kv next state st KvCount = st
      ag kv next state st KvKeys = st
      ag kv next state _ KvClear = KvState 0 []

fn :: ag kv next reply KvState KvCmd => String
      ag kv next reply _ (KvPut _   val) = val
      ag kv next reply st (KvGet key) = ag kv lookup (kv_items st) key
      ag kv next reply st (KvDel key) = ag kv lookup (kv_items st) key
      ag kv next reply st (KvHas key) = ag kv has str (ag kv exists (kv_items st) key)
      ag kv next reply st KvCount = int to str (kv_size st)
      ag kv next reply st KvKeys = ag kv keys str (kv_items st)
      ag kv next reply _ KvClear = ""

fn :: ag kv step KvState KvCmd => KvState String
      ag kv step st      cmd   =
        st2 = ag kv next state st cmd
        rep = ag kv next reply st cmd
        (st2, rep)

fn :: new kv agent => Agent KvCmd String
      new kv agent =  agent (ag kv step) (KvState 0 [])

fn :: ag kv call (Agent KvCmd String) KvCmd => String
      ag kv call ag                   cmd   =
        | not (agent alive ag) = ""
        | otherwise            =
          send cmd to ag
          receive from ag

fn :: agent kv put (Agent KvCmd String) String String => String
      agent kv put ag                   key    val    =  ag kv call ag (KvPut key val)

fn :: agent kv get (Agent KvCmd String) String => String
      agent kv get ag                   key    =  ag kv call ag (KvGet key)

fn :: agent kv delete (Agent KvCmd String) String => String
      agent kv delete ag                   key    =  ag kv call ag (KvDel key)

fn :: agent kv has (Agent KvCmd String) String => Bool
      agent kv has ag                   key    =  (ag kv call ag (KvHas key)) == "1"

fn :: ag parse int String => Int
      ag parse int s      =
        | (str len s) == 0 = 0
        | otherwise        = str to int s

fn :: agent kv count (Agent KvCmd String) => Int
      agent kv count ag                   =  ag parse int (ag kv call ag KvCount)

fn :: agent kv keys (Agent KvCmd String) => String
      agent kv keys ag                   =  ag kv call ag KvKeys

fn :: agent kv clear (Agent KvCmd String) => String
      agent kv clear ag                   =  ag kv call ag KvClear
```

---

## 30.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `agent`

- **Algorithmic & Safety Guarantee**: Zero shared mutable memory across actors: every message is transferred by value / Copy-on-Write and `stop` deterministically reclaims the actor's region.
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/agent.ridgun` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test agent.ridgun`.

### The 5 Golden Rules When Programming with `agent`

1. **Declare `import agent` at the top of your file** and call its functions with spaces, exactly as they are declared, so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `agent` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `agent`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `agent` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 31**, we will explore the **`pool`** lib in full depth (The `pool` Lib — Bounded Worker Pool, Round-Robin Dispatch, and Work-Stealing).
