# Capítol 22: La lib `posix` — Capa d'Abstracció de Plataforma (PAL), Rellotges, Senyals i CSPRNG

## 22.1. Per què existeix la lib `posix`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `posix` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `posix`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: les banderes com `O_CREAT`, `O_NONBLOCK` o els números de syscall canvien entre Linux, macOS i arquitectures (`X86_64` vs `Arm64`), i en C tot es resol amb una jungla il·legible d'`#ifdef`.

La lib **`posix`** implementa la **Capa d'Abstracció de Plataforma (PAL)** de 2 nivells de Ridgun fent servir guardes tabulars sobre `sys os` (`Linux | MacOS | Windows`) i `sys arch` (`X86_64 | Arm64 | RiscV64`), a més de sondeig de descriptors (`wait fd` / `PollStatus`), rellotges monòtons i de paret (`RGF-017`), senyals (`RGF-018`) i entropia CSPRNG del nucli (`sys random bytes`).

En un ecosistema tradicional, resoldre les tasques del domini **`POSIX`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`posix`** (`src/main/ridgun/lib/posix.ridgun`) aborda el problema amb quatre principis innegociables:

1. **Declara `import posix` (o `import posix as alias`) a l'inici del fitxer**: cada lib defineix el seu espai de noms `module :: posix` i en mode `--strict` les funcions multi-paraula s'invoquen sempre amb espais naturals.
2. **Encadena les teves canonades d'esquerra a dreta amb `->`**: escriu `entrada pas u -> pas dos -> resultat`, fes servir màscares `(+ _ _ +)` per desestructurar seqüències i omet `_ =` en sentències seqüencials (o descarta amb `-> ()`).
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `posix` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 22.2. Artefactes natius, importació i catàleg complet de l'API de `posix`

A `ridgun-libs`, **`posix`** és una **lib** de primera classe situada a `src/main/ridgun/lib/posix.ridgun` (domini `POSIX`). En compilar amb `stable bundle`, s'empaqueta en un format natiu:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/posix.ridgunlib` | Distribució i importació directa amb `import posix` |

> Cada lib declara el seu propi espai de noms amb `module :: posix`: n'hi ha prou d'escriure `import posix` (o `import posix as alias`) a la capçalera i cridar les seves funcions amb espais naturals (`la meva funcio x`) i canonades `->` (`x la meva funcio -> resultat`).

### 22.2.1. Resum de famílies funcionals de `posix`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `o rdonly / o wronly / o rdwr / o creat / o trunc / o append / o nonblock / o cloexec` | Banderes d'obertura com a funcions, amb el valor correcte per a l'arquitectura de la màquina amfitriona |
| `wait fd` | Espera fins que un descriptor està llest: `PollReady`, `PollTimeout` o `PollError` |
| `sys monotonic ms / sys monotonic ns` | Rellotges monotònics per mesurar el temps transcorregut |
| `sys signal watch / sys signal wait / posix notify signal` | Vigila senyals a través d'un descriptor, espera'ls amb un timeout i envia'n un a un procés |
| `sys random bytes / sys random tensor` | Bytes aleatoris del nucli (`getrandom`), com a `String` o com a `Tensor[U8]` |
| `posix open / posix read / posix write / posix close` | Fitxers per descriptor, directament sobre el nucli |
| `posix mkdir / posix chmod / sys unlink / sys rename / sys rmdir / sys symlink / sys readlink` | Operacions del sistema de fitxers sobre rutes validades |
| `posix mkdir all` | Crea un directori i tots els pares que falten; retorna el codi d'error del nivell que falla |
| `posix fsync / posix fdatasync / posix ftruncate / posix lock exclusive / posix pread` | Escriptures duradores, truncament, bloquejos exclusius de fitxer i lectures posicionals (`FR-POSIX-003`) |
| `posix fork / posix pipe / posix dup2 / posix execve / posix waitpid` | Control de processos directament sobre el nucli, amb estat de sortida tipat (`ProcExited`, `ProcSignal`) |

