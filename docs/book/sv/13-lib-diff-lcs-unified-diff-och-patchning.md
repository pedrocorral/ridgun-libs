# Kapitel 13: Lib:en `diff` — LCS-raddiff, Redigeringsavstånd, Unified Diff och Patchning

## 13.1. Varför finns lib:en `diff`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `diff`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `diff`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: när ett test fallerar eller en konfigurationsfil ändras tvingar en rå 200-raders `"expected A, got B"`-utskrift dig att kisa mot skärmen för att hitta exakt vilken rad som ändrats.

Lib:en **`diff`** beräknar **Longest Common Subsequence (LCS)** över en 2D `Tensor[Int]`-tabell för att skapa minimala redigeringssekvenser (`DiffKeep`, `DiffAdd`, `DiffDel`), redigeringsavstånd, **Unified Diff** (`---`/`+++`/`@@`) och förlustfri patchning (`diff apply`).

I ett traditionellt ekosystem innebär uppgifter inom domänen **`DIFF`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`diff`** (`src/main/ridgun/lib/diff.rg`) problemet genom fyra kompromisslösa principer:

1. **Totala funktioner och explicita kontrakt (`=>`)**: ingen funktion i `diff` kastar dolda undantag eller förlitar sig på `null`. Varje gränsfall returnerar ett dokumenterat sentinelvärde eller en algebraisk summatyp (`Option`, `Result`).
2. **Noll C-kod och noll `libc`**: varje rad i `diff` kompileras direkt till inbyggd ELF64-maskinkod verifierad av `ridgunc`.
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `diff` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 13.2. Inbyggda artefakter, import och komplett API-katalog för `diff`

I `ridgun-libs` är **`diff`** en förstklassig **lib** placerad i `src/main/ridgun/lib/diff.rg` (domän `DIFF`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/diff.rglib` | Portabel distribution och direkt import med `import diff` |
| **Kompilerat arkiv** | `target/diff.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libdiff.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import diff` överst och anropar funktionerna med mellanslag eller understreck.

### 13.2.1. Översikt över funktionella familjer i `diff`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `type DiffOp` | `DiffKeep String | DiffDel String | DiffAdd String` |
| `diff lines / diff text` | Beräknar minimalt LCS-redigeringsskript mellan `[String]`-listor eller flerradiga texter |
| `diff edit distance / diff stats` | Minimalt insättnings-/borttagningsavstånd och `(kept, added, deleted)`-antal |
| `diff format / diff unified` | Renderar kompakta `+ / - /  `-rader eller standard Unified Diff med rubriker |
| `diff apply / diff apply text` | Återskapar måldokumentet förlustfritt från ett redigeringsskript |

### 13.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/diff.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/diff.rg` (`2` typer, `0` operatorer och `33` funktioner):

**Algebraiska datatyper och poster (`type`) i `diff`:**

```ridgun
type DiffEdit = diff_op: String, line_text: String, old_line_no: Int, new_line_no: Int
type DiffStats = equal_count: Int, insert_count: Int, delete_count: Int
```

| # | Funktion / Signatur (`fn ::`) | Returtyp |
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

## 13.3. Djupdykning i `diff`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `diff` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test diff.rg`.

### 13.3.1. Exempel 1: Huvudflöde i tabellform med `diff`

Lägg märke till hur `=`-tecknen och transformationsstegen med `diff` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import diff

fn :: auditar cambio (antes : String) (despues : String) => (Int, String)
      auditar cambio antes despues =
        dist   = diff edit distance ( ["host=localhost", "port=8080"] ) ( ["host=0.0.0.0", "port=8080"] )
        parche = diff unified "config.old" "config.new" antes despues
        (dist, parche)
```

### 13.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `diff` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import diff

fn :: verificar parche (orig : [String]) (nuevo : [String]) => [String]
      verificar parche orig nuevo =
        ops = diff lines orig nuevo
        diff apply ops
```

### 13.3.3. Exempel 3: Jämförelse av tomma och identiska texter: noll redigeringsavstånd och invariantverifiering

I detta praktiska exempel undersöker vi grundligt hur `diff` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 13.3.4. Exempel 4: Rena infogningar (`DiffInsert`), rena borttagningar (`DiffDelete`) och framåtpatchning (`diff patch`)

I detta praktiska exempel undersöker vi grundligt hur `diff` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 13.3.5. Exempel 5: Eugene Myers klassiska vektor (`ABCABBA` $\rightarrow$ `CBABAC`): längsta gemensamma delsekvens (LCS) och minimalt redigeringsavstånd

I detta praktiska exempel undersöker vi grundligt hur `diff` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 13.3.6. Exempel 6: Inspektion av käll- och målradnummer (`diff old line`, `diff new line`) och exakt rekonstruktion med `diff patch`

I detta praktiska exempel undersöker vi grundligt hur `diff` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 13.3.7. Exempel 7: GNU-liknande unified diff-formatering (`--- old`, `+++ new`, `-`, `+`, ` `) med `diff unified` och `(kept, deleted, inserted)`-statistik

I detta praktiska exempel undersöker vi grundligt hur `diff` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 13.3.8. Exempel 8: Robusthet vid filer med upprepade rader och duplicerade kodblock

I detta praktiska exempel undersöker vi grundligt hur `diff` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

## 13.4. Under huven: hur `diff` är byggd i ren Ridgun (`src/main/ridgun/lib/diff.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/diff.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 13.4.1. Intern implementation: Internal Helpers

Se hur `diff.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

### 13.4.2. Intern implementation: Public API

Se hur `diff.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

## 13.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `diff`

- **Algoritmisk garanti och säkerhet**: Garanterad matematisk identitet $diff\_edit\_distance(a, b) == |a| + |b| - 2 \cdot LCS(a, b)$ och förlustfri rekonstruktion `diff apply (diff lines a b) == b`.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/diff.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test diff.rg`.

### De 5 Gyllene Reglerna när du programmerar med `diff`

1. **Deklarera `import diff` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `diff`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `diff`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `diff` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 14** går vi vidare och utforskar lib:en **`template`** på djupet (Lib:en `template` — Säkra Mustache-mallar med Automatisk HTML- och LaTeX-kodning).
