# Capítulo 31: A lib `pool` — Pool Limitado de Trabalhadores, Round-Robin e Work-Stealing

## 1. Por que existe a lib `pool`?

Sejamos sinceros: lançar uma nova thread ou ator por cada pedido sem limite superior (`unbounded spawning`) garante que um pico de tráfego esgota a memória do servidor em segundos.

A lib **`pool`** fornece um despachante de tarefas com **contrapressão explícita** (`PoolAccept`, `PoolRejectFull`), partição equilibrada de lotes em $K$ vias (`pool partition`), reequilíbrio por **roubo de trabalho (*work-stealing*)** (`pool steal rebalance`) e execução paralela sobre atores nativos.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`pool`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/pool.rg` (domínio `AGENT`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/pool.rglib` | Distribuição e importação direta com `import pool` |
| **Ficheiro compilado** | `target/pool.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libpool.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import pool` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `pool`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `pool new : Int -> Int -> PoolState` | Cria um pool limitado com `workers` vias e capacidade máxima `max_queue` |
| `pool submit : PoolState -> PoolTask -> (PoolState, PoolDecision)` | Coloca uma tarefa na fila em round-robin ou devolve `PoolRejectFull` se saturado |
| `pool partition / pool steal rebalance` | Divide lotes por $K$ trabalhadores e rouba metade de uma fila sobrecarregada para um trabalhador livre |
| `pool map sum / pool parallel sum2` | Despacha cargas de trabalho em paralelo sobre trabalhadores `agent` nativos |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `pool`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import pool

fn :: encolar con contrapresion () => (Int, Int)
      encolar con contrapresion =
        p0        = pool new 4 16
        tarea     = PoolTask 1 100 "indexar-bloque"
        (p1, dec) = pool submit p0 tarea
        (pool queued p1, pool accepted p1)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `pool` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import pool

fn :: sumar en paralelo () => Int
      sumar en paralelo =
        pool parallel sum2 [10, 20, 30] [40, 50, 60]
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Capacidade de fila estritamente limitada (`queued <= max_queue`) para proteger a memória sob sobrecarga e distribuição determinística entre trabalhadores.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_pool.rg`.