### 22.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/posix.ridgun`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/posix.ridgun` (`2` tipus, `0` operadors i `161` funcions):

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
| `25` | `fn :: o directory for SysArch` | `Int` |
| `26` | `fn :: o directory` | `Int` |
| `27` | `fn :: errno eio` | `Int` |
| `28` | `fn :: errno ebadf` | `Int` |
| `29` | `fn :: errno ewouldblock` | `Int` |
| `30` | `fn :: errno enotdir` | `Int` |
| `31` | `fn :: errno einval` | `Int` |
| `32` | `fn :: errno enospc` | `Int` |
| `33` | `fn :: is bad posix code Int` | `Bool` |
| `34` | `fn :: has unsafe posix char String Int Int` | `Bool` |
| `35` | `fn :: is safe posix path len String Int` | `Bool` |
| `36` | `fn :: is safe posix path String` | `Bool` |
| `37` | `fn :: lstat exists (Bool String Int Int Int String String Int String)` | `Bool` |
| `38` | `fn :: lstat kind (Bool String Int Int Int String String Int String)` | `String` |
| `39` | `fn :: lstat mode (Bool String Int Int Int String String Int String)` | `Int` |
| `40` | `fn :: lstat size (Bool String Int Int Int String String Int String)` | `Int` |
| `41` | `fn :: lstat mtime sec (Bool String Int Int Int String String Int String)` | `Int` |
| `42` | `fn :: lstat symlink target (Bool String Int Int Int String String Int String)` | `String` |
| `43` | `fn :: px raw byte Int` | `String` |
| `44` | `fn :: px put u64 le Tensor[U8] Int Int` | `Tensor[U8]` |
| `45` | `fn :: px u64 le Int` | `String` |
| `46` | `fn :: px get u32 le Tensor[U8] Int` | `Int` |
| `47` | `fn :: px get u64 le Tensor[U8] Int` | `Int` |
| `48` | `fn :: px cstr String` | `Tensor[U8]` |
| `49` | `fn :: px sys nr SysArch Int Int` | `Int` |
| `50` | `fn :: px nr Int Int` | `Int` |
| `51` | `fn :: nr read` | `Int` |
| `52` | `fn :: nr lseek` | `Int` |
| `53` | `fn :: nr mmap` | `Int` |
| `54` | `fn :: nr munmap` | `Int` |
| `55` | `fn :: nr rt sigprocmask` | `Int` |
| `56` | `fn :: nr pread64` | `Int` |
| `57` | `fn :: nr pwrite64` | `Int` |
| `58` | `fn :: nr socket` | `Int` |
| `59` | `fn :: nr connect` | `Int` |
| `60` | `fn :: nr accept` | `Int` |
| `61` | `fn :: nr sendto` | `Int` |
| `62` | `fn :: nr shutdown` | `Int` |
| `63` | `fn :: nr bind` | `Int` |
| `64` | `fn :: nr listen` | `Int` |
| `65` | `fn :: nr getsockname` | `Int` |
| `66` | `fn :: nr setsockopt` | `Int` |
| `67` | `fn :: nr getsockopt` | `Int` |
| `68` | `fn :: nr clone` | `Int` |
| `69` | `fn :: nr execve` | `Int` |
| `70` | `fn :: nr exit` | `Int` |
| `71` | `fn :: nr wait4` | `Int` |
| `72` | `fn :: nr fcntl` | `Int` |
| `73` | `fn :: nr flock` | `Int` |
| `74` | `fn :: nr fsync` | `Int` |
| `75` | `fn :: nr fdatasync` | `Int` |
| `76` | `fn :: nr ftruncate` | `Int` |
| `77` | `fn :: nr clock gettime` | `Int` |
| `78` | `fn :: nr unlinkat` | `Int` |
| `79` | `fn :: nr symlinkat` | `Int` |
| `80` | `fn :: nr signalfd4` | `Int` |
| `81` | `fn :: nr eventfd2` | `Int` |
| `82` | `fn :: nr dup3` | `Int` |
| `83` | `fn :: nr pipe2` | `Int` |
| `84` | `fn :: nr renameat2` | `Int` |
| `85` | `fn :: nr getrandom` | `Int` |
| `86` | `fn :: nr memfd create` | `Int` |
| `87` | `fn :: at fdcwd` | `Int` |
| `88` | `fn :: sys monotonic ms` | `Int` |
| `89` | `fn :: sys monotonic ns` | `Int` |
| `90` | `fn :: map poll rc Int` | `PollStatus` |
| `91` | `fn :: wait fd Int Int Int` | `PollStatus` |
| `92` | `fn :: posix open String Int Int` | `Int` |
| `93` | `fn :: posix close Int` | `Int` |
| `94` | `fn :: posix read Int Int` | `String` |
| `95` | `fn :: posix write Int String` | `Int` |
| `96` | `fn :: posix kill Int Int` | `Int` |
| `97` | `fn :: wnohang` | `Int` |
| `98` | `fn :: wuntraced` | `Int` |
| `99` | `fn :: pack pipe fds Int Int Int` | `Int Int Int` |
| `100` | `fn :: posix pipe flags Int` | `Int Int Int` |
| `101` | `fn :: posix pipe` | `Int Int Int` |
| `102` | `fn :: posix pipe cloexec` | `Int Int Int` |
| `103` | `fn :: posix dup2 Int Int` | `Int` |
| `104` | `fn :: px dup same Int Int` | `Int` |
| `105` | `fn :: posix fork` | `Int` |
| `106` | `fn :: posix exit Int` | `Int` |
| `107` | `fn :: posix execve String [String] [String]` | `Int` |
| `108` | `fn :: posix waitpid Int Int` | `Int Int` |
| `109` | `fn :: px wait4 retry Int Tensor[U8] Int` | `Int` |
| `110` | `fn :: px wait4 again Int Tensor[U8] Int Int` | `Int` |
| `111` | `fn :: px wait4 result Int Int` | `Int Int` |
| `112` | `fn :: waitpid decode sig Int Int` | `ProcStatus` |
| `113` | `fn :: waitpid decode status Int` | `ProcStatus` |
| `114` | `fn :: posix mkdir String` | `Bool` |
| `115` | `fn :: posix chmod String Int` | `Bool` |
| `116` | `fn :: posix chdir String` | `Bool` |
| `117` | `fn :: px unlinkat path String Int` | `Int` |
| `118` | `fn :: px path pair sys Int Tensor[U8] Tensor[U8]` | `Int` |
| `119` | `fn :: px path pair call Int String String` | `Int` |
| `120` | `fn :: px use pal files` | `Bool` |
| `121` | `fn :: posix mkdir all String Int` | `Int` |
| `122` | `fn :: px mkdir step String Int Int Int Int` | `Int` |
| `123` | `fn :: px mkdir rc Int` | `Int` |
| `124` | `fn :: sys rmdir String` | `Bool` |
| `125` | `fn :: sys unlink String` | `Bool` |
| `126` | `fn :: sys rename String String` | `Bool` |
| `127` | `fn :: sys symlink String String` | `Bool` |
| `128` | `fn :: sys readlink String` | `String` |
| `129` | `fn :: valid signal list [Int]` | `Bool` |
| `130` | `fn :: valid signal rest [Int]` | `Bool` |
| `131` | `fn :: px bit shift Int` | `Int` |
| `132` | `fn :: px sig mask [Int]` | `Int` |
| `133` | `fn :: px finish sig watch Int` | `Int Int` |
| `134` | `fn :: sys signal watch [Int]` | `Int Int` |
| `135` | `fn :: px finish sig read Int Tensor[U8]` | `Int Int` |
| `136` | `fn :: px wait sig after poll Int Int` | `Int Int` |
| `137` | `fn :: sys signal wait Int Int` | `Int Int` |
| `138` | `fn :: posix notify signal Int Int` | `Int` |
| `139` | `fn :: px no bytes` | `Tensor[U8]` |
| `140` | `fn :: px getrandom tensor Int` | `Int Tensor[U8]` |
| `141` | `fn :: px getrandom got Int Tensor[U8] Int` | `Int Tensor[U8]` |
| `142` | `fn :: px getrandom join String (Int Tensor[U8])` | `Int Tensor[U8]` |
| `143` | `fn :: px random as str (Int Tensor[U8])` | `Int String` |
| `144` | `fn :: sys random bytes Int` | `Int String` |
| `145` | `fn :: sys random tensor Int` | `Int Tensor[U8]` |
| `146` | `fn :: path separator SysOs` | `String` |
| `147` | `fn :: null device for SysOs` | `String` |
| `148` | `fn :: null device` | `String` |
| `149` | `fn :: process exists Int` | `Bool` |
| `150` | `fn :: posix fdatasync Int` | `Int` |
| `151` | `fn :: posix fsync Int` | `Int` |
| `152` | `fn :: posix ftruncate Int Int` | `Int` |
| `153` | `fn :: px close keep rc Int Int` | `Int` |
| `154` | `fn :: px fsync opened dir Int` | `Int` |
| `155` | `fn :: posix sync dir String` | `Int` |
| `156` | `fn :: posix lock exclusive Int` | `Int` |
| `157` | `fn :: posix unlock Int` | `Int` |
| `158` | `fn :: posix pread max` | `Int` |
| `159` | `fn :: px pread result Int Tensor[U8] Int` | `Int String` |
| `160` | `fn :: px pread into Int Int Int` | `Int String` |
| `161` | `fn :: posix pread Int Int Int` | `Int String` |

