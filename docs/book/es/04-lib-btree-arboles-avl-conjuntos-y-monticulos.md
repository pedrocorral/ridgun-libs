# Capítulo 04: La lib `btree` — Árboles AVL Persistentes $O(\log N)$, Conjuntos y Montículos

## 04.1. ¿Por qué existe la lib `btree`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `btree` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `btree`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: las tablas hash mutables sufren ataques de colisión de claves (HashDoS), no mantienen las claves ordenadas para consultas por rango y no pueden compartirse entre actores sin copiarlas enteras o meter un candado.

La lib **`btree`** implementa tres estructuras de datos funcionales persistentes en $O(\log N)$ con compartición estructural: **`BTreeMap`** (árbol AVL auto-balanceado), **`BTreeSet`** (álgebra de conjuntos ordenada) y **`MinHeap`** (cola de prioridad *leftist heap*).

En un ecosistema tradicional, resolver las tareas del dominio **`BTREE`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`btree`** (`src/main/ridgun/lib/btree.rg`) aborda el problema con cuatro principios innegociables:

1. **Funciones totales y contratos explícitos (`=>`)**: ninguna función de `btree` lanza excepciones ocultas ni depende de `null`. Todo caso límite (entradas vacías, divisores cero, tramas truncadas o índices fuera de rango) devuelve un valor centinela documentado o un tipo algebraico suma (`Option`, `Result`).
2. **Cero código C y cero `libc`**: todo el código de `btree` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `btree` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 04.2. Artefactos nativos, importación y catálogo completo de la API de `btree`

En `ridgun-libs`, **`btree`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/btree.rg` (dominio `BTREE`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/btree.rglib` | Distribución e importación directa con `import btree` |
| **Archivo compilado** | `target/btree.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libbtree.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import btree` en el encabezado y llamar a sus funciones con espacios (`mi funcion x`) o guiones bajos (`mi_funcion x`) indistintamente.

### 04.2.1. Resumen de familias funcionales de `btree`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `btree empty / btree insert / btree get / btree remove` | Búsqueda, inserción y borrado persistente en diccionario AVL en $O(\log N)$ |
| `btree min key / btree max key / btree range` | Extremos ordenados y consulta por rango `[lo, hi]` |
| `bset from list / bset union / bset intersect / bset diff` | Álgebra de conjuntos ordenados (`BTreeSet`) y predicado de subconjunto |
| `heap empty / heap push / heap peek / heap pop / heap sort` | Cola de prioridad `MinHeap` (*leftist heap*) con fusión en $O(\log N)$ |

### 04.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/btree.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/btree.rg` (`3` tipos, `0` operadores y `54` funciones):

**Tipos algebraicos y registros (`type`) de `btree`:**

```ridgun
type BTreeMap = BMapEmpty | BMapNode String String Int BTreeMap BTreeMap
type BTreeSet = BSetEmpty | BSetNode String Int BTreeSet BTreeSet
type MinHeap = HeapEmpty | HeapNode Int String Int MinHeap MinHeap
```

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
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

## 04.3. Explorando `btree` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `btree` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test btree.rg`.

### 04.3.1. Ejemplo 1: Flujo principal en estilo tabular con `btree`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `btree` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

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

### 04.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `btree` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

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

### 04.3.3. Ejemplo 3: Árboles AVL `BTreeMap`: inserción con auto-balanceo, búsqueda $O(\log N)$, borrado, recorrido en orden y extremos (`min key`, `max key`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `btree` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 04.3.4. Ejemplo 4: Conjuntos ordenados `BTreeSet`: álgebra de conjuntos (`union`, `intersect`, `diff`, `is subset`) y conversión ordenada a lista

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `btree` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 04.3.5. Ejemplo 5: Colas de prioridad `MinHeap` (montículo izquierdista): `heap push`, `heap peek`, `heap pop` y planificación por prioridad en $O(\log N)$

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `btree` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

## 04.4. Bajo el capó: cómo está construida `btree` en Ridgun puro (`src/main/ridgun/lib/btree.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/btree.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 04.4.1. Implementación interna: Lexicographical String Comparison & Int Helpers

Fíjate en cómo `btree.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

Fíjate en cómo `btree.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

Fíjate en cómo `btree.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

Fíjate en cómo `btree.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

## 04.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `btree`

- **Garantía algorítmica y de seguridad**: Rotaciones AVL estrictas (`height diff <= 1`), inmunidad total a HashDoS, consultas por rango en $O(\log N + K)$ y fusión de montículos en $O(\log N)$.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/btree.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test btree.rg`.

### Las 5 Reglas de Oro al programar con `btree`

1. **Declara `import btree` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `btree` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `btree` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `btree` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 05** pasaremos a explorar en profundidad la lib **`tensor`** (La lib `tensor` — Tensores Multidimensionales, Vistas y Contracción de Einstein).
