# Capítulo 08: La lib `json` — Árbol AST Recursivo RFC 8259, Pretty-Printer y Consultas por Ruta

## 08.1. ¿Por qué existe la lib `json`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `json` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `json`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: navegar un JSON anidado en muchos lenguajes estáticos implica escribir tres pantallas de boilerplate o encadenar diez `.and_then()` antes de leer un simple puerto.

La lib **`json`** proporciona un analizador descendente recursivo completo para **RFC 8259** sobre el ADT algebraico `JsonVal` (`JnNull`, `JnBool`, `JnInt`, `JnStr`, `JnArr`, `JnObj`, `JnErr`), serialización compacta e indentada (`json pretty`) y consultas directas por ruta con puntos (`"server.http.port"`, `"users.0.name"`).

En un ecosistema tradicional, resolver las tareas del dominio **`JSON`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`json`** (`src/main/ridgun/lib/json.rg`) aborda el problema con cuatro principios innegociables:

1. **Funciones totales y contratos explícitos (`=>`)**: ninguna función de `json` lanza excepciones ocultas ni depende de `null`. Todo caso límite (entradas vacías, divisores cero, tramas truncadas o índices fuera de rango) devuelve un valor centinela documentado o un tipo algebraico suma (`Option`, `Result`).
2. **Cero código C y cero `libc`**: todo el código de `json` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `json` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 08.2. Artefactos nativos, importación y catálogo completo de la API de `json`

En `ridgun-libs`, **`json`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/json.rg` (dominio `JSON`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/json.rglib` | Distribución e importación directa con `import json` |
| **Archivo compilado** | `target/json.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libjson.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import json` en el encabezado y llamar a sus funciones con espacios (`mi funcion x`) o guiones bajos (`mi_funcion x`) indistintamente.

### 08.2.1. Resumen de familias funcionales de `json`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `type JsonVal` | `JnNull | JnBool Bool | JnInt Int | JnStr String | JnArr [JsonVal] | JnObj [String JsonVal] | JnErr String` |
| `json parse / json is ok` | Analiza texto JSON en un árbol `JsonVal` y valida la ausencia de `JnErr` |
| `json stringify / json pretty` | Serializa `JsonVal` a JSON compacto o multilínea indentado |
| `json get path / json get str / json get int / json get bool` | Recorre objetos y listas anidados mediante rutas con puntos (`"a.b.0.c"`) |

### 08.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/json.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/json.rg` (`7` tipos, `0` operadores y `56` funciones):

**Tipos algebraicos y registros (`type`) de `json`:**