---

## 22.3. Explorant `posix` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `posix` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test posix.ridgun`.

### 22.3.1. Exemple 1: Flux principal en estil tabular amb `posix`

Observa com en Ridgun els signes `=` i els passos de transformació amb `posix` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import posix

fn :: medir operacion => Int Int
      medir operacion =
        sys monotonic ms -> t0
        rc, bytes = sys random bytes 32
        sys monotonic ms -> t1
        (rc, t1 - t0)
```

### 22.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `posix` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 38 libs de `ridgun-libs`:

```ridgun
import posix

fn :: esperar lectura Int => PollStatus
      esperar lectura fd =
        wait fd fd (poll in) 100
```

### 22.3.3. Exemple 3: Constants POSIX (`O_*`, `POLL*`, `SIG*`), validació de rutes segures, canonades anònimes (`sys pipe`) i sondeig `wait fd`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `posix` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test posix constants descriptors and poll => ()
      test posix constants descriptors and poll =
        poll in -> assert equals 1 "POLLIN == 1"
        poll -> assert equals out 4 "POLLOUT == 4"
        poll err -> assert equals 8 "POLLERR == 8"
        sig int -> assert equals 2 "SIGINT == 2"
        sig kill -> assert equals 9 "SIGKILL == 9"
        sig term -> assert equals 15 "SIGTERM == 15"
        o rdonly -> assert equals 0 "O_RDONLY == 0"
        o wronly -> assert equals 1 "O_WRONLY == 1"
        o rdwr -> assert equals 2 "O_RDWR == 2"
        o creat -> assert equals 64 "O_CREAT == 64"
        o trunc -> assert equals 512 "O_TRUNC == 512"
        o append -> assert equals 1024 "O_APPEND == 1024"
        o nonblock -> assert equals 2048 "O_NONBLOCK == 2048"
        o cloexec -> assert equals 524288 "O_CLOEXEC == 524288"
        bad_p   = wait fd (0 - 1) (poll in) 10
        is poll error bad_p -> assert true "wait fd on -1 returns PollError"
        p_res   = posix pipe
        tuple3 status p_res -> assert equals 0 "posix pipe status == 0"
        rfd     = tuple3 rfd p_res
        wfd     = tuple3 wfd p_res
        p_to    = wait fd rfd (poll in) 20
        is poll timeout p_to -> assert true "wait fd on empty pipe times out"
        written = posix write wfd "hello-posix"
        written -> assert equals 11 "posix write 11 bytes"
        p_rdy   = wait fd rfd (poll in) 100
        is poll ready p_rdy -> assert true "wait fd after write is PollReady"
        got     = posix read rfd 64
        got -> assert equals "hello-posix" "posix read matches written payload"
        posix close rfd -> assert equals 0 "posix close rfd"
        assert equals (posix close wfd) 0 "posix close wfd"
```

