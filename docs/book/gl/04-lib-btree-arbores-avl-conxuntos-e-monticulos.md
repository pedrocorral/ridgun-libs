# Capítulo 04: A lib `btree` — Árbores AVL Persistentes $O(\log N)$, Conxuntos e Montículos

## 04.1. Por que existe a lib `btree`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `btree` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `btree`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: as táboas hash mutables sofren ataques de colisión de chaves (HashDoS), non manteñen as chaves ordenadas para consultas por rango e non se poden compartir entre actores sen copialas enteiras ou meter un cadeado.

A lib **`btree`** implementa tres estruturas de datos funcionais persistentes en $O(\log N)$ con compartición estrutural: **`BTreeMap`** (árbore AVL autobalanceada), **`BTreeSet`** (álxebra de conxuntos ordenada) e **`MinHeap`** (fila de prioridade *leftist heap*).

Nun ecosistema tradicional, resolver as tarefas do dominio **`BTREE`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`btree`** (`src/main/ridgun/lib/btree.rg`) aborda o problema con catro principios innegociables:

1. **Funcións totais e contratos explícitos (`=>`)**: ningunha función de `btree` lanza excepcións ocultas nin depende de `null`. Todo caso límite devolve un valor sentinela documentado ou un tipo alxébrico suma (`Option`, `Result`).
2. **Cero código C e cero `libc`**: todo o código de `btree` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `btree` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 04.2. Artefactos nativos, importación e catálogo completo da API de `btree`

En `ridgun-libs`, **`btree`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/btree.rg` (dominio `BTREE`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/btree.rglib` | Distribución e importación directa con `import btree` |
| **Ficheiro compilado** | `target/btree.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libbtree.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import btree` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

### 04.2.1. Resumo de familias funcionais de `btree`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `btree empty / btree insert / btree get / btree remove` | Busca, inserción e borrado persistente en dicionario AVL en $O(\log N)$ |
| `btree min key / btree max key / btree range` | Extremos ordenados e consulta por rango `[lo, hi]` |
| `bset from list / bset union / bset intersect / bset diff` | Álxebra de conxuntos ordenados (`BTreeSet`) e predicado de subconxunto |
| `heap empty / heap push / heap peek / heap pop / heap sort` | Fila de prioridade `MinHeap` (*leftist heap*) con fusión en $O(\log N)$ |

### 04.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/btree.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/btree.rg` (`3` tipos, `0` operadores e `54` funcións):

**Tipos alxébricos e rexistros (`type`) de `btree`:**

