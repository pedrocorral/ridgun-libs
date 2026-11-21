# 32. kapitulua: `net_agent` lib-a — Agente bat Konexio bakoitzeko: Zundaketa Ez-blokeatzailea eta Erreaktorearen Ekorketa

## 32.1. Zergatik existitzen da `net_agent` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `net_agent` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `net_agent`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: zerbitzari batean, TCP konexioak onartzea zati erraza da; zailena konexio bakoitzaren egoera bereizita gordetzea, besteak blokeatu gabe irakurtzea eta idaztea, eta konexio bat amaitzean deskribatzaile bakoitza ixtea eta agente bakoitza gelditzea da.

**`net_agent`** lib-ak `ridgun-libs`-en zirkulua ixten du **`posix`**, **`socket`** eta **`agent`** batuz: `ConnSlot` batek konexio-deskribatzaile bat eta haren egoera gordetzen duen agentea parekatzen ditu; `conn poll step`-ek deskribatzailea blokeatu gabe zundatzen du, iristen dena agenteari pasatzen dio eta haren erantzuna idazten du bueltan; `reactor sweep`-ek gauza bera egiten du konexio-taula oso baterako eta itxitakoak kentzen ditu; eta `reactor shutdown`-ek deskribatzaile guztiak ixten ditu eta agente guztiak gelditzen ditu.

Ekosistema tradizional batean, **`AGENT`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`net_agent`** lib-ak (`src/main/ridgun/lib/net_agent.ridgun`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Deklaratu `import net_agent` (edo `import net_agent as alias`) fitxategiaren hasieran**: lib bakoitzak `module :: net agent` izen-espazioa definitzen du eta `--strict` moduan hitz anitzeko funtzioei zuriune naturalekin deitzen zaie beti.
2. **Kateatu zure datu-hodiak ezkerretik eskuinera `->` bidez**: idatzi `sarrera lehen urratsa -> bigarren urratsa -> emaitza`, erabili `(+ _ _ +)` maskarak sekuentziak desegituratzeko eta kendu `_ =` sententzia sekuentzialetan (edo baztertu `-> ()` bidez).
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `net_agent`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 32.2. Artefaktu natiboak, inportazioa eta `net_agent` APIaren katalogo osoa

`ridgun-libs`-en, **`net_agent`** lehen mailako **lib** bat da, `src/main/ridgun/lib/net_agent.ridgun` bidean kokatua (`AGENT` domeinua). `stable bundle`-ekin konpilatzean, formatu natibo bakarrean paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/net_agent.ridgunlib` | Banaketa eta inportazio zuzena `import net_agent` bidez |

> Lib bakoitzak bere izen-espazioa deklaratzen du `module :: net agent` bidez: nahikoa da goiburuan `import net_agent` (edo `import net_agent as alias`) idaztea eta bere funtzioei zuriune naturalekin (`nire funtzioa x`) eta `->` hodiekin (`x nire funtzioa -> emaitza`) deitzea.

### 32.2.1. `net_agent`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `ConnSlot / StepOutcome` | Konexio-deskribatzaile bat bere agentearekin, eta urrats baten emaitza: `ConnKeep` edo `ConnClosed` |
| `conn poll step` | Konexio bat blokeatu gabe zundatzen du, iristen dena bere agenteari pasatzen dio eta erantzuna bidaltzen du |
| `reactor sweep` | Urrats bat taula bateko konexio bakoitzaren gainean; itxitakoak taulatik irteten dira |
| `reactor shutdown` | Deskribatzaile guztiak ixten ditu eta agente guztiak gelditzen ditu |

### 32.2.2. `src/main/ridgun/lib/net_agent.ridgun`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/net_agent.ridgun` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`2` mota, `0` eragile eta `10` funtzio):

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
| `5` | `fn :: conn write timeout ms` | `Int` |
| `6` | `fn :: conn drain outbound Int Agent Option` | `StepOutcome` |
| `7` | `fn :: conn after write Int Agent String (Int Int)` | `StepOutcome` |
| `8` | `fn :: reactor sweep [ConnSlot]` | `[ConnSlot]` |
| `9` | `fn :: reactor sweep next StepOutcome [ConnSlot]` | `[ConnSlot]` |
| `10` | `fn :: reactor shutdown [ConnSlot]` | `()` |