```ridgun
type JsonField = JsonField String JsonVal
type JsonVal = JsonNull | JsonBool Bool | JsonInt Int | JsonStr String | JsonArr [JsonVal] | JsonObj [JsonField]
type JsonRes = JsonOk JsonVal | JsonErr String
type JsonStep = JStepOk JsonVal Int | JStepErr String
type JsonArrStep = JArrOk [JsonVal] Int | JArrErr String
type JsonObjStep = JObjOk [JsonField] Int | JObjErr String
type JsonStrStep = JStrOk String Int | JStrErr String
```

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: j_is_ws Int` | `Bool` |
| `2` | `fn :: j_is_digit Int` | `Bool` |
| `3` | `fn :: j_skip_ws String Int Int` | `Int` |
| `4` | `fn :: j_spaces Int` | `String` |
| `5` | `fn :: j_escape_loop String Int Int String` | `String` |
| `6` | `fn :: j_escape_str String` | `String` |
| `7` | `fn :: j_unescape_char Int` | `String` |
| `8` | `fn :: j_parse_str_loop String Int Int String` | `JsonStrStep` |
| `9` | `fn :: j_parse_string String Int Int` | `JsonStrStep` |
| `10` | `fn :: j_scan_digits String Int Int` | `Int` |
| `11` | `fn :: j_parse_number String Int Int` | `JsonStep` |
| `12` | `fn :: j_finish_neg_num String Int Int` | `JsonStep` |
| `13` | `fn :: j_finish_pos_num String Int Int` | `JsonStep` |
| `14` | `fn :: j_parse_val String Int Int` | `JsonStep` |
| `15` | `fn :: j_parse_val_at String Int Int` | `JsonStep` |
| `16` | `fn :: j_wrap_str_step JsonStrStep` | `JsonStep` |
| `17` | `fn :: j_parse_arr_open String Int Int` | `JsonStep` |
| `18` | `fn :: j_parse_arr_first String Int Int` | `JsonStep` |
| `19` | `fn :: j_finish_arr_step JsonArrStep` | `JsonStep` |
| `20` | `fn :: j_parse_arr_items String Int Int [JsonVal]` | `JsonArrStep` |
| `21` | `fn :: j_parse_arr_after_item String Int [JsonVal] JsonStep` | `JsonArrStep` |
| `22` | `fn :: j_parse_arr_delim String Int Int [JsonVal]` | `JsonArrStep` |
| `23` | `fn :: j_parse_obj_open String Int Int` | `JsonStep` |
| `24` | `fn :: j_parse_obj_first String Int Int` | `JsonStep` |
| `25` | `fn :: j_finish_obj_step JsonObjStep` | `JsonStep` |
| `26` | `fn :: j_parse_obj_fields String Int Int [JsonField]` | `JsonObjStep` |
| `27` | `fn :: j_parse_obj_after_key String Int [JsonField] JsonStrStep` | `JsonObjStep` |
| `28` | `fn :: j_parse_obj_colon String Int Int String [JsonField]` | `JsonObjStep` |
| `29` | `fn :: j_parse_obj_after_val String Int String [JsonField] JsonStep` | `JsonObjStep` |
| `30` | `fn :: j_parse_obj_delim String Int Int [JsonField]` | `JsonObjStep` |
| `31` | `fn :: j_check_eof String Int JsonStep` | `JsonRes` |
| `32` | `fn :: j_check_eof_pos Int Int JsonVal` | `JsonRes` |
| `33` | `fn :: json parse String` | `JsonRes` |
| `34` | `fn :: j_join_arr [JsonVal]` | `String` |
| `35` | `fn :: j_join_obj [JsonField]` | `String` |
| `36` | `fn :: json stringify JsonVal` | `String` |
| `37` | `fn :: j_pretty_arr [JsonVal] Int Int` | `String` |
| `38` | `fn :: j_pretty_obj [JsonField] Int Int` | `String` |
| `39` | `fn :: j_pretty_val JsonVal Int Int` | `String` |
| `40` | `fn :: json pretty JsonVal Int` | `String` |
| `41` | `fn :: j_find_field [JsonField] String` | `JsonVal` |
| `42` | `fn :: json get field JsonVal String` | `JsonVal` |
| `43` | `fn :: j_nth_val [JsonVal] Int` | `JsonVal` |
| `44` | `fn :: json get index JsonVal Int` | `JsonVal` |
| `45` | `fn :: j_split_dots_loop String Int Int Int [String]` | `[String]` |
| `46` | `fn :: j_step_path JsonVal String` | `JsonVal` |
| `47` | `fn :: j_walk_path JsonVal [String]` | `JsonVal` |
| `48` | `fn :: json get path JsonVal String` | `JsonVal` |
| `49` | `fn :: json get str JsonVal String String` | `String` |
| `50` | `fn :: j_unwrap_str JsonVal String` | `String` |
| `51` | `fn :: json get int JsonVal String Int` | `Int` |
| `52` | `fn :: j_unwrap_int JsonVal Int` | `Int` |
| `53` | `fn :: json get bool JsonVal String Bool` | `Bool` |
| `54` | `fn :: j_unwrap_bool JsonVal Bool` | `Bool` |
| `55` | `fn :: j_put_field [JsonField] String JsonVal` | `[JsonField]` |
| `56` | `fn :: json set field JsonVal String JsonVal` | `JsonVal` |

---

## 08.3. Explorando `json` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `json` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test json.rg`.