### 22.3.4. Exemple 4: Metadades `lstat`, rellotges monotònics i de paret (`sys monotonic ns`), senyals per descriptor (`signalfd4`) i entropia del kernel (`sys random bytes`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `posix` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test posix filesystem clocks signals and random => ()
      test posix filesystem clocks signals and random =
        my_pid  = sys getpid
        dir_p   = "/tmp/rg_posix_test_{my_pid}"
        f1      = "{dir_p}/a.txt"
        f2      = "{dir_p}/b.txt"
        lnk     = "{dir_p}/sym.txt"
        sys rmdir dir_p
        posix mkdir dir_p -> assert true "posix mkdir"
        write file f1 "payload"
        posix chmod f1 420 -> assert true "posix chmod 0644"
        sys rename f1 f2 -> assert true "sys rename a.txt -> b.txt"
        sys symlink f2 lnk -> assert true "sys symlink"
        sys readlink lnk -> assert equals f2 "sys readlink target"
        sys unlink lnk -> assert true "sys unlink symlink"
        sys unlink f2 -> assert true "sys unlink b.txt"
        sys rmdir dir_p -> assert true "sys rmdir"
        deep    = "{dir_p}/x/y/z"
        posix mkdir all deep 448 -> assert int equals 0 "posix mkdir all makes the directory and its parents"
        posix mkdir all deep 448 -> assert int equals 0 "posix mkdir all on a directory that is there"
        posix mkdir all "{dir_p}//x/y/" 448 -> assert int equals 0 "posix mkdir all with empty parts in the path"
        (posix mkdir all "" 448) < 0 -> assert true "posix mkdir all rejects an empty path"
        sys rmdir deep -> assert true "the deepest directory existed"
        sys rmdir "{dir_p}/x/y"
        sys rmdir "{dir_p}/x"
        sys rmdir dir_p -> assert true "the first parent existed"
        (sys getpid) > 0 -> assert true "sys_getpid > 0"
        (str len (sys getcwd)) > 0 -> assert true "sys_getcwd non-empty"
        t1      = sys monotonic ms
        n1      = sys time ns
        m1      = sys monotonic ns
        w1      = sys wall time ms
        sys sleep ms 25
        t2      = sys monotonic ms
        n2      = sys time ns
        m2      = sys monotonic ns
        w2      = sys wall time ms
        (t2 - t1) >= 20 -> assert true "monotonic ms elapsed >= 20"
        n2 > n1 -> assert true "sys time ns increases"
        (n2 - n1) >= 20000000 -> assert true "sys time ns elapsed >= 20ms (20,000,000 ns)"
        (m2 - m1) >= 20000000 -> assert true "sys monotonic ns elapsed >= 20ms"
        ns increasing (sys time ns) 0 10000 -> assert true "sys time ns never goes back over 10000 reads"
        w1 > 1700000000000 -> assert true "wall time > 1700000000000"
        w1 < 4102444800000 -> assert true "wall time < 2100-01-01"
        k_sec   = kernel wall sec
        w_sec   = w2 / 1000
        ((w_sec - k_sec) <= 2) and ((k_sec - w_sec) <= 2) -> assert true "sys wall time ms matches kernel clock_gettime(REALTIME) within 2s"
        (w2 - w1) >= 20 -> assert true "wall time ms elapsed >= 20"
        sw_bad  = sys signal watch [9]
        pair fst sw_bad -> assert equals (0 - 7) "SIGKILL watch rejected with -7"
        sw_ok   = sys signal watch [sig term]
        pair fst sw_ok -> assert equals 0 "SIGTERM watch ok"
        sh      = pair snd sw_ok
        (sys call (nr fcntl) sh 1 0 0 0 0) >= 0 -> assert true "signalfd handle is real kernel fd"
        sys kill (sys getpid) (sig term) -> assert equals 0 "real kernel sys_kill SIGTERM does not kill process"
        sw_got  = sys signal wait sh 100
        pair fst sw_got -> assert equals 0 "sys_signal_wait status 0 after real sys_kill"
        pair snd sw_got -> assert equals (sig term) "sys_signal_wait got real SIGTERM (15)"
        posix notify signal (sys getpid) (sig term) -> assert equals 0 "notify signal"
        sw_got2 = sys signal wait sh 100
        pair fst sw_got2 -> assert equals 0 "sys_signal_wait status 0"
        pair snd sw_got2 -> assert equals (sig term) "sys_signal_wait got SIGTERM"
        sw_to   = sys signal wait sh 20
        pair fst sw_to -> assert equals (0 - 2) "second sys_signal_wait times out (-2)"
        posix close sh -> assert equals 0 "posix close signalfd"
        pair fst (sys signal wait sh 10) -> assert equals (0 - 7) "sys_signal_wait on closed fd -> -7"
        r_bad   = sys random bytes (0 - 1)
        pair fst r_bad -> assert equals (0 - 7) "negative random bytes -> -7"
        r_zero  = sys random bytes 0
        pair fst r_zero -> assert equals 0 "0 random bytes -> 0"
        pair snd r_zero -> assert equals "" "0 random bytes -> empty"
        r1      = sys random bytes 32
        r2      = sys random bytes 32
        rt      = sys random tensor 256
        pair fst r1 -> assert equals 0 "random 32 status 0"
        str len (pair snd r1) -> assert equals 32 "random 32 length == 32"
        pair fst rt -> assert equals 0 "random tensor 256 status 0"
        bytes len (pair snd rt) -> assert equals 256 "random tensor 256 length == 256"
        bytes len (pair snd (sys random tensor 0)) -> assert equals 0 "random tensor 0 is empty"
        pair fst (sys random tensor (0 - 1)) -> assert equals (0 - 7) "random tensor -1 -> -7"
        pair fst (sys random tensor 65537) -> assert equals (0 - 7) "random tensor over 64 KiB -> -7"
        path separator Linux -> assert equals "/" "path separator Linux"
        path separator Windows -> assert equals "\\" "path separator Windows"
        null device for Linux -> assert equals "/dev/null" "null device Linux"
        null device for Windows -> assert equals "NUL" "null device Windows"
        process exists (sys getpid) -> assert true "process exists self"
        process exists 99999999 -> assert false "process exists non-existent pid"
        assert false ((pair snd r1) == (pair snd r2)) "two 32-byte random draws differ"
