# Capítulo 30: A lib `agent` — Modelo Nativo de Atores (`agent`, `send`, `receive`), KV Store e Rate Limiter

## 1. Por que existe a lib `agent`?

Sejamos sinceros: partilhar memória mutável entre threads com `Mutex`, `RwLock` e variáveis de condição é uma fábrica inesgotável de *deadlocks* e condições de corrida.

A lib **`agent`** tira partido do **Modelo Nativo de Agentes** do Ridgun (`agent`, `send ... to`, `receive from`, `try receive from`, `stop`) para oferecer caixas de correio isoladas com passagem de mensagens Copy-on-Write, um armazém chave-valor concorrente (`KvStore`), um limitador de taxa *token-bucket* (`RateBucket`) e supervisão (`AgentHealth`).

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`agent`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/agent.rg` (domínio `AGENT`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/agent.rglib` | Distribuição e importação direta com `import agent` |
| **Ficheiro compilado** | `target/agent.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libagent.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import agent` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `agent`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `agent roundtrip / agent drain count` | Lança atores nativos (`agent`), troca mensagens (`send ... to` / `receive from`) e executa `stop` |
| `kv store new / kv store apply` | Armazém chave-valor imutável para atores (`KvPut`, `KvGet`, `KvDelete`, `KvClear`) |
| `rate bucket new / rate bucket allow` | Limitador de taxa *token-bucket* que devolve o balde atualizado e `(allowed, remaining)` |
| `sup mark failed / sup should restart` | Políticas de supervisão com controlo de orçamento de reinícios (`max_restarts`) |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `agent`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import agent

fn :: probar actor nativo () => (Int, Int)
      probar actor nativo =
        eco = agent roundtrip 42
        vac = agent drain count [10, 20, 30]
        (eco, vac)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `agent` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import agent

fn :: aplicar limite peticion () => (Bool, Int)
      aplicar limite peticion =
        b0         = rate bucket new 10 2 1000
        (b1, res1) = rate bucket allow b0 1 1000
        rateresp allowed res1, rateobs remaining res1
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Zero memória mutável partilhada entre atores: cada mensagem é transferida por valor / Copy-on-Write e `stop` liberta a região do agente de forma determinística.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_agent.rg`.