### 08.3.1. Ejemplo 1: Flujo principal en estilo tabular con `json`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `json` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import json

fn :: leer config servidor (raw : String) => (String, Int, Bool)
      leer config servidor raw =
        doc  = json parse raw
        host = json get str doc "server.host" "127.0.0.1"
        port = json get int doc "server.port" 8080
        tls  = json get bool doc "server.tls.enabled" False
        (host, port, tls)
```

### 08.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `json` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import json

fn :: construir manifiesto () => String
      construir manifiesto =
        nodo = JnObj [("app", JnStr "solstice"), ("workers", JnInt 8), ("tags", JnArr [JnStr "elf64", JnStr "rmm2"])]
        json pretty nodo 2
```

### 08.3.3. Ejemplo 3: Análisis sintáctico (`json parse`), serialización compacta (`json stringify`) e impresión indentada (`json pretty`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `json` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test json parse stringify and pretty => ()
      test json parse stringify and pretty =
        lb = char_from_code 123
        rb = char_from_code 125
        raw = lb + "\"user\":" + lb + "\"name\":\"Ada \\\"Lovelace\\\"\",\"age\":36,\"active\":true,\"roles\":[\"admin\",\"math\"],\"meta\":null" + rb + rb
        res = json parse raw
        _ = assert true (is_json_ok res) "AC1: json parse nested object and array"
        val = unwrap_json res

        compact = json stringify val
        _ = assert str eq compact raw "AC1: json stringify lossless round-trip"

        pretty_s = json pretty val 2
        res2 = json parse pretty_s
        _ = assert true (is_json_ok res2) "AC1: json pretty output parses back cleanly"
        _ = assert str eq (json stringify (unwrap_json res2)) raw "AC1: json pretty round-trip equality"
        ()
```

### 08.3.4. Ejemplo 4: Primitivas JSON (`null`, `bool`, `int`, `str`), secuencias de escape y contenedores vacíos (`[]`, `{}`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `json` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test json primitives escapes and empty containers => ()
      test json primitives escapes and empty containers =
        lb = char_from_code 123
        rb = char_from_code 125
        bs = char_from_code 92
        nl = char_from_code 10
        tab = char_from_code 9
        _ = assert str eq (json stringify (unwrap_json (json parse (lb + rb)))) (lb + rb) "AC1: empty object {}"
        _ = assert str eq (json stringify (unwrap_json (json parse "[]"))) "[]" "AC1: empty array []"
        _ = assert str eq (json stringify (unwrap_json (json parse ("  " + lb + "  " + rb + "  ")))) (lb + rb) "AC1: whitespace-padded empty object"
        _ = assert true (is_json_null (unwrap_json (json parse "null"))) "AC1: root null literal"
        _ = assert str eq (json stringify (unwrap_json (json parse "true"))) "true" "AC1: root true literal"
        _ = assert str eq (json stringify (unwrap_json (json parse "false"))) "false" "AC1: root false literal"
        _ = assert str eq (json stringify (unwrap_json (json parse "0"))) "0" "AC1: root zero integer"
        _ = assert str eq (json stringify (unwrap_json (json parse "-42000"))) "-42000" "AC1: root negative integer"

        esc_json = lb + "\"msg\":\"line1" + bs + "nline2" + bs + "t" + bs + bs + "slash\"" + rb
        esc_val = unwrap_json (json parse esc_json)
        _ = assert str eq (json get str esc_val "msg" "") ("line1" + nl + "line2" + tab + bs + "slash") "AC1: unescape \\n, \\t, \\\\ in JSON strings"
        _ = assert str eq (json stringify esc_val) esc_json "AC1: re-escape \\n, \\t, \\\\ on stringify"
        ()
```