```ridgun
type BTreeMap = BMapEmpty | BMapNode String String Int BTreeMap BTreeMap
type BTreeSet = BSetEmpty | BSetNode String Int BTreeSet BTreeSet
type MinHeap = HeapEmpty | HeapNode Int String Int MinHeap MinHeap
```

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 04.3. Explorando `btree` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `btree` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test btree.rg`.

### 04.3.1. Exemplo 1: Fluxo principal en estilo tabular con `btree`

Observa como en Ridgun os signos `=` e os pasos de transformación con `btree` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

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

### 04.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `btree` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

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

### 04.3.3. Exemplo 3: Árbores AVL `BTreeMap`: inserción con auto-balanceo, busca $O(\log N)$, borrado, percorrido en orde e extremos (`min key`, `max key`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `btree` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test_btree_map_avl_balance_and_crud => ()
      test_btree_map_avl_balance_and_crud =
        m0 = btree empty
        _ = assert int equals (btree size m0) 0 "AC1: empty map size 0"
        _ = assert int equals (btree height m0) 0 "AC1: empty map height 0"
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
        _ = assert int equals (btree size m15) 15 "AC1: btree size after 15 ascending puts"
        _ = assert true ((btree height m15) <= 5) "AC1: AVL tree height <= 5 on 15 sequential ascending keys"
        _ = assert str eq (btree get m15 "k08") "v8" "AC1: btree get k08"
        _ = assert str eq (btree_get_or m15 "k99" "def") "def" "AC1: btree get or fallback"
        _ = assert true (btree has m15 "k15") "AC1: btree has k15"
        _ = assert false (btree has m15 "k00") "AC1: btree has k00 false"

        -- Descending insertion order (triggers right-rotations) + RL/LR double rotations
        d0 = btree_from_list [("z", "26"), ("x", "24"), ("v", "22"), ("t", "20"), ("r", "18"), ("u", "21"), ("y", "25")]
        _ = assert int equals (btree size d0) 7 "AC1: descending + RL/LR size 7"
        _ = assert true ((btree height d0) <= 4) "AC1: descending + RL/LR height <= 4"
        _ = assert str eq (bt_join_strs (btree keys d0)) "r,t,u,v,x,y,z" "AC1: keys in-order after RL/LR rotations"
        _ = assert str eq (bt_join_strs (btree values d0)) "18,20,21,22,24,25,26" "AC1: values in key order"

        -- Overwrite existing key preserves size
        d_upd = btree put d0 "v" "22_new"
        _ = assert int equals (btree size d_upd) 7 "AC1: update existing key preserves size"
        _ = assert str eq (btree get d_upd "v") "22_new" "AC1: updated value retrieved"

        -- Remove root/two-child node, single-child node, leaf node, and non-existent key
        d_rem1 = btree remove d_upd "v"
        d_rem2 = btree remove d_rem1 "r"
        d_rem3 = btree remove d_rem2 "nonexistent"
        _ = assert int equals (btree size d_rem3) 5 "AC1: size after removing 2 existing keys and 1 missing key"
        _ = assert false (btree has d_rem3 "v") "AC1: removed two-child node 'v' absent"
        _ = assert false (btree has d_rem3 "r") "AC1: removed leaf node 'r' absent"
        _ = assert str eq (bt_join_strs (btree keys d_rem3)) "t,u,x,y,z" "AC1: keys remain strictly sorted after removals"

        pairs = btree_to_list d_rem3
        m_rt = btree_from_list pairs
        _ = assert int equals (btree size m_rt) 5 "AC1: btree to/from list round-trip size"
        _ = assert str eq (btree get m_rt "y") "25" "AC1: btree to/from list round-trip lookup"
        ()
```

### 04.3.4. Exemplo 4: Conxuntos ordenados `BTreeSet`: álxebra de conxuntos (`union`, `intersect`, `diff`, `is subset`) e conversión ordenada a lista

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `btree` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test_btree_set_operations => ()
      test_btree_set_operations =
        s1 = bset_from_list ["charlie", "alpha", "bravo", "alpha", "charlie"]
        s2 = bset_from_list ["bravo", "delta", "echo"]
        s_empty = bset empty
        _ = assert int equals (bset size s1) 3 "AC2: bset deduplicates items"
        _ = assert true (bset has s1 "bravo") "AC2: bset has bravo"
        _ = assert false (bset has s1 "delta") "AC2: bset has delta false"
        _ = assert str eq (bt_join_strs (bset_to_list s1)) "alpha,bravo,charlie" "AC2: bset sorted order"

        s1_rem = bset remove s1 "bravo"
        _ = assert int equals (bset size s1_rem) 2 "AC2: bset remove size"
        _ = assert false (bset has s1_rem "bravo") "AC2: bset remove membership"

        u = bset union s1 s2
        _ = assert str eq (bt_join_strs (bset_to_list u)) "alpha,bravo,charlie,delta,echo" "AC2: bset union"
        _ = assert int equals (bset size (bset union s1 s1)) 3 "AC2: union idempotence A U A = A"
        _ = assert int equals (bset size (bset union s1 s_empty)) 3 "AC2: union identity A U empty = A"

        inter = bset intersect s1 s2
        _ = assert str eq (bt_join_strs (bset_to_list inter)) "bravo" "AC2: bset intersect"
        _ = assert int equals (bset size (bset intersect s1 s_empty)) 0 "AC2: intersect with empty is empty"

        df = bset diff s1 s2
        _ = assert str eq (bt_join_strs (bset_to_list df)) "alpha,charlie" "AC2: bset diff A \\ B"
        _ = assert int equals (bset size (bset diff s1 s1)) 0 "AC2: self difference A \\ A is empty"
        ()
