# Capítol 03: La lib `list` — Llistes, Mergesort $O(N \log N)$ i Mapes Clau-Valor

## 03.1. Per què existeix la lib `list`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `list` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `list`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: accedir a un índex fora de rang (`IndexError` / `panic!`) o mutar una llista compartida per accident són dos dels errors més freqüents en processar col·leccions.

La lib **`list`** proporciona indexació amb valor per defecte, llescat (`take`, `drop`, `slice`), rangs amb pas, deduplicació estable, ordenació **mergesort $O(N \log N)$** per a `[Int]` i `[String]`, i diccionaris associatius immutables `[String String]` (`list kv get`, `list kv put`, `list kv merge`).

En un ecosistema tradicional, resoldre les tasques del domini **`LIST`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`list`** (`src/main/ridgun/lib/list.ridgun`) aborda el problema amb quatre principis innegociables:

1. **Declara `import list` (o `import list as alias`) a l'inici del fitxer**: cada lib defineix el seu espai de noms `module :: list` i en mode `--strict` les funcions multi-paraula s'invoquen sempre amb espais naturals.
2. **Encadena les teves canonades d'esquerra a dreta amb `->`**: escriu `entrada pas u -> pas dos -> resultat`, fes servir màscares `(+ _ _ +)` per desestructurar seqüències i omet `_ =` en sentències seqüencials (o descarta amb `-> ()`).
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `list` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 03.2. Artefactes natius, importació i catàleg complet de l'API de `list`

A `ridgun-libs`, **`list`** és una **lib** de primera classe situada a `src/main/ridgun/lib/list.ridgun` (domini `LIST`). En compilar amb `stable bundle`, s'empaqueta en un format natiu:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/list.ridgunlib` | Distribució i importació directa amb `import list` |

> Cada lib declara el seu propi espai de noms amb `module :: list`: n'hi ha prou d'escriure `import list` (o `import list as alias`) a la capçalera i cridar les seves funcions amb espais naturals (`la meva funcio x`) i canonades `->` (`x la meva funcio -> resultat`).

### 03.2.1. Resum de famílies funcionals de `list`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `list nth or / list str nth or` | Lectura segura per índex retornant `default_val` si està fora de rang |
| `list take / list drop / list slice / list reverse` | Prefix, sufix, subrang `[start, end)` i inversió recursiva de cua |
| `list range / list range step` | Genera seqüències aritmètiques (`step == 0` retorna `[]` de forma segura) |
| `list sort / list str sort / list dedup / list str dedup` | Ordenació mergesort $O(N \log N)$ estable i deduplicació per primera aparició |
| `list kv empty / list kv put / list kv get / list kv get or / list kv remove / list kv merge` | Operacions sobre diccionaris associatius ordenats `[String String]` |
| `list sort by int / list sort by text / list count by / list group by` | Ordenació estable per una clau calculada una vegada per element, i recompte o agrupació per clau en temps esperat lineal |

