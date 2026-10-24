# Capítulo 22: A lib `posix` — Capa de Abstracción de Plataforma (PAL), Reloxos, Sinais e CSPRNG

## 22.1. Por que existe a lib `posix`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `posix` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `posix`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: as bandeiras coma `O_CREAT`, `O_NONBLOCK` ou os números de syscall mudan entre Linux, macOS e arquitecturas (`X86_64` vs `Arm64`), e en C todo se resolve cunha xungla ilexible de `#ifdef`.

A lib **`posix`** implementa a **Capa de Abstracción de Plataforma (PAL)** de 2 niveis de Ridgun usando gardas tabulares sobre `sys os` (`Linux | MacOS | Windows`) e `sys arch` (`X86_64 | Arm64 | RiscV64`), ademais de sondaxe de descritores (`wait fd` / `PollStatus`), reloxos monótonos e de parede (`RGF-017`), sinais (`RGF-018`) e entropía CSPRNG do kernel (`sys random bytes`).

Nun ecosistema tradicional, resolver as tarefas do dominio **`POSIX`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`posix`** (`src/main/ridgun/lib/posix.rg`) aborda o problema con catro principios innegociables:

1. **Funcións totais e contratos explícitos (`=>`)**: ningunha función de `posix` lanza excepcións ocultas nin depende de `null`. Todo caso límite devolve un valor sentinela documentado ou un tipo alxébrico suma (`Option`, `Result`).
2. **Cero código C e cero `libc`**: todo o código de `posix` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `posix` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 22.2. Artefactos nativos, importación e catálogo completo da API de `posix`

En `ridgun-libs`, **`posix`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/posix.rg` (dominio `POSIX`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/posix.rglib` | Distribución e importación directa con `import posix` |
| **Ficheiro compilado** | `target/posix.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libposix.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import posix` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

### 22.2.1. Resumo de familias funcionais de `posix`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `pal open create trunc wr / pal o nonblock` | Tradución de bandeiras do SO segundo `sys os` (`Linux | MacOS | Windows`) |
| `wait fd : Int -> Int -> Int -> PollStatus` | Sonda un descritor devolvendo `PollReady`, `PollTimeout` ou `PollError errno` |
| `clock monotonic ms / clock monotonic ns / clock wall ms` | Reloxos monótonos e reloxo de parede UTC en milisegundos (`RGF-017`) |
| `signal watch / signal poll / sys random bytes` | Sondaxe non bloqueante de sinais (`SIGINT`, `SIGTERM`) e bytes CSPRNG do kernel |
| `read text / write text / file exists / run cmd` | E/S de ficheiros de alto nivel, directorios e execución de subprocesos |

### 22.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/posix.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/posix.rg` (`2` tipos, `0` operadores e `92` funcións):

**Tipos alxébricos e rexistros (`type`) de `posix`:**

```ridgun
type PollStatus = PollReady Int | PollTimeout | PollError Int
type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int
```

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 22.3. Explorando `posix` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `posix` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test posix.rg`.

### 22.3.1. Exemplo 1: Fluxo principal en estilo tabular con `posix`

Observa como en Ridgun os signos `=` e os pasos de transformación con `posix` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import posix

fn :: medir operacion () => (Int, Int)
      medir operacion =
        t0  = clock monotonic ms
        rnd = len (sys random bytes 32)
        t1  = clock monotonic ms
        (rnd, t1 - t0)
```

### 22.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `posix` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import posix

fn :: esperar lectura (fd : Int) => Bool
      esperar lectura fd =
        est = wait fd fd poll_in 100
        est == PollReady
