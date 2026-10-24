# Capítulo 17: La lib `path` — Normalización POSIX (`path clean`) y Confinamiento contra Path Traversal

## 17.1. ¿Por qué existe la lib `path`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `path` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `path`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: unir rutas con `base + "/" + archivo` sin limpiar segmentos `..` ni validar prefijos es como dejar la puerta abierta para que alguien pida `../../etc/passwd` en tu servidor web.

La lib **`path`** implementa normalización léxica POSIX (`path clean` al estilo `filepath.Clean` de Go), unión segura (`path join`), descomposición (`dirname`, `basename`, `stem`, `ext`, `replace ext`) y el predicado de seguridad **`path is safe subpath`** (`VUL-INJ-001`) contra escapes de directorio.

En un ecosistema tradicional, resolver las tareas del dominio **`PATH`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`path`** (`src/main/ridgun/lib/path.rg`) aborda el problema con cuatro principios innegociables:

1. **Funciones totales y contratos explícitos (`=>`)**: ninguna función de `path` lanza excepciones ocultas ni depende de `null`. Todo caso límite (entradas vacías, divisores cero, tramas truncadas o índices fuera de rango) devuelve un valor centinela documentado o un tipo algebraico suma (`Option`, `Result`).
2. **Cero código C y cero `libc`**: todo el código de `path` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `path` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 17.2. Artefactos nativos, importación y catálogo completo de la API de `path`

En `ridgun-libs`, **`path`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/path.rg` (dominio `PATH`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/path.rglib` | Distribución e importación directa con `import path` |
| **Archivo compilado** | `target/path.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libpath.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import path` en el encabezado y llamar a sus funciones con espacios (`mi funcion x`) o guiones bajos (`mi_funcion x`) indistintamente.

### 17.2.1. Resumen de familias funcionales de `path`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `path clean / path join / path join list` | Colapsa `//`, `.` y `..` léxicamente y une segmentos de ruta |
| `path dirname / path basename / path split` | Divide una ruta en directorio padre y nombre de archivo final |
| `path ext / path stem / path replace ext` | Extrae o cambia la extensión (tratando `.bashrc` como raíz `.bashrc` y ext `""`) |
| `path is safe subpath : String -> String -> Bool` | Verifica que `rel` permanezca estrictamente dentro de `base_dir` y sin bytes NUL |

### 17.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/path.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/path.rg` (`0` tipos, `0` operadores y `30` funciones):

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: pa split slash loop String Int Int Int` | `[String]` |
| `2` | `fn :: pa rev strs [String] [String]` | `[String]` |
| `3` | `fn :: pa join slash [String]` | `String` |
| `4` | `fn :: pa pop stack [String] Bool` | `[String]` |
| `5` | `fn :: pa norm segs [String] [String] Bool` | `[String]` |
| `6` | `fn :: pa finish clean String Bool` | `String` |
| `7` | `fn :: path is abs String` | `Bool` |
| `8` | `fn :: path is rel String` | `Bool` |
| `9` | `fn :: path clean String` | `String` |
| `10` | `fn :: path join String String` | `String` |
| `11` | `fn :: path join list [String]` | `String` |
| `12` | `fn :: pa last char idx String Int Int` | `Int` |
| `13` | `fn :: pa dirname at String Int` | `String` |
| `14` | `fn :: pa dirname clean String` | `String` |
| `15` | `fn :: path dirname String` | `String` |
| `16` | `fn :: pa basename at String Int` | `String` |
| `17` | `fn :: pa basename clean String` | `String` |
| `18` | `fn :: path basename String` | `String` |
| `19` | `fn :: path split String` | `String String` |
| `20` | `fn :: pa ext at String Int` | `String` |
| `21` | `fn :: path ext String` | `String` |
| `22` | `fn :: pa stem at String Int` | `String` |
| `23` | `fn :: path stem String` | `String` |
| `24` | `fn :: pa norm ext String` | `String` |
| `25` | `fn :: pa combine dir base String String` | `String` |
| `26` | `fn :: path replace ext String String` | `String` |
| `27` | `fn :: pa is safe char Int` | `Bool` |
| `28` | `fn :: pa safe chars loop String Int Int` | `Bool` |
| `29` | `fn :: pa check prefix String String` | `Bool` |
| `30` | `fn :: path is safe subpath String String` | `Bool` |

---

## 17.3. Explorando `path` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `path` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test path.rg`.

### 17.3.1. Ejemplo 1: Flujo principal en estilo tabular con `path`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `path` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import path

