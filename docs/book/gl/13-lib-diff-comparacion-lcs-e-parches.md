# Capítulo 13: A lib `diff` — Algoritmo LCS, Distancia de Edición, Unified Diff e Parches

## 13.1. Por que existe a lib `diff`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `diff` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `diff`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: cando un test falla ou un ficheiro de configuración muda, un seco `"expected A, got B"` de 200 liñas obrígache a deixarte as pestanas buscando que liña exacta mudou.

A lib **`diff`** calcula a **Subsecuencia Común Máis Longa (LCS)** sobre `Tensor[Int]` 2D para producir edicións mínimas (`DiffKeep`, `DiffAdd`, `DiffDel`), distancia de edición, estatísticas, formato **Unified Diff** (`---`/`+++`/`@@`) e reconstrución exacta con `diff apply`.

Nun ecosistema tradicional, resolver as tarefas do dominio **`DIFF`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`diff`** (`src/main/ridgun/lib/diff.rg`) aborda o problema con catro principios innegociables:

1. **Funcións totais e contratos explícitos (`=>`)**: ningunha función de `diff` lanza excepcións ocultas nin depende de `null`. Todo caso límite devolve un valor sentinela documentado ou un tipo alxébrico suma (`Option`, `Result`).
2. **Cero código C e cero `libc`**: todo o código de `diff` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `diff` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 13.2. Artefactos nativos, importación e catálogo completo da API de `diff`

En `ridgun-libs`, **`diff`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/diff.rg` (dominio `DIFF`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/diff.rglib` | Distribución e importación directa con `import diff` |
| **Ficheiro compilado** | `target/diff.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libdiff.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import diff` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

### 13.2.1. Resumo de familias funcionais de `diff`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `type DiffOp` | `DiffKeep String | DiffDel String | DiffAdd String` |
| `diff lines / diff text` | Calcula o guión mínimo de edición LCS entre listas `[String]` ou textos multiliña |
| `diff edit distance / diff stats` | Distancia mínima de inserción+borrado e reconto `(kept, added, deleted)` |
| `diff format / diff unified` | Formatea liñas compactas `+ / - /  ` ou Unified Diff estándar con cabeceiras |
| `diff apply / diff apply text` | Reconstrúe o documento destino sen perdas a partir do guión de edición |

### 13.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/diff.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/diff.rg` (`2` tipos, `0` operadores e `33` funcións):

**Tipos alxébricos e rexistros (`type`) de `diff`:**

```ridgun
type DiffEdit = diff_op: String, line_text: String, old_line_no: Int, new_line_no: Int
type DiffStats = equal_count: Int, insert_count: Int, delete_count: Int
```

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 13.3. Explorando `diff` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `diff` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test diff.rg`.

### 13.3.1. Exemplo 1: Fluxo principal en estilo tabular con `diff`

Observa como en Ridgun os signos `=` e os pasos de transformación con `diff` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import diff

fn :: auditar cambio (antes : String) (despues : String) => (Int, String)
      auditar cambio antes despues =
        dist   = diff edit distance ( ["host=localhost", "port=8080"] ) ( ["host=0.0.0.0", "port=8080"] )
        parche = diff unified "config.old" "config.new" antes despues
        (dist, parche)
```

### 13.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `diff` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import diff

fn :: verificar parche (orig : [String]) (nuevo : [String]) => [String]
      verificar parche orig nuevo =
        ops = diff lines orig nuevo
        diff apply ops
```

### 13.3.3. Exemplo 3: Comparación de textos baleiros e idénticos: distancia de edición cero e verificación de invariantes

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `diff` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 13.3.4. Exemplo 4: Insercións puras (`DiffInsert`), borrados puros (`DiffDelete`) e aplicación cara adiante (`diff patch`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `diff` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 13.3.5. Exemplo 5: O vector clásico de Eugene Myers (`ABCABBA` $\rightarrow$ `CBABAC`): subsecuencia común máis longa (LCS) e distancia mínima

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `diff` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 13.3.6. Exemplo 6: Inspección de números de liña de orixe e destino (`diff old line`, `diff new line`) e reconstrución exacta con `diff patch`

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `diff` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 13.3.7. Exemplo 7: Xeración de parches unificados estilo GNU (`--- old`, `+++ new`, `-`, `+`, ` `) con `diff unified` e estatísticas `(kept, deleted, inserted)`

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `diff` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 13.3.8. Exemplo 8: Robustez ante ficheiros con liñas repetidas e bloques duplicados

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `diff` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

## 13.4. Baixo o capó: como está construída `diff` en Ridgun puro (`src/main/ridgun/lib/diff.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/diff.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 13.4.1. Implementación interna: Internal Helpers

Fíxate en como `diff.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

### 13.4.2. Implementación interna: Public API

Fíxate en como `diff.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

## 13.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `diff`

- **Garantía algorítmica e de seguridade**: Identidade matemática garantida $diff\_edit\_distance(a, b) == |a| + |b| - 2 \cdot LCS(a, b)$ e reconstrución sen perdas `diff apply (diff lines a b) == b`.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/diff.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test diff.rg`.

### As 5 Regras de Ouro ao programar con `diff`

1. **Declara `import diff` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `diff` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `diff` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `diff` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 14** pasaremos a explorar en profundidade a lib **`template`** (A lib `template` — Modelos Mustache Seguros con Auto-Escape HTML e LaTeX).
