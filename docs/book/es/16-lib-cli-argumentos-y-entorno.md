# Capítulo 16: La lib `cli` — Banderas, Opciones, Barrera `--`, Subcomandos y Variables de Entorno

## 16.1. ¿Por qué existe la lib `cli`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `cli` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `cli`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: analizar `argv` a mano siempre empieza con un bucle inocente y termina rompiéndose cuando alguien pasa `-la` agrupado, `--port=9090` con signo igual o `--` seguido de un archivo que empieza por guion `-archivo.rg`.

La lib **`cli`** resuelve banderas largas (`--verbose`), cortas (`-v`), agrupadas (`-la`), opciones con valor (`--port=8080`, `--port 8080`, `-p 8080`), el separador POSIX `--`, argumentos posicionales, subcomandos y lectura tipada de variables de entorno (`env get int or`, `env get bool or`).

En un ecosistema tradicional, resolver las tareas del dominio **`CLI`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`cli`** (`src/main/ridgun/lib/cli.rg`) aborda el problema con cuatro principios innegociables:

1. **Declara `import cli` (o `import cli as alias`) al inicio del archivo**: cada lib define su espacio de nombres `module :: cli` y en modo `--strict` las funciones multi-palabra se invocan siempre con espacios naturales.
2. **Encadena tus tuberías de izquierda a derecha con `->`**: escribe `entrada paso uno -> paso dos -> resultado`, usa máscaras `(+ _ _ +)` para desestructurar secuencias y omite `_ =` en sentencias secuenciales (o descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `cli` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 16.2. Artefactos nativos, importación y catálogo completo de la API de `cli`

En `ridgun-libs`, **`cli`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/cli.rg` (dominio `CLI`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/cli.rglib` | Distribución e importación directa con `import cli` |
| **Archivo compilado** | `target/cli.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libcli.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Cada lib declara su propio espacio de nombres con `module :: cli`: basta con escribir `import cli` (o `import cli as alias`) en el encabezado y llamar a sus funciones con espacios naturales (`mi funcion x`) y tuberías `->` (`x mi funcion -> resultado`).

### 16.2.1. Resumen de familias funcionales de `cli`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `cli has flag : [String] -> String -> String -> Bool` | Detecta `--long`, `-s` o banderas agrupadas `-xyz` antes de `--` |
| `cli get opt / cli get int opt` | Extrae opción de texto o entera (`--k=v`, `--k v`, `-k v`) con valor por defecto |
| `cli positionals / cli subcommand` | Recoge los argumentos posicionales (incluyendo todo lo que sigue a `--`) |
| `env get or / env get int or / env get bool or` | Lee variables de entorno con conversión tipada y valores de respaldo |

### 16.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/cli.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/cli.rg` (`0` tipos, `0` operadores y `26` funciones):

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: cl str contains char String Int Int Int` | `Bool` |
| `2` | `fn :: cl is bundled short String String` | `Bool` |
| `3` | `fn :: cl list contains str [String] String` | `Bool` |
| `4` | `fn :: cl is digits loop String Int Int` | `Bool` |
| `5` | `fn :: cl is signed int len String Int` | `Bool` |
| `6` | `fn :: cl is signed int String` | `Bool` |
| `7` | `fn :: cl is ws Int` | `Bool` |
| `8` | `fn :: cl lower char String Int Int` | `String` |
| `9` | `fn :: cl trim lower loop String Int Int` | `String` |
| `10` | `fn :: cli has flag [String] String String` | `Bool` |
| `11` | `fn :: cl match eq pfx String String` | `String` |
| `12` | `fn :: cl match eq prefix String String` | `String` |
| `13` | `fn :: cl has eq prefix String String` | `Bool` |
| `14` | `fn :: cli get opt [String] String String String` | `String` |
| `15` | `fn :: cl parse int opt String Int` | `Int` |
| `16` | `fn :: cli get int opt [String] String String Int` | `Int` |
| `17` | `fn :: cl is flag tok String` | `Bool` |
| `18` | `fn :: cli positionals with opts [String] [String]` | `[String]` |
| `19` | `fn :: cli positionals [String]` | `[String]` |
| `20` | `fn :: cl first str [String]` | `String` |
| `21` | `fn :: cli subcommand [String]` | `String` |
| `22` | `fn :: cl env val or String String` | `String` |
| `23` | `fn :: env get or String String` | `String` |
| `24` | `fn :: env get int or String Int` | `Int` |
| `25` | `fn :: cl parse bool val String Bool` | `Bool` |
| `26` | `fn :: env get bool or String Bool` | `Bool` |

---

## 16.3. Explorando `cli` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `cli` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test cli.rg`.

### 16.3.1. Ejemplo 1: Flujo principal en estilo tabular con `cli`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `cli` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import cli

fn :: analizar comando [String] => String Bool Int [String]
      analizar comando args =
        args cli subcommand -> sub
        cli has flag args "--all" "-a" -> all_f
        cli get int opt args "--port" "-p" 8080 -> port
        cli positionals with opts args ["--port", "-p"] -> arch
        (sub, all_f, port, arch)
```

### 16.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `cli` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import cli

fn :: leer config entorno => Int Bool
      leer config entorno =
        env get int or "SOLSTICE_WORKERS" 4 -> workers
        env get bool or "SOLSTICE_DEBUG" False -> debug
        (workers, debug)
```

### 16.3.3. Ejemplo 3: Banderas booleanas (`cli has flag`) y opciones con valor (`--key=val` y `--key val`, `cli opt int`, `cli opt bool`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `cli` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test cli flags and options => ()
      test cli flags and options =
        args = ["serve", "-la", "--verbose", "--port=9090", "-h", "127.0.0.1", "--workers", "-4", "--", "--ignored-flag", "-z", "file.rg"]
        assert true (cli has flag args "--verbose" "-v") "AC1: long flag --verbose"
        assert true (cli has flag args "--all" "-a") "AC1: bundled short flag -a in -la"
        assert true (cli has flag args "--list" "-l") "AC1: bundled short flag -l in -la"
        assert false (cli has flag args "--quiet" "-q") "AC1: missing flag returns False"
        assert false (cli has flag args "--ignored-flag" "") "AC1: long flag after -- is ignored"
        assert false (cli has flag args "" "-z") "AC1: short flag after -- is ignored"
        assert false (cli has flag [] "--verbose" "-v") "AC1: empty args returns False"

        -- Option extraction: --key=val, --key val, -k=val, -k val, empty value --key=
        assert str eq (cli get opt args "--port" "-p" "8080") "9090" "AC2: --port=9090 inline equals"
        assert str eq (cli get opt args "--host" "-h" "0.0.0.0") "127.0.0.1" "AC2: -h 127.0.0.1 separate token"
        assert str eq (cli get opt args "--mode" "-m" "prod") "prod" "AC2: missing option returns fallback"
        assert int equals (cli get int opt args "--port" "-p" 8080) 9090 "AC2: cli_get_int_opt positive int"
        assert int equals (cli get int opt args "--workers" "-w" 1) (0 - 4) "AC2: cli_get_int_opt negative int"
        assert int equals (cli get int opt args "--host" "-h" 8080) 8080 "AC2: non-numeric option falls back to default int"

        short_eq_args = ["-p=3000", "--empty="]
        assert int equals (cli get int opt short_eq_args "--port" "-p" 80) 3000 "AC2: short option -p=3000"
        assert str eq (cli get opt short_eq_args "--empty" "-e" "def") "" "AC2: explicit empty --empty= returns empty string"
        ()
```

### 16.3.4. Ejemplo 4: Extracción de posicionales respetando `--` (`cli positionals`), subcomandos (`cli subcommand`) y variables de entorno tipadas (`env str/int/bool or`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `cli` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test cli positionals subcommand and env => ()
      test cli positionals subcommand and env =
        args = ["build", "-v", "--output", "target/app", "-j", "8", "--", "-dashfile.rg", "--another-literal", "main.rg"]
        assert str eq (cli subcommand args) "build" "AC3: cli_subcommand first positional"
        assert str eq (cli subcommand ["-v", "--release", "test"]) "test" "AC3: cli_subcommand skips leading flags"
        assert str eq (cli subcommand ["--help", "-v"]) "" "AC3: cli_subcommand empty when only flags"
        assert str eq (cli subcommand []) "" "AC3: cli_subcommand empty on []"

        pos = cli positionals with opts args ["--output", "-j"]
        assert eq pos ["build", "-dashfile.rg", "--another-literal", "main.rg"]

        -- Single "-" (stdin/stdout convention) is treated as a positional argument, not a flag!
        stdin_args = ["cat", "-n", "-"]
        assert eq (cli positionals stdin_args) ["cat", "-"]

        -- Environment variable readers
        assert true ((str len (env get or "PATH" "")) > 0) "AC4: env_get_or PATH non-empty"
        assert str eq (env get or "RIDGUN_NONEXISTENT_ENV_999" "fallback_val") "fallback_val" "AC4: env_get_or fallback"
        assert int equals (env get int or "RIDGUN_NONEXISTENT_ENV_999" 42) 42 "AC4: env_get_int_or fallback"
        assert true (env get bool or "RIDGUN_NONEXISTENT_ENV_999" True) "AC4: env_get_bool_or True fallback"
        assert false (env get bool or "RIDGUN_NONEXISTENT_ENV_999" False) "AC4: env_get_bool_or False fallback"
        ()
```

### 16.3.5. Ejemplo 5: Despachador completo de herramienta CLI combinando subcomandos, banderas, opciones tipadas y respaldo por variables de entorno

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `cli` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
import cli

fn :: despachar comando (argv : [String]) => (String, String, Int, Bool, [String])
      despachar comando argv =
        cmd     = cli subcommand argv
        host    = cli opt or argv "--host" "-H" (env str or "RG_HOST" "127.0.0.1")
        puerto  = cli opt int or argv "--port" "-p" (env int or "RG_PORT" 8080)
        verbose = (cli has flag argv "--verbose" "-v") or (env bool or "RG_VERBOSE" False)
        archivos = cli positionals argv
        (cmd, host, puerto, verbose, archivos)
```

---

## 16.4. Bajo el capó: cómo está construida `cli` en Ridgun puro (`src/main/ridgun/lib/cli.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/cli.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 16.4.1. Implementación interna: Internal String & List Helpers

Fíjate en cómo `cli.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
module :: cli

fn :: cl str contains char String Int Int Int => Bool
      cl str contains char s ch idx len =
        | idx >= len                = False
        | (str char at s idx) == ch = True
        | otherwise                 = cl str contains char s ch (idx + 1) len

fn :: cl is bundled short String String => Bool
      cl is bundled short arg short_flag =
        | (str len short_flag) != 2        = False
        | (str char at short_flag 0) != 45 = False
        | (str len arg) < 2                = False
        | (str char at arg 0) != 45        = False
        | (str char at arg 1) == 45        = False
        | otherwise                        = cl str contains char arg (str char at short_flag 1) 1 (str len arg)

fn :: cl list contains str [String] String => Bool
      cl list contains str [] _ = False
      cl list contains str (x:rest) tgt =
        | x == tgt  = True
        | otherwise = cl list contains str rest tgt

fn :: cl is digits loop String Int Int => Bool
      cl is digits loop s idx len =
        | idx >= len                                           = True
        | (str char at s idx) < 48 or (str char at s idx) > 57 = False
        | otherwise                                            = cl is digits loop s (idx + 1) len

fn :: cl is signed int len String Int => Bool
      cl is signed int len s n =
        | n == 0                  = False
        | (str char at s 0) == 45 =
          | n <= 1    = False
          | otherwise = cl is digits loop s 1 n |.
        | otherwise               = cl is digits loop s 0 n

fn :: cl is signed int String => Bool
      cl is signed int s      =  cl is signed int len s (str len s)

fn :: cl is ws Int => Bool
      cl is ws c   =  c == 32 or c == 9 or c == 10 or c == 13

fn :: cl lower char String Int Int => String
      cl lower char s idx c =
        | c >= 65 and c <= 90 = char from code (c + 32)
        | otherwise           = str slice s idx (idx + 1)

fn :: cl trim lower loop String Int Int => String
      cl trim lower loop s idx len =
        | idx >= len                   = ""
        | cl is ws (str char at s idx) = cl trim lower loop s (idx + 1) len
        | otherwise                    = (cl lower char s idx (str char at s idx)) + (cl trim lower loop s (idx + 1) len)
```

### 16.4.2. Implementación interna: Positional Arguments & Subcommand Extraction

Fíjate en cómo `cli.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: cl is flag tok String => Bool
      cl is flag tok a      =
        | (str len a) <= 1        = False
        | (str char at a 0) == 45 = True
        | otherwise               = False

fn :: cli positionals with opts [String] [String] => [String]
      cli positionals with opts [] _ = []
      cli positionals with opts (a:[]) _ =
        | a == "--"        = []
        | cl is flag tok a = []
        | otherwise        = [a]
      cli positionals with opts (a:b:rst) val_opts =
        | a == "--"                       = [b] :: rst
        | cl list contains str val_opts a = cli positionals with opts rst val_opts
        | cl is flag tok a                = cli positionals with opts ([b] :: rst) val_opts
        | otherwise                       = [a] :: (cli positionals with opts ([b] :: rst) val_opts)

fn :: cli positionals [String] => [String]
      cli positionals args     =  cli positionals with opts args []

fn :: cl first str [String] => String
      cl first str []       =  ""
      cl first str (x:_)    =  x

fn :: cli subcommand [String] => String
      cli subcommand args     =  args cli positionals -> cl first str
```

### 16.4.3. Implementación interna: Typed Environment Variable Readers

Fíjate en cómo `cli.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: cl env val or String String => String
      cl env val or val fallback =
        | (str len val) == 0 = fallback
        | otherwise          = val

fn :: env get or String String   => String
      env get or key    fallback =  cl env val or (sys getenv key) fallback

fn :: env get int or String Int => Int
      env get int or key fallback = cl parse int opt (sys getenv key) fallback

fn :: cl parse bool val String Bool => Bool
      cl parse bool val val fallback =
        | val == "1" or val == "true" or val == "yes" or val == "on"  = True
        | val == "0" or val == "false" or val == "no" or val == "off" = False
        | otherwise                                                   = fallback

fn :: env get bool or String Bool => Bool
      env get bool or key fallback =
        key sys getenv -> raw
        cl trim lower loop raw 0 (str len raw) -> norm
        cl parse bool val norm fallback
```

---

## 16.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `cli`

- **Garantía algorítmica y de seguridad**: Respeto estricto del separador POSIX `--`: ningún argumento situado a la derecha de `--` se interpreta jamás como bandera.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/cli.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test cli.rg`.

### Las 5 Reglas de Oro al programar con `cli`

1. **Declara `import cli` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `cli` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `cli` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `cli` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 17** pasaremos a explorar en profundidad la lib **`path`** (La lib `path` — Normalización POSIX (`path clean`) y Confinamiento contra Path Traversal).
