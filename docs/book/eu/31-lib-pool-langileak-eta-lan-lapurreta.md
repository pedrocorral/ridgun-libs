# 31. kapitulua: `pool` lib-a — Agente-poolak: Gako bidezko Zatikatzea, Hedapena eta Hustuketa Ez-blokeatzailea

## 31.1. Zergatik existitzen da `pool` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `pool` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `pool`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: sartzen den eskaera bakoitzeko goi-mugarik gabe hari edo aktore berri bat abiarazteak (`unbounded spawning`) trafiko-gailur batean memoria segundo gutxitan agortzea eragiten du (*Out Of Memory*).

**`pool`** lib-ak agente kopuru finko bat `AgentPool` batean biltzen du: `pool ask shard`-ek eskaera bakoitza bere gakoak aukeratutako agenteari bidaltzen dio, eta, hala, gako bera beti agente berera iristen da; `pool broadcast`-ek mezu bat agente guztiei bidaltzen die; `pool drain all`-ek prest dauden erantzunak biltzen ditu, blokeatu gabe; eta `pool shutdown`-ek guztiak gelditzen ditu.

Ekosistema tradizional batean, **`AGENT`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`pool`** lib-ak (`src/main/ridgun/lib/pool.ridgun`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Deklaratu `import pool` (edo `import pool as alias`) fitxategiaren hasieran**: lib bakoitzak `module :: pool` izen-espazioa definitzen du eta `--strict` moduan hitz anitzeko funtzioei zuriune naturalekin deitzen zaie beti.
2. **Kateatu zure datu-hodiak ezkerretik eskuinera `->` bidez**: idatzi `sarrera lehen urratsa -> bigarren urratsa -> emaitza`, erabili `(+ _ _ +)` maskarak sekuentziak desegituratzeko eta kendu `_ =` sententzia sekuentzialetan (edo baztertu `-> ()` bidez).
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `pool`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 31.2. Artefaktu natiboak, inportazioa eta `pool` APIaren katalogo osoa

`ridgun-libs`-en, **`pool`** lehen mailako **lib** bat da, `src/main/ridgun/lib/pool.ridgun` bidean kokatua (`AGENT` domeinua). `stable bundle`-ekin konpilatzean, formatu natibo bakarrean paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/pool.ridgunlib` | Banaketa eta inportazio zuzena `import pool` bidez |

> Lib bakoitzak bere izen-espazioa deklaratzen du `module :: pool` bidez: nahikoa da goiburuan `import pool` (edo `import pool as alias`) idaztea eta bere funtzioei zuriune naturalekin (`nire funtzioa x`) eta `->` hodiekin (`x nire funtzioa -> emaitza`) deitzea.

### 31.2.1. `pool`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `Pool / pool size / pool agents` | Agente kopuru finkoko `AgentPool` bat, bere tamaina eta bere agenteak |
| `pool ask shard` | Eskaera-erantzuna gakoaren arabera aukeratutako agentearekin: gako bera beti agente berera iristen da |
| `pool broadcast` | Mezu bat bidaltzen die pooleko agente guztiei |
| `pool drain all / pool drain ready` | Prest dauden erantzunak biltzen ditu, blokeatu gabe |
| `pool shutdown` | Pooleko agente guztiak gelditzen ditu |

### 31.2.2. `src/main/ridgun/lib/pool.ridgun`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/pool.ridgun` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`1` mota, `0` eragile eta `15` funtzio):

**`pool`-eko mota aljebraikoak eta erregistroak (`type`):**

```ridgun
type AgentPool = Pool Int [Agent]
```

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
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

## 31.3. `pool` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `pool` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test pool.ridgun`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 31.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `pool` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `pool` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import pool

fn :: despachar a shard AgentPool Int String => String
      despachar a shard p hash_clave msg =
        pool ask shard p hash_clave msg
```

### 31.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`pool` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 38 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import pool

fn :: difundir y cerrar AgentPool String => ()
      difundir y cerrar p evento =
        pool broadcast p evento
        pool shutdown p
```

### 31.3.3. 3. adibidea: Aktore-konbinatzaileak (`agent ask`, `agent try ask`, `agent send batch`, `agent map batch`, `agent drain ready`), zatikatutako pool-ak eta konexio-erreaktorea

Adibide praktiko honetan `pool` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 31.3.4. 4. adibidea: Agenteen bizi-zikloa (`is agent alive`, `agent status`, `stop agent`) eta egoera isolatuko agente kontagailua (`new counter agent`)

Adibide praktiko honetan `pool` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 31.3.5. 5. adibidea: *Append-only* egunkari-agentea (`new log agent`) eta mezu-igorpenezko memoriako gako-balio biltegia (`new kv agent`)

Adibide praktiko honetan `pool` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 31.3.6. 6. adibidea: Gako bidezko bideratze determinista (`pool ask shard`), hedapen masiboa (`pool broadcast`), hustuketa ez-blokeatzailea (`pool drain all`) eta itzaltzea (`pool shutdown`)

Adibide praktiko honetan `pool` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

## 31.4. Kaputaren azpian: nola dagoen eraikia `pool` Ridgun hutsean (`src/main/ridgun/lib/pool.ridgun`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/pool.ridgun` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 31.4.1. Barne-inplementazioa: Pool Size, Agent Selection, and Request-Reply by Key

Ikusi nola `pool.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 31.4.2. Barne-inplementazioa: Broadcast, Non-Blocking Drain, and Shutdown

Ikusi nola `pool.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

## 31.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `pool`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: Agente kopurua poola eraikitzean finkatzen da; beraz, poolaren memoria mugatua da, eta `abs(key) % size` bidezko bideratzea determinista da: gako bera beti agente berera iristen da.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/pool.ridgun`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test pool.ridgun` suite automatizatuaren bidez.

### `pool`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import pool` fitxategiaren hasieran** eta deitu bere funtzioei zuriuneekin, deklaratuta dauden bezala, zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `pool`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `pool`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `pool` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**32. kapituluan** **`net_agent`** lib-a sakonki esploratuko dugu (`net_agent` lib-a — Sare-konexioen Gainbegiralea eta Gertaera-zubi Ez-blokeatzailea).
