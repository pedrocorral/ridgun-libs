# Capítulo 32: A lib `net_agent` — Supervisor de Ligações de Rede e Ponte de Eventos Não Bloqueante

## 32.1. Por que existe a lib `net_agent`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `net_agent` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `net_agent`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: num servidor real como o **Solstice**, aceitar ligações TCP é a parte fácil; o difícil é limitar o máximo de clientes simultâneos, desconectar clientes zombies inativos (*idle timeout*) e ligar o ciclo `ppoll` aos seus atores sem fugas de descritores.

A lib **`net_agent`** fecha o círculo do `ridgun-libs` unindo **`posix`**, **`socket`** e **`agent`**: gere tabelas de ligações supervisionadas (`NetSupervisor`), aplica limites de concorrência (`max_conns`), purga ligações inativas (`net evict idle`) e converte eventos de descritores do kernel em eventos tipados (`NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout`, `NetEvError`), além de fornecer um passo de eco TCP completo (`net tcp echo step`).

Num ecossistema tradicional, resolver as tarefas do domínio **`AGENT`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`net_agent`** (`src/main/ridgun/lib/net_agent.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Funções totais e contratos explícitos (`=>`)**: nenhuma função da `net_agent` lança exceções ocultas nem depende de `null`. Qualquer caso limite devolve um valor sentinela documentado ou um tipo algébrico soma (`Option`, `Result`).
2. **Zero código C e zero `libc`**: todo o código da `net_agent` compila diretamente para código máquina nativo ELF64 verificado pelo `ridgunc`.
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `net_agent` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 32.2. Artefactos nativos, importação e catálogo completo da API de `net_agent`

No `ridgun-libs`, **`net_agent`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/net_agent.rg` (domínio `AGENT`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/net_agent.rglib` | Distribuição e importação direta com `import net_agent` |
| **Ficheiro compilado** | `target/net_agent.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libnet_agent.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import net_agent` no topo e invocar as suas funções com espaços ou underscores.

### 32.2.1. Resumo das famílias funcionais da `net_agent`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `net supervisor new : Int -> Int -> NetSupervisor` | Cria um supervisor de ligações com limite `max_conns` e inatividade `idle_timeout_ms` |
| `net register conn / net record rx / net record tx / net close conn` | Regista sockets aceites, atualiza contadores de bytes/atividade e fecha pares |
| `net evict idle : NetSupervisor -> Int -> (NetSupervisor, [Int])` | Fecha e expulsa ligações inativas além de `idle_timeout_ms`, devolvendo os respetivos FDs |
| `net poll fd : Int -> Bool -> Int -> NetEvent` | Ponte `wait fd` não bloqueante que emite `NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout` ou `NetEvError` |
| `net tcp echo step : String -> Int -> (Int, String)` | Passo completo de ponta a ponta TCP loopback (`listen/connect/accept/supervise/echo`) |

### 32.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/net_agent.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/net_agent.rg` (`2` tipos, `0` operadores e `8` funções):

**Tipos algébricos e registos (`type`) da `net_agent`:**

```ridgun
type ConnSlot = ConnSlot Int Agent
type StepOutcome = ConnKeep ConnSlot String | ConnClosed
```

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
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

## 32.3. Explorando a `net_agent` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `net_agent` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test net_agent.rg`.

### 32.3.1. Exemplo 1: Fluxo principal em estilo tabular com `net_agent`

Repare como em Ridgun os sinais `=` e os passos de transformação com `net_agent` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

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

### 32.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `net_agent` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import net_agent

fn :: probar puente tcp supervisado () => (Int, String)
      probar puente tcp supervisado =
        net tcp echo step "ping-supervisado" 1000
```

### 32.3.3. Exemplo 3: Combinadores de atores (`agent ask`, `try ask`, `send batch`, `map batch`, `drain ready`), pools particionados e reator de conexões

Neste exemplo prático exploramos de forma exaustiva como a `net_agent` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 32.3.4. Exemplo 4: Ciclo de vida de agentes (`is agent alive`, `agent status`, `stop agent`) e agente contador com estado isolado (`new counter agent`)

Neste exemplo prático exploramos de forma exaustiva como a `net_agent` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 32.3.5. Exemplo 5: Agente de registo *append-only* (`new log agent`) e armazenamento chave-valor em memória por passagem de mensagens (`new kv agent`)

Neste exemplo prático exploramos de forma exaustiva como a `net_agent` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 32.3.6. Exemplo 6: Sondagem não bloqueante de descritores (`conn poll step`), varrimento de tabela de conexões (`reactor sweep`) e encerramento limpo (`reactor shutdown`)

Neste exemplo prático exploramos de forma exaustiva como a `net_agent` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

## 32.4. Debaixo do capô: como a `net_agent` é construída em Ridgun puro (`src/main/ridgun/lib/net_agent.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/net_agent.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 32.4.1. Implementação interna: Core Implementation Part 1

Observe como `net_agent.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

### 32.4.2. Implementação interna: Core Implementation Part 2

Observe como `net_agent.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

## 32.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `net_agent`

- **Garantia algorítmica e de segurança**: Proteção automática contra esgotamento de descritores (`max_conns`), expulsão determinística de ligações inativas e fecho garantido de sockets em `net tcp echo step`.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/net_agent.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test net_agent.rg`.

### As 5 Regras de Ouro ao programar com a `net_agent`

1. **Declare `import net_agent` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `net_agent` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `net_agent` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `net_agent` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

Concluiu o percurso exaustivo pelas **32 libs padrão do `ridgun-libs`**! Agora tem nas suas mãos todas as peças para construir aplicações e ferramentas de sistemas completas em Ridgun puro.
