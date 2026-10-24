# Capítulo 12: La lib `glob` — Patrones de Comodines (`*`, `?`, `[a-z]`) y Filtrado de Listas

## 12.1. ¿Por qué existe la lib `glob`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `glob` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `glob`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: usar una expresión regular completa solo para comprobar si un archivo termina en `*.rg` o empieza por `test_[0-9]*.rg` es matar moscas a cañonazos.

La lib **`glob`** implementa coincidencia exacta de comodines de shell (`*`, `?`, clases `[a-z]`, clases negadas `[!0-9]` / `[^a-z]`), variantes insensibles a mayúsculas (`glob match ci`) y filtrado directo de listas de rutas o nombres.

En un ecosistema tradicional, resolver las tareas del dominio **`GLOB`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`glob`** (`src/main/ridgun/lib/glob.rg`) aborda el problema con cuatro principios innegociables:

1. **Funciones totales y contratos explícitos (`=>`)**: ninguna función de `glob` lanza excepciones ocultas ni depende de `null`. Todo caso límite (entradas vacías, divisores cero, tramas truncadas o índices fuera de rango) devuelve un valor centinela documentado o un tipo algebraico suma (`Option`, `Result`).
2. **Cero código C y cero `libc`**: todo el código de `glob` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `glob` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 12.2. Artefactos nativos, importación y catálogo completo de la API de `glob`

En `ridgun-libs`, **`glob`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/glob.rg` (dominio `GLOB`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/glob.rglib` | Distribución e importación directa con `import glob` |
| **Archivo compilado** | `target/glob.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libglob.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import glob` en el encabezado y llamar a sus funciones con espacios (`mi funcion x`) o guiones bajos (`mi_funcion x`) indistintamente.

### 12.2.1. Resumen de familias funcionales de `glob`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `glob match / glob match ci` | Coincidencia de patrones glob sensible e insensible a mayúsculas ASCII |
| `glob filter / glob any match` | Filtra `[String]` según un patrón o comprueba si coincide algún patrón de una lista |
| `glob has magic` | Detecta si una cadena contiene metacaracteres de comodín (`*`, `?`, `[`) |

### 12.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/glob.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/glob.rg` (`0` tipos, `0` operadores y `18` funciones):

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: gl lower char String Int Int` | `String` |
| `2` | `fn :: gl to lower loop String Int Int` | `String` |
| `3` | `fn :: gl to lower String` | `String` |
| `4` | `fn :: gl find close bracket String Int Int` | `Int` |
| `5` | `fn :: gl match range String Int Int Int Int Int` | `Bool` |
| `6` | `fn :: gl match class body String Int Int Int` | `Bool` |
| `7` | `fn :: gl eval bracket char String Int Int Int Int` | `Bool` |
| `8` | `fn :: gl eval bracket String Int Int Int` | `Bool` |
| `9` | `fn :: gl skip stars String Int Int` | `Int` |
| `10` | `fn :: gl match star String Int Int String Int Int` | `Bool` |
| `11` | `fn :: gl match star at String Int Int String Int Int` | `Bool` |
| `12` | `fn :: gl match bracket step String Int Int String Int Int Int` | `Bool` |
| `13` | `fn :: gl match step String Int Int String Int Int Int` | `Bool` |
| `14` | `fn :: gl match loop String Int Int String Int Int` | `Bool` |
| `15` | `fn :: glob match String String` | `Bool` |
| `16` | `fn :: glob match ci String String` | `Bool` |
| `17` | `fn :: glob filter String [String]` | `[String]` |
| `18` | `fn :: glob any match [String] String` | `Bool` |

---

## 12.3. Explorando `glob` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `glob` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test glob.rg`.

### 12.3.1. Ejemplo 1: Flujo principal en estilo tabular con `glob`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `glob` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import glob

fn :: seleccionar fuentes ridgun (archivos : [String]) => [String]
      seleccionar fuentes ridgun archivos =
        glob filter "test_[a-z]*.rg" archivos
```

### 12.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `glob` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import glob

fn :: es ruta excluida (ruta : String) => Bool
      es ruta excluida ruta =
        glob any match ["*.tmp", "*.bak", "target/*"] ruta
```