### 03.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/list.ridgun`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/list.ridgun` (`0` tipus, `0` operadors i `60` funcions):

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
|---|---|---|
| `1` | `fn :: list str len [String]` | `Int` |
| `2` | `fn :: list is empty [Int]` | `Bool` |
| `3` | `fn :: list str is empty [String]` | `Bool` |
| `4` | `fn :: list nth [Int] Int` | `Int` |
| `5` | `fn :: list str nth or [String] Int String` | `String` |
| `6` | `fn :: list str nth [String] Int` | `String` |
| `7` | `fn :: list head [Int] Int` | `Int` |
| `8` | `fn :: list last [Int] Int` | `Int` |
| `9` | `fn :: list str take [String] Int` | `[String]` |
| `10` | `fn :: list str drop [String] Int` | `[String]` |
| `11` | `fn :: l clamp nonneg Int` | `Int` |
| `12` | `fn :: l slice ints from [Int] Int Int` | `[Int]` |
| `13` | `fn :: list slice [Int] Int Int` | `[Int]` |
| `14` | `fn :: l slice strs from [String] Int Int` | `[String]` |
| `15` | `fn :: list str slice [String] Int Int` | `[String]` |
| `16` | `fn :: list str reverse [String]` | `[String]` |
| `17` | `fn :: list range step Int Int Int` | `[Int]` |
| `18` | `fn :: list range Int Int` | `[Int]` |
| `19` | `fn :: list replicate Int Int` | `[Int]` |
| `20` | `fn :: l idx int [Int] Int Int` | `Int` |
| `21` | `fn :: list index of [Int] Int` | `Int` |
| `22` | `fn :: l idx str [String] String Int` | `Int` |
| `23` | `fn :: list str index of [String] String` | `Int` |
| `24` | `fn :: list str contains [String] String` | `Bool` |
| `25` | `fn :: list count [Int] Int` | `Int` |
| `26` | `fn :: list str count [String] String` | `Int` |
| `27` | `fn :: l dedup ints [Int] [Int]` | `[Int]` |
| `28` | `fn :: list dedup [Int]` | `[Int]` |
| `29` | `fn :: l dedup strs [String] [String]` | `[String]` |
| `30` | `fn :: list str dedup [String]` | `[String]` |
| `31` | `fn :: list sort ints [Int]` | `[Int]` |
| `32` | `fn :: list sort texts [String]` | `[String]` |
| `33` | `fn :: list sort by int [A] (A` | `Int) => [A]` |
| `34` | `fn :: list sort by text [A] (A` | `String) => [A]` |
| `35` | `fn :: list sort [Int]` | `[Int]` |
| `36` | `fn :: list is sorted [Int]` | `Bool` |
| `37` | `fn :: list str sort [String]` | `[String]` |
| `38` | `fn :: l gen len [A] Int` | `Int` |
| `39` | `fn :: l group ids [A] (A` | `String) (HashMap Int) Tensor[Int * n] Int => HashMap Int` |
| `40` | `fn :: l group ids key [A] (A` | `String) (HashMap Int) Tensor[Int * n] Int String => HashMap Int` |
| `41` | `fn :: l group ids step [A] (A` | `String) (HashMap Int) Tensor[Int * n] Int String Int => HashMap Int` |
| `42` | `fn :: l count into [A] (A` | `String) (HashMap Int) => HashMap Int` |
| `43` | `fn :: list count by [A] (A` | `String) => [String Int]` |
| `44` | `fn :: l rev gen [A] [A]` | `[A]` |
| `45` | `fn :: l collect [A] Tensor[Int * n] Tensor[[A] * n] Int` | `()` |
| `46` | `fn :: l group pairs [String Int] Tensor[[A] * n] [String [A]]` | `[String [A]]` |
| `47` | `fn :: l group by n [A] (A` | `String) Int => [String [A]]` |
| `48` | `fn :: list group by [A] (A` | `String) => [String [A]]` |
| `49` | `fn :: l kv key (String String)` | `String` |
| `50` | `fn :: l kv val (String String)` | `String` |
| `51` | `fn :: list kv empty` | `[String String]` |
| `52` | `fn :: list kv len [String String]` | `Int` |
| `53` | `fn :: list kv has [String String] String` | `Bool` |
| `54` | `fn :: list kv get or [String String] String String` | `String` |
| `55` | `fn :: list kv get [String String] String` | `String` |
| `56` | `fn :: list kv put [String String] String String` | `[String String]` |
| `57` | `fn :: list kv remove [String String] String` | `[String String]` |
| `58` | `fn :: list kv keys [String String]` | `[String]` |
| `59` | `fn :: list kv values [String String]` | `[String]` |
| `60` | `fn :: list kv merge [String String] [String String]` | `[String String]` |

---

## 03.3. Explorant `list` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `list` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test list.ridgun`.

### 03.3.1. Exemple 1: Flux principal en estil tabular amb `list`

Observa com en Ridgun els signes `=` i els passos de transformació amb `list` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import list

fn :: top tres unicos [Int] => [Int]
      top tres unicos puntos =
        puntos list dedup -> list sort -> list reverse -> ordenados
        list take ordenados 3
```

### 03.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `list` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 38 libs de `ridgun-libs`:

```ridgun
import list

fn :: configurar entorno [String String] => String [String]
      configurar entorno base =
        list kv put base "host" "0.0.0.0" -> cfg1
        list kv put cfg1 "port" "8080" -> cfg2
        list kv get or cfg2 "host" "127.0.0.1" -> host
        list kv keys cfg2 -> claves
        (host, claves)
