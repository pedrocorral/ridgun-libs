# Kapitel 32: Lib:en `net_agent` — Övervakare för Nätverksanslutningar och Icke-blockerande Händelsebrygga

## 32.1. Varför finns lib:en `net_agent`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `net_agent`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `net_agent`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: i en riktig server som **Solstice** är det enkelt att acceptera TCP-anslutningar; det svåra är att begränsa max antal samtidiga klienter, rensa bort inaktiva zombie-anslutningar (*idle timeout*) och koppla ihop `ppoll`-loopen med dina aktörer utan att läcka fildeskriptorer.

Lib:en **`net_agent`** sluter cirkeln i `ridgun-libs` genom att förena **`posix`**, **`socket`** och **`agent`**: den hanterar övervakade anslutningstabeller (`NetSupervisor`), upprätthåller gränser för samtidiga klienter (`max_conns`), rensar inaktiva anslutningar (`net evict idle`), översätter kärndeskriptor-polling till typade aktörshändelser (`NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout`, `NetEvError`) och erbjuder ett komplett övervakat TCP-ekosteg (`net tcp echo step`).

I ett traditionellt ekosystem innebär uppgifter inom domänen **`AGENT`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`net_agent`** (`src/main/ridgun/lib/net_agent.rg`) problemet genom fyra kompromisslösa principer:

1. **Totala funktioner och explicita kontrakt (`=>`)**: ingen funktion i `net_agent` kastar dolda undantag eller förlitar sig på `null`. Varje gränsfall returnerar ett dokumenterat sentinelvärde eller en algebraisk summatyp (`Option`, `Result`).
2. **Noll C-kod och noll `libc`**: varje rad i `net_agent` kompileras direkt till inbyggd ELF64-maskinkod verifierad av `ridgunc`.
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `net_agent` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 32.2. Inbyggda artefakter, import och komplett API-katalog för `net_agent`

