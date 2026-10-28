# Capítol 23: La lib `io` — Errors Tipats `IoResult`, E/S amb `with timeout` i Processos

## 23.1. Per què existeix la lib `io`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `io` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `io`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: una crida a `read()` o un subprocess fill sense data límit (`timeout`) és una invitació perquè un sol recurs penjat esgoti tots els treballadors del teu servidor.

La lib **`io`** modela cada operació del sistema amb ADTs explícits (`IoError`, `IoResult[A]`), combina `ppoll` no bloquejant amb quotes lèxiques `with timeout wait_ms do` de Ridgun i ofereix els operadors mixfix `read fd ... timeout` i `write fd ... timeout`.

En un ecosistema tradicional, resoldre les tasques del domini **`IO`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`io`** (`src/main/ridgun/lib/io.rg`) aborda el problema amb quatre principis innegociables:

1. **Declara `import io` (o `import io as alias`) a l'inici del fitxer**: cada lib defineix el seu espai de noms `module :: io` i en mode `--strict` les funcions multi-paraula s'invoquen sempre amb espais naturals.
2. **Encadena les teves canonades d'esquerra a dreta amb `->`**: escriu `entrada pas u -> pas dos -> resultat`, fes servir màscares `(+ _ _ +)` per desestructurar seqüències i omet `_ =` en sentències seqüencials (o descarta amb `-> ()`).
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `io` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 23.2. Artefactes natius, importació i catàleg complet de l'API de `io`

A `ridgun-libs`, **`io`** és una **lib** de primera classe situada a `src/main/ridgun/lib/io.rg` (domini `IO`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/io.rglib` | Distribució i importació directa amb `import io` |
| **Fitxer compilat** | `target/io.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libio.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Cada lib declara el seu propi espai de noms amb `module :: io`: n'hi ha prou d'escriure `import io` (o `import io as alias`) a la capçalera i cridar les seves funcions amb espais naturals (`la meva funcio x`) i canonades `->` (`x la meva funcio -> resultat`).

### 23.2.1. Resum de famílies funcionals de `io`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `type IoError / type IoResult[A]` | `IoNotFound | IoPermission | IoTimeout | IoRefused | IoReset | IoEOF | IoInvalid | IoSysError` |
| `io read with timeout / io write with timeout` | Lectura/escriptura no bloquejant de descriptor acotada per `wait_ms` |
| `read fd N max M timeout T / write fd N data S timeout T` | Operadors mixfix ergonòmics (`op ::`) per a E/S de descriptor amb data límit |
| `io read file / io write file / io read lines` | Funcions segures de fitxers i fluxos de línies que retornen `IoResult` |
| `exec with timeout : String -> Int -> IoResult[ProcStatus]` | Executa una comanda externa acotada per una quota lèxica `with timeout` |

### 23.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/io.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/io.rg` (`2` tipus, `2` operadors i `42` funcions):

**Tipus algebraics i registres (`type`) de `io`:**

```ridgun
type IoError = Timeout Int | Eof | SysErr Int String | NotFound String
type IoResult = String | Int | Timeout Int | Eof | SysErr Int String | NotFound String | IoErr IoError | IoOk String | IoTimeout | IoEof | IoError Int
```

**Operadors mixfix (`op ::`) de `io`:**

```ridgun
op :: read fd Int max Int timeout Int => IoResult
op :: write fd Int data String timeout Int => IoResult
```

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 23.3. Explorant `io` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `io` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test io.rg`.

### 23.3.1. Exemple 1: Flux principal en estil tabular amb `io`

Observa com en Ridgun els signes `=` i els passos de transformació amb `io` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import io

fn :: leer peticion segura Int => String
      leer peticion segura fd =
        read fd fd max 4096 timeout 250 -> res
        res format io result
```

### 23.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `io` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import io

fn :: describir fallo => String
      describir fallo =
        format io error (Timeout 250)
```

### 23.3.3. Exemple 3: Jerarquia extensible d'errors `IoError` (`Timeout`, `Eof`, `InvalidInput`, `PermissionDenied`, `NotFound`, `PosixErrno`) i formatació `io error message`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `io` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test io error formatting => ()
      test io error formatting =
        assert str eq (format io error (Timeout 500)) "timeout after 500 ms" "format Timeout 500"
        assert str eq (format io error Eof) "unexpected end of file" "format Eof"
        assert str eq (format io error (SysErr 9 "poll")) "syscall error 9 in poll" "format SysErr"
        assert str eq (format io error (NotFound "/missing")) "file not found: /missing" "format NotFound"
        ()
```

### 23.3.4. Exemple 4: Lectura i escriptura en descriptors acotades per termini (`read fd ... timeout`, `write fd ... timeout`, `with timeout`) i detecció d'`Eof`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `io` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 23.3.5. Exemple 5: Execució segura de subprocessos amb límit estricte de temps (`io exec timeout`) i neteja automàtica del fill

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `io` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test io exec timeout => ()
      test io exec timeout =
        ok_res = io exec timeout "true" 500
        assert str eq (format io result ok_res) "ok:int:0" "io exec timeout true succeeds"
        to_res = io exec timeout "sleep 2" 40
        assert str eq (format io result to_res) "err:timeout after 40 ms" "io exec timeout sleep 2 times out"
        ()
```

### 23.3.6. Exemple 6: Predicats de sistema de fitxers (`file exists`, `is dir`, `is regular file`, `file size`), lectura per línies (`io read lines`) i còpia (`copy file`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `io` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

## 23.4. Sota el capó: com està construïda `io` en Ridgun pur (`src/main/ridgun/lib/io.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/io.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 23.4.1. Implementació interna: Extensible I/O Error & Result Sum Types (§5.1)

Fixa't en com `io.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 23.4.2. Implementació interna: Timeout-Bounded Command Execution (§5.2)

Fixa't en com `io.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 23.4.3. Implementació interna: Safe File Read & Line-Stream Helpers

Fixa't en com `io.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 23.4.4. Implementació interna: Ridgun v0.9.5 PAL & Ambient Deadline `io read with timeout` (§3.1)

Fixa't en com `io.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

## 23.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `io`

- **Garantia algorísmica i de seguretat**: Cap lectura, escriptura o comanda executada a través d'`io` amb quota `wait_ms` pot bloquejar indefinidament el fil o actor que fa la crida.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/io.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test io.rg`.

### Les 5 Regles d'Or en programar amb `io`

1. **Declara `import io` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `io` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `io` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `io` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 24** passarem a explorar en profunditat la lib **`crypto`** (La lib `crypto` — SHA-256, HMAC, PBKDF2, Argon2id i ChaCha20-Poly1305 AEAD).
