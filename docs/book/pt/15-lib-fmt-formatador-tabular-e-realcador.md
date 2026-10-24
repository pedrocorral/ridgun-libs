# Capítulo 15: A lib `fmt` — Formatador Tabular Canónico 2D e Realçador de Sintaxe em 9 Formatos

## 1. Por que existe a lib `fmt`?

Sejamos sinceros: a beleza do código Ridgun reside nas suas colunas tabulares perfeitamente alinhadas (`::`, `=`, `|`, `->`, `--`), mas alinhar espaços à mão ou exportar código colorido para terminal, HTML e LaTeX é trabalhoso.

A lib **`fmt`** é o motor oficial de formatação tabular 2D e realce léxico do Ridgun: alinha assinaturas `fn ::`, equações, guardas `|` e comentários `--`, e exporta para **9 formatos de saída** (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`).

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`fmt`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/fmt.rg` (domínio `FMT`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/fmt.rglib` | Distribuição e importação direta com `import fmt` |
| **Ficheiro compilado** | `target/fmt.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libfmt.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import fmt` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `fmt`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `fmt source / fmt source with` | Formata código-fonte Ridgun usando o alinhamento tabular 2D canónico |
| `fmt check` | Devolve `True` se o código já cumprir o formato tabular canónico de `fmt source` |
| `fmt render / fmt render with` | Formata e realça o código para qualquer um dos 9 formatos `FmtTarget` |
| `fmt tokenize line` | Tokeniza uma linha em `TokKeyword`, `TokType`, `TokOperator`, `TokString`, `TokNumber`, `TokComment` |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `fmt`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import fmt

fn :: formatear y verificar (codigo : String) => (String, Bool)
      formatear y verificar codigo =
        limpio = fmt source codigo
        es_ok  = fmt check limpio
        (limpio, es_ok)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `fmt` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import fmt

fn :: exportar bloque html (codigo : String) => String
      exportar bloque html codigo =
        fmt render codigo FmtHtmlCss
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Idempotência estrita (`fmt source (fmt source s) == fmt source s`) e preservação de 100 % dos tokens semânticos.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_fmt.rg`.