fn :: resolver archivo estatico (raiz : String) (peticion : String) => (Bool, String)
      resolver archivo estatico raiz peticion =
        seguro = path is safe subpath raiz peticion
        ruta   = path join raiz peticion
        (seguro, ruta)
```

### 17.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `path` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import path

fn :: cambiar salida a objeto (fuente : String) => (String, String, String)
      cambiar salida a objeto fuente =
        dir = path dirname fuente
        nom = path stem fuente
        obj = path replace ext (path clean fuente) ".rglib"
        (dir, nom, obj)
```

### 17.3.3. Ejemplo 3: Normalización léxica POSIX (`path clean`) y unión segura de segmentos (`path join`, `path join all`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `path` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test path clean and join => ()
      test path clean and join =
        -- Go path/path_test.go cleantests vectors
        _ = assert str eq (path clean "") "." "AC1: empty -> ."
        _ = assert str eq (path clean ".") "." "AC1: . -> ."
        _ = assert str eq (path clean "././.") "." "AC1: ././. -> ."
        _ = assert str eq (path clean "/") "/" "AC1: / -> /"
        _ = assert str eq (path clean "///") "/" "AC1: /// -> /"
        _ = assert str eq (path clean "/././") "/" "AC1: /././ -> /"
        _ = assert str eq (path clean "/../a") "/a" "AC1: /../a clamped at root"
        _ = assert str eq (path clean "/../../..") "/" "AC1: /../../.. clamped at root"
        _ = assert str eq (path clean "a/b/..") "a" "AC1: a/b/.. -> a"
        _ = assert str eq (path clean "a/../b") "b" "AC1: a/../b -> b"
        _ = assert str eq (path clean "a/../../b") "../b" "AC1: relative .. preserved when above ."
        _ = assert str eq (path clean "../../a/b/..") "../../a" "AC1: leading ../.. preserved"
        _ = assert str eq (path clean "/a/b/../c/./d//") "/a/c/d" "AC1: complex absolute normalization"

        -- path_join & path_join_list
        _ = assert str eq (path join "" "") "." "AC1: join empty empty"
        _ = assert str eq (path join "/var/log" "") "/var/log" "AC1: join with empty right"
        _ = assert str eq (path join "" "app.log") "app.log" "AC1: join with empty left"
        _ = assert str eq (path join "/var/log" "app/server.log") "/var/log/app/server.log" "AC1: join relative child"
        _ = assert str eq (path join "/var/log" "/etc/hosts") "/etc/hosts" "AC1: join absolute child overrides base"
        _ = assert str eq (path join list []) "." "AC1: join_list [] -> ."
        _ = assert str eq (path join list ["src", "main", "ridgun", "lib", "path.rg"]) "src/main/ridgun/lib/path.rg" "AC1: join_list 5 segments"
        ()
