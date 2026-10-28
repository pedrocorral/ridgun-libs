# Kapitel 30: Lib:en `agent` — Inbyggd Aktörskonkurrens (`agent`, `send`, `receive`), KV-lagring och Rate Limiter

## 30.1. Varför finns lib:en `agent`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `agent`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `agent`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: att dela muterbart minne mellan trådar med `Mutex`, `RwLock` och villkorsvariabler är en outsinlig fabrik av *deadlocks* och kapplöpningsvillkor.

Lib:en **`agent`** bygger vidare på Ridguns **inbyggda aktörsmodell** (`agent`, `send ... to`, `receive from`, `try receive from`, `stop`) och erbjuder isolerade brevlådor med Copy-on-Write-meddelanden, en konkurrent nyckel-värde-lagring (`KvStore`), en *token-bucket*-begränsare (`RateBucket`) samt övervakning (`AgentHealth`).

I ett traditionellt ekosystem innebär uppgifter inom domänen **`AGENT`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`agent`** (`src/main/ridgun/lib/agent.rg`) problemet genom fyra kompromisslösa principer:

1. **Deklarera `import agent` (eller `import agent as alias`) överst i filen**: varje lib definierar sin `module :: agent`-namnrymd och i `--strict`-läge anropas flerordsfunktioner alltid med naturliga mellanslag.
2. **Kedja dina datapipelines från vänster till höger med `->`**: skriv `indata steg ett -> steg två -> resultat`, använd `(+ _ _ +)`-sekvensmasker för att packa upp tupler och utelämna `_ =` vid sekventiella satser (eller kasta med `-> ()`).
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `agent` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 30.2. Inbyggda artefakter, import och komplett API-katalog för `agent`

I `ridgun-libs` är **`agent`** en förstklassig **lib** placerad i `src/main/ridgun/lib/agent.rg` (domän `AGENT`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/agent.rglib` | Portabel distribution och direkt import med `import agent` |
| **Kompilerat arkiv** | `target/agent.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libagent.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> Varje lib deklarerar sin egen namnrymd med `module :: agent`: skriv bara `import agent` (eller `import agent as alias`) överst och anropa dess funktioner med naturliga mellanslag (`min funktion x`) och `->`-pipelines (`x min funktion -> resultat`).

### 30.2.1. Översikt över funktionella familjer i `agent`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `agent roundtrip / agent drain count` | Startar inbyggda aktörer (`agent`), utbyter meddelanden (`send ... to` / `receive from`) och kör `stop` |
| `kv store new / kv store apply` | Oföränderlig nyckel-värde-lagring för aktörer (`KvPut`, `KvGet`, `KvDelete`, `KvClear`) |
| `rate bucket new / rate bucket allow` | *Token-bucket*-begränsare som returnerar uppdaterad hink och `(allowed, remaining)` |
| `sup mark failed / sup should restart` | Övervakningsfunktioner som spårar omstartsbudget (`max_restarts`) |

### 30.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/agent.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/agent.rg` (`7` typer, `0` operatorer och `65` funktioner):

**Algebraiska datatyper och poster (`type`) i `agent`:**

```ridgun
type AgentStatus = AgentRunning | AgentStopped | AgentTimedOut Int | AgentFailed String
type AgentReply  = ReplyInt Int | ReplyStr String | ReplyBool Bool | ReplyEmpty | ReplyStopped | ReplyTimeout Int | ReplyError String
type CounterState = cnt_val: Int
type KvCmd        = KvPut String String | KvGet String | KvDel String | KvHas String | KvCount | KvKeys | KvClear
type KvEntry      = kv_k: String, kv_v: String
type KvState      = kv_size: Int, kv_items: [KvEntry]
type LogState     = log_sep: String, log_buf: String
```

| # | Funktion / Signatur (`fn ::`) | Returtyp |
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
| `58` | `fn :: kv put (Agent KvCmd String) String String` | `String` |
| `59` | `fn :: kv get (Agent KvCmd String) String` | `String` |
| `60` | `fn :: kv delete (Agent KvCmd String) String` | `String` |
| `61` | `fn :: kv has (Agent KvCmd String) String` | `Bool` |
| `62` | `fn :: ag parse int String` | `Int` |
| `63` | `fn :: kv count (Agent KvCmd String)` | `Int` |
| `64` | `fn :: kv keys (Agent KvCmd String)` | `String` |
| `65` | `fn :: kv clear (Agent KvCmd String)` | `String` |

---

## 30.3. Djupdykning i `agent`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `agent` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test agent.rg`.

### 30.3.1. Exempel 1: Huvudflöde i tabellform med `agent`

Lägg märke till hur `=`-tecknen och transformationsstegen med `agent` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

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

### 30.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `agent` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import agent

fn :: consultar almacen kv => String Int
      consultar almacen kv =
        new kv agent -> kv
        kv put kv "modo" "produccion" -> ()
        kv get kv "modo" -> modo
        kv count kv -> total
        kv stop agent -> ()
        (modo, total)
```

### 30.3.3. Exempel 3: Aktörskombinatorer (`agent ask`, `try ask`, `send batch`, `map batch`, `drain ready`), shardade pooler och anslutningsreaktor

I detta praktiska exempel undersöker vi grundligt hur `agent` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 30.3.4. Exempel 4: Agentlivscykel (`is agent alive`, `agent status`, `stop agent`) och isolerad tillståndsfull räknaragent (`new counter agent`)

I detta praktiska exempel undersöker vi grundligt hur `agent` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 30.3.5. Exempel 5: Append-only-loggagent (`new log agent`) och meddelandebaserad nyckel-värde-lagring i minnet (`new kv agent`)

I detta praktiska exempel undersöker vi grundligt hur `agent` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

---

## 30.4. Under huven: hur `agent` är byggd i ren Ridgun (`src/main/ridgun/lib/agent.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/agent.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 30.4.1. Intern implementation: Status & Reply Formatting

Se hur `agent.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

### 30.4.2. Intern implementation: Core Combinators (`agent ask`, `agent try ask`, `agent send batch`, `agent receive count`, `agent map batch`, `agent drain ready`)

Se hur `agent.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

### 30.4.3. Intern implementation: Stateful Counter Agent (`new counter agent`, `counter add`, `counter get`, `counter reset`)

Se hur `agent.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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
          _ = send delta to ag
          receive from ag

fn :: counter get (Agent Int Int) => Int
      counter get ag              =  counter add ag 0

fn :: counter reset (Agent Int Int) => Int
      counter reset ag              =  counter add ag (0 - 999999999)
```

### 30.4.4. Intern implementation: Stateful In-Memory Key-Value Agent (`new kv agent`, `kv put`, `kv get`, `kv delete`, `kv has`, `kv count`, `kv keys`, `kv clear`)

Se hur `agent.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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
```

---

## 30.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `agent`

- **Algoritmisk garanti och säkerhet**: Noll delat muterbart minne mellan aktörer: varje meddelande överförs via värde / Copy-on-Write och `stop` frigör aktörens minnesregion deterministiskt.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/agent.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test agent.rg`.

### De 5 Gyllene Reglerna när du programmerar med `agent`

1. **Deklarera `import agent` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `agent`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `agent`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `agent` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 31** går vi vidare och utforskar lib:en **`pool`** på djupet (Lib:en `pool` — Begränsad Worker-pool, Round-Robin och Work-Stealing).