```

### 03.3.3. Exemple 3: Indexació segura (`list nth`, `list head`, `list last`), llescat (`take`, `drop`, `slice`), rangs (`range`, `iota`, `replicate`) i deduplicació (`dedup`, `list count`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `list` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test list indexing slicing and ranges => ()
      test list indexing slicing and ranges =
        xs = [10, 20, 30, 40, 50]
        ss = ["aa", "bb", "cc", "dd"]
        list len xs -> assert int equals 5 "AC1: list_len 5"
        list str len ss -> assert int equals 4 "AC1: list_str_len 4"
        list is empty [] -> assert true "AC1: list_is_empty []"
        list is empty xs -> assert false "AC1: list_is_empty non-empty"
        list str is empty [] -> assert true "AC1: list_str_is_empty []"
        list str is empty ss -> assert false "AC1: list_str_is_empty non-empty"

        list nth xs 0 -> assert int equals 10 "AC1: list_nth 0"
        list nth xs 4 -> assert int equals 50 "AC1: list_nth 4"
        list nth or xs 99 (0 - 1) -> assert int equals (0 - 1) "AC1: list_nth_or out of bounds"
        list nth or xs (0 - 1) (0 - 1) -> assert int equals (0 - 1) "AC1: list_nth_or negative"
        list str nth ss 2 -> assert str eq "cc" "AC1: list_str_nth 2"
        list str nth or ss 99 "oob" -> assert str eq "oob" "AC1: list_str_nth_or out of bounds"
        list head xs 0 -> assert int equals 10 "AC1: list_head"
        list head [] 99 -> assert int equals 99 "AC1: list_head empty fallback"
        list last xs 0 -> assert int equals 50 "AC1: list_last"
        list last [] 99 -> assert int equals 99 "AC1: list_last empty fallback"

        list take xs 3 -> assert eq [10, 20, 30]
        list take xs 0 -> assert eq []
        list take xs (0 - 2) -> assert eq []
        list take xs 99 -> assert eq [10, 20, 30, 40, 50]
        list drop xs 3 -> assert eq [40, 50]
        list drop xs 0 -> assert eq xs
        list drop xs 99 -> assert eq []
        list slice xs 1 4 -> assert eq [20, 30, 40]
        list slice xs (0 - 3) 2 -> assert eq [10, 20]
        list slice xs 4 2 -> assert eq []
        list str slice ss 1 3 -> assert eq ["bb", "cc"]

        list reverse xs -> assert eq [50, 40, 30, 20, 10]
        list str reverse ss -> assert eq ["dd", "cc", "bb", "aa"]

        list range 1 5 -> assert eq [1, 2, 3, 4, 5]
        list range 3 3 -> assert eq [3]
        list range 5 1 -> assert eq []
        list range step 0 6 2 -> assert eq [0, 2, 4, 6]
        list range step 6 0 (0 - 2) -> assert eq [6, 4, 2, 0]
        list range step 1 5 0 -> assert eq []
        list replicate 3 7 -> assert eq [7, 7, 7]
        list replicate 0 7 -> assert eq []

        list contains xs 30 -> assert true "AC1: list_contains 30"
        list contains xs 99 -> assert false "AC1: list_contains 99"
        list str contains ss "cc" -> assert true "AC1: list_str_contains cc"
        list str contains ss "zz" -> assert false "AC1: list_str_contains zz"
        list index of xs 30 -> assert int equals 2 "AC1: list_index_of 30"
        list index of xs 99 -> assert int equals (0 - 1) "AC1: list_index_of missing"
        list str index of ss "dd" -> assert int equals 3 "AC1: list_str_index_of dd"
        list count [1, 2, 1, 3, 1] 1 -> assert int equals 3 "AC1: list_count"
        list str count ["a", "b", "a"] "a" -> assert int equals 2 "AC1: list_str_count"
        list dedup [3, 1, 3, 2, 1, 3] -> assert eq [3, 1, 2]
        list str dedup ["b", "a", "b", "c", "a"] -> assert eq ["b", "a", "c"]
        ()
```

### 03.3.4. Exemple 4: Ordenació determinista $O(N \log N)$ (`list sort ints`, `list sort texts`, `list is sorted`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `list` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test list mergesort => ()
      test list mergesort =
        unsorted = [42, 7, 19, 7, 0, (0 - 5), 100, 3, (0 - 50)]
        sorted = list sort unsorted
        sorted -> assert eq [(0 - 50), (0 - 5), 0, 3, 7, 7, 19, 42, 100]
        list is sorted sorted -> assert true "AC2: list_is_sorted after sort"
        list is sorted unsorted -> assert false "AC2: list_is_sorted false on unsorted"
        list is sorted [] -> assert true "AC2: empty list is sorted"
        list is sorted [1] -> assert true "AC2: singleton list is sorted"
        list sort [] -> assert eq []
        list sort [1] -> assert eq [1]
        list sort [5, 4, 3, 2, 1] -> assert eq [1, 2, 3, 4, 5]
        s_strs = list str sort ["delta", "alpha", "charlie", "bravo", "alpha", "al", ""]
        s_strs -> assert eq ["", "al", "alpha", "alpha", "bravo", "charlie", "delta"]
        ()
