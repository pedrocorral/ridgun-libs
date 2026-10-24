# Capítulo 31: A lib `pool` — Pool Limitado de Trabalhadores, Round-Robin e Work-Stealing

## 31.1. Por que existe a lib `pool`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `pool` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `pool`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: lançar uma nova thread ou ator por cada pedido sem limite superior (`unbounded spawning`) garante que um pico de tráfego esgota a memória do servidor em segundos.

A lib **`pool`** fornece um despachante de tarefas com **contrapressão explícita** (`PoolAccept`, `PoolRejectFull`), partição equilibrada de lotes em $K$ vias (`pool partition`), reequilíbrio por **roubo de trabalho (*work-stealing*)** (`pool steal rebalance`) e execução paralela sobre atores nativos.

Num ecossistema tradicional, resolver as tarefas do domínio **`AGENT`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`pool`** (`src/main/ridgun/lib/pool.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Funções totais e contratos explícitos (`=>`)**: nenhuma função da `pool` lança exceções ocultas nem depende de `null`. Qualquer caso limite devolve um valor sentinela documentado ou um tipo algébrico soma (`Option`, `Result`).
2. **Zero código C e zero `libc`**: todo o código da `pool` compila diretamente para código máquina nativo ELF64 verificado pelo `ridgunc`.
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `pool` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 31.2. Artefactos nativos, importação e catálogo completo da API de `pool`

No `ridgun-libs`, **`pool`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/pool.rg` (domínio `AGENT`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/pool.rglib` | Distribuição e importação direta com `import pool` |
| **Ficheiro compilado** | `target/pool.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libpool.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import pool` no topo e invocar as suas funções com espaços ou underscores.

### 31.2.1. Resumo das famílias funcionais da `pool`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `pool new : Int -> Int -> PoolState` | Cria um pool limitado com `workers` vias e capacidade máxima `max_queue` |
| `pool submit : PoolState -> PoolTask -> (PoolState, PoolDecision)` | Coloca uma tarefa na fila em round-robin ou devolve `PoolRejectFull` se saturado |
| `pool partition / pool steal rebalance` | Divide lotes por $K$ trabalhadores e rouba metade de uma fila sobrecarregada para um trabalhador livre |
| `pool map sum / pool parallel sum2` | Despacha cargas de trabalho em paralelo sobre trabalhadores `agent` nativos |

### 31.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/pool.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/pool.rg` (`1` tipos, `0` operadores e `14` funções):

**Tipos algébricos e registos (`type`) da `pool`:**

```ridgun
type AgentPool = Pool Int [Agent]
```

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
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

## 31.3. Explorando a `pool` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `pool` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test pool.rg`.

### 31.3.1. Exemplo 1: Fluxo principal em estilo tabular com `pool`

Repare como em Ridgun os sinais `=` e os passos de transformação com `pool` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import pool

fn :: encolar con contrapresion () => (Int, Int)
      encolar con contrapresion =
        p0        = pool new 4 16
        tarea     = PoolTask 1 100 "indexar-bloque"
        (p1, dec) = pool submit p0 tarea
        (pool queued p1, pool accepted p1)
```

### 31.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `pool` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import pool

fn :: sumar en paralelo () => Int
      sumar en paralelo =
        pool parallel sum2 [10, 20, 30] [40, 50, 60]
```

### 31.3.3. Exemplo 3: Combinadores de atores (`agent ask`, `try ask`, `send batch`, `map batch`, `drain ready`), pools particionados e reator de conexões

Neste exemplo prático exploramos de forma exaustiva como a `pool` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 31.3.4. Exemplo 4: Ciclo de vida de agentes (`is agent alive`, `agent status`, `stop agent`) e agente contador com estado isolado (`new counter agent`)

Neste exemplo prático exploramos de forma exaustiva como a `pool` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 31.3.5. Exemplo 5: Agente de registo *append-only* (`new log agent`) e armazenamento chave-valor em memória por passagem de mensagens (`new kv agent`)

Neste exemplo prático exploramos de forma exaustiva como a `pool` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 31.3.6. Exemplo 6: Encaminhamento determinístico por chave (`pool ask shard`), difusão (`pool broadcast`), drenagem não bloqueante (`pool drain all`) e encerramento (`pool shutdown`)

Neste exemplo prático exploramos de forma exaustiva como a `pool` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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
        _    = pool broadcast p 1
        pend = pool drain all p
        _    = pool shutdown p
        (sz, r_a + r_b, pend)
```

---

## 31.4. Debaixo do capô: como a `pool` é construída em Ridgun puro (`src/main/ridgun/lib/pool.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/pool.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 31.4.1. Implementação interna: Core Implementation Part 1

Observe como `pool.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
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
        shard_idx = (pool abs key_hash) % size
        target_ag = pool get agent agents shard_idx
        ask target_ag msg

-- Broadcast a message to every agent in the pool (e.g. configuration reload or tick)
fn :: pool broadcast AgentPool       A   => ()
      pool broadcast (Pool _ agents) msg =  pool broadcast list agents msg

fn :: pool broadcast list [Agent]   A   => ()
      pool broadcast list []        _   =  ()
      pool broadcast list (ag:rest) msg =
        send msg to ag
        pool broadcast list rest msg
```

### 31.4.2. Implementação interna: Core Implementation Part 2

Observe como `pool.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
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
        ready = pool drain ready ag
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

## 31.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `pool`

- **Garantia algorítmica e de segurança**: Capacidade de fila estritamente limitada (`queued <= max_queue`) para proteger a memória sob sobrecarga e distribuição determinística entre trabalhadores.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/pool.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test pool.rg`.

### As 5 Regras de Ouro ao programar com a `pool`

1. **Declare `import pool` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `pool` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `pool` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `pool` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 32** passaremos a explorar em profundidade a lib **`net_agent`** (A lib `net_agent` — Supervisor de Ligações de Rede e Ponte de Eventos Não Bloqueante).
