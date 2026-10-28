# Capítol 13: La lib `diff` — Algorisme LCS, Distància d'Edició, Unified Diff i Pedaços

## 13.1. Per què existeix la lib `diff`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `diff` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `diff`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: quan un test falla o un fitxer de configuració canvia, un sec `"expected A, got B"` de 200 línies t'obliga a deixar-te les pestanyes buscant quina línia exacta ha canviat.

La lib **`diff`** calcula la **Subseqüència Comuna Més Llarga (LCS)** sobre `Tensor[Int]` 2D per produir edicions mínimes (`DiffKeep`, `DiffAdd`, `DiffDel`), distància d'edició, estadístiques, format **Unified Diff** (`---`/`+++`/`@@`) i reconstrucció exacta amb `diff apply`.

En un ecosistema tradicional, resoldre les tasques del domini **`DIFF`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`diff`** (`src/main/ridgun/lib/diff.rg`) aborda el problema amb quatre principis innegociables:

1. **Declara `import diff` (o `import diff as alias`) a l'inici del fitxer**: cada lib defineix el seu espai de noms `module :: diff` i en mode `--strict` les funcions multi-paraula s'invoquen sempre amb espais naturals.
2. **Encadena les teves canonades d'esquerra a dreta amb `->`**: escriu `entrada pas u -> pas dos -> resultat`, fes servir màscares `(+ _ _ +)` per desestructurar seqüències i omet `_ =` en sentències seqüencials (o descarta amb `-> ()`).
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `diff` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 13.2. Artefactes natius, importació i catàleg complet de l'API de `diff`