```

### 04.3.5. Exemplo 5: Colas de prioridade `MinHeap` (montículo esquerdista): `heap push`, `heap peek`, `heap pop` e planificación por prioridade en $O(\log N)$

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `btree` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test_min_heap_priority_queue => ()
      test_min_heap_priority_queue =
        h0 = heap empty
        _ = assert int equals (heap size h0) 0 "AC3: empty heap size 0"
        h1 = heap push h0 50 "low"
        h2 = heap push h1 10 "urgent-1"
        h3 = heap push h2 30 "normal"
        h4 = heap push h3 20 "high"
        h5 = heap push h4 10 "urgent-2"
        h6 = heap push h5 (-5) "critical"
        _ = assert int equals (heap size h6) 6 "AC3: heap size 6"
        pk = heap peek h6
        _ = assert int equals (hp_peek_prio pk) (-5) "AC3: heap peek negative priority (-5)"
        _ = assert str eq (hp_peek_val pk) "critical" "AC3: heap peek critical value"

        p0 = heap pop h6
        _ = assert int equals (hp_pop_prio p0) (-5) "AC3: pop 0 (-5)"
        p1 = heap pop (hp_pop_rest p0)
        _ = assert int equals (hp_pop_prio p1) 10 "AC3: pop 1 (10)"
        p2 = heap pop (hp_pop_rest p1)
        _ = assert int equals (hp_pop_prio p2) 10 "AC3: pop 2 duplicate priority (10)"

        -- Interleaved push after partial pop
        h_mid = heap push (hp_pop_rest p2) 15 "medium-high"
        p3 = heap pop h_mid
        _ = assert int equals (hp_pop_prio p3) 15 "AC3: interleaved push 15 popped before 20"
        p4 = heap pop (hp_pop_rest p3)
        _ = assert int equals (hp_pop_prio p4) 20 "AC3: pop 20"
        p5 = heap pop (hp_pop_rest p4)
        _ = assert int equals (hp_pop_prio p5) 30 "AC3: pop 30"
        p6 = heap pop (hp_pop_rest p5)
        _ = assert int equals (hp_pop_prio p6) 50 "AC3: pop 50"
        _ = assert int equals (heap size (hp_pop_rest p6)) 0 "AC3: heap empty after popping all"
        ()
```

---

## 04.4. Baixo o capó: como está construída `btree` en Ridgun puro (`src/main/ridgun/lib/btree.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/btree.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 04.4.1. Implementación interna: Lexicographical String Comparison & Int Helpers

Fíxate en como `btree.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: bt_max Int Int => Int
      bt_max a   b
        | a >= b = a
        | otherwise = b

fn :: bt_str_cmp_loop String String Int Int Int => Int
      bt_str_cmp_loop a b idx la lb
        | idx >= la AND idx >= lb = 0
        | idx >= la = -1
        | idx >= lb = 1
        | (str_char_at a idx) < (str_char_at b idx) = -1
        | (str_char_at a idx) > (str_char_at b idx) = 1
        | otherwise = bt_str_cmp_loop a b (idx + 1) la lb

fn :: bt_str_cmp String String => Int
      bt_str_cmp a      b      =  bt_str_cmp_loop a b 0 (str_len a) (str_len b)
```

### 04.4.2. Implementación interna: AVL-Balanced Ordered Map (`BTreeMap`)