```

### 22.3.3. Exemplo 3: Constantes POSIX (`O_*`, `POLL*`, `SIG*`), validación de rutas seguras, tubaxes anónimas (`sys pipe`) e sondaxe `sys poll status`

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `posix` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test posix constants descriptors and poll => ()
      test posix constants descriptors and poll =
        _       = assert equals (poll in) 1 "POLLIN == 1"
        _       = assert equals poll_out 4 "POLLOUT == 4"
        _       = assert equals (poll err) 8 "POLLERR == 8"
        _       = assert equals (sig int) 2 "SIGINT == 2"
        _       = assert equals (sig kill) 9 "SIGKILL == 9"
        _       = assert equals (sig term) 15 "SIGTERM == 15"
        _       = assert equals (o rdonly) 0 "O_RDONLY == 0"
        _       = assert equals (o wronly) 1 "O_WRONLY == 1"
        _       = assert equals (o rdwr) 2 "O_RDWR == 2"
        _       = assert equals (o creat) 64 "O_CREAT == 64"
        _       = assert equals (o trunc) 512 "O_TRUNC == 512"
        _       = assert equals (o append) 1024 "O_APPEND == 1024"
        _       = assert equals (o nonblock) 2048 "O_NONBLOCK == 2048"
        _       = assert equals (o cloexec) 524288 "O_CLOEXEC == 524288"
        bad_p   = wait fd (0 - 1) (poll in) 10
        _       = assert true (is poll error bad_p) "wait fd on -1 returns PollError"
        p_res   = posix pipe
        _       = assert equals (tuple3 status p_res) 0 "posix pipe status == 0"
        rfd     = tuple3 rfd p_res
        wfd     = tuple3 wfd p_res
        p_to    = wait fd rfd (poll in) 20
        _       = assert true (is poll timeout p_to) "wait fd on empty pipe times out"
        written = posix write wfd "hello-posix"
        _       = assert equals written 11 "posix write 11 bytes"
        p_rdy   = wait fd rfd (poll in) 100
        _       = assert true (is poll ready p_rdy) "wait fd after write is PollReady"
        got     = posix read rfd 64
        _       = assert equals got "hello-posix" "posix read matches written payload"
        _       = assert equals (posix close rfd) 0 "posix close rfd"
        assert equals (posix close wfd) 0 "posix close wfd"
```

### 22.3.4. Exemplo 4: Metadatos `lstat`, reloxos monotónicos e de parede (`clock_gettime`), sinais por descritor (`signalfd4`) e entropía do kernel (`sys random bytes`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `posix` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test posix filesystem clocks signals and random => ()
      test posix filesystem clocks signals and random =
        dir_p   = "/tmp/rg_posix_test_{sys_getpid}"
        f1      = "{dir_p}/a.txt"
        f2      = "{dir_p}/b.txt"
        lnk     = "{dir_p}/sym.txt"
        _       = sys rmdir dir_p
        _       = assert true (posix mkdir dir_p) "posix mkdir"
        _       = write file f1 "payload"
        _       = assert true (posix chmod f1 420) "posix chmod 0644"
        _       = assert true (sys rename f1 f2) "sys rename a.txt -> b.txt"
        _       = assert true (sys symlink f2 lnk) "sys symlink"
        _       = assert equals (sys readlink lnk) f2 "sys readlink target"
        _       = assert true (sys unlink lnk) "sys unlink symlink"
        _       = assert true (sys unlink f2) "sys unlink b.txt"
        _       = assert true (sys rmdir dir_p) "sys rmdir"
        _       = assert true ((sys getpid) > 0) "sys_getpid > 0"
        _       = assert true ((str len (sys getcwd)) > 0) "sys_getcwd non-empty"
        t1      = sys monotonic ms
        n1      = sys monotonic ns
        w1      = sys wall time ms
        _       = sys sleep ms 25
        t2      = sys monotonic ms
        n2      = sys monotonic ns
        w2      = sys wall time ms
        _       = assert true ((t2 - t1) >= 20) "monotonic ms elapsed >= 20"
        _       = assert true (n2 > n1) "monotonic ns non-decreasing"
        _       = assert true ((n2 - n1) >= 20000000) "monotonic ns elapsed >= 20ms (20,000,000 ns)"
        _       = assert true (w1 > 1700000000000) "wall time > 1700000000000"
        k_sec   = sys call 201 0 0 0 0 0 0
        w_sec   = w2 / 1000
        _       = assert true (((w_sec - k_sec) <= 2) and ((k_sec - w_sec) <= 2)) "sys_wall_time_ms matches kernel time(0) within 2s"
        _       = assert true ((w2 - w1) >= 20) "wall time ms elapsed >= 20"
        sw_bad  = sys signal watch [9]
        _       = assert equals (pair fst sw_bad) (0 - 7) "SIGKILL watch rejected with -7"
        sw_ok   = sys signal watch [sig term]
        _       = assert equals (pair fst sw_ok) 0 "SIGTERM watch ok"
        sh      = pair snd sw_ok
        _       = assert true ((sys call 72 sh 1 0 0 0 0) >= 0) "signalfd handle is real kernel fd"
        _       = assert equals (sys kill (sys getpid) (sig term)) 0 "real kernel sys_kill SIGTERM does not kill process"
        sw_got  = sys signal wait sh 100
        _       = assert equals (pair fst sw_got) 0 "sys_signal_wait status 0 after real sys_kill"
        _       = assert equals (pair snd sw_got) (sig term) "sys_signal_wait got real SIGTERM (15)"
        _       = assert equals (posix notify signal (sys getpid) (sig term)) 0 "notify signal"
        sw_got2 = sys signal wait sh 100
        _       = assert equals (pair fst sw_got2) 0 "sys_signal_wait status 0"
        _       = assert equals (pair snd sw_got2) (sig term) "sys_signal_wait got SIGTERM"
        sw_to   = sys signal wait sh 20
        _       = assert equals (pair fst sw_to) (0 - 2) "second sys_signal_wait times out (-2)"
        _       = assert equals (posix close sh) 0 "posix close signalfd"
        _       = assert equals (pair fst (sys signal wait sh 10)) (0 - 7) "sys_signal_wait on closed fd -> -7"
        r_bad   = sys random bytes (0 - 1)
        _       = assert equals (pair fst r_bad) (0 - 7) "negative random bytes -> -7"
        r_zero  = sys random bytes 0
        _       = assert equals (pair fst r_zero) 0 "0 random bytes -> 0"
        _       = assert equals (pair snd r_zero) "" "0 random bytes -> empty"
        r1      = sys random bytes 32
        r2      = sys random bytes 32
        rl      = sys random bytes list 256
        _       = assert equals (pair fst r1) 0 "random 32 status 0"
        _       = assert equals (str len (pair snd r1)) 32 "random 32 length == 32"
        _       = assert equals (pair fst rl) 0 "random list 256 status 0"
        _       = assert equals (path separator Linux) "/" "path separator Linux"
        _       = assert equals (path separator Windows) "\\" "path separator Windows"
        _       = assert equals (null device for Linux) "/dev/null" "null device Linux"
        _       = assert equals (null device for Windows) "NUL" "null device Windows"
        _       = assert true (process exists (sys getpid)) "process exists self"
        _       = assert false (process exists 99999999) "process exists non-existent pid"
        assert false ((pair snd r1) == (pair snd r2)) "two 32-byte random draws differ"
