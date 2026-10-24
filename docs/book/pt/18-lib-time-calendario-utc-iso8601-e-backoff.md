# Capítulo 18: A lib `time` — Calendário Civil UTC (Hinnant), ISO-8601, Durações e Backoff

## 1. Por que existe a lib `time`?

Sejamos sinceros: as funções de data da `libc` (`localtime`, `gmtime`, `mktime`) dependem de estado global mutável (`TZ`), não são seguras entre threads e falham frequentemente nas regras de anos bissextos.

A lib **`time`** implementa o algoritmo de calendário civil gregoriano proléptico em **$O(1)$ de Howard Hinnant**, formatação e análise estrita **ISO-8601 / RFC 3339** (`YYYY-MM-DDTHH:MM:SSZ`), durações legíveis (`1h 1m 1s 5ms`) e cálculo de *exponential backoff* limitado.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`time`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/time.rg` (domínio `TIME`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/time.rglib` | Distribuição e importação direta com `import time` |
| **Ficheiro compilado** | `target/time.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libtime.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import time` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `time`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `time epoch to utc / time utc to epoch` | Conversão em $O(1)$ entre segundos Unix epoch e `(year, month, day, hour, min, sec)` |
| `time is leap year / time days in month / time day of week` | Regras de ano bissexto (`400 / 100 / 4`), dias do mês e dia ISO da semana (`1=Seg..7=Dom`) |
| `time format iso8601 / time parse iso8601` | Formata e valida marcas `YYYY-MM-DDTHH:MM:SSZ` (`-1` em datas inválidas como 30 de fev) |
| `time format duration ms / time backoff ms` | Durações legíveis e tempos de espera exponenciais limitados $base \cdot 2^{attempt}$ |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `time`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import time

fn :: registrar evento temporal (epoch_s : Int) => (String, Int, String)
      registrar evento temporal epoch_s =
        iso = time format iso8601 epoch_s
        sem = time day of week epoch_s
        dur = time format duration ms 3661005
        (iso, sem, dur)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `time` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import time

fn :: planificar reintentos () => [Int]
      planificar reintentos =
        [time backoff ms 0 100 5000, time backoff ms 1 100 5000, time backoff ms 2 100 5000, time backoff ms 9 100 5000]
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Conversão de calendário em $O(1)$ sem ciclos ano a ano e validação estrita de dias por mês (rejeitando 29 de fevereiro em anos não bissextos).
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_time.rg`.