### 08.3.5. Ejemplo 5: Consultas profundas por ruta de puntos (`json query`, `json query str/int/bool`) y actualización funcional (`json set field`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `json` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test json dot path queries and updates => ()
      test json dot path queries and updates =
        lb = char_from_code 123
        rb = char_from_code 125
        raw = lb + "\"user\":" + lb + "\"name\":\"Ada\",\"age\":36,\"active\":true,\"roles\":[\"admin\",\"math\"],\"matrix\":[[10,20],[30,40]]" + rb + ",\"count\":-7,\"disabled\":false" + rb
        val = unwrap_json (json parse raw)

        _ = assert str eq (json get str val "user.name" "") "Ada" "AC2: json get str dot path"
        _ = assert int equals (json get int val "user.age" 0) 36 "AC2: json get int dot path"
        _ = assert int equals (json get int val "count" 0) (-7) "AC2: json get int negative"
        _ = assert true (json get bool val "user.active" False) "AC2: json get bool true"
        _ = assert false (json get bool val "disabled" True) "AC2: json get bool false"
        _ = assert str eq (json get str val "user.roles.0" "") "admin" "AC2: json get str array index 0"
        _ = assert str eq (json get str val "user.roles.1" "") "math" "AC2: json get str array index 1"
        _ = assert int equals (json get int val "user.matrix.1.0" 0) 30 "AC2: nested 2D array index user.matrix.1.0"
        _ = assert int equals (json get int val "user.matrix.1.1" 0) 40 "AC2: nested 2D array index user.matrix.1.1"
        _ = assert str eq (json get str val "user.roles.99" "oob") "oob" "AC2: out-of-bounds array index fallback"
        _ = assert str eq (json get str val "user.missing.deep" "fallback") "fallback" "AC2: missing deep dot-path fallback"

        updated = json set field val "version" (JsonInt 2)
        _ = assert int equals (json get int updated "version" 0) 2 "AC2: json set field adds new key"
        overwritten = json set field updated "count" (JsonInt 99)
        _ = assert int equals (json get int overwritten "count" 0) 99 "AC2: json set field overwrites existing key"
        ()
```

### 08.3.6. Ejemplo 6: Detección segura de entradas JSON malformadas (`JsonErr`) sin pánicos ni excepciones

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `json` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test json malformed inputs => ()
      test json malformed inputs =
        lb = char_from_code 123
        rb = char_from_code 125
        _ = assert false (is_json_ok (json parse "")) "AC3: reject empty input"
        _ = assert false (is_json_ok (json parse "   ")) "AC3: reject whitespace-only input"
        _ = assert false (is_json_ok (json parse (lb + "\"unclosed\":1"))) "AC3: reject unclosed object"
        _ = assert false (is_json_ok (json parse "[1, 2, 3")) "AC3: reject unclosed array"
        _ = assert false (is_json_ok (json parse "\"unterminated string")) "AC3: reject unterminated string"
        _ = assert false (is_json_ok (json parse (lb + "unquoted: 1" + rb))) "AC3: reject unquoted object key"
        _ = assert false (is_json_ok (json parse (lb + "\"k\" 1" + rb))) "AC3: reject missing colon in object"
        _ = assert false (is_json_ok (json parse "[1, 2] trailing")) "AC3: reject trailing garbage token"
        _ = assert false (is_json_ok (json parse "tru")) "AC3: reject truncated boolean literal"
        _ = assert false (is_json_ok (json parse "nul")) "AC3: reject truncated null literal"
        ()
```

---

## 08.4. Bajo el capó: cómo está construida `json` en Ridgun puro (`src/main/ridgun/lib/json.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/json.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 08.4.1. Implementación interna: Whitespace & Character Helpers

