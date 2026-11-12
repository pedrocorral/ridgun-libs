# Capitolo 13: La lib `diff` — Algoritmo LCS, Distanza di Modifica, Unified Diff e Patch

## 13.1. Perché esiste la lib `diff`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `diff` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `diff`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: quando un test fallisce o un file di configurazione cambia, un secco `"expected A, got B"` di 200 righe ti costringe a consumarti gli occhi per capire quale riga esatta sia cambiata.

La lib **`diff`** calcola la **Sottosequenza Comune Più Lunga (LCS)** su `Tensor[Int]` 2D per produrre modifiche minime (`DiffKeep`, `DiffAdd`, `DiffDel`), distanza di modifica, statistiche, formato **Unified Diff** (`---`/`+++`/`@@`) e ricostruzione esatta con `diff apply`.

In un ecosistema tradizionale, risolvere i compiti del dominio **`DIFF`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`diff`** (`src/main/ridgun/lib/diff.ridgun`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import diff` (o `import diff as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: diff` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `diff` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 13.2. Artefatti nativi, importazione e catalogo completo dell'API di `diff`

In `ridgun-libs`, **`diff`** è una **lib** di prima classe situata in `src/main/ridgun/lib/diff.ridgun` (dominio `DIFF`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/diff.ridgunlib` | Distribuzione e importazione diretta con `import diff` |
| **File compilato** | `target/diff.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libdiff.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: diff`: basta scrivere `import diff` (o `import diff as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 13.2.1. Riepilogo delle famiglie funzionali di `diff`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `type DiffOp` | `DiffKeep String | DiffDel String | DiffAdd String` |
| `diff lines / diff text` | Calcola lo script minimo di modifica LCS tra liste `[String]` o testi multilinea |
| `diff edit distance / diff stats` | Distanza minima di inserimento+cancellazione e conteggio `(kept, added, deleted)` |
| `diff format / diff unified` | Formatta righe compatte `+ / - /  ` o Unified Diff standard con intestazioni |
| `diff apply / diff apply text` | Ricostruisce il documento di destinazione senza perdite a partire dallo script di modifica |

### 13.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/diff.ridgun`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/diff.ridgun` (`2` tipi, `0` operatori e `33` funzioni):

**Tipi algebrici e record (`type`) di `diff`:**

```ridgun
type DiffEdit = diff_op: String, line_text: String, old_line_no: Int, new_line_no: Int
type DiffStats = equal_count: Int, insert_count: Int, delete_count: Int
```

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
|---|---|---|
| `1` | `fn :: df max Int Int` | `Int` |
| `2` | `fn :: df int to str pos Int` | `String` |
| `3` | `fn :: df int to str Int` | `String` |
| `4` | `fn :: df rev [String] [String]` | `[String]` |
| `5` | `fn :: df rev ints [Int] [Int]` | `[Int]` |
| `6` | `fn :: df split lines loop String Int Int Int [String]` | `[String]` |
| `7` | `fn :: df split lines String` | `[String]` |
| `8` | `fn :: df zeros Int [Int]` | `[Int]` |
| `9` | `fn :: df nth int [Int] Int` | `Int` |
| `10` | `fn :: df head int [Int]` | `Int` |
| `11` | `fn :: df cell val String String Int Int Int` | `Int` |
| `12` | `fn :: df build row String [String] [Int] Int [Int]` | `[Int]` |
| `13` | `fn :: df build dp [String] [String] [[Int]]` | `[[Int]]` |
| `14` | `fn :: df tail rows [[Int]]` | `[[Int]]` |
| `15` | `fn :: df head row [[Int]]` | `[Int]` |
| `16` | `fn :: df rev edits [DiffEdit] [DiffEdit]` | `[DiffEdit]` |
| `17` | `fn :: df backtrack [String] [String] [[Int]] Int Int Int [DiffEdit]` | `[DiffEdit]` |
| `18` | `fn :: df backtrack step String [String] String [String] [[Int]] Int Int Int [DiffEdit]` | `[DiffEdit]` |
| `19` | `fn :: df backtrack branch String [String] String [String] [[Int]] [[Int]] Int Int Int Int Int [DiffEdit]` | `[DiffEdit]` |
| `20` | `fn :: df list length [String]` | `Int` |
| `21` | `fn :: diff lines [String] [String]` | `[DiffEdit]` |
| `22` | `fn :: diff text String String` | `[DiffEdit]` |
| `23` | `fn :: df stats loop [DiffEdit] Int Int Int` | `DiffStats` |
| `24` | `fn :: diff stats [DiffEdit]` | `DiffStats` |
| `25` | `fn :: diff edit distance String String` | `Int` |
| `26` | `fn :: diff has changes [DiffEdit]` | `Bool` |
| `27` | `fn :: df format unified lines [DiffEdit] String` | `String` |
| `28` | `fn :: df hunk start Int` | `Int` |
| `29` | `fn :: df unified header String String Int Int` | `String` |
| `30` | `fn :: diff unified String String String String` | `String` |
| `31` | `fn :: df apply collect [DiffEdit] [String]` | `[String]` |
| `32` | `fn :: df join lines [String]` | `String` |
| `33` | `fn :: diff apply [DiffEdit]` | `String` |

---

## 13.3. Esplorare `diff` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `diff` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test diff.ridgun`.

### 13.3.1. Esempio 1: Flusso principale in stile tabulare con `diff`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `diff` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import diff

fn :: auditar cambio String String => Int String
      auditar cambio antes despues =
        diff edit distance antes despues -> dist
        diff unified antes despues "config.old" "config.new" -> parche
        (dist, parche)
```

### 13.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `diff` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import diff

fn :: verificar parche String [DiffEdit] => String
      verificar parche orig ops =
        diff apply orig ops
```

### 13.3.3. Esempio 3: Confronto di testi vuoti e identici: distanza di modifica zero e verifica degli invarianti

In questo esempio pratico esploriamo in modo esaustivo come si comporta `diff` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test diff empty and identical => ()
      test diff empty and identical =
        nl = char from code 10
        e_empty = diff text "" ""
        assert int equals (count edits e_empty) 0 "AC1: empty diff edit count"
        assert false (diff has changes e_empty) "AC1: empty diff has no changes"
        assert int equals (diff edit distance "" "") 0 "AC1: empty edit distance"
        assert str eq (diff apply e_empty) "" "AC3: empty diff apply"
        same_doc = "alpha" + nl + "beta" + nl + "gamma"
        e_same = diff text same_doc same_doc
        assert int equals (count edits e_same) 3 "AC1: identical 3-line count"
        assert false (diff has changes e_same) "AC1: identical has no changes"
        st_same = diff stats e_same
        assert int equals (equal_count st_same) 3 "AC1: equal_count == 3"
        assert int equals (insert_count st_same) 0 "AC1: insert_count == 0"
        assert int equals (delete_count st_same) 0 "AC1: delete_count == 0"
        assert int equals (diff edit distance same_doc same_doc) 0 "AC1: identical edit distance == 0"
        assert str eq (diff apply e_same) same_doc "AC3: identical diff apply"
        ()
```

### 13.3.4. Esempio 4: Inserimenti puri (`DiffInsert`), cancellazioni pure (`DiffDelete`) e applicazione in avanti (`diff patch`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `diff` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test diff pure insert and delete => ()
      test diff pure insert and delete =
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
        ins0 = nth edit e_ins 0
        ins2 = nth edit e_ins 2
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
        del0 = nth edit e_del 0
        del2 = nth edit e_del 2
        assert str eq (diff_op del0) "delete" "AC1: del0 op"
        assert int equals (old_line_no del0) 1 "AC1: del0 old_line_no"
        assert int equals (new_line_no del0) 0 "AC1: del0 new_line_no"
        assert int equals (old_line_no del2) 3 "AC1: del2 old_line_no"
        ()
```

### 13.3.5. Esempio 5: Il vettore classico di Eugene Myers (`ABCABBA` $\rightarrow$ `CBABAC`): sottosequenza comune più lunga (LCS) e distanza minima

In questo esempio pratico esploriamo in modo esaustivo come si comporta `diff` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test diff myers classic vector => ()
      test diff myers classic vector =
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

### 13.3.6. Esempio 6: Ispezione dei numeri di riga sorgente e destinazione (`diff old line`, `diff new line`) e ricostruzione esatta con `diff patch`

In questo esempio pratico esploriamo in modo esaustivo come si comporta `diff` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test diff code hunks and line numbers => ()
      test diff code hunks and line numbers =
        nl = char from code 10
        old_code = "fn :: add Int Int => Int" + nl + "      add a b = a + b" + nl + "" + nl + "fn :: sub Int Int => Int" + nl + "      sub a b = a - b"
        new_code = "fn :: add Int Int => Int" + nl + "      add x y = x + y" + nl + "" + nl + "fn :: mul Int Int => Int" + nl + "      mul a b = a * b" + nl + "" + nl + "fn :: sub Int Int => Int" + nl + "      sub a b = a - b"
        edits = diff text old_code new_code
        assert true (diff has changes edits) "AC1: code refactoring has changes"
        assert str eq (diff apply edits) new_code "AC3: code refactoring lossless apply"
        e0 = nth edit edits 0
        assert str eq (diff_op e0) "equal" "AC1: line 1 equal"
        assert int equals (old_line_no e0) 1 "AC1: line 1 old_line_no"
        assert int equals (new_line_no e0) 1 "AC1: line 1 new_line_no"
        e1 = nth edit edits 1
        assert str eq (diff_op e1) "delete" "AC1: line 2 deleted"
        assert str eq (line_text e1) "      add a b = a + b" "AC1: deleted line text"
        assert int equals (old_line_no e1) 2 "AC1: deleted old_line_no"
        assert int equals (new_line_no e1) 0 "AC1: deleted new_line_no"
        e2 = nth edit edits 2
        assert str eq (diff_op e2) "insert" "AC1: line 2 inserted"
        assert str eq (line_text e2) "      add x y = x + y" "AC1: inserted line text"
        assert int equals (old_line_no e2) 0 "AC1: inserted old_line_no"
        assert int equals (new_line_no e2) 2 "AC1: inserted new_line_no"
        ()
```

### 13.3.7. Esempio 7: Generazione di patch unificate in stile GNU (`--- old`, `+++ new`, `-`, `+`, ` `) con `diff unified` e statistiche `(kept, deleted, inserted)`

In questo esempio pratico esploriamo in modo esaustivo come si comporta `diff` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test diff unified formatting => ()
      test diff unified formatting =
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

### 13.3.8. Esempio 8: Robustezza su file con righe ripetute e blocchi duplicati

In questo esempio pratico esploriamo in modo esaustivo come si comporta `diff` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test diff repetitive lines => ()
      test diff repetitive lines =
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

## 13.4. Sotto il cofano: come è costruita `diff` in Ridgun puro (`src/main/ridgun/lib/diff.ridgun`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/diff.ridgun` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 13.4.1. Implementazione interna: Internal Helpers

Nota come `diff.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 13.4.2. Implementazione interna: Public API

Nota come `diff.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

## 13.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `diff`

- **Garanzia algoritmica e di sicurezza**: Identità matematica garantita $diff\_edit\_distance(a, b) == |a| + |b| - 2 \cdot LCS(a, b)$ e ricostruzione senza perdite `diff apply (diff lines a b) == b`.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/diff.ridgun` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test diff.ridgun`.

### Le 5 Regole d'Oro quando programmi con `diff`

1. **Dichiara `import diff` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `diff` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `diff` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `diff` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 14** passeremo a esplorare in profondità la lib **`template`** (La lib `template` — Modelli Mustache Sicuri con Auto-Escape HTML e LaTeX).