### 12.3.3. Ejemplo 3: Comodines `*` y `?`, coincidencia exacta de extremos y casos límite con patrones vacíos

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `glob` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test glob wildcards and boundaries => ()
      test glob wildcards and boundaries =
        _ = assert true (glob match "" "") "AC1: empty pattern matches empty string"
        _ = assert false (glob match "" "a") "AC1: empty pattern rejects non-empty"
        _ = assert true (glob match "*" "") "AC1: * matches empty string"
        _ = assert true (glob match "***" "") "AC1: *** matches empty string"
        _ = assert true (glob match "*" "anything.rg") "AC1: * matches full filename"
        _ = assert true (glob match "*.rg" "socket.rg") "AC1: *.rg matches socket.rg"
        _ = assert true (glob match "*.rg" ".rg") "AC1: *.rg matches leading dot .rg"
        _ = assert false (glob match "*.rg" "README.md") "AC1: *.rg rejects README.md"
        _ = assert false (glob match "*.rg" "socket.rg.bak") "AC1: *.rg rejects trailing suffix"
        _ = assert true (glob match "test_?.rg" "test_a.rg") "AC1: ? matches single char"
        _ = assert false (glob match "test_?.rg" "test_.rg") "AC1: ? rejects zero chars"
        _ = assert false (glob match "test_?.rg" "test_ab.rg") "AC1: ? rejects two chars"
        _ = assert true (glob match "???" "abc") "AC1: ??? matches 3 chars"
        _ = assert false (glob match "???" "ab") "AC1: ??? rejects 2 chars"
        _ = assert true (glob match "a*b*c" "abc") "AC1: multiple * matching zero chars"
        _ = assert true (glob match "a*b*c" "axxxbyyyc") "AC1: multiple * matching substrings"
        _ = assert true (glob match "a*b*c" "abbc") "AC1: backtracking * across repeated b"
        _ = assert false (glob match "a*b*c" "axxxbyyy") "AC1: missing trailing literal after *"
        _ = assert true (glob match "a***b" "axyzb") "AC1: collapsed *** matches"
        -- Pathological backtracking immunity via gl_skip_stars
        _ = assert false (glob match "****************a" "bbbbbbbbbbbbbbbbbbbbbbbbbbbb") "AC1: collapsed stars avoid exponential backtracking"
        ()
```

### 12.3.4. Ejemplo 4: Clases de caracteres `[a-z]`, rangos negados `[!0-9]` / `[^0-9]` y coincidencia insensible a mayúsculas (`glob match ci`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `glob` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test glob classes and case insensitivity => ()
      test glob classes and case insensitivity =
        _ = assert true (glob match "file_[0-9].txt" "file_0.txt") "AC2: [0-9] lower bound 0"
        _ = assert true (glob match "file_[0-9].txt" "file_9.txt") "AC2: [0-9] upper bound 9"
        _ = assert false (glob match "file_[0-9].txt" "file_a.txt") "AC2: [0-9] rejects alpha"
        _ = assert true (glob match "id_[a-zA-Z0-9].rg" "id_Z.rg") "AC2: multi-range [a-zA-Z0-9] matches Z"
        _ = assert true (glob match "id_[a-zA-Z0-9].rg" "id_5.rg") "AC2: multi-range [a-zA-Z0-9] matches 5"
        _ = assert false (glob match "id_[a-zA-Z0-9].rg" "id__.rg") "AC2: multi-range [a-zA-Z0-9] rejects _"
        _ = assert true (glob match "v[135].rg" "v3.rg") "AC2: discrete character set [135]"
        _ = assert false (glob match "v[135].rg" "v2.rg") "AC2: discrete character set rejects 2"
        _ = assert true (glob match "file_[!0-9].txt" "file_a.txt") "AC2: [!0-9] POSIX negated class"
        _ = assert false (glob match "file_[!0-9].txt" "file_7.txt") "AC2: [!0-9] rejects digit"
        _ = assert true (glob match "file_[^0-9].txt" "file_z.txt") "AC2: [^0-9] caret negated class"
        _ = assert false (glob match "file_[^0-9].txt" "file_0.txt") "AC2: [^0-9] rejects digit"
        _ = assert true (glob match "a[b" "a[b") "AC2: unclosed '[' matches literally"
        _ = assert false (glob match "a[b" "axb") "AC2: unclosed '[' rejects non-bracket"

        -- Case-insensitive matching
        _ = assert true (glob match ci "*.RG" "socket.rg") "AC2: glob_match_ci *.RG on lowercase"
        _ = assert true (glob match ci "*.rg" "SOCKET.RG") "AC2: glob_match_ci *.rg on uppercase"
        _ = assert true (glob match ci "src/**/Test_[A-Z]*.rg" "SRC/main/test_crypto.RG") "AC2: glob_match_ci mixed case"
        ()
```

### 12.3.5. Ejemplo 5: Filtrado masivo de listas de rutas (`glob filter`) y comprobación contra múltiples patrones (`glob any match`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `glob` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test glob filter and any match => ()
      test glob filter and any match =
        files = ["socket.rg", "README.md", "test_socket.rg", "crypto.rg", "build.sh"]
        _ = assert eq (glob filter "*.rg" files) ["socket.rg", "test_socket.rg", "crypto.rg"]
        _ = assert eq (glob filter "test_*.rg" files) ["test_socket.rg"]
        _ = assert eq (glob filter "*.nomatch" files) []
        _ = assert eq (glob filter "*.rg" []) []
        _ = assert true (glob any match ["*.md", "*.txt", "*.sh"] "README.md") "AC3: glob_any_match first pattern"
        _ = assert true (glob any match ["*.md", "*.txt", "*.sh"] "build.sh") "AC3: glob_any_match last pattern"
        _ = assert false (glob any match ["*.md", "*.txt"] "socket.rg") "AC3: glob_any_match no match"
        _ = assert false (glob any match [] "socket.rg") "AC3: glob_any_match empty pattern list"
        ()