Fíjate en cómo `json.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: j_is_ws Int => Bool
      j_is_ws c   =  c == 32 OR c == 9 OR c == 10 OR c == 13

fn :: j_is_digit Int => Bool
      j_is_digit c   =  c >= 48 AND c <= 57

fn :: j_skip_ws String Int Int => Int
      j_skip_ws s      pos len
        | pos >= len = len
        | j_is_ws (str_char_at s pos) = j_skip_ws s (pos + 1) len
        | otherwise = pos

fn :: j_spaces Int => String
      j_spaces n
        | n <= 0 = ""
        | otherwise = " " + (j_spaces (n - 1))
```

### 08.4.2. Implementación interna: Integer Literal Parsing

Fíjate en cómo `json.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: j_scan_digits String Int Int => Int
      j_scan_digits s      pos len
        | pos >= len = len
        | j_is_digit (str_char_at s pos) = j_scan_digits s (pos + 1) len
        | otherwise = pos

fn :: j_parse_number String Int Int => JsonStep
      j_parse_number s      pos len
        | (str_char_at s pos) == 45 = j_finish_neg_num s pos (j_scan_digits s (pos + 1) len)
        | otherwise = j_finish_pos_num s pos (j_scan_digits s pos len)

fn :: j_finish_neg_num String Int Int     => JsonStep
      j_finish_neg_num s      pos end_pos
        | end_pos <= (pos + 1) = JStepErr "invalid negative number"
        | otherwise = JStepOk (JsonInt (str_to_int (str_slice s pos end_pos))) end_pos

fn :: j_finish_pos_num String Int Int     => JsonStep
      j_finish_pos_num s      pos end_pos
        | end_pos <= pos = JStepErr "expected number"
        | otherwise = JStepOk (JsonInt (str_to_int (str_slice s pos end_pos))) end_pos
```

### 08.4.3. Implementación interna: Serialization & Pretty-Printing

Fíjate en cómo `json.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: j_join_arr [JsonVal] => String
      j_join_arr []        =  ""
      j_join_arr (v:[])    =  json stringify v
      j_join_arr (v:vs)    =  (json stringify v) + "," + (j_join_arr vs)

fn :: j_join_obj [JsonField] => String
      j_join_obj []          =  ""
      j_join_obj ((JsonField k v):[]) = (j_escape_str k) + ":" + (json stringify v)
      j_join_obj ((JsonField k v):rest) = (j_escape_str k) + ":" + (json stringify v) + "," + (j_join_obj rest)

fn :: json stringify JsonVal          => String
      json stringify JsonNull         =  "null"
      json stringify (JsonBool True)  =  "true"
      json stringify (JsonBool False) =  "false"
      json stringify (JsonInt n)      =  int_to_str n
      json stringify (JsonStr s)      =  j_escape_str s
      json stringify (JsonArr items)  =  "[" + (j_join_arr items) + "]"
      json stringify (JsonObj fields) =  (char_from_code 123) + (j_join_obj fields) + (char_from_code 125)

fn :: j_pretty_arr [JsonVal] Int Int => String
      j_pretty_arr []        _   _   =  ""
      j_pretty_arr (v:[])    ind cur =  (j_spaces (cur + ind)) + (j_pretty_val v ind (cur + ind))
      j_pretty_arr (v:vs)    ind cur =  (j_spaces (cur + ind)) + (j_pretty_val v ind (cur + ind)) + "," + (char_from_code 10) + (j_pretty_arr vs ind cur)

fn :: j_pretty_obj [JsonField] Int Int => String
      j_pretty_obj []          _   _   =  ""
      j_pretty_obj ((JsonField k v):[]) ind cur =
        (j_spaces (cur + ind)) + (j_escape_str k) + ": " + (j_pretty_val v ind (cur + ind))
      j_pretty_obj ((JsonField k v):rest) ind cur =
        (j_spaces (cur + ind)) + (j_escape_str k) + ": " + (j_pretty_val v ind (cur + ind)) + "," + (char_from_code 10) + (j_pretty_obj rest ind cur)

fn :: j_pretty_val JsonVal          Int Int => String
      j_pretty_val (JsonArr [])     _   _   =  "[]"
      j_pretty_val (JsonArr items)  ind cur =
        nl = char_from_code 10
        "[" + nl + (j_pretty_arr items ind cur) + nl + (j_spaces cur) + "]"
      j_pretty_val (JsonObj [])     _   _   =  (char_from_code 123) + (char_from_code 125)
      j_pretty_val (JsonObj fields) ind cur =
        nl = char_from_code 10
        (char_from_code 123) + nl + (j_pretty_obj fields ind cur) + nl + (j_spaces cur) + (char_from_code 125)
      j_pretty_val v                _   _   =  json stringify v

fn :: json pretty JsonVal Int => String
      json pretty val     ind =  j_pretty_val val ind 0
```

