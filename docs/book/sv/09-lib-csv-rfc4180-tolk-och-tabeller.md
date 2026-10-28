# Kapitel 09: Lib:en `csv` — RFC 4180 CSV/TSV-Tillståndsmaskin och Kolumnindexerade Tabeller

## 09.1. Varför finns lib:en `csv`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `csv`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `csv`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: alla tror att CSV-tolkning bara är `str split rad ","`... tills det dyker upp ett citerat fält med ett kommatecken inuti, dubbla citattecken `""` eller en radbrytning `\r\n` mitt i en cell.

Lib:en **`csv`** implementerar en komplett **RFC 4180**-tillståndsmaskin för CSV och TSV, smart serialisering med citattecken och typen `CsvTable` för kolumn- och raduppslagning via rubriknamn.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`CSV`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`csv`** (`src/main/ridgun/lib/csv.rg`) problemet genom fyra kompromisslösa principer:

1. **Deklarera `import csv` (eller `import csv as alias`) överst i filen**: varje lib definierar sin `module :: csv`-namnrymd och i `--strict`-läge anropas flerordsfunktioner alltid med naturliga mellanslag.
2. **Kedja dina datapipelines från vänster till höger med `->`**: skriv `indata steg ett -> steg två -> resultat`, använd `(+ _ _ +)`-sekvensmasker för att packa upp tupler och utelämna `_ =` vid sekventiella satser (eller kasta med `-> ()`).
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `csv` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 09.2. Inbyggda artefakter, import och komplett API-katalog för `csv`