```

### 22.3.5. Exemplo 5: Comunicación entre procesos por tubaxe (`sys pipe`), sondaxe non bloqueante (`sys poll status`) e temporización monotónica (`sys monotonic ns`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `posix` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
import posix

fn :: medir latencia tuberia => (Int, Int)
      medir latencia tuberia =
        t0             = sys monotonic ns
        (rc, rfd, wfd) = sys pipe
        _              = sys write fd wfd "ping"
        listo          = sys poll rfd (poll in) 50
        leido          = sys read fd rfd 4
        _              = sys close rfd
        _              = sys close wfd
        t1             = sys monotonic ns
        (rc + listo + (str len leido), t1 - t0)
```

---

## 22.4. Baixo o capó: como está construída `posix` en Ridgun puro (`src/main/ridgun/lib/posix.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/posix.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 22.4.1. Implementación interna: Poll & Process Status ADTs

Fíxate en como `posix.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
type PollStatus = PollReady Int | PollTimeout | PollError Int

type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int
```

### 22.4.2. Implementación interna: Path Safety Validation (VUL-INJ-002 / VUL-INPUT-001)

Fíxate en como `posix.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

Fíxate en como `posix.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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
```

### 22.4.4. Implementación interna: Ridgun v0.9.5 Target OS / Arch & Process Probe Helpers

Fíxate en como `posix.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

## 22.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `posix`

- **Garantía algorítmica e de seguridade**: As ramas de `sys os` e `sys arch` que non corresponden ao binario destino son eliminadas en tempo de compilación (Dead-Code Elimination) por `ridgunc`.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/posix.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test posix.rg`.

### As 5 Regras de Ouro ao programar con `posix`

1. **Declara `import posix` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `posix` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `posix` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `posix` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 23** pasaremos a explorar en profundidade a lib **`io`** (A lib `io` — Erros Tipados `IoResult`, E/S con `with timeout` e Procesos).