```

### 22.3.5. Exemple 5: Comunicació entre processos per canonada (`sys pipe`), sondeig no bloquejant (`wait fd`) i temporització monotònica (`sys monotonic ns`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `posix` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
import posix

fn :: medir latencia tuberia => Int Int
      medir latencia tuberia =
        t0           = sys monotonic ns
        rc, rfd, wfd = posix pipe
        posix write wfd "ping" -> ()
        listo        = sys poll rfd (poll in) 50
        leido        = posix read rfd 4
        posix close rfd -> ()
        posix close wfd -> ()
        t1           = sys monotonic ns
        (rc + listo + (str len leido), t1 - t0)
```

### 22.3.6. Exemple 6: Control de processos sobre el nucli: `posix pipe`, `posix fork`, `posix dup2`, `posix execve` i `posix waitpid`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `posix` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test posix fork pipe dup2 execve waitpid => ()
      test posix fork pipe dup2 execve waitpid =
        wnohang -> assert equals 1 "WNOHANG == 1"
        wuntraced -> assert equals 2 "WUNTRACED == 2"
        p_res   = posix pipe
        tuple3 status p_res -> assert equals 0 "posix pipe status == 0"
        rfd     = tuple3 rfd p_res
        wfd     = tuple3 wfd p_res
        handle fork branch (posix fork) rfd wfd
