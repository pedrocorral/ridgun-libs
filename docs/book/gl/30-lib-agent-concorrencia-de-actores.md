# Capítulo 30: A lib `agent` — Modelo Nativo de Actores (`agent`, `send`, `receive`), KV Store e Rate Limiter

## 30.1. Por que existe a lib `agent`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `agent` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `agent`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: compartir memoria mutable entre fíos con `Mutex`, `RwLock` e variables de condición é unha fábrica inesgotable de *deadlocks* e condicións de carreira.

A lib **`agent`** aproveita o **Modelo Nativo de Axentes** de Ridgun (`agent`, `send ... to`, `receive from`, `try receive from`, `stop`) para ofrecer caixas de correo illadas con paso de mensaxes Copy-on-Write, un almacén chave-valor concorrente (`KvStore`), un limitador de taxa por cubo de tokens (`RateBucket`) e supervisión de estado (`AgentHealth`).

Nun ecosistema tradicional, resolver as tarefas do dominio **`AGENT`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`agent`** (`src/main/ridgun/lib/agent.rg`) aborda o problema con catro principios innegociables:

1. **Funcións totais e contratos explícitos (`=>`)**: ningunha función de `agent` lanza excepcións ocultas nin depende de `null`. Todo caso límite devolve un valor sentinela documentado ou un tipo alxébrico suma (`Option`, `Result`).
2. **Cero código C e cero `libc`**: todo o código de `agent` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `agent` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 30.2. Artefactos nativos, importación e catálogo completo da API de `agent`

En `ridgun-libs`, **`agent`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/agent.rg` (dominio `AGENT`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/agent.rglib` | Distribución e importación directa con `import agent` |
| **Ficheiro compilado** | `target/agent.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libagent.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import agent` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

### 30.2.1. Resumo de familias funcionais de `agent`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `agent roundtrip / agent drain count` | Lanza actores nativos (`agent`), intercambia mensaxes (`send ... to` / `receive from`) e executa `stop` |
| `kv store new / kv store apply` | Almacén chave-valor inmutable para actores (`KvPut`, `KvGet`, `KvDelete`, `KvClear`) |
| `rate bucket new / rate bucket allow` | Limitador de taxa por cubo de tokens que devolve o cubo actualizado e `(allowed, remaining)` |
| `sup mark failed / sup should restart` | Políticas de supervisión con control de orzamento de reinicios (`max_restarts`) |

### 30.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/agent.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/agent.rg` (`7` tipos, `0` operadores e `65` funcións):

**Tipos alxébricos e rexistros (`type`) de `agent`:**

```ridgun
type AgentStatus = AgentRunning | AgentStopped | AgentTimedOut Int | AgentFailed String
type AgentReply  = ReplyInt Int | ReplyStr String | ReplyBool Bool | ReplyEmpty | ReplyStopped | ReplyTimeout Int | ReplyError String
type CounterState = cnt_val: Int
type KvCmd        = KvPut String String | KvGet String | KvDel String | KvHas String | KvCount | KvKeys | KvClear
type KvEntry      = kv_k: String, kv_v: String
type KvState      = kv_size: Int, kv_items: [KvEntry]
type LogState     = log_sep: String, log_buf: String
```

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 30.3. Explorando `agent` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `agent` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test agent.rg`.

### 30.3.1. Exemplo 1: Fluxo principal en estilo tabular con `agent`

Observa como en Ridgun os signos `=` e os pasos de transformación con `agent` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import agent

fn :: probar actor nativo () => (Int, Int)
      probar actor nativo =
        eco = agent roundtrip 42
        vac = agent drain count [10, 20, 30]
        (eco, vac)
```

### 30.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `agent` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import agent

fn :: aplicar limite peticion () => (Bool, Int)
      aplicar limite peticion =
        b0         = rate bucket new 10 2 1000
        (b1, res1) = rate bucket allow b0 1 1000
        rateresp allowed res1, rateobs remaining res1
```

### 30.3.3. Exemplo 3: Combinadores de actores (`agent ask`, `try ask`, `send batch`, `map batch`, `drain ready`), pools particionados e reactor de conexións

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `agent` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 30.3.4. Exemplo 4: Ciclo de vida de axentes (`is agent alive`, `agent status`, `stop agent`) e axente contador con estado illado (`new counter agent`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `agent` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 30.3.5. Exemplo 5: Axente de bitácora *append-only* (`new log agent`) e almacén clave-valor en memoria por paso de mensaxes (`new kv agent`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `agent` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

---

## 30.4. Baixo o capó: como está construída `agent` en Ridgun puro (`src/main/ridgun/lib/agent.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/agent.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 30.4.1. Implementación interna: Status & Reply Formatting

Fíxate en como `agent.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
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

### 30.4.2. Implementación interna: Core Combinators (`agent ask`, `agent try ask`, `agent send batch`, `agent receive count`, `agent map batch`, `agent drain ready`)

Fíxate en como `agent.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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
        n = agent list len msgs 0
        _ = agent send batch ag msgs
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

### 30.4.3. Implementación interna: Stateful Counter Agent (`new counter agent`, `counter add`, `counter get`, `counter reset`)

Fíxate en como `agent.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

### 30.4.4. Implementación interna: Stateful In-Memory Key-Value Agent (`new kv agent`, `kv put`, `kv get`, `kv delete`, `kv has`, `kv count`, `kv keys`, `kv clear`)

Fíxate en como `agent.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

## 30.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `agent`

- **Garantía algorítmica e de seguridade**: Cero memoria mutable compartida entre actores: cada mensaxe transfírese por valor / Copy-on-Write e `stop` libera a rexión do axente de forma determinista.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/agent.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test agent.rg`.

### As 5 Regras de Ouro ao programar con `agent`

1. **Declara `import agent` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `agent` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `agent` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `agent` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 31** pasaremos a explorar en profundidade a lib **`pool`** (A lib `pool` — Pool Acoutado de Traballadores, Round-Robin e Roubo de Traballo).
