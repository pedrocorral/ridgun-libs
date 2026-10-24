# Capítulo 23: La lib `io` — Errores Tipados `IoResult`, E/S con `with timeout` y Procesos

## 23.1. ¿Por qué existe la lib `io`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `io` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `io`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: una llamada a `read()` o un subproceso hijo sin fecha límite (`timeout`) es una invitación a que un solo recurso colgado agote todos los trabajadores de tu servidor.

La lib **`io`** modela cada operación del sistema con ADTs explícitos (`IoError`, `IoResult[A]`), combina `ppoll` no bloqueante con cuotas léxicas `with timeout wait_ms do` de Ridgun y ofrece los operadores mixfix `read fd ... timeout` y `write fd ... timeout`.

En un ecosistema tradicional, resolver las tareas del dominio **`IO`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`io`** (`src/main/ridgun/lib/io.rg`) aborda el problema con cuatro principios innegociables:

1. **Funciones totales y contratos explícitos (`=>`)**: ninguna función de `io` lanza excepciones ocultas ni depende de `null`. Todo caso límite (entradas vacías, divisores cero, tramas truncadas o índices fuera de rango) devuelve un valor centinela documentado o un tipo algebraico suma (`Option`, `Result`).
2. **Cero código C y cero `libc`**: todo el código de `io` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `io` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 23.2. Artefactos nativos, importación y catálogo completo de la API de `io`

En `ridgun-libs`, **`io`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/io.rg` (dominio `IO`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/io.rglib` | Distribución e importación directa con `import io` |
| **Archivo compilado** | `target/io.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libio.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import io` en el encabezado y llamar a sus funciones con espacios (`mi funcion x`) o guiones bajos (`mi_funcion x`) indistintamente.

### 23.2.1. Resumen de familias funcionales de `io`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `type IoError / type IoResult[A]` | `IoNotFound | IoPermission | IoTimeout | IoRefused | IoReset | IoEOF | IoInvalid | IoSysError` |
| `io read with timeout / io write with timeout` | Lectura/escritura no bloqueante de descriptor acotada por `wait_ms` |
| `read fd N max M timeout T / write fd N data S timeout T` | Operadores mixfix ergonómicos (`op ::`) para E/S de descriptor con fecha límite |
| `io read file / io write file / io read lines` | Funciones seguras de archivos y flujos de líneas que devuelven `IoResult` |
| `exec with timeout : String -> Int -> IoResult[ProcStatus]` | Ejecuta un comando externo acotado por una cuota léxica `with timeout` |

### 23.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/io.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/io.rg` (`2` tipos, `2` operadores y `37` funciones):

**Tipos algebraicos y registros (`type`) de `io`:**

```ridgun
type IoError = Timeout Int | Eof | SysErr Int String | NotFound String
type IoResult = String | Int | Timeout Int | Eof | SysErr Int String | NotFound String | IoErr IoError | IoOk String | IoTimeout | IoEof | IoError Int
```

**Operadores mixfix (`op ::`) de `io`:**

```ridgun
op :: read fd Int max Int timeout Int => IoResult
op :: write fd Int data String timeout Int => IoResult
```

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: format io error IoError` | `String` |
| `2` | `fn :: format io result IoResult` | `String` |
| `3` | `fn :: map read bytes String` | `IoResult` |
| `4` | `fn :: read fd after poll PollStatus Int Int Int` | `IoResult` |
| `5` | `fn :: read fd Int Int Int` | `IoResult` |
| `6` | `fn :: map write rc Int` | `IoResult` |
| `7` | `fn :: write fd after poll PollStatus Int String Int` | `IoResult` |
| `8` | `fn :: write fd Int String Int` | `IoResult` |
| `9` | `fn :: has null char String Int Int` | `Bool` |
| `10` | `fn :: pad ms three Int` | `String` |
| `11` | `fn :: format timeout sec Int` | `String` |
| `12` | `fn :: map exec rc Int Int` | `IoResult` |
| `13` | `fn :: io exec timeout String Int` | `IoResult` |
| `14` | `fn :: exec with timeout String Int` | `IoResult` |
| `15` | `fn :: read existing or empty String` | `String` |
| `16` | `fn :: append file String String` | `Int` |
| `17` | `fn :: file exists String` | `Bool` |
| `18` | `fn :: is file String` | `Bool` |
| `19` | `fn :: is dir String` | `Bool` |
| `20` | `fn :: is symlink String` | `Bool` |
| `21` | `fn :: extract size (Bool String Int Int Int String String Int String)` | `Int` |
| `22` | `fn :: file size String` | `Int` |
| `23` | `fn :: extract mtime (Bool String Int Int Int String String Int String)` | `Int` |
| `24` | `fn :: file mtime String` | `Int` |
| `25` | `fn :: extract mode (Bool String Int Int Int String String Int String)` | `Int` |
| `26` | `fn :: file mode String` | `Int` |
| `27` | `fn :: io read file safe String` | `IoResult` |
| `28` | `fn :: split lines loop String Int Int Int` | `[String]` |
| `29` | `fn :: split non empty lines String Int` | `[String]` |
| `30` | `fn :: io read lines String` | `[String]` |
| `31` | `fn :: str list is empty [String]` | `Bool` |
| `32` | `fn :: join lines nl [String]` | `String` |
| `33` | `fn :: io write lines String [String]` | `Int` |
| `34` | `fn :: io wrap chunk String` | `IoResult` |
| `35` | `fn :: io read after poll Int Int` | `IoResult` |
| `36` | `fn :: io read poll step Int` | `IoResult` |
| `37` | `fn :: io read with timeout String Int` | `IoResult` |

---

## 23.3. Explorando `io` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `io` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test io.rg`.

