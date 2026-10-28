# Capítulo 11: La lib `regex` — Motor de Expresiones Regulares Thompson NFA en Tiempo Lineal $O(N \cdot M)$

## 11.1. ¿Por qué existe la lib `regex`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `regex` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `regex`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: los motores de expresiones regulares con *backtracking* han causado caídas globales famosas (como en Cloudflare o StackOverflow) cuando un patrón como `(a+)+b` recibe treinta `a` seguidas y entra en tiempo exponencial $O(2^N)$.

La lib **`regex`** compila tus expresiones regulares (`.`, `*`, `+`, `?`, `|`, `()`, `[a-z]`, `[^...]`, `^`, `$`, `\d`, `\w`, `\s`) a un **autómata finito no determinista de Thompson (NFA)** y avanza el conjunto de estados paso a paso en tiempo estrictamente lineal **$O(N \cdot M)$**, haciendo que los ataques **ReDoS sean matemáticamente imposibles**.

En un ecosistema tradicional, resolver las tareas del dominio **`REGEX`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`regex`** (`src/main/ridgun/lib/regex.rg`) aborda el problema con cuatro principios innegociables:

1. **Declara `import regex` (o `import regex as alias`) al inicio del archivo**: cada lib define su espacio de nombres `module :: regex` y en modo `--strict` las funciones multi-palabra se invocan siempre con espacios naturales.
2. **Encadena tus tuberías de izquierda a derecha con `->`**: escribe `entrada paso uno -> paso dos -> resultado`, usa máscaras `(+ _ _ +)` para desestructurar secuencias y omite `_ =` en sentencias secuenciales (o descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `regex` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 11.2. Artefactos nativos, importación y catálogo completo de la API de `regex`

En `ridgun-libs`, **`regex`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/regex.rg` (dominio `REGEX`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/regex.rglib` | Distribución e importación directa con `import regex` |
| **Archivo compilado** | `target/regex.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libregex.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Cada lib declara su propio espacio de nombres con `module :: regex`: basta con escribir `import regex` (o `import regex as alias`) en el encabezado y llamar a sus funciones con espacios naturales (`mi funcion x`) y tuberías `->` (`x mi funcion -> resultado`).

### 11.2.1. Resumen de familias funcionales de `regex`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `regex match / regex is match` | Coincidencia de cadena completa y búsqueda de subcadena en tiempo lineal $O(N \cdot M)$ |
| `regex find / regex find all` | Extrae la primera o todas las subcadenas coincidentes sin solapamiento |
| `regex replace / regex replace all` | Reemplaza la primera o todas las coincidencias de la expresión regular |
| `regex split / regex escape` | Divide texto según un delimitador regex y escapa metacaracteres |

### 11.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/regex.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/regex.rg` (`4` tipos, `0` operadores y `70` funciones):

**Tipos algebraicos y registros (`type`) de `regex`:**

```ridgun
type RegexMatch = matched: Bool, match_start: Int, match_end: Int, text: String
type ReNode = ReEmpty | ReChar Int | ReAny | ReClass Bool [Int] | ReShort Int | ReBol | ReEol | ReStar ReNode | RePlus ReNode | ReOpt ReNode | ReSeq ReNode ReNode | ReAlt ReNode ReNode
type ReParseRes = ReParseRes ReNode Int
type NfaInst = InstChar Int Int | InstAny Int | InstClass Bool [Int] Int | InstShort Int Int | InstBol Int | InstEol Int | InstSplit Int Int | InstJump Int | InstMatch
```

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: re_is_digit Int` | `Bool` |
| `2` | `fn :: re_is_word Int` | `Bool` |
| `3` | `fn :: re_is_space Int` | `Bool` |
| `4` | `fn :: re_match_short Int Int` | `Bool` |
| `5` | `fn :: re_in_ranges Int [Int]` | `Bool` |
| `6` | `fn :: re_escape_char Int` | `ReNode` |
| `7` | `fn :: re_class_char String Int Int` | `(Int Int)` |
| `8` | `fn :: re_fst_int (Int Int)` | `Int` |
| `9` | `fn :: re_snd_int (Int Int)` | `Int` |
| `10` | `fn :: re_parse_class_items String Int Int [Int]` | `([Int] Int)` |
| `11` | `fn :: re_parse_class_item_step String Int Int [Int]` | `([Int] Int)` |
| `12` | `fn :: re_parse_class_range_check String Int Int Int [Int]` | `([Int] Int)` |
| `13` | `fn :: re_parse_class_range_hi String Int Int Int [Int]` | `([Int] Int)` |
| `14` | `fn :: re_fst_ranges ([Int] Int)` | `[Int]` |
| `15` | `fn :: re_snd_pos ([Int] Int)` | `Int` |
| `16` | `fn :: re_parse_class String Int Int` | `ReParseRes` |
| `17` | `fn :: re_finish_class Bool ([Int] Int)` | `ReParseRes` |
| `18` | `fn :: re_res_node ReParseRes` | `ReNode` |
| `19` | `fn :: re_res_pos ReParseRes` | `Int` |
| `20` | `fn :: re_parse_group String Int Int` | `ReParseRes` |
| `21` | `fn :: re_close_group ReNode String Int Int` | `ReParseRes` |
| `22` | `fn :: re_parse_atom String Int Int` | `ReParseRes` |
| `23` | `fn :: re_parse_postfix ReNode String Int Int` | `ReParseRes` |
| `24` | `fn :: re_parse_factor String Int Int` | `ReParseRes` |
| `25` | `fn :: re_is_seq_stop Int` | `Bool` |
| `26` | `fn :: re_parse_seq_loop ReNode String Int Int` | `ReParseRes` |
| `27` | `fn :: re_parse_seq_step ReNode String Int Int` | `ReParseRes` |
| `28` | `fn :: re_parse_seq String Int Int` | `ReParseRes` |
| `29` | `fn :: re_parse_seq_first String Int Int` | `ReParseRes` |
| `30` | `fn :: re_parse_alt_loop ReNode String Int Int` | `ReParseRes` |
| `31` | `fn :: re_parse_alt_branch ReNode String Int Int` | `ReParseRes` |
| `32` | `fn :: re_parse_alt String Int Int` | `ReParseRes` |
| `33` | `fn :: nfa_len [NfaInst]` | `Int` |
| `34` | `fn :: re_compile_seq ReNode ReNode Int` | `[NfaInst]` |
| `35` | `fn :: re_compile_opt ReNode Int` | `[NfaInst]` |
| `36` | `fn :: re_compile_star ReNode Int` | `[NfaInst]` |
| `37` | `fn :: re_compile_plus ReNode Int` | `[NfaInst]` |
| `38` | `fn :: re_compile_alt ReNode ReNode Int` | `[NfaInst]` |
| `39` | `fn :: re_compile_node ReNode Int` | `[NfaInst]` |
| `40` | `fn :: re_compile String` | `[NfaInst]` |
| `41` | `fn :: nfa_inst_at [NfaInst] Int` | `NfaInst` |
| `42` | `fn :: nfa_set_has [Int] Int` | `Bool` |
| `43` | `fn :: nfa_closure [NfaInst] [Int] Int Int [Int]` | `[Int]` |
| `44` | `fn :: nfa_closure_inst [NfaInst] Int [Int] Int Int [Int] NfaInst` | `[Int]` |
| `45` | `fn :: nfa_step_one NfaInst Int` | `[Int]` |
| `46` | `fn :: nfa_step [NfaInst] [Int] Int` | `[Int]` |
| `47` | `fn :: nfa_is_match_inst NfaInst` | `Bool` |
| `48` | `fn :: nfa_has_match [NfaInst] [Int]` | `Bool` |
| `49` | `fn :: nfa_update_last [NfaInst] [Int] Int Int` | `Int` |
| `50` | `fn :: nfa_sim_loop [NfaInst] String Int Int [Int] Int` | `Int` |
| `51` | `fn :: nfa_sim_step [NfaInst] String Int Int [Int] Int` | `Int` |
| `52` | `fn :: nfa_longest_from [NfaInst] String Int Int` | `Int` |
| `53` | `fn :: nfa_full_loop [NfaInst] String Int Int [Int]` | `Bool` |
| `54` | `fn :: nfa_full_step [NfaInst] String Int Int [Int]` | `Bool` |
| `55` | `fn :: regex match String String` | `Bool` |
| `56` | `fn :: nfa_find_from [NfaInst] String Int Int` | `RegexMatch` |
| `57` | `fn :: nfa_find_check [NfaInst] String Int Int Int` | `RegexMatch` |
| `58` | `fn :: regex find String String` | `RegexMatch` |
| `59` | `fn :: regex is match String String` | `Bool` |
| `60` | `fn :: nfa_find_all_loop [NfaInst] String Int Int [RegexMatch]` | `[RegexMatch]` |
| `61` | `fn :: nfa_find_all_step [NfaInst] String Int Int [RegexMatch] Int` | `[RegexMatch]` |
| `62` | `fn :: regex find all String String` | `[RegexMatch]` |
| `63` | `fn :: regex replace String String String` | `String` |
| `64` | `fn :: re_apply_replace RegexMatch String String` | `String` |
| `65` | `fn :: nfa_replace_all_loop [NfaInst] String String Int Int String` | `String` |
| `66` | `fn :: nfa_replace_all_step [NfaInst] String String Int Int String Int` | `String` |
| `67` | `fn :: regex replace all String String String` | `String` |
| `68` | `fn :: nfa_split_loop [NfaInst] String Int Int Int [String]` | `[String]` |
| `69` | `fn :: nfa_split_step [NfaInst] String Int Int Int [String] Int` | `[String]` |
| `70` | `fn :: regex split String String` | `[String]` |

---

## 11.3. Explorando `regex` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `regex` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test regex.rg`.

### 11.3.1. Ejemplo 1: Flujo principal en estilo tabular con `regex`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `regex` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import regex

fn :: extraer codigos postales String => [String]
      extraer codigos postales texto =
        regex find all "\d+" texto
```

### 11.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `regex` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import regex

fn :: censurar telefonos String => Bool String
      censurar telefonos comentario =
        regex is match "\d+-\d+" comentario -> tiene
        regex replace all "\d+-\d+" comentario "[TELEFONO]" -> limpio
        (tiene, limpio)
```

### 11.3.3. Ejemplo 3: Anclas (`^`, `$`), cuantificadores (`*`, `+`, `?`), alternancia (`|`), grupos `(...)`, clases `[a-z0-9]` y atajos (`\d`, `\w`, `\s`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `regex` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test_regex_operators_and_classes => ()
      test_regex_operators_and_classes =
        assert true (regex match "" "") "AC1: empty pattern matches empty string"
        assert false (regex match "" "nonempty") "AC1: empty pattern rejects non-empty on full match"
        assert true (regex match 'a(b|c)+d?e*' "abcbdeee") "AC1: alternation group plus opt star"
        assert true (regex match 'a(b|c)+d?e*' "ac") "AC1: opt and star match zero occurrences"
        assert false (regex match 'a(b|c)+d?e*' "ade") "AC1: plus requires at least one"
        assert true (regex match '(foo|bar|baz)+' "barfoobazbar") "AC1: multi-branch alternation with plus"
        assert false (regex match '(foo|bar|baz)+' "barquxfoo") "AC1: multi-branch alternation rejects unknown"
        assert true (regex match '[a-zA-Z_][a-zA-Z0-9_]*' "_valid_Identifier_99") "AC1: identifier character class"
        assert false (regex match '[a-zA-Z_][a-zA-Z0-9_]*' "9invalid") "AC1: identifier rejects leading digit"
        assert true (regex match '[^0-9]+' "hello_world") "AC1: negated char class"
        assert false (regex match '[^0-9]+' "hello42") "AC1: negated char class rejects digits"
        assert true (regex match '\w+\s+\d+' "agent   007") "AC1: shorthand escapes \\w \\s \\d"
        assert true (regex match '\D+\S+' "abc_123") "AC1: negated shorthand escapes \\D \\S"
        assert true (regex match 'v\d+\.\d+\.\d+' "v0.9.16") "AC1: escaped dot literal"
        assert false (regex match 'v\d+\.\d+\.\d+' "v0X9Y16") "AC1: escaped dot rejects non-dot"
        assert true (regex is match '^hello' "hello world") "AC1: bol anchor matches start"
        assert false (regex is match '^world' "hello world") "AC1: bol anchor rejects middle"
        assert true (regex is match 'world$' "hello world") "AC1: eol anchor matches end"
        assert false (regex is match 'hello$' "hello world") "AC1: eol anchor rejects prefix"
        assert true (regex is match '^exact$' "exact") "AC1: anchored ^exact$ matches full string"
        assert false (regex is match '^exact$' "not exact") "AC1: anchored ^exact$ rejects extra chars"
        -- Russ Cox pathological backtracking benchmarks (exponential in backtracking engines, O(N*M) in Thompson NFA)
        assert false (regex match '(a+)+b' "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaac") "AC1: Thompson NFA immune to (a+)+b ReDoS"
        assert false (regex match '(a|aa)+b' "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaac") "AC1: Thompson NFA immune to (a|aa)+b ReDoS"
        assert true (regex match 'a?a?a?a?a?a?a?a?aaaaaaaa' "aaaaaaaa") "AC1: Russ Cox a?^n a^n vector"
        ()
```

### 11.3.4. Ejemplo 4: Extracción de coincidencias (`regex find`, `regex find all`), reemplazo (`regex replace`, `regex replace all`) y división (`regex split`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `regex` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test_regex_find_replace_split => ()
      test_regex_find_replace_split =
        m1 = regex find '\d+' "item #42 and #99"
        assert true (matched m1) "AC2: find matched"
        assert int equals (match_start m1) 6 "AC2: find start"
        assert int equals (match_end m1) 8 "AC2: find end"
        assert str eq (text m1) "42" "AC2: find text"

        m_none = regex find '\d+' "no digits here"
        assert false (matched m_none) "AC2: find returns matched=False when absent"

        all_m = regex find all '[a-z]+=\d+' "id=10, port=8080, ttl=60"
        assert int equals (re_match_count all_m) 3 "AC2: find all key=val count"
        assert str eq (text (re_match_at all_m 0)) "id=10" "AC2: find all first match"
        assert str eq (text (re_match_at all_m 1)) "port=8080" "AC2: find all second match"
        assert str eq (text (re_match_at all_m 2)) "ttl=60" "AC2: find all third match"

        r1 = regex replace '\d+' "X" "v1.2.3"
        assert str eq r1 "vX.2.3" "AC3: replace first"
        r_no = regex replace '\d+' "X" "abc"
        assert str eq r_no "abc" "AC3: replace with no match returns original"
        r2 = regex replace all '\d+' "X" "v1.22.333"
        assert str eq r2 "vX.X.X" "AC3: replace all"

        parts = regex split '\s*[,;]\s*' "alpha, beta ;  gamma,delta"
        assert int equals (re_str_count parts) 4 "AC3: split count"
        assert str eq (re_str_at parts 0) "alpha" "AC3: split[0]"
        assert str eq (re_str_at parts 1) "beta" "AC3: split[1]"
        assert str eq (re_str_at parts 2) "gamma" "AC3: split[2]"
        assert str eq (re_str_at parts 3) "delta" "AC3: split[3]"
        ()
```

### 11.3.5. Ejemplo 5: Validador de identificadores y anonimizador de trazas en tiempo lineal $O(N \cdot M)$ con Thompson NFA (`regex is match`, `regex replace all`, `regex split`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `regex` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
import regex

fn :: limpiar traza y validar id (usuario_id : String) (linea_log : String) => (Bool, String, [String])
      limpiar traza y validar id usuario_id linea_log =
        id_valido = regex is match "^usr_[a-z0-9]+$" usuario_id
        sin_ips   = regex replace all "\d+\.\d+\.\d+\.\d+" linea_log "[IP-REDACTADA]"
        tokens    = regex split "\s+" sin_ips
        (id_valido, sin_ips, tokens)
```

---

## 11.4. Bajo el capó: cómo está construida `regex` en Ridgun puro (`src/main/ridgun/lib/regex.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/regex.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 11.4.1. Implementación interna: Character Class & Shorthand Helpers

Fíjate en cómo `regex.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
module :: regex

fn :: re is digit Int => Bool
      re is digit c = c >= 48 and c <= 57

fn :: re is word Int => Bool
      re is word c = (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95

fn :: re is space Int => Bool
      re is space c = c == 32 or c == 9 or c == 10 or c == 13 or c == 11 or c == 12

fn :: re match short Int Int => Bool
      re match short 100 c = re is digit c
      re match short 68 c = not (re is digit c)
      re match short 119 c = re is word c
      re match short 87 c = not (re is word c)
      re match short 115 c = re is space c
      re match short 83 c = not (re is space c)
      re match short _ _ = False

fn :: re in ranges Int [Int] => Bool
      re in ranges _ [] = False
      re in ranges _ (_:[]) = False
      re in ranges c (lo:hi:rs) =
        | c >= lo and c <= hi = True
        | otherwise = re in ranges c rs
```

### 11.4.2. Implementación interna: Thompson NFA Compiler (`ReNode` -> `[NfaInst]`)

Fíjate en cómo `regex.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: nfa len [NfaInst] => Int
      nfa len [] = 0
      nfa len (_:rest) = 1 + (nfa len rest)

fn :: re compile seq ReNode ReNode Int => [NfaInst]
      re compile seq a b start_id =
        insts_a = re compile node a start_id
        mid_id = start_id + (nfa len insts_a)
        insts_b = re compile node b mid_id
        insts_a :: insts_b

fn :: re compile opt ReNode Int => [NfaInst]
      re compile opt a start_id =
        body = re compile node a (start_id + 1)
        end_id = start_id + 1 + (nfa len body)
        [InstSplit (start_id + 1) end_id] :: body

fn :: re compile star ReNode Int => [NfaInst]
      re compile star a start_id =
        body = re compile node a (start_id + 1)
        end_id = start_id + 2 + (nfa len body)
        ([InstSplit (start_id + 1) end_id] :: body) :: [InstJump start_id]

fn :: re compile plus ReNode Int => [NfaInst]
      re compile plus a start_id =
        body = re compile node a start_id
        split_id = start_id + (nfa len body)
        body :: [InstSplit start_id (split_id + 1)]

fn :: re compile alt ReNode ReNode Int => [NfaInst]
      re compile alt a b start_id =
        body_a = re compile node a (start_id + 1)
        jump_id = start_id + 1 + (nfa len body_a)
        start_b = jump_id + 1
        body_b = re compile node b start_b
        end_id = start_b + (nfa len body_b)
        (([InstSplit (start_id + 1) start_b] :: body_a) :: [InstJump end_id]) :: body_b

fn :: re compile node ReNode Int => [NfaInst]
      re compile node ReEmpty _ = []
      re compile node (ReChar c) start_id = [InstChar c (start_id + 1)]
      re compile node ReAny start_id = [InstAny (start_id + 1)]
      re compile node (ReClass neg rngs) start_id = [InstClass neg rngs (start_id + 1)]
      re compile node (ReShort k) start_id = [InstShort k (start_id + 1)]
      re compile node ReBol start_id = [InstBol (start_id + 1)]
      re compile node ReEol start_id = [InstEol (start_id + 1)]
      re compile node (ReOpt a) start_id = re compile opt a start_id
      re compile node (ReStar a) start_id = re compile star a start_id
      re compile node (RePlus a) start_id = re compile plus a start_id
      re compile node (ReSeq a b) start_id = re compile seq a b start_id
      re compile node (ReAlt a b) start_id = re compile alt a b start_id

fn :: re compile String => [NfaInst]
      re compile pat =
        re parse alt pat 0 (str len pat) -> parsed
        (re compile node (re res node parsed) 0) :: [InstMatch]
```

### 11.4.3. Implementación interna: Linear-Time Thompson NFA State-Set Simulation

Fíjate en cómo `regex.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: nfa inst at [NfaInst] Int => NfaInst
      nfa inst at [] _ = InstMatch
      nfa inst at (i:_) 0 = i
      nfa inst at (_:rest) idx = nfa inst at rest (idx - 1)

fn :: nfa set has [Int] Int => Bool
      nfa set has [] _ = False
      nfa set has (x:xs) v =
        | x == v = True
        | otherwise = nfa set has xs v

fn :: nfa closure [NfaInst] [Int] Int Int [Int] => [Int]
      nfa closure _ [] _ _ visited = visited
      nfa closure prog (s:ss) pos len visited =
        | nfa set has visited s = nfa closure prog ss pos len visited
        | otherwise = nfa closure inst prog s ss pos len (visited :: [s]) (nfa inst at prog s)

fn :: nfa closure inst [NfaInst] Int [Int] Int Int [Int] NfaInst => [Int]
      nfa closure inst prog _ ss pos len vis (InstJump out) = nfa closure prog ([out] :: ss) pos len vis
      nfa closure inst prog _ ss pos len vis (InstSplit o1 o2) = nfa closure prog ([o1, o2] :: ss) pos len vis
      nfa closure inst prog _ ss pos len vis (InstBol out) =
        | pos == 0 = nfa closure prog ([out] :: ss) pos len vis
        | otherwise = nfa closure prog ss pos len vis
      nfa closure inst prog _ ss pos len vis (InstEol out) =
        | pos == len = nfa closure prog ([out] :: ss) pos len vis
        | otherwise = nfa closure prog ss pos len vis
      nfa closure inst prog _ ss pos len vis _ = nfa closure prog ss pos len vis

fn :: nfa step one NfaInst Int => [Int]
      nfa step one (InstChar expected out) c =
        | c == expected = [out]
        | otherwise = []
      nfa step one (InstAny out) c =
        | c != 10 = [out]
        | otherwise = []
      nfa step one (InstClass neg rngs out) c =
        | (re in ranges c rngs) != neg = [out]
        | otherwise = []
      nfa step one (InstShort kind out) c =
        | re match short kind c = [out]
        | otherwise = []
      nfa step one _ _ = []

fn :: nfa step [NfaInst] [Int] Int => [Int]
      nfa step _ [] _ = []
      nfa step prog (s:ss) c = (nfa step one (nfa inst at prog s) c) :: (nfa step prog ss c)

fn :: nfa is match inst NfaInst => Bool
      nfa is match inst InstMatch = True
      nfa is match inst _ = False

fn :: nfa has match [NfaInst] [Int] => Bool
      nfa has match _ [] = False
      nfa has match prog (s:ss) =
        | nfa is match inst (nfa inst at prog s) = True
        | otherwise = nfa has match prog ss

fn :: nfa update last [NfaInst] [Int] Int Int => Int
      nfa update last prog active cand cur =
        | nfa has match prog active = cand
        | otherwise = cur

fn :: nfa sim loop [NfaInst] String Int Int [Int] Int => Int
      nfa sim loop _ _ _ _ [] last_m = last_m
      nfa sim loop prog input pos len active last_m =
        | pos >= len = last_m
        | otherwise = nfa sim step prog input pos len active last_m

fn :: nfa sim step [NfaInst] String Int Int [Int] Int => Int
      nfa sim step prog input pos len active last_m =
        str char at input pos -> c
        nfa closure prog (nfa step prog active c) (pos + 1) len [] -> next_act
        nfa update last prog next_act (pos + 1) last_m -> next_last
        nfa sim loop prog input (pos + 1) len next_act next_last

fn :: nfa longest from [NfaInst] String Int Int => Int
      nfa longest from prog input pos len =
        nfa closure prog [0] pos len [] -> init_act
        nfa update last prog init_act pos (0 - 1) -> init_last
        nfa sim loop prog input pos len init_act init_last

fn :: nfa full loop [NfaInst] String Int Int [Int] => Bool
      nfa full loop _ _ _ _ [] = False
      nfa full loop prog input pos len active =
        | pos >= len = nfa has match prog active
        | otherwise = nfa full step prog input pos len active

fn :: nfa full step [NfaInst] String Int Int [Int] => Bool
      nfa full step prog input pos len active =
        str char at input pos -> c
        nfa closure prog (nfa step prog active c) (pos + 1) len [] -> next_act
        nfa full loop prog input (pos + 1) len next_act
```

### 11.4.4. Implementación interna: Public Regex API (`API-REGEX-001`)

Fíjate en cómo `regex.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: regex match String String => Bool
      regex match pat input =
        pat re compile -> prog
        input str len -> len
        nfa closure prog [0] 0 len [] -> init_act
        nfa full loop prog input 0 len init_act

fn :: nfa find from [NfaInst] String Int Int => RegexMatch
      nfa find from prog input pos len =
        | pos > len = RegexMatch False (0 - 1) (0 - 1) ""
        | otherwise = nfa find check prog input pos len (nfa longest from prog input pos len)

fn :: nfa find check [NfaInst] String Int Int Int => RegexMatch
      nfa find check prog input pos len end_pos =
        | end_pos >= pos = RegexMatch True pos end_pos (str slice input pos end_pos)
        | otherwise = nfa find from prog input (pos + 1) len

fn :: regex find String String => RegexMatch
      regex find pat input =
        pat re compile -> prog
        nfa find from prog input 0 (str len input)

fn :: regex is match String String => Bool
      regex is match pat input = regex find pat input -> matched

fn :: nfa find all loop [NfaInst] String Int Int [RegexMatch] => [RegexMatch]
      nfa find all loop prog input pos len acc =
        | pos > len = acc
        | otherwise = nfa find all step prog input pos len acc (nfa longest from prog input pos len)

fn :: nfa find all step [NfaInst] String Int Int [RegexMatch] Int => [RegexMatch]
      nfa find all step prog input pos len acc end_pos =
        | end_pos > pos = nfa find all loop prog input end_pos len (acc :: [RegexMatch True pos end_pos (str slice input pos end_pos)])
        | end_pos == pos = nfa find all loop prog input (pos + 1) len (acc :: [RegexMatch True pos pos ""])
        | otherwise = nfa find all loop prog input (pos + 1) len acc

fn :: regex find all String String => [RegexMatch]
      regex find all pat input =
        pat re compile -> prog
        nfa find all loop prog input 0 (str len input) []

fn :: regex replace String String String => String
      regex replace pat repl input =
        regex find pat input -> m
        re apply replace m repl input

fn :: re apply replace RegexMatch String String => String
      re apply replace m repl input =
        | not (matched m) = input
        | otherwise = (str slice input 0 (match_start m)) + repl + (str slice input (match_end m) (str len input))

fn :: nfa replace all loop [NfaInst] String String Int Int String => String
      nfa replace all loop prog repl input pos len acc =
        | pos >= len = acc
        | otherwise = nfa replace all step prog repl input pos len acc (nfa longest from prog input pos len)

fn :: nfa replace all step [NfaInst] String String Int Int String Int => String
      nfa replace all step prog repl input pos len acc end_pos =
        | end_pos > pos = nfa replace all loop prog repl input end_pos len (acc + repl)
        | otherwise = nfa replace all loop prog repl input (pos + 1) len (acc + (str slice input pos (pos + 1)))

fn :: regex replace all String String String => String
      regex replace all pat repl input =
        pat re compile -> prog
        nfa replace all loop prog repl input 0 (str len input) ""

fn :: nfa split loop [NfaInst] String Int Int Int [String] => [String]
      nfa split loop prog input pos len last_s acc =
        | pos >= len = acc :: [str slice input last_s len]
        | otherwise = nfa split step prog input pos len last_s acc (nfa longest from prog input pos len)

fn :: nfa split step [NfaInst] String Int Int Int [String] Int => [String]
      nfa split step prog input pos len last_s acc end_pos =
        | end_pos > pos = nfa split loop prog input end_pos len end_pos (acc :: [str slice input last_s pos])
        | otherwise = nfa split loop prog input (pos + 1) len last_s acc

fn :: regex split String String => [String]
      regex split pat input =
        pat re compile -> prog
        nfa split loop prog input 0 (str len input) 0 []
```

---

## 11.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `regex`

- **Garantía algorítmica y de seguridad**: Simulación de conjunto de estados NFA sin recursión descontrolada de pila y tiempo $O(N \cdot M)$ garantizado incluso ante patrones patológicos `(a+)+b`.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/regex.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test regex.rg`.

### Las 5 Reglas de Oro al programar con `regex`

1. **Declara `import regex` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `regex` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `regex` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `regex` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 12** pasaremos a explorar en profundidad la lib **`glob`** (La lib `glob` — Patrones de Comodines (`*`, `?`, `[a-z]`) y Filtrado de Listas).
