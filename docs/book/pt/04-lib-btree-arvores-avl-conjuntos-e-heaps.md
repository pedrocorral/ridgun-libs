# Capítulo 04: A lib `btree` — Árvores AVL Persistentes $O(\log N)$, Conjuntos e Heaps

## 1. Por que existe a lib `btree`?

Sejamos sinceros: tabelas de hash mutáveis sofrem ataques de colisão de chaves (HashDoS), não mantêm as chaves ordenadas para consultas por intervalo e não podem ser partilhadas entre atores sem bloqueios.

A lib **`btree`** implementa três estruturas de dados funcionais persistentes em $O(\log N)$ com partilha estrutural: **`BTreeMap`** (árvore AVL autobalanceada), **`BTreeSet`** (álgebra de conjuntos ordenada) e **`MinHeap`** (fila de prioridade *leftist heap*).

---

## 2. Artefactos, importação e arquitetura sem `libc`

No `ridgun-libs`, **`btree`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/btree.rg` (domínio `BTREE`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/btree.rglib` | Distribuição e importação direta com `import btree` |
| **Ficheiro compilado** | `target/btree.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libbtree.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import btree` no topo e invocar as suas funções com espaços ou underscores.

---

## 3. Referência rápida da API de `btree`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `btree empty / btree insert / btree get / btree remove` | Pesquisa, inserção e remoção persistente em dicionário AVL em $O(\log N)$ |
| `btree min key / btree max key / btree range` | Extremos ordenados e consulta por intervalo `[lo, hi]` |
| `bset from list / bset union / bset intersect / bset diff` | Álgebra de conjuntos ordenados (`BTreeSet`) e predicado de subconjunto |
| `heap empty / heap push / heap peek / heap pop / heap sort` | Fila de prioridade `MinHeap` (*leftist heap*) com fusão em $O(\log N)$ |

---

## 4. Receitas práticas em estilo tabular

### Receita 1: Fluxo principal com `btree`

Repare como os sinais `=` e os passos de transformação ficam alinhados como uma tabela limpa:

```ridgun
import btree

fn :: consultar rango precios () => [String String]
      consultar rango precios =
        t0 = btree empty
        t1 = btree insert t0 "item:10" "Teclado"
        t2 = btree insert t1 "item:20" "Monitor"
        t3 = btree insert t2 "item:30" "Raton"
        btree range t3 "item:10" "item:25"
```

### Receita 2: Composição segura e sem efeitos colaterais

Todas as funções da lib `btree` compõem-se perfeitamente com as restantes 32 libs do `ridgun-libs`:

```ridgun
import btree

fn :: despachar urgente () => (Int, String)
      despachar urgente =
        h0 = heap empty
        h1 = heap push h0 50 "backup-nocturno"
        h2 = heap push h1 10 "alerta-seguridad"
        h3 = heap push h2 30 "rotar-logs"
        heap peek h3
```

---

## 5. Debaixo do capô: desempenho, memória RMM e garantias

- **Garantia algorítmica e de segurança**: Rotações AVL estritas (`height diff <= 1`), imunidade total a HashDoS, consultas por intervalo em $O(\log N + K)$ e fusão de heaps em $O(\log N)$.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test_btree.rg`.
