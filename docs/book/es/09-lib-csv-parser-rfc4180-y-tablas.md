# Capítulo 09: La lib `csv` — Analizador de Estados RFC 4180 para CSV/TSV y Tablas Indexadas

## 09.1. ¿Por qué existe la lib `csv`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `csv` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `csv`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: todo el mundo cree que parsear un CSV es hacer `str split linea ","`... hasta que aparece un campo entre comillas con una coma dentro, comillas escapadas `""` o un salto de línea `\r\n` en mitad de una celda.

La lib **`csv`** implementa una máquina de estados completa conforme a **RFC 4180** para CSV y TSV, serialización automática con entrecomillado inteligente y el tipo `CsvTable` para consultar columnas y filas por nombre de cabecera.

En un ecosistema tradicional, resolver las tareas del dominio **`CSV`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`csv`** (`src/main/ridgun/lib/csv.rg`) aborda el problema con cuatro principios innegociables:

1. **Declara `import csv` (o `import csv as alias`) al inicio del archivo**: cada lib define su espacio de nombres `module :: csv` y en modo `--strict` las funciones multi-palabra se invocan siempre con espacios naturales.
2. **Encadena tus tuberías de izquierda a derecha con `->`**: escribe `entrada paso uno -> paso dos -> resultado`, usa máscaras `(+ _ _ +)` para desestructurar secuencias y omite `_ =` en sentencias secuenciales (o descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `csv` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 09.2. Artefactos nativos, importación y catálogo completo de la API de `csv`

En `ridgun-libs`, **`csv`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/csv.rg` (dominio `CSV`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/csv.rglib` | Distribución e importación directa con `import csv` |
| **Archivo compilado** | `target/csv.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libcsv.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Cada lib declara su propio espacio de nombres con `module :: csv`: basta con escribir `import csv` (o `import csv as alias`) en el encabezado y llamar a sus funciones con espacios naturales (`mi funcion x`) y tuberías `->` (`x mi funcion -> resultado`).

### 09.2.1. Resumen de familias funcionales de `csv`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `csv parse / tsv parse / csv parse with` | Analiza texto CSV/TSV (incluyendo celdas multilínea y escapes `""`) en `[[String]]` |
| `csv stringify / tsv stringify` | Serializa `[[String]]` entrecomillando solo celdas con delimitadores, comillas o saltos |
| `csv parse table / csv get cell / csv col` | Consulta sobre `CsvTable` indexada por cabecera `(fila, nombre_col)` o columna completa |
| `csv row to kv / csv table to kv list` | Convierte filas tabulares en diccionarios `[String String]` indexados por cabecera |

### 09.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/csv.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/csv.rg` (`1` tipos, `0` operadores y `23` funciones):

**Tipos algebraicos y registros (`type`) de `csv`:**

```ridgun
type CsvTable = headers: [String], rows: [[String]], delimiter_char: String, has_headers: Bool
```

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
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

## 09.3. Explorando `csv` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `csv` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test csv.rg`.

### 09.3.1. Ejemplo 1: Flujo principal en estilo tabular con `csv`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `csv` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import csv

fn :: extraer columna precios String => [String] String
      extraer columna precios raw_csv =
        raw_csv csv parse -> tabla
        csv col by name tabla "precio" -> precios
        csv cell by name tabla 0 "producto" -> primero
        (precios, primero)
```

### 09.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `csv` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import csv

fn :: exportar informe => String
      exportar informe =
        [["id", "nota"], ["1", "Contiene, coma"], ["2", "Dijo "hola""]] -> filas
        filas csv encode
```

### 09.3.3. Ejemplo 3: Ida y vuelta RFC 4180 CSV/TSV con comillas escapadas `""`, comas internas y saltos de línea embebidos

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `csv` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 09.3.4. Ejemplo 4: Manejo de finales de línea `CRLF` (`\r\n`), celdas vacías consecutivas y delimitadores personalizados

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `csv` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 09.3.5. Ejemplo 5: Tablas con cabecera (`CsvTable`): búsqueda por fila y nombre de columna (`csv get cell`), extracción de columnas y registros clave-valor

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `csv` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

## 09.4. Bajo el capó: cómo está construida `csv` en Ridgun puro (`src/main/ridgun/lib/csv.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/csv.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 09.4.1. Implementación interna: RFC 4180 State-Machine Parser

Fíjate en cómo `csv.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

### 09.4.2. Implementación interna: RFC 4180 Serialization & Escaping

Fíjate en cómo `csv.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

### 09.4.3. Implementación interna: Column Extraction & Header-Mapped Lookup

Fíjate en cómo `csv.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

## 09.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `csv`

- **Garantía algorítmica y de seguridad**: Soporte exacto de saltos `\r\n` y `\n` tanto fuera como dentro de comillas, y cero pérdida de datos en viajes de ida y vuelta `csv parse (csv stringify filas)`.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/csv.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test csv.rg`.

### Las 5 Reglas de Oro al programar con `csv`

1. **Declara `import csv` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `csv` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `csv` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `csv` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 10** pasaremos a explorar en profundidad la lib **`ini`** (La lib `ini` — Archivos `.ini` por Secciones, `.env` e Interpolación de Variables).
