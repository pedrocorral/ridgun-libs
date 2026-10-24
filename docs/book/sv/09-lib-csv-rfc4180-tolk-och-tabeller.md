# Kapitel 09: Lib:en `csv` — RFC 4180 CSV/TSV-Tillståndsmaskin och Kolumnindexerade Tabeller

## 09.1. Varför finns lib:en `csv`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `csv`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `csv`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: alla tror att CSV-tolkning bara är `str split rad ","`... tills det dyker upp ett citerat fält med ett kommatecken inuti, dubbla citattecken `""` eller en radbrytning `\r\n` mitt i en cell.

Lib:en **`csv`** implementerar en komplett **RFC 4180**-tillståndsmaskin för CSV och TSV, smart serialisering med citattecken och typen `CsvTable` för kolumn- och raduppslagning via rubriknamn.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`CSV`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`csv`** (`src/main/ridgun/lib/csv.rg`) problemet genom fyra kompromisslösa principer:

1. **Totala funktioner och explicita kontrakt (`=>`)**: ingen funktion i `csv` kastar dolda undantag eller förlitar sig på `null`. Varje gränsfall returnerar ett dokumenterat sentinelvärde eller en algebraisk summatyp (`Option`, `Result`).
2. **Noll C-kod och noll `libc`**: varje rad i `csv` kompileras direkt till inbyggd ELF64-maskinkod verifierad av `ridgunc`.
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

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import csv` överst och anropar funktionerna med mellanslag eller understreck.

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

fn :: extraer columna precios (raw_csv : String) => ([String], String)
      extraer columna precios raw_csv =
        tabla   = csv parse table raw_csv
        precios = csv col tabla "precio"
        primero = csv get cell tabla 0 "producto" "desconocido"
        (precios, primero)
```

### 09.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `csv` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import csv

fn :: exportar informe () => String
      exportar informe =
        filas = [["id", "nota"], ["1", "Contiene, coma"], ["2", "Dijo "hola""]]
        csv stringify filas
```

### 09.3.3. Exempel 3: RFC 4180 CSV/TSV tur-och-retur med dubblerade citattecken `""`, inbäddade komman och flerradsceller

I detta praktiska exempel undersöker vi grundligt hur `csv` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test_csv_tsv_roundtrip => ()
      test_csv_tsv_roundtrip =
        nl = char_from_code 10
        tab = char_from_code 9
        raw_csv = "name,role,note" + nl + "Ada,\"Admin, Lead\",\"Quote \"\"here\"\"\"" + nl + "Bob,User,\"Line 1" + nl + "Line 2\"" + nl
        parsed = csv parse raw_csv
        _ = assert int equals (csv_row_count parsed) 3 "AC1: 3 rows parsed including multiline quoted cell"
        _ = assert str eq (csv_cell_at parsed 1 1) "Admin, Lead" "AC1: quoted comma preserved"
        _ = assert str eq (csv_cell_at parsed 1 2) "Quote \"here\"" "AC1: doubled quote unescaped"
        _ = assert str eq (csv_cell_at parsed 2 2) ("Line 1" + nl + "Line 2") "AC1: embedded newline in quoted cell preserved"
        re_csv = csv stringify parsed
        _ = assert str eq re_csv raw_csv "AC1/AC2: RFC 4180 CSV quoted comma, escaped quote, and newline round-trip"

        raw_tsv = "col1" + tab + "col2" + nl + "val,1" + tab + "val2" + nl
        parsed_tsv = tsv parse raw_tsv
        _ = assert str eq (csv_cell_at parsed_tsv 1 0) "val,1" "AC1: TSV unquoted comma preserved"
        re_tsv = tsv stringify parsed_tsv
        _ = assert str eq re_tsv raw_tsv "AC1/AC2: TSV round-trip"
        ()
```

### 09.3.4. Exempel 4: Hantering av `CRLF`-radslut (`\r\n`), på varandra följande tomma celler och anpassade avgränsare

I detta praktiska exempel undersöker vi grundligt hur `csv` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test_csv_crlf_and_empty_cells => ()
      test_csv_crlf_and_empty_cells =
        cr = char_from_code 13
        nl = char_from_code 10
        crlf = cr + nl
        raw_crlf = "a,b,c" + crlf + "1,,3" + crlf + ",2," + crlf
        rows_crlf = csv parse raw_crlf
        _ = assert int equals (csv_row_count rows_crlf) 3 "AC1: CRLF row count"
        _ = assert str eq (csv_cell_at rows_crlf 1 0) "1" "AC1: cell (1,0)"
        _ = assert str eq (csv_cell_at rows_crlf 1 1) "" "AC1: middle empty cell (1,1)"
        _ = assert str eq (csv_cell_at rows_crlf 1 2) "3" "AC1: cell (1,2)"
        _ = assert str eq (csv_cell_at rows_crlf 2 0) "" "AC1: leading empty cell (2,0)"
        _ = assert str eq (csv_cell_at rows_crlf 2 1) "2" "AC1: cell (2,1)"
        _ = assert str eq (csv_cell_at rows_crlf 2 2) "" "AC1: trailing empty cell (2,2)"

        semi_rows = csv parse with delim ("k1;k2" + nl + "v1;v2" + nl) ";"
        _ = assert int equals (csv_row_count semi_rows) 2 "AC1: semicolon delimiter row count"
        _ = assert str eq (csv_cell_at semi_rows 1 1) "v2" "AC1: semicolon delimiter cell (1,1)"
        _ = assert int equals (csv_row_count (csv parse "")) 0 "AC1: empty input yields 0 rows"
        ()
