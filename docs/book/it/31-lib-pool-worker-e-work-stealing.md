# Capitolo 31: La lib `pool` — Pool di Agenti: Sharding per Chiave, Broadcast e Svuotamento Non Bloccante

## 31.1. Perché esiste la lib `pool`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `pool` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `pool`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: avviare un nuovo thread o attore per ogni richiesta in ingresso senza un limite superiore (`unbounded spawning`) fa sì che un picco di traffico esaurisca la memoria in pochi secondi (*Out Of Memory*).

La lib **`pool`** raggruppa un numero fisso di agenti in un `AgentPool`: `pool ask shard` invia ogni richiesta all'agente scelto in base alla sua chiave, così la stessa chiave raggiunge sempre lo stesso agente; `pool broadcast` invia un messaggio a ogni agente; `pool drain all` raccoglie, senza bloccarsi, le risposte che sono pronte; e `pool shutdown` li arresta tutti.

In un ecosistema tradizionale, risolvere i compiti del dominio **`AGENT`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`pool`** (`src/main/ridgun/lib/pool.ridgun`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import pool` (o `import pool as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: pool` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `pool` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 31.2. Artefatti nativi, importazione e catalogo completo dell'API di `pool`

In `ridgun-libs`, **`pool`** è una **lib** di prima classe situata in `src/main/ridgun/lib/pool.ridgun` (dominio `AGENT`). Compilando con `stable bundle`, viene impacchettata in un artefatto nativo:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/pool.ridgunlib` | Distribuzione e importazione diretta con `import pool` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: pool`: basta scrivere `import pool` (o `import pool as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 31.2.1. Riepilogo delle famiglie funzionali di `pool`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `Pool / pool size / pool agents` | Un `AgentPool` con un numero fisso di agenti, la sua dimensione e i suoi agenti |
| `pool ask shard` | Richiesta-risposta con l'agente scelto in base alla chiave: la stessa chiave raggiunge sempre lo stesso agente |
| `pool broadcast` | Invia un messaggio a ogni agente del pool |
| `pool drain all / pool drain ready` | Raccoglie le risposte che sono pronte, senza bloccarsi |
| `pool shutdown` | Arresta ogni agente del pool |

### 31.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/pool.ridgun`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/pool.ridgun` (`1` tipi, `0` operatori e `15` funzioni):

**Tipi algebrici e record (`type`) di `pool`:**

```ridgun
type AgentPool = Pool Int [Agent]
```

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
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

## 31.3. Esplorare `pool` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `pool` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test pool.ridgun`.

### 31.3.1. Esempio 1: Flusso principale in stile tabulare con `pool`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `pool` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import pool

fn :: despachar a shard AgentPool Int String => String
      despachar a shard p hash_clave msg =
        pool ask shard p hash_clave msg
```

### 31.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `pool` è progettata per comporsi con le guardie booleane `|` e con il resto delle 38 lib di `ridgun-libs`:

```ridgun
import pool

fn :: difundir y cerrar AgentPool String => ()
      difundir y cerrar p evento =
        pool broadcast p evento
        pool shutdown p
```

### 31.3.3. Esempio 3: Combinatori di attori (`agent ask`, `agent try ask`, `agent send batch`, `agent map batch`, `agent drain ready`), pool partizionati e reattore di connessioni

In questo esempio pratico esploriamo in modo esaustivo come si comporta `pool` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 31.3.4. Esempio 4: Ciclo di vita degli agenti (`is agent alive`, `agent status`, `stop agent`) e agente contatore con stato isolato (`new counter agent`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `pool` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 31.3.5. Esempio 5: Agente di registro *append-only* (`new log agent`) e store chiave-valore in memoria tramite scambio di messaggi (`new kv agent`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `pool` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 31.3.6. Esempio 6: Instradamento deterministico per chiave (`pool ask shard`), broadcast massivo (`pool broadcast`), drenaggio non bloccante (`pool drain all`) e arresto (`pool shutdown`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `pool` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

## 31.4. Sotto il cofano: come è costruita `pool` in Ridgun puro (`src/main/ridgun/lib/pool.ridgun`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/pool.ridgun` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 31.4.1. Implementazione interna: Pool Size, Agent Selection, and Request-Reply by Key

Nota come `pool.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 31.4.2. Implementazione interna: Broadcast, Non-Blocking Drain, and Shutdown

Nota come `pool.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

## 31.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `pool`

- **Garanzia algoritmica e di sicurezza**: Il numero di agenti è fissato quando il pool viene costruito, quindi la memoria del pool è limitata, e l'instradamento tramite `abs(key) % size` è deterministico: la stessa chiave raggiunge sempre lo stesso agente.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/pool.ridgun` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test pool.ridgun`.

### Le 5 Regole d'Oro quando programmi con `pool`

1. **Dichiara `import pool` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `pool` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `pool` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `pool` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 32** passeremo a esplorare in profondità la lib **`net_agent`** (La lib `net_agent` — Supervisore di Connessioni di Rete e Ponte di Eventi Non Bloccante).
