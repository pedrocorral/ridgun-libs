# Capítulo 31: A lib `pool` — Pool Acoutado de Axentes Traballadores e Reparto por Chave

## 31.1. Por que existe a lib `pool`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `pool` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `pool`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: lanzar un fío ou actor novo por cada petición entrante sen límite superior (`unbounded spawning`) fai que un pico de tráfico esgote a memoria en segundos (*Out Of Memory*).

A lib **`pool`** executa traballos nun número fixo de axentes traballadores, cada un co seu propio estado (unha sesión de base de datos, un contador, nada): `pool submit` entrega un traballo a un traballador libre ou rexéitao ao instante cando todos están ocupados; `pool done fd` é un descritor que queda lexible cando un traballo remata, de xeito que un servidor o agarda xunto aos seus sockets e nunca sondea; `pool collect` devolve cada resultado exactamente unha vez; `pool tagged` di cantos traballadores retén un cliente; e `pool drain` agarda polos traballos en curso e para os traballadores. É o pool que Solstice escribiu á man no seu servidor HTTP. A lib tamén reparte unha mensaxe por chave sobre unha lista de axentes (`pool ask shard`).

Nun ecosistema tradicional, resolver as tarefas do dominio **`AGENT`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`pool`** (`src/main/ridgun/lib/pool.ridgun`) aborda o problema con catro principios innegociables:

1. **Declara `import pool` (ou `import pool as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: pool` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `pool` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 31.2. Artefactos nativos, importación e catálogo completo da API de `pool`

En `ridgun-libs`, **`pool`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/pool.ridgun` (dominio `AGENT`). Ao compilar con `stable bundle`, empaquétase nun formato nativo:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/pool.ridgunlib` | Distribución e importación directa con `import pool` |

> Cada lib declara o seu propio espazo de nomes con `module :: pool`: abonda con escribir `import pool` (ou `import pool as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 31.2.1. Resumo de familias funcionais de `pool`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `pool start / pool capacity / pool busy / pool idle` | Arrinca un pool de 1 a 64 traballadores cunha función traballadora e un estado inicial; o seu tamaño e cantos están ocupados ou libres |
| `pool submit / pool refused` | Entrega un traballo a un traballador libre, ou devolve `-1` ao instante cando todos están ocupados; o número de traballos rexeitados |
| `pool done fd / pool collect` | Un descritor que queda lexible cando un traballo remata, e os resultados dos traballos rematados, cada un exactamente unha vez |
| `pool tagged` | Cantos traballadores ocupados reteñen unha etiqueta, para que un cliente non os ocupe todos |
| `pool drain` | Non acepta máis traballos, agarda polos que están en curso e para os traballadores |
| `pool of / pool size / pool is empty / pool agents` | Un `AgentPool` cun número fixo de axentes, o seu tamaño e os seus axentes |
| `pool ask shard / pool ask shard or` | Petición-resposta co axente escollido por chave: a mesma chave chega sempre ao mesmo axente |
| `pool broadcast` | Envía unha mensaxe a todos os axentes do pool |
| `pool drain all / pool drain ready` | Recolle as respostas que están listas, sen bloquear |
| `pool shutdown` | Detén todos os axentes do pool |

### 31.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/pool.ridgun`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/pool.ridgun` (`5` tipos, `0` operadores e `52` funcións):

**Tipos alxébricos e rexistros (`type`) de `pool`:**

```ridgun
type PoolMsg S J R = PoolMsg (S J => (S, R)) Int Int J
type PoolSlot S J R = ps_agent: (Agent (PoolMsg S J R) R), ps_busy: Bool, ps_index: Int, ps_tag: String
type WorkerPool S J R = wp_fn: (S J => (S, R)), wp_slots: [(PoolSlot S J R)], wp_done_r: Int, wp_done_w: Int, wp_refused: Int, wp_open: Bool
type PoolDone R = PoolDone Int String R
type AgentPool = Pool Int [Agent]
```

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: pool run S (PoolMsg S J R)` | `S R` |
| `2` | `fn :: pool new slots S Int Int` | `[PoolSlot S J R]` |
| `3` | `fn :: pool clamp workers Int` | `Int` |
| `4` | `fn :: pool started (S J` | `(S, R)) S Int (Int Int Int) => WorkerPool S J R` |
| `5` | `fn :: pool start Int (S J` | `(S, R)) S => WorkerPool S J R` |
| `6` | `fn :: pool slot count [(PoolSlot S J R)] Int` | `Int` |
| `7` | `fn :: pool busy count [(PoolSlot S J R)] Int` | `Int` |
| `8` | `fn :: pool capacity (WorkerPool S J R)` | `Int` |
| `9` | `fn :: pool busy (WorkerPool S J R)` | `Int` |
| `10` | `fn :: pool idle (WorkerPool S J R)` | `Int` |
| `11` | `fn :: pool refused (WorkerPool S J R)` | `Int` |
| `12` | `fn :: pool done fd (WorkerPool S J R)` | `Int` |
| `13` | `fn :: pool tag count [(PoolSlot S J R)] String Int` | `Int` |
| `14` | `fn :: pool tagged (WorkerPool S J R) String` | `Int` |
| `15` | `fn :: pool first idle [(PoolSlot S J R)]` | `Int` |
| `16` | `fn :: pool hand [(PoolSlot S J R)] (S J` | `(S, R)) Int Int J String => [PoolSlot S J R]` |
| `17` | `fn :: pool handed (PoolSlot S J R) (PoolMsg S J R) String` | `PoolSlot S J R` |
| `18` | `fn :: pool submit to (WorkerPool S J R) J String Int` | `Int (WorkerPool S J R)` |
| `19` | `fn :: pool submit (WorkerPool S J R) J String` | `Int (WorkerPool S J R)` |
| `20` | `fn :: pool is ready PollStatus` | `Bool` |
| `21` | `fn :: pool take [(PoolSlot S J R)] Int [(PoolSlot S J R)] [(PoolDone R)]` | `[PoolSlot S J R] [PoolDone R]` |
| `22` | `fn :: pool take all [(PoolSlot S J R)] String Int [(PoolDone R)]` | `[PoolSlot S J R] [PoolDone R]` |
| `23` | `fn :: pool take next ([(PoolSlot S J R)] [(PoolDone R)]) String Int` | `[PoolSlot S J R] [PoolDone R]` |
| `24` | `fn :: pool collected (WorkerPool S J R) ([(PoolSlot S J R)] [(PoolDone R)])` | `[PoolDone R] (WorkerPool S J R)` |
| `25` | `fn :: pool collect (WorkerPool S J R) Int` | `[PoolDone R] (WorkerPool S J R)` |
| `26` | `fn :: pool stop slots [(PoolSlot S J R)]` | `()` |
| `27` | `fn :: pool closed (WorkerPool S J R) [(PoolDone R)]` | `[PoolDone R] (WorkerPool S J R)` |
| `28` | `fn :: pool drain until (WorkerPool S J R) Int [(PoolDone R)]` | `[PoolDone R] (WorkerPool S J R)` |
| `29` | `fn :: pool drain more ([(PoolDone R)] (WorkerPool S J R)) Int [(PoolDone R)]` | `[PoolDone R] (WorkerPool S J R)` |
| `30` | `fn :: pool drain (WorkerPool S J R) Int` | `[PoolDone R] (WorkerPool S J R)` |
| `31` | `fn :: pool count [Agent] Int` | `Int` |
| `32` | `fn :: pool of [Agent]` | `AgentPool` |
| `33` | `fn :: pool size AgentPool` | `Int` |
| `34` | `fn :: pool is empty AgentPool` | `Bool` |
| `35` | `fn :: pool agents AgentPool` | `[Agent]` |
| `36` | `fn :: pool get agent [Agent] Int` | `Agent` |
| `37` | `fn :: pool abs Int` | `Int` |
| `38` | `fn :: pool ask shard AgentPool Int A` | `B` |
| `39` | `fn :: pool ask at [Agent] Int Int A` | `B` |
| `40` | `fn :: pool stop empty A` | `B` |
| `41` | `fn :: pool ask shard or AgentPool Int A B` | `B` |
| `42` | `fn :: pool ask at or [Agent] Int Int A B` | `B` |
| `43` | `fn :: pool broadcast AgentPool A` | `()` |
| `44` | `fn :: pool send one Agent A` | `()` |
| `45` | `fn :: pool broadcast list [Agent] A` | `()` |
| `46` | `fn :: pool drain ready Agent` | `[B]` |
| `47` | `fn :: pool drain ready loop Agent [B]` | `[B]` |
| `48` | `fn :: pool drain step Agent Option [B]` | `[B]` |
| `49` | `fn :: pool drain all AgentPool` | `[B]` |
| `50` | `fn :: pool drain list [Agent] [B]` | `[B]` |
| `51` | `fn :: pool stop list [Agent]` | `()` |
| `52` | `fn :: pool shutdown AgentPool` | `()` |

---

## 31.3. Explorando `pool` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `pool` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test pool.ridgun`.

### 31.3.1. Exemplo 1: Fluxo principal en estilo tabular con `pool`

Observa como en Ridgun os signos `=` e os pasos de transformación con `pool` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import pool

fn :: doblar Int Int => Int Int
      doblar hechos n =  (hechos + 1, n * 2)

fn :: enviar y recoger => Int
      enviar y recoger =
        p0          = pool start 4 (doblar) 0
        quien, p1   = pool submit p0 21 "cliente-a"
        hechos, p2  = pool collect p1 1000
        resto, p3   = pool drain p2 1000
        pool refused p3
```

### 31.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `pool` está deseñada para compoñerse con gardas booleanas `|` e co resto das 38 libs de `ridgun-libs`:

```ridgun
import pool

fn :: entregado (Int (WorkerPool Int Int Int)) => String (WorkerPool Int Int Int)
      entregado (k, p) =  ("trabajador {k}", p)

fn :: aceptar o rechazar (WorkerPool Int Int Int) Int String => String (WorkerPool Int Int Int)
      aceptar o rechazar p trabajo cliente =
        | (pool tagged p cliente) >= 2 = ("demasiadas peticiones de " + cliente, p)
        | (pool idle p) == 0           = ("ocupado", p)
        | otherwise                    = entregado (pool submit p trabajo cliente)
```

### 31.3.3. Exemplo 3: Enrutamento determinista por clave (`pool ask shard`), difusión masiva (`pool broadcast`), drenaxe non bloqueante (`pool drain all`) e apagado (`pool shutdown`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `pool` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 31.3.4. Exemplo 4: Reparto por chave (`pool ask shard`): mesma chave, mesmo axente; chaves por quenda, axentes por quenda; difusión e parada

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `pool` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test pool routing by key => ()
      test pool routing by key =
        a0 = new counter agent 0
        a1 = new counter agent 1000
        a2 = new counter agent 2000
        pl = Pool 3 [a0, a1, a2]
        pool size pl -> assert int equals 3 "pool size 3"
        agent list len (pool agents pl) 0 -> assert int equals 3 "pool agents holds the 3 agents"
        pool ask shard pl 0 1 -> assert int equals 1 "key 0 -> agent 0"
        pool ask shard pl 1 1 -> assert int equals 1001 "key 1 -> agent 1"
        pool ask shard pl 2 1 -> assert int equals 2001 "key 2 -> agent 2"
        pool ask shard pl 3 1 -> assert int equals 2 "key 3 -> agent 0 again: keys in turn visit the agents in turn"
        pool ask shard pl 7 1 -> assert int equals 1002 "key 7 -> agent 1"
        pool ask shard pl 7 1 -> assert int equals 1003 "the same key always reaches the same agent"
        pool ask shard pl (0 - 2) 1 -> assert int equals 2002 "negative key -> agent abs(key) % size"
        agent list len (pool drain all pl) 0 -> assert int equals 0 "pool drain all with nothing ready -> []"
        pool broadcast pl 100
        counter get a0 -> assert int equals 102 "broadcast reached agent 0"
        counter get a1 -> assert int equals 1103 "broadcast reached agent 1"
        counter get a2 -> assert int equals 2102 "broadcast reached agent 2"
        one = Pool 1 [new counter agent 5]
        pool ask shard one 12345 1 -> assert int equals 6 "a pool of one agent takes every key"
        pool shutdown one
        pool shutdown pl
        is agent alive a0 -> assert false "pool shutdown stops agent 0"
        is agent alive a2 -> assert false "pool shutdown stops agent 2"
```

### 31.3.5. Exemplo 5: Os traballos van a traballadores libres, un pool cheo rexeita ao instante e os resultados recóllense sen sondear

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `pool` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test pool takes jobs and refuses when full => ()
      test pool takes jobs and refuses when full =
        p0 = pool start 3 (tw work) 0
        pool capacity p0 -> assert int equals 3 "a pool of 3 workers"
        pool busy p0 -> assert int equals 0 "no worker is busy at the start"
        pool idle p0 -> assert int equals 3 "the three are idle"
        (pool done fd p0) >= 0 -> assert true "the pool has a descriptor to wait on"
        k1, p1 = pool submit p0 300 "a"
        k2, p2 = pool submit p1 300 "a"
        k3, p3 = pool submit p2 300 "b"
        k1 -> assert int equals 0 "the first job goes to worker 0"
        k2 -> assert int equals 1 "the second to worker 1"
        k3 -> assert int equals 2 "the third to worker 2"
        pool busy p3 -> assert int equals 3 "the three workers are busy"
        t0 = sys monotonic ms
        k4, p4 = pool submit p3 300 "c"
        k4 -> assert int equals (0 - 1) "a fourth job is refused"
        ((sys monotonic ms) - t0) < 100 -> assert true "and refused at once, without waiting"
        pool refused p4 -> assert int equals 1 "the pool counts the refused job"
        pool tagged p4 "a" -> assert int equals 2 "two busy workers hold the tag a"
        pool tagged p4 "b" -> assert int equals 1 "one holds the tag b"
        pool tagged p4 "c" -> assert int equals 0 "none holds the tag of the refused job"

        t1 = sys monotonic ms
        none, p5 = pool collect p4 0
        pd count none 0 -> assert int equals 0 "collect without waiting: nothing has ended"
        ((sys monotonic ms) - t1) < 100 -> assert true "and it returns at once"
        t2 = sys monotonic ms
        none2, p6 = pool collect p5 50
        pd count none2 0 -> assert int equals 0 "collect with 50 ms: still nothing"
        ((sys monotonic ms) - t2) >= 40 -> assert true "after waiting about 50 ms"

        is ready (wait fd (pool done fd p6) (poll in) 2000) -> assert true "the pool's descriptor is readable when a job ends"
        got, p7 = collect all p6 3 10 []
        pd count got 0 -> assert int equals 3 "the three results are collected"
        pd slots sum got 0 -> assert int equals 3 "one from each worker: 0 + 1 + 2"
        pd results sum got 0 -> assert int equals 900000 "each result is its own job on a fresh state"
        pd tagged got "a" 0 -> assert int equals 2 "two results carry the tag a"
        pd tagged got "b" 0 -> assert int equals 1 "one carries the tag b"
        pool busy p7 -> assert int equals 0 "every worker is idle again"
        pool tagged p7 "a" -> assert int equals 0 "and no tag is held"
        late, p8 = pool collect p7 0
        pd count late 0 -> assert int equals 0 "a result is never returned twice"

        -- AC6 and AC1: jobs that end in another order keep their own results, and a worker keeps its state
        ka, p9  = pool submit p8 200 "slow"
        kb, p10 = pool submit p9 20 "fast"
        ka -> assert int equals 0 "the slow job goes to worker 0"
        kb -> assert int equals 1 "the fast job to worker 1"
        first, p11 = collect all p10 1 10 []
        pd tag (pd first first) -> assert str eq "fast" "the fast job ends first"
        pd slot (pd first first) -> assert int equals 1 "and comes from worker 1"
        pd result (pd first first) -> assert int equals 20001 "with its own result; worker 1 had done one job before"
        second, p12 = collect all p11 1 10 []
        pd tag (pd first second) -> assert str eq "slow" "the slow job ends later"
        pd result (pd first second) -> assert int equals 200001 "with its own result; worker 0 had done one job before"

        -- AC7: drain
        kx, p13 = pool submit p12 100 "x"
        ky, p14 = pool submit p13 100 "y"
        drained, p15 = pool drain p14 2000
        pd count drained 0 -> assert int equals 2 "drain returns the results of the two jobs in flight"
        pd results sum drained 0 -> assert int equals 200004 "workers 0 and 1 had done two jobs each: 100002 + 100002"
        pool busy p15 -> assert int equals 0 "nothing runs after the drain"
        kz, p16 = pool submit p15 10 "z"
        kz -> assert int equals (0 - 1) "a drained pool takes no more jobs"
        pool done fd p16 -> assert int equals (0 - 1) "and its descriptor is closed"
        ()
```

### 31.3.6. Exemplo 6: De 1 a 64 traballadores

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `pool` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test pool size limits => ()
      test pool size limits =
        one = pool start 0 (tw work) 0
        pool capacity one -> assert int equals 1 "fewer than 1 worker gives 1"
        _, o2 = pool drain one 100
        many = pool start 100 (tw work) 0
        pool capacity many -> assert int equals 64 "more than 64 workers gives 64"
        _, m2 = pool drain many 100
        pool capacity m2 -> assert int equals 0 "a drained pool has no workers"
        ()
```

### 31.3.7. Exemplo 7: Reparto por chave sobre unha lista baleira e o tamaño real dunha lista

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `pool` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test pool routing edge cases => ()
      test pool routing edge cases =
        none = pool of []
        pool is empty none -> assert true "a list with no agents is empty"
        pool size none -> assert int equals 0 "and its size is 0"
        pool ask shard or none 3 1 (0 - 1) -> assert int equals (0 - 1) "pool ask shard or gives its default when there is nobody to ask"
        a = new counter agent 0
        b = new counter agent 1000
        two = Pool 5 [a, b]
        pool size two -> assert int equals 2 "the size is the number of agents, whatever number was written"
        pool ask shard two 3 1 -> assert int equals 1001 "key 3 over two agents reaches agent 1"
        pool ask shard or two 4 1 (0 - 1) -> assert int equals 1 "key 4 reaches agent 0, also with a default"
        pool is empty two -> assert false "a list with agents is not empty"
        pool shutdown two
        ()
```

---

## 31.4. Baixo o capó: como está construída `pool` en Ridgun puro (`src/main/ridgun/lib/pool.ridgun`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/pool.ridgun` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 31.4.1. Implementación interna: Worker pool (FR-POOL-001 AC1 to AC7)

Fíxate en como `pool.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
module :: pool

-- A fixed number of worker agents, each with its own state. A job goes to an idle worker or is refused.
-- When a worker ends a job it writes its number to a pipe, so the caller waits on a descriptor and never polls.

-- What a worker gets: the function to run, its own number, the write end of the pipe and the job.
-- Inside a `type` the pair of the result is written `(S, R)` (ridgunc 1.0.51 does not read `S R` there).
type PoolMsg S J R = PoolMsg (S J => (S, R)) Int Int J

-- One worker: its agent, whether it runs a job, its number and the tag of that job.
type PoolSlot S J R = ps_agent: (Agent (PoolMsg S J R) R), ps_busy: Bool, ps_index: Int, ps_tag: String

-- wp_done_r / wp_done_w: the pipe the workers report on. wp_open: False once the pool is drained.
type WorkerPool S J R = wp_fn: (S J => (S, R)), wp_slots: [(PoolSlot S J R)], wp_done_r: Int, wp_done_w: Int, wp_refused: Int, wp_open: Bool

-- A job that ended: the worker that ran it, its tag and its result.
type PoolDone R = PoolDone Int String R

-- The worker: runs the job on its state, tells the pool it has ended, and answers the result.
-- The number written is the worker's number plus 1, so it is never the byte 0.
fn :: pool run S (PoolMsg S J R) => S R
      pool run st (PoolMsg f slot done job) =
        st2, r = f st job
        posix write done (char from code (slot + 1)) -> ()
        (st2, r)

fn :: pool new slots S Int Int => [PoolSlot S J R]
      pool new slots s0 i n =
        | i >= n    = []
        | otherwise = [PoolSlot (agent (pool run) s0) False i ""] :: (pool new slots s0 (i + 1) n)

fn :: pool clamp workers Int => Int
      pool clamp workers n =
        | n < 1     = 1
        | n > 64    = 64
        | otherwise = n

fn :: pool started (S J => (S, R)) S Int (Int Int Int) => WorkerPool S J R
      pool started f s0 n (rc, r, w) =
        | rc != 0   = WorkerPool f [] (0 - 1) (0 - 1) 0 False
        | otherwise = WorkerPool f (pool new slots s0 0 n) r w 0 True

-- A pool of `n` workers (1 to 64) that run `f`, each starting from the state `s0`.
fn :: pool start Int (S J => (S, R)) S => WorkerPool S J R
      pool start n f s0 =  pool started f s0 (pool clamp workers n) posix pipe

fn :: pool slot count [(PoolSlot S J R)] Int => Int
      pool slot count []       n =  n
      pool slot count (_:rest) n =  pool slot count rest (n + 1)

fn :: pool busy count [(PoolSlot S J R)] Int => Int
      pool busy count []       n =  n
      pool busy count (s:rest) n =
        | ps_busy s = pool busy count rest (n + 1)
        | otherwise = pool busy count rest n

fn :: pool capacity (WorkerPool S J R) => Int
      pool capacity p =  pool slot count (wp_slots p) 0

fn :: pool busy (WorkerPool S J R) => Int
      pool busy p =  pool busy count (wp_slots p) 0

fn :: pool idle (WorkerPool S J R) => Int
      pool idle p =  (pool capacity p) - (pool busy p)

fn :: pool refused (WorkerPool S J R) => Int
      pool refused p =  wp_refused p

-- The descriptor that is readable when a job has ended (-1 when the pool could not start).
fn :: pool done fd (WorkerPool S J R) => Int
      pool done fd p =  wp_done_r p

fn :: pool tag count [(PoolSlot S J R)] String Int => Int
      pool tag count []       _   n =  n
      pool tag count (s:rest) tag n =
        | (ps_busy s) and (ps_tag s) == tag = pool tag count rest tag (n + 1)
        | otherwise                         = pool tag count rest tag n

-- Busy workers whose job was submitted with `tag`.
fn :: pool tagged (WorkerPool S J R) String => Int
      pool tagged p tag =  pool tag count (wp_slots p) tag 0

-- The number of the first idle worker, or -1.
fn :: pool first idle [(PoolSlot S J R)] => Int
      pool first idle []       =  0 - 1
      pool first idle (s:rest) =
        | ps_busy s = pool first idle rest
        | otherwise = ps_index s

-- Hands the job to worker `k` and marks it busy with the tag.
fn :: pool hand [(PoolSlot S J R)] (S J => (S, R)) Int Int J String => [PoolSlot S J R]
      pool hand []       _ _ _ _   _   =  []
      pool hand (s:rest) f w k job tag =
        | (ps_index s) == k = [pool handed s (PoolMsg f k w job) tag] :: rest
        | otherwise         = [s] :: (pool hand rest f w k job tag)

fn :: pool handed (PoolSlot S J R) (PoolMsg S J R) String => PoolSlot S J R
      pool handed s m tag =
        send m to (ps_agent s)
        s with ps_busy = True, ps_tag = tag

fn :: pool submit to (WorkerPool S J R) J String Int => Int (WorkerPool S J R)
      pool submit to p job tag k =
        | k < 0     = (0 - 1, p with wp_refused = ((wp_refused p) + 1))
        | otherwise = (k, p with wp_slots = (pool hand (wp_slots p) (wp_fn p) (wp_done_w p) k job tag))

-- Gives the job to an idle worker: the answer is the number of that worker, or -1 when every worker
-- is busy or the pool was drained, and the pool to use from now on. It never waits.
fn :: pool submit (WorkerPool S J R) J String => Int (WorkerPool S J R)
      pool submit p job tag =
        | not (wp_open p) = (0 - 1, p with wp_refused = ((wp_refused p) + 1))
        | otherwise       = pool submit to p job tag (pool first idle (wp_slots p))

fn :: pool is ready PollStatus    => Bool
      pool is ready (PollReady _) =  True
      pool is ready _             =  False

-- Frees worker `k` and takes its result, which is ready: its byte is in the pipe.
fn :: pool take [(PoolSlot S J R)] Int [(PoolSlot S J R)] [(PoolDone R)] => [PoolSlot S J R] [PoolDone R]
      pool take []       _ kept got =  (kept, got)
      pool take (s:rest) k kept got =
        | (ps_index s) == k and (ps_busy s) = pool take rest k (kept :: [s with ps_busy = False, ps_tag = ""]) (got :: [PoolDone k (ps_tag s) (receive from (ps_agent s))])
        | otherwise                         = pool take rest k (kept :: [s]) got

fn :: pool take all [(PoolSlot S J R)] String Int [(PoolDone R)] => [PoolSlot S J R] [PoolDone R]
      pool take all slots bytes i got =
        | i >= (str len bytes) = (slots, got)
        | otherwise            = pool take next (pool take slots ((str char at bytes i) - 1) [] got) bytes i

fn :: pool take next ([(PoolSlot S J R)] [(PoolDone R)]) String Int => [PoolSlot S J R] [PoolDone R]
      pool take next (slots, got) bytes i =  pool take all slots bytes (i + 1) got

fn :: pool collected (WorkerPool S J R) ([(PoolSlot S J R)] [(PoolDone R)]) => [PoolDone R] (WorkerPool S J R)
      pool collected p (slots, got) =  (got, p with wp_slots = slots)

-- The jobs that have ended, each exactly once, and the pool to use from now on.
-- Waits at most `timeout_ms` for the first one (0: does not wait).
fn :: pool collect (WorkerPool S J R) Int => [PoolDone R] (WorkerPool S J R)
      pool collect p timeout_ms =
        | (pool busy p) == 0                                           = ([], p)
        | pool is ready (wait fd (wp_done_r p) (poll in) timeout_ms)   = pool collected p (pool take all (wp_slots p) (posix read (wp_done_r p) 256) 0 [])
        | otherwise                                                    = ([], p)

fn :: pool stop slots [(PoolSlot S J R)] => ()
      pool stop slots []       =  ()
      pool stop slots (s:rest) =
        stop (ps_agent s)
        pool stop slots rest

fn :: pool closed (WorkerPool S J R) [(PoolDone R)] => [PoolDone R] (WorkerPool S J R)
      pool closed p got =
        pool stop slots (wp_slots p)
        posix close (wp_done_r p) -> ()
        posix close (wp_done_w p) -> ()
        (got, p with wp_slots = [], wp_done_r = (0 - 1), wp_done_w = (0 - 1), wp_open = False)

fn :: pool drain until (WorkerPool S J R) Int [(PoolDone R)] => [PoolDone R] (WorkerPool S J R)
      pool drain until p deadline got =
        | (pool busy p) == 0 or (sys monotonic ms) >= deadline = pool closed p got
        | otherwise                                            = pool drain more (pool collect p (deadline - (sys monotonic ms))) deadline got

fn :: pool drain more ([(PoolDone R)] (WorkerPool S J R)) Int [(PoolDone R)] => [PoolDone R] (WorkerPool S J R)
      pool drain more (more, p) deadline got =  pool drain until p deadline (got :: more)

-- Takes no more jobs, waits at most `timeout_ms` for the ones in flight, stops every worker and closes
-- the pipe. The answer is the results of those jobs and the drained pool.
-- The result comes first in every pair: ridgunc 1.0.55 in strict mode refuses an output that starts with `(`.
fn :: pool drain (WorkerPool S J R) Int => [PoolDone R] (WorkerPool S J R)
      pool drain p timeout_ms =
        | not (wp_open p) = ([], p)
        | otherwise       = pool drain until (p with wp_open = False) ((sys monotonic ms) + timeout_ms) []
```

### 31.4.2. Implementación interna: Routing by key over a list of agents (FR-POOL-001 AC8)

Fíxate en como `pool.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
type AgentPool = Pool Int [Agent]

fn :: pool count [Agent]  Int => Int
      pool count []       n   =  n
      pool count (_:rest) n   =  pool count rest (n + 1)

-- A pool of the agents of a list.
fn :: pool of [Agent] => AgentPool
      pool of ags     =  Pool (pool count ags 0) ags

-- The number of agents the pool holds (the list decides, not the number written in `Pool n agents`).
fn :: pool size AgentPool    => Int
      pool size (Pool _ ags) =  pool count ags 0

fn :: pool is empty AgentPool => Bool
      pool is empty pl        =  (pool size pl) == 0

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

-- Routes a message to agent `abs(key) % n`, n being the number of agents of the pool, and returns its reply.
-- A pool with no agents has nobody to ask: the program stops with a message. `pool ask shard or` does not stop.
fn :: pool ask shard AgentPool Int A => B
      pool ask shard (Pool _ agents) key_hash msg =
        pool ask at agents (pool count agents 0) key_hash msg

fn :: pool ask at [Agent] Int Int A => B
      pool ask at agents n key_hash msg =
        | n <= 0    = pool stop empty msg
        | otherwise = ask (pool get agent agents ((pool abs key_hash) % n)) msg

fn :: pool stop empty A => B
      pool stop empty msg =
        echo "pool ask shard: the pool has no agents"
        sys exit 1
        pool stop empty msg

-- The same, or `default` when the pool has no agents.
fn :: pool ask shard or AgentPool Int A B => B
      pool ask shard or (Pool _ agents) key_hash msg default =
        pool ask at or agents (pool count agents 0) key_hash msg default

fn :: pool ask at or [Agent] Int Int A B => B
      pool ask at or agents n key_hash msg default =
        | n <= 0    = default
        | otherwise = ask (pool get agent agents ((pool abs key_hash) % n)) msg

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

## 31.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `pool`

- **Garantía algorítmica e de seguridade**: Como moito corren `worker_count` traballos á vez (de 1 a 64) e nada se pon en cola, así que a memoria do pool está acoutada; cada resultado devólvese exactamente unha vez e co seu propio traballo, e só o fío de quen chama fala cos traballadores.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/pool.ridgun` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test pool.ridgun`.

### As 5 Regras de Ouro ao programar con `pool`

1. **Declara `import pool` ao inicio do ficheiro** e chama as súas funcións con espazos, tal como están declaradas, para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `pool` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `pool` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `pool` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 32** pasaremos a explorar en profundidade a lib **`net_agent`** (A lib `net_agent` — Moitas conexións nun só bucle que non agarda por ningunha).
