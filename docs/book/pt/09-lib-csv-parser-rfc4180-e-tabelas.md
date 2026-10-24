# Capítulo 09: A lib `csv` — Analisador de Estados RFC 4180 para CSV/TSV e Tabelas Indexadas

## 1. Por que existe a lib `csv`?

Sejamos sinceros: toda a gente acha que analisar um CSV é fazer `str split linha ","`... até aparecer um campo entre aspas com uma vírgula lá dentro, aspas duplicadas `""` ou uma quebra de linha `\r\n` a meio de uma célula.

A lib **`csv`** implementa uma máquina de estados completa conforme a **RFC 4180** para CSV e TSV, serialização automática com aspas inteligentes e o tipo `CsvTable` para consultar colunas e linhas pelo nome do cabeçalho.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`csv`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/csv.rg` (domínio `CSV`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/csv.rglib` | Distribuição e importação direta com `import csv` |
| **Ficheiro compilado** | `target/csv.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libcsv.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import csv` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `csv`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `csv parse / tsv parse / csv parse with` | Analisa texto CSV/TSV (incluindo células multilinha e escapes `""`) em `[[String]]` |
| `csv stringify / tsv stringify` | Serializa `[[String]]` colocando aspas apenas em células com delimitadores, aspas ou quebras |
| `csv parse table / csv get cell / csv col` | Consulta sobre `CsvTable` indexada por cabeçalho `(linha, nome_col)` ou coluna inteira |
| `csv row to kv / csv table to kv list` | Converte linhas tabulares em dicionários `[String String]` indexados pelo cabeçalho |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `csv`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import csv

fn :: extraer columna precios (raw_csv : String) => ([String], String)
      extraer columna precios raw_csv =
        tabla   = csv parse table raw_csv
        precios = csv col tabla "precio"
        primero = csv get cell tabla 0 "producto" "desconocido"
        (precios, primero)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `csv` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import csv

fn :: exportar informe () => String
      exportar informe =
        filas = [["id", "nota"], ["1", "Contiene, coma"], ["2", "Dijo "hola""]]
        csv stringify filas
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Suporte exato de quebras `\r\n` e `\n` dentro e fora de aspas, e zero perda de dados em viagens de ida e volta `csv parse (csv stringify linhas)`.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_csv.rg`.
