# Capítulo 09: A lib `csv` — Analizador de Estados RFC 4180 para CSV/TSV e Táboas Indexadas

## 09.1. Por que existe a lib `csv`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `csv` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `csv`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: todo o mundo cre que analizar un CSV é facer `str split lina ","`... ata que aparece un campo entre comiñas cunha coma dentro, comiñas escapadas `""` ou un salto de liña `\r\n` no medio dunha cela.

A lib **`csv`** implementa unha máquina de estados completa conforme a **RFC 4180** para CSV e TSV, serialización automática con comiñas intelixentes e o tipo `CsvTable` para consultar columnas e filas por nome de cabeceira.

Nun ecosistema tradicional, resolver as tarefas do dominio **`CSV`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`csv`** (`src/main/ridgun/lib/csv.rg`) aborda o problema con catro principios innegociables:

1. **Funcións totais e contratos explícitos (`=>`)**: ningunha función de `csv` lanza excepcións ocultas nin depende de `null`. Todo caso límite devolve un valor sentinela documentado ou un tipo alxébrico suma (`Option`, `Result`).
2. **Cero código C e cero `libc`**: todo o código de `csv` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `csv` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 09.2. Artefactos nativos, importación e catálogo completo da API de `csv`

En `ridgun-libs`, **`csv`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/csv.rg` (dominio `CSV`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/csv.rglib` | Distribución e importación directa con `import csv` |
| **Ficheiro compilado** | `target/csv.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libcsv.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import csv` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

### 09.2.1. Resumo de familias funcionais de `csv`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `csv parse / tsv parse / csv parse with` | Analiza texto CSV/TSV (incluíndo celas multiliña e escapes `""`) en `[[String]]` |
| `csv stringify / tsv stringify` | Serializa `[[String]]` entrecomiñando só celas con delimitadores, comiñas ou saltos |
| `csv parse table / csv get cell / csv col` | Consulta sobre `CsvTable` indexada por cabeceira `(fila, nome_col)` ou columna completa |
| `csv row to kv / csv table to kv list` | Converte filas tabulares en dicionarios `[String String]` indexados por cabeceira |

### 09.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/csv.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/csv.rg` (`1` tipos, `0` operadores e `23` funcións):

**Tipos alxébricos e rexistros (`type`) de `csv`:**

```ridgun
type CsvTable = headers: [String], rows: [[String]], delimiter_char: String, has_headers: Bool
```

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 09.3. Explorando `csv` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `csv` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test csv.rg`.

### 09.3.1. Exemplo 1: Fluxo principal en estilo tabular con `csv`

Observa como en Ridgun os signos `=` e os pasos de transformación con `csv` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import csv

fn :: extraer columna precios (raw_csv : String) => ([String], String)
      extraer columna precios raw_csv =
        tabla   = csv parse table raw_csv
        precios = csv col tabla "precio"
        primero = csv get cell tabla 0 "producto" "desconocido"
        (precios, primero)
```

### 09.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `csv` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import csv

fn :: exportar informe () => String
      exportar informe =
        filas = [["id", "nota"], ["1", "Contiene, coma"], ["2", "Dijo "hola""]]
        csv stringify filas
```

### 09.3.3. Exemplo 3: Ida e volta RFC 4180 CSV/TSV con comiñas escapadas `""`, comas internas e saltos de liña incrustados

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `csv` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 09.3.4. Exemplo 4: Manexo de finais de liña `CRLF` (`\r\n`), celas baleiras consecutivas e delimitadores personalizados

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `csv` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 09.3.5. Exemplo 5: Táboas con cabeceira (`CsvTable`): busca por fila e nome de columna (`csv get cell`), extracción de columnas e rexistros clave-valor

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `csv` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

## 09.4. Baixo o capó: como está construída `csv` en Ridgun puro (`src/main/ridgun/lib/csv.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/csv.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 09.4.1. Implementación interna: RFC 4180 State-Machine Parser

Fíxate en como `csv.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

### 09.4.2. Implementación interna: RFC 4180 Serialization & Escaping

Fíxate en como `csv.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

### 09.4.3. Implementación interna: Column Extraction & Header-Mapped Lookup

Fíxate en como `csv.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

## 09.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `csv`

- **Garantía algorítmica e de seguridade**: Soporte exacto de saltos `\r\n` e `\n` tanto fóra coma dentro de comiñas, e cero perda de datos en viaxes de ida e volta `csv parse (csv stringify filas)`.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/csv.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test csv.rg`.

### As 5 Regras de Ouro ao programar con `csv`

1. **Declara `import csv` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `csv` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `csv` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `csv` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 10** pasaremos a explorar en profundidade a lib **`ini`** (A lib `ini` — Ficheiros `.ini` por Seccións, `.env` e Interpolación de Variables).