I `ridgun-libs` är **`net_agent`** en förstklassig **lib** placerad i `src/main/ridgun/lib/net_agent.rg` (domän `AGENT`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/net_agent.rglib` | Portabel distribution och direkt import med `import net_agent` |
| **Kompilerat arkiv** | `target/net_agent.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libnet_agent.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import net_agent` överst och anropar funktionerna med mellanslag eller understreck.

### 32.2.1. Översikt över funktionella familjer i `net_agent`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `net supervisor new : Int -> Int -> NetSupervisor` | Skapar en anslutningsövervakare med `max_conns` och `idle_timeout_ms` |
| `net register conn / net record rx / net record tx / net close conn` | Registrerar accepterade sockets, spårar byte-räknare/tidsstämplar och stänger anslutningar |
| `net evict idle : NetSupervisor -> Int -> (NetSupervisor, [Int])` | Stänger och rensar ut anslutningar som varit inaktiva längre än `idle_timeout_ms` |
| `net poll fd : Int -> Bool -> Int -> NetEvent` | Icke-blockerande `wait fd`-brygga som ger `NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout` eller `NetEvError` |
| `net tcp echo step : String -> Int -> (Int, String)` | Komplett TCP loopback-steg från ända till ända (`listen/connect/accept/supervise/echo`) |

### 32.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/net_agent.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/net_agent.rg` (`2` typer, `0` operatorer och `8` funktioner):

**Algebraiska datatyper och poster (`type`) i `net_agent`:**

```ridgun
type ConnSlot = ConnSlot Int Agent
type StepOutcome = ConnKeep ConnSlot String | ConnClosed
```

| # | Funktion / Signatur (`fn ::`) | Returtyp |
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

## 32.3. Djupdykning i `net_agent`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `net_agent` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test net_agent.rg`.

### 32.3.1. Exempel 1: Huvudflöde i tabellform med `net_agent`

Lägg märke till hur `=`-tecknen och transformationsstegen med `net_agent` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

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

### 32.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `net_agent` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import net_agent

fn :: probar puente tcp supervisado () => (Int, String)
      probar puente tcp supervisado =
        net tcp echo step "ping-supervisado" 1000
```

### 32.3.3. Exempel 3: Aktörskombinatorer (`agent ask`, `try ask`, `send batch`, `map batch`, `drain ready`), shardade pooler och anslutningsreaktor

I detta praktiska exempel undersöker vi grundligt hur `net_agent` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 32.3.4. Exempel 4: Agentlivscykel (`is agent alive`, `agent status`, `stop agent`) och isolerad tillståndsfull räknaragent (`new counter agent`)

I detta praktiska exempel undersöker vi grundligt hur `net_agent` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 32.3.5. Exempel 5: Append-only-loggagent (`new log agent`) och meddelandebaserad nyckel-värde-lagring i minnet (`new kv agent`)

I detta praktiska exempel undersöker vi grundligt hur `net_agent` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 32.3.6. Exempel 6: Icke-blockerande deskriptoravfrågning (`conn poll step`), svepning av anslutningstabell (`reactor sweep`) och kontrollerad nedstängning (`reactor shutdown`)

I detta praktiska exempel undersöker vi grundligt hur `net_agent` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
import agent
import net_agent

fn :: sesion eco (n : Int) (trama : String) => (Int, String)
      sesion eco n trama =
        sig = n + 1
        (sig, "[#{sig}] {trama}")

fn :: ejemplo reactor conexiones (fd1 : Int) (fd2 : Int) => [ConnSlot]
      ejemplo reactor conexiones fd1 fd2 =
        ag1     = agent sesion eco 0
        ag2     = agent sesion eco 0
        activas = [ConnSlot fd1 ag1, ConnSlot fd2 ag2]
        -- Barrido no bloqueante (sys_poll timeout=0) de todas las conexiones
        vivas   = reactor sweep activas
        -- Cierre ordenado de descriptores y parada determinista de agentes
        _       = reactor shutdown vivas
        []
```

---

## 32.4. Under huven: hur `net_agent` är byggd i ren Ridgun (`src/main/ridgun/lib/net_agent.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/net_agent.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 32.4.1. Intern implementation: Core Implementation Part 1

Se hur `net_agent.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
type ConnSlot = ConnSlot Int Agent

type StepOutcome = ConnKeep ConnSlot String | ConnClosed

-- Poll a single connection fd (non-blocking, timeout = 0) and route incoming data to its Agent
fn :: conn poll step ConnSlot         => StepOutcome
      conn poll step (ConnSlot fd ag) =
        ev = sys poll fd 1 0
        conn handle event fd ag ev

fn :: conn handle event Int Agent Int => StepOutcome
      conn handle event fd ag ev
        | ev < 0 =
          -- Poll error: close descriptor and stop agent
          _ = sys close fd
          stop ag
          ConnClosed
        | ev >= 8 =
          -- POLLERR (8) or POLLHUP (16): peer disconnected
          _ = sys close fd
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
        _ = sys close fd
        stop ag
        ConnClosed
      conn feed payload fd ag data =
        send data to ag
        conn drain outbound fd ag (try receive from ag)
```

### 32.4.2. Intern implementation: Core Implementation Part 2

Se hur `net_agent.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: conn cast str A => String
      conn cast str x =  x

fn :: conn drain outbound Int Agent Option => StepOutcome
      conn drain outbound fd ag None = ConnKeep (ConnSlot fd ag) ""
      conn drain outbound fd ag (Some resp) =
        s = conn cast str resp
        _ = sys write fd fd s
        ConnKeep (ConnSlot fd ag) s

-- Sweep an entire connection table, pruning closed connections and keeping active ones
fn :: reactor sweep [ConnSlot]  => [ConnSlot]
      reactor sweep []          =  []
      reactor sweep (slot:rest) =
        reactor sweep next (conn poll step slot) (reactor sweep rest)

fn :: reactor sweep next StepOutcome       [ConnSlot] => [ConnSlot]
      reactor sweep next ConnClosed        kept       =  kept
      reactor sweep next (ConnKeep slot _) kept       =  [slot] :: kept

-- Gracefully close all sockets and stop all connection agents on server shutdown
fn :: reactor shutdown [ConnSlot] => ()
      reactor shutdown []         =  ()
      reactor shutdown ((ConnSlot fd ag):rest) =
        _ = sys close fd
        stop ag
        reactor shutdown rest
```

---

## 32.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `net_agent`

- **Algoritmisk garanti och säkerhet**: Automatiskt skydd mot deskriptoruttömning (`max_conns`), deterministisk utrensning av inaktiva anslutningar och garanterad stängning av sockets i `net tcp echo step`.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/net_agent.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test net_agent.rg`.

### De 5 Gyllene Reglerna när du programmerar med `net_agent`

1. **Deklarera `import net_agent` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `net_agent`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `net_agent`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `net_agent` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

Du har nu genomfört hela djupdykningen genom alla **32 standard-libs i `ridgun-libs`**! Nu har du alla byggstenar som krävs för att bygga kompletta applikationer och systemverktyg i ren Ridgun.