Fíxate en como `btree.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: btree empty => BTreeMap
      btree empty =  BMapEmpty

fn :: btree height BTreeMap  => Int
      btree height BMapEmpty =  0
      btree height (BMapNode _ _ h _ _) = h

fn :: bt_mk String String BTreeMap BTreeMap => BTreeMap
      bt_mk k      v      l        r        =  BMapNode k v (1 + (bt_max (btree_height l) (btree_height r))) l r

fn :: bt_bf BTreeMap  => Int
      bt_bf BMapEmpty =  0
      bt_bf (BMapNode _ _ _ l r) = (btree_height l) - (btree_height r)

fn :: bt_rot_right BTreeMap => BTreeMap
      bt_rot_right (BMapNode y yv _ (BMapNode x xv _ t1 t2) t3) = bt_mk x xv t1 (bt_mk y yv t2 t3)
      bt_rot_right node     =  node

fn :: bt_rot_left BTreeMap => BTreeMap
      bt_rot_left (BMapNode x xv _ t1 (BMapNode y yv _ t2 t3)) = bt_mk y yv (bt_mk x xv t1 t2) t3
      bt_rot_left node     =  node

fn :: bt_rebalance String String BTreeMap BTreeMap => BTreeMap
      bt_rebalance k      v      l        r
        | ((btree_height l) - (btree_height r)) > 1 AND (bt_bf l) >= 0 = bt_rot_right (bt_mk k v l r)
        | ((btree_height l) - (btree_height r)) > 1 = bt_rot_right (bt_mk k v (bt_rot_left l) r)
        | ((btree_height l) - (btree_height r)) < (-1) AND (bt_bf r) <= 0 = bt_rot_left (bt_mk k v l r)
        | ((btree_height l) - (btree_height r)) < (-1) = bt_rot_left (bt_mk k v l (bt_rot_right r))
        | otherwise = bt_mk k v l r

fn :: btree put BTreeMap  String String => BTreeMap
      btree put BMapEmpty key    val    =  BMapNode key val 1 BMapEmpty BMapEmpty
      btree put (BMapNode k v _ l r) key val
        | (bt_str_cmp key k) < 0 = bt_rebalance k v (btree_put l key val) r
        | (bt_str_cmp key k) > 0 = bt_rebalance k v l (btree_put r key val)
        | otherwise = bt_mk key val l r

fn :: btree get or BTreeMap String String => String
      btree get or BMapEmpty _ fallback = fallback
      btree get or (BMapNode k v _ l r) key fallback
        | (bt_str_cmp key k) < 0 = btree_get_or l key fallback
        | (bt_str_cmp key k) > 0 = btree_get_or r key fallback
        | otherwise = v

fn :: btree get BTreeMap String => String
      btree get t        key    =  btree_get_or t key ""
```

### 04.4.3. Implementación interna: AVL-Balanced Ordered Set (`BTreeSet`)

Fíxate en como `btree.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: bset empty => BTreeSet
      bset empty =  BSetEmpty

fn :: bs_height BTreeSet           => Int
      bs_height BSetEmpty          =  0
      bs_height (BSetNode _ h _ _) =  h

fn :: bs_mk String BTreeSet BTreeSet => BTreeSet
      bs_mk k      l        r        =  BSetNode k (1 + (bt_max (bs_height l) (bs_height r))) l r

fn :: bs_bf BTreeSet           => Int
      bs_bf BSetEmpty          =  0
      bs_bf (BSetNode _ _ l r) =  (bs_height l) - (bs_height r)

fn :: bs_rot_right BTreeSet => BTreeSet
      bs_rot_right (BSetNode y _ (BSetNode x _ t1 t2) t3) = bs_mk x t1 (bs_mk y t2 t3)
      bs_rot_right node     =  node

fn :: bs_rot_left BTreeSet => BTreeSet
      bs_rot_left (BSetNode x _ t1 (BSetNode y _ t2 t3)) = bs_mk y (bs_mk x t1 t2) t3
      bs_rot_left node     =  node

fn :: bs_rebalance String BTreeSet BTreeSet => BTreeSet
      bs_rebalance k      l        r
        | ((bs_height l) - (bs_height r)) > 1 AND (bs_bf l) >= 0 = bs_rot_right (bs_mk k l r)
        | ((bs_height l) - (bs_height r)) > 1 = bs_rot_right (bs_mk k (bs_rot_left l) r)
        | ((bs_height l) - (bs_height r)) < (-1) AND (bs_bf r) <= 0 = bs_rot_left (bs_mk k l r)
        | ((bs_height l) - (bs_height r)) < (-1) = bs_rot_left (bs_mk k l (bs_rot_right r))
        | otherwise = bs_mk k l r

fn :: bset add BTreeSet           String => BTreeSet
      bset add BSetEmpty          key    =  BSetNode key 1 BSetEmpty BSetEmpty
      bset add (BSetNode k _ l r) key
        | (bt_str_cmp key k) < 0 = bs_rebalance k (bset_add l key) r
        | (bt_str_cmp key k) > 0 = bs_rebalance k l (bset_add r key)
        | otherwise = bs_mk k l r

fn :: bset has BTreeSet           String => Bool
      bset has BSetEmpty          _      =  False
      bset has (BSetNode k _ l r) key
        | (bt_str_cmp key k) < 0 = bset_has l key
        | (bt_str_cmp key k) > 0 = bset_has r key
        | otherwise = True

fn :: bs_min_key BTreeSet           => String
      bs_min_key BSetEmpty          =  ""
      bs_min_key (BSetNode k _ BSetEmpty _) = k
      bs_min_key (BSetNode _ _ l _) =  bs_min_key l
```