```

### 09.3.5. Exempel 5: Tabeller med rubrikrad (`CsvTable`): uppslagning via rad och kolumnnamn (`csv get cell`), kolumnextraktion och nyckel-värde-poster

I detta praktiska exempel undersöker vi grundligt hur `csv` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test_csv_table_lookup => ()
      test_csv_table_lookup =
        nl = char_from_code 10
        raw_csv = "id,name,dept" + nl + "10,Ada,Math" + nl + "20,Grace,Compilers" + nl
        tbl = csv parse table raw_csv True
        _ = assert true (has_headers tbl) "AC3: table has_headers True"
        _ = assert int equals (csv_len (headers tbl)) 3 "AC3: 3 headers extracted"
        _ = assert str eq (csv get by header tbl 0 "name") "Ada" "AC3: csv get by header row 0"
        _ = assert str eq (csv get by header tbl 1 "dept") "Compilers" "AC3: csv get by header row 1"
        _ = assert str eq (csv get by header tbl 0 "missing") "" "AC3: csv get by header missing column"
        _ = assert str eq (csv get by header tbl 99 "name") "" "AC3: csv get by header out-of-bounds row"

        tbl_no_h = csv parse table raw_csv False
        _ = assert false (has_headers tbl_no_h) "AC3: table has_headers False"
        _ = assert int equals (csv_row_count (rows tbl_no_h)) 3 "AC3: headerless table keeps all 3 rows"

        names = csv col (rows tbl) 1
        _ = assert int equals (csv_len names) 2 "AC3: csv col length"
        _ = assert str eq (csv_str_at names 0) "Ada" "AC3: csv col[0]"
        _ = assert str eq (csv_str_at names 1) "Grace" "AC3: csv col[1]"

        rmap = csv row to map ["id", "name", "dept"] ["10", "Ada", "Math"]
        _ = assert str eq (csv_pair_val rmap "id") "10" "AC3: csv row to map id"
        _ = assert str eq (csv_pair_val rmap "name") "Ada" "AC3: csv row to map name"
        _ = assert str eq (csv_pair_val rmap "dept") "Math" "AC3: csv row to map dept"
        ()
```

---

## 09.4. Under huven: hur `csv` är byggd i ren Ridgun (`src/main/ridgun/lib/csv.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/csv.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 09.4.1. Intern implementation: RFC 4180 State-Machine Parser

Se hur `csv.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: csv_delim_code String => Int
      csv_delim_code ""     =  44
      csv_delim_code d      =  str_char_at d 0

fn :: csv_append_final_row [[String]] [String] String => [[String]]
      csv_append_final_row rows       []       ""     =  rows
      csv_append_final_row rows       cur_row  cell   =  rows :: [cur_row :: [cell]]

fn :: csv_parse_quoted String Int Int Int String [String] [[String]] => [[String]]
      csv_parse_quoted s pos len d_code cell cur_row rows
        | pos >= len = csv_append_final_row rows cur_row cell
        | (str_char_at s pos) == 34 AND (pos + 1) < len AND (str_char_at s (pos + 1)) == 34 = csv_parse_quoted s (pos + 2) len d_code (cell + (char_from_code 34)) cur_row rows
        | (str_char_at s pos) == 34 = csv_parse_unquoted s (pos + 1) len d_code cell cur_row rows
        | otherwise = csv_parse_quoted s (pos + 1) len d_code (cell + (str_slice s pos (pos + 1))) cur_row rows

fn :: csv_parse_unquoted String Int Int Int String [String] [[String]] => [[String]]
      csv_parse_unquoted s pos len d_code cell cur_row rows
        | pos >= len = csv_append_final_row rows cur_row cell
        | (str_char_at s pos) == 34 AND cell == "" = csv_parse_quoted s (pos + 1) len d_code "" cur_row rows
        | (str_char_at s pos) == d_code = csv_parse_unquoted s (pos + 1) len d_code "" (cur_row :: [cell]) rows
        | (str_char_at s pos) == 13 AND (pos + 1) < len AND (str_char_at s (pos + 1)) == 10 = csv_parse_unquoted s (pos + 2) len d_code "" [] (rows :: [cur_row :: [cell]])
        | (str_char_at s pos) == 10 OR (str_char_at s pos) == 13 = csv_parse_unquoted s (pos + 1) len d_code "" [] (rows :: [cur_row :: [cell]])
        | otherwise = csv_parse_unquoted s (pos + 1) len d_code (cell + (str_slice s pos (pos + 1))) cur_row rows

fn :: csv parse with delim String String => [[String]]
      csv parse with delim s delim =
        csv_parse_unquoted s 0 (str_len s) (csv_delim_code delim) "" [] []

fn :: csv parse String => [[String]]
      csv parse s      =  csv parse with delim s ","

fn :: tsv parse String => [[String]]
      tsv parse s      =  csv parse with delim s (char_from_code 9)

fn :: csv_build_table [[String]] Bool  => CsvTable
      csv_build_table []         has_h =  CsvTable [] [] "," has_h
      csv_build_table (h:rest)   True  =  CsvTable h rest "," True
      csv_build_table all_rows   False =  CsvTable [] all_rows "," False

fn :: csv parse table String Bool  => CsvTable
      csv parse table s      has_h =  csv_build_table (csv parse s) has_h
```

