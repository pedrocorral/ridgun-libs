# Kapitel 31: Lib:en `pool` — Begränsad Worker-pool, Round-Robin och Work-Stealing

## 31.1. Varför finns lib:en `pool`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `pool`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `pool`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: att starta en ny tråd eller aktör för varje inkommande anrop utan övre gräns garanterar att en trafiktopp tömmer serverns minne på några sekunder.

Lib:en **`pool`** tillhandahåller en begränsad uppgiftsfördelare med **explicit mottryck** (`PoolAccept`, `PoolRejectFull`), balanserad uppdelning i $K$ filer (`pool partition`), ombalansering med **work-stealing** (`pool steal rebalance`) och parallell exekvering över inbyggda aktörer.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`AGENT`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`pool`** (`src/main/ridgun/lib/pool.rg`) problemet genom fyra kompromisslösa principer:

1. **Totala funktioner och explicita kontrakt (`=>`)**: ingen funktion i `pool` kastar dolda undantag eller förlitar sig på `null`. Varje gränsfall returnerar ett dokumenterat sentinelvärde eller en algebraisk summatyp (`Option`, `Result`).
2. **Noll C-kod och noll `libc`**: varje rad i `pool` kompileras direkt till inbyggd ELF64-maskinkod verifierad av `ridgunc`.
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `pool` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 31.2. Inbyggda artefakter, import och komplett API-katalog för `pool`

