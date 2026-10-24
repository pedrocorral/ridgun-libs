# 32. kapitulua: `net_agent` lib-a — Sare-konexioen Gainbegiralea eta Gertaera-zubi Ez-blokeatzailea

## 32.1. Zergatik existitzen da `net_agent` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `net_agent` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `net_agent`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: **Solstice** bezalako benetako zerbitzari batean, TCP konexioak onartzea zati erraza da; zailena aldi bereko bezeroen gehienekoa mugatzea, bezero zonbi geldoak deskonektatzea (*idle timeout*) eta `ppoll` begizta zure aktoreekin deskribatzaile-ihesik gabe lotzea da.

**`net_agent`** lib-ak `ridgun-libs`-en zirkulua ixten du **`posix`**, **`socket`** eta **`agent`** batuz: gainbegiratutako konexio-taulak (`NetSupervisor`) kudeatzen ditu, konkurrentzia-mugak (`max_conns`) aplikatzen ditu, konexio geldoak garbitzen ditu (`net evict idle`) eta nukleoko deskribatzaileen gertaerak gertaera tipatuetan (`NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout`, `NetEvError`) bihurtzen ditu, muturretik muturrerako TCP oihartzun-urrats oso batez (`net tcp echo step`) gain.

Ekosistema tradizional batean, **`AGENT`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`net_agent`** lib-ak (`src/main/ridgun/lib/net_agent.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Funtzio osoak eta kontratu esplizituak (`=>`)**: `net_agent`-eko funtzio bakar batek ere ez du ezkutuko salbuespenik jaurtitzen, ezta `null` erabiltzen ere. Muga-kasu orok dokumentatutako balio bat edo batura-mota aljebraiko bat (`Option`, `Result`) itzultzen du.
2. **Zero C kode eta zero `libc`**: `net_agent`-eko kode guztia zuzenean ELF64 makina-kode natibora konpilatzen da, `ridgunc`-ek egiaztatuta.
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `net_agent`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 32.2. Artefaktu natiboak, inportazioa eta `net_agent` APIaren katalogo osoa

`ridgun-libs`-en, **`net_agent`** lehen mailako **lib** bat da, `src/main/ridgun/lib/net_agent.rg` bidean kokatua (`AGENT` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/net_agent.rglib` | Banaketa eta inportazio zuzena `import net_agent` bidez |
| **Fitxategi konpilatua** | `target/net_agent.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libnet_agent.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import net_agent` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

### 32.2.1. `net_agent`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `net supervisor new : Int -> Int -> NetSupervisor` | `max_conns` muga eta `idle_timeout_ms` geldotasun-epemuga dituen konexio-gainbegiralea sortzen du |
| `net register conn / net record rx / net record tx / net close conn` | Onartutako socketak erregistratu, byte/jarduera kontagailuak eguneratu eta parekoak ixten ditu |
| `net evict idle : NetSupervisor -> Int -> (NetSupervisor, [Int])` | `idle_timeout_ms` baino gehiago geldirik dauden konexioak itxi eta kanporatzen ditu, FDak itzuliz |
| `net poll fd : Int -> Bool -> Int -> NetEvent` | `NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout` edo `NetEvError` igortzen duen `wait fd` zubia |
| `net tcp echo step : String -> Int -> (Int, String)` | Muturretik muturrerako TCP loopback urrats osoa (`listen/connect/accept/supervise/echo`) |

### 32.2.2. `src/main/ridgun/lib/net_agent.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/net_agent.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`2` mota, `0` eragile eta `8` funtzio):

**`net_agent`-eko mota aljebraikoak eta erregistroak (`type`):**

```ridgun
type ConnSlot = ConnSlot Int Agent
type StepOutcome = ConnKeep ConnSlot String | ConnClosed
```

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
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

## 32.3. `net_agent` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `net_agent` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test net_agent.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 32.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `net_agent` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `net_agent` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

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

### 32.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`net_agent` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import net_agent

fn :: probar puente tcp supervisado () => (Int, String)
      probar puente tcp supervisado =
        net tcp echo step "ping-supervisado" 1000
```

### 32.3.3. 3. adibidea: Aktore-konbinatzaileak (`agent ask`, `try ask`, `send batch`, `map batch`, `drain ready`), zatikatutako pool-ak eta konexio-erreaktorea

Adibide praktiko honetan `net_agent` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 32.3.4. 4. adibidea: Agenteen bizi-zikloa (`is agent alive`, `agent status`, `stop agent`) eta egoera isolatuko agente kontagailua (`new counter agent`)

Adibide praktiko honetan `net_agent` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 32.3.5. 5. adibidea: *Append-only* egunkari-agentea (`new log agent`) eta mezu-igorpenezko memoriako gako-balio biltegia (`new kv agent`)

Adibide praktiko honetan `net_agent` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 32.3.6. 6. adibidea: Deskribatzaileen zundaketa ez-blokeatzailea (`conn poll step`), konexio-taularen ekorketa (`reactor sweep`) eta itzaltze garbia (`reactor shutdown`)

Adibide praktiko honetan `net_agent` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

## 32.4. Kaputaren azpian: nola dagoen eraikia `net_agent` Ridgun hutsean (`src/main/ridgun/lib/net_agent.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/net_agent.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 32.4.1. Barne-inplementazioa: Core Implementation Part 1

Ikusi nola `net_agent.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 32.4.2. Barne-inplementazioa: Core Implementation Part 2

Ikusi nola `net_agent.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

## 32.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `net_agent`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: Deskribatzaileen agorpenaren aurkako babes automatikoa (`max_conns`), konexio geldoen kanporatze determinista eta socketen itxiera bermatua `net tcp echo step`-en.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/net_agent.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test net_agent.rg` suite automatizatuaren bidez.

### `net_agent`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import net_agent` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `net_agent`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `net_agent`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `net_agent` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

Osatu duzu **`ridgun-libs`-eko 32 lib estandarren** ibilbide sakona! Orain esku artean dituzu Ridgun hutsean aplikazio eta sistema-tresna osoak eraikitzeko pieza guztiak.