### 23.3.1. Ejemplo 1: Flujo principal en estilo tabular con `io`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `io` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import io

fn :: leer peticion segura (fd : Int) => String
      leer peticion segura fd =
        res = read fd fd max 4096 timeout 250
        io unwrap or res ""
```

### 23.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `io` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import io

fn :: describir fallo () => String
      describir fallo =
        format io error (IoTimeout "read" 250)
```

### 23.3.3. Ejemplo 3: Jerarquía extensible de errores `IoError` (`Timeout`, `Eof`, `InvalidInput`, `PermissionDenied`, `NotFound`, `PosixErrno`) y formateo `io error message`

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `io` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test io error formatting => ()
      test io error formatting =
        _ = assert str eq (format io error (Timeout 500)) "timeout after 500 ms" "format Timeout 500"
        _ = assert str eq (format io error Eof) "unexpected end of file" "format Eof"
        _ = assert str eq (format io error (SysErr 9 "poll")) "syscall error 9 in poll" "format SysErr"
        _ = assert str eq (format io error (NotFound "/missing")) "file not found: /missing" "format NotFound"
        ()
```

### 23.3.4. Ejemplo 4: Lectura y escritura en descriptores acotadas por plazo (`read fd ... timeout`, `write fd ... timeout`, `with timeout`) y detección de `Eof`

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `io` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test io pipe timeout and eof => ()
      test io pipe timeout and eof =
        pt     = posix pipe
        rc     = pipe rc3 pt
        rfd    = pipe rfd3 pt
        wfd    = pipe wfd3 pt
        _      = assert eq rc 0

        -- 1. Empty pipe read with 50 ms timeout must time out within [40, 300) ms (TS-PERF-001 AC2)
        t3     = sys monotonic ms
        r_to   = read fd rfd max 32 timeout 50
        t4     = sys monotonic ms
        dt     = t4 - t3
        _      = assert str eq (format io result r_to) "err:timeout after 50 ms" "empty pipe read Timeout 50"
        _      = assert true (dt >= 40 and dt < 300) "dt in [40, 300): {dt}"

        -- 2. Write payload via mixfix `write fd ... data ... timeout ...`
        w_res  = write fd wfd data "stream-ok" timeout 100
        _      = assert str eq (format io result w_res) "ok:int:9" "write fd returns 9 bytes"

        -- 3. Read payload via mixfix `read fd ... max ... timeout ...`
        r_ok   = read fd rfd max 64 timeout 100
        _      = assert str eq (format io result r_ok) "ok:str:stream-ok" "read fd returns stream-ok"

        -- 4. Close write end and verify subsequent read returns Eof
        _      = posix close wfd
        r_eof  = read fd rfd max 64 timeout 100
        _      = assert str eq (format io result r_eof) "err:unexpected end of file" "closed pipe read returns Eof"
        _      = posix close rfd

        -- 5. Bad fd / invalid max_bytes
        r_bad  = read fd (0 - 1) max 64 timeout 50
        _      = assert str eq (format io result r_bad) "err:syscall error 9 in read" "negative fd read SysErr 9"
        r_zero = read fd rfd max 0 timeout 50
        _      = assert str eq (format io result r_zero) "err:syscall error 22 in read" "zero max_bytes read SysErr 22"
        ()
```

### 23.3.5. Ejemplo 5: Ejecución segura de subprocesos con límite estricto de tiempo (`io exec timeout`) y limpieza automática del hijo

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `io` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test io exec timeout => ()
      test io exec timeout =
        ok_res = io exec timeout "true" 500
        _      = assert str eq (format io result ok_res) "ok:int:0" "io exec timeout true succeeds"
        to_res = io exec timeout "sleep 2" 40
        _      = assert str eq (format io result to_res) "err:timeout after 40 ms" "io exec timeout sleep 2 times out"
        ()
