# Capitolo 30: La lib `agent` — Modello Nativo ad Attori (`agent`, `send`, `receive`), Combinatori Richiesta-Risposta e Agenti Contatore, Log e Chiave-Valore

## 30.1. Perché esiste la lib `agent`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `agent` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `agent`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: condividere memoria mutabile tra thread con `Mutex`, `RwLock` e variabili di condizione è una fabbrica inesauribile di *deadlock* e race condition.

La lib **`agent`** sfrutta il **Modello Nativo di Agenti** di Ridgun (`agent`, `send ... to`, `receive from`, `try receive from`, `stop`) per offrire combinatori richiesta-risposta, bloccanti, non bloccanti o limitati da un timeout (`agent ask`, `agent try ask`, `ask int with timeout`), invio in batch e svuotamento (`agent send batch`, `agent map batch`, `agent drain ready`), ispezione del ciclo di vita (`is agent alive`, `agent status`, `stop agent`) e tre agenti con stato già pronti: un contatore, un log append-only e uno store chiave-valore in memoria.

In un ecosistema tradizionale, risolvere i compiti del dominio **`AGENT`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`agent`** (`src/main/ridgun/lib/agent.ridgun`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import agent` (o `import agent as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: agent` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `agent` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 30.2. Artefatti nativi, importazione e catalogo completo dell'API di `agent`

In `ridgun-libs`, **`agent`** è una **lib** di prima classe situata in `src/main/ridgun/lib/agent.ridgun` (dominio `AGENT`). Compilando con `stable bundle`, viene impacchettata in un artefatto nativo:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/agent.ridgunlib` | Distribuzione e importazione diretta con `import agent` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: agent`: basta scrivere `import agent` (o `import agent as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 30.2.1. Riepilogo delle famiglie funzionali di `agent`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `agent ask / agent try ask / ask int / ask str / ask int with timeout / ask str with timeout` | Richiesta-risposta con un agente: bloccante, non bloccante o limitata da un timeout |
| `agent send batch / agent map batch / agent receive count / agent drain ready / relay int / relay str` | Invia un batch di messaggi, raccoglie le risposte e inoltra un risultato da un agente a un altro |
| `is agent alive / agent status / stop agent / agent stop all` | Ispezione del ciclo di vita e arresto ordinato, con un `AgentStatus` tipizzato |
| `new counter agent / counter add / counter get / counter reset` | Un contatore mantenuto dentro un agente |
| `new log agent / log append / log read / log clear` | Un log append-only mantenuto dentro un agente |
| `new kv agent / agent kv put / agent kv get / agent kv delete / agent kv has / agent kv count / agent kv keys / agent kv clear` | Uno store chiave-valore in memoria mantenuto dentro un agente |

### 30.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/agent.ridgun`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/agent.ridgun` (`7` tipi, `0` operatori e `65` funzioni):

**Tipi algebrici e record (`type`) di `agent`:**

```ridgun
type AgentStatus = AgentRunning | AgentStopped | AgentTimedOut Int | AgentFailed String
type AgentReply  = ReplyInt Int | ReplyStr String | ReplyBool Bool | ReplyEmpty | ReplyStopped | ReplyTimeout Int | ReplyError String
type CounterState = cnt_val: Int
type KvCmd        = KvPut String String | KvGet String | KvDel String | KvHas String | KvCount | KvKeys | KvClear
type KvEntry      = kv_k: String, kv_v: String
type KvState      = kv_size: Int, kv_items: [KvEntry]
type LogState     = log_sep: String, log_buf: String
```

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
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

## 30.3. Esplorare `agent` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `agent` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test agent.ridgun`.

### 30.3.1. Esempio 1: Flusso principale in stile tabulare con `agent`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `agent` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

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

### 30.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `agent` è progettata per comporsi con le guardie booleane `|` e con il resto delle 38 lib di `ridgun-libs`:

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

### 30.3.3. Esempio 3: Combinatori di attori (`agent ask`, `agent try ask`, `agent send batch`, `agent map batch`, `agent drain ready`), pool partizionati e reattore di connessioni

In questo esempio pratico esploriamo in modo esaustivo come si comporta `agent` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 30.3.4. Esempio 4: Ciclo di vita degli agenti (`is agent alive`, `agent status`, `stop agent`) e agente contatore con stato isolato (`new counter agent`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `agent` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 30.3.5. Esempio 5: Agente di registro *append-only* (`new log agent`) e store chiave-valore in memoria tramite scambio di messaggi (`new kv agent`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `agent` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

## 30.4. Sotto il cofano: come è costruita `agent` in Ridgun puro (`src/main/ridgun/lib/agent.ridgun`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/agent.ridgun` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 30.4.1. Implementazione interna: Status & Reply Formatting

Nota come `agent.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 30.4.2. Implementazione interna: Core Combinators (`agent ask`, `agent try ask`, `agent send batch`, `agent receive count`, `agent map batch`, `agent drain ready`)

Nota come `agent.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 30.4.3. Implementazione interna: Stateful Counter Agent (`new counter agent`, `counter add`, `counter get`, `counter reset`)

Nota come `agent.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 30.4.4. Implementazione interna: Stateful In-Memory Key-Value Agent (`new kv agent`, `agent kv put`, `agent kv get`, `agent kv delete`, `agent kv has`, `agent kv count`, `agent kv keys`, `agent kv clear`)

Nota come `agent.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

## 30.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `agent`

- **Garanzia algoritmica e di sicurezza**: Zero memoria mutabile condivisa tra attori: ogni messaggio viene trasferito per valore / Copy-on-Write e `stop` libera la regione dell'agente in modo deterministico.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/agent.ridgun` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test agent.ridgun`.

### Le 5 Regole d'Oro quando programmi con `agent`

1. **Dichiara `import agent` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `agent` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `agent` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `agent` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 31** passeremo a esplorare in profondità la lib **`pool`** (La lib `pool` — Pool Limitato di Agenti Worker e Sharding per Chiave).