```

### 22.3.7. Exemple 7: Operacions de fitxer duradores: `posix fsync`, `posix fdatasync`, `posix ftruncate`, bloquejos exclusius i `posix pread`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `posix` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test posix durable file ops => ()
      test posix durable file ops =
        px sys nr X86_64 75 83 -> assert equals 75 "picker: x86_64 number"
        px sys nr Arm64 75 83 -> assert equals 83 "picker: arm64 number"
        o directory for X86_64 -> assert equals 65536 "O_DIRECTORY x86_64"
        o directory for Arm64 -> assert equals 16384 "O_DIRECTORY arm64"
        nr fdatasync -> assert equals (px sys nr (sys arch) 75 83) "fdatasync nr matches the host arch"
        nr fsync -> assert equals (px sys nr (sys arch) 74 82) "fsync nr matches the host arch"
        nr ftruncate -> assert equals (px sys nr (sys arch) 77 46) "ftruncate nr matches the host arch"
        nr flock -> assert equals (px sys nr (sys arch) 73 32) "flock nr matches the host arch"
        nr pread64 -> assert equals (px sys nr (sys arch) 17 67) "pread64 nr matches the host arch"
        my_pid = sys getpid
        dir_p  = "/tmp/rg_posix_dur_{my_pid}"
        f_dat  = "{dir_p}/f.dat"
        f_lock = "{dir_p}/lock"
        f_r    = "{dir_p}/r.dat"
        posix mkdir dir_p -> assert true "mkdir durable test dir"
        fd     = posix open f_dat ((o creat) + (o rdwr) + (o trunc)) 420
        fd >= 0 -> assert true "open f.dat"
        posix write fd "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789" -> assert equals 100 "write 100 bytes"
        posix fdatasync fd -> assert equals 0 "fdatasync on fresh write -> 0"
        posix fsync fd -> assert equals 0 "fsync on fresh write -> 0"
        posix close fd -> assert equals 0 "close f.dat"
        posix fdatasync fd -> assert equals (0 - errno ebadf) "fdatasync on closed fd -> -EBADF"
        posix fsync fd -> assert equals (0 - errno ebadf) "fsync on closed fd -> -EBADF"
        posix fdatasync (0 - 1) -> assert equals (0 - 9) "fdatasync on -1 -> -9"
        fd2    = posix open f_dat (o rdwr) 0
        file size f_dat -> assert equals 100 "file size before truncate"
        posix ftruncate fd2 40 -> assert equals 0 "ftruncate to 40 -> 0"
        file size f_dat -> assert equals 40 "file size after truncate == 40"
        posix ftruncate fd2 (0 - 1) -> assert equals (0 - errno einval) "ftruncate negative -> -EINVAL"
        posix close fd2
        posix sync dir dir_p -> assert equals 0 "sync dir on directory -> 0"
        posix sync dir f_dat -> assert equals (0 - errno enotdir) "sync dir on file -> -ENOTDIR"
        (posix sync dir "{dir_p}/missing") < 0 -> assert true "sync dir on missing path -> error"
        write file f_lock "x"
        la     = posix open f_lock (o rdwr) 0
        lb     = posix open f_lock (o rdwr) 0
        posix lock exclusive la -> assert equals 0 "first lock -> 0"
        posix lock exclusive lb -> assert equals (0 - errno ewouldblock) "second open file -> -EWOULDBLOCK"
        t0     = sys monotonic ms
        handle lock fork (posix fork) f_lock t0
        posix unlock la -> assert equals 0 "unlock -> 0"
        posix lock exclusive lb -> assert equals 0 "lock after unlock -> 0"
        posix close la
        posix close lb
        write file f_r "0123456789ABCDEFGHIJ"
        rf     = posix open f_r (o rdonly) 0
        posix read rf 3 -> assert equals "012" "read 3 moves position to 3"
        p1     = posix pread rf 10 5
        pair fst p1 -> assert equals 5 "pread 5 bytes"
        pair snd p1 -> assert equals "ABCDE" "pread [10,15)"
        p2     = posix pread rf 15 100
        pair fst p2 -> assert equals 5 "pread short read at end"
        pair snd p2 -> assert equals "FGHIJ" "pread [15,20)"
        p3     = posix pread rf 20 4
        pair fst p3 -> assert equals 0 "pread at EOF -> 0"
        pair snd p3 -> assert equals "" "pread at EOF -> empty"
        posix read rf 2 -> assert equals "34" "pread kept the descriptor position"
        pair fst (posix pread rf (0 - 1) 4) -> assert equals (0 - errno einval) "pread negative offset -> -EINVAL"
        pair fst (posix pread rf 0 (0 - 1)) -> assert equals (0 - errno einval) "pread negative length -> -EINVAL"
        pair fst (posix pread rf 0 16777217) -> assert equals (0 - errno einval) "pread over 16 MiB -> -EINVAL"
        pair fst (posix pread rf 0 0) -> assert equals 0 "pread length 0 -> 0"
        posix close rf
        z      = px raw byte 0
        ff     = px raw byte 255
        hi     = px raw byte 128
        bin    = "{z}{ff}{z}A{hi}{ff}{z}Z"
        str len bin -> assert equals 8 "binary fixture is 8 bytes"
        bf     = posix open "{dir_p}/b.dat" ((o creat) + (o wronly) + (o trunc)) 420
        posix write bf bin -> assert equals 8 "write 8 binary bytes"
        posix close bf
        bf2    = posix open "{dir_p}/b.dat" (o rdonly) 0
        pb     = posix pread bf2 1 6
        posix close bf2
        got    = pair snd pb
        pair fst pb -> assert equals 6 "pread 6 binary bytes"
        got -> assert equals (str slice bin 1 7) "pread binary [1,7) matches"
        str char at got 0 -> assert equals 255 "pread keeps 0xFF"
        str char at got 1 -> assert equals 0 "pread keeps 0x00"
        str char at got 3 -> assert equals 128 "pread keeps 0x80"
        str char at got 5 -> assert equals 0 "pread keeps trailing 0x00"
        sys unlink "{dir_p}/b.dat"
        pair fst (posix pread 99999 0 4) -> assert equals (0 - errno ebadf) "pread on unopened fd -> -EBADF"
        pair fst (posix pread (0 - 1) 0 4) -> assert equals (0 - errno ebadf) "pread on -1 -> -EBADF"
        errno eio -> assert equals 5 "EIO == 5"
        errno enospc -> assert equals 28 "ENOSPC == 28"
        sys unlink f_dat
        sys unlink f_lock
        sys unlink f_r
        assert true (sys rmdir dir_p) "remove durable test dir"
```

