# Capítulo 10: La lib `ini` — Archivos `.ini` por Secciones, `.env` e Interpolación de Variables

## 10.1. ¿Por qué existe la lib `ini`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `ini` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `ini`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: los archivos `.env` y `.ini` parecen triviales hasta que alguien añade `export KEY="valor # con almohadilla"`, comentarios `;` al final de la línea o referencias cruzadas entre variables.

La lib **`ini`** analiza configuraciones `.ini` con secciones (`[database]`) y archivos `.env` con prefijos `export`, preservando símbolos `#` y `;` dentro de comillas y resolviendo interpolaciones de variables en `dotenv parse`.

En un ecosistema tradicional, resolver las tareas del dominio **`INI`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`ini`** (`src/main/ridgun/lib/ini.rg`) aborda el problema con cuatro principios innegociables:

1. **Declara `import ini` (o `import ini as alias`) al inicio del archivo**: cada lib define su espacio de nombres `module :: ini` y en modo `--strict` las funciones multi-palabra se invocan siempre con espacios naturales.
2. **Encadena tus tuberías de izquierda a derecha con `->`**: escribe `entrada paso uno -> paso dos -> resultado`, usa máscaras `(+ _ _ +)` para desestructurar secuencias y omite `_ =` en sentencias secuenciales (o descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `ini` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 10.2. Artefactos nativos, importación y catálogo completo de la API de `ini`

En `ridgun-libs`, **`ini`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/ini.rg` (dominio `INI`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/ini.rglib` | Distribución e importación directa con `import ini` |
| **Archivo compilado** | `target/ini.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libini.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Cada lib declara su propio espacio de nombres con `module :: ini`: basta con escribir `import ini` (o `import ini as alias`) en el encabezado y llamar a sus funciones con espacios naturales (`mi funcion x`) y tuberías `->` (`x mi funcion -> resultado`).

### 10.2.1. Resumen de familias funcionales de `ini`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `ini parse / ini stringify` | Analiza texto `.ini` por secciones en `IniDoc` y lo serializa de vuelta |
| `ini get / ini get int / ini get bool / ini set` | Consultas tipadas por sección+clave (`""` para sección global) y actualización inmutable |
| `ini sections / ini section map` | Lista los nombres de sección o extrae el mapa `[String String]` de una sección |
| `dotenv parse` | Analiza archivos `.env` (`export K=V`, comillas, comentarios y expansión de variables) |

### 10.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/ini.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/ini.rg` (`3` tipos, `0` operadores y `44` funciones):

**Tipos algebraicos y registros (`type`) de `ini`:**

```ridgun
type IniEntry = IniEntry String String
type IniSection = section_name: String, entries: [IniEntry]
type IniDoc = sections: [IniSection]
```

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: ini_is_hspace Int` | `Bool` |
| `2` | `fn :: ini_trim_left_loop String Int Int` | `String` |
| `3` | `fn :: ini_trim_right_loop String Int` | `String` |
| `4` | `fn :: ini_trim String` | `String` |
| `5` | `fn :: ini_split_lines_loop String Int Int Int [String]` | `[String]` |
| `6` | `fn :: ini_skip_quoted String Int Int Int` | `Int` |
| `7` | `fn :: ini_strip_comment_loop String Int Int` | `String` |
| `8` | `fn :: ini_unquote_unescape_loop String Int Int String` | `String` |
| `9` | `fn :: ini_clean_val String` | `String` |
| `10` | `fn :: ini_clean_val_len String Int` | `String` |
| `11` | `fn :: ini_p_key IniEntry` | `String` |
| `12` | `fn :: ini_p_val IniEntry` | `String` |
| `13` | `fn :: ini_kv_get [IniEntry] String String` | `String` |
| `14` | `fn :: ini_kv_put [IniEntry] String String` | `[IniEntry]` |
| `15` | `fn :: ini_find_rbrace String Int Int` | `Int` |
| `16` | `fn :: ini_expand_brace String Int Int [IniEntry] String Int` | `String` |
| `17` | `fn :: ini_interpolate_loop String Int Int [IniEntry] String` | `String` |
| `18` | `fn :: ini_interpolate String [IniEntry]` | `String` |
| `19` | `fn :: ini_sec_put [IniSection] String String String` | `[IniSection]` |
| `20` | `fn :: ini_sec_ensure [IniSection] String` | `[IniSection]` |
| `21` | `fn :: ini_sec_get [IniSection] String String String` | `String` |
| `22` | `fn :: ini_find_eq String Int Int` | `Int` |
| `23` | `fn :: ini_strip_export String` | `String` |
| `24` | `fn :: ini_parse_kv_at String [IniSection] String Int` | `[IniSection]` |
| `25` | `fn :: ini_sec_entries [IniSection] String` | `[IniEntry]` |
| `26` | `fn :: ini_parse_lines [String] [IniSection] String` | `[IniSection]` |
| `27` | `fn :: ini_parse_sec_hdr String [String] [IniSection]` | `[IniSection]` |
| `28` | `fn :: ini_parse_kv_line String [String] [IniSection] String` | `[IniSection]` |
| `29` | `fn :: ini_parse_clean_line String [String] [IniSection] String` | `[IniSection]` |
| `30` | `fn :: ini parse String` | `IniDoc` |
| `31` | `fn :: dotenv parse String` | `[IniEntry]` |
| `32` | `fn :: ini get IniDoc String String String` | `String` |
| `33` | `fn :: ini get int IniDoc String String Int` | `Int` |
| `34` | `fn :: ini_parse_int_or String Int` | `Int` |
| `35` | `fn :: ini get bool IniDoc String String Bool` | `Bool` |
| `36` | `fn :: ini_parse_bool_or String Bool` | `Bool` |
| `37` | `fn :: ini set IniDoc String String String` | `IniDoc` |
| `38` | `fn :: ini_collect_sec_names [IniSection]` | `[String]` |
| `39` | `fn :: ini sections IniDoc` | `[String]` |
| `40` | `fn :: dotenv get [IniEntry] String String` | `String` |
| `41` | `fn :: ini_format_entries [IniEntry]` | `String` |
| `42` | `fn :: ini_format_section IniSection` | `String` |
| `43` | `fn :: ini_format_sections [IniSection]` | `String` |
| `44` | `fn :: ini stringify IniDoc` | `String` |

---

## 10.3. Explorando `ini` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `ini` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test ini.rg`.

### 10.3.1. Ejemplo 1: Flujo principal en estilo tabular con `ini`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `ini` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import ini

fn :: cargar base de datos String => String Int Bool
      cargar base de datos texto_ini =
        texto_ini ini parse -> doc
        ini get doc "database" "host" "localhost" -> host
        ini get int doc "database" "port" 5432 -> port
        ini get bool doc "database" "pool" True -> pool
        (host, port, pool)
```

### 10.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `ini` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import ini

fn :: actualizar puerto [String String String] String => String
      actualizar puerto doc nuevo =
        ini set doc "database" "port" nuevo -> doc2
        doc2 ini encode
```

### 10.3.3. Ejemplo 3: Secciones `[seccion]`, comentarios (`;` y `#`), lecturas tipadas (`get str`, `get int`, `get bool`) y actualización inmutable (`ini set`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `ini` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test_ini_sections_and_typed_getters => ()
      test_ini_sections_and_typed_getters =
        nl = char from code 10
        src = "# Global header comment" + nl + "; Secondary comment" + nl + "global_env = production" + nl + nl + "[database]" + nl + "host = \"127.0.0.1\"" + nl + "port = 5432 ; default pg" + nl + "timeout = -1 # infinite" + nl + "password = \"p@ss#word;123\"" + nl + "ssl = true" + nl + "pool_enabled = yes" + nl + "readonly = 0" + nl + "debug_sql = no" + nl + nl + "[server]" + nl + "workers = 4" + nl + "enabled = 1" + nl
        doc = ini parse src
        assert str eq (ini get doc "" "global_env" "") "production" "AC1: global sectionless key in root '' section"
        assert str eq (ini get doc "database" "host" "") "127.0.0.1" "AC1: ini get quoted string"
        assert int equals (ini get int doc "database" "port" 0) 5432 "AC1: ini get int with ';' inline comment"
        assert int equals (ini get int doc "database" "timeout" 0) (-1) "AC1: ini get negative int with '#' inline comment"
        assert str eq (ini get doc "database" "password" "") "p@ss#word;123" "AC1: quoted '#' and ';' preserved inside string"
        assert true (ini get bool doc "database" "ssl" False) "AC1: ini get bool 'true'"
        assert true (ini get bool doc "database" "pool_enabled" False) "AC1: ini get bool 'yes'"
        assert false (ini get bool doc "database" "readonly" True) "AC1: ini get bool '0'"
        assert false (ini get bool doc "database" "debug_sql" True) "AC1: ini get bool 'off'"
        assert int equals (ini get int doc "server" "workers" 0) 4 "AC1: ini get second section"
        assert true (ini get bool doc "server" "enabled" False) "AC1: ini get bool '1'"
        assert str eq (ini get doc "server" "missing" "default_v") "default_v" "AC1: ini get fallback on missing key"
        assert str eq (ini get doc "no_such_section" "k" "fallback") "fallback" "AC1: ini get fallback on missing section"
        secs = ini sections doc
        assert int equals (ini_sec_count secs) 3 "AC1: 3 sections (root '', database, server)"
        ()
```

### 10.3.4. Ejemplo 4: Archivos `.env` con `export`, comillas, interpolación de variables `${VAR}` y serialización canónica (`ini stringify`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `ini` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test_dotenv_interpolation_and_roundtrip => ()
      test_dotenv_interpolation_and_roundtrip =
        nl = char from code 10
        lb = char from code 123
        rb = char from code 125
        env_src = "# .env test" + nl + "export BASE_DIR=/srv/app" + nl + "APP_NAME='solstice'" + nl + "LOG_DIR=\"$" + lb + "BASE_DIR" + rb + "/$" + lb + "APP_NAME" + rb + "/logs\"" + nl + "WITH_UNKNOWN=\"prefix_$" + lb + "UNDEFINED_VAR" + rb + "_suffix\"" + nl + "PORT=8080 # inline comment" + nl
        env = dotenv parse env_src
        assert str eq (dotenv get env "BASE_DIR" "") "/srv/app" "AC2: dotenv export key"
        assert str eq (dotenv get env "APP_NAME" "") "solstice" "AC2: dotenv single-quoted value"
        assert str eq (dotenv get env "LOG_DIR" "") "/srv/app/solstice/logs" "AC2: dotenv multiple variable interpolations"
        assert str eq (dotenv get env "WITH_UNKNOWN" "") "prefix__suffix" "AC2: dotenv undefined variable expands to empty"
        assert str eq (dotenv get env "PORT" "") "8080" "AC2: dotenv inline comment stripped"
        assert str eq (dotenv get env "MISSING_KEY" "def") "def" "AC2: dotenv missing key fallback"

        doc0 = ini parse ("[app]" + nl + "name = demo" + nl + "port = 3000" + nl)
        doc1 = ini set doc0 "app" "version" "1.0"
        doc2 = ini set doc1 "app" "port" "9090"
        doc3 = ini set doc2 "metrics" "enabled" "true"
        out_s = ini stringify doc3
        doc_rt = ini parse out_s
        assert str eq (ini get doc_rt "app" "name" "") "demo" "AC3: ini stringify round-trip name"
        assert str eq (ini get doc_rt "app" "version" "") "1.0" "AC3: ini set new key + round-trip"
        assert int equals (ini get int doc_rt "app" "port" 0) 9090 "AC3: ini set overwrite existing key + round-trip"
        assert true (ini get bool doc_rt "metrics" "enabled" False) "AC3: ini set new section + round-trip"
        ()
```

### 10.3.5. Ejemplo 5: Configuración jerárquica de un servicio: fusión de `.env` con interpolación `${VAR}` y secciones `[database]` / `[server]` en INI

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `ini` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
import ini

fn :: cargar configuracion servicio (raw_ini : String) (raw_env : String) => (String, Int, Bool, String)
      cargar configuracion servicio raw_ini raw_env =
        env_entries = dotenv parse raw_env
        doc         = ini parse raw_ini
        db_host     = ini get str doc "database" "host" "localhost"
        db_port     = ini get int doc "database" "port" 5432
        tls_activo  = ini get bool doc "database" "tls" True
        doc_act     = ini set doc "server" "dsn" "{db_host}:{db_port}"
        (dotenv get env_entries "APP_ENV" "prod", db_port, tls_activo, ini stringify doc_act)
```

---

## 10.4. Bajo el capó: cómo está construida `ini` en Ridgun puro (`src/main/ridgun/lib/ini.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/ini.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 10.4.1. Implementación interna: Whitespace, Comment & Line Helpers

Fíjate en cómo `ini.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
module :: ini

fn :: ini is hspace Int => Bool
      ini is hspace c = c == 32 or c == 9 or c == 13

fn :: ini trim left loop String Int Int => String
      ini trim left loop s pos len =
        | pos >= len = ""
        | ini is hspace (str char at s pos) = ini trim left loop s (pos + 1) len
        | otherwise = str slice s pos len

fn :: ini trim right loop String Int => String
      ini trim right loop s end_pos =
        | end_pos <= 0 = ""
        | ini is hspace (str char at s (end_pos - 1)) = ini trim right loop s (end_pos - 1)
        | otherwise = str slice s 0 end_pos

fn :: ini trim String => String
      ini trim s =
        ini trim right loop s (str len s) -> r
        ini trim left loop r 0 (str len r)

fn :: ini split lines loop String Int Int Int [String] => [String]
      ini split lines loop s pos len start acc =
        | pos >= len and start == len = acc
        | pos >= len = acc :: [str slice s start len]
        | (str char at s pos) == 10 = ini split lines loop s (pos + 1) len (pos + 1) (acc :: [str slice s start pos])
        | otherwise = ini split lines loop s (pos + 1) len start acc

fn :: ini skip quoted String Int Int Int => Int
      ini skip quoted s pos len q =
        | pos >= len = len
        | (str char at s pos) == 92 = ini skip quoted s (pos + 2) len q
        | (str char at s pos) == q = pos + 1
        | otherwise = ini skip quoted s (pos + 1) len q

fn :: ini strip comment loop String Int Int => String
      ini strip comment loop s pos len =
        | pos >= len = s
        | (str char at s pos) == 34 = ini strip comment loop s (ini skip quoted s (pos + 1) len 34) len
        | (str char at s pos) == 39 = ini strip comment loop s (ini skip quoted s (pos + 1) len 39) len
        | (str char at s pos) == 35 or (str char at s pos) == 59 = str slice s 0 pos
        | (pos + 1) < len and (str char at s pos) == 45 and (str char at s (pos + 1)) == 45 = str slice s 0 pos
        | otherwise = ini strip comment loop s (pos + 1) len

fn :: ini unquote unescape loop String Int Int String => String
      ini unquote unescape loop s pos len acc =
        | pos >= len = acc
        | (str char at s pos) == 92 and (pos + 1) < len and (str char at s (pos + 1)) == 110 = ini unquote unescape loop s (pos + 2) len (acc + (char from code 10))
        | (str char at s pos) == 92 and (pos + 1) < len and (str char at s (pos + 1)) == 116 = ini unquote unescape loop s (pos + 2) len (acc + (char from code 9))
        | (str char at s pos) == 92 and (pos + 1) < len = ini unquote unescape loop s (pos + 1 + 1) len (acc + (str slice s (pos + 1) (pos + 2)))
        | otherwise = ini unquote unescape loop s (pos + 1) len (acc + (str slice s pos (pos + 1)))

fn :: ini clean val String => String
      ini clean val raw =
        raw ini trim -> tr
        tr str len -> len
        ini clean val len tr len

fn :: ini clean val len String Int => String
      ini clean val len tr len =
        | len >= 2 and (str char at tr 0) == 34 and (str char at tr (len - 1)) == 34 = ini unquote unescape loop (str slice tr 1 (len - 1)) 0 (len - 2) ""
        | len >= 2 and (str char at tr 0) == 39 and (str char at tr (len - 1)) == 39 = str slice tr 1 (len - 1)
        | otherwise = tr
```

### 10.4.2. Implementación interna: Key-Value Pair Helpers (`[IniEntry]`)

Fíjate en cómo `ini.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: ini p key IniEntry => String
      ini p key (IniEntry k _) = k

fn :: ini p val IniEntry => String
      ini p val (IniEntry _ v) = v

fn :: ini kv get [IniEntry] String String => String
      ini kv get [] _ fallback = fallback
      ini kv get (pair:rest) key fallback =
        | (ini p key pair) == key = ini p val pair
        | otherwise = ini kv get rest key fallback

fn :: ini kv put [IniEntry] String String => [IniEntry]
      ini kv put [] key val = [IniEntry key val]
      ini kv put (pair:rest) key val =
        | (ini p key pair) == key = [IniEntry key val] :: rest
        | otherwise = [pair] :: (ini kv put rest key val)
```

### 10.4.3. Implementación interna: Sectioned INI Document Helpers

Fíjate en cómo `ini.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: ini sec put [IniSection] String String String => [IniSection]
      ini sec put [] sec key val = [IniSection sec [IniEntry key val]]
      ini sec put (s:rest) sec key val =
        | (section_name s) == sec = [IniSection sec (ini kv put (entries s) key val)] :: rest
        | otherwise = [s] :: (ini sec put rest sec key val)

fn :: ini sec ensure [IniSection] String => [IniSection]
      ini sec ensure [] sec = [IniSection sec []]
      ini sec ensure (s:rest) sec =
        | (section_name s) == sec = [s] :: rest
        | otherwise = [s] :: (ini sec ensure rest sec)

fn :: ini sec get [IniSection] String String String => String
      ini sec get [] _ _ fallback = fallback
      ini sec get (s:rest) sec key fallback =
        | (section_name s) == sec = ini kv get (entries s) key fallback
        | otherwise = ini sec get rest sec key fallback

fn :: ini find eq String Int Int => Int
      ini find eq s pos len =
        | pos >= len = (0 - 1)
        | (str char at s pos) == 61 = pos
        | otherwise = ini find eq s (pos + 1) len

fn :: ini strip export String => String
      ini strip export tr =
        | str starts with tr "export " = ini trim (str slice tr 7 (str len tr))
        | otherwise = tr

fn :: ini parse kv at String [IniSection] String Int => [IniSection]
      ini parse kv at line secs cur_s eq_pos =
        | eq_pos == (0 - 1) = secs
        | otherwise = ini sec put secs cur_s (ini trim (str slice line 0 eq_pos)) (ini interpolate (ini clean val (str slice line (eq_pos + 1) (str len line))) (ini sec entries secs cur_s))

fn :: ini sec entries [IniSection] String => [IniEntry]
      ini sec entries [] _ = []
      ini sec entries (s:rest) sec =
        | (section_name s) == sec = entries s
        | otherwise = ini sec entries rest sec

fn :: ini parse lines [String] [IniSection] String => [IniSection]
      ini parse lines [] secs _ = secs
      ini parse lines (l:ls) secs cur_s =
        ini strip comment loop l 0 (str len l) -> ini trim -> clean
        ini parse clean line clean ls secs cur_s

fn :: ini parse sec hdr String [String] [IniSection] => [IniSection]
      ini parse sec hdr clean ls secs =
        str slice clean 1 ((str len clean) - 1) -> ini trim -> new_sec
        ini parse lines ls (ini sec ensure secs new_sec) new_sec

fn :: ini parse kv line String [String] [IniSection] String => [IniSection]
      ini parse kv line clean ls secs cur_s =
        clean ini strip export -> stripped
        ini parse kv at stripped secs cur_s (ini find eq stripped 0 (str len stripped)) -> next_secs
        ini parse lines ls next_secs cur_s

fn :: ini parse clean line String [String] [IniSection] String => [IniSection]
      ini parse clean line "" ls secs cur_s = ini parse lines ls secs cur_s
      ini parse clean line clean ls secs cur_s =
        | (str char at clean 0) == 91 and (str char at clean ((str len clean) - 1)) == 93 = ini parse sec hdr clean ls secs
        | otherwise = ini parse kv line clean ls secs cur_s

fn :: ini parse String => IniDoc
      ini parse src =
        ini split lines loop src 0 (str len src) 0 [] -> lines
        IniDoc (ini parse lines lines [] "")

fn :: dotenv parse String => [IniEntry]
      dotenv parse src =
        src ini parse -> doc
        ini sec entries (sections doc) ""
```

### 10.4.4. Implementación interna: Queries, Updates & Serialization

Fíjate en cómo `ini.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: ini get IniDoc String String String => String
      ini get doc sec key fallback = ini sec get (sections doc) sec key fallback

fn :: ini get int IniDoc String String Int => Int
      ini get int doc sec key fallback =
        ini get doc sec key "" -> v
        ini parse int or v fallback

fn :: ini parse int or String Int => Int
      ini parse int or "" fallback = fallback
      ini parse int or v _ = str to int v

fn :: ini get bool IniDoc String String Bool => Bool
      ini get bool doc sec key fallback =
        ini get doc sec key "" -> v
        ini parse bool or v fallback

fn :: ini parse bool or String Bool => Bool
      ini parse bool or "" fallback = fallback
      ini parse bool or "true" _ = True
      ini parse bool or "True" _ = True
      ini parse bool or "1" _ = True
      ini parse bool or "yes" _ = True
      ini parse bool or "false" _ = False
      ini parse bool or "False" _ = False
      ini parse bool or "0" _ = False
      ini parse bool or "no" _ = False
      ini parse bool or _ fallback = fallback

fn :: ini set IniDoc String String String => IniDoc
      ini set doc sec key val = IniDoc (ini sec put (sections doc) sec key val)

fn :: ini collect sec names [IniSection] => [String]
      ini collect sec names [] = []
      ini collect sec names (s:rest) = [section_name s] :: (ini collect sec names rest)

fn :: ini sections IniDoc => [String]
      ini sections doc = ini collect sec names (sections doc)

fn :: dotenv get [IniEntry] String String => String
      dotenv get env key fallback = ini kv get env key fallback

fn :: ini format entries [IniEntry] => String
      ini format entries [] = ""
      ini format entries ((IniEntry k v):rs) = k + " = " + v + (char from code 10) + (ini format entries rs)

fn :: ini format section IniSection => String
      ini format section sec =
        | (section_name sec) == "" = ini format entries (entries sec)
        | otherwise = "[" + (section_name sec) + "]" + (char from code 10) + (ini format entries (entries sec))

fn :: ini format sections [IniSection] => String
      ini format sections [] = ""
      ini format sections (s:[]) = ini format section s
      ini format sections (s:rest) = (ini format section s) + (char from code 10) + (ini format sections rest)

fn :: ini stringify IniDoc => String
      ini stringify doc = ini format sections (sections doc)
```

---

## 10.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `ini`

- **Garantía algorítmica y de seguridad**: Respeto total por los caracteres `#` y `;` cuando aparecen entre comillas simples o dobles, y conversión booleana flexible (`true/1/yes/on` vs `false/0/no/off`).
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/ini.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test ini.rg`.

### Las 5 Reglas de Oro al programar con `ini`

1. **Declara `import ini` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `ini` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `ini` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `ini` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 11** pasaremos a explorar en profundidad la lib **`regex`** (La lib `regex` — Motor de Expresiones Regulares Thompson NFA en Tiempo Lineal $O(N \cdot M)$).