```

---

## 12.4. Bajo el capó: cómo está construida `glob` en Ridgun puro (`src/main/ridgun/lib/glob.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/glob.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 12.4.1. Implementación interna: Bracket Character Class `[...]` Matching

Fíjate en cómo `glob.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: gl find close bracket String Int Int => Int
      gl find close bracket pat idx plen =
        | idx >= plen                  = 0 - 1
        | (str char at pat idx) == 93  = idx
        | otherwise                    = gl find close bracket pat (idx + 1) plen

fn :: gl match range String Int Int Int Int Int => Bool
      gl match range pat idx end_idx tc lo hi =
        | tc >= lo and tc <= hi = True
        | otherwise             = gl match class body pat (idx + 3) end_idx tc

fn :: gl match class body String Int Int Int => Bool
      gl match class body pat idx end_idx tc =
        | idx >= end_idx = False
        | ((idx + 2) < end_idx) and ((str char at pat (idx + 1)) == 45) =
          gl match range pat idx end_idx tc (str char at pat idx) (str char at pat (idx + 2))
        | (str char at pat idx) == tc = True
        | otherwise                   = gl match class body pat (idx + 1) end_idx tc

fn :: gl eval bracket char String Int Int Int Int => Bool
      gl eval bracket char pat pstart close_idx tc c0 =
        | c0 == 33 or c0 == 94 = not (gl match class body pat (pstart + 1) close_idx tc)
        | otherwise            = gl match class body pat pstart close_idx tc

fn :: gl eval bracket String Int Int Int => Bool
      gl eval bracket pat pstart close_idx tc =
        gl eval bracket char pat pstart close_idx tc (str char at pat pstart)
```

### 12.4.2. Implementación interna: Wildcard (`*`, `?`, `[...]`) Matcher

Fíjate en cómo `glob.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: gl skip stars String Int Int => Int
      gl skip stars pat pidx plen =
        | pidx >= plen                 = pidx
        | (str char at pat pidx) == 42 = gl skip stars pat (pidx + 1) plen
        | otherwise                    = pidx

fn :: gl match star String Int Int String Int Int => Bool
      gl match star pat pidx plen txt tidx tlen =
        | gl match loop pat pidx plen txt tidx tlen = True
        | tidx >= tlen                              = False
        | otherwise                                 = gl match star pat pidx plen txt (tidx + 1) tlen

fn :: gl match star at String Int Int String Int Int => Bool
      gl match star at pat next_p plen txt tidx tlen =
        | next_p >= plen = True
        | otherwise      = gl match star pat next_p plen txt tidx tlen

fn :: gl match bracket step String Int Int String Int Int Int => Bool
      gl match bracket step pat pidx plen txt tidx tlen close_idx =
        | close_idx < 0 =
          | (str char at txt tidx) == 91 = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
          | otherwise                    = False |.
        | gl eval bracket pat (pidx + 1) close_idx (str char at txt tidx) =
          gl match loop pat (close_idx + 1) plen txt (tidx + 1) tlen
        | otherwise = False

fn :: gl match step String Int Int String Int Int Int => Bool
      gl match step pat pidx plen txt tidx tlen pc =
        | pc == 42                     = gl match star at pat (gl skip stars pat (pidx + 1) plen) plen txt tidx tlen
        | tidx >= tlen                 = False
        | pc == 63                     = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
        | pc == 91                     = gl match bracket step pat pidx plen txt tidx tlen (gl find close bracket pat (pidx + 1) plen)
        | pc == (str char at txt tidx) = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
        | otherwise                    = False

fn :: gl match loop String Int Int String Int Int => Bool
      gl match loop pat pidx plen txt tidx tlen =
        | pidx >= plen = tidx >= tlen
        | otherwise    = gl match step pat pidx plen txt tidx tlen (str char at pat pidx)

fn :: glob match String String => Bool
      glob match pat    txt    =  gl match loop pat 0 (str len pat) txt 0 (str len txt)

fn :: glob match ci String String => Bool
      glob match ci pat    txt    =  glob match (gl to lower pat) (gl to lower txt)
```

---

## 12.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `glob`

- **Garantía algorítmica y de seguridad**: Colapso automático de estrellas consecutivas (`***` $\rightarrow$ `*`) para evitar retrocesos redundantes y manejo seguro de corchetes sin cerrar `[`.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/glob.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test glob.rg`.

### Las 5 Reglas de Oro al programar con `glob`

1. **Declara `import glob` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `glob` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `glob` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `glob` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 13** pasaremos a explorar en profundidad la lib **`diff`** (La lib `diff` — Algoritmo LCS, Distancia de Edición, Unified Diff y Parches).
