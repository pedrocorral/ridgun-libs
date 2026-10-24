# Capítulo 03: A lib `list` — Listas, Mergesort $O(N \log N)$ e Mapas Chave-Valor

## 1. Por que existe a lib `list`?

Sejamos sinceros: aceder a um índice fora de limites (`IndexError` / `panic!`) ou mutar acidentalmente uma lista partilhada são dois dos erros mais comuns ao processar coleções.

A lib **`list`** fornece indexação segura com valor padrão, fatiamento (`take`, `drop`, `slice`), intervalos com passo, desduplicação estável, ordenação **mergesort $O(N \log N)$** para `[Int]` e `[String]`, e mapas associativos imutáveis `[String String]` (`kv get`, `kv put`, `kv merge`).

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`list`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/list.rg` (domínio `LIST`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/list.rglib` | Distribuição e importação direta com `import list` |
| **Ficheiro compilado** | `target/list.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/liblist.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import list` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `list`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `list nth or / list str nth or` | Leitura segura por índice devolvendo `default_val` se fora de limites |
| `list take / list drop / list slice / list reverse` | Prefixo, sufixo, subintervalo `[start, end)` e inversão recursiva de cauda |
| `list range / list range step` | Gera sequências aritméticas (`step == 0` devolve `[]` em segurança) |
| `list sort / list str sort / list dedup / list str dedup` | Ordenação mergesort $O(N \log N)$ estável e desduplicação pela primeira ocorrência |
| `kv empty / kv put / kv get / kv get or / kv remove / kv merge` | Operações sobre dicionários associativos ordenados `[String String]` |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `list`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import list

fn :: top tres unicos (puntos : [Int]) => [Int]
      top tres unicos puntos =
        unicos    = list dedup puntos
        ordenados = list reverse (list sort unicos)
        list take ordenados 3
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `list` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import list

fn :: configurar entorno (base : [String String]) => (String, [String])
      configurar entorno base =
        cfg1 = kv put base "host" "0.0.0.0"
        cfg2 = kv put cfg1 "port" "8080"
        host = kv get or cfg2 "host" "127.0.0.1"
        (host, kv keys cfg2)
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Ordenação determinística $O(N \log N)$ no pior caso (sem o $O(N^2)$ patológico do Quicksort) e preservação da ordem de inserção nos mapas `kv`.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_list.rg`.