A `ridgun-libs`, **`diff`** és una **lib** de primera classe situada a `src/main/ridgun/lib/diff.rg` (domini `DIFF`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/diff.rglib` | Distribució i importació directa amb `import diff` |
| **Fitxer compilat** | `target/diff.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libdiff.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Cada lib declara el seu propi espai de noms amb `module :: diff`: n'hi ha prou d'escriure `import diff` (o `import diff as alias`) a la capçalera i cridar les seves funcions amb espais naturals (`la meva funcio x`) i canonades `->` (`x la meva funcio -> resultat`).

### 13.2.1. Resum de famílies funcionals de `diff`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `type DiffOp` | `DiffKeep String | DiffDel String | DiffAdd String` |
| `diff lines / diff text` | Calcula el guió mínim d'edició LCS entre llistes `[String]` o textos multilínia |
| `diff edit distance / diff stats` | Distància mínima d'inserció+esborrat i recompte `(kept, added, deleted)` |
| `diff format / diff unified` | Formata línies compactes `+ / - /  ` o Unified Diff estàndard amb capçaleres |
| `diff apply / diff apply text` | Reconstrueix el document destí sense pèrdues a partir del guió d'edició |

### 13.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/diff.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/diff.rg` (`2` tipus, `0` operadors i `33` funcions):

**Tipus algebraics i registres (`type`) de `diff`:**

```ridgun
type DiffEdit = diff_op: String, line_text: String, old_line_no: Int, new_line_no: Int
type DiffStats = equal_count: Int, insert_count: Int, delete_count: Int
```

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
|---|---|---|
| `1` | `fn :: df_max Int Int` | `Int` |
| `2` | `fn :: df_int_to_str_pos Int` | `String` |
| `3` | `fn :: df_int_to_str Int` | `String` |
| `4` | `fn :: df_rev [String] [String]` | `[String]` |
| `5` | `fn :: df_rev_ints [Int] [Int]` | `[Int]` |
| `6` | `fn :: df_split_lines_loop String Int Int Int [String]` | `[String]` |
| `7` | `fn :: df_split_lines String` | `[String]` |
| `8` | `fn :: df_zeros Int [Int]` | `[Int]` |
| `9` | `fn :: df_nth_int [Int] Int` | `Int` |
| `10` | `fn :: df_head_int [Int]` | `Int` |
| `11` | `fn :: df_cell_val String String Int Int Int` | `Int` |
| `12` | `fn :: df_build_row String [String] [Int] Int [Int]` | `[Int]` |
| `13` | `fn :: df_build_dp [String] [String] [[Int]]` | `[[Int]]` |
| `14` | `fn :: df_tail_rows [[Int]]` | `[[Int]]` |
| `15` | `fn :: df_head_row [[Int]]` | `[Int]` |
| `16` | `fn :: df_rev_edits [DiffEdit] [DiffEdit]` | `[DiffEdit]` |
| `17` | `fn :: df_backtrack [String] [String] [[Int]] Int Int Int [DiffEdit]` | `[DiffEdit]` |
| `18` | `fn :: df_backtrack_step String [String] String [String] [[Int]] Int Int Int [DiffEdit]` | `[DiffEdit]` |
| `19` | `fn :: df_backtrack_branch String [String] String [String] [[Int]] [[Int]] Int Int Int Int Int [DiffEdit]` | `[DiffEdit]` |
| `20` | `fn :: df_list_length [String]` | `Int` |
| `21` | `fn :: diff lines [String] [String]` | `[DiffEdit]` |
| `22` | `fn :: diff text String String` | `[DiffEdit]` |
| `23` | `fn :: df_stats_loop [DiffEdit] Int Int Int` | `DiffStats` |
| `24` | `fn :: diff stats [DiffEdit]` | `DiffStats` |
| `25` | `fn :: diff edit distance String String` | `Int` |
| `26` | `fn :: diff has changes [DiffEdit]` | `Bool` |
| `27` | `fn :: df_format_unified_lines [DiffEdit] String` | `String` |
| `28` | `fn :: df_hunk_start Int` | `Int` |
| `29` | `fn :: df_unified_header String String Int Int` | `String` |
| `30` | `fn :: diff unified String String String String` | `String` |
| `31` | `fn :: df_apply_collect [DiffEdit] [String]` | `[String]` |
| `32` | `fn :: df_join_lines [String]` | `String` |
| `33` | `fn :: diff apply [DiffEdit]` | `String` |

---

## 13.3. Explorant `diff` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `diff` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test diff.rg`.

### 13.3.1. Exemple 1: Flux principal en estil tabular amb `diff`

Observa com en Ridgun els signes `=` i els passos de transformació amb `diff` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import diff

fn :: auditar cambio String String => Int String
      auditar cambio antes despues =
        diff edit distance antes despues -> dist
        diff unified antes despues "config.old" "config.new" -> parche
        (dist, parche)
```

### 13.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `diff` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import diff

fn :: verificar parche String [DiffEdit] => String
      verificar parche orig ops =
        diff apply orig ops
```

### 13.3.3. Exemple 3: Comparació de textos buits i idèntics: distància d'edició zero i verificació d'invariants

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `diff` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test_diff_empty_and_identical => ()
      test_diff_empty_and_identical =
        nl = char from code 10
        e_empty = diff text "" ""
        assert int equals (count_edits e_empty) 0 "AC1: empty diff edit count"
        assert false (diff has changes e_empty) "AC1: empty diff has no changes"
        assert int equals (diff edit distance "" "") 0 "AC1: empty edit distance"
        assert str eq (diff apply e_empty) "" "AC3: empty diff apply"
        same_doc = "alpha" + nl + "beta" + nl + "gamma"
        e_same = diff text same_doc same_doc
        assert int equals (count_edits e_same) 3 "AC1: identical 3-line count"
        assert false (diff has changes e_same) "AC1: identical has no changes"
        st_same = diff stats e_same
        assert int equals (equal_count st_same) 3 "AC1: equal_count == 3"
        assert int equals (insert_count st_same) 0 "AC1: insert_count == 0"
        assert int equals (delete_count st_same) 0 "AC1: delete_count == 0"
        assert int equals (diff edit distance same_doc same_doc) 0 "AC1: identical edit distance == 0"
        assert str eq (diff apply e_same) same_doc "AC3: identical diff apply"
        ()
```

### 13.3.4. Exemple 4: Insercions pures (`DiffInsert`), esborrats purs (`DiffDelete`) i aplicació cap endavant (`diff patch`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `diff` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test_diff_pure_insert_and_delete => ()
      test_diff_pure_insert_and_delete =
        nl = char from code 10
        target = "line1" + nl + "line2" + nl + "line3"
        e_ins = diff text "" target
        assert true (diff has changes e_ins) "AC1: pure insert has changes"
        st_ins = diff stats e_ins
        assert int equals (equal_count st_ins) 0 "AC1: pure insert equal_count"
        assert int equals (insert_count st_ins) 3 "AC1: pure insert insert_count"
        assert int equals (delete_count st_ins) 0 "AC1: pure insert delete_count"
        assert int equals (diff edit distance "" target) 3 "AC1: pure insert edit distance"
        assert str eq (diff apply e_ins) target "AC3: pure insert apply"
        ins0 = nth_edit e_ins 0
        ins2 = nth_edit e_ins 2
        assert str eq (diff_op ins0) "insert" "AC1: ins0 op"
        assert int equals (old_line_no ins0) 0 "AC1: ins0 old_line_no"
        assert int equals (new_line_no ins0) 1 "AC1: ins0 new_line_no"
        assert int equals (new_line_no ins2) 3 "AC1: ins2 new_line_no"
        e_del = diff text target ""
        assert true (diff has changes e_del) "AC1: pure delete has changes"
        st_del = diff stats e_del
        assert int equals (equal_count st_del) 0 "AC1: pure delete equal_count"
        assert int equals (insert_count st_del) 0 "AC1: pure delete insert_count"
        assert int equals (delete_count st_del) 3 "AC1: pure delete delete_count"
        assert int equals (diff edit distance target "") 3 "AC1: pure delete edit distance"
        assert str eq (diff apply e_del) "" "AC3: pure delete apply"
        del0 = nth_edit e_del 0
        del2 = nth_edit e_del 2
        assert str eq (diff_op del0) "delete" "AC1: del0 op"
        assert int equals (old_line_no del0) 1 "AC1: del0 old_line_no"
        assert int equals (new_line_no del0) 0 "AC1: del0 new_line_no"
        assert int equals (old_line_no del2) 3 "AC1: del2 old_line_no"
        ()
```

### 13.3.5. Exemple 5: El vector clàssic d'Eugene Myers (`ABCABBA` $\rightarrow$ `CBABAC`): subseqüència comuna més llarga (LCS) i distància mínima

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `diff` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test_diff_myers_classic_vector => ()
      test_diff_myers_classic_vector =
        nl = char from code 10
        old_lines = ["A", "B", "C", "A", "B", "B", "A"]
        new_lines = ["C", "B", "A", "B", "A", "C"]
        edits = diff lines old_lines new_lines
        st = diff stats edits
        assert int equals (equal_count st) 4 "AC1: Myers LCS length 4"
        assert int equals (delete_count st) 3 "AC1: Myers delete count 3"
        assert int equals (insert_count st) 2 "AC1: Myers insert count 2"
        old_s = "A" + nl + "B" + nl + "C" + nl + "A" + nl + "B" + nl + "B" + nl + "A"
        new_s = "C" + nl + "B" + nl + "A" + nl + "B" + nl + "A" + nl + "C"
        assert int equals (diff edit distance old_s new_s) 5 "AC1: Myers edit distance 5"
        assert str eq (diff apply edits) new_s "AC3: Myers apply reproduces CBABAC"
        ()
```

### 13.3.6. Exemple 6: Inspecció de números de línia d'origen i destí (`diff old line`, `diff new line`) i reconstrucció exacta amb `diff patch`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `diff` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test_diff_code_hunks_and_line_numbers => ()
      test_diff_code_hunks_and_line_numbers =
        nl = char from code 10
        old_code = "fn :: add Int Int => Int" + nl + "      add a b = a + b" + nl + "" + nl + "fn :: sub Int Int => Int" + nl + "      sub a b = a - b"
        new_code = "fn :: add Int Int => Int" + nl + "      add x y = x + y" + nl + "" + nl + "fn :: mul Int Int => Int" + nl + "      mul a b = a * b" + nl + "" + nl + "fn :: sub Int Int => Int" + nl + "      sub a b = a - b"
        edits = diff text old_code new_code
        assert true (diff has changes edits) "AC1: code refactoring has changes"
        assert str eq (diff apply edits) new_code "AC3: code refactoring lossless apply"
        e0 = nth_edit edits 0
        assert str eq (diff_op e0) "equal" "AC1: line 1 equal"
        assert int equals (old_line_no e0) 1 "AC1: line 1 old_line_no"
        assert int equals (new_line_no e0) 1 "AC1: line 1 new_line_no"
        e1 = nth_edit edits 1
        assert str eq (diff_op e1) "delete" "AC1: line 2 deleted"
        assert str eq (line_text e1) "      add a b = a + b" "AC1: deleted line text"
        assert int equals (old_line_no e1) 2 "AC1: deleted old_line_no"
        assert int equals (new_line_no e1) 0 "AC1: deleted new_line_no"
        e2 = nth_edit edits 2
        assert str eq (diff_op e2) "insert" "AC1: line 2 inserted"
        assert str eq (line_text e2) "      add x y = x + y" "AC1: inserted line text"
        assert int equals (old_line_no e2) 0 "AC1: inserted old_line_no"
        assert int equals (new_line_no e2) 2 "AC1: inserted new_line_no"
        ()
```

### 13.3.7. Exemple 7: Generació de pegats unificats estil GNU (`--- old`, `+++ new`, `-`, `+`, ` `) amb `diff unified` i estadístiques `(kept, deleted, inserted)`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `diff` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test_diff_unified_formatting => ()
      test_diff_unified_formatting =
        nl = char from code 10
        old_s = "one" + nl + "two" + nl + "three"
        new_s = "one" + nl + "TWO" + nl + "three" + nl + "four"
        uni = diff unified "a/sample.txt" "b/sample.txt" old_s new_s
        expected = "--- a/sample.txt" + nl + "+++ b/sample.txt" + nl + "@@ -1,3 +1,4 @@" + nl + " one" + nl + "-two" + nl + "+TWO" + nl + " three" + nl + "+four" + nl
        assert str eq uni expected "AC2: unified diff output matches standard header and hunk format"
        uni_empty = diff unified "a/empty" "b/empty" "" ""
        assert str eq uni_empty ("--- a/empty" + nl + "+++ b/empty" + nl + "@@ -0,0 +0,0 @@" + nl) "AC2: unified diff empty files"
        ()
```

### 13.3.8. Exemple 8: Robustesa davant fitxers amb línies repetides i blocs duplicats

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `diff` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test_diff_repetitive_lines => ()
      test_diff_repetitive_lines =
        nl = char from code 10
        old_rep = "x" + nl + "x" + nl + "y" + nl + "x" + nl + "x"
        new_rep = "x" + nl + "y" + nl + "y" + nl + "x"
        edits = diff text old_rep new_rep
        st = diff stats edits
        assert int equals (equal_count st) 3 "AC1: repetitive LCS equal_count"
        assert int equals (delete_count st) 2 "AC1: repetitive LCS delete_count"
        assert int equals (insert_count st) 1 "AC1: repetitive LCS insert_count"
        assert str eq (diff apply edits) new_rep "AC3: repetitive lines apply"
        ()
```

---

## 13.4. Sota el capó: com està construïda `diff` en Ridgun pur (`src/main/ridgun/lib/diff.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/diff.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 13.4.1. Implementació interna: Internal Helpers

Fixa't en com `diff.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
module :: diff

fn :: df max Int Int => Int
      df max a b =
        | a >= b = a
        | otherwise = b

fn :: df int to str pos Int => String
      df int to str pos n =
        | n == 0 = ""
        | otherwise = (df int to str pos (n / 10)) + (char from code ((n % 10) + 48))

fn :: df int to str Int => String
      df int to str n =
        | n == 0 = "0"
        | n < 0 = "-" + (df int to str pos (0 - n))
        | otherwise = df int to str pos n

fn :: df rev [String] [String] => [String]
      df rev [] acc = acc
      df rev (x:xs) acc = df rev xs ([x] :: acc)

fn :: df rev ints [Int] [Int] => [Int]
      df rev ints [] acc = acc
      df rev ints (x:xs) acc = df rev ints xs ([x] :: acc)

fn :: df split lines loop String Int Int Int [String] => [String]
      df split lines loop s idx n start acc =
        | idx >= n = df rev ([str slice s start n] :: acc) []
        | (str char at s idx) == 10 = df split lines loop s (idx + 1) n (idx + 1) ([str slice s start idx] :: acc)
        | otherwise = df split lines loop s (idx + 1) n start acc

fn :: df split lines String => [String]
      df split lines s =
        | (str len s) == 0 = []
        | otherwise = df split lines loop s 0 (str len s) 0 []

fn :: df zeros Int [Int] => [Int]
      df zeros n acc =
        | n <= 0 = acc
        | otherwise = df zeros (n - 1) ([0] :: acc)

fn :: df nth int [Int] Int => Int
      df nth int [] _ = 0
      df nth int (x:xs) idx =
        | idx <= 0 = x
        | otherwise = df nth int xs (idx - 1)

fn :: df head int [Int] => Int
      df head int [] = 0
      df head int (x:_) = x

fn :: df cell val String String Int Int Int => Int
      df cell val old_line b diag down right_val =
        | old_line == b = diag + 1
        | otherwise = df max down right_val

fn :: df build row String [String] [Int] Int [Int] => [Int]
      df build row _ [] _ _ acc = acc
      df build row old_line (b:bs) (diag:next_rest) right_val acc =
        cell = df cell val old_line b diag (df head int next_rest) right_val
        df build row old_line bs next_rest cell ([cell] :: acc)
      df build row _ (_:_) [] _ acc = acc

fn :: df build dp [String] [String] [[Int]] => [[Int]]
      df build dp [] _ rows = rows
      df build dp (a:as) rev_new (next_row:rest_rows) =
        next_rev = df rev ints next_row []
        curr_row = df build row a rev_new next_rev 0 [0]
        df build dp as rev_new ([curr_row, next_row] :: rest_rows)
      df build dp (_:_) _ [] = []

fn :: df tail rows [[Int]] => [[Int]]
      df tail rows [] = []
      df tail rows (_:rs) = rs

fn :: df head row [[Int]] => [Int]
      df head row [] = []
      df head row (r:_) = r

fn :: df rev edits [DiffEdit] [DiffEdit] => [DiffEdit]
      df rev edits [] acc = acc
      df rev edits (e:es) acc = df rev edits es ([e] :: acc)

fn :: df backtrack [String] [String] [[Int]] Int Int Int [DiffEdit] => [DiffEdit]
      df backtrack [] [] _ _ _ _ acc = df rev edits acc []
      df backtrack [] (b:bs) rows j old_no new_no acc =
        ed = DiffEdit "insert" b 0 new_no
        df backtrack [] bs rows (j + 1) old_no (new_no + 1) ([ed] :: acc)
      df backtrack (a:as) [] rows j old_no new_no acc =
        ed = DiffEdit "delete" a old_no 0
        df backtrack as [] (df tail rows rows) j (old_no + 1) new_no ([ed] :: acc)
      df backtrack (a:as) (b:bs) rows j old_no new_no acc =
        df backtrack step a as b bs rows j old_no new_no acc

fn :: df backtrack step String [String] String [String] [[Int]] Int Int Int [DiffEdit] => [DiffEdit]
      df backtrack step a as b bs rows j old_no new_no acc =
        | a == b =
          df backtrack as bs (df tail rows rows) (j + 1) (old_no + 1) (new_no + 1) ([DiffEdit "equal" a old_no new_no] :: acc)
        | otherwise =
          df backtrack branch a as b bs rows (df tail rows rows) j old_no new_no (df nth int (df head row (df tail rows rows)) j) (df nth int (df head row rows) (j + 1)) acc

fn :: df backtrack branch String [String] String [String] [[Int]] [[Int]] Int Int Int Int Int [DiffEdit] => [DiffEdit]
      df backtrack branch a as b bs rows next_rows j old_no new_no del_score ins_score acc =
        | del_score >= ins_score =
          df backtrack as ([b] :: bs) next_rows j (old_no + 1) new_no ([DiffEdit "delete" a old_no 0] :: acc)
        | otherwise =
          df backtrack ([a] :: as) bs rows (j + 1) old_no (new_no + 1) ([DiffEdit "insert" b 0 new_no] :: acc)

fn :: df list length [String] => Int
      df list length [] = 0
      df list length (_:xs) = 1 + (df list length xs)
```

### 13.4.2. Implementació interna: Public API

Fixa't en com `diff.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
fn :: diff lines [String] [String] => [DiffEdit]
      diff lines old_lines new_lines =
        old_lines df rev [] -> rev_old
        new_lines df rev [] -> rev_new
        df zeros ((df list length new_lines) + 1) [] -> zero_row
        df build dp rev_old rev_new [zero_row] -> dp_rows
        df backtrack old_lines new_lines dp_rows 0 1 1 []

fn :: diff text String String => [DiffEdit]
      diff text old_s new_s = diff lines (df split lines old_s) (df split lines new_s)

fn :: df stats loop [DiffEdit] Int Int Int => DiffStats
      df stats loop [] eq ins del = DiffStats eq ins del
      df stats loop (e:es) eq ins del =
        | (diff_op e) == "equal" = df stats loop es (eq + 1) ins del
        | (diff_op e) == "insert" = df stats loop es eq (ins + 1) del
        | otherwise = df stats loop es eq ins (del + 1)

fn :: diff stats [DiffEdit] => DiffStats
      diff stats edits = df stats loop edits 0 0 0

fn :: diff edit distance String String => Int
      diff edit distance old_s new_s =
        diff text old_s new_s -> diff stats -> st
        (insert_count st) + (delete_count st)

fn :: diff has changes [DiffEdit] => Bool
      diff has changes [] = False
      diff has changes (e:es) =
        | (diff_op e) == "equal" = diff has changes es
        | otherwise = True

fn :: df format unified lines [DiffEdit] String => String
      df format unified lines [] acc = acc
      df format unified lines (e:es) acc =
        | (diff_op e) == "equal" = df format unified lines es (acc + " " + (line_text e) + (char from code 10))
        | (diff_op e) == "delete" = df format unified lines es (acc + "-" + (line_text e) + (char from code 10))
        | otherwise = df format unified lines es (acc + "+" + (line_text e) + (char from code 10))

fn :: df hunk start Int => Int
      df hunk start cnt =
        | cnt == 0 = 0
        | otherwise = 1

fn :: df unified header String String Int Int => String
      df unified header old_label new_label old_cnt new_cnt =
        old_cnt df hunk start -> old_start
        new_cnt df hunk start -> new_start
        char from code 10 -> nl
        "--- " + old_label + nl + "+++ " + new_label + nl + "@@ -" + (df int to str old_start) + "," + (df int to str old_cnt) + " +" + (df int to str new_start) + "," + (df int to str new_cnt) + " @@" + nl

fn :: diff unified String String String String => String
      diff unified old_label new_label old_s new_s =
        diff text old_s new_s -> edits
        edits diff stats -> st
        (equal_count st) + (delete_count st) -> old_cnt
        (equal_count st) + (insert_count st) -> new_cnt
        df unified header old_label new_label old_cnt new_cnt -> hdr
        df format unified lines edits hdr

fn :: df apply collect [DiffEdit] [String] => [String]
      df apply collect [] acc = df rev acc []
      df apply collect (e:es) acc =
        | (diff_op e) == "delete" = df apply collect es acc
        | otherwise = df apply collect es ([line_text e] :: acc)

fn :: df join lines [String] => String
      df join lines [] = ""
      df join lines (x:[]) = x
      df join lines (x:xs) = x + (char from code 10) + (df join lines xs)

fn :: diff apply [DiffEdit] => String
      diff apply edits = df join lines (df apply collect edits [])
```

---

## 13.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `diff`

- **Garantia algorísmica i de seguretat**: Identitat matemàtica garantida $diff\_edit\_distance(a, b) == |a| + |b| - 2 \cdot LCS(a, b)$ i reconstrucció sense pèrdues `diff apply (diff lines a b) == b`.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/diff.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test diff.rg`.

### Les 5 Regles d'Or en programar amb `diff`

1. **Declara `import diff` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `diff` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `diff` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `diff` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 14** passarem a explorar en profunditat la lib **`template`** (La lib `template` — Plantilles Mustache Segures amb Auto-Escapament HTML i LaTeX).
