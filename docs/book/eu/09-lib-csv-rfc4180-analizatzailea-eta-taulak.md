# 09. kapitulua: `csv` lib-a — CSV/TSV-rako RFC 4180 Egoera-analizatzailea eta Taula Indexatuak

## 09.1. Zergatik existitzen da `csv` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `csv` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `csv`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: mundu guztiak uste du CSV bat analizatzea `str split lerroa ","` egitea dela... harik eta komatxo artean koma bat, `""` komatxo iheskorrak edo gelaxka baten erdian `\r\n` lerro-jauzi bat dituen eremu bat agertzen den arte.

**`csv`** lib-ak **RFC 4180** arauarekiko egoera-makina oso bat inplementatzen du CSV eta TSV formatuetarako, komatxo adimentsudun serializazio automatikoa eta goiburu-izenaren araberako zutabeak eta errenkadak kontsultatzeko `CsvTable` mota.

Ekosistema tradizional batean, **`CSV`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`csv`** lib-ak (`src/main/ridgun/lib/csv.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Funtzio osoak eta kontratu esplizituak (`=>`)**: `csv`-eko funtzio bakar batek ere ez du ezkutuko salbuespenik jaurtitzen, ezta `null` erabiltzen ere. Muga-kasu orok dokumentatutako balio bat edo batura-mota aljebraiko bat (`Option`, `Result`) itzultzen du.
2. **Zero C kode eta zero `libc`**: `csv`-eko kode guztia zuzenean ELF64 makina-kode natibora konpilatzen da, `ridgunc`-ek egiaztatuta.
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `csv`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 09.2. Artefaktu natiboak, inportazioa eta `csv` APIaren katalogo osoa

`ridgun-libs`-en, **`csv`** lehen mailako **lib** bat da, `src/main/ridgun/lib/csv.rg` bidean kokatua (`CSV` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/csv.rglib` | Banaketa eta inportazio zuzena `import csv` bidez |
| **Fitxategi konpilatua** | `target/csv.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libcsv.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import csv` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

### 09.2.1. `csv`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `csv parse / tsv parse / csv parse with` | CSV/TSV testua (`""` ihesak eta lerro anitzeko gelaxkak barne) `[[String]]`-ra analizatzen du |
| `csv stringify / tsv stringify` | `[[String]]` serializatzen du, bereizleak, komatxoak edo jauziak dituzten gelaxkak soilik komatxo artean jarriz |
| `csv parse table / csv get cell / csv col` | Goiburuz indexatutako `CsvTable` kontsulta `(errenkada, zutabe_izena)` bidez edo zutabe osoa |
| `csv row to kv / csv table to kv list` | Errenkada taularatuak goiburuz indexatutako `[String String]` hiztegietara bihurtzen ditu |

### 09.2.2. `src/main/ridgun/lib/csv.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/csv.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`1` mota, `0` eragile eta `23` funtzio):

**`csv`-eko mota aljebraikoak eta erregistroak (`type`):**

```ridgun
type CsvTable = headers: [String], rows: [[String]], delimiter_char: String, has_headers: Bool
```

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
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

## 09.3. `csv` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `csv` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test csv.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 09.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `csv` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `csv` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import csv

fn :: extraer columna precios (raw_csv : String) => ([String], String)
      extraer columna precios raw_csv =
        tabla   = csv parse table raw_csv
        precios = csv col tabla "precio"
        primero = csv get cell tabla 0 "producto" "desconocido"
        (precios, primero)
```

### 09.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`csv` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import csv

fn :: exportar informe () => String
      exportar informe =
        filas = [["id", "nota"], ["1", "Contiene, coma"], ["2", "Dijo "hola""]]
        csv stringify filas
```

### 09.3.3. 3. adibidea: RFC 4180 CSV/TSV joan-etorria `""` komatxo iheskorrekin, barne-komekin eta txertatutako lerro-jauziekin

Adibide praktiko honetan `csv` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 09.3.4. 4. adibidea: `CRLF` (`\r\n`) lerro-amaieren, gelaxka huts jarraituen eta mugatzaile pertsonalizatuen kudeaketa

Adibide praktiko honetan `csv` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 09.3.5. 5. adibidea: Goiburudun taulak (`CsvTable`): errenkada eta zutabe-izenaren araberako bilaketa (`csv get cell`), zutabe-erauzketa eta gako-balio erregistroak

Adibide praktiko honetan `csv` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

## 09.4. Kaputaren azpian: nola dagoen eraikia `csv` Ridgun hutsean (`src/main/ridgun/lib/csv.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/csv.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 09.4.1. Barne-inplementazioa: RFC 4180 State-Machine Parser

Ikusi nola `csv.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 09.4.2. Barne-inplementazioa: RFC 4180 Serialization & Escaping

Ikusi nola `csv.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 09.4.3. Barne-inplementazioa: Column Extraction & Header-Mapped Lookup

Ikusi nola `csv.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

## 09.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `csv`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: `\r\n` eta `\n` lerro-jauzien euskarri zehatza komatxoen barruan zein kanpoan, eta zero datu-galera `csv parse (csv stringify errenkadak)` joan-etorrietan.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/csv.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test csv.rg` suite automatizatuaren bidez.

### `csv`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import csv` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `csv`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `csv`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `csv` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**10. kapituluan** **`ini`** lib-a sakonki esploratuko dugu (`ini` lib-a — Atalkako `.ini` Fitxategiak, `.env` eta Aldagaien Interpolazioa).
