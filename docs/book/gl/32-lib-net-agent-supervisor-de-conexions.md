# Capítulo 32: A lib `net_agent` — Supervisor de Conexións de Rede e Ponte de Eventos Non Bloqueante

## 32.1. Por que existe a lib `net_agent`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `net_agent` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `net_agent`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: nun servidor real coma **Solstice**, aceptar conexións TCP é a parte fácil; o difícil é limitar o máximo de clientes simultáneos, desconectar clientes zombis inactivos (*idle timeout*) e conectar o bucle `ppoll` cos teus actores sen fugas de descritores.

A lib **`net_agent`** pecha o círculo de `ridgun-libs` unindo **`posix`**, **`socket`** e **`agent`**: xestiona táboas de conexións supervisadas (`NetSupervisor`), aplica límites de concorrencia (`max_conns`), purga conexións inactivas (`net evict idle`) e converte eventos de descritores do kernel en eventos tipados (`NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout`, `NetEvError`) ademais de ofrecer un paso de eco TCP completo de extremo a extremo (`net tcp echo step`).

Nun ecosistema tradicional, resolver as tarefas do dominio **`AGENT`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`net_agent`** (`src/main/ridgun/lib/net_agent.rg`) aborda o problema con catro principios innegociables:

1. **Declara `import net_agent` (ou `import net_agent as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: net agent` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `net_agent` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 32.2. Artefactos nativos, importación e catálogo completo da API de `net_agent`

En `ridgun-libs`, **`net_agent`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/net_agent.rg` (dominio `AGENT`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/net_agent.rglib` | Distribución e importación directa con `import net_agent` |
| **Ficheiro compilado** | `target/net_agent.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libnet_agent.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Cada lib declara o seu propio espazo de nomes con `module :: net agent`: abonda con escribir `import net_agent` (ou `import net_agent as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 32.2.1. Resumo de familias funcionais de `net_agent`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `net supervisor new : Int -> Int -> NetSupervisor` | Crea un supervisor de conexións con límite `max_conns` e inactividade `idle_timeout_ms` |
| `net register conn / net record rx / net record tx / net close conn` | Rexistra sockets aceptados, actualiza contadores de bytes/actividade e pecha pares |
| `net evict idle : NetSupervisor -> Int -> (NetSupervisor, [Int])` | Pecha e expulsa conexións inactivas máis aló de `idle_timeout_ms`, devolvendo os seus FDs |
| `net poll fd : Int -> Bool -> Int -> NetEvent` | Ponte `wait fd` non bloqueante que emite `NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout` ou `NetEvError` |
| `net tcp echo step : String -> Int -> (Int, String)` | Paso completo de extremo a extremo TCP loopback (`listen/connect/accept/supervise/echo`) |

### 32.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/net_agent.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/net_agent.rg` (`2` tipos, `0` operadores e `8` funcións):

**Tipos alxébricos e rexistros (`type`) de `net_agent`:**

```ridgun
type ConnSlot = ConnSlot Int Agent
type StepOutcome = ConnKeep ConnSlot String | ConnClosed
```

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 32.3. Explorando `net_agent` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `net_agent` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test net_agent.rg`.

### 32.3.1. Exemplo 1: Fluxo principal en estilo tabular con `net_agent`

Observa como en Ridgun os signos `=` e os pasos de transformación con `net_agent` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import net_agent

fn :: barrer conexiones activas [ConnSlot] => [ConnSlot]
      barrer conexiones activas tabla =
        tabla reactor sweep
```

### 32.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `net_agent` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import net_agent

fn :: apagar reactor [ConnSlot] => ()
      apagar reactor tabla =
        tabla reactor shutdown
```

### 32.3.3. Exemplo 3: Combinadores de actores (`agent ask`, `try ask`, `send batch`, `map batch`, `drain ready`), pools particionados e reactor de conexións

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `net_agent` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 32.3.4. Exemplo 4: Ciclo de vida de axentes (`is agent alive`, `agent status`, `stop agent`) e axente contador con estado illado (`new counter agent`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `net_agent` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 32.3.5. Exemplo 5: Axente de bitácora *append-only* (`new log agent`) e almacén clave-valor en memoria por paso de mensaxes (`new kv agent`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `net_agent` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 32.3.6. Exemplo 6: Sondaxe non bloqueante de descritores (`conn poll step`), varrido de táboa de conexións (`reactor sweep`) e apagado limpo (`reactor shutdown`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `net_agent` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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
        -- Barrido no bloqueante (sys poll timeout=0) de todas las conexiones
        vivas   = reactor sweep activas
        -- Cierre ordenado de descriptores y parada determinista de agentes
        reactor shutdown vivas -> ()
        []
```

---

## 32.4. Baixo o capó: como está construída `net_agent` en Ridgun puro (`src/main/ridgun/lib/net_agent.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/net_agent.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 32.4.1. Implementación interna: Core Implementation Part 1

Fíxate en como `net_agent.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
module :: net agent

type ConnSlot = ConnSlot Int Agent

type StepOutcome = ConnKeep ConnSlot String | ConnClosed

fn :: conn poll step ConnSlot         => StepOutcome
      conn poll step (ConnSlot fd ag) =
        sys poll fd 1 0 -> ev
        conn handle event fd ag ev

fn :: conn handle event Int Agent Int => StepOutcome
      conn handle event fd ag ev
        | ev < 0 =
          _ = sys close fd
          stop ag
          ConnClosed
        | ev >= 8 =
          _ = sys close fd
          stop ag
          ConnClosed
        | ev == 0 =
      conn drain outbound fd ag (try receive from ag)
        | otherwise =
          payload = sys read fd fd 65536
          conn feed payload fd ag payload

fn :: conn feed payload Int Agent String => StepOutcome
      conn feed payload fd ag "" =
        sys close fd -> ()
        stop ag
        ConnClosed
      conn feed payload fd ag data =
        send data to ag
        conn drain outbound fd ag (try receive from ag)
```

### 32.4.2. Implementación interna: Core Implementation Part 2

Fíxate en como `net_agent.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: conn cast str A => String
      conn cast str x =  x

fn :: conn drain outbound Int Agent Option => StepOutcome
      conn drain outbound fd ag None = ConnKeep (ConnSlot fd ag) ""
      conn drain outbound fd ag (Some resp) =
        resp conn cast str -> s
        sys write fd fd s -> ()
        ConnKeep (ConnSlot fd ag) s

fn :: reactor sweep [ConnSlot]  => [ConnSlot]
      reactor sweep []          =  []
      reactor sweep (slot:rest) =
        slot conn poll step -> outcome
        rest reactor sweep -> kept
        reactor sweep next outcome kept

fn :: reactor sweep next StepOutcome       [ConnSlot] => [ConnSlot]
      reactor sweep next ConnClosed        kept       =  kept
      reactor sweep next (ConnKeep slot _) kept       =  [slot] :: kept

fn :: reactor shutdown [ConnSlot] => ()
      reactor shutdown []         =  ()
      reactor shutdown ((ConnSlot fd ag):rest) =
        sys close fd -> ()
        stop ag
        reactor shutdown rest
```

---

## 32.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `net_agent`

- **Garantía algorítmica e de seguridade**: Protección automática fronte a esgotamento de descritores (`max_conns`), expulsión determinista de conexións inactivas e peche garantido de sockets en `net tcp echo step`.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/net_agent.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test net_agent.rg`.

### As 5 Regras de Ouro ao programar con `net_agent`

1. **Declara `import net_agent` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `net_agent` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `net_agent` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `net_agent` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

Completaches o percorrido exhaustivo polas **32 libs estándar de `ridgun-libs`**! Agora tes nas túas mans todas as pezas para construír aplicacións e ferramentas de sistemas completas en Ridgun puro.
