# Capítol 31: La lib `pool` — Pool Acotat de Treballadors, Round-Robin i Robatori de Treball

## 31.1. Per què existeix la lib `pool`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `pool` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `pool`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: llançar un fil o actor nou per cada petició entrant sense límit superior (`unbounded spawning`) fa que un pic de trànsit esgoti la memòria en segons (*Out Of Memory*).

La lib **`pool`** proporciona un despatxador de tasques amb **contrapressió explícita** (`PoolAccept`, `PoolRejectFull`), partició equilibrada de lots en $K$ carrils (`pool partition`), reequilibri per **robatori de treball (*work-stealing*)** (`pool steal rebalance`) i execució paral·lela sobre actors natius.

En un ecosistema tradicional, resoldre les tasques del domini **`AGENT`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`pool`** (`src/main/ridgun/lib/pool.rg`) aborda el problema amb quatre principis innegociables:

1. **Declara `import pool` (o `import pool as alias`) a l'inici del fitxer**: cada lib defineix el seu espai de noms `module :: pool` i en mode `--strict` les funcions multi-paraula s'invoquen sempre amb espais naturals.
2. **Encadena les teves canonades d'esquerra a dreta amb `->`**: escriu `entrada pas u -> pas dos -> resultat`, fes servir màscares `(+ _ _ +)` per desestructurar seqüències i omet `_ =` en sentències seqüencials (o descarta amb `-> ()`).
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `pool` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 31.2. Artefactes natius, importació i catàleg complet de l'API de `pool`

A `ridgun-libs`, **`pool`** és una **lib** de primera classe situada a `src/main/ridgun/lib/pool.rg` (domini `AGENT`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/pool.rglib` | Distribució i importació directa amb `import pool` |
| **Fitxer compilat** | `target/pool.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libpool.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Cada lib declara el seu propi espai de noms amb `module :: pool`: n'hi ha prou d'escriure `import pool` (o `import pool as alias`) a la capçalera i cridar les seves funcions amb espais naturals (`la meva funcio x`) i canonades `->` (`x la meva funcio -> resultat`).

### 31.2.1. Resum de famílies funcionals de `pool`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `pool new : Int -> Int -> PoolState` | Crea un pool acotat amb `workers` carrils i capacitat màxima `max_queue` |
| `pool submit : PoolState -> PoolTask -> (PoolState, PoolDecision)` | Encola una tasca en round-robin o retorna `PoolRejectFull` si està saturat |
| `pool partition / pool steal rebalance` | Reparteix lots entre $K$ treballadors i roba la meitat d'una cua sobrecarregada per a un treballador lliure |
| `pool map sum / pool parallel sum2` | Despatxa càrregues de treball en paral·lel sobre treballadors `agent` natius |

### 31.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/pool.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/pool.rg` (`1` tipus, `0` operadors i `14` funcions):

**Tipus algebraics i registres (`type`) de `pool`:**

```ridgun
type AgentPool = Pool Int [Agent]
```

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 31.3. Explorant `pool` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `pool` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test pool.rg`.

### 31.3.1. Exemple 1: Flux principal en estil tabular amb `pool`

Observa com en Ridgun els signes `=` i els passos de transformació amb `pool` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import pool

fn :: despachar a shard AgentPool Int String => String
      despachar a shard p hash_clave msg =
        pool ask shard p hash_clave msg
```

### 31.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `pool` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import pool

fn :: difundir y cerrar AgentPool String => ()
      difundir y cerrar p evento =
        pool broadcast p evento
        pool shutdown p
```

### 31.3.3. Exemple 3: Combinadors d'actors (`agent ask`, `try ask`, `send batch`, `map batch`, `drain ready`), pools particionats i reactor de connexions

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `pool` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 31.3.4. Exemple 4: Cicle de vida d'agents (`is agent alive`, `agent status`, `stop agent`) i agent comptador amb estat aïllat (`new counter agent`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `pool` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 31.3.5. Exemple 5: Agent de bitàcola *append-only* (`new log agent`) i magatzem clau-valor en memòria per pas de missatges (`new kv agent`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `pool` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 31.3.6. Exemple 6: Encaminament determinista per clau (`pool ask shard`), difusió massiva (`pool broadcast`), drenatge no bloquejant (`pool drain all`) i apagada (`pool shutdown`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `pool` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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
        pool broadcast p 1 -> ()
        pend = pool drain all p
        pool shutdown p -> ()
        (sz, r_a + r_b, pend)
```

---

## 31.4. Sota el capó: com està construïda `pool` en Ridgun pur (`src/main/ridgun/lib/pool.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/pool.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 31.4.1. Implementació interna: Core Implementation Part 1

Fixa't en com `pool.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
module :: pool

type AgentPool = Pool Int [Agent]

fn :: pool size AgentPool   => Int
      pool size (Pool sz _) =  sz

fn :: pool agents AgentPool    => [Agent]
      pool agents (Pool _ ags) =  ags

fn :: pool get agent [Agent]  Int => Agent
      pool get agent (ag:_)   0   =  ag
      pool get agent (_:rest) idx =  pool get agent rest (idx - 1)

fn :: pool abs Int => Int
      pool abs x
        | x < 0     = 0 - x
        | otherwise = x

fn :: pool ask shard AgentPool Int A => B
      pool ask shard (Pool size agents) key_hash msg =
        (pool abs key_hash) % size -> shard_idx
        pool get agent agents shard_idx -> target_ag
        ask target_ag msg

fn :: pool broadcast AgentPool       A   => ()
      pool broadcast (Pool _ agents) msg =  pool broadcast list agents msg
```

### 31.4.2. Implementació interna: Core Implementation Part 2

Fixa't en com `pool.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
fn :: pool broadcast list [Agent]   A   => ()
      pool broadcast list []        _   =  ()
      pool broadcast list (ag:rest) msg =
        send msg to ag
        pool broadcast list rest msg

fn :: pool drain ready Agent => [B]
      pool drain ready ag    =  pool drain ready loop ag []

fn :: pool drain ready loop Agent [B] => [B]
      pool drain ready loop ag acc =
        pool drain step ag (try receive from ag) acc

fn :: pool drain step Agent Option [B] => [B]
      pool drain step _ None acc = acc
      pool drain step ag (Some r) acc = pool drain ready loop ag (acc :: [r])

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

fn :: pool shutdown AgentPool       => ()
      pool shutdown (Pool _ agents) =  pool stop list agents
```

---

## 31.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `pool`

- **Garantia algorísmica i de seguretat**: Capacitat de cua estrictament acotada (`queued <= max_queue`) per protegir la memòria sota sobrecàrrega i repartiment determinista entre treballadors.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/pool.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test pool.rg`.

### Les 5 Regles d'Or en programar amb `pool`

1. **Declara `import pool` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `pool` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `pool` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `pool` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 32** passarem a explorar en profunditat la lib **`net_agent`** (La lib `net_agent` — Supervisor de Connexions de Xarxa i Pont d'Esdeveniments No Bloquejant).