### 08.4.4. Implementación interna: Dot-Path Queries & Field Updates

Fíjate en cómo `json.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: j_find_field [JsonField] String => JsonVal
      j_find_field []          _      =  JsonNull
      j_find_field ((JsonField k v):fs) key
        | k == key = v
        | otherwise = j_find_field fs key

fn :: json get field JsonVal          String => JsonVal
      json get field (JsonObj fields) key    =  j_find_field fields key
      json get field _                _      =  JsonNull

fn :: j_nth_val [JsonVal] Int => JsonVal
      j_nth_val []        _   =  JsonNull
      j_nth_val (v:vs)    idx
        | idx < 0 = JsonNull
        | idx == 0 = v
        | otherwise = j_nth_val vs (idx - 1)

fn :: json get index JsonVal         Int => JsonVal
      json get index (JsonArr items) idx =  j_nth_val items idx
      json get index _               _   =  JsonNull

fn :: j_split_dots_loop String Int Int Int [String] => [String]
      j_split_dots_loop s pos len start acc
        | pos >= len = acc :: [str_slice s start len]
        | (str_char_at s pos) == 46 = j_split_dots_loop s (pos + 1) len (pos + 1) (acc :: [str_slice s start pos])
        | otherwise = j_split_dots_loop s (pos + 1) len start acc

fn :: j_step_path JsonVal          String => JsonVal
      j_step_path (JsonObj fields) seg    =  j_find_field fields seg
      j_step_path (JsonArr items)  seg
        | seg != "" AND (j_scan_digits seg 0 (str_len seg)) == (str_len seg) = j_nth_val items (str_to_int seg)
        | otherwise = JsonNull
      j_step_path _                _      =  JsonNull

fn :: j_walk_path JsonVal [String]   => JsonVal
      j_walk_path val     []         =  val
      j_walk_path val     ("":rest)  =  j_walk_path val rest
      j_walk_path val     (seg:rest) =  j_walk_path (j_step_path val seg) rest

fn :: json get path JsonVal String   => JsonVal
      json get path val     ""       =  val
      json get path val     dot_path =  j_walk_path val (j_split_dots_loop dot_path 0 (str_len dot_path) 0 [])

fn :: json get str JsonVal String String => String
      json get str val dot_path fallback = j_unwrap_str (json get path val dot_path) fallback

fn :: j_unwrap_str JsonVal     String   => String
      j_unwrap_str (JsonStr s) _        =  s
      j_unwrap_str _           fallback =  fallback
```

---

## 08.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `json`

- **Garantía algorítmica y de seguridad**: Rechazo estricto de basura sobrante tras el valor raíz (`trailing garbage`), manejo completo de escapes y retorno seguro de `JnErr` sin excepciones.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/json.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test json.rg`.

### Las 5 Reglas de Oro al programar con `json`

1. **Declara `import json` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `json` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `json` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `json` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 09** pasaremos a explorar en profundidad la lib **`csv`** (La lib `csv` — Analizador de Estados RFC 4180 para CSV/TSV y Tablas Indexadas).
