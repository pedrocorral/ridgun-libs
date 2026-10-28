# Capítol 22: La lib `posix` — Capa d'Abstracció de Plataforma (PAL), Rellotges, Senyals i CSPRNG

## 22.1. Per què existeix la lib `posix`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `posix` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `posix`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: les banderes com `O_CREAT`, `O_NONBLOCK` o els números de syscall canvien entre Linux, macOS i arquitectures (`X86_64` vs `Arm64`), i en C tot es resol amb una jungla il·legible d'`#ifdef`.

La lib **`posix`** implementa la **Capa d'Abstracció de Plataforma (PAL)** de 2 nivells de Ridgun fent servir guardes tabulars sobre `sys os` (`Linux | MacOS | Windows`) i `sys arch` (`X86_64 | Arm64 | RiscV64`), a més de sondeig de descriptors (`wait fd` / `PollStatus`), rellotges monòtons i de paret (`RGF-017`), senyals (`RGF-018`) i entropia CSPRNG del nucli (`sys random bytes`).

En un ecosistema tradicional, resoldre les tasques del domini **`POSIX`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`posix`** (`src/main/ridgun/lib/posix.rg`) aborda el problema amb quatre principis innegociables:

1. **Declara `import posix` (o `import posix as alias`) a l'inici del fitxer**: cada lib defineix el seu espai de noms `module :: posix` i en mode `--strict` les funcions multi-paraula s'invoquen sempre amb espais naturals.
2. **Encadena les teves canonades d'esquerra a dreta amb `->`**: escriu `entrada pas u -> pas dos -> resultat`, fes servir màscares `(+ _ _ +)` per desestructurar seqüències i omet `_ =` en sentències seqüencials (o descarta amb `-> ()`).
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `posix` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 22.2. Artefactes natius, importació i catàleg complet de l'API de `posix`

A `ridgun-libs`, **`posix`** és una **lib** de primera classe situada a `src/main/ridgun/lib/posix.rg` (domini `POSIX`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/posix.rglib` | Distribució i importació directa amb `import posix` |
| **Fitxer compilat** | `target/posix.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libposix.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Cada lib declara el seu propi espai de noms amb `module :: posix`: n'hi ha prou d'escriure `import posix` (o `import posix as alias`) a la capçalera i cridar les seves funcions amb espais naturals (`la meva funcio x`) i canonades `->` (`x la meva funcio -> resultat`).

### 22.2.1. Resum de famílies funcionals de `posix`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `pal open create trunc wr / pal o nonblock` | Traducció de banderes del SO segons `sys os` (`Linux | MacOS | Windows`) |
| `wait fd : Int -> Int -> Int -> PollStatus` | Sondeja un descriptor retornant `PollReady`, `PollTimeout` o `PollError errno` |
| `clock monotonic ms / clock monotonic ns / clock wall ms` | Rellotges monòtons i rellotge de paret UTC en mil·lisegons (`RGF-017`) |
| `signal watch / signal poll / sys random bytes` | Sondeig no bloquejant de senyals (`SIGINT`, `SIGTERM`) i bytes CSPRNG del nucli |
| `read text / write text / file exists / run cmd` | E/S de fitxers d'alt nivell, directoris i execució de subprocessos |

### 22.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/posix.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/posix.rg` (`2` tipus, `0` operadors i `103` funcions):

**Tipus algebraics i registres (`type`) de `posix`:**

```ridgun
type PollStatus = PollReady Int | PollTimeout | PollError Int
type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int
```

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 22.3. Explorant `posix` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `posix` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test posix.rg`.

### 22.3.1. Exemple 1: Flux principal en estil tabular amb `posix`

Observa com en Ridgun els signes `=` i els passos de transformació amb `posix` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import posix

fn :: medir operacion => Int Int
      medir operacion =
        clock monotonic ms -> t0
        sys random bytes 32 -> (+ _) -> rc
        clock monotonic ms -> t1
        (rc, t1 - t0)
```

### 22.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `posix` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import posix

fn :: esperar lectura Int => PollStatus
      esperar lectura fd =
        wait fd fd (poll in) 100
```

### 22.3.3. Exemple 3: Constants POSIX (`O_*`, `POLL*`, `SIG*`), validació de rutes segures, canonades anònimes (`sys pipe`) i sondeig `sys poll status`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `posix` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 22.3.4. Exemple 4: Metadades `lstat`, rellotges monotònics i de paret (`clock_gettime`), senyals per descriptor (`signalfd4`) i entropia del kernel (`sys random bytes`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `posix` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 22.3.5. Exemple 5: Comunicació entre processos per canonada (`sys pipe`), sondeig no bloquejant (`sys poll status`) i temporització monotònica (`sys monotonic ns`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `posix` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

## 22.4. Sota el capó: com està construïda `posix` en Ridgun pur (`src/main/ridgun/lib/posix.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/posix.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 22.4.1. Implementació interna: Poll & Process Status ADTs

Fixa't en com `posix.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
module :: posix

type PollStatus = PollReady Int | PollTimeout | PollError Int

type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int
```

### 22.4.2. Implementació interna: Path Safety Validation (VUL-INJ-002 / VUL-INPUT-001)

Fixa't en com `posix.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 22.4.3. Implementació interna: RG-010 Filesystem & Process Operations

Fixa't en com `posix.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 22.4.4. Implementació interna: Ridgun v0.9.5 Target OS / Arch & Process Probe Helpers

Fixa't en com `posix.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

## 22.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `posix`

- **Garantia algorísmica i de seguretat**: Les branques de `sys os` i `sys arch` que no corresponen al binari destí són eliminades en temps de compilació (Dead-Code Elimination) per `ridgunc`.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/posix.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test posix.rg`.

### Les 5 Regles d'Or en programar amb `posix`

1. **Declara `import posix` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `posix` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `posix` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `posix` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 23** passarem a explorar en profunditat la lib **`io`** (La lib `io` — Errors Tipats `IoResult`, E/S amb `with timeout` i Processos).
