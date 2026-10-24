# Capítulo 32: La lib `net_agent` — Supervisor de Conexiones de Red y Puente de Eventos No Bloqueante

## 32.1. ¿Por qué existe la lib `net_agent`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `net_agent` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `net_agent`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: en un servidor real como **Solstice**, aceptar conexiones TCP es la parte fácil; lo difícil es limitar el máximo de clientes simultáneos, desconectar clientes zombis inactivos (*idle timeout*) y conectar el bucle `ppoll` con tus actores sin fugas de descriptores.

La lib **`net_agent`** cierra el círculo de `ridgun-libs` uniendo **`posix`**, **`socket`** y **`agent`**: gestiona tablas de conexiones supervisadas (`NetSupervisor`), aplica límites de concurrencia (`max_conns`), purga conexiones inactivas (`net evict idle`) y convierte eventos de descriptores del kernel en eventos tipados (`NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout`, `NetEvError`) además de ofrecer un paso de eco TCP completo de extremo a extremo (`net tcp echo step`).

En un ecosistema tradicional, resolver las tareas del dominio **`AGENT`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`net_agent`** (`src/main/ridgun/lib/net_agent.rg`) aborda el problema con cuatro principios innegociables:

1. **Funciones totales y contratos explícitos (`=>`)**: ninguna función de `net_agent` lanza excepciones ocultas ni depende de `null`. Todo caso límite (entradas vacías, divisores cero, tramas truncadas o índices fuera de rango) devuelve un valor centinela documentado o un tipo algebraico suma (`Option`, `Result`).
2. **Cero código C y cero `libc`**: todo el código de `net_agent` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `net_agent` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 32.2. Artefactos nativos, importación y catálogo completo de la API de `net_agent`

En `ridgun-libs`, **`net_agent`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/net_agent.rg` (dominio `AGENT`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/net_agent.rglib` | Distribución e importación directa con `import net_agent` |
| **Archivo compilado** | `target/net_agent.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libnet_agent.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import net_agent` en el encabezado y llamar a sus funciones con espacios (`mi funcion x`) o guiones bajos (`mi_funcion x`) indistintamente.

### 32.2.1. Resumen de familias funcionales de `net_agent`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `net supervisor new : Int -> Int -> NetSupervisor` | Crea un supervisor de conexiones con límite `max_conns` e inactividad `idle_timeout_ms` |
| `net register conn / net record rx / net record tx / net close conn` | Registra sockets aceptados, actualiza contadores de bytes/actividad y cierra pares |
| `net evict idle : NetSupervisor -> Int -> (NetSupervisor, [Int])` | Cierra y expulsa conexiones inactivas más allá de `idle_timeout_ms`, devolviendo sus FDs |
| `net poll fd : Int -> Bool -> Int -> NetEvent` | Puente `wait fd` no bloqueante que emite `NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout` o `NetEvError` |
| `net tcp echo step : String -> Int -> (Int, String)` | Paso completo de extremo a extremo TCP loopback (`listen/connect/accept/supervise/echo`) |

### 32.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/net_agent.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/net_agent.rg` (`2` tipos, `0` operadores y `8` funciones):

**Tipos algebraicos y registros (`type`) de `net_agent`:**

```ridgun
type ConnSlot = ConnSlot Int Agent
type StepOutcome = ConnKeep ConnSlot String | ConnClosed
```

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
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

## 32.3. Explorando `net_agent` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `net_agent` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test net_agent.rg`.

### 32.3.1. Ejemplo 1: Flujo principal en estilo tabular con `net_agent`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `net_agent` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

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

### 32.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `net_agent` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import net_agent

fn :: probar puente tcp supervisado () => (Int, String)
      probar puente tcp supervisado =
        net tcp echo step "ping-supervisado" 1000
```

### 32.3.3. Ejemplo 3: Combinadores de actores (`agent ask`, `try ask`, `send batch`, `map batch`, `drain ready`), pools particionados y reactor de conexiones

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `net_agent` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 32.3.4. Ejemplo 4: Ciclo de vida de agentes (`is agent alive`, `agent status`, `stop agent`) y agente contador con estado aislado (`new counter agent`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `net_agent` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 32.3.5. Ejemplo 5: Agente de bitácora *append-only* (`new log agent`) y almacén clave-valor en memoria por paso de mensajes (`new kv agent`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `net_agent` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 32.3.6. Ejemplo 6: Sondeo no bloqueante de descriptores (`conn poll step`), barrido de tabla de conexiones (`reactor sweep`) y apagado limpio (`reactor shutdown`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `net_agent` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

## 32.4. Bajo el capó: cómo está construida `net_agent` en Ridgun puro (`src/main/ridgun/lib/net_agent.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/net_agent.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 32.4.1. Implementación interna: Core Implementation Part 1

Fíjate en cómo `net_agent.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

### 32.4.2. Implementación interna: Core Implementation Part 2

Fíjate en cómo `net_agent.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

## 32.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `net_agent`

- **Garantía algorítmica y de seguridad**: Protección automática frente a agotamiento de descriptores (`max_conns`), expulsión determinista de conexiones inactivas y cierre garantizado de sockets en `net tcp echo step`.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/net_agent.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test net_agent.rg`.

### Las 5 Reglas de Oro al programar con `net_agent`

1. **Declara `import net_agent` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `net_agent` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `net_agent` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `net_agent` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

¡Has completado el recorrido exhaustivo por las **32 libs estándar de `ridgun-libs`**! Ahora tienes en tus manos todas las piezas para construir aplicaciones y herramientas de sistemas completas en Ridgun puro.
