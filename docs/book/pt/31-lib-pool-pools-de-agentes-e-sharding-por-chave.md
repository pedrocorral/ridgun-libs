# Capítulo 31: A lib `pool` — Pools de Agentes: Sharding por Chave, Broadcast e Drenagem Não Bloqueante

## 31.1. Por que existe a lib `pool`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `pool` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `pool`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: quando todos os pedidos do mesmo utilizador ou da mesma chave têm de chegar ao mesmo trabalhador, e de vez em quando uma mensagem tem de chegar a todos, escrever à mão esse encaminhamento e a paragem ordenada em cada programa é repetitivo e fácil de fazer mal.

A lib **`pool`** agrupa um número fixo de agentes num `AgentPool`: `pool ask shard` envia cada pedido ao agente escolhido pela sua chave, pelo que a mesma chave chega sempre ao mesmo agente; `pool broadcast` envia uma mensagem a todos os agentes; `pool drain all` recolhe, sem bloquear, as respostas que estão prontas; e `pool shutdown` faz parar todos eles.

Num ecossistema tradicional, resolver as tarefas do domínio **`AGENT`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`pool`** (`src/main/ridgun/lib/pool.ridgun`) aborda o problema com quatro princípios inegociáveis:

1. **Declare `import pool` (ou `import pool as alias`) no início do ficheiro**: cada lib define o seu espaço de nomes `module :: pool` e em modo `--strict` as funções multi-palavra são sempre invocadas com espaços naturais.
2. **Encadeie os seus pipelines da esquerda para a direita com `->`**: escreva `entrada passo um -> passo dois -> resultado`, use máscaras `(+ _ _ +)` para desestruturar sequências e omita `_ =` em instruções sequenciais (ou descarte com `-> ()`).
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `pool` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 31.2. Artefactos nativos, importação e catálogo completo da API de `pool`

No `ridgun-libs`, **`pool`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/pool.ridgun` (domínio `AGENT`). Ao compilar com `stable bundle`, é empacotada num formato nativo:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/pool.ridgunlib` | Distribuição e importação direta com `import pool` |

> Cada lib declara o seu próprio espaço de nomes com `module :: pool`: basta escrever `import pool` (ou `import pool as alias`) no topo e invocar as suas funções com espaços naturais (`minha funcao x`) e pipelines `->` (`x minha funcao -> resultado`).

### 31.2.1. Resumo das famílias funcionais da `pool`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `Pool / pool size / pool agents` | Um `AgentPool` com um número fixo de agentes, o seu tamanho e os seus agentes |
| `pool ask shard` | Pedido-resposta com o agente escolhido pela chave: a mesma chave chega sempre ao mesmo agente |
| `pool broadcast` | Envia uma mensagem a todos os agentes do pool |
| `pool drain all / pool drain ready` | Recolhe as respostas que estão prontas, sem bloquear |
| `pool shutdown` | Faz parar todos os agentes do pool |

### 31.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/pool.ridgun`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/pool.ridgun` (`1` tipos, `0` operadores e `15` funções):

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

## 31.3. Explorando a `pool` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `pool` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test pool.ridgun`.

### 31.3.1. Exemplo 1: Fluxo principal em estilo tabular com `pool`

Repare como em Ridgun os sinais `=` e os passos de transformação com `pool` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import pool

fn :: despachar a shard AgentPool Int String => String
      despachar a shard p hash_clave msg =
        pool ask shard p hash_clave msg
```

### 31.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `pool` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 38 libs do `ridgun-libs`:

```ridgun
import pool

fn :: difundir y cerrar AgentPool String => ()
      difundir y cerrar p evento =
        pool broadcast p evento
        pool shutdown p
```

### 31.3.3. Exemplo 3: Combinadores de atores (`agent ask`, `agent try ask`, `agent send batch`, `agent map batch`, `agent drain ready`), pools particionados e reator de conexões

Neste exemplo prático exploramos de forma exaustiva como a `pool` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 31.3.4. Exemplo 4: Ciclo de vida de agentes (`is agent alive`, `agent status`, `stop agent`) e agente contador com estado isolado (`new counter agent`)

Neste exemplo prático exploramos de forma exaustiva como a `pool` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 31.3.5. Exemplo 5: Agente de registo *append-only* (`new log agent`) e armazenamento chave-valor em memória por passagem de mensagens (`new kv agent`)

Neste exemplo prático exploramos de forma exaustiva como a `pool` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 31.3.6. Exemplo 6: Encaminhamento determinístico por chave (`pool ask shard`), difusão (`pool broadcast`), drenagem não bloqueante (`pool drain all`) e encerramento (`pool shutdown`)

Neste exemplo prático exploramos de forma exaustiva como a `pool` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 31.3.7. Exemplo 7: Encaminhamento por chave (`pool ask shard`): mesma chave, mesmo agente; chaves à vez, agentes à vez; broadcast e paragem

Neste exemplo prático exploramos de forma exaustiva como a `pool` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

---

## 31.4. Debaixo do capô: como a `pool` é construída em Ridgun puro (`src/main/ridgun/lib/pool.ridgun`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/pool.ridgun` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 31.4.1. Implementação interna: Pool Size, Agent Selection, and Request-Reply by Key

Observe como `pool.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

### 31.4.2. Implementação interna: Broadcast, Non-Blocking Drain, and Shutdown

Observe como `pool.ridgun` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

## 31.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `pool`

- **Garantia algorítmica e de segurança**: O número de agentes é fixado quando o pool é construído, pelo que a memória do pool é limitada, e o encaminhamento por `abs(key) % size` é determinístico: a mesma chave chega sempre ao mesmo agente.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/pool.ridgun` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test pool.ridgun`.

### As 5 Regras de Ouro ao programar com a `pool`

1. **Declare `import pool` no início do ficheiro** e chame as suas funções com espaços, tal como estão declaradas, para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `pool` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `pool` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `pool` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 32** passaremos a explorar em profundidade a lib **`net_agent`** (A lib `net_agent` — Um Agente por Ligação: Sondagem Não Bloqueante e Varrimento do Reator).