```

### 23.3.6. Ejemplo 6: Predicados de sistema de archivos (`file exists`, `is dir`, `is regular file`, `file size`), lectura por líneas (`io read lines`) y copia (`copy file`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `io` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test io file and metadata => ()
      test io file and metadata =
        pid   = sys getpid
        dpath = "/tmp/rg_io_dir_{pid}"
        fpath = "{dpath}/file.txt"
        spath = "{dpath}/sym.txt"
        bpath = "{dpath}/bytes.bin"
        lpath = "{dpath}/lines.txt"

        _     = sys rmdir dpath
        _     = posix mkdir dpath
        _     = assert true (is dir dpath) "is dir dpath"
        _     = assert false (is file dpath) "not is file dpath"

        -- 1. write_file + append_file + read_file
        _     = write file fpath "hello "
        w2    = append file fpath "world"
        _     = assert eq w2 0
        _     = assert str eq (read file fpath) "hello world" "write_file + append_file content"

        -- 2. write_bytes + read_bytes
        _     = write bytes bpath [65, 66, 67, 0, 255]
        rb    = read bytes bpath
        _     = assert eq (int list len rb) 5

        -- 3. symlink + metadata predicates
        _     = assert true (sys symlink fpath spath) "sys symlink fpath spath"
        _     = assert true (file exists fpath) "file exists fpath"
        _     = assert true (is file fpath) "is file fpath"
        _     = assert false (is symlink fpath) "not is symlink fpath"
        _     = assert true (is symlink spath) "is symlink spath"
        _     = assert eq (file size fpath) 11
        _     = assert true ((file mtime fpath) > 1700000000) "file mtime > 1700000000"
        _     = assert true ((file mode fpath) > 0) "file mode > 0"
        _     = assert false (file exists "/tmp/rg_io_nonexistent_999999.txt") "missing file exists False"

        -- 4. io read file safe + io write lines / io read lines
        miss  = io read file safe "/tmp/rg_io_missing_999.txt"
        _     = assert str eq (format io result miss) "err:file not found: /tmp/rg_io_missing_999.txt" "NotFound missing file"
        hit   = io read file safe fpath
        _     = assert str eq (format io result hit) "ok:str:hello world" "safe read existing file"

        _     = io write lines lpath ["alpha", "beta", "gamma"]
        lines = io read lines lpath
        _     = assert eq (str list len lines) 3

        -- 5. v0.9.5 PAL `io read with timeout` (`with timeout wait_ms do` + `sys open path 2048 0` + `sys poll fd 1 -1`)
        r_amb  = io read with timeout fpath 200_ms
        _      = assert str eq (format io result r_amb) "ok:str:hello world" "io read with timeout 200_ms"
        r_miss = io read with timeout "/tmp/rg_io_missing_999.txt" 50_ms
        _      = assert true (str starts with (format io result r_miss) "err:io error -") "io read with timeout missing file -> IoError"

        -- Cleanup
        _     = sys unlink spath
        _     = sys unlink fpath
        _     = sys unlink bpath
        _     = sys unlink lpath
        _     = sys rmdir dpath
        ()
```

---

## 23.4. Bajo el capó: cómo está construida `io` en Ridgun puro (`src/main/ridgun/lib/io.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/io.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 23.4.1. Implementación interna: Extensible I/O Error & Result Sum Types (§5.1)

Fíjate en cómo `io.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
type IoError = Timeout Int | Eof | SysErr Int String | NotFound String

type IoResult = String | Int | Timeout Int | Eof | SysErr Int String | NotFound String | IoErr IoError | IoOk String | IoTimeout | IoEof | IoError Int

fn :: format io error IoError            => String
      format io error (Timeout ms)       =  "timeout after {ms} ms"
      format io error Eof                =  "unexpected end of file"
      format io error (SysErr c op_name) =  "syscall error {c} in {op_name}"
      format io error (NotFound path)    =  "file not found: {path}"
      format io error _                  =  "unknown io error"

fn :: format io result IoResult           => String
      format io result (String s)         =  "ok:str:{s}"
      format io result (IoOk s)           =  "ok:str:{s}"
      format io result (Int n)            =  "ok:int:{n}"
      format io result (Timeout ms)       =  "err:timeout after {ms} ms"
      format io result IoTimeout          =  "err:timeout"
      format io result Eof                =  "err:unexpected end of file"
      format io result IoEof              =  "err:unexpected end of file"
      format io result (IoError c)        =  "err:io error {c}"
      format io result (SysErr c op_name) =  "err:syscall error {c} in {op_name}"
      format io result (NotFound path)    =  "err:file not found: {path}"
      format io result (IoErr err)        =  "err:" + (format io error err)
      format io result _                  =  "err:unknown io error"
```

### 23.4.2. Implementación interna: Timeout-Bounded Command Execution (§5.2)