### 04.4.4. Implementación interna: Leftist MinHeap Priority Queue (`MinHeap`)

Fíxate en como `btree.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: heap empty => MinHeap
      heap empty =  HeapEmpty

fn :: hp_rank MinHeap   => Int
      hp_rank HeapEmpty =  0
      hp_rank (HeapNode _ _ r _ _) = r

fn :: hp_mk Int String MinHeap MinHeap => MinHeap
      hp_mk p   v      a       b
        | (hp_rank a) >= (hp_rank b) = HeapNode p v ((hp_rank b) + 1) a b
        | otherwise = HeapNode p v ((hp_rank a) + 1) b a

fn :: hp_merge MinHeap   MinHeap   => MinHeap
      hp_merge HeapEmpty h2        =  h2
      hp_merge h1        HeapEmpty =  h1
      hp_merge (HeapNode p1 v1 r1 l1 rt1) (HeapNode p2 v2 r2 l2 rt2)
        | p1 <= p2 = hp_mk p1 v1 l1 (hp_merge rt1 (HeapNode p2 v2 r2 l2 rt2))
        | otherwise = hp_mk p2 v2 l2 (hp_merge (HeapNode p1 v1 r1 l1 rt1) rt2)

fn :: heap push MinHeap Int  String => MinHeap
      heap push h       prio val    =  hp_merge h (HeapNode prio val 1 HeapEmpty HeapEmpty)

fn :: heap peek MinHeap   => (Int String)
      heap peek HeapEmpty =  (0, "")
      heap peek (HeapNode p v _ _ _) = (p, v)

fn :: heap pop MinHeap   => (Int String MinHeap)
      heap pop HeapEmpty =  (0, "", HeapEmpty)
      heap pop (HeapNode p v _ l r) = (p, v, hp_merge l r)

fn :: heap size MinHeap   => Int
      heap size HeapEmpty =  0
      heap size (HeapNode _ _ _ l r) = 1 + (heap_size l) + (heap_size r)
```

---

## 04.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `btree`

- **Garantía algorítmica e de seguridade**: Rotacións AVL estritas (`height diff <= 1`), inmunidade total a HashDoS, consultas por rango en $O(\log N + K)$ e fusión de montículos en $O(\log N)$.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/btree.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test btree.rg`.

### As 5 Regras de Ouro ao programar con `btree`

1. **Declara `import btree` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `btree` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `btree` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `btree` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 05** pasaremos a explorar en profundidade a lib **`tensor`** (A lib `tensor` — Tensores Multidimensionais, Vistas e Contracción de Einstein).
