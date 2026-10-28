# Capítulo 22: La lib `posix` — Capa de Abstracción de Plataforma (PAL), Relojes, Señales y CSPRNG

## 22.1. ¿Por qué existe la lib `posix`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `posix` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `posix`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: las banderas como `O_CREAT`, `O_NONBLOCK` o los números de syscall cambian entre Linux, macOS y arquitecturas (`X86_64` vs `Arm64`), y en C todo se resuelve con una jungla ilegible de `#ifdef`.

La lib **`posix`** implementa la **Capa de Abstracción de Plataforma (PAL)** de 2 niveles de Ridgun usando guardas tabulares sobre `sys os` (`Linux | MacOS | Windows`) y `sys arch` (`X86_64 | Arm64 | RiscV64`), además de sondeo de descriptores (`wait fd` / `PollStatus`), relojes monótonos y de pared (`RGF-017`), señales (`RGF-018`) y entropía CSPRNG del kernel (`sys random bytes`).

En un ecosistema tradicional, resolver las tareas del dominio **`POSIX`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`posix`** (`src/main/ridgun/lib/posix.rg`) aborda el problema con cuatro principios innegociables:

1. **Declara `import posix` (o `import posix as alias`) al inicio del archivo**: cada lib define su espacio de nombres `module :: posix` y en modo `--strict` las funciones multi-palabra se invocan siempre con espacios naturales.
2. **Encadena tus tuberías de izquierda a derecha con `->`**: escribe `entrada paso uno -> paso dos -> resultado`, usa máscaras `(+ _ _ +)` para desestructurar secuencias y omite `_ =` en sentencias secuenciales (o descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `posix` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 22.2. Artefactos nativos, importación y catálogo completo de la API de `posix`

En `ridgun-libs`, **`posix`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/posix.rg` (dominio `POSIX`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/posix.rglib` | Distribución e importación directa con `import posix` |
| **Archivo compilado** | `target/posix.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libposix.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Cada lib declara su propio espacio de nombres con `module :: posix`: basta con escribir `import posix` (o `import posix as alias`) en el encabezado y llamar a sus funciones con espacios naturales (`mi funcion x`) y tuberías `->` (`x mi funcion -> resultado`).

### 22.2.1. Resumen de familias funcionales de `posix`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `pal open create trunc wr / pal o nonblock` | Traducción de banderas del SO según `sys os` (`Linux | MacOS | Windows`) |
| `wait fd : Int -> Int -> Int -> PollStatus` | Sondea un descriptor devolviendo `PollReady`, `PollTimeout` o `PollError errno` |
| `clock monotonic ms / clock monotonic ns / clock wall ms` | Relojes monótonos y reloj de pared UTC en milisegundos (`RGF-017`) |
| `signal watch / signal poll / sys random bytes` | Sondeo no bloqueante de señales (`SIGINT`, `SIGTERM`) y bytes CSPRNG del kernel |
| `read text / write text / file exists / run cmd` | E/S de archivos de alto nivel, directorios y ejecución de subprocesos |

### 22.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/posix.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/posix.rg` (`2` tipos, `0` operadores y `103` funciones):

**Tipos algebraicos y registros (`type`) de `posix`:**

```ridgun
type PollStatus = PollReady Int | PollTimeout | PollError Int
type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int
```

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: poll in` | `Int` |
| `2` | `fn :: poll out` | `Int` |
| `3` | `fn :: poll err` | `Int` |
| `4` | `fn :: poll hup` | `Int` |
| `5` | `fn :: poll nval` | `Int` |
| `6` | `fn :: sig hup` | `Int` |
| `7` | `fn :: sig int` | `Int` |
| `8` | `fn :: sig quit` | `Int` |
| `9` | `fn :: sig kill` | `Int` |
| `10` | `fn :: sig usr1` | `Int` |
| `11` | `fn :: sig usr2` | `Int` |
| `12` | `fn :: sig pipe` | `Int` |
| `13` | `fn :: sig alrm` | `Int` |
| `14` | `fn :: sig term` | `Int` |
| `15` | `fn :: sig chld` | `Int` |
| `16` | `fn :: o rdonly` | `Int` |
| `17` | `fn :: o wronly` | `Int` |
| `18` | `fn :: o rdwr` | `Int` |
| `19` | `fn :: o creat` | `Int` |
| `20` | `fn :: o excl` | `Int` |
| `21` | `fn :: o trunc` | `Int` |
| `22` | `fn :: o append` | `Int` |
| `23` | `fn :: o nonblock` | `Int` |
| `24` | `fn :: o cloexec` | `Int` |
| `25` | `fn :: is bad posix code Int` | `Bool` |
| `26` | `fn :: has unsafe posix char String Int Int` | `Bool` |
| `27` | `fn :: is safe posix path len String Int` | `Bool` |
| `28` | `fn :: is safe posix path String` | `Bool` |
| `29` | `fn :: lstat exists (Bool String Int Int Int String String Int String)` | `Bool` |
| `30` | `fn :: lstat kind (Bool String Int Int Int String String Int String)` | `String` |
| `31` | `fn :: lstat mode (Bool String Int Int Int String String Int String)` | `Int` |
| `32` | `fn :: lstat size (Bool String Int Int Int String String Int String)` | `Int` |
| `33` | `fn :: lstat mtime sec (Bool String Int Int Int String String Int String)` | `Int` |
| `34` | `fn :: lstat symlink target (Bool String Int Int Int String String Int String)` | `String` |
| `35` | `fn :: px raw byte ub Int` | `String` |
| `36` | `fn :: px raw byte Int` | `String` |
| `37` | `fn :: px u64 le Int` | `String` |
| `38` | `fn :: px decode u32 le String Int` | `Int` |
| `39` | `fn :: px decode u64 le String Int` | `Int` |
| `40` | `fn :: px alloc page Int` | `Int` |
| `41` | `fn :: px free page Int Int Int` | `Int` |
| `42` | `fn :: px alloc mfd` | `Int` |
| `43` | `fn :: px poke Int Int String` | `Int` |
| `44` | `fn :: px peek Int Int Int` | `String` |
| `45` | `fn :: px clock gettime Int` | `Int Int` |
| `46` | `fn :: px pair fst (Int Int)` | `Int` |
| `47` | `fn :: px pair snd (Int Int)` | `Int` |
| `48` | `fn :: sys monotonic ms` | `Int` |
| `49` | `fn :: sys monotonic ns` | `Int` |
| `50` | `fn :: sys wall time ms` | `Int` |
| `51` | `fn :: map poll rc Int` | `PollStatus` |
| `52` | `fn :: wait fd Int Int Int` | `PollStatus` |
| `53` | `fn :: posix open String Int Int` | `Int` |
| `54` | `fn :: posix close Int` | `Int` |
| `55` | `fn :: posix read Int Int` | `String` |
| `56` | `fn :: posix write Int String` | `Int` |
| `57` | `fn :: posix kill Int Int` | `Int` |
| `58` | `fn :: pack pipe fds Int Int Int` | `Int Int Int` |
| `59` | `fn :: posix pipe` | `Int Int Int` |
| `60` | `fn :: posix mkdir String` | `Bool` |
| `61` | `fn :: posix chmod String Int` | `Bool` |
| `62` | `fn :: posix chdir String` | `Bool` |
| `63` | `fn :: px syscall1 path Int String` | `Int` |
| `64` | `fn :: px syscall2 path Int String String` | `Int` |
| `65` | `fn :: sys rmdir String` | `Bool` |
| `66` | `fn :: sys unlink String` | `Bool` |
| `67` | `fn :: sys rename String String` | `Bool` |
| `68` | `fn :: sys symlink String String` | `Bool` |
| `69` | `fn :: sys readlink String` | `String` |
| `70` | `fn :: valid signal list [Int]` | `Bool` |
| `71` | `fn :: valid signal rest [Int]` | `Bool` |
| `72` | `fn :: px bit shift Int` | `Int` |
| `73` | `fn :: px sig mask [Int]` | `Int` |
| `74` | `fn :: px finish sig watch Int` | `Int Int` |
| `75` | `fn :: sys signal watch [Int]` | `Int Int` |
| `76` | `fn :: px finish sig read Int String` | `Int Int` |
| `77` | `fn :: px wait sig after poll Int Int` | `Int Int` |
| `78` | `fn :: sys signal wait Int Int` | `Int Int` |
| `79` | `fn :: posix notify signal Int Int` | `Int` |
| `80` | `fn :: px bytes to list loop String Int Int` | `[Int]` |
| `81` | `fn :: px getrandom call Int Int Int` | `Int` |
| `82` | `fn :: px getrandom step Int Int Int` | `Int` |
| `83` | `fn :: px getrandom loop Int Int` | `Int` |
| `84` | `fn :: px finish getrandom Int String Int` | `Int String` |
| `85` | `fn :: px getrandom checked Int` | `Int String` |
| `86` | `fn :: sys random bytes Int` | `Int String` |
| `87` | `fn :: px finish random list (Int String)` | `Int [Int]` |
| `88` | `fn :: sys random bytes list Int` | `Int [Int]` |
| `89` | `fn :: path separator SysOs` | `String` |
| `90` | `fn :: null device for SysOs` | `String` |
| `91` | `fn :: null device` | `String` |
| `92` | `fn :: process exists Int` | `Bool` |

---

## 22.3. Explorando `posix` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `posix` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test posix.rg`.

### 22.3.1. Ejemplo 1: Flujo principal en estilo tabular con `posix`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `posix` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import posix

fn :: medir operacion => Int Int
      medir operacion =
        clock monotonic ms -> t0
        sys random bytes 32 -> (+ _) -> rc
        clock monotonic ms -> t1
        (rc, t1 - t0)
```

### 22.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `posix` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import posix

fn :: esperar lectura Int => PollStatus
      esperar lectura fd =
        wait fd fd (poll in) 100
```

### 22.3.3. Ejemplo 3: Constantes POSIX (`O_*`, `POLL*`, `SIG*`), validación de rutas seguras, tuberías anónimas (`sys pipe`) y sondeo `sys poll status`

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `posix` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test posix constants descriptors and poll => ()
      test posix constants descriptors and poll =
        assert equals (poll in) 1 "POLLIN == 1"
        assert equals poll out 4 "POLLOUT == 4"
        assert equals (poll err) 8 "POLLERR == 8"
        assert equals (sig int) 2 "SIGINT == 2"
        assert equals (sig kill) 9 "SIGKILL == 9"
        assert equals (sig term) 15 "SIGTERM == 15"
        assert equals (o rdonly) 0 "O_RDONLY == 0"
        assert equals (o wronly) 1 "O_WRONLY == 1"
        assert equals (o rdwr) 2 "O_RDWR == 2"
        assert equals (o creat) 64 "O_CREAT == 64"
        assert equals (o trunc) 512 "O_TRUNC == 512"
        assert equals (o append) 1024 "O_APPEND == 1024"
        assert equals (o nonblock) 2048 "O_NONBLOCK == 2048"
        assert equals (o cloexec) 524288 "O_CLOEXEC == 524288"
        bad_p   = wait fd (0 - 1) (poll in) 10
        assert true (is poll error bad_p) "wait fd on -1 returns PollError"
        p_res   = posix pipe
        assert equals (tuple3 status p_res) 0 "posix pipe status == 0"
        rfd     = tuple3 rfd p_res
        wfd     = tuple3 wfd p_res
        p_to    = wait fd rfd (poll in) 20
        assert true (is poll timeout p_to) "wait fd on empty pipe times out"
        written = posix write wfd "hello-posix"
        assert equals written 11 "posix write 11 bytes"
        p_rdy   = wait fd rfd (poll in) 100
        assert true (is poll ready p_rdy) "wait fd after write is PollReady"
        got     = posix read rfd 64
        assert equals got "hello-posix" "posix read matches written payload"
        assert equals (posix close rfd) 0 "posix close rfd"
        assert equals (posix close wfd) 0 "posix close wfd"
```

### 22.3.4. Ejemplo 4: Metadatos `lstat`, relojes monotónicos y de pared (`clock_gettime`), señales por descriptor (`signalfd4`) y entropía del kernel (`sys random bytes`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `posix` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test posix filesystem clocks signals and random => ()
      test posix filesystem clocks signals and random =
        dir_p   = "/tmp/rg_posix_test_{sys_getpid}"
        f1      = "{dir_p}/a.txt"
        f2      = "{dir_p}/b.txt"
        lnk     = "{dir_p}/sym.txt"
        sys rmdir dir_p -> ()
        assert true (posix mkdir dir_p) "posix mkdir"
        write file f1 "payload"
        assert true (posix chmod f1 420) "posix chmod 0644"
        assert true (sys rename f1 f2) "sys rename a.txt -> b.txt"
        assert true (sys symlink f2 lnk) "sys symlink"
        assert equals (sys readlink lnk) f2 "sys readlink target"
        assert true (sys unlink lnk) "sys unlink symlink"
        assert true (sys unlink f2) "sys unlink b.txt"
        assert true (sys rmdir dir_p) "sys rmdir"
        assert true ((sys getpid) > 0) "sys_getpid > 0"
        assert true ((str len (sys getcwd)) > 0) "sys_getcwd non-empty"
        t1      = sys monotonic ms
        n1      = sys monotonic ns
        w1      = sys wall time ms
        sys sleep ms 25 -> ()
        t2      = sys monotonic ms
        n2      = sys monotonic ns
        w2      = sys wall time ms
        assert true ((t2 - t1) >= 20) "monotonic ms elapsed >= 20"
        assert true (n2 > n1) "monotonic ns non-decreasing"
        assert true ((n2 - n1) >= 20000000) "monotonic ns elapsed >= 20ms (20,000,000 ns)"
        assert true (w1 > 1700000000000) "wall time > 1700000000000"
        k_sec   = sys call 201 0 0 0 0 0 0
        w_sec   = w2 / 1000
        assert true (((w_sec - k_sec) <= 2) and ((k_sec - w_sec) <= 2)) "sys_wall_time_ms matches kernel time(0) within 2s"
        assert true ((w2 - w1) >= 20) "wall time ms elapsed >= 20"
        sw_bad  = sys signal watch [9]
        assert equals (pair fst sw_bad) (0 - 7) "SIGKILL watch rejected with -7"
        sw_ok   = sys signal watch [sig term]
        assert equals (pair fst sw_ok) 0 "SIGTERM watch ok"
        sh      = pair snd sw_ok
        assert true ((sys call 72 sh 1 0 0 0 0) >= 0) "signalfd handle is real kernel fd"
        assert equals (sys kill (sys getpid) (sig term)) 0 "real kernel sys_kill SIGTERM does not kill process"
        sw_got  = sys signal wait sh 100
        assert equals (pair fst sw_got) 0 "sys_signal_wait status 0 after real sys_kill"
        assert equals (pair snd sw_got) (sig term) "sys_signal_wait got real SIGTERM (15)"
        assert equals (posix notify signal (sys getpid) (sig term)) 0 "notify signal"
        sw_got2 = sys signal wait sh 100
        assert equals (pair fst sw_got2) 0 "sys_signal_wait status 0"
        assert equals (pair snd sw_got2) (sig term) "sys_signal_wait got SIGTERM"
        sw_to   = sys signal wait sh 20
        assert equals (pair fst sw_to) (0 - 2) "second sys_signal_wait times out (-2)"
        assert equals (posix close sh) 0 "posix close signalfd"
        assert equals (pair fst (sys signal wait sh 10)) (0 - 7) "sys_signal_wait on closed fd -> -7"
        r_bad   = sys random bytes (0 - 1)
        assert equals (pair fst r_bad) (0 - 7) "negative random bytes -> -7"
        r_zero  = sys random bytes 0
        assert equals (pair fst r_zero) 0 "0 random bytes -> 0"
        assert equals (pair snd r_zero) "" "0 random bytes -> empty"
        r1      = sys random bytes 32
        r2      = sys random bytes 32
        rl      = sys random bytes list 256
        assert equals (pair fst r1) 0 "random 32 status 0"
        assert equals (str len (pair snd r1)) 32 "random 32 length == 32"
        assert equals (pair fst rl) 0 "random list 256 status 0"
        assert equals (path separator Linux) "/" "path separator Linux"
        assert equals (path separator Windows) "\\" "path separator Windows"
        assert equals (null device for Linux) "/dev/null" "null device Linux"
        assert equals (null device for Windows) "NUL" "null device Windows"
        assert true (process exists (sys getpid)) "process exists self"
        assert false (process exists 99999999) "process exists non-existent pid"
        assert false ((pair snd r1) == (pair snd r2)) "two 32-byte random draws differ"
```

### 22.3.5. Ejemplo 5: Comunicación entre procesos por tubería (`sys pipe`), sondeo no bloqueante (`sys poll status`) y temporización monotónica (`sys monotonic ns`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `posix` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
import posix

fn :: medir latencia tuberia => (Int, Int)
      medir latencia tuberia =
        t0             = sys monotonic ns
        (rc, rfd, wfd) = sys pipe
        sys write fd wfd "ping" -> ()
        listo          = sys poll rfd (poll in) 50
        leido          = sys read fd rfd 4
        sys close rfd -> ()
        sys close wfd -> ()
        t1             = sys monotonic ns
        (rc + listo + (str len leido), t1 - t0)
```

---

## 22.4. Bajo el capó: cómo está construida `posix` en Ridgun puro (`src/main/ridgun/lib/posix.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/posix.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 22.4.1. Implementación interna: Poll & Process Status ADTs

Fíjate en cómo `posix.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
module :: posix

type PollStatus = PollReady Int | PollTimeout | PollError Int

type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int
```

### 22.4.2. Implementación interna: Path Safety Validation (VUL-INJ-002 / VUL-INPUT-001)

Fíjate en cómo `posix.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: is bad posix code Int => Bool
      is bad posix code c   =
        c == 0 or c == 10 or c == 13 or c == 59 or c == 96 or c == 124 or c == 38 or c == 36 or c == 39 or c == 34

fn :: has unsafe posix char String Int Int => Bool
      has unsafe posix char s idx slen =
        | idx >= slen                           = False
        | is bad posix code (str char at s idx) = True
        | otherwise                             = has unsafe posix char s (idx + 1) slen

fn :: is safe posix path len String Int => Bool
      is safe posix path len path plen =
        | plen == 0 or plen > 4096 = False
        | otherwise                = not (has unsafe posix char path 0 plen)

fn :: is safe posix path String => Bool
      is safe posix path path   =
        is safe posix path len path (str len path)
```

### 22.4.3. Implementación interna: RG-010 Filesystem & Process Operations

Fíjate en cómo `posix.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: posix mkdir String => Bool
      posix mkdir path   =
        | not (is safe posix path path) = False
        | otherwise                     = (sys mkdir path 493) == 0

fn :: posix chmod String Int  => Bool
      posix chmod path   mode =
        | not (is safe posix path path) = False
        | otherwise                     = (sys chmod path mode) == 0

fn :: posix chdir String => Bool
      posix chdir path   =
        | not (is safe posix path path) = False
        | otherwise                     = (sys chdir path) == 0

fn :: px syscall1 path Int String => Int
      px syscall1 path nr  path   =
        ptr = px alloc page 4096
        mfd = px alloc mfd
        b0  = px raw byte 0
        _   = px poke mfd ptr (path + b0)
        rc  = sys call nr ptr 0 0 0 0 0
        _   = px free page mfd ptr 4096
        rc

fn :: px syscall2 path Int String String => Int
      px syscall2 path nr p1 p2 =
        ptr   = px alloc page 4096
        mfd   = px alloc mfd
        b0    = px raw byte 0
        p2048 = ptr + 2048
        _     = px poke mfd ptr (p1 + b0)
        _     = px poke mfd p2048 (p2 + b0)
        rc    = sys call nr ptr p2048 0 0 0 0
        _     = px free page mfd ptr 4096
        rc

fn :: sys rmdir String => Bool
      sys rmdir path   =
        | not (is safe posix path path) = False
        | otherwise                     = (px syscall1 path 84 path) == 0

fn :: sys unlink String => Bool
      sys unlink path   =
        | not (is safe posix path path) = False
        | otherwise                     = (px syscall1 path 87 path) == 0

fn :: sys rename String String   => Bool
      sys rename old_p  new_path =
        | not (is safe posix path old_p) or not (is safe posix path new_path) = False
        | otherwise = (px syscall2 path 82 old_p new_path) == 0

fn :: sys symlink String String    => Bool
      sys symlink target link_path =
        | not (is safe posix path target) or not (is safe posix path link_path) = False
        | otherwise = (px syscall2 path 88 target link_path) == 0

fn :: sys readlink String => String
      sys readlink path   =
        | not (is safe posix path path) = ""
        | otherwise                     = lstat symlink target (file lstat path)
```

### 22.4.4. Implementación interna: Ridgun v0.9.5 Target OS / Arch & Process Probe Helpers

Fíjate en cómo `posix.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: path separator SysOs   => String
      path separator Windows =  "\\"
      path separator _       =  "/"

fn :: null device for SysOs   => String
      null device for Windows =  "NUL"
      null device for _       =  "/dev/null"

fn :: null device => String
      null device =  null device for (sys os)

fn :: process exists Int => Bool
      process exists pid =
        | pid <= 0  = False
        | otherwise = (sys kill pid 0) == 0
```

---

## 22.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `posix`

- **Garantía algorítmica y de seguridad**: Las ramas de `sys os` y `sys arch` que no corresponden al binario destino son eliminadas en tiempo de compilación (Dead-Code Elimination) por `ridgunc`.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/posix.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test posix.rg`.

### Las 5 Reglas de Oro al programar con `posix`

1. **Declara `import posix` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `posix` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `posix` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `posix` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 23** pasaremos a explorar en profundidad la lib **`io`** (La lib `io` — Errores Tipados `IoResult`, E/S con `with timeout` y Procesos).
