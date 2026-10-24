# 13. kapitulua: `diff` lib-a — LCS Algoritmoa, Edizio-distantzia, Unified Diff eta Adabakiak

## 13.1. Zergatik existitzen da `diff` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `diff` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `diff`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: test batek huts egiten duenean edo konfigurazio-fitxategi bat aldatzen denean, 200 lerroko `"expected A, got B"` lehor batek zein lerro zehatz aldatu den bilatzen begiak uztera behartzen zaitu.

**`diff`** lib-ak **Azpisekuentzia Komun Luzeena (LCS)** kalkulatzen du 2D `Tensor[Int]` baten gainean edizio minimoak (`DiffKeep`, `DiffAdd`, `DiffDel`), edizio-distantzia, estatistikak, **Unified Diff** formatua eta `diff apply` bidezko berreraikuntza zehatza sortzeko.

Ekosistema tradizional batean, **`DIFF`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`diff`** lib-ak (`src/main/ridgun/lib/diff.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Funtzio osoak eta kontratu esplizituak (`=>`)**: `diff`-eko funtzio bakar batek ere ez du ezkutuko salbuespenik jaurtitzen, ezta `null` erabiltzen ere. Muga-kasu orok dokumentatutako balio bat edo batura-mota aljebraiko bat (`Option`, `Result`) itzultzen du.
2. **Zero C kode eta zero `libc`**: `diff`-eko kode guztia zuzenean ELF64 makina-kode natibora konpilatzen da, `ridgunc`-ek egiaztatuta.
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `diff`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 13.2. Artefaktu natiboak, inportazioa eta `diff` APIaren katalogo osoa

`ridgun-libs`-en, **`diff`** lehen mailako **lib** bat da, `src/main/ridgun/lib/diff.rg` bidean kokatua (`DIFF` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/diff.rglib` | Banaketa eta inportazio zuzena `import diff` bidez |
| **Fitxategi konpilatua** | `target/diff.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libdiff.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import diff` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

### 13.2.1. `diff`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `type DiffOp` | `DiffKeep String | DiffDel String | DiffAdd String` |
| `diff lines / diff text` | `[String]` zerrenden edo lerro anitzeko testuen arteko LCS edizio-gidoi minimoa kalkulatzen du |
| `diff edit distance / diff stats` | Txertaketa+ezabaketa distantzia minimoa eta `(kept, added, deleted)` zenbaketa |
| `diff format / diff unified` | `+ / - /  ` lerro trinkoak edo goiburudun Unified Diff estandarra errenderizatzen ditu |
| `diff apply / diff apply text` | Helburuko dokumentua galerarik gabe berreraikitzen du edizio-gidoitik abiatuta |

### 13.2.2. `src/main/ridgun/lib/diff.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/diff.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`2` mota, `0` eragile eta `33` funtzio):

**`diff`-eko mota aljebraikoak eta erregistroak (`type`):**

```ridgun
type DiffEdit = diff_op: String, line_text: String, old_line_no: Int, new_line_no: Int
type DiffStats = equal_count: Int, insert_count: Int, delete_count: Int
```

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
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

## 13.3. `diff` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `diff` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test diff.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 13.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `diff` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `diff` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import diff

fn :: auditar cambio (antes : String) (despues : String) => (Int, String)
      auditar cambio antes despues =
        dist   = diff edit distance ( ["host=localhost", "port=8080"] ) ( ["host=0.0.0.0", "port=8080"] )
        parche = diff unified "config.old" "config.new" antes despues
        (dist, parche)
```

### 13.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`diff` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import diff

fn :: verificar parche (orig : [String]) (nuevo : [String]) => [String]
      verificar parche orig nuevo =
        ops = diff lines orig nuevo
        diff apply ops
```

### 13.3.3. 3. adibidea: Testu huts eta berdinen konparazioa: zero edizio-distantzia eta inbarianteen egiaztapena

Adibide praktiko honetan `diff` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_diff_empty_and_identical => ()
      test_diff_empty_and_identical =
        nl = char_from_code 10
        e_empty = diff text "" ""
        _ = assert int equals (count_edits e_empty) 0 "AC1: empty diff edit count"
        _ = assert false (diff has changes e_empty) "AC1: empty diff has no changes"
        _ = assert int equals (diff edit distance "" "") 0 "AC1: empty edit distance"
        _ = assert str eq (diff apply e_empty) "" "AC3: empty diff apply"
        same_doc = "alpha" + nl + "beta" + nl + "gamma"
        e_same = diff text same_doc same_doc
        _ = assert int equals (count_edits e_same) 3 "AC1: identical 3-line count"
        _ = assert false (diff has changes e_same) "AC1: identical has no changes"
        st_same = diff stats e_same
        _ = assert int equals (equal_count st_same) 3 "AC1: equal_count == 3"
        _ = assert int equals (insert_count st_same) 0 "AC1: insert_count == 0"
        _ = assert int equals (delete_count st_same) 0 "AC1: delete_count == 0"
        _ = assert int equals (diff edit distance same_doc same_doc) 0 "AC1: identical edit distance == 0"
        _ = assert str eq (diff apply e_same) same_doc "AC3: identical diff apply"
        ()
```

### 13.3.4. 4. adibidea: Txertaketa hutsak (`DiffInsert`), ezabaketa hutsak (`DiffDelete`) eta aurrerantz aplikatzea (`diff patch`)

Adibide praktiko honetan `diff` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_diff_pure_insert_and_delete => ()
      test_diff_pure_insert_and_delete =
        nl = char_from_code 10
        target = "line1" + nl + "line2" + nl + "line3"
        e_ins = diff text "" target
        _ = assert true (diff has changes e_ins) "AC1: pure insert has changes"
        st_ins = diff stats e_ins
        _ = assert int equals (equal_count st_ins) 0 "AC1: pure insert equal_count"
        _ = assert int equals (insert_count st_ins) 3 "AC1: pure insert insert_count"
        _ = assert int equals (delete_count st_ins) 0 "AC1: pure insert delete_count"
        _ = assert int equals (diff edit distance "" target) 3 "AC1: pure insert edit distance"
        _ = assert str eq (diff apply e_ins) target "AC3: pure insert apply"
        ins0 = nth_edit e_ins 0
        ins2 = nth_edit e_ins 2
        _ = assert str eq (diff_op ins0) "insert" "AC1: ins0 op"
        _ = assert int equals (old_line_no ins0) 0 "AC1: ins0 old_line_no"
        _ = assert int equals (new_line_no ins0) 1 "AC1: ins0 new_line_no"
        _ = assert int equals (new_line_no ins2) 3 "AC1: ins2 new_line_no"
        e_del = diff text target ""
        _ = assert true (diff has changes e_del) "AC1: pure delete has changes"
        st_del = diff stats e_del
        _ = assert int equals (equal_count st_del) 0 "AC1: pure delete equal_count"
        _ = assert int equals (insert_count st_del) 0 "AC1: pure delete insert_count"
        _ = assert int equals (delete_count st_del) 3 "AC1: pure delete delete_count"
        _ = assert int equals (diff edit distance target "") 3 "AC1: pure delete edit distance"
        _ = assert str eq (diff apply e_del) "" "AC3: pure delete apply"
        del0 = nth_edit e_del 0
        del2 = nth_edit e_del 2
        _ = assert str eq (diff_op del0) "delete" "AC1: del0 op"
        _ = assert int equals (old_line_no del0) 1 "AC1: del0 old_line_no"
        _ = assert int equals (new_line_no del0) 0 "AC1: del0 new_line_no"
        _ = assert int equals (old_line_no del2) 3 "AC1: del2 old_line_no"
        ()
```

### 13.3.5. 5. adibidea: Eugene Myersen bektore klasikoa (`ABCABBA` $\rightarrow$ `CBABAC`): azpisekuentzia komun luzeena (LCS) eta distantzia minimoa

Adibide praktiko honetan `diff` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_diff_myers_classic_vector => ()
      test_diff_myers_classic_vector =
        nl = char_from_code 10
        old_lines = ["A", "B", "C", "A", "B", "B", "A"]
        new_lines = ["C", "B", "A", "B", "A", "C"]
        edits = diff lines old_lines new_lines
        st = diff stats edits
        _ = assert int equals (equal_count st) 4 "AC1: Myers LCS length 4"
        _ = assert int equals (delete_count st) 3 "AC1: Myers delete count 3"
        _ = assert int equals (insert_count st) 2 "AC1: Myers insert count 2"
        old_s = "A" + nl + "B" + nl + "C" + nl + "A" + nl + "B" + nl + "B" + nl + "A"
        new_s = "C" + nl + "B" + nl + "A" + nl + "B" + nl + "A" + nl + "C"
        _ = assert int equals (diff edit distance old_s new_s) 5 "AC1: Myers edit distance 5"
        _ = assert str eq (diff apply edits) new_s "AC3: Myers apply reproduces CBABAC"
        ()
```

### 13.3.6. 6. adibidea: Jatorrizko eta helburuko lerro-zenbakien ikuskapena (`diff old line`, `diff new line`) eta berreraikuntza zehatza `diff patch` bidez

Adibide praktiko honetan `diff` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_diff_code_hunks_and_line_numbers => ()
      test_diff_code_hunks_and_line_numbers =
        nl = char_from_code 10
        old_code = "fn :: add Int Int => Int" + nl + "      add a b = a + b" + nl + "" + nl + "fn :: sub Int Int => Int" + nl + "      sub a b = a - b"
        new_code = "fn :: add Int Int => Int" + nl + "      add x y = x + y" + nl + "" + nl + "fn :: mul Int Int => Int" + nl + "      mul a b = a * b" + nl + "" + nl + "fn :: sub Int Int => Int" + nl + "      sub a b = a - b"
        edits = diff text old_code new_code
        _ = assert true (diff has changes edits) "AC1: code refactoring has changes"
        _ = assert str eq (diff apply edits) new_code "AC3: code refactoring lossless apply"
        e0 = nth_edit edits 0
        _ = assert str eq (diff_op e0) "equal" "AC1: line 1 equal"
        _ = assert int equals (old_line_no e0) 1 "AC1: line 1 old_line_no"
        _ = assert int equals (new_line_no e0) 1 "AC1: line 1 new_line_no"
        e1 = nth_edit edits 1
        _ = assert str eq (diff_op e1) "delete" "AC1: line 2 deleted"
        _ = assert str eq (line_text e1) "      add a b = a + b" "AC1: deleted line text"
        _ = assert int equals (old_line_no e1) 2 "AC1: deleted old_line_no"
        _ = assert int equals (new_line_no e1) 0 "AC1: deleted new_line_no"
        e2 = nth_edit edits 2
        _ = assert str eq (diff_op e2) "insert" "AC1: line 2 inserted"
        _ = assert str eq (line_text e2) "      add x y = x + y" "AC1: inserted line text"
        _ = assert int equals (old_line_no e2) 0 "AC1: inserted old_line_no"
        _ = assert int equals (new_line_no e2) 2 "AC1: inserted new_line_no"
        ()
```

### 13.3.7. 7. adibidea: GNU estiloko adabaki bateratuen sorrera (`--- old`, `+++ new`, `-`, `+`, ` `) `diff unified` bidez eta `(kept, deleted, inserted)` estatistikak

Adibide praktiko honetan `diff` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_diff_unified_formatting => ()
      test_diff_unified_formatting =
        nl = char_from_code 10
        old_s = "one" + nl + "two" + nl + "three"
        new_s = "one" + nl + "TWO" + nl + "three" + nl + "four"
        uni = diff unified "a/sample.txt" "b/sample.txt" old_s new_s
        expected = "--- a/sample.txt" + nl + "+++ b/sample.txt" + nl + "@@ -1,3 +1,4 @@" + nl + " one" + nl + "-two" + nl + "+TWO" + nl + " three" + nl + "+four" + nl
        _ = assert str eq uni expected "AC2: unified diff output matches standard header and hunk format"
        uni_empty = diff unified "a/empty" "b/empty" "" ""
        _ = assert str eq uni_empty ("--- a/empty" + nl + "+++ b/empty" + nl + "@@ -0,0 +0,0 @@" + nl) "AC2: unified diff empty files"
        ()
```

### 13.3.8. 8. adibidea: Errepikatutako lerroak eta bloke bikoiztuak dituzten fitxategien aurreko sendotasuna

Adibide praktiko honetan `diff` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_diff_repetitive_lines => ()
      test_diff_repetitive_lines =
        nl = char_from_code 10
        old_rep = "x" + nl + "x" + nl + "y" + nl + "x" + nl + "x"
        new_rep = "x" + nl + "y" + nl + "y" + nl + "x"
        edits = diff text old_rep new_rep
        st = diff stats edits
        _ = assert int equals (equal_count st) 3 "AC1: repetitive LCS equal_count"
        _ = assert int equals (delete_count st) 2 "AC1: repetitive LCS delete_count"
        _ = assert int equals (insert_count st) 1 "AC1: repetitive LCS insert_count"
        _ = assert str eq (diff apply edits) new_rep "AC3: repetitive lines apply"
        ()
```

---

## 13.4. Kaputaren azpian: nola dagoen eraikia `diff` Ridgun hutsean (`src/main/ridgun/lib/diff.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/diff.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 13.4.1. Barne-inplementazioa: Internal Helpers

Ikusi nola `diff.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: df_max Int Int => Int
      df_max a   b
        | a >= b = a
        | otherwise = b

fn :: df_int_to_str_pos Int => String
      df_int_to_str_pos n
        | n == 0 = ""
        | otherwise = (df_int_to_str_pos (n / 10)) + (char_from_code ((n % 10) + 48))

fn :: df_int_to_str Int => String
      df_int_to_str n
        | n == 0 = "0"
        | n < 0 = "-" + (df_int_to_str_pos (0 - n))
        | otherwise = df_int_to_str_pos n

fn :: df_rev [String] [String] => [String]
      df_rev []       acc      =  acc
      df_rev (x:xs)   acc      =  df_rev xs ([x] :: acc)

fn :: df_rev_ints [Int]  [Int] => [Int]
      df_rev_ints []     acc   =  acc
      df_rev_ints (x:xs) acc   =  df_rev_ints xs ([x] :: acc)

fn :: df_split_lines_loop String Int Int Int [String] => [String]
      df_split_lines_loop s idx n start acc
        | idx >= n = df_rev ([str_slice s start n] :: acc) []
        | (str_char_at s idx) == 10 = df_split_lines_loop s (idx + 1) n (idx + 1) ([str_slice s start idx] :: acc)
        | otherwise = df_split_lines_loop s (idx + 1) n start acc

fn :: df_split_lines String => [String]
      df_split_lines s
        | (str_len s) == 0 = []
        | otherwise = df_split_lines_loop s 0 (str_len s) 0 []

fn :: df_zeros Int [Int] => [Int]
      df_zeros n   acc
        | n <= 0 = acc
        | otherwise = df_zeros (n - 1) ([0] :: acc)

fn :: df_nth_int [Int]  Int => Int
      df_nth_int []     _   =  0
      df_nth_int (x:xs) idx
        | idx <= 0 = x
        | otherwise = df_nth_int xs (idx - 1)

fn :: df_head_int [Int] => Int
      df_head_int []    =  0
      df_head_int (x:_) =  x
```

### 13.4.2. Barne-inplementazioa: Public API

Ikusi nola `diff.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: diff lines [String]  [String]  => [DiffEdit]
      diff lines old_lines new_lines =
        rev_old = df_rev old_lines []
        rev_new = df_rev new_lines []
        zero_row = df_zeros ((df_list_length new_lines) + 1) []
        dp_rows = df_build_dp rev_old rev_new [zero_row]
        df_backtrack old_lines new_lines dp_rows 0 1 1 []

fn :: diff text String String => [DiffEdit]
      diff text old_s  new_s  =  diff lines (df_split_lines old_s) (df_split_lines new_s)

fn :: df_stats_loop [DiffEdit] Int Int Int => DiffStats
      df_stats_loop []         eq  ins del =  DiffStats eq ins del
      df_stats_loop (e:es)     eq  ins del
        | (diff_op e) == "equal" = df_stats_loop es (eq + 1) ins del
        | (diff_op e) == "insert" = df_stats_loop es eq (ins + 1) del
        | otherwise = df_stats_loop es eq ins (del + 1)

fn :: diff stats [DiffEdit] => DiffStats
      diff stats edits      =  df_stats_loop edits 0 0 0

fn :: diff edit distance String String => Int
      diff edit distance old_s  new_s  =
        st = diff stats (diff text old_s new_s)
        (insert_count st) + (delete_count st)

fn :: diff has changes [DiffEdit] => Bool
      diff has changes []         =  False
      diff has changes (e:es)
        | (diff_op e) == "equal" = diff has changes es
        | otherwise = True

fn :: df_format_unified_lines [DiffEdit] String => String
      df_format_unified_lines []         acc    =  acc
      df_format_unified_lines (e:es)     acc
        | (diff_op e) == "equal" = df_format_unified_lines es (acc + " " + (line_text e) + (char_from_code 10))
        | (diff_op e) == "delete" = df_format_unified_lines es (acc + "-" + (line_text e) + (char_from_code 10))
        | otherwise = df_format_unified_lines es (acc + "+" + (line_text e) + (char_from_code 10))

fn :: df_hunk_start Int => Int
      df_hunk_start cnt
        | cnt == 0 = 0
        | otherwise = 1

fn :: df_unified_header String    String    Int     Int     => String
      df_unified_header old_label new_label old_cnt new_cnt =
        old_start = df_hunk_start old_cnt
        new_start = df_hunk_start new_cnt
        nl = char_from_code 10
        "--- " + old_label + nl + "+++ " + new_label + nl + "@@ -" + (df_int_to_str old_start) + "," + (df_int_to_str old_cnt) + " +" + (df_int_to_str new_start) + "," + (df_int_to_str new_cnt) + " @@" + nl
```

---

## 13.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `diff`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: $diff\_edit\_distance(a, b) == |a| + |b| - 2 \cdot LCS(a, b)$ identitate matematiko bermatua eta galerarik gabeko berreraikuntza: `diff apply (diff lines a b) == b`.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/diff.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test diff.rg` suite automatizatuaren bidez.

### `diff`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import diff` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `diff`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `diff`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `diff` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**14. kapituluan** **`template`** lib-a sakonki esploratuko dugu (`template` lib-a — HTML eta LaTeX Auto-ihesa duten Mustache Txantiloi Seguruak).