```

### 17.3.4. Ejemplo 4: Descomposición (`dirname`, `basename`, `ext`, `stem`) y confinamiento contra *path traversal* (`path is safe rel`, `path resolve under`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `path` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test path components and confinement => ()
      test path components and confinement =
        p = "/home/boogie/ridgun-libs/src/socket.rg"
        _ = assert true (path is abs p) "AC2: path_is_abs true"
        _ = assert false (path is rel p) "AC2: path_is_rel false"
        _ = assert false (path is abs "") "AC2: empty is not abs"
        _ = assert true (path is rel "src/socket.rg") "AC2: relative path_is_rel"
        _ = assert str eq (path dirname p) "/home/boogie/ridgun-libs/src" "AC2: dirname"
        _ = assert str eq (path basename p) "socket.rg" "AC2: basename"
        sp = path split p
        _ = assert str eq (pair_fst sp) "/home/boogie/ridgun-libs/src" "AC2: split dirname"
        _ = assert str eq (pair_snd sp) "socket.rg" "AC2: split basename"
        _ = assert str eq (path dirname "/") "/" "AC2: dirname of / is /"
        _ = assert str eq (path basename "/") "/" "AC2: basename of / is /"
        _ = assert str eq (path dirname "/top") "/" "AC2: dirname of /top is /"
        _ = assert str eq (path dirname "barefile.txt") "." "AC2: dirname of bare filename is ."

        -- Multi-dot filenames, dotfiles, and extension replacement
        _ = assert str eq (path stem p) "socket" "AC2: stem"
        _ = assert str eq (path ext p) ".rg" "AC2: ext"
        _ = assert str eq (path stem "archive.tar.gz") "archive.tar" "AC2: multi-dot stem"
        _ = assert str eq (path ext "archive.tar.gz") ".gz" "AC2: multi-dot ext"
        _ = assert str eq (path stem ".gitignore") ".gitignore" "AC2: dotfile stem"
        _ = assert str eq (path ext ".gitignore") "" "AC2: dotfile empty ext"
        _ = assert str eq (path replace ext p "rglib") "/home/boogie/ridgun-libs/src/socket.rglib" "AC2: replace_ext without leading dot"
        _ = assert str eq (path replace ext p ".so") "/home/boogie/ridgun-libs/src/socket.so" "AC2: replace_ext with leading dot"
        _ = assert str eq (path replace ext "main.rg" "") "main" "AC2: replace_ext with empty removes extension"

        -- OWASP Path Traversal & Shell Injection Confinement (VUL-INJ-002)
        _ = assert true (path is safe subpath "/srv/www" "assets/app.js") "AC3: safe child subpath"
        _ = assert true (path is safe subpath "/srv/www" "a/b/../c_1-2.txt") "AC3: safe normalized internal .."
        _ = assert false (path is safe subpath "/srv/www" "") "AC3: empty child rejected"
        _ = assert false (path is safe subpath "" "assets/app.js") "AC3: empty base rejected"
        _ = assert false (path is safe subpath "/srv/www" "../etc/passwd") "AC3: direct .. traversal rejected"
        _ = assert false (path is safe subpath "/srv/www" "a/b/../../../etc/passwd") "AC3: deep .. traversal escaping base rejected"
        _ = assert false (path is safe subpath "/srv/www" "/etc/passwd") "AC3: absolute child path rejected"
        _ = assert false (path is safe subpath "/srv/www" "/srv/www/index.html") "AC3: absolute child matching base still rejected"
        _ = assert false (path is safe subpath "/srv/www" "bad;rm -rf /") "AC3: shell semicolon metachar rejected"
        _ = assert false (path is safe subpath "/srv/www" "bad|cat") "AC3: shell pipe metachar rejected"
        _ = assert false (path is safe subpath "/srv/www" "bad$var") "AC3: shell dollar metachar rejected"
        ()
```

### 17.3.5. Ejemplo 5: Resolutor de archivos estáticos en *sandbox*: validación contra saltos `..`, bytes nulos y extracción de `dirname`/`basename`/`ext`/`stem`

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `path` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
import path

fn :: resolver archivo seguro (raiz : String) (peticion : String) => (String, String, String, String)
      resolver archivo seguro raiz peticion =
        ruta_final = path resolve under raiz peticion
        | ruta_final == "" = ("denegado", "", "", "")
        | otherwise        =
          dir  = path dirname ruta_final
          base = path basename ruta_final
          ext  = path ext ruta_final
          stem = path stem ruta_final
          (ruta_final, dir, base, "{stem} ({ext})")
```

---

## 17.4. Bajo el capó: cómo está construida `path` en Ridgun puro (`src/main/ridgun/lib/path.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/path.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 17.4.1. Implementación interna: Core Implementation Part 1

Fíjate en cómo `path.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: pa split slash loop String Int Int Int => [String]
      pa split slash loop p start idx len =
        | idx >= len                = [(str slice p start len)]
        | (str char at p idx) == 47 = [(str slice p start idx)] :: (pa split slash loop p (idx + 1) (idx + 1) len)
        | otherwise                 = pa split slash loop p start (idx + 1) len

fn :: pa rev strs [String] [String] => [String]
      pa rev strs []       acc      =  acc
      pa rev strs (x:rest) acc      =  pa rev strs rest ([x] :: acc)

fn :: pa join slash [String] => String
      pa join slash []       =  ""
      pa join slash (x:[])   =  x
      pa join slash (x:rest) =  x + "/" + (pa join slash rest)

fn :: pa pop stack [String] Bool  => [String]
      pa pop stack []       True  =  []
      pa pop stack []       False =  [".."]
      pa pop stack (top:rs) is_ab =
        | top == ".." = ["..", ".."] :: rs
        | otherwise   = rs

fn :: pa norm segs [String] [String] Bool => [String]
      pa norm segs [] stack _ = pa rev strs stack []
      pa norm segs (s:rest) stack is_ab =
        | (str len s) == 0 or s == "." = pa norm segs rest stack is_ab
        | s == ".."                    = pa norm segs rest (pa pop stack stack is_ab) is_ab
        | otherwise                    = pa norm segs rest ([s] :: stack) is_ab

fn :: pa finish clean String Bool  => String
      pa finish clean joined True  =
        | (str len joined) == 0 = "/"
        | otherwise             = "/" + joined
      pa finish clean joined False =
        | (str len joined) == 0 = "."
        | otherwise             = joined
```

