# Kapitel 22: Lib:en `posix` — Plattformslager (PAL), Klockor, Signaler och CSPRNG

## 22.1. Varför finns lib:en `posix`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `posix`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `posix`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: flaggor som `O_CREAT` och `O_NONBLOCK` eller syscall-nummer skiljer sig mellan Linux, macOS och arkitekturer (`X86_64` mot `Arm64`), och i C löser man det med en oläslig `#ifdef`-djungel.

Lib:en **`posix`** implementerar Ridguns tvåskikts **Platform Abstraction Layer (PAL)** med tabulära vakter över `sys os` (`Linux | MacOS | Windows`) och `sys arch` (`X86_64 | Arm64 | RiscV64`), samt deskriptor-polling (`wait fd`), monotona klockor (`RGF-017`), signaler (`RGF-018`) och CSPRNG (`sys random bytes`).

I ett traditionellt ekosystem innebär uppgifter inom domänen **`POSIX`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`posix`** (`src/main/ridgun/lib/posix.rg`) problemet genom fyra kompromisslösa principer:

1. **Deklarera `import posix` (eller `import posix as alias`) överst i filen**: varje lib definierar sin `module :: posix`-namnrymd och i `--strict`-läge anropas flerordsfunktioner alltid med naturliga mellanslag.
2. **Kedja dina datapipelines från vänster till höger med `->`**: skriv `indata steg ett -> steg två -> resultat`, använd `(+ _ _ +)`-sekvensmasker för att packa upp tupler och utelämna `_ =` vid sekventiella satser (eller kasta med `-> ()`).
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `posix` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 22.2. Inbyggda artefakter, import och komplett API-katalog för `posix`

I `ridgun-libs` är **`posix`** en förstklassig **lib** placerad i `src/main/ridgun/lib/posix.rg` (domän `POSIX`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/posix.rglib` | Portabel distribution och direkt import med `import posix` |
| **Kompilerat arkiv** | `target/posix.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libposix.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> Varje lib deklarerar sin egen namnrymd med `module :: posix`: skriv bara `import posix` (eller `import posix as alias`) överst och anropa dess funktioner med naturliga mellanslag (`min funktion x`) och `->`-pipelines (`x min funktion -> resultat`).

### 22.2.1. Översikt över funktionella familjer i `posix`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `pal open create trunc wr / pal o nonblock` | Målmedveten OS-flaggöversättning via `sys os` (`Linux | MacOS | Windows`) |
| `wait fd : Int -> Int -> Int -> PollStatus` | Pollar en deskriptor och returnerar `PollReady`, `PollTimeout` eller `PollError errno` |
| `clock monotonic ms / clock monotonic ns / clock wall ms` | Monotona klockor och UTC-väggklocka i millisekunder (`RGF-017`) |
| `signal watch / signal poll / sys random bytes` | Icke-blockerande signal-polling (`SIGINT`, `SIGTERM`) och CSPRNG-bytes från kärnan |
| `read text / write text / file exists / run cmd` | Högnivå-fil-I/O, katalogoperationer och barnprocess-wrappers |

### 22.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/posix.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/posix.rg` (`2` typer, `0` operatorer och `103` funktioner):

**Algebraiska datatyper och poster (`type`) i `posix`:**

```ridgun
type PollStatus = PollReady Int | PollTimeout | PollError Int
type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int
```

| # | Funktion / Signatur (`fn ::`) | Returtyp |
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

## 22.3. Djupdykning i `posix`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `posix` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test posix.rg`.

### 22.3.1. Exempel 1: Huvudflöde i tabellform med `posix`

Lägg märke till hur `=`-tecknen och transformationsstegen med `posix` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import posix

fn :: medir operacion => Int Int
      medir operacion =
        clock monotonic ms -> t0
        sys random bytes 32 -> (+ _) -> rc
        clock monotonic ms -> t1
        (rc, t1 - t0)
```

### 22.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `posix` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import posix

fn :: esperar lectura Int => PollStatus
      esperar lectura fd =
        wait fd fd (poll in) 100
```

### 22.3.3. Exempel 3: POSIX-konstanter (`O_*`, `POLL*`, `SIG*`), säker sökvägsvalidering, anonyma rör (`sys pipe`) och `sys poll status`-avfrågning

I detta praktiska exempel undersöker vi grundligt hur `posix` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 22.3.4. Exempel 4: `lstat`-metadata, monotoniska och väggklockor (`clock_gettime`), signalbevakning via deskriptor (`signalfd4`) och kärnentropi (`sys random bytes`)

I detta praktiska exempel undersöker vi grundligt hur `posix` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 22.3.5. Exempel 5: Processkommunikation via rör (`sys pipe`), icke-blockerande avfrågning (`sys poll status`) och monotonisk tidtagning (`sys monotonic ns`)

I detta praktiska exempel undersöker vi grundligt hur `posix` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

## 22.4. Under huven: hur `posix` är byggd i ren Ridgun (`src/main/ridgun/lib/posix.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/posix.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 22.4.1. Intern implementation: Poll & Process Status ADTs

Se hur `posix.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
module :: posix

type PollStatus = PollReady Int | PollTimeout | PollError Int

type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int
```

### 22.4.2. Intern implementation: Path Safety Validation (VUL-INJ-002 / VUL-INPUT-001)

Se hur `posix.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

### 22.4.3. Intern implementation: RG-010 Filesystem & Process Operations

Se hur `posix.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

### 22.4.4. Intern implementation: Ridgun v0.9.5 Target OS / Arch & Process Probe Helpers

Se hur `posix.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

## 22.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `posix`

- **Algoritmisk garanti och säkerhet**: Grenar av `sys os` och `sys arch` som inte matchar målplattformen elimineras statiskt vid kompilering (Dead-Code Elimination) av `ridgunc`.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/posix.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test posix.rg`.

### De 5 Gyllene Reglerna när du programmerar med `posix`

1. **Deklarera `import posix` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `posix`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `posix`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `posix` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 23** går vi vidare och utforskar lib:en **`io`** på djupet (Lib:en `io` — Typade `IoResult`-fel, `with timeout`-I/O och Processer).
