# Capítulo 12: A lib `glob` — Padrões de Wildcards (`*`, `?`, `[a-z]`) e Filtragem de Listas

## 1. Por que existe a lib `glob`?

Sejamos sinceros: usar uma expressão regular completa só para verificar se um ficheiro termina em `*.rg` ou começa por `test_[0-9]*.rg` é matar moscas com tiros de canhão.

A lib **`glob`** implementa correspondência exata de wildcards de shell (`*`, `?`, classes `[a-z]`, classes negadas `[!0-9]` / `[^a-z]`), variantes insensíveis a maiúsculas (`glob match ci`) e filtragem direta de listas.

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`glob`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/glob.rg` (domínio `GLOB`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/glob.rglib` | Distribuição e importação direta com `import glob` |
| **Ficheiro compilado** | `target/glob.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libglob.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import glob` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `glob`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `glob match / glob match ci` | Correspondência de padrões glob sensível e insensível a maiúsculas ASCII |
| `glob filter / glob any match` | Filtra `[String]` por padrão ou verifica se algum padrão de uma lista corresponde |
| `glob has magic` | Deteta se uma cadeia contém metacaracteres de wildcard (`*`, `?`, `[`) |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `glob`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import glob

fn :: seleccionar fuentes ridgun (archivos : [String]) => [String]
      seleccionar fuentes ridgun archivos =
        glob filter "test_[a-z]*.rg" archivos
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `glob` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import glob

fn :: es ruta excluida (ruta : String) => Bool
      es ruta excluida ruta =
        glob any match ["*.tmp", "*.bak", "target/*"] ruta
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Colapso automático de asteriscos consecutivos (`***` $\rightarrow$ `*`) para evitar retrocessos redundantes e tratamento seguro de parênteses retos `[` não fechados.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_glob.rg`.