---

## 32.3. `net_agent` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `net_agent` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test net_agent.ridgun`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 32.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `net_agent` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `net_agent` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import net_agent

fn :: barrer conexiones activas [ConnSlot] => [ConnSlot]
      barrer conexiones activas tabla =
        tabla reactor sweep
```

### 32.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`net_agent` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 38 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import net_agent

fn :: apagar reactor [ConnSlot] => ()
      apagar reactor tabla =
        tabla reactor shutdown
```

### 32.3.3. 3. adibidea: Aktore-konbinatzaileak (`agent ask`, `agent try ask`, `agent send batch`, `agent map batch`, `agent drain ready`), zatikatutako pool-ak eta konexio-erreaktorea

Adibide praktiko honetan `net_agent` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 32.3.4. 4. adibidea: Agenteen bizi-zikloa (`is agent alive`, `agent status`, `stop agent`) eta egoera isolatuko agente kontagailua (`new counter agent`)

Adibide praktiko honetan `net_agent` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 32.3.5. 5. adibidea: *Append-only* egunkari-agentea (`new log agent`) eta mezu-igorpenezko memoriako gako-balio biltegia (`new kv agent`)

Adibide praktiko honetan `net_agent` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 32.3.6. 6. adibidea: Deskribatzaileen zundaketa ez-blokeatzailea (`conn poll step`), konexio-taularen ekorketa (`reactor sweep`) eta itzaltze garbia (`reactor shutdown`)

Adibide praktiko honetan `net_agent` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 32.3.7. 7. adibidea: Datuen bidea benetako TCP konexio baten gainean: `conn poll step`, agentearen erantzuna eta `reactor sweep` ixtean

Adibide praktiko honetan `net_agent` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test net agent data path => ()
      test net agent data path =
        l_res = sys tcp listen "127.0.0.1" 0 16
        sock rc l_res -> assert int equals 0 "listen on an ephemeral port"
        lfd   = sock fd l_res
        c_res = sys tcp connect "127.0.0.1" (sys local port lfd) 500
        sock rc c_res -> assert int equals 0 "client connects"
        cfd   = sock fd c_res
        a_res = sys accept lfd 500
        sock accept rc a_res -> assert int equals 0 "server accepts"
        sfd   = sock accept fd a_res
        ag    = agent (ag echo conn step) (CounterState 0)
        slot  = ConnSlot sfd ag

        outcome text (conn poll step slot) -> assert str eq "keep:" "no data: the slot is kept and nothing is written"
        sock recv rc (sys recv cfd 16 20) -> assert int equals (0 - 2) "no data: the client receives nothing"

        s1 = sys send cfd "ping" 500
        sock rc s1 -> assert int equals 0 "client sends ping"
        step until reply slot cfd 50 -> assert str eq "keep:echo:1:ping" "the data reaches the agent and its reply is written"
        sock recv data (sys recv cfd 64 500) -> assert str eq "echo:1:ping" "the client reads the reply"

        s2 = sys send cfd "pong" 500
        sock rc s2 -> assert int equals 0 "client sends pong"
        step until reply slot cfd 50 -> assert str eq "keep:echo:2:pong" "the agent keeps the state of its connection"
        sock recv data (sys recv cfd 64 500) -> assert str eq "echo:2:pong" "the client reads the second reply"

        agent list len (reactor sweep [slot]) 0 -> assert int equals 1 "reactor sweep keeps a live connection"
        is agent alive ag -> assert true "the agent of a live connection is running"

        sys close cfd
        sys poll sfd 1 500 -> closed_ev
        agent list len (reactor sweep [slot]) 0 -> assert int equals 0 "reactor sweep drops a connection closed by the peer"
        is agent alive ag -> assert false "the agent stops when its connection closes"
        sys close lfd
        ()