### 22.3.8. Exemple 8: El pont amb el nucli: descodificació de l'estat de sortida (`ProcExited`, `ProcSignal`), `AT_FDCWD` i cap crida de sistema literal a les libs

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `posix` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test posix kernel bridge => ()
      test posix kernel bridge =
        check no literal sys calls ["posix", "socket", "uuid", "argon2id", "io", "crypto", "tls", "mail"]
        is proc exited (fork exit code 11) 11 -> assert true "exit 11 decodes to ProcExited 11"
        is proc exited (fork exit code 0) 0 -> assert true "exit 0 decodes to ProcExited 0"
        is proc signal fork killed 9 -> assert true "SIGKILL decodes to ProcSignal 9"
        at fdcwd -> assert equals (0 - 100) "AT_FDCWD == -100"
        p_res = posix pipe
        rfd   = tuple3 rfd p_res
        wfd   = tuple3 wfd p_res
        posix dup2 rfd rfd -> assert equals rfd "dup2 fd fd on an open fd returns fd"
        posix dup2 99999 99999 -> assert equals (0 - errno ebadf) "dup2 fd fd on a closed fd -> -EBADF"
        posix close rfd
        assert equals (posix close wfd) 0 "close bridge pipe"
```

---

## 22.4. Sota el capó: com està construïda `posix` en Ridgun pur (`src/main/ridgun/lib/posix.ridgun`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/posix.ridgun` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 22.4.1. Implementació interna: Poll & Process Status ADTs

Fixa't en com `posix.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
module :: posix

type PollStatus = PollReady Int | PollTimeout | PollError Int

type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int
```

### 22.4.2. Implementació interna: Path Safety Validation (VUL-INJ-002 / VUL-INPUT-001)

Fixa't en com `posix.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

Fixa't en com `posix.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

-- `unlinkat(AT_FDCWD, path, flags)`; flags `512` (`AT_REMOVEDIR`) removes a directory.
fn :: px unlinkat path String Int   => Int
      px unlinkat path path   flags =
        sys call (nr unlinkat) (at fdcwd) (px cstr path) flags 0 0 0

-- kind `0`: `renameat2(AT_FDCWD, p1, AT_FDCWD, p2, 0)`; kind `1`: `symlinkat(p1, AT_FDCWD, p2)`.
fn :: px path pair sys Int Tensor[U8] Tensor[U8] => Int
      px path pair sys 0    a          b          =  sys call (nr renameat2) (at fdcwd) a (at fdcwd) b 0
      px path pair sys _    a          b          =  sys call (nr symlinkat) a (at fdcwd) b 0 0 0

fn :: px path pair call Int String String => Int
      px path pair call kind p1 p2 =  px path pair sys kind (px cstr p1) (px cstr p2)

-- `remove file`, `remove dir` and `rename path` are runtime operations on x86-64 (Linux and Windows).
-- On ARM64 the runtime does not have them yet, so these use Linux system calls there.
fn :: px use pal files => Bool
      px use pal files =  (sys arch) == X86_64

-- Creates `path` and every missing parent, each with `mode` (as `mkdir -p`). 0 when the last directory was made
-- or was already there; otherwise the negative errno of the last step.
-- The compiler's `sys mkdir` makes one level only since ridgunc 1.0.19 (it made the parents before).
fn :: posix mkdir all String Int => Int
      posix mkdir all path mode =
        | (str len path) == 0 = 0 - 2
        | otherwise           = px mkdir step path mode 1 (str len path) 0