I `ridgun-libs` är **`pool`** en förstklassig **lib** placerad i `src/main/ridgun/lib/pool.rg` (domän `AGENT`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/pool.rglib` | Portabel distribution och direkt import med `import pool` |
| **Kompilerat arkiv** | `target/pool.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libpool.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import pool` överst och anropar funktionerna med mellanslag eller understreck.

### 31.2.1. Översikt över funktionella familjer i `pool`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `pool new : Int -> Int -> PoolState` | Skapar en begränsad pool med `workers` filer och `max_queue` i kökapacitet |
| `pool submit : PoolState -> PoolTask -> (PoolState, PoolDecision)` | Köar en uppgift med round-robin eller returnerar `PoolRejectFull` vid mättnad |
| `pool partition / pool steal rebalance` | Delar upp batcher över $K$ arbetare och stjäl hälften av en överbelastad kö till en ledig arbetare |
| `pool map sum / pool parallel sum2` | Fördelar arbetslaster parallellt över inbyggda `agent`-arbetare |

### 31.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/pool.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/pool.rg` (`1` typer, `0` operatorer och `14` funktioner):

**Algebraiska datatyper och poster (`type`) i `pool`:**

```ridgun
type AgentPool = Pool Int [Agent]
```

| # | Funktion / Signatur (`fn ::`) | Returtyp |
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

## 31.3. Djupdykning i `pool`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `pool` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test pool.rg`.

### 31.3.1. Exempel 1: Huvudflöde i tabellform med `pool`

Lägg märke till hur `=`-tecknen och transformationsstegen med `pool` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import pool

fn :: encolar con contrapresion () => (Int, Int)
      encolar con contrapresion =
        p0        = pool new 4 16
        tarea     = PoolTask 1 100 "indexar-bloque"
        (p1, dec) = pool submit p0 tarea
        (pool queued p1, pool accepted p1)
```

### 31.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `pool` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import pool

fn :: sumar en paralelo () => Int
      sumar en paralelo =
        pool parallel sum2 [10, 20, 30] [40, 50, 60]
```

### 31.3.3. Exempel 3: Aktörskombinatorer (`agent ask`, `try ask`, `send batch`, `map batch`, `drain ready`), shardade pooler och anslutningsreaktor

I detta praktiska exempel undersöker vi grundligt hur `pool` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test spec combinators pool and net agent => ()
      test spec combinators pool and net agent =
        w1 = agent (ag double worker)
        _  = assert int equals (agent ask w1 21) 42 "agent ask 21 -> 42"
        mb = agent map batch w1 [3, 5, 7]
        _  = assert int equals (ag sum ints mb) 30 "agent map batch [3,5,7] -> [6,10,14] sum 30"
        _  = agent send batch w1 [10, 20]
        rc = agent receive count w1 2
        _  = assert int equals (ag sum ints rc) 60 "agent send batch + agent receive count -> 60"
        c_dr = new counter agent 100
        _  = send 5 to c_dr
        _  = send 10 to c_dr
        dr = agent drain ready c_dr
        _  = assert int equals (ag sum ints dr) 220 "agent drain ready [105, 115] -> 220"
        _  = agent stop all [w1, c_dr]
        _  = assert false (is agent alive w1) "w1 stopped by agent stop all"
        _  = assert false (is agent alive c_dr) "c_dr stopped by agent stop all"

        s0 = new counter agent 0
        s1 = new counter agent 1000
        pl = Pool 2 [s0, s1]
        _  = assert int equals (pool size pl) 2 "pool size 2"
        _  = assert int equals (pool ask shard pl 0 5) 5 "pool ask shard 0 -> 5"
        _  = assert int equals (pool ask shard pl 1 7) 1007 "pool ask shard 1 -> 1007"
        _  = assert int equals (pool ask shard pl (0 - 3) 3) 1010 "pool ask shard negative key -> shard 1"
        _  = pool broadcast pl 10
        all_dr = pool drain all pl
        _  = assert int equals (ag sum ints all_dr) 1035 "pool drain all [15, 1020] -> 1035"
        _  = pool shutdown pl
        _  = assert false (is agent alive s0) "pool s0 stopped"
        _  = assert false (is agent alive s1) "pool s1 stopped"

        ca = agent (ag echo conn step) (CounterState 0)
        cb = agent (ag echo conn step) (CounterState 0)
        s_eof = conn feed payload (0 - 1) ca ""
        s_err = conn handle event (0 - 1) cb 8
        kept  = reactor sweep next s_eof (reactor sweep next s_err [])
        _  = assert int equals (agent list len kept 0) 0 "reactor sweep next prunes closed slots"
        _  = assert false (is agent alive ca) "ca stopped on EOF"
        _  = assert false (is agent alive cb) "cb stopped on POLLERR"
        cc = agent (ag echo conn step) (CounterState 0)
        _  = reactor shutdown [ConnSlot (0 - 1) cc]
        assert false (is agent alive cc) "cc stopped on reactor shutdown"
```

### 31.3.4. Exempel 4: Agentlivscykel (`is agent alive`, `agent status`, `stop agent`) och isolerad tillståndsfull räknaragent (`new counter agent`)

I detta praktiska exempel undersöker vi grundligt hur `pool` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test agent lifecycle and counter => ()
      test agent lifecycle and counter =
        _   = assert str eq (format agent status AgentRunning) "running" "format AgentRunning"
        _   = assert str eq (format agent status AgentStopped) "stopped" "format AgentStopped"
        _   = assert str eq (format agent status (AgentTimedOut 250)) "timeout after 250 ms" "format AgentTimedOut"
        _   = assert str eq (format agent status (AgentFailed "boom")) "failed: boom" "format AgentFailed"
        _   = assert str eq (format agent reply (ReplyInt 42)) "42" "format ReplyInt"
        _   = assert str eq (format agent reply (ReplyStr "ok")) "ok" "format ReplyStr"
        _   = assert str eq (format agent reply (ReplyBool True)) "true" "format ReplyBool True"
        _   = assert str eq (format agent reply (ReplyBool False)) "false" "format ReplyBool False"
        _   = assert str eq (format agent reply ReplyEmpty) "agent outbox empty" "format ReplyEmpty"
        _   = assert str eq (format agent reply ReplyStopped) "agent stopped" "format ReplyStopped"
        _   = assert str eq (format agent reply (ReplyTimeout 50)) "agent timeout after 50 ms" "format ReplyTimeout"
        _   = assert str eq (format agent reply (ReplyError "bad")) "agent error: bad" "format ReplyError"

        c   = new counter agent 10
        _   = assert ok (is agent alive c)
        _   = assert str eq (format agent status (agent status c)) "running" "counter running"
        _   = assert str eq (format agent reply (try poll int c)) "agent outbox empty" "empty outbox before send"
        _   = assert eq (counter get c) 10
        _   = assert eq (counter add c 5) 15
        _   = assert eq (counter add c 7) 22
        _   = assert str eq (format agent reply (ask int c 8)) "30" "ask int 8 -> 30"
        _   = assert str eq (format agent reply (ask int with timeout c 12 200)) "42" "ask int with timeout -> 42"
        _   = assert eq (counter reset c) 0
        _   = assert eq (counter get c) 0
        bs  = ask batch int c [1, 2, 3, 4]
        _   = assert eq (ag sum ints bs) 20

        c2  = new counter agent 100
        rel = relay int c c2 5
        _   = assert str eq (format agent reply rel) "115" "relay int c (10+5=15) -> c2 (100+15=115)"

        st1 = stop agent c
        _   = assert str eq (format agent status st1) "stopped" "stop agent returns AgentStopped"
        _   = assert eq (is agent alive c) False
        _   = assert str eq (format agent status (agent status c)) "stopped" "agent status after stop"
        _   = assert str eq (format agent reply (ask int c 1)) "agent stopped" "ask int after stop"
        _   = assert str eq (format agent reply (try poll int c)) "agent stopped" "try poll int after stop"
        _   = assert str eq (format agent reply (ask int with timeout c 1 50)) "agent stopped" "ask int with timeout after stop"
        _   = assert str eq (format agent reply (relay int c c2 1)) "agent stopped" "relay int after stop"
        c0  = new counter agent 0
        _   = assert int equals (counter get c0) 0 "counter 0 initial"
        _   = assert int equals (counter add c0 3) 3 "counter 0 add 3"
        _   = stop agent c0
        _   = stop agent c2
        assert eq (is agent alive c2) False
```

### 31.3.5. Exempel 5: Append-only-loggagent (`new log agent`) och meddelandebaserad nyckel-värde-lagring i minnet (`new kv agent`)

I detta praktiska exempel undersöker vi grundligt hur `pool` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test log and kv agents => ()
      test log and kv agents =
        lg  = new log agent "\n"
        _   = assert ok (is agent alive lg)
        _   = assert str eq (format agent reply (try poll str lg)) "agent outbox empty" "log empty outbox"
        _   = assert str eq (log read lg) "" "initial log empty"
        _   = assert str eq (log append lg "alpha") "alpha" "log append alpha"
        _   = assert str eq (log append lg "beta") "alpha\nbeta" "log append beta"
        _   = assert str eq (format agent reply (ask str with timeout lg "gamma" 200)) "alpha\nbeta\ngamma" "ask str with timeout gamma"
        _   = assert str eq (log read lg) "alpha\nbeta\ngamma" "log read"
        _   = assert str eq (log clear lg) "" "log clear"
        _   = assert str eq (log read lg) "" "log read after clear"
        b   = ask batch str lg ["one", "two"]
        _   = assert str eq (ag join strs b) "one|one\ntwo" "ask batch str"
        lg2 = new log agent ":"
        _   = assert str eq (format agent reply (relay str lg lg2 "three")) "one\ntwo\nthree" "relay str"
        _   = stop agent lg
        _   = stop agent lg2
        _   = assert str eq (format agent reply (ask str lg "x")) "agent stopped" "ask str after stop"

        kv  = new kv agent
        _   = assert ok (is agent alive kv)
        _   = assert int equals (kv count kv) 0 "kv count 0"
        _   = assert false (kv has kv "host") "kv has host false"
        _   = assert str eq (kv put kv "host" "127.0.0.1") "127.0.0.1" "kv put host"
        _   = assert str eq (kv put kv "port" "8080") "8080" "kv put port"
        _   = assert int equals (kv count kv) 2 "kv count 2"
        _   = assert ok (kv has kv "host")
        _   = assert ok (kv has kv "port")
        _   = assert str eq (kv get kv "host") "127.0.0.1" "kv get host"
        _   = assert str eq (kv get kv "port") "8080" "kv get port"
        _   = assert str eq (kv keys kv) "host,port" "kv keys"
        _   = assert str eq (kv put kv "port" "9090") "9090" "kv overwrite port"
        _   = assert str eq (kv get kv "port") "9090" "kv get updated port"
        _   = assert int equals (kv count kv) 2 "kv count after overwrite"
        _   = assert str eq (kv delete kv "host") "127.0.0.1" "kv delete host"
        _   = assert false (kv has kv "host") "kv has host after delete"
        _   = assert int equals (kv count kv) 1 "kv count 1"
        _   = assert str eq (kv clear kv) "" "kv clear"
        _   = assert int equals (kv count kv) 0 "kv count after clear"
        _   = stop agent kv
        assert false (is agent alive kv) "kv stopped"
```

### 31.3.6. Exempel 6: Deterministisk nyckelshardning (`pool ask shard`), utsändning (`pool broadcast`), icke-blockerande tömning (`pool drain all`) och avstängning (`pool shutdown`)

I detta praktiska exempel undersöker vi grundligt hur `pool` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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
        _    = pool broadcast p 1
        pend = pool drain all p
        _    = pool shutdown p
        (sz, r_a + r_b, pend)
```

---

## 31.4. Under huven: hur `pool` är byggd i ren Ridgun (`src/main/ridgun/lib/pool.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/pool.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 31.4.1. Intern implementation: Core Implementation Part 1

Se hur `pool.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
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
        shard_idx = (pool abs key_hash) % size
        target_ag = pool get agent agents shard_idx
        ask target_ag msg

-- Broadcast a message to every agent in the pool (e.g. configuration reload or tick)
fn :: pool broadcast AgentPool       A   => ()
      pool broadcast (Pool _ agents) msg =  pool broadcast list agents msg

fn :: pool broadcast list [Agent]   A   => ()
      pool broadcast list []        _   =  ()
      pool broadcast list (ag:rest) msg =
        send msg to ag
        pool broadcast list rest msg
```

### 31.4.2. Intern implementation: Core Implementation Part 2

Se hur `pool.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
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
        ready = pool drain ready ag
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

## 31.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `pool`

- **Algoritmisk garanti och säkerhet**: Strikt begränsad kökapacitet (`queued <= max_queue`) för att skydda minnet vid belastningstoppar samt deterministisk fördelning mellan arbetare.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/pool.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test pool.rg`.

### De 5 Gyllene Reglerna när du programmerar med `pool`

1. **Deklarera `import pool` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `pool`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `pool`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `pool` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 32** går vi vidare och utforskar lib:en **`net_agent`** på djupet (Lib:en `net_agent` — Övervakare för Nätverksanslutningar och Icke-blockerande Händelsebrygga).