```

### 03.3.5. Exemple 5: Mapes associatius clau-valor immutables (`list kv put`, `list kv get or`, `list kv has`, `list kv remove`, `list kv keys`, `list kv values`, `list kv len`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `list` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test kv associative map => ()
      test kv associative map =
        m0 = list kv empty
        list kv len m0 -> assert int equals 0 "AC3: list_kv_empty len 0"
        m1 = list kv put m0 "host" "127.0.0.1"
        m2 = list kv put m1 "port" "8080"
        m3 = list kv put m2 "port" "9090"
        list kv len m3 -> assert int equals 2 "AC3: list_kv_put updates in-place without duplicating key"
        list kv has m3 "host" -> assert true "AC3: list_kv_has host"
        list kv has m3 "missing" -> assert false "AC3: list_kv_has missing"
        list kv get m3 "port" -> assert str eq "9090" "AC3: list_kv_get updated port"
        list kv get m3 "missing" -> assert str eq "" "AC3: list_kv_get missing returns empty"
        list kv get or m3 "mode" "prod" -> assert str eq "prod" "AC3: list_kv_get_or default"
        list kv keys m3 -> assert eq ["host", "port"]
        list kv values m3 -> assert eq ["127.0.0.1", "9090"]
        m4 = list kv merge m3 [("port", "8443"), ("tls", "true")]
        list kv len m4 -> assert int equals 3 "AC3: list_kv_merge len 3"
        list kv get m4 "port" -> assert str eq "8443" "AC3: list_kv_merge overrides port"
        list kv get m4 "tls" -> assert str eq "true" "AC3: list_kv_merge adds tls"
        m5 = list kv remove m4 "host"
        list kv has m5 "host" -> assert false "AC3: list_kv_remove removes host"
        list kv len m5 -> assert int equals 2 "AC3: list_kv_remove len 2"

        -- RG-066: verify `agent kv *` and `list kv *` work side-by-side in the same module
        ag = new kv agent
        agent kv put ag "host" (list kv get m4 "port") -> assert str eq "8443" "RG-066: agent kv put + list kv get"
        agent kv get ag "host" -> assert str eq "8443" "RG-066: agent kv get"
        stop agent ag
        ()
```

### 03.3.6. Exemple 6: Ordenació estable per clau (`list sort by int`, `list sort by text`): una crida a la clau per element i entrades de 100 000 elements

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `list` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test list sort by key => ()
      test list sort by key =
        big   = 9223372036854775807
        small = 0 - 9223372036854775807 - 1
        list sort ints [] -> assert eq []
        list sort ints [7] -> assert eq [7]
        list sort ints [3, 0 - 1, big, 0, small, 0 - 65536, 65536, 2, 2] -> assert eq [small, 0 - 65536, 0 - 1, 0, 2, 2, 3, 65536, big]

        hi  = char from code 200
        hi2 = char from code 255
        long_a = kb10 "a"
        long_b = kb10 "b"
        list sort texts [] -> assert eq []
        list sort texts ["b", hi, "", "a", "ab", "a", hi2] -> assert eq ["", "a", "a", "ab", "b", hi, hi2]
        list sort texts [long_b, "z", long_a] -> assert eq [long_a, long_b, "z"]
        list sort [3, 1, 2] -> assert eq [1, 2, 3]
        list str sort ["b", "a"] -> assert eq ["a", "b"]

        es = [Entry "a" 2, Entry "b" 1, Entry "c" 2, Entry "d" 1]
        list sort by int es (e => score e) -> assert eq [Entry "b" 1, Entry "d" 1, Entry "a" 2, Entry "c" 2]
        list sort by text es (e => int to str (score e)) -> assert eq [Entry "b" 1, Entry "d" 1, Entry "a" 2, Entry "c" 2]
        list sort by text [Entry hi 1, Entry "" 2, Entry "a" 3, Entry "" 4] (e => name e) -> assert eq [Entry "" 2, Entry "" 4, Entry "a" 3, Entry hi 1]
        list sort by int [] (e => score e) -> assert eq []
        list sort by text [] (e => name e) -> assert eq []

        calls = Tensor[Int * 1]
        list sort by int es (e =>
          calls_(0) = calls_(0) + 1
          score e
        )
        calls_(0) -> assert int equals 4 "AC3: key function called once per element"

        n  = 100000
        xs = list sort ints (gen ints 0 n [])
        ascending ints xs -> assert true "AC6: 100k ints ascending"
        list len xs -> assert int equals n "AC6: 100k ints keep every element"
        ys = list sort by int (gen entries 0 n []) (e => score e)
        stable entries ys -> assert true "AC6: 100k records ascending and stable"
        ()
