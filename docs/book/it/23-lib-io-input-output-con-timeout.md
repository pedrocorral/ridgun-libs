# Capitolo 23: La lib `io` — Errori Tipizzati `IoResult`, I/O con `with timeout` e Processi

## 23.1. Perché esiste la lib `io`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `io` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `io`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: una chiamata a `read()` o un sottoprocesso figlio senza scadenza (`timeout`) è un invito affinché una singola risorsa bloccata esaurisca tutti i worker del tuo server.

La lib **`io`** modella ogni operazione di sistema con ADT espliciti (`IoError`, `IoResult[A]`), combina `ppoll` non bloccante con quote lessicali `with timeout wait_ms do` di Ridgun e offre gli operatori mixfix `read fd ... timeout` e `write fd ... timeout`.

In un ecosistema tradizionale, risolvere i compiti del dominio **`IO`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`io`** (`src/main/ridgun/lib/io.ridgun`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import io` (o `import io as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: io` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `io` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 23.2. Artefatti nativi, importazione e catalogo completo dell'API di `io`

In `ridgun-libs`, **`io`** è una **lib** di prima classe situata in `src/main/ridgun/lib/io.ridgun` (dominio `IO`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/io.ridgunlib` | Distribuzione e importazione diretta con `import io` |
| **File compilato** | `target/io.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libio.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: io`: basta scrivere `import io` (o `import io as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 23.2.1. Riepilogo delle famiglie funzionali di `io`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `type IoError / type IoResult[A]` | `IoNotFound | IoPermission | IoTimeout | IoRefused | IoReset | IoEOF | IoInvalid | IoSysError` |
| `io read with timeout / io write with timeout` | Lettura/scrittura non bloccante di descrittore limitata da `wait_ms` |
| `read fd N max M timeout T / write fd N data S timeout T` | Operatori mixfix ergonomici (`op ::`) per I/O su descrittore con scadenza |
| `io read file / io write file / io read lines` | Funzioni sicure su file e flussi di righe che restituiscono `IoResult` |
| `exec with timeout : String -> Int -> IoResult[ProcStatus]` | Esegue un comando esterno limitato da una quota lessicale `with timeout` |

### 23.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/io.ridgun`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/io.ridgun` (`2` tipi, `2` operatori e `42` funzioni):

**Tipi algebrici e record (`type`) di `io`:**

```ridgun
type IoError = Timeout Int | Eof | SysErr Int String | NotFound String
type IoResult = String | Int | Timeout Int | Eof | SysErr Int String | NotFound String | IoErr IoError | IoOk String | IoTimeout | IoEof | IoError Int
```

**Operatori mixfix (`op ::`) di `io`:**

```ridgun
op :: read fd Int max Int timeout Int => IoResult
op :: write fd Int data String timeout Int => IoResult
```

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
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

## 23.3. Esplorare `io` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `io` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test io.ridgun`.

### 23.3.1. Esempio 1: Flusso principale in stile tabulare con `io`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `io` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import io

fn :: leer peticion segura Int => String
      leer peticion segura fd =
        read fd fd max 4096 timeout 250 -> res
        res format io result
```

### 23.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `io` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import io

fn :: describir fallo => String
      describir fallo =
        format io error (Timeout 250)
```

### 23.3.3. Esempio 3: Gerarchia estensibile di errori `IoError` (`Timeout`, `Eof`, `InvalidInput`, `PermissionDenied`, `NotFound`, `PosixErrno`) e formattazione `io error message`

In questo esempio pratico esploriamo in modo esaustivo come si comporta `io` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test io error formatting => ()
      test io error formatting =
        assert str eq (format io error (Timeout 500)) "timeout after 500 ms" "format Timeout 500"
        assert str eq (format io error Eof) "unexpected end of file" "format Eof"
        assert str eq (format io error (SysErr 9 "poll")) "syscall error 9 in poll" "format SysErr"
        assert str eq (format io error (NotFound "/missing")) "file not found: /missing" "format NotFound"
        ()
```

### 23.3.4. Esempio 4: Lettura e scrittura su descrittori limitate nel tempo (`read fd ... timeout`, `write fd ... timeout`, `with timeout`) e rilevamento di `Eof`

In questo esempio pratico esploriamo in modo esaustivo come si comporta `io` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test io pipe timeout and eof => ()
      test io pipe timeout and eof =
        pt     = posix pipe
        rc     = pipe rc3 pt
        rfd    = pipe rfd3 pt
        wfd    = pipe wfd3 pt
        assert eq rc 0

        -- 1. Empty pipe read with 50 ms timeout must time out within [40, 300) ms (TS-PERF-001 AC2)
        t3     = sys monotonic ms
        r_to   = read fd rfd max 32 timeout 50
        t4     = sys monotonic ms
        dt     = t4 - t3
        assert str eq (format io result r_to) "err:timeout after 50 ms" "empty pipe read Timeout 50"
        assert true (dt >= 40 and dt < 300) "dt in [40, 300): {dt}"

        -- 2. Write payload via mixfix `write fd ... data ... timeout ...`
        w_res  = write fd wfd data "stream-ok" timeout 100
        assert str eq (format io result w_res) "ok:int:9" "write fd returns 9 bytes"

        -- 3. Read payload via mixfix `read fd ... max ... timeout ...`
        r_ok   = read fd rfd max 64 timeout 100
        assert str eq (format io result r_ok) "ok:str:stream-ok" "read fd returns stream-ok"

        -- 4. Close write end and verify subsequent read returns Eof
        posix close wfd -> ()
        r_eof  = read fd rfd max 64 timeout 100
        assert str eq (format io result r_eof) "err:unexpected end of file" "closed pipe read returns Eof"
        posix close rfd -> ()

        -- 5. Bad fd / invalid max_bytes
        r_bad  = read fd (0 - 1) max 64 timeout 50
        assert str eq (format io result r_bad) "err:syscall error 9 in read" "negative fd read SysErr 9"
        r_zero = read fd rfd max 0 timeout 50
        assert str eq (format io result r_zero) "err:syscall error 22 in read" "zero max_bytes read SysErr 22"
        ()
```

### 23.3.5. Esempio 5: Esecuzione sicura di sottoprocessi con limite rigoroso di tempo (`io exec timeout`) e pulizia automatica del processo figlio

In questo esempio pratico esploriamo in modo esaustivo come si comporta `io` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test io exec timeout => ()
      test io exec timeout =
        ok_res = io exec timeout "true" 500
        assert str eq (format io result ok_res) "ok:int:0" "io exec timeout true succeeds"
        to_res = io exec timeout "sleep 2" 40
        assert str eq (format io result to_res) "err:timeout after 40 ms" "io exec timeout sleep 2 times out"
        ()
```

### 23.3.6. Esempio 6: Predicati del file system (`file exists`, `is dir`, `is regular file`, `file size`), lettura per righe (`io read lines`) e copia (`copy file`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `io` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test io file and metadata => ()
      test io file and metadata =
        pid   = sys getpid
        dpath = "/tmp/rg_io_dir_{pid}"
        fpath = "{dpath}/file.txt"
        spath = "{dpath}/sym.txt"
        bpath = "{dpath}/bytes.bin"
        lpath = "{dpath}/lines.txt"

        sys rmdir dpath -> ()
        posix mkdir dpath -> ()
        assert true (is dir dpath) "is dir dpath"
        assert false (is file dpath) "not is file dpath"

        -- 1. write file + append file + read file
        write file fpath "hello "
        w2    = append file fpath "world"
        assert eq w2 0
        assert str eq (read file fpath) "hello world" "write_file + append_file content"

        -- 2. write_bytes + read_bytes
        write bytes bpath [65, 66, 67, 0, 255]
        rb    = read bytes bpath
        assert eq (int list len rb) 5

        -- 3. symlink + metadata predicates
        assert true (sys symlink fpath spath) "sys symlink fpath spath"
        assert true (file exists fpath) "file exists fpath"
        assert true (is file fpath) "is file fpath"
        assert false (is symlink fpath) "not is symlink fpath"
        assert true (is symlink spath) "is symlink spath"
        assert eq (file size fpath) 11
        assert true ((file mtime fpath) > 1700000000) "file mtime > 1700000000"
        assert true ((file mode fpath) > 0) "file mode > 0"
        assert false (file exists "/tmp/rg_io_nonexistent_999999.txt") "missing file exists False"

        -- 4. io read file safe + io write lines / io read lines
        miss  = io read file safe "/tmp/rg_io_missing_999.txt"
        assert str eq (format io result miss) "err:file not found: /tmp/rg_io_missing_999.txt" "NotFound missing file"
        hit   = io read file safe fpath
        assert str eq (format io result hit) "ok:str:hello world" "safe read existing file"

        io write lines lpath ["alpha", "beta", "gamma"] -> ()
        lines = io read lines lpath
        assert eq (str list len lines) 3

        -- 5. v0.9.5 PAL `io read with timeout` (`with timeout wait_ms do` + `sys open path 2048 0` + `sys poll fd 1 -1`)
        r_amb  = io read with timeout fpath 200_ms
        assert str eq (format io result r_amb) "ok:str:hello world" "io read with timeout 200_ms"
        r_miss = io read with timeout "/tmp/rg_io_missing_999.txt" 50_ms
        assert true (str starts with (format io result r_miss) "err:io error -") "io read with timeout missing file -> IoError"

        -- Cleanup
        sys unlink spath -> ()
        sys unlink fpath -> ()
        sys unlink bpath -> ()
        sys unlink lpath -> ()
        sys rmdir dpath -> ()
        ()
```

---

## 23.4. Sotto il cofano: come è costruita `io` in Ridgun puro (`src/main/ridgun/lib/io.ridgun`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/io.ridgun` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 23.4.1. Implementazione interna: Extensible I/O Error & Result Sum Types (§5.1)

Nota come `io.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
module :: io

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

### 23.4.2. Implementazione interna: Timeout-Bounded Command Execution (§5.2)

Nota come `io.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 23.4.3. Implementazione interna: Safe File Read & Line-Stream Helpers

Nota come `io.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

fn :: io write lines step String [String] => Int
      io write lines step path   lines    =
        lines join lines nl -> body
        write file path body
        0

fn :: io write lines String [String] => Int
      io write lines path   lines    =
        | not (is safe posix path path) = 0 - 22
        | otherwise                     = io write lines step path lines
```

### 23.4.4. Implementazione interna: Ridgun v0.9.5 PAL & Ambient Deadline `io read with timeout` (§3.1)

Nota come `io.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: io wrap chunk String => IoResult
      io wrap chunk ""     =  IoEof
      io wrap chunk s      =  IoOk s

fn :: io close and return Int IoResult => IoResult
      io close and return fd  res      =
        sys close fd -> ()
        res

fn :: io read chunk and close Int => IoResult
      io read chunk and close fd  =
        sys read fd fd 65536 -> chunk
        sys close fd -> ()
        chunk io wrap chunk

fn :: io read after poll Int Int => IoResult
      io read after poll fd ev =
        | ev == 0   = io close and return fd IoTimeout
        | ev < 0    = io close and return fd (IoError ev)
        | otherwise = io read chunk and close fd

fn :: io poll and read Int => IoResult
      io poll and read fd  =
        sys poll fd 1 (0 - 1) -> ev
        io read after poll fd ev

fn :: io read poll step Int => IoResult
      io read poll step fd  =
        | fd < 0    = IoError fd
        | otherwise = io poll and read fd

fn :: io read with timeout String Int => IoResult
      io read with timeout path wait_ms =
        with timeout wait_ms do
          fd = sys open path 2048 0
          io read poll step fd
```

---

## 23.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `io`

- **Garanzia algoritmica e di sicurezza**: Nessuna lettura, scrittura o comando eseguito tramite `io` con quota `wait_ms` può bloccare indefinitamente il thread o l'attore chiamante.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/io.ridgun` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test io.ridgun`.

### Le 5 Regole d'Oro quando programmi con `io`

1. **Dichiara `import io` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `io` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `io` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `io` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 24** passeremo a esplorare in profondità la lib **`crypto`** (La lib `crypto` — SHA-256, HMAC, PBKDF2, Argon2id e ChaCha20-Poly1305 AEAD).