### 17.4.2. Implementación interna: Core Implementation Part 2

Fíjate en cómo `path.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: path is abs String => Bool
      path is abs p      =
        | (str len p) == 0        = False
        | (str char at p 0) == 47 = True
        | otherwise               = False

fn :: path is rel String => Bool
      path is rel p      =  not (path is abs p)

fn :: path clean String => String
      path clean p      =
        | (str len p) == 0 = "."
        | otherwise =
          is_ab = path is abs p
          segs  = pa split slash loop p 0 0 (str len p)
          norm  = pa norm segs segs [] is_ab
          pa finish clean (pa join slash norm) is_ab

fn :: path join String String => String
      path join a      b      =
        | (str len a) == 0 = path clean b
        | (str len b) == 0 = path clean a
        | path is abs b    = path clean b
        | otherwise        = path clean (a + "/" + b)

fn :: path join list [String]   => String
      path join list []         =  "."
      path join list (x:[])     =  path clean x
      path join list (x:y:rest) =  path join list ([(path join x y)] :: rest)

fn :: pa last char idx String Int Int => Int
      pa last char idx s ch idx =
        | idx < 0                   = 0 - 1
        | (str char at s idx) == ch = idx
        | otherwise                 = pa last char idx s ch (idx - 1)
```

### 17.4.3. Implementación interna: Core Implementation Part 4

Fíjate en cómo `path.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: path ext String => String
      path ext p      =
        base = path basename p
        pa ext at base (pa last char idx base 46 ((str len base) - 1))

fn :: pa stem at String Int => String
      pa stem at base   dot =
        | dot <= 0  = base
        | otherwise = str slice base 0 dot

fn :: path stem String => String
      path stem p      =
        base = path basename p
        pa stem at base (pa last char idx base 46 ((str len base) - 1))

fn :: pa norm ext String => String
      pa norm ext ext    =
        | (str len ext) == 0        = ""
        | (str char at ext 0) == 46 = ext
        | otherwise                 = "." + ext

fn :: pa combine dir base String String => String
      pa combine dir base dir base =
        | dir == "." = base
        | dir == "/" = "/" + base
        | otherwise  = dir + "/" + base

fn :: path replace ext String String  => String
      path replace ext p      new_ext =
        pa combine dir base (path dirname p) ((path stem p) + (pa norm ext new_ext))

fn :: pa is safe char Int => Bool
      pa is safe char c   =
        | c >= 48 and c <= 57                        = True
        | c >= 65 and c <= 90                        = True
        | c >= 97 and c <= 122                       = True
        | c == 47 or c == 46 or c == 95 or c == 45   = True
        | otherwise                                  = False
```

### 17.4.4. Implementación interna: Core Implementation Part 5

Fíjate en cómo `path.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: pa safe chars loop String Int Int => Bool
      pa safe chars loop s idx len =
        | idx >= len                          = True
        | not (pa is safe char (str char at s idx)) = False
        | otherwise                           = pa safe chars loop s (idx + 1) len

fn :: pa check prefix String String => Bool
      pa check prefix bclean full   =
        | bclean == "/" = path is abs full
        | full == bclean = True
        | otherwise     = str starts with full (bclean + "/")

fn :: path is safe subpath String String => Bool
      path is safe subpath base child =
        | (str len base) == 0 or (str len child) == 0          = False
        | path is abs child                                    = False
        | not (pa safe chars loop base 0 (str len base))       = False
        | not (pa safe chars loop child 0 (str len child))     = False
        | otherwise =
          bclean = path clean base
          full   = path clean (bclean + "/" + child)
          pa check prefix bclean full
```

---

## 17.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `path`

- **Garantía algorítmica y de seguridad**: `path is safe subpath` rechaza rutas absolutas, bytes NUL y cualquier secuencia `..` que intente escapar del directorio raíz o de un prefijo hermano (`/srv/www-secret`).
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/path.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test path.rg`.

### Las 5 Reglas de Oro al programar con `path`

1. **Declara `import path` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `path` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `path` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `path` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 18** pasaremos a explorar en profundidad la lib **`time`** (La lib `time` — Calendario Civil UTC (Hinnant), ISO-8601, Duraciones y Backoff).
