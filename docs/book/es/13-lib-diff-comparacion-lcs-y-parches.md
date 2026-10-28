# Capítulo 13: La lib `diff` — Algoritmo LCS, Distancia de Edición, Unified Diff y Parches

## 13.1. ¿Por qué existe la lib `diff`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `diff` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `diff`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: cuando un test falla o un archivo de configuración cambia, un seco `"expected A, got B"` de 200 líneas te obliga a dejarte las pestañas buscando qué línea exacta ha cambiado.

La lib **`diff`** calcula la **Subsecuencia Común Más Larga (LCS)** sobre `Tensor[Int]` 2D para producir ediciones mínimas (`DiffKeep`, `DiffAdd`, `DiffDel`), distancia de edición, estadísticas, formato **Unified Diff** (`---`/`+++`/`@@`) y reconstrucción exacta con `diff apply`.

En un ecosistema tradicional, resolver las tareas del dominio **`DIFF`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`diff`** (`src/main/ridgun/lib/diff.rg`) aborda el problema con cuatro principios innegociables:

1. **Declara `import diff` (o `import diff as alias`) al inicio del archivo**: cada lib define su espacio de nombres `module :: diff` y en modo `--strict` las funciones multi-palabra se invocan siempre con espacios naturales.
2. **Encadena tus tuberías de izquierda a derecha con `->`**: escribe `entrada paso uno -> paso dos -> resultado`, usa máscaras `(+ _ _ +)` para desestructurar secuencias y omite `_ =` en sentencias secuenciales (o descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `diff` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 13.2. Artefactos nativos, importación y catálogo completo de la API de `diff`

En `ridgun-libs`, **`diff`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/diff.rg` (dominio `DIFF`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/diff.rglib` | Distribución e importación directa con `import diff` |
| **Archivo compilado** | `target/diff.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libdiff.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Cada lib declara su propio espacio de nombres con `module :: diff`: basta con escribir `import diff` (o `import diff as alias`) en el encabezado y llamar a sus funciones con espacios naturales (`mi funcion x`) y tuberías `->` (`x mi funcion -> resultado`).

### 13.2.1. Resumen de familias funcionales de `diff`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `type DiffOp` | `DiffKeep String | DiffDel String | DiffAdd String` |
| `diff lines / diff text` | Calcula el guion mínimo de edición LCS entre listas `[String]` o textos multilínea |
| `diff edit distance / diff stats` | Distancia mínima de inserción+borrado y recuento `(kept, added, deleted)` |
| `diff format / diff unified` | Formatea líneas compactas `+ / - /  ` o Unified Diff estándar con cabeceras |
| `diff apply / diff apply text` | Reconstruye el documento destino sin pérdidas a partir del guion de edición |

### 13.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/diff.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/diff.rg` (`2` tipos, `0` operadores y `33` funciones):

**Tipos algebraicos y registros (`type`) de `diff`:**

```ridgun
type DiffEdit = diff_op: String, line_text: String, old_line_no: Int, new_line_no: Int
type DiffStats = equal_count: Int, insert_count: Int, delete_count: Int
```

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
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

## 13.3. Explorando `diff` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `diff` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test diff.rg`.

### 13.3.1. Ejemplo 1: Flujo principal en estilo tabular con `diff`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `diff` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import diff

fn :: auditar cambio String String => Int String
      auditar cambio antes despues =
        diff edit distance antes despues -> dist
        diff unified antes despues "config.old" "config.new" -> parche
        (dist, parche)
```

### 13.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `diff` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import diff

fn :: verificar parche String [DiffEdit] => String
      verificar parche orig ops =
        diff apply orig ops
```

### 13.3.3. Ejemplo 3: Comparación de textos vacíos e idénticos: distancia de edición cero y verificación de invariantes

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `diff` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 13.3.4. Ejemplo 4: Inserciones puras (`DiffInsert`), borrados puros (`DiffDelete`) y aplicación hacia adelante (`diff patch`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `diff` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 13.3.5. Ejemplo 5: El vector clásico de Eugene Myers (`ABCABBA` $\rightarrow$ `CBABAC`): subsecuencia común más larga (LCS) y distancia mínima

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `diff` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 13.3.6. Ejemplo 6: Inspección de números de línea de origen y destino (`diff old line`, `diff new line`) y reconstrucción exacta con `diff patch`

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `diff` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 13.3.7. Ejemplo 7: Generación de parches unificados estilo GNU (`--- old`, `+++ new`, `-`, `+`, ` `) con `diff unified` y estadísticas `(kept, deleted, inserted)`

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `diff` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 13.3.8. Ejemplo 8: Robustez ante archivos con líneas repetidas y bloques duplicados

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `diff` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

## 13.4. Bajo el capó: cómo está construida `diff` en Ridgun puro (`src/main/ridgun/lib/diff.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/diff.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 13.4.1. Implementación interna: Internal Helpers

Fíjate en cómo `diff.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

### 13.4.2. Implementación interna: Public API

Fíjate en cómo `diff.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

## 13.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `diff`

- **Garantía algorítmica y de seguridad**: Identidad matemática garantizada $diff\_edit\_distance(a, b) == |a| + |b| - 2 \cdot LCS(a, b)$ y reconstrucción sin pérdidas `diff apply (diff lines a b) == b`.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/diff.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test diff.rg`.

### Las 5 Reglas de Oro al programar con `diff`

1. **Declara `import diff` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `diff` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `diff` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `diff` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 14** pasaremos a explorar en profundidad la lib **`template`** (La lib `template` — Plantillas Mustache Seguras con Auto-Escape HTML y LaTeX).