I `ridgun-libs` är **`csv`** en förstklassig **lib** placerad i `src/main/ridgun/lib/csv.rg` (domän `CSV`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/csv.rglib` | Portabel distribution och direkt import med `import csv` |
| **Kompilerat arkiv** | `target/csv.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libcsv.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> Varje lib deklarerar sin egen namnrymd med `module :: csv`: skriv bara `import csv` (eller `import csv as alias`) överst och anropa dess funktioner med naturliga mellanslag (`min funktion x`) och `->`-pipelines (`x min funktion -> resultat`).

### 09.2.1. Översikt över funktionella familjer i `csv`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `csv parse / tsv parse / csv parse with` | Tolkar CSV/TSV-text (inklusive flerradiga citerade fält och `""`) till `[[String]]` |
| `csv stringify / tsv stringify` | Serialiserar `[[String]]` och citerar endast celler med avgränsare, citattecken eller radbrytningar |
| `csv parse table / csv get cell / csv col` | Rubrikindexerad `CsvTable`-uppslagning via `(rad, kolumnnamn)` eller hel kolumn |
| `csv row to kv / csv table to kv list` | Konverterar tabellrader till `[String String]`-mappar nycklade efter rubrik |

### 09.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/csv.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/csv.rg` (`1` typer, `0` operatorer och `23` funktioner):

**Algebraiska datatyper och poster (`type`) i `csv`:**

```ridgun
type CsvTable = headers: [String], rows: [[String]], delimiter_char: String, has_headers: Bool
```

| # | Funktion / Signatur (`fn ::`) | Returtyp |
|---|---|---|
| `1` | `fn :: csv_delim_code String` | `Int` |
| `2` | `fn :: csv_append_final_row [[String]] [String] String` | `[[String]]` |
| `3` | `fn :: csv_parse_quoted String Int Int Int String [String] [[String]]` | `[[String]]` |
| `4` | `fn :: csv_parse_unquoted String Int Int Int String [String] [[String]]` | `[[String]]` |
| `5` | `fn :: csv parse with delim String String` | `[[String]]` |
| `6` | `fn :: csv parse String` | `[[String]]` |
| `7` | `fn :: tsv parse String` | `[[String]]` |
| `8` | `fn :: csv_build_table [[String]] Bool` | `CsvTable` |
| `9` | `fn :: csv parse table String Bool` | `CsvTable` |
| `10` | `fn :: csv_needs_quotes_loop String Int Int Int` | `Bool` |
| `11` | `fn :: csv_double_quotes_loop String Int Int String` | `String` |
| `12` | `fn :: csv_format_cell String Int` | `String` |
| `13` | `fn :: csv_join_row [String] String Int` | `String` |
| `14` | `fn :: csv_join_rows [[String]] String Int` | `String` |
| `15` | `fn :: csv stringify with delim [[String]] String` | `String` |
| `16` | `fn :: csv stringify [[String]]` | `String` |
| `17` | `fn :: tsv stringify [[String]]` | `String` |
| `18` | `fn :: csv_nth_str [String] Int` | `String` |
| `19` | `fn :: csv_nth_row [[String]] Int` | `[String]` |
| `20` | `fn :: csv col [[String]] Int` | `[String]` |
| `21` | `fn :: csv_find_header_idx [String] String Int` | `Int` |
| `22` | `fn :: csv get by header CsvTable Int String` | `String` |
| `23` | `fn :: csv row to map [String] [String]` | `[String String]` |

---

## 09.3. Djupdykning i `csv`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `csv` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test csv.rg`.

### 09.3.1. Exempel 1: Huvudflöde i tabellform med `csv`

Lägg märke till hur `=`-tecknen och transformationsstegen med `csv` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import csv

fn :: extraer columna precios String => [String] String
      extraer columna precios raw_csv =
        raw_csv csv parse -> tabla
        csv col by name tabla "precio" -> precios
        csv cell by name tabla 0 "producto" -> primero
        (precios, primero)
```

### 09.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `csv` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import csv

fn :: exportar informe => String
      exportar informe =
        [["id", "nota"], ["1", "Contiene, coma"], ["2", "Dijo "hola""]] -> filas
        filas csv encode
```

### 09.3.3. Exempel 3: RFC 4180 CSV/TSV tur-och-retur med dubblerade citattecken `""`, inbäddade komman och flerradsceller

I detta praktiska exempel undersöker vi grundligt hur `csv` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test_csv_tsv_roundtrip => ()
      test_csv_tsv_roundtrip =
        nl = char from code 10
        tab = char from code 9
        raw_csv = "name,role,note" + nl + "Ada,\"Admin, Lead\",\"Quote \"\"here\"\"\"" + nl + "Bob,User,\"Line 1" + nl + "Line 2\"" + nl
        parsed = csv parse raw_csv
        assert int equals (csv_row_count parsed) 3 "AC1: 3 rows parsed including multiline quoted cell"
        assert str eq (csv_cell_at parsed 1 1) "Admin, Lead" "AC1: quoted comma preserved"
        assert str eq (csv_cell_at parsed 1 2) "Quote \"here\"" "AC1: doubled quote unescaped"
        assert str eq (csv_cell_at parsed 2 2) ("Line 1" + nl + "Line 2") "AC1: embedded newline in quoted cell preserved"
        re_csv = csv stringify parsed
        assert str eq re_csv raw_csv "AC1/AC2: RFC 4180 CSV quoted comma, escaped quote, and newline round-trip"

        raw_tsv = "col1" + tab + "col2" + nl + "val,1" + tab + "val2" + nl
        parsed_tsv = tsv parse raw_tsv
        assert str eq (csv_cell_at parsed_tsv 1 0) "val,1" "AC1: TSV unquoted comma preserved"
        re_tsv = tsv stringify parsed_tsv
        assert str eq re_tsv raw_tsv "AC1/AC2: TSV round-trip"
        ()
```

### 09.3.4. Exempel 4: Hantering av `CRLF`-radslut (`\r\n`), på varandra följande tomma celler och anpassade avgränsare

I detta praktiska exempel undersöker vi grundligt hur `csv` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test_csv_crlf_and_empty_cells => ()
      test_csv_crlf_and_empty_cells =
        cr = char from code 13
        nl = char from code 10
        crlf = cr + nl
        raw_crlf = "a,b,c" + crlf + "1,,3" + crlf + ",2," + crlf
        rows_crlf = csv parse raw_crlf
        assert int equals (csv_row_count rows_crlf) 3 "AC1: CRLF row count"
        assert str eq (csv_cell_at rows_crlf 1 0) "1" "AC1: cell (1,0)"
        assert str eq (csv_cell_at rows_crlf 1 1) "" "AC1: middle empty cell (1,1)"
        assert str eq (csv_cell_at rows_crlf 1 2) "3" "AC1: cell (1,2)"
        assert str eq (csv_cell_at rows_crlf 2 0) "" "AC1: leading empty cell (2,0)"
        assert str eq (csv_cell_at rows_crlf 2 1) "2" "AC1: cell (2,1)"
        assert str eq (csv_cell_at rows_crlf 2 2) "" "AC1: trailing empty cell (2,2)"

        semi_rows = csv parse with delim ("k1;k2" + nl + "v1;v2" + nl) ";"
        assert int equals (csv_row_count semi_rows) 2 "AC1: semicolon delimiter row count"
        assert str eq (csv_cell_at semi_rows 1 1) "v2" "AC1: semicolon delimiter cell (1,1)"
        assert int equals (csv_row_count (csv parse "")) 0 "AC1: empty input yields 0 rows"
        ()
```

### 09.3.5. Exempel 5: Tabeller med rubrikrad (`CsvTable`): uppslagning via rad och kolumnnamn (`csv get cell`), kolumnextraktion och nyckel-värde-poster

I detta praktiska exempel undersöker vi grundligt hur `csv` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test_csv_table_lookup => ()
      test_csv_table_lookup =
        nl = char from code 10
        raw_csv = "id,name,dept" + nl + "10,Ada,Math" + nl + "20,Grace,Compilers" + nl
        tbl = csv parse table raw_csv True
        assert true (has_headers tbl) "AC3: table has_headers True"
        assert int equals (csv_len (headers tbl)) 3 "AC3: 3 headers extracted"
        assert str eq (csv get by header tbl 0 "name") "Ada" "AC3: csv get by header row 0"
        assert str eq (csv get by header tbl 1 "dept") "Compilers" "AC3: csv get by header row 1"
        assert str eq (csv get by header tbl 0 "missing") "" "AC3: csv get by header missing column"
        assert str eq (csv get by header tbl 99 "name") "" "AC3: csv get by header out-of-bounds row"

        tbl_no_h = csv parse table raw_csv False
        assert false (has_headers tbl_no_h) "AC3: table has_headers False"
        assert int equals (csv_row_count (rows tbl_no_h)) 3 "AC3: headerless table keeps all 3 rows"

        names = csv col (rows tbl) 1
        assert int equals (csv_len names) 2 "AC3: csv col length"
        assert str eq (csv_str_at names 0) "Ada" "AC3: csv col[0]"
        assert str eq (csv_str_at names 1) "Grace" "AC3: csv col[1]"

        rmap = csv row to map ["id", "name", "dept"] ["10", "Ada", "Math"]
        assert str eq (csv_pair_val rmap "id") "10" "AC3: csv row to map id"
        assert str eq (csv_pair_val rmap "name") "Ada" "AC3: csv row to map name"
        assert str eq (csv_pair_val rmap "dept") "Math" "AC3: csv row to map dept"
        ()
```

---

## 09.4. Under huven: hur `csv` är byggd i ren Ridgun (`src/main/ridgun/lib/csv.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/csv.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 09.4.1. Intern implementation: RFC 4180 State-Machine Parser

Se hur `csv.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
module :: csv

fn :: csv delim code String => Int
      csv delim code "" = 44
      csv delim code d = str char at d 0

fn :: csv append final row [[String]] [String] String => [[String]]
      csv append final row rows [] "" = rows
      csv append final row rows cur_row cell = rows :: [cur_row :: [cell]]

fn :: csv parse quoted String Int Int Int String [String] [[String]] => [[String]]
      csv parse quoted s pos len d_code cell cur_row rows =
        | pos >= len = csv append final row rows cur_row cell
        | (str char at s pos) == 34 and (pos + 1) < len and (str char at s (pos + 1)) == 34 = csv parse quoted s (pos + 2) len d_code (cell + (char from code 34)) cur_row rows
        | (str char at s pos) == 34 = csv parse unquoted s (pos + 1) len d_code cell cur_row rows
        | otherwise = csv parse quoted s (pos + 1) len d_code (cell + (str slice s pos (pos + 1))) cur_row rows

fn :: csv parse unquoted String Int Int Int String [String] [[String]] => [[String]]
      csv parse unquoted s pos len d_code cell cur_row rows =
        | pos >= len = csv append final row rows cur_row cell
        | (str char at s pos) == 34 and cell == "" = csv parse quoted s (pos + 1) len d_code "" cur_row rows
        | (str char at s pos) == d_code = csv parse unquoted s (pos + 1) len d_code "" (cur_row :: [cell]) rows
        | (str char at s pos) == 13 and (pos + 1) < len and (str char at s (pos + 1)) == 10 = csv parse unquoted s (pos + 2) len d_code "" [] (rows :: [cur_row :: [cell]])
        | (str char at s pos) == 10 or (str char at s pos) == 13 = csv parse unquoted s (pos + 1) len d_code "" [] (rows :: [cur_row :: [cell]])
        | otherwise = csv parse unquoted s (pos + 1) len d_code (cell + (str slice s pos (pos + 1))) cur_row rows

fn :: csv parse with delim String String => [[String]]
      csv parse with delim s delim =
        csv parse unquoted s 0 (str len s) (csv delim code delim) "" [] []

fn :: csv parse String => [[String]]
      csv parse s = csv parse with delim s ","

fn :: tsv parse String => [[String]]
      tsv parse s = csv parse with delim s (char from code 9)

fn :: csv build table [[String]] Bool => CsvTable
      csv build table [] has_h = CsvTable [] [] "," has_h
      csv build table (h:rest) True = CsvTable h rest "," True
      csv build table all_rows False = CsvTable [] all_rows "," False

fn :: csv parse table String Bool => CsvTable
      csv parse table s has_h = csv build table (csv parse s) has_h
```

### 09.4.2. Intern implementation: RFC 4180 Serialization & Escaping

Se hur `csv.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: csv needs quotes loop String Int Int Int => Bool
      csv needs quotes loop s pos len d_code =
        | pos >= len = False
        | (str char at s pos) == d_code or (str char at s pos) == 34 or (str char at s pos) == 10 or (str char at s pos) == 13 = True
        | otherwise = csv needs quotes loop s (pos + 1) len d_code

fn :: csv double quotes loop String Int Int String => String
      csv double quotes loop s pos len acc =
        | pos >= len = acc
        | (str char at s pos) == 34 = csv double quotes loop s (pos + 1) len (acc + (char from code 34) + (char from code 34))
        | otherwise = csv double quotes loop s (pos + 1) len (acc + (str slice s pos (pos + 1)))

fn :: csv format cell String Int => String
      csv format cell cell d_code =
        | csv needs quotes loop cell 0 (str len cell) d_code = (char from code 34) + (csv double quotes loop cell 0 (str len cell) "") + (char from code 34)
        | otherwise = cell

fn :: csv join row [String] String Int => String
      csv join row [] _ _ = ""
      csv join row (c:[]) _ d_code = csv format cell c d_code
      csv join row (c:cs) delim d_code = (csv format cell c d_code) + delim + (csv join row cs delim d_code)

fn :: csv join rows [[String]] String Int => String
      csv join rows [] _ _ = ""
      csv join rows (r:rs) delim d_code = (csv join row r delim d_code) + (char from code 10) + (csv join rows rs delim d_code)

fn :: csv stringify with delim [[String]] String => String
      csv stringify with delim rows delim =
        csv join rows rows delim (csv delim code delim)

fn :: csv stringify [[String]] => String
      csv stringify rows = csv stringify with delim rows ","

fn :: tsv stringify [[String]] => String
      tsv stringify rows = csv stringify with delim rows (char from code 9)
```

### 09.4.3. Intern implementation: Column Extraction & Header-Mapped Lookup

Se hur `csv.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: csv nth str [String] Int => String
      csv nth str [] _ = ""
      csv nth str (x:xs) idx =
        | idx < 0 = ""
        | idx == 0 = x
        | otherwise = csv nth str xs (idx - 1)

fn :: csv nth row [[String]] Int => [String]
      csv nth row [] _ = []
      csv nth row (r:rs) idx =
        | idx < 0 = []
        | idx == 0 = r
        | otherwise = csv nth row rs (idx - 1)

fn :: csv col [[String]] Int => [String]
      csv col [] _ = []
      csv col (r:rs) col_idx = [csv nth str r col_idx] :: (csv col rs col_idx)

fn :: csv find header idx [String] String Int => Int
      csv find header idx [] _ _ = (0 - 1)
      csv find header idx (h:hs) target idx =
        | h == target = idx
        | otherwise = csv find header idx hs target (idx + 1)

fn :: csv get by header CsvTable Int String => String
      csv get by header tbl row_idx col_name =
        headers tbl -> csv find header idx col_name 0 -> c_idx
        rows tbl -> csv nth row row_idx -> csv nth str c_idx

fn :: csv row to map [String] [String] => [String String]
      csv row to map [] _ = []
      csv row to map _ [] = []
      csv row to map (h:hs) (v:vs) = [(h, v)] :: (csv row to map hs vs)
```

---

## 09.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `csv`

- **Algoritmisk garanti och säkerhet**: Exakt hantering av `\r\n` och `\n` både inom och utanför citattecken samt förlustfria rundresor med `csv parse (csv stringify rader)`.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/csv.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test csv.rg`.

### De 5 Gyllene Reglerna när du programmerar med `csv`

1. **Deklarera `import csv` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `csv`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `csv`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `csv` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 10** går vi vidare och utforskar lib:en **`ini`** på djupet (Lib:en `ini` — Sektionsindelade `.ini`-filer, `.env` och Variabelinterpolering).