```

### 03.3.7. Exemple 7: Recompte i agrupació per clau (`list count by`, `list group by`) sobre 20 000 elements

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `list` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test list count and group by => ()
      test list count and group by =
        hi = char from code 200
        long_a = kb10 "a"
        long_b = kb10 "b"
        words = ["x", "y", "x", "", hi, long_a, "x", "", long_b, hi]
        counts = list count by words (w => w)
        counts -> assert eq [("x", 3), ("y", 1), ("", 2), (hi, 2), (long_a, 1), (long_b, 1)]
        sum counts counts 0 -> assert int equals 10 "AC4: counts add up to the length"
        list count by [] (w => w) -> assert eq []

        es = [Entry "a" 2, Entry "b" 1, Entry "c" 2, Entry "d" 1, Entry "e" 3]
        list group by es (e => int to str (score e)) -> assert eq [("2", [Entry "a" 2, Entry "c" 2]), ("1", [Entry "b" 1, Entry "d" 1]), ("3", [Entry "e" 3])]
        list group by words (w => w) -> assert eq [("x", ["x", "x", "x"]), ("y", ["y"]), ("", ["", ""]), (hi, [hi, hi]), (long_a, [long_a]), (long_b, [long_b])]
        list group by [] (e => name e) -> assert eq []

        big = list count by (gen entries 0 20000 []) (e => int to str (score e))
        list len (map ((k c) => c) big) -> assert int equals 1000 "AC4: 1000 distinct keys"
        sum counts big 0 -> assert int equals 20000 "AC4: counts add up to 20000"
        ()
```

---

## 03.4. Sota el capó: com està construïda `list` en Ridgun pur (`src/main/ridgun/lib/list.ridgun`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/list.ridgun` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 03.4.1. Implementació interna: List Length & Emptiness

Fixa't en com `list.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
module :: list

-- `list len`, `list nth or`, `list last or`, `list take`, `list drop`, `list reverse` and
-- `list contains` are the generic ones of the compiler prelude (ridgunc 0.9.55).
-- The `list str` names stay as one-line aliases.

fn :: list str len [String] => Int
      list str len xs       =  list len xs

fn :: list is empty [Int] => Bool
      list is empty []    =  True
      list is empty _     =  False

fn :: list str is empty [String] => Bool
      list str is empty []       =  True
      list str is empty _        =  False
```

### 03.4.2. Implementació interna: Slicing (`take`, `drop`, `slice`) & Reversal

Fixa't en com `list.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
fn :: list str take [String] Int => [String]
      list str take xs       n   =  list take xs n

fn :: list str drop [String] Int => [String]
      list str drop xs       n   =  list drop xs n

fn :: l clamp nonneg Int => Int
      l clamp nonneg x   =
        | x < 0     = 0
        | otherwise = x

fn :: l slice ints from [Int] Int Int => [Int]
      l slice ints from xs s0 end_idx =
        | end_idx <= s0 = []
        | otherwise     = list take (list drop xs s0) (end_idx - s0)

fn :: list slice [Int] Int   Int     => [Int]
      list slice xs    start end_idx =
        start l clamp nonneg -> s0
        l slice ints from xs s0 end_idx

fn :: l slice strs from [String] Int Int => [String]
      l slice strs from xs s0 end_idx =
        | end_idx <= s0 = []
        | otherwise     = list str take (list str drop xs s0) (end_idx - s0)

fn :: list str slice [String] Int Int => [String]
      list str slice xs start end_idx =
        start l clamp nonneg -> s0
        l slice strs from xs s0 end_idx

fn :: list str reverse [String] => [String]
      list str reverse xs       =  list reverse xs
```

### 03.4.3. Implementació interna: Search, Count & Deduplication

Fixa't en com `list.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
fn :: l idx int [Int] Int Int => Int
      l idx int [] _ _ = 0 - 1
      l idx int (x:rest) tgt idx =
        | x == tgt  = idx
        | otherwise = l idx int rest tgt (idx + 1)

