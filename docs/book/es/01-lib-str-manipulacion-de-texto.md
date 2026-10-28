# Capítulo 01: La lib `str` — Manipulación de Texto, Búsqueda y Formato Tabular

## 01.1. ¿Por qué existe la lib `str`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `str` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `str`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: en C manipular cadenas con `strtok` y `strncpy` es caminar por un campo de minas de desbordamientos de búfer y punteros `NULL`, y en otros lenguajes acabas importando tres paquetes solo para alinear columnas o repetir un separador en $O(\log N)$.

La lib **`str`** proporciona todas las primitivas puras e inmutables para buscar, recortar, dividir, unir, cambiar mayúsculas/minúsculas, repetir por duplicación binaria $O(\log N)$ y rellenar cadenas.

En un ecosistema tradicional, resolver las tareas del dominio **`STR`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`str`** (`src/main/ridgun/lib/str.rg`) aborda el problema con cuatro principios innegociables:

1. **Declara `import str` (o `import str as alias`) al inicio del archivo**: cada lib define su espacio de nombres `module :: str` y en modo `--strict` las funciones multi-palabra se invocan siempre con espacios naturales.
2. **Encadena tus tuberías de izquierda a derecha con `->`**: escribe `entrada paso uno -> paso dos -> resultado`, usa máscaras `(+ _ _ +)` para desestructurar secuencias y omite `_ =` en sentencias secuenciales (o descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `str` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 01.2. Artefactos nativos, importación y catálogo completo de la API de `str`

En `ridgun-libs`, **`str`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/str.rg` (dominio `STR`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/str.rglib` | Distribución e importación directa con `import str` |
| **Archivo compilado** | `target/str.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libstr.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Cada lib declara su propio espacio de nombres con `module :: str`: basta con escribir `import str` (o `import str as alias`) en el encabezado y llamar a sus funciones con espacios naturales (`mi funcion x`) y tuberías `->` (`x mi funcion -> resultado`).

### 01.2.1. Resumen de familias funcionales de `str`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `str index of : String -> String -> Int` | Primer índice de la subcadena (`-1` si no existe / `0` si es vacía) |
| `str contains / str starts with / str ends with` | Predicados `Bool` de subcadena, prefijo y sufijo |
| `str trim / str trim left / str trim right` | Elimina espacios en blanco ASCII (` `, `\t`, `\n`, `\r`) |
| `str split / str lines / str words / str join` | Divide en `[String]` y une listas con un separador |
| `str replace / str to upper / str to lower` | Reemplazo sin solapamiento y conversión ASCII de mayúsculas/minúsculas |
| `str repeat / str pad left / str pad right` | Repetición en $O(\log N)$ y relleno de columnas a ancho fijo |

### 01.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/str.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/str.rg` (`0` tipos, `0` operadores y `42` funciones):

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: is ascii space Int` | `Bool` |
| `2` | `fn :: is ascii lower Int` | `Bool` |
| `3` | `fn :: is ascii upper Int` | `Bool` |
| `4` | `fn :: to upper code Int` | `Int` |
| `5` | `fn :: to lower code Int` | `Int` |
| `6` | `fn :: str index of from String String Int Int Int` | `Int` |
| `7` | `fn :: str index of String String` | `Int` |
| `8` | `fn :: str ends with step String String Int Int` | `Bool` |
| `9` | `fn :: str ends with String String` | `Bool` |
| `10` | `fn :: str is empty String` | `Bool` |
| `11` | `fn :: first non space idx String Int Int` | `Int` |
| `12` | `fn :: last non space end String Int` | `Int` |
| `13` | `fn :: str trim left String` | `String` |
| `14` | `fn :: str trim right String` | `String` |
| `15` | `fn :: str trim slice String Int Int` | `String` |
| `16` | `fn :: str trim String` | `String` |
| `17` | `fn :: str is blank String` | `Bool` |
| `18` | `fn :: str replace step String String String Int` | `String` |
| `19` | `fn :: str replace String String String` | `String` |
| `20` | `fn :: str split chars String Int Int [String]` | `[String]` |
| `21` | `fn :: str split onech loop String Int Int Int Int [String]` | `[String]` |
| `22` | `fn :: str split loop String String Int Int Int Int Int [String]` | `[String]` |
| `23` | `fn :: str split step String String Int Int` | `[String]` |
| `24` | `fn :: str split String String` | `[String]` |
| `25` | `fn :: str join pair step [String] String [String]` | `[String]` |
| `26` | `fn :: str join pairs [String] String` | `String` |
| `27` | `fn :: str join [String] String` | `String` |
| `28` | `fn :: upper char code String Int Int` | `String` |
| `29` | `fn :: upper char slice String Int` | `String` |
| `30` | `fn :: str to upper range String Int Int` | `String` |
| `31` | `fn :: str to upper String` | `String` |
| `32` | `fn :: lower char code String Int Int` | `String` |
| `33` | `fn :: lower char slice String Int` | `String` |
| `34` | `fn :: str to lower range String Int Int` | `String` |
| `35` | `fn :: str to lower String` | `String` |
| `36` | `fn :: str repeat loop String Int String` | `String` |
| `37` | `fn :: str repeat String Int` | `String` |
| `38` | `fn :: pad fill unit String` | `String` |
| `39` | `fn :: str pad left step String Int String Int` | `String` |
| `40` | `fn :: str pad left String Int String` | `String` |
| `41` | `fn :: str pad right step String Int String Int` | `String` |
| `42` | `fn :: str pad right String Int String` | `String` |

---

## 01.3. Explorando `str` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `str` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test str.rg`.

### 01.3.1. Ejemplo 1: Flujo principal en estilo tabular con `str`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `str` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import str

fn :: normalizar cabecera String => String
      normalizar cabecera raw =
        raw str trim -> str to lower -> limpia
        limpia str split " " -> partes
        str join partes "-" -> slug
        str pad right slug 24 "."
```

### 01.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `str` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import str

fn :: extraer dominio String => String
      extraer dominio correo =
        str index of correo "@" -> pos
        | pos < 0   = "sin-dominio"
        | otherwise =
          correo str to lower -> minusc
          str replace minusc "@" " en "
```

### 01.3.3. Ejemplo 3: Búsqueda de subcadenas (`str index of`), sufijos (`str ends with`) y predicados de vacío/blanco

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `str` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test str search and predicates => ()
      test str search and predicates =
        assert equals (str index of "hello world" "world") 6 "AC1: index_of world"
        assert equals (str index of "hello world" "hello") 0 "AC1: index_of hello at 0"
        assert equals (str index of "ababa" "aba") 0 "AC1: index_of returns first occurrence"
        assert equals (str index of "hello" "xyz") (0 - 1) "AC1: index_of missing"
        assert equals (str index of "short" "much_longer_needle") (0 - 1) "AC1: needle longer than haystack -> -1"
        assert equals (str index of "" "a") (0 - 1) "AC1: non-empty needle in empty haystack -> -1"
        assert equals (str index of "" "") 0 "AC1: empty needle in empty haystack -> 0"
        assert equals (str index of "abc" "") 0 "AC1: empty needle -> 0"

        assert true (str ends with "archive.rglib" ".rglib") "AC1: ends_with true"
        assert true (str ends with "exact" "exact") "AC1: ends_with full string"
        assert true (str ends with "any" "") "AC1: ends_with empty suffix true"
        assert false (str ends with "archive.rg" ".rglib") "AC1: ends_with false"
        assert false (str ends with "short" "longer_suffix") "AC1: ends_with suffix longer than string"

        assert true (str is empty "") "AC1: is_empty true"
        assert false (str is empty " ") "AC1: space is not empty"
        assert true (str is blank "") "AC1: empty is blank"
        assert true (str is blank "   \t\n\r ") "AC1: whitespace-only is blank"
        assert false (str is blank "  x ") "AC1: non-whitespace is not blank"
        ()
```

### 01.3.4. Ejemplo 4: Recorte de espacios (`trim`, `trim left`, `trim right`), reemplazo (`str replace`), división (`str split`) y unión (`str join`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `str` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test str trim replace and split => ()
      test str trim replace and split =
        assert equals (str trim "  \thi\n\r ") "hi" "AC2: str_trim mixed ASCII whitespace"
        assert equals (str trim "   \t\r\n") "" "AC2: str_trim all whitespace -> empty"
        assert equals (str trim "") "" "AC2: str_trim empty -> empty"
        assert equals (str trim "no_ws") "no_ws" "AC2: str_trim no whitespace"
        assert equals (str trim left "  abc  ") "abc  " "AC2: str_trim_left"
        assert equals (str trim right "  abc  ") "  abc" "AC2: str_trim_right"

        assert equals (str replace "a-b-c" "-" "_") "a_b_c" "AC2: str_replace single char"
        assert equals (str replace "aaaa" "aa" "b") "bb" "AC2: str_replace non-overlapping left-to-right"
        assert equals (str replace "Hello,World" "World" "") "Hello," "AC2: str_replace deletion to empty"
        assert equals (str replace "abc" "" "x") "abc" "AC2: str_replace empty old leaves string unchanged"
        assert equals (str replace "abc" "z" "y") "abc" "AC2: str_replace absent needle"

        assert equals (str split "a,b,c" ",") ["a", "b", "c"] "AC2: str_split comma"
        assert equals (str split "a,,b," ",") ["a", "", "b", ""] "AC2: str_split consecutive and trailing delim"
        assert equals (str split ",a" ",") ["", "a"] "AC2: str_split leading delim"
        assert equals (str split "a::b::c" "::") ["a", "b", "c"] "AC2: str_split multi-char delimiter"
        assert equals (str split "ab" "") ["a", "b"] "AC2: str_split empty delim splits chars"
        assert equals (str split "" "") [] "AC2: str_split empty string with empty delim -> []"

        assert equals (str join [] "::") "" "AC2: str_join empty list"
        assert equals (str join ["only"] "::") "only" "AC2: str_join singleton"
        assert equals (str join ["alpha", "beta", "gamma"] "::") "alpha::beta::gamma" "AC2: str_join 3 items"
        ()
```

### 01.3.5. Ejemplo 5: Conversión de caja ASCII (`to upper`, `to lower`), repetición binaria $O(\log N)$ (`str repeat`) y alineación tabular (`pad left`, `pad right`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `str` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test str case repeat and padding => ()
      test str case repeat and padding =
        assert equals (str to upper "Abc! 123 xyz") "ABC! 123 XYZ" "AC3: str_to_upper"
        assert equals (str to lower "Abc! 123 XYZ") "abc! 123 xyz" "AC3: str_to_lower"
        assert equals (str to upper "") "" "AC3: str_to_upper empty"

        assert equals (str repeat "ab" 3) "ababab" "AC3: str_repeat 3"
        assert equals (str repeat "ab" 1) "ab" "AC3: str_repeat 1"
        assert equals (str repeat "ab" 0) "" "AC3: str_repeat 0"
        assert equals (str repeat "ab" (0 - 5)) "" "AC3: str_repeat negative -> empty"
        assert equals (str repeat "" 100) "" "AC3: str_repeat empty string -> empty"

        t0 = sys monotonic ms
        r64k = str repeat "x" 65536
        r256k = str repeat "x" 262144
        t1 = sys monotonic ms
        r8m = str repeat "x" 8000000
        assert equals (str len r64k) 65536 "AC3: str_repeat 65536 length"
        assert equals (str len r256k) 262144 "AC3: str_repeat 262144 length"
        assert equals (str len r8m) 8000000 "AC3: RG-052 str_repeat 8000000 exact length without 1 MiB cap"
        assert true ((t1 - t0) < 200) "AC3: LIB-9 str_repeat 64k+256k in < 200 ms"

        assert equals (str pad left "7" 3 "0") "007" "AC3: str_pad_left"
        assert equals (str pad right "7" 3 "0") "700" "AC3: str_pad_right"
        assert equals (str pad left "7" 4 "") "   7" "AC3: str_pad_left empty pad_ch defaults to space"
        assert equals (str pad left "7" 4 "xyz") "xxx7" "AC3: str_pad_left uses first char of pad_ch"
        assert equals (str pad left "1234" 3 "0") "1234" "AC3: str_pad_left already wider than width"
        assert equals (str pad right "1234" 3 "0") "1234" "AC3: str_pad_right already wider than width"
        ()
```

---

## 01.4. Bajo el capó: cómo está construida `str` en Ridgun puro (`src/main/ridgun/lib/str.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/str.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 01.4.1. Implementación interna: ASCII Classification Helpers

Fíjate en cómo `str.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
module :: str

fn :: is ascii space Int  => Bool
      is ascii space code =
        code == 32 or code == 9 or code == 10 or code == 13

fn :: is ascii lower Int  => Bool
      is ascii lower code =  code >= 97 and code <= 122

fn :: is ascii upper Int  => Bool
      is ascii upper code =  code >= 65 and code <= 90

fn :: to upper code Int  => Int
      to upper code code =
        | is ascii lower code = code - 32
        | otherwise           = code

fn :: to lower code Int  => Int
      to lower code code =
        | is ascii upper code = code + 32
        | otherwise           = code
```

### 01.4.2. Implementación interna: Whitespace Trimming

Fíjate en cómo `str.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: first non space idx String Int Int => Int
      first non space idx s idx len =
        | idx >= len                         = len
        | is ascii space (str char at s idx) = first non space idx s (idx + 1) len
        | otherwise                          = idx

fn :: last non space end String Int => Int
      last non space end s end =
        | end <= 0                                 = 0
        | is ascii space (str char at s (end - 1)) = last non space end s (end - 1)
        | otherwise                                = end

fn :: str trim left String => String
      str trim left s      =
        s str len -> len
        first non space idx s 0 len -> start
        str slice s start len

fn :: str trim right String => String
      str trim right s      =
        s str len -> len
        last non space end s len -> end
        str slice s 0 end

fn :: str trim slice String Int Int => String
      str trim slice s start end =
        | start >= end = ""
        | otherwise    = str slice s start end

fn :: str trim String => String
      str trim s      =
        s str len -> len
        first non space idx s 0 len -> start
        last non space end s len -> end
        str trim slice s start end

fn :: str is blank String => Bool
      str is blank s      =  s str trim -> str is empty
```

### 01.4.3. Implementación interna: String Splitting & Joining

Fíjate en cómo `str.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: str split chars String Int Int [String] => [String]
      str split chars s idx slen acc =
        | idx >= slen = acc
        | otherwise   = str split chars s (idx + 1) slen (acc :: [str slice s idx (idx + 1)])

fn :: str split onech loop String Int Int Int Int [String] => [String]
      str split onech loop s d0 pos slen seg_start acc =
        | pos >= slen = acc :: [str slice s seg_start slen]
        | (str char at s pos) == d0 =
          seg = str slice s seg_start pos
          str split onech loop s d0 (pos + 1) slen (pos + 1) (acc :: [seg])
        | otherwise =
          str split onech loop s d0 (pos + 1) slen seg_start acc

fn :: str split loop String String Int Int Int Int Int [String] => [String]
      str split loop s delim d0 pos slen dlen seg_start acc =
        | pos + dlen > slen = acc :: [str slice s seg_start slen]
        | (str char at s pos) == d0 and (str slice s pos (pos + dlen)) == delim =
          seg = str slice s seg_start pos
          str split loop s delim d0 (pos + dlen) slen dlen (pos + dlen) (acc :: [seg])
        | otherwise =
          str split loop s delim d0 (pos + 1) slen dlen seg_start acc

fn :: str split step String String Int Int => [String]
      str split step s delim slen dlen =
        | dlen == 0 = str split chars s 0 slen []
        | dlen == 1 = str split onech loop s (str char at delim 0) 0 slen 0 []
        | otherwise = str split loop s delim (str char at delim 0) 0 slen dlen 0 []

fn :: str split String String => [String]
      str split s      delim  =
        str split step s delim (str len s) (str len delim)

fn :: str join pair step [String] String [String] => [String]
      str join pair step []         _   acc =  acc
      str join pair step (a:[])     _   acc =  acc :: [a]
      str join pair step (a:b:rest) sep acc =
        str join pair step rest sep (acc :: [a + sep + b])

fn :: str join pairs [String] String => String
      str join pairs []       _   =  ""
      str join pairs (x:[])   _   =  x
      str join pairs (x:y:[]) sep =  x + sep + y
      str join pairs xs       sep =
        str join pairs (str join pair step xs sep []) sep

fn :: str join [String] String => String
      str join xs       sep    =  str join pairs xs sep
```

### 01.4.4. Implementación interna: Repetition & Padding

Fíjate en cómo `str.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: str repeat loop String Int String => String
      str repeat loop cur n acc =
        | n <= 0       = acc
        | (n % 2) == 1 = str repeat loop (cur + cur) (n / 2) (acc + cur)
        | otherwise    = str repeat loop (cur + cur) (n / 2) acc

fn :: str repeat String Int => String
      str repeat s      n   =
        | n <= 0 or (str len s) == 0 = ""
        | otherwise                  = str repeat loop s n ""

fn :: pad fill unit String => String
      pad fill unit pad_ch =
        | (str len pad_ch) == 0 = " "
        | otherwise             = str slice pad_ch 0 1

fn :: str pad left step String Int String Int => String
      str pad left step s width pad_ch slen =
        | slen >= width = s
        | otherwise     = (str repeat (pad fill unit pad_ch) (width - slen)) + s

fn :: str pad left String Int String => String
      str pad left s width pad_ch =
        str pad left step s width pad_ch (str len s)

fn :: str pad right step String Int String Int => String
      str pad right step s width pad_ch slen =
        | slen >= width = s
        | otherwise     = s + (str repeat (pad fill unit pad_ch) (width - slen))

fn :: str pad right String Int String => String
      str pad right s width pad_ch =
        str pad right step s width pad_ch (str len s)
```

---

## 01.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `str`

- **Garantía algorítmica y de seguridad**: Repetición en $O(\log N)$ mediante duplicación de cadenas, predicados seguros ante agujas vacías y cero mutación en el lugar.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/str.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test str.rg`.

### Las 5 Reglas de Oro al programar con `str`

1. **Declara `import str` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `str` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `str` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `str` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 02** pasaremos a explorar en profundidad la lib **`math`** (La lib `math` — Aritmética Segura, Teoría de Números y Estadística).
