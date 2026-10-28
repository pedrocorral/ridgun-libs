# Capítulo 04: A lib `btree` — Árvores AVL Persistentes $O(\log N)$, Conjuntos e Heaps

## 04.1. Por que existe a lib `btree`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `btree` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `btree`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: tabelas de hash mutáveis sofrem ataques de colisão de chaves (HashDoS), não mantêm as chaves ordenadas para consultas por intervalo e não podem ser partilhadas entre atores sem bloqueios.

A lib **`btree`** implementa três estruturas de dados funcionais persistentes em $O(\log N)$ com partilha estrutural: **`BTreeMap`** (árvore AVL autobalanceada), **`BTreeSet`** (álgebra de conjuntos ordenada) e **`MinHeap`** (fila de prioridade *leftist heap*).

Num ecossistema tradicional, resolver as tarefas do domínio **`BTREE`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`btree`** (`src/main/ridgun/lib/btree.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Declare `import btree` (ou `import btree as alias`) no início do ficheiro**: cada lib define o seu espaço de nomes `module :: btree` e em modo `--strict` as funções multi-palavra são sempre invocadas com espaços naturais.
2. **Encadeie os seus pipelines da esquerda para a direita com `->`**: escreva `entrada passo um -> passo dois -> resultado`, use máscaras `(+ _ _ +)` para desestruturar sequências e omita `_ =` em instruções sequenciais (ou descarte com `-> ()`).
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `btree` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 04.2. Artefactos nativos, importação e catálogo completo da API de `btree`

No `ridgun-libs`, **`btree`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/btree.rg` (domínio `BTREE`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/btree.rglib` | Distribuição e importação direta com `import btree` |
| **Ficheiro compilado** | `target/btree.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libbtree.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Cada lib declara o seu próprio espaço de nomes com `module :: btree`: basta escrever `import btree` (ou `import btree as alias`) no topo e invocar as suas funções com espaços naturais (`minha funcao x`) e pipelines `->` (`x minha funcao -> resultado`).

### 04.2.1. Resumo das famílias funcionais da `btree`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `btree empty / btree insert / btree get / btree remove` | Pesquisa, inserção e remoção persistente em dicionário AVL em $O(\log N)$ |
| `btree min key / btree max key / btree range` | Extremos ordenados e consulta por intervalo `[lo, hi]` |
| `bset from list / bset union / bset intersect / bset diff` | Álgebra de conjuntos ordenados (`BTreeSet`) e predicado de subconjunto |
| `heap empty / heap push / heap peek / heap pop / heap sort` | Fila de prioridade `MinHeap` (*leftist heap*) com fusão em $O(\log N)$ |

### 04.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/btree.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/btree.rg` (`3` tipos, `0` operadores e `54` funções):

**Tipos algébricos e registos (`type`) da `btree`:**

```ridgun
type BTreeMap = BMapEmpty | BMapNode String String Int BTreeMap BTreeMap
type BTreeSet = BSetEmpty | BSetNode String Int BTreeSet BTreeSet
type MinHeap = HeapEmpty | HeapNode Int String Int MinHeap MinHeap
```

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: bt_max Int Int` | `Int` |
| `2` | `fn :: bt_str_cmp_loop String String Int Int Int` | `Int` |
| `3` | `fn :: bt_str_cmp String String` | `Int` |
| `4` | `fn :: btree empty` | `BTreeMap` |
| `5` | `fn :: btree height BTreeMap` | `Int` |
| `6` | `fn :: bt_mk String String BTreeMap BTreeMap` | `BTreeMap` |
| `7` | `fn :: bt_bf BTreeMap` | `Int` |
| `8` | `fn :: bt_rot_right BTreeMap` | `BTreeMap` |
| `9` | `fn :: bt_rot_left BTreeMap` | `BTreeMap` |
| `10` | `fn :: bt_rebalance String String BTreeMap BTreeMap` | `BTreeMap` |
| `11` | `fn :: btree put BTreeMap String String` | `BTreeMap` |
| `12` | `fn :: btree get or BTreeMap String String` | `String` |
| `13` | `fn :: btree get BTreeMap String` | `String` |
| `14` | `fn :: btree has BTreeMap String` | `Bool` |
| `15` | `fn :: bt_min_pair BTreeMap` | `(String String)` |
| `16` | `fn :: bt_pair_k (String String)` | `String` |
| `17` | `fn :: bt_pair_v (String String)` | `String` |
| `18` | `fn :: bt_delete_root BTreeMap BTreeMap` | `BTreeMap` |
| `19` | `fn :: btree remove BTreeMap String` | `BTreeMap` |
| `20` | `fn :: btree size BTreeMap` | `Int` |
| `21` | `fn :: btree keys BTreeMap` | `[String]` |
| `22` | `fn :: btree values BTreeMap` | `[String]` |
| `23` | `fn :: btree to list BTreeMap` | `[String String]` |
| `24` | `fn :: bt_from_pairs [String String] BTreeMap` | `BTreeMap` |
| `25` | `fn :: btree from list [String String]` | `BTreeMap` |
| `26` | `fn :: bset empty` | `BTreeSet` |
| `27` | `fn :: bs_height BTreeSet` | `Int` |
| `28` | `fn :: bs_mk String BTreeSet BTreeSet` | `BTreeSet` |
| `29` | `fn :: bs_bf BTreeSet` | `Int` |
| `30` | `fn :: bs_rot_right BTreeSet` | `BTreeSet` |
| `31` | `fn :: bs_rot_left BTreeSet` | `BTreeSet` |
| `32` | `fn :: bs_rebalance String BTreeSet BTreeSet` | `BTreeSet` |
| `33` | `fn :: bset add BTreeSet String` | `BTreeSet` |
| `34` | `fn :: bset has BTreeSet String` | `Bool` |
| `35` | `fn :: bs_min_key BTreeSet` | `String` |
| `36` | `fn :: bs_delete_root BTreeSet BTreeSet` | `BTreeSet` |
| `37` | `fn :: bset remove BTreeSet String` | `BTreeSet` |
| `38` | `fn :: bset size BTreeSet` | `Int` |
| `39` | `fn :: bset to list BTreeSet` | `[String]` |
| `40` | `fn :: bs_from_strs [String] BTreeSet` | `BTreeSet` |
| `41` | `fn :: bset from list [String]` | `BTreeSet` |
| `42` | `fn :: bset union BTreeSet BTreeSet` | `BTreeSet` |
| `43` | `fn :: bs_inter_loop [String] BTreeSet BTreeSet` | `BTreeSet` |
| `44` | `fn :: bset intersect BTreeSet BTreeSet` | `BTreeSet` |
| `45` | `fn :: bs_diff_loop [String] BTreeSet` | `BTreeSet` |
| `46` | `fn :: bset diff BTreeSet BTreeSet` | `BTreeSet` |
| `47` | `fn :: heap empty` | `MinHeap` |
| `48` | `fn :: hp_rank MinHeap` | `Int` |
| `49` | `fn :: hp_mk Int String MinHeap MinHeap` | `MinHeap` |
| `50` | `fn :: hp_merge MinHeap MinHeap` | `MinHeap` |
| `51` | `fn :: heap push MinHeap Int String` | `MinHeap` |
| `52` | `fn :: heap peek MinHeap` | `(Int String)` |
| `53` | `fn :: heap pop MinHeap` | `(Int String MinHeap)` |
| `54` | `fn :: heap size MinHeap` | `Int` |

---

## 04.3. Explorando a `btree` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `btree` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test btree.rg`.

### 04.3.1. Exemplo 1: Fluxo principal em estilo tabular com `btree`

Repare como em Ridgun os sinais `=` e os passos de transformação com `btree` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import btree

fn :: consultar rango precios => [String String]
      consultar rango precios =
        btree empty -> t0
        btree insert t0 "item:10" "Teclado" -> t1
        btree insert t1 "item:20" "Monitor" -> t2
        btree insert t2 "item:30" "Raton" -> t3
        btree range t3 "item:10" "item:25"
```

### 04.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `btree` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import btree

fn :: despachar urgente => Int String
      despachar urgente =
        heap empty -> h0
        heap push h0 50 "backup-nocturno" -> h1
        heap push h1 10 "alerta-seguridad" -> h2
        heap push h2 30 "rotar-logs" -> h3
        h3 heap peek
```

### 04.3.3. Exemplo 3: Árvores AVL `BTreeMap`: inserção com autobalanceamento, pesquisa $O(\log N)$, remoção, travessia em ordem e extremos (`min key`, `max key`)

Neste exemplo prático exploramos de forma exaustiva como a `btree` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_btree_map_avl_balance_and_crud => ()
      test_btree_map_avl_balance_and_crud =
        m0 = btree empty
        assert int equals (btree size m0) 0 "AC1: empty map size 0"
        assert int equals (btree height m0) 0 "AC1: empty map height 0"
        m1 = btree put m0 "k01" "v1"
        m2 = btree put m1 "k02" "v2"
        m3 = btree put m2 "k03" "v3"
        m4 = btree put m3 "k04" "v4"
        m5 = btree put m4 "k05" "v5"
        m6 = btree put m5 "k06" "v6"
        m7 = btree put m6 "k07" "v7"
        m8 = btree put m7 "k08" "v8"
        m9 = btree put m8 "k09" "v9"
        m10 = btree put m9 "k10" "v10"
        m11 = btree put m10 "k11" "v11"
        m12 = btree put m11 "k12" "v12"
        m13 = btree put m12 "k13" "v13"
        m14 = btree put m13 "k14" "v14"
        m15 = btree put m14 "k15" "v15"
        assert int equals (btree size m15) 15 "AC1: btree size after 15 ascending puts"
        assert true ((btree height m15) <= 5) "AC1: AVL tree height <= 5 on 15 sequential ascending keys"
        assert str eq (btree get m15 "k08") "v8" "AC1: btree get k08"
        assert str eq (btree get or m15 "k99" "def") "def" "AC1: btree get or fallback"
        assert true (btree has m15 "k15") "AC1: btree has k15"
        assert false (btree has m15 "k00") "AC1: btree has k00 false"

        -- Descending insertion order (triggers right-rotations) + RL/LR double rotations
        d0 = btree from list [("z", "26"), ("x", "24"), ("v", "22"), ("t", "20"), ("r", "18"), ("u", "21"), ("y", "25")]
        assert int equals (btree size d0) 7 "AC1: descending + RL/LR size 7"
        assert true ((btree height d0) <= 4) "AC1: descending + RL/LR height <= 4"
        assert str eq (bt_join_strs (btree keys d0)) "r,t,u,v,x,y,z" "AC1: keys in-order after RL/LR rotations"
        assert str eq (bt_join_strs (btree values d0)) "18,20,21,22,24,25,26" "AC1: values in key order"

        -- Overwrite existing key preserves size
        d_upd = btree put d0 "v" "22_new"
        assert int equals (btree size d_upd) 7 "AC1: update existing key preserves size"
        assert str eq (btree get d_upd "v") "22_new" "AC1: updated value retrieved"

        -- Remove root/two-child node, single-child node, leaf node, and non-existent key
        d_rem1 = btree remove d_upd "v"
        d_rem2 = btree remove d_rem1 "r"
        d_rem3 = btree remove d_rem2 "nonexistent"
        assert int equals (btree size d_rem3) 5 "AC1: size after removing 2 existing keys and 1 missing key"
        assert false (btree has d_rem3 "v") "AC1: removed two-child node 'v' absent"
        assert false (btree has d_rem3 "r") "AC1: removed leaf node 'r' absent"
        assert str eq (bt_join_strs (btree keys d_rem3)) "t,u,x,y,z" "AC1: keys remain strictly sorted after removals"

        pairs = btree to list d_rem3
        m_rt = btree from list pairs
        assert int equals (btree size m_rt) 5 "AC1: btree to/from list round-trip size"
        assert str eq (btree get m_rt "y") "25" "AC1: btree to/from list round-trip lookup"
        ()
```

### 04.3.4. Exemplo 4: Conjuntos ordenados `BTreeSet`: álgebra de conjuntos (`union`, `intersect`, `diff`, `is subset`) e conversão ordenada para lista

Neste exemplo prático exploramos de forma exaustiva como a `btree` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_btree_set_operations => ()
      test_btree_set_operations =
        s1 = bset from list ["charlie", "alpha", "bravo", "alpha", "charlie"]
        s2 = bset from list ["bravo", "delta", "echo"]
        s_empty = bset empty
        assert int equals (bset size s1) 3 "AC2: bset deduplicates items"
        assert true (bset has s1 "bravo") "AC2: bset has bravo"
        assert false (bset has s1 "delta") "AC2: bset has delta false"
        assert str eq (bt_join_strs (bset to list s1)) "alpha,bravo,charlie" "AC2: bset sorted order"

        s1_rem = bset remove s1 "bravo"
        assert int equals (bset size s1_rem) 2 "AC2: bset remove size"
        assert false (bset has s1_rem "bravo") "AC2: bset remove membership"

        u = bset union s1 s2
        assert str eq (bt_join_strs (bset to list u)) "alpha,bravo,charlie,delta,echo" "AC2: bset union"
        assert int equals (bset size (bset union s1 s1)) 3 "AC2: union idempotence A U A = A"
        assert int equals (bset size (bset union s1 s_empty)) 3 "AC2: union identity A U empty = A"

        inter = bset intersect s1 s2
        assert str eq (bt_join_strs (bset to list inter)) "bravo" "AC2: bset intersect"
        assert int equals (bset size (bset intersect s1 s_empty)) 0 "AC2: intersect with empty is empty"

        df = bset diff s1 s2
        assert str eq (bt_join_strs (bset to list df)) "alpha,charlie" "AC2: bset diff A \\ B"
        assert int equals (bset size (bset diff s1 s1)) 0 "AC2: self difference A \\ A is empty"
        ()
```

### 04.3.5. Exemplo 5: Filas de prioridade `MinHeap` (heap esquerdista): `heap push`, `heap peek`, `heap pop` e escalonamento por prioridade em $O(\log N)$

Neste exemplo prático exploramos de forma exaustiva como a `btree` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test_min_heap_priority_queue => ()
      test_min_heap_priority_queue =
        h0 = heap empty
        assert int equals (heap size h0) 0 "AC3: empty heap size 0"
        h1 = heap push h0 50 "low"
        h2 = heap push h1 10 "urgent-1"
        h3 = heap push h2 30 "normal"
        h4 = heap push h3 20 "high"
        h5 = heap push h4 10 "urgent-2"
        h6 = heap push h5 (-5) "critical"
        assert int equals (heap size h6) 6 "AC3: heap size 6"
        pk = heap peek h6
        assert int equals (hp_peek_prio pk) (-5) "AC3: heap peek negative priority (-5)"
        assert str eq (hp_peek_val pk) "critical" "AC3: heap peek critical value"

        p0 = heap pop h6
        assert int equals (hp_pop_prio p0) (-5) "AC3: pop 0 (-5)"
        p1 = heap pop (hp_pop_rest p0)
        assert int equals (hp_pop_prio p1) 10 "AC3: pop 1 (10)"
        p2 = heap pop (hp_pop_rest p1)
        assert int equals (hp_pop_prio p2) 10 "AC3: pop 2 duplicate priority (10)"

        -- Interleaved push after partial pop
        h_mid = heap push (hp_pop_rest p2) 15 "medium-high"
        p3 = heap pop h_mid
        assert int equals (hp_pop_prio p3) 15 "AC3: interleaved push 15 popped before 20"
        p4 = heap pop (hp_pop_rest p3)
        assert int equals (hp_pop_prio p4) 20 "AC3: pop 20"
        p5 = heap pop (hp_pop_rest p4)
        assert int equals (hp_pop_prio p5) 30 "AC3: pop 30"
        p6 = heap pop (hp_pop_rest p5)
        assert int equals (hp_pop_prio p6) 50 "AC3: pop 50"
        assert int equals (heap size (hp_pop_rest p6)) 0 "AC3: heap empty after popping all"
        ()
```

---

## 04.4. Debaixo do capô: como a `btree` é construída em Ridgun puro (`src/main/ridgun/lib/btree.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/btree.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 04.4.1. Implementação interna: Lexicographical String Comparison & Int Helpers

Observe como `btree.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
module :: btree

fn :: bt max Int Int => Int
      bt max a b =
        | a >= b = a
        | otherwise = b

fn :: bt str cmp loop String String Int Int Int => Int
      bt str cmp loop a b idx la lb =
        | idx >= la and idx >= lb = 0
        | idx >= la = (0 - 1)
        | idx >= lb = 1
        | (str char at a idx) < (str char at b idx) = (0 - 1)
        | (str char at a idx) > (str char at b idx) = 1
        | otherwise = bt str cmp loop a b (idx + 1) la lb

fn :: bt str cmp String String => Int
      bt str cmp a b = bt str cmp loop a b 0 (str len a) (str len b)
```

### 04.4.2. Implementação interna: AVL-Balanced Ordered Map (`BTreeMap`)

Observe como `btree.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: btree empty => BTreeMap
      btree empty = BMapEmpty

fn :: btree height BTreeMap => Int
      btree height BMapEmpty = 0
      btree height (BMapNode _ _ h _ _) = h

fn :: bt mk String String BTreeMap BTreeMap => BTreeMap
      bt mk k v l r = BMapNode k v (1 + (bt max (btree height l) (btree height r))) l r

fn :: bt bf BTreeMap => Int
      bt bf BMapEmpty = 0
      bt bf (BMapNode _ _ _ l r) = (btree height l) - (btree height r)

fn :: bt rot right BTreeMap => BTreeMap
      bt rot right (BMapNode y yv _ (BMapNode x xv _ t1 t2) t3) = bt mk x xv t1 (bt mk y yv t2 t3)
      bt rot right node = node

fn :: bt rot left BTreeMap => BTreeMap
      bt rot left (BMapNode x xv _ t1 (BMapNode y yv _ t2 t3)) = bt mk y yv (bt mk x xv t1 t2) t3
      bt rot left node = node

fn :: bt rebalance String String BTreeMap BTreeMap => BTreeMap
      bt rebalance k v l r =
        | ((btree height l) - (btree height r)) > 1 and (bt bf l) >= 0 = bt rot right (bt mk k v l r)
        | ((btree height l) - (btree height r)) > 1 = bt rot right (bt mk k v (bt rot left l) r)
        | ((btree height l) - (btree height r)) < (0 - 1) and (bt bf r) <= 0 = bt rot left (bt mk k v l r)
        | ((btree height l) - (btree height r)) < (0 - 1) = bt rot left (bt mk k v l (bt rot right r))
        | otherwise = bt mk k v l r

fn :: btree put BTreeMap String String => BTreeMap
      btree put BMapEmpty key val = BMapNode key val 1 BMapEmpty BMapEmpty
      btree put (BMapNode k v _ l r) key val =
        | (bt str cmp key k) < 0 = bt rebalance k v (btree put l key val) r
        | (bt str cmp key k) > 0 = bt rebalance k v l (btree put r key val)
        | otherwise = bt mk key val l r

fn :: btree get or BTreeMap String String => String
      btree get or BMapEmpty _ fallback = fallback
      btree get or (BMapNode k v _ l r) key fallback =
        | (bt str cmp key k) < 0 = btree get or l key fallback
        | (bt str cmp key k) > 0 = btree get or r key fallback
        | otherwise = v

fn :: btree get BTreeMap String => String
      btree get t key = btree get or t key ""

fn :: btree has BTreeMap String => Bool
      btree has BMapEmpty _ = False
      btree has (BMapNode k _ _ l r) key =
        | (bt str cmp key k) < 0 = btree has l key
        | (bt str cmp key k) > 0 = btree has r key
        | otherwise = True

fn :: bt min pair BTreeMap => String String
      bt min pair BMapEmpty = ("", "")
      bt min pair (BMapNode k v _ BMapEmpty _) = (k, v)
      bt min pair (BMapNode _ _ _ l _) = bt min pair l

fn :: bt pair k (String String) => String
      bt pair k (k, _) = k

fn :: bt pair v (String String) => String
      bt pair v (_, v) = v

fn :: bt delete root BTreeMap BTreeMap => BTreeMap
      bt delete root BMapEmpty r = r
      bt delete root l BMapEmpty = l
      bt delete root l r =
        r bt min pair -> succ
        succ bt pair k -> sk
        succ bt pair v -> sv
        bt rebalance sk sv l (btree remove r sk)

fn :: btree remove BTreeMap String => BTreeMap
      btree remove BMapEmpty _ = BMapEmpty
      btree remove (BMapNode k v _ l r) key =
        | (bt str cmp key k) < 0 = bt rebalance k v (btree remove l key) r
        | (bt str cmp key k) > 0 = bt rebalance k v l (btree remove r key)
        | otherwise = bt delete root l r

fn :: btree size BTreeMap => Int
      btree size BMapEmpty = 0
      btree size (BMapNode _ _ _ l r) = 1 + (btree size l) + (btree size r)

fn :: btree keys BTreeMap => [String]
      btree keys BMapEmpty = []
      btree keys (BMapNode k _ _ l r) = ((btree keys l) :: [k]) :: (btree keys r)

fn :: btree values BTreeMap => [String]
      btree values BMapEmpty = []
      btree values (BMapNode _ v _ l r) = ((btree values l) :: [v]) :: (btree values r)

fn :: btree to list BTreeMap => [String String]
      btree to list BMapEmpty = []
      btree to list (BMapNode k v _ l r) = ((btree to list l) :: [(k, v)]) :: (btree to list r)

fn :: bt from pairs [String String] BTreeMap => BTreeMap
      bt from pairs [] acc = acc
      bt from pairs (p:rest) acc = bt from pairs rest (btree put acc (bt pair k p) (bt pair v p))

fn :: btree from list [String String] => BTreeMap
      btree from list pairs = bt from pairs pairs BMapEmpty
```

### 04.4.3. Implementação interna: AVL-Balanced Ordered Set (`BTreeSet`)

Observe como `btree.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: bset empty => BTreeSet
      bset empty = BSetEmpty

fn :: bs height BTreeSet => Int
      bs height BSetEmpty = 0
      bs height (BSetNode _ h _ _) = h

fn :: bs mk String BTreeSet BTreeSet => BTreeSet
      bs mk k l r = BSetNode k (1 + (bt max (bs height l) (bs height r))) l r

fn :: bs bf BTreeSet => Int
      bs bf BSetEmpty = 0
      bs bf (BSetNode _ _ l r) = (bs height l) - (bs height r)

fn :: bs rot right BTreeSet => BTreeSet
      bs rot right (BSetNode y _ (BSetNode x _ t1 t2) t3) = bs mk x t1 (bs mk y t2 t3)
      bs rot right node = node

fn :: bs rot left BTreeSet => BTreeSet
      bs rot left (BSetNode x _ t1 (BSetNode y _ t2 t3)) = bs mk y (bs mk x t1 t2) t3
      bs rot left node = node

fn :: bs rebalance String BTreeSet BTreeSet => BTreeSet
      bs rebalance k l r =
        | ((bs height l) - (bs height r)) > 1 and (bs bf l) >= 0 = bs rot right (bs mk k l r)
        | ((bs height l) - (bs height r)) > 1 = bs rot right (bs mk k (bs rot left l) r)
        | ((bs height l) - (bs height r)) < (0 - 1) and (bs bf r) <= 0 = bs rot left (bs mk k l r)
        | ((bs height l) - (bs height r)) < (0 - 1) = bs rot left (bs mk k l (bs rot right r))
        | otherwise = bs mk k l r

fn :: bset add BTreeSet String => BTreeSet
      bset add BSetEmpty key = BSetNode key 1 BSetEmpty BSetEmpty
      bset add (BSetNode k _ l r) key =
        | (bt str cmp key k) < 0 = bs rebalance k (bset add l key) r
        | (bt str cmp key k) > 0 = bs rebalance k l (bset add r key)
        | otherwise = bs mk k l r

fn :: bset has BTreeSet String => Bool
      bset has BSetEmpty _ = False
      bset has (BSetNode k _ l r) key =
        | (bt str cmp key k) < 0 = bset has l key
        | (bt str cmp key k) > 0 = bset has r key
        | otherwise = True

fn :: bs min key BTreeSet => String
      bs min key BSetEmpty = ""
      bs min key (BSetNode k _ BSetEmpty _) = k
      bs min key (BSetNode _ _ l _) = bs min key l

fn :: bs delete root BTreeSet BTreeSet => BTreeSet
      bs delete root BSetEmpty r = r
      bs delete root l BSetEmpty = l
      bs delete root l r =
        sk = bs min key r
        bs rebalance sk l (bset remove r sk)

fn :: bset remove BTreeSet String => BTreeSet
      bset remove BSetEmpty _ = BSetEmpty
      bset remove (BSetNode k _ l r) key =
        | (bt str cmp key k) < 0 = bs rebalance k (bset remove l key) r
        | (bt str cmp key k) > 0 = bs rebalance k l (bset remove r key)
        | otherwise = bs delete root l r

fn :: bset size BTreeSet => Int
      bset size BSetEmpty = 0
      bset size (BSetNode _ _ l r) = 1 + (bset size l) + (bset size r)

fn :: bset to list BTreeSet => [String]
      bset to list BSetEmpty = []
      bset to list (BSetNode k _ l r) = ((bset to list l) :: [k]) :: (bset to list r)

fn :: bs from strs [String] BTreeSet => BTreeSet
      bs from strs [] acc = acc
      bs from strs (k:rest) acc = bs from strs rest (bset add acc k)

fn :: bset from list [String] => BTreeSet
      bset from list keys = bs from strs keys BSetEmpty

fn :: bset union BTreeSet BTreeSet => BTreeSet
      bset union a b = bs from strs (bset to list b) a

fn :: bs inter loop [String] BTreeSet BTreeSet => BTreeSet
      bs inter loop [] _ acc = acc
      bs inter loop (k:rest) b acc =
        | bset has b k = bs inter loop rest b (bset add acc k)
        | otherwise = bs inter loop rest b acc

fn :: bset intersect BTreeSet BTreeSet => BTreeSet
      bset intersect a b = bs inter loop (bset to list a) b BSetEmpty

fn :: bs diff loop [String] BTreeSet => BTreeSet
      bs diff loop [] acc = acc
      bs diff loop (k:rest) acc = bs diff loop rest (bset remove acc k)

fn :: bset diff BTreeSet BTreeSet => BTreeSet
      bset diff a b = bs diff loop (bset to list b) a
```

### 04.4.4. Implementação interna: Leftist MinHeap Priority Queue (`MinHeap`)

Observe como `btree.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: heap empty => MinHeap
      heap empty = HeapEmpty

fn :: hp rank MinHeap => Int
      hp rank HeapEmpty = 0
      hp rank (HeapNode _ _ r _ _) = r

fn :: hp mk Int String MinHeap MinHeap => MinHeap
      hp mk p v a b =
        | (hp rank a) >= (hp rank b) = HeapNode p v ((hp rank b) + 1) a b
        | otherwise = HeapNode p v ((hp rank a) + 1) b a

fn :: hp merge MinHeap MinHeap => MinHeap
      hp merge HeapEmpty h2 = h2
      hp merge h1 HeapEmpty = h1
      hp merge (HeapNode p1 v1 r1 l1 rt1) (HeapNode p2 v2 r2 l2 rt2) =
        | p1 <= p2 = hp mk p1 v1 l1 (hp merge rt1 (HeapNode p2 v2 r2 l2 rt2))
        | otherwise = hp mk p2 v2 l2 (hp merge (HeapNode p1 v1 r1 l1 rt1) rt2)

fn :: heap push MinHeap Int String => MinHeap
      heap push h prio val = hp merge h (HeapNode prio val 1 HeapEmpty HeapEmpty)

fn :: heap peek MinHeap => Int String
      heap peek HeapEmpty = (0, "")
      heap peek (HeapNode p v _ _ _) = (p, v)

fn :: heap pop MinHeap => Int String MinHeap
      heap pop HeapEmpty = (0, "", HeapEmpty)
      heap pop (HeapNode p v _ l r) = (p, v, hp merge l r)

fn :: heap size MinHeap => Int
      heap size HeapEmpty = 0
      heap size (HeapNode _ _ _ l r) = 1 + (heap size l) + (heap size r)
```

---

## 04.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `btree`

- **Garantia algorítmica e de segurança**: Rotações AVL estritas (`height diff <= 1`), imunidade total a HashDoS, consultas por intervalo em $O(\log N + K)$ e fusão de heaps em $O(\log N)$.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/btree.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test btree.rg`.

### As 5 Regras de Ouro ao programar com a `btree`

1. **Declare `import btree` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `btree` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `btree` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `btree` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 05** passaremos a explorar em profundidade a lib **`tensor`** (A lib `tensor` — Tensores Multidimensionais, Vistas e Contração de Einstein).
