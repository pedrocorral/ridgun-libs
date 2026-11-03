# Capitolo 22: La lib `posix` — Livello di Astrazione della Piattaforma (PAL), Orologi, Segnali e CSPRNG

## 22.1. Perché esiste la lib `posix`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `posix` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `posix`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: flag come `O_CREAT`, `O_NONBLOCK` o i numeri di syscall cambiano tra Linux, macOS e architetture (`X86_64` vs `Arm64`), e in C tutto si risolve con una giungla illeggibile di `#ifdef`.

La lib **`posix`** implementa il **Livello di Astrazione della Piattaforma (PAL)** a 2 livelli di Ridgun usando guardie tabulari su `sys os` (`Linux | MacOS | Windows`) e `sys arch` (`X86_64 | Arm64 | RiscV64`), oltre a polling dei descrittori (`wait fd` / `PollStatus`), orologi monotoni e di sistema (`RGF-017`), segnali (`RGF-018`) ed entropia CSPRNG del kernel (`sys random bytes`).

In un ecosistema tradizionale, risolvere i compiti del dominio **`POSIX`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`posix`** (`src/main/ridgun/lib/posix.rg`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import posix` (o `import posix as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: posix` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `posix` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 22.2. Artefatti nativi, importazione e catalogo completo dell'API di `posix`

In `ridgun-libs`, **`posix`** è una **lib** di prima classe situata in `src/main/ridgun/lib/posix.rg` (dominio `POSIX`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/posix.rglib` | Distribuzione e importazione diretta con `import posix` |
| **File compilato** | `target/posix.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libposix.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: posix`: basta scrivere `import posix` (o `import posix as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 22.2.1. Riepilogo delle famiglie funzionali di `posix`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `pal open create trunc wr / pal o nonblock` | Traduzione dei flag del sistema operativo secondo `sys os` (`Linux | MacOS | Windows`) |
| `wait fd : Int -> Int -> Int -> PollStatus` | Esegue il polling di un descrittore restituendo `PollReady`, `PollTimeout` o `PollError errno` |
| `clock monotonic ms / clock monotonic ns / clock wall ms` | Orologi monotoni e orologio di sistema UTC in millisecondi (`RGF-017`) |
| `signal watch / signal poll / sys random bytes` | Polling non bloccante dei segnali (`SIGINT`, `SIGTERM`) e byte CSPRNG del kernel |
| `read text / write text / file exists / run cmd` | I/O di file ad alto livello, directory ed esecuzione di sottoprocessi |

### 22.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/posix.rg`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/posix.rg` (`2` tipi, `0` operatori e `103` funzioni):

**Tipi algebrici e record (`type`) di `posix`:**

```ridgun
type PollStatus = PollReady Int | PollTimeout | PollError Int
type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int
```

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
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

## 22.3. Esplorare `posix` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `posix` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test posix.rg`.

### 22.3.1. Esempio 1: Flusso principale in stile tabulare con `posix`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `posix` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import posix

fn :: medir operacion => Int Int
      medir operacion =
        clock monotonic ms -> t0
        sys random bytes 32 -> (+ _) -> rc
        clock monotonic ms -> t1
        (rc, t1 - t0)
```

### 22.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `posix` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import posix

fn :: esperar lectura Int => PollStatus
      esperar lectura fd =
        wait fd fd (poll in) 100
```

### 22.3.3. Esempio 3: Costanti POSIX (`O_*`, `POLL*`, `SIG*`), validazione di percorsi sicuri, pipe anonime (`sys pipe`) e polling `sys poll status`

In questo esempio pratico esploriamo in modo esaustivo come si comporta `posix` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 22.3.4. Esempio 4: Metadati `lstat`, orologi monotoni e di sistema (`clock_gettime`), segnali via descrittore (`signalfd4`) ed entropia del kernel (`sys random bytes`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `posix` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 22.3.5. Esempio 5: Comunicazione tra processi tramite pipe (`sys pipe`), polling non bloccante (`sys poll status`) e temporizzazione monotona (`sys monotonic ns`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `posix` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

## 22.4. Sotto il cofano: come è costruita `posix` in Ridgun puro (`src/main/ridgun/lib/posix.rg`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/posix.rg` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 22.4.1. Implementazione interna: Poll & Process Status ADTs

Nota come `posix.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
module :: posix

type PollStatus = PollReady Int | PollTimeout | PollError Int

type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int
```

### 22.4.2. Implementazione interna: Path Safety Validation (VUL-INJ-002 / VUL-INPUT-001)

Nota come `posix.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 22.4.3. Implementazione interna: RG-010 Filesystem & Process Operations

Nota come `posix.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 22.4.4. Implementazione interna: Ridgun v0.9.5 Target OS / Arch & Process Probe Helpers

Nota come `posix.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

## 22.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `posix`

- **Garanzia algoritmica e di sicurezza**: I rami di `sys os` e `sys arch` che non corrispondono al binario di destinazione vengono eliminati in fase di compilazione (Dead-Code Elimination) da `ridgunc`.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/posix.rg` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test posix.rg`.

### Le 5 Regole d'Oro quando programmi con `posix`

1. **Dichiara `import posix` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `posix` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `posix` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `posix` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 23** passeremo a esplorare in profondità la lib **`io`** (La lib `io` — Errori Tipizzati `IoResult`, I/O con `with timeout` e Processi).