fn :: list index of [Int] Int => Int
      list index of xs    tgt =  l idx int xs tgt 0

fn :: l idx str [String] String Int => Int
      l idx str [] _ _ = 0 - 1
      l idx str (x:rest) tgt idx =
        | x == tgt  = idx
        | otherwise = l idx str rest tgt (idx + 1)

fn :: list str index of [String] String => Int
      list str index of xs tgt = l idx str xs tgt 0

fn :: list str contains [String] String => Bool
      list str contains xs       tgt    =  list contains xs tgt

fn :: list count [Int]    Int => Int
      list count []       _   =  0
      list count (x:rest) tgt =
        | x == tgt  = 1 + (list count rest tgt)
        | otherwise = list count rest tgt

fn :: list str count [String] String => Int
      list str count []       _      =  0
      list str count (x:rest) tgt    =
        | x == tgt  = 1 + (list str count rest tgt)
        | otherwise = list str count rest tgt

fn :: l dedup ints [Int]    [Int] => [Int]
      l dedup ints []       seen  =  list reverse seen
      l dedup ints (x:rest) seen  =
        | list contains seen x = l dedup ints rest seen
        | otherwise            = l dedup ints rest ([x] :: seen)

fn :: list dedup [Int] => [Int]
      list dedup xs    =  l dedup ints xs []

fn :: l dedup strs [String] [String] => [String]
      l dedup strs []       seen     =  list str reverse seen
      l dedup strs (x:rest) seen     =
        | list str contains seen x = l dedup strs rest seen
        | otherwise                = l dedup strs rest ([x] :: seen)

fn :: list str dedup [String] => [String]
      list str dedup xs       =  l dedup strs xs []
```

### 03.4.4. Implementació interna: Associative Key-Value Map (`[String String]`, `RG-066`)

Fixa't en com `list.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
fn :: l kv key (String String) => String
      l kv key (k, _)          =  k

fn :: l kv val (String String) => String
      l kv val (_, v)          =  v

fn :: list kv empty => [String String]
      list kv empty =  []

fn :: list kv len [String String] => Int
      list kv len []              =  0
      list kv len (_:rest)        =  1 + (list kv len rest)

fn :: list kv has [String String] String => Bool
      list kv has []              _      =  False
      list kv has (pair:rest)     key    =
        | (l kv key pair) == key = True
        | otherwise              = list kv has rest key

fn :: list kv get or [String String] String String => String
      list kv get or [] _ fallback = fallback
      list kv get or (pair:rest) key fallback =
        | (l kv key pair) == key = l kv val pair
        | otherwise              = list kv get or rest key fallback

fn :: list kv get [String String] String => String
      list kv get pairs           key    =  list kv get or pairs key ""

fn :: list kv put [String String] String String => [String String]
      list kv put []              key    val    =  [(key, val)]
      list kv put (pair:rest)     key    val    =
        | (l kv key pair) == key = [(key, val)] :: rest
        | otherwise              = [pair] :: (list kv put rest key val)

fn :: list kv remove [String String] String => [String String]
      list kv remove []              _      =  []
      list kv remove (pair:rest)     key    =
        | (l kv key pair) == key = list kv remove rest key
        | otherwise              = [pair] :: (list kv remove rest key)

fn :: list kv keys [String String] => [String]
      list kv keys []              =  []
      list kv keys (pair:rest)     =  [(l kv key pair)] :: (list kv keys rest)

fn :: list kv values [String String] => [String]
      list kv values []              =  []
      list kv values (pair:rest)     =  [(l kv val pair)] :: (list kv values rest)

fn :: list kv merge [String String] [String String] => [String String]
      list kv merge base            []              =  base
      list kv merge base            (pair:rest)     =
        list kv merge (list kv put base (l kv key pair) (l kv val pair)) rest
```

---

## 03.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `list`

- **Garantia algorísmica i de seguretat**: Ordenació determinista $O(N \log N)$ en el pitjor cas (sense l'$O(N^2)$ patològic de Quicksort) i preservació de l'ordre d'inserció en mapes `kv`.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/list.ridgun` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test list.ridgun`.

### Les 5 Regles d'Or en programar amb `list`

1. **Declara `import list` a l'inici del fitxer** i crida les seves funcions amb espais, tal com estan declarades, perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `list` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `list` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `list` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 04** passarem a explorar en profunditat la lib **`btree`** (La lib `btree` — Arbres AVL Persistents $O(\log N)$, Conjunts i Monticles).