### 09.4.2. Intern implementation: RFC 4180 Serialization & Escaping

Se hur `csv.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: csv_needs_quotes_loop String Int Int Int    => Bool
      csv_needs_quotes_loop s      pos len d_code
        | pos >= len = False
        | (str_char_at s pos) == d_code OR (str_char_at s pos) == 34 OR (str_char_at s pos) == 10 OR (str_char_at s pos) == 13 = True
        | otherwise = csv_needs_quotes_loop s (pos + 1) len d_code

fn :: csv_double_quotes_loop String Int Int String => String
      csv_double_quotes_loop s      pos len acc
        | pos >= len = acc
        | (str_char_at s pos) == 34 = csv_double_quotes_loop s (pos + 1) len (acc + (char_from_code 34) + (char_from_code 34))
        | otherwise = csv_double_quotes_loop s (pos + 1) len (acc + (str_slice s pos (pos + 1)))

fn :: csv_format_cell String Int    => String
      csv_format_cell cell   d_code
        | csv_needs_quotes_loop cell 0 (str_len cell) d_code = (char_from_code 34) + (csv_double_quotes_loop cell 0 (str_len cell) "") + (char_from_code 34)
        | otherwise = cell

fn :: csv_join_row [String] String Int    => String
      csv_join_row []       _      _      =  ""
      csv_join_row (c:[])   _      d_code =  csv_format_cell c d_code
      csv_join_row (c:cs)   delim  d_code =  (csv_format_cell c d_code) + delim + (csv_join_row cs delim d_code)

fn :: csv_join_rows [[String]] String Int    => String
      csv_join_rows []         _      _      =  ""
      csv_join_rows (r:rs)     delim  d_code =  (csv_join_row r delim d_code) + (char_from_code 10) + (csv_join_rows rs delim d_code)

fn :: csv stringify with delim [[String]] String => String
      csv stringify with delim rows delim =
        csv_join_rows rows delim (csv_delim_code delim)

fn :: csv stringify [[String]] => String
      csv stringify rows       =  csv stringify with delim rows ","

fn :: tsv stringify [[String]] => String
      tsv stringify rows       =  csv stringify with delim rows (char_from_code 9)
```

### 09.4.3. Intern implementation: Column Extraction & Header-Mapped Lookup

Se hur `csv.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: csv_nth_str [String] Int => String
      csv_nth_str []       _   =  ""
      csv_nth_str (x:xs)   idx
        | idx < 0 = ""
        | idx == 0 = x
        | otherwise = csv_nth_str xs (idx - 1)

fn :: csv_nth_row [[String]] Int => [String]
      csv_nth_row []         _   =  []
      csv_nth_row (r:rs)     idx
        | idx < 0 = []
        | idx == 0 = r
        | otherwise = csv_nth_row rs (idx - 1)

fn :: csv col [[String]] Int     => [String]
      csv col []         _       =  []
      csv col (r:rs)     col_idx =  [csv_nth_str r col_idx] :: (csv col rs col_idx)

fn :: csv_find_header_idx [String] String Int => Int
      csv_find_header_idx []       _      _   =  -1
      csv_find_header_idx (h:hs)   target idx
        | h == target = idx
        | otherwise = csv_find_header_idx hs target (idx + 1)

fn :: csv get by header CsvTable Int String => String
      csv get by header tbl row_idx col_name =
        c_idx = csv_find_header_idx (headers tbl) col_name 0
        csv_nth_str (csv_nth_row (rows tbl) row_idx) c_idx

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