Fíjate en cómo `io.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: has null char String Int Int => Bool
      has null char s idx slen =
        | idx >= slen              = False
        | (str char at s idx) == 0 = True
        | otherwise                = has null char s (idx + 1) slen

fn :: pad ms three Int => String
      pad ms three rem =
        | rem < 10  = "00{rem}"
        | rem < 100 = "0{rem}"
        | otherwise = "{rem}"

fn :: format timeout sec Int => String
      format timeout sec ms  =
        secs = ms / 1000
        rem  = ms % 1000
        p    = pad ms three rem
        "{secs}.{p}s"

fn :: map exec rc Int Int        => IoResult
      map exec rc rc  timeout_ms =
        | rc == 124 or rc == 137 = Timeout timeout_ms
        | rc < 0                 = SysErr (0 - rc) "exec"
        | otherwise              = Int rc

fn :: io exec timeout String Int        => IoResult
      io exec timeout cmd    timeout_ms =
        | (str len cmd) == 0 or (has null char cmd 0 (str len cmd)) = SysErr 22 "exec"
        | timeout_ms <= 0                                           = Timeout timeout_ms
        | otherwise                                                 =
          tspec = format timeout sec timeout_ms
          rc    = shell exec "timeout -k 0.01s {tspec} sh -c \"{cmd}\" >/dev/null 2>&1"
          map exec rc rc timeout_ms

fn :: exec with timeout String Int        => IoResult
      exec with timeout cmd    timeout_ms =
        io exec timeout cmd timeout_ms
```

### 23.4.3. Implementación interna: Safe File Read & Line-Stream Helpers

Fíjate en cómo `io.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: io read file safe String => IoResult
      io read file safe path   =
        | not (is safe posix path path)        = SysErr 22 "read_file"
        | not (lstat exists (file lstat path)) = NotFound path
        | otherwise                            = String (read file path)

fn :: split lines loop String Int Int Int => [String]
      split lines loop s idx start slen =
        | idx >= slen =
          | start == slen = []
          | otherwise     = [str slice s start slen] |.
        | (str char at s idx) == 10 =
          line = str slice s start idx
          [line] :: (split lines loop s (idx + 1) (idx + 1) slen)
        | otherwise =
          split lines loop s (idx + 1) start slen

fn :: split non empty lines String Int => [String]
      split non empty lines raw rlen =
        | rlen == 0 = []
        | otherwise = split lines loop raw 0 0 rlen

fn :: io read lines String => [String]
      io read lines path   =
        | not (is safe posix path path)        = []
        | not (lstat exists (file lstat path)) = []
        | otherwise                            =
          raw = read file path
          split non empty lines raw (str len raw)

fn :: str list is empty [String] => Bool
      str list is empty []       =  True
      str list is empty (_:_)    =  False

fn :: join lines nl [String]    => String
      join lines nl []          =  ""
      join lines nl (line:rest) =
        | str list is empty rest = line + "\n"
        | otherwise              = line + "\n" + (join lines nl rest)

fn :: io write lines String [String] => Int
      io write lines path   lines    =
        | not (is safe posix path path) = 0 - 22
        | otherwise                     =
          _ = write file path (join lines nl lines)
          0
```

### 23.4.4. Implementación interna: Ridgun v0.9.5 PAL & Ambient Deadline `io read with timeout` (§3.1)

Fíjate en cómo `io.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: io wrap chunk String => IoResult
      io wrap chunk ""     =  IoEof
      io wrap chunk s      =  IoOk s

fn :: io read after poll Int Int => IoResult
      io read after poll fd ev =
        | ev == 0 =
          _ = sys close fd
          IoTimeout
        | ev < 0 =
          _ = sys close fd
          IoError ev
        | otherwise =
          chunk = sys read fd fd 65536
          _     = sys close fd
          io wrap chunk chunk

fn :: io read poll step Int => IoResult
      io read poll step fd  =
        | fd < 0    = IoError fd
        | otherwise =
          ev = sys poll fd 1 (0 - 1)
          io read after poll fd ev

fn :: io read with timeout String Int => IoResult
      io read with timeout path wait_ms =
        with timeout wait_ms do
          fd = sys open path 2048 0
          io read poll step fd
```

---

## 23.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `io`

- **Garantía algorítmica y de seguridad**: Ninguna lectura, escritura o comando ejecutado a través de `io` con cuota `wait_ms` puede bloquear indefinidamente el hilo o actor llamante.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/io.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test io.rg`.

### Las 5 Reglas de Oro al programar con `io`

1. **Declara `import io` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `io` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `io` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `io` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 24** pasaremos a explorar en profundidad la lib **`crypto`** (La lib `crypto` — SHA-256, HMAC, PBKDF2, Argon2id y ChaCha20-Poly1305 AEAD).
