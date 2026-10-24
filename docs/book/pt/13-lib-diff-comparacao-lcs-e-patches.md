# Capítulo 13: A lib `diff` — Algoritmo LCS, Distância de Edição, Unified Diff e Patches

## 1. Por que existe a lib `diff`?

Sejamos sinceros: quando um teste falha ou um ficheiro de configuração muda, um seco `"expected A, got B"` de 200 linhas obriga-o a queimar as pestanas à procura da linha exata que mudou.

A lib **`diff`** calcula a **Subsequência Comum Mais Longa (LCS)** sobre `Tensor[Int]` 2D para produzir edições mínimas (`DiffKeep`, `DiffAdd`, `DiffDel`), distância de edição, estatísticas, formato **Unified Diff** (`---`/`+++`/`@@`) e reconstrução exata com `diff apply`.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`diff`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/diff.rg` (domínio `DIFF`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/diff.rglib` | Distribuição e importação direta com `import diff` |
| **Ficheiro compilado** | `target/diff.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libdiff.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import diff` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `diff`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `type DiffOp` | `DiffKeep String | DiffDel String | DiffAdd String` |
| `diff lines / diff text` | Calcula o script mínimo de edição LCS entre listas `[String]` ou textos multilinha |
| `diff edit distance / diff stats` | Distância mínima de inserção+remoção e contagem `(kept, added, deleted)` |
| `diff format / diff unified` | Formata linhas compactas `+ / - /  ` ou Unified Diff padrão com cabeçalhos |
| `diff apply / diff apply text` | Reconstrói o documento de destino sem perdas a partir de um script de edição |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `diff`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import diff

fn :: auditar cambio (antes : String) (despues : String) => (Int, String)
      auditar cambio antes despues =
        dist   = diff edit distance ( ["host=localhost", "port=8080"] ) ( ["host=0.0.0.0", "port=8080"] )
        parche = diff unified "config.old" "config.new" antes despues
        (dist, parche)
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `diff` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import diff

fn :: verificar parche (orig : [String]) (nuevo : [String]) => [String]
      verificar parche orig nuevo =
        ops = diff lines orig nuevo
        diff apply ops
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Identidade matemática garantida $diff\_edit\_distance(a, b) == |a| + |b| - 2 \cdot LCS(a, b)$ e reconstrução sem perdas `diff apply (diff lines a b) == b`.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_diff.rg`.
