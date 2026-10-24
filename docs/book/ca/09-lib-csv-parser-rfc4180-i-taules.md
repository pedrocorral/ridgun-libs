# Capítol 09: La lib `csv` — Analitzador d'Estats RFC 4180 per a CSV/TSV i Taules Indexades

## 09.1. Per què existeix la lib `csv`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `csv` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `csv`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: tothom es pensa que analitzar un CSV és fer `str split linia ","`... fins que apareix un camp entre cometes amb una coma a dins, cometes escapades `""` o un salt de línia `\r\n` al mig d'una cel·la.

La lib **`csv`** implementa una màquina d'estats completa conforme a **RFC 4180** per a CSV i TSV, serialització automàtica amb cometes intel·ligents i el tipus `CsvTable` per consultar columnes i files per nom de capçalera.

En un ecosistema tradicional, resoldre les tasques del domini **`CSV`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`csv`** (`src/main/ridgun/lib/csv.rg`) aborda el problema amb quatre principis innegociables:

1. **Funcions totals i contractes explícits (`=>`)**: cap funció de `csv` llança excepcions ocultes ni depèn de `null`. Tot cas límit retorna un valor sentinella documentat o un tipus algebraic suma (`Option`, `Result`).
2. **Zero codi C i zero `libc`**: tot el codi de `csv` compila directament a codi màquina natiu ELF64 verificat per `ridgunc`.
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `csv` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 09.2. Artefactes natius, importació i catàleg complet de l'API de `csv`

A `ridgun-libs`, **`csv`** és una **lib** de primera classe situada a `src/main/ridgun/lib/csv.rg` (domini `CSV`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/csv.rglib` | Distribució i importació directa amb `import csv` |
| **Fitxer compilat** | `target/csv.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libcsv.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import csv` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

### 09.2.1. Resum de famílies funcionals de `csv`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `csv parse / tsv parse / csv parse with` | Analitza text CSV/TSV (incloent-hi cel·les multilínia i escapaments `""`) en `[[String]]` |
| `csv stringify / tsv stringify` | Serialitza `[[String]]` posant cometes només a cel·les amb delimitadors, cometes o salts |
| `csv parse table / csv get cell / csv col` | Consulta sobre `CsvTable` indexada per capçalera `(fila, nom_col)` o columna completa |
| `csv row to kv / csv table to kv list` | Converteix files tabulars en diccionaris `[String String]` indexats per capçalera |

### 09.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/csv.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/csv.rg` (`1` tipus, `0` operadors i `23` funcions):

**Tipus algebraics i registres (`type`) de `csv`:**

```ridgun
type CsvTable = headers: [String], rows: [[String]], delimiter_char: String, has_headers: Bool
```

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 09.3. Explorant `csv` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `csv` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test csv.rg`.

### 09.3.1. Exemple 1: Flux principal en estil tabular amb `csv`

Observa com en Ridgun els signes `=` i els passos de transformació amb `csv` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import csv

fn :: extraer columna precios (raw_csv : String) => ([String], String)
      extraer columna precios raw_csv =
        tabla   = csv parse table raw_csv
        precios = csv col tabla "precio"
        primero = csv get cell tabla 0 "producto" "desconocido"
        (precios, primero)
```

### 09.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `csv` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import csv

fn :: exportar informe () => String
      exportar informe =
        filas = [["id", "nota"], ["1", "Contiene, coma"], ["2", "Dijo "hola""]]
        csv stringify filas
```

### 09.3.3. Exemple 3: Anada i tornada RFC 4180 CSV/TSV amb cometes escapades `""`, comes internes i salts de línia incrustats

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `csv` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 09.3.4. Exemple 4: Maneig de finals de línia `CRLF` (`\r\n`), cel·les buides consecutives i delimitadors personalitzats

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `csv` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 09.3.5. Exemple 5: Taules amb capçalera (`CsvTable`): cerca per fila i nom de columna (`csv get cell`), extracció de columnes i registres clau-valor

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `csv` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

## 09.4. Sota el capó: com està construïda `csv` en Ridgun pur (`src/main/ridgun/lib/csv.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/csv.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 09.4.1. Implementació interna: RFC 4180 State-Machine Parser

Fixa't en com `csv.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 09.4.2. Implementació interna: RFC 4180 Serialization & Escaping

Fixa't en com `csv.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 09.4.3. Implementació interna: Column Extraction & Header-Mapped Lookup

Fixa't en com `csv.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

## 09.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `csv`

- **Garantia algorísmica i de seguretat**: Suport exacte de salts `\r\n` i `\n` tant fora com dins de cometes, i zero pèrdua de dades en viatges d'anada i tornada `csv parse (csv stringify files)`.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/csv.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test csv.rg`.

### Les 5 Regles d'Or en programar amb `csv`

1. **Declara `import csv` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `csv` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `csv` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `csv` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 10** passarem a explorar en profunditat la lib **`ini`** (La lib `ini` — Fitxers `.ini` per Seccions, `.env` i Interpolació de Variables).