```

### 32.3.8. 8. adibidea: Socketaren bufferrak baino erantzun handiagoa eta irakurtzen ez duen parekoa (`conn write timeout ms`)

Adibide praktiko honetan `net_agent` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test net agent large reply and slow peer => ()
      test net agent large reply and slow peer =
        conn write timeout ms -> assert int equals 1000 "a step waits at most 1000 ms for a peer to take a reply"
        l_res = sys tcp listen "127.0.0.1" 0 16
        lfd   = sock fd l_res
        port  = sys local port lfd

        c1    = sock fd (sys tcp connect "127.0.0.1" port 500)
        s1    = sock accept fd (sys accept lfd 500)
        ag1   = agent (ag big reply) (CounterState 0)
        slot1 = ConnSlot s1 ag1
        rd    = agent (ag read count)
        send c1 4194304 to rd
        q1    = sys send c1 "big" 500
        sock rc q1 -> assert int equals 0 "client asks for the 4 MiB reply"
        str len (step until reply slot1 c1 50) -> assert int equals (5 + 4194304) "a 4 MiB reply is written whole while the peer reads"
        receive from rd -> assert int equals 4194304 "the peer reads the 4 MiB"
        stop rd
        is agent alive ag1 -> assert true "the agent of the reading peer keeps running"
        reactor shutdown [slot1]
        sys close c1

        c2    = sock fd (sys tcp connect "127.0.0.1" port 500)
        s2    = sock accept fd (sys accept lfd 500)
        ag2   = agent (ag big reply) (CounterState 0)
        slot2 = ConnSlot s2 ag2
        q2    = sys send c2 "huge" 500
        sock rc q2 -> assert int equals 0 "client asks for the 16 MiB reply and does not read it"
        t0    = sys time ms
        step until reply slot2 c2 50 -> assert str eq "closed" "a peer that does not read is closed, not served a cut reply"
        took  = (sys time ms) - t0
        took < 5000 -> assert true "the step returns after the write timeout instead of blocking"
        is agent alive ag2 -> assert false "the agent of the closed connection is stopped"
        agent list len (reactor sweep []) 0 -> assert int equals 0 "an empty table stays empty"
        sys close c2
        sys close lfd
        ()
```

---

## 32.4. Kaputaren azpian: nola dagoen eraikia `net_agent` Ridgun hutsean (`src/main/ridgun/lib/net_agent.ridgun`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/net_agent.ridgun` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 32.4.1. Barne-inplementazioa: One Step of a Connection: Poll, Pass to the Agent, Write the Reply

Ikusi nola `net_agent.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

-- The longest a step waits for a peer to take a reply (milliseconds).
fn :: conn write timeout ms => Int
      conn write timeout ms =  1000

fn :: conn drain outbound Int Agent Option => StepOutcome
      conn drain outbound fd ag None = ConnKeep (ConnSlot fd ag) ""
      conn drain outbound fd ag (Some resp) =
        resp conn cast str -> s
        conn after write fd ag s (sys send fd s (conn write timeout ms))

-- The reply is written whole or the connection is closed: a peer that does not read
-- cannot hold the reactor longer than `conn write timeout ms`, and never gets a cut reply.
fn :: conn after write Int Agent String (Int Int) => StepOutcome
      conn after write fd ag s (rc, sent) =
        | rc == 0 and sent == (str len s) = ConnKeep (ConnSlot fd ag) s
        | otherwise =
          sys close fd -> ()
          stop ag
          ConnClosed
```

### 32.4.2. Barne-inplementazioa: Reactor Sweep and Shutdown

Ikusi nola `net_agent.ridgun`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

## 32.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `net_agent`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: Ixten den edo huts egiten duen konexio bat taulatik irteten da hura ikusten duen ekorketan, deskribatzailea itxita eta agentea geldituta, eta `reactor shutdown`-ek gauza bera egiten du gainerako guztiekin; beraz, ez dago deskribatzaile-ihesik, ezta agente-ihesik ere.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/net_agent.ridgun`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test net_agent.ridgun` suite automatizatuaren bidez.

### `net_agent`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import net_agent` fitxategiaren hasieran** eta deitu bere funtzioei zuriuneekin, deklaratuta dauden bezala, zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `net_agent`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `net_agent`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `net_agent` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**33. kapituluan** **`ai`** lib-a sakonki esploratuko dugu (`ai` lib-a — AA Agenteak, Tool Calling, SSE Streaming-a, ReAct Mugatua, Segurtasun-Hesiketak, Mini-RAG eta MCP).
