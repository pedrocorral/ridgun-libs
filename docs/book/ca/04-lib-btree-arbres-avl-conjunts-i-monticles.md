# Capítol 04: La lib `btree` — Arbres AVL Persistents $O(\log N)$, Conjunts i Monticles

## 04.1. Per què existeix la lib `btree`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `btree` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `btree`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: les taules hash mutables pateixen atacs de col·lisió de claus (HashDoS), no mantenen les claus ordenades per a consultes per rang i no es poden compartir entre actors sense copiar-les senceres o posar-hi un cadenat.

La lib **`btree`** implementa tres estructures de dades funcionals persistents en $O(\log N)$ amb compartició estructural: **`BTreeMap`** (arbre AVL autobalancejat), **`BTreeSet`** (àlgebra de conjunts ordenada) i **`MinHeap`** (cua de prioritat *leftist heap*).

En un ecosistema tradicional, resoldre les tasques del domini **`BTREE`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`btree`** (`src/main/ridgun/lib/btree.rg`) aborda el problema amb quatre principis innegociables:

1. **Declara `import btree` (o `import btree as alias`) a l'inici del fitxer**: cada lib defineix el seu espai de noms `module :: btree` i en mode `--strict` les funcions multi-paraula s'invoquen sempre amb espais naturals.
2. **Encadena les teves canonades d'esquerra a dreta amb `->`**: escriu `entrada pas u -> pas dos -> resultat`, fes servir màscares `(+ _ _ +)` per desestructurar seqüències i omet `_ =` en sentències seqüencials (o descarta amb `-> ()`).
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `btree` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 04.2. Artefactes natius, importació i catàleg complet de l'API de `btree`

A `ridgun-libs`, **`btree`** és una **lib** de primera classe situada a `src/main/ridgun/lib/btree.rg` (domini `BTREE`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/btree.rglib` | Distribució i importació directa amb `import btree` |
| **Fitxer compilat** | `target/btree.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libbtree.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Cada lib declara el seu propi espai de noms amb `module :: btree`: n'hi ha prou d'escriure `import btree` (o `import btree as alias`) a la capçalera i cridar les seves funcions amb espais naturals (`la meva funcio x`) i canonades `->` (`x la meva funcio -> resultat`).

### 04.2.1. Resum de famílies funcionals de `btree`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `btree empty / btree insert / btree get / btree remove` | Cerca, inserció i esborrat persistent en diccionari AVL en $O(\log N)$ |
| `btree min key / btree max key / btree range` | Extrems ordenats i consulta per rang `[lo, hi]` |
| `bset from list / bset union / bset intersect / bset diff` | Àlgebra de conjunts ordenats (`BTreeSet`) i predicat de subconjunt |
| `heap empty / heap push / heap peek / heap pop / heap sort` | Cua de prioritat `MinHeap` (*leftist heap*) amb fusió en $O(\log N)$ |

### 04.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/btree.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/btree.rg` (`3` tipus, `0` operadors i `54` funcions):

**Tipus algebraics i registres (`type`) de `btree`:**

```ridgun
type BTreeMap = BMapEmpty | BMapNode String String Int BTreeMap BTreeMap
type BTreeSet = BSetEmpty | BSetNode String Int BTreeSet BTreeSet
type MinHeap = HeapEmpty | HeapNode Int String Int MinHeap MinHeap
```

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 04.3. Explorant `btree` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `btree` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test btree.rg`.

### 04.3.1. Exemple 1: Flux principal en estil tabular amb `btree`

Observa com en Ridgun els signes `=` i els passos de transformació amb `btree` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

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

### 04.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `btree` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

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

### 04.3.3. Exemple 3: Arbres AVL `BTreeMap`: inserció amb autobalanceig, cerca $O(\log N)$, esborrat, recorregut en ordre i extrems (`min key`, `max key`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `btree` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 04.3.4. Exemple 4: Conjunts ordenats `BTreeSet`: àlgebra de conjunts (`union`, `intersect`, `diff`, `is subset`) i conversió ordenada a llista

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `btree` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 04.3.5. Exemple 5: Cues de prioritat `MinHeap` (monticle esquerrà): `heap push`, `heap peek`, `heap pop` i planificació per prioritat en $O(\log N)$

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `btree` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

## 04.4. Sota el capó: com està construïda `btree` en Ridgun pur (`src/main/ridgun/lib/btree.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/btree.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 04.4.1. Implementació interna: Lexicographical String Comparison & Int Helpers

Fixa't en com `btree.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 04.4.2. Implementació interna: AVL-Balanced Ordered Map (`BTreeMap`)

Fixa't en com `btree.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 04.4.3. Implementació interna: AVL-Balanced Ordered Set (`BTreeSet`)

Fixa't en com `btree.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 04.4.4. Implementació interna: Leftist MinHeap Priority Queue (`MinHeap`)

Fixa't en com `btree.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

## 04.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `btree`

- **Garantia algorísmica i de seguretat**: Rotacions AVL estrictes (`height diff <= 1`), immunitat total a HashDoS, consultes per rang en $O(\log N + K)$ i fusió de monticles en $O(\log N)$.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/btree.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test btree.rg`.

### Les 5 Regles d'Or en programar amb `btree`

1. **Declara `import btree` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `btree` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `btree` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `btree` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 05** passarem a explorar en profunditat la lib **`tensor`** (La lib `tensor` — Tensors Multidimensionals, Vistes i Contracció d'Einstein).