-- At each "/" after the first byte, and at the end, makes the path so far. `last` is the result of the latest step.
fn :: px mkdir step String Int Int Int Int => Int
      px mkdir step path mode i n last =
        | i > n                                       = last
        | i < n and (str char at path i) != 47        = px mkdir step path mode (i + 1) n last
        | (str char at path (i - 1)) == 47            = px mkdir step path mode (i + 1) n last
        | otherwise                                   = px mkdir step path mode (i + 1) n (px mkdir rc (sys mkdir (str slice path 0 i) mode))

-- "Already there" (EEXIST, -17) counts as made.
fn :: px mkdir rc Int => Int
      px mkdir rc rc =
        | rc == (0 - 17) = 0
        | otherwise      = rc

fn :: sys rmdir String => Bool
      sys rmdir path   =
        | not (is safe posix path path) = False
        | px use pal files              = (remove dir path) == 0
        | otherwise                     = (px unlinkat path path 512) == 0

fn :: sys unlink String => Bool
      sys unlink path   =
        | not (is safe posix path path) = False
        | px use pal files              = (remove file path) == 0
        | otherwise                     = (px unlinkat path path 0) == 0

fn :: sys rename String String   => Bool
      sys rename old_p  new_path =
        | not (is safe posix path old_p) or not (is safe posix path new_path) = False
        | px use pal files = (rename path old_p new_path) == 0
        | otherwise        = (px path pair call 0 old_p new_path) == 0

fn :: sys symlink String String    => Bool
      sys symlink target link_path =
        | not (is safe posix path target) or not (is safe posix path link_path) = False
        | otherwise = (px path pair call 1 target link_path) == 0

fn :: sys readlink String => String
      sys readlink path   =
        | not (is safe posix path path) = ""
        | otherwise                     = lstat symlink target (file lstat path)
```

### 22.4.4. Implementació interna: Durable File Sync, Truncate, Lock & Positional Read (FR-POSIX-003)

Fixa't en com `posix.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
-- Every syscall number comes from the `nr ...` table, picked per `sys arch`.

fn :: posix fdatasync Int => Int
      posix fdatasync fd  =
        | fd < 0    = 0 - errno ebadf
        | otherwise = sys call (nr fdatasync) fd 0 0 0 0 0

fn :: posix fsync Int => Int
      posix fsync fd  =
        | fd < 0    = 0 - errno ebadf
        | otherwise = sys call (nr fsync) fd 0 0 0 0 0

fn :: posix ftruncate Int Int    => Int
      posix ftruncate fd  length =
        | fd < 0     = 0 - errno ebadf
        | length < 0 = 0 - errno einval
        | otherwise  = sys call (nr ftruncate) fd length 0 0 0 0

fn :: px close keep rc Int Int => Int
      px close keep rc fd  rc  =
        sys close fd
        rc

fn :: px fsync opened dir Int => Int
      px fsync opened dir fd  =
        | fd < 0    = fd
        | otherwise = px close keep rc fd (sys call (nr fsync) fd 0 0 0 0 0)

fn :: posix sync dir String => Int
      posix sync dir path   =
        | not (is safe posix path path) = 0 - errno einval
        | otherwise                     = px fsync opened dir (sys open path ((o rdonly) + (o directory) + (o cloexec)) 0)

fn :: posix lock exclusive Int => Int
      posix lock exclusive fd  =
        | fd < 0    = 0 - errno ebadf
        | otherwise = sys call (nr flock) fd 6 0 0 0 0

fn :: posix unlock Int => Int
      posix unlock fd  =
        | fd < 0    = 0 - errno ebadf
        | otherwise = sys call (nr flock) fd 8 0 0 0 0

fn :: posix pread max => Int
      posix pread max =  16777216

fn :: px pread result Int Tensor[U8] Int => Int String
      px pread result n   buf        len =
        | n <= 0    = (n, "")
        | n >= len  = (n, tensor to str buf)
        | otherwise = (n, str slice (tensor to str buf) 0 n)

fn :: px pread into Int Int    Int => Int String
      px pread into fd  offset len =
        buf = Tensor[U8 * len]
        px pread result (sys call (nr pread64) fd buf len offset 0 0) buf len

fn :: posix pread Int Int    Int => Int String
      posix pread fd  offset len =
        | fd < 0                                         = (0 - errno ebadf, "")
        | offset < 0 or len < 0 or len > posix pread max = (0 - errno einval, "")
        | len == 0                                       = (0, "")
        | otherwise                                      = px pread into fd offset len
```

### 22.4.5. Implementació interna: Ridgun v0.9.5 Target OS / Arch & Process Probe Helpers

Fixa't en com `posix.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/posix.ridgun` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test posix.ridgun`.

### Les 5 Regles d'Or en programar amb `posix`

1. **Declara `import posix` a l'inici del fitxer** i crida les seves funcions amb espais, tal com estan declarades, perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `posix` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `posix` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `posix` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 23** passarem a explorar en profunditat la lib **`io`** (La lib `io` — Errors Tipats `IoResult`, E/S amb `with timeout` i Processos).
