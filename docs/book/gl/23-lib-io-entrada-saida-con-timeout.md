# Capítulo 23: A lib `io` — Erros Tipados `IoResult`, E/S con `with timeout` e Procesos

## 23.1. Por que existe a lib `io`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `io` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `io`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: unha chamada a `read()` ou un subproceso fillo sen data límite (`timeout`) é unha invitación a que un só recurso colgado esgote todos os traballadores do teu servidor.

A lib **`io`** modela cada operación do sistema con ADTs explícitos (`IoError`, `IoResult[A]`), combina `ppoll` non bloqueante con cotas léxicas `with timeout wait_ms do` de Ridgun e ofrece os operadores mixfix `read fd ... timeout` e `write fd ... timeout`.

Nun ecosistema tradicional, resolver as tarefas do dominio **`IO`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`io`** (`src/main/ridgun/lib/io.rg`) aborda o problema con catro principios innegociables:

1. **Declara `import io` (ou `import io as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: io` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `io` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 23.2. Artefactos nativos, importación e catálogo completo da API de `io`

En `ridgun-libs`, **`io`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/io.rg` (dominio `IO`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/io.rglib` | Distribución e importación directa con `import io` |
| **Ficheiro compilado** | `target/io.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libio.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Cada lib declara o seu propio espazo de nomes con `module :: io`: abonda con escribir `import io` (ou `import io as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 23.2.1. Resumo de familias funcionais de `io`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `type IoError / type IoResult[A]` | `IoNotFound | IoPermission | IoTimeout | IoRefused | IoReset | IoEOF | IoInvalid | IoSysError` |
| `io read with timeout / io write with timeout` | Lectura/escritura non bloqueante de descritor acoutada por `wait_ms` |
| `read fd N max M timeout T / write fd N data S timeout T` | Operadores mixfix ergonómicos (`op ::`) para E/S de descritor con data límite |
| `io read file / io write file / io read lines` | Funcións seguras de ficheiros e fluxos de liñas que devolven `IoResult` |
| `exec with timeout : String -> Int -> IoResult[ProcStatus]` | Executa un comando externo acoutado por unha cota léxica `with timeout` |

### 23.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/io.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/io.rg` (`2` tipos, `2` operadores e `42` funcións):

**Tipos alxébricos e rexistros (`type`) de `io`:**

```ridgun
type IoError = Timeout Int | Eof | SysErr Int String | NotFound String
type IoResult = String | Int | Timeout Int | Eof | SysErr Int String | NotFound String | IoErr IoError | IoOk String | IoTimeout | IoEof | IoError Int
```

**Operadores mixfix (`op ::`) de `io`:**

```ridgun
op :: read fd Int max Int timeout Int => IoResult
op :: write fd Int data String timeout Int => IoResult
```

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 23.3. Explorando `io` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `io` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test io.rg`.

### 23.3.1. Exemplo 1: Fluxo principal en estilo tabular con `io`

Observa como en Ridgun os signos `=` e os pasos de transformación con `io` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import io

fn :: leer peticion segura Int => String
      leer peticion segura fd =
        read fd fd max 4096 timeout 250 -> res
        res format io result
```

### 23.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `io` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import io

fn :: describir fallo => String
      describir fallo =
        format io error (Timeout 250)
```

### 23.3.3. Exemplo 3: Xerarquía extensible de erros `IoError` (`Timeout`, `Eof`, `InvalidInput`, `PermissionDenied`, `NotFound`, `PosixErrno`) e formatado `io error message`

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `io` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test io error formatting => ()
      test io error formatting =
        assert str eq (format io error (Timeout 500)) "timeout after 500 ms" "format Timeout 500"
        assert str eq (format io error Eof) "unexpected end of file" "format Eof"
        assert str eq (format io error (SysErr 9 "poll")) "syscall error 9 in poll" "format SysErr"
        assert str eq (format io error (NotFound "/missing")) "file not found: /missing" "format NotFound"
        ()
```

### 23.3.4. Exemplo 4: Lectura e escritura en descritores acoutadas por prazo (`read fd ... timeout`, `write fd ... timeout`, `with timeout`) e detección de `Eof`

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `io` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 23.3.5. Exemplo 5: Execución segura de subprocesos con límite estrito de tempo (`io exec timeout`) e limpeza automática do fillo

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `io` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test io exec timeout => ()
      test io exec timeout =
        ok_res = io exec timeout "true" 500
        assert str eq (format io result ok_res) "ok:int:0" "io exec timeout true succeeds"
        to_res = io exec timeout "sleep 2" 40
        assert str eq (format io result to_res) "err:timeout after 40 ms" "io exec timeout sleep 2 times out"
        ()
```

### 23.3.6. Exemplo 6: Predicados de sistema de ficheiros (`file exists`, `is dir`, `is regular file`, `file size`), lectura por liñas (`io read lines`) e copia (`copy file`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `io` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

## 23.4. Baixo o capó: como está construída `io` en Ridgun puro (`src/main/ridgun/lib/io.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/io.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 23.4.1. Implementación interna: Extensible I/O Error & Result Sum Types (§5.1)

Fíxate en como `io.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

### 23.4.2. Implementación interna: Timeout-Bounded Command Execution (§5.2)

Fíxate en como `io.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

Fíxate en como `io.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

### 23.4.4. Implementación interna: Ridgun v0.9.5 PAL & Ambient Deadline `io read with timeout` (§3.1)

Fíxate en como `io.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

## 23.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `io`

- **Garantía algorítmica e de seguridade**: Ningunha lectura, escritura ou comando executado a través de `io` con cota `wait_ms` pode bloquear indefinidamente o fío ou actor chamante.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/io.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test io.rg`.

### As 5 Regras de Ouro ao programar con `io`

1. **Declara `import io` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `io` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `io` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `io` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 24** pasaremos a explorar en profundidade a lib **`crypto`** (A lib `crypto` — SHA-256, HMAC, PBKDF2, Argon2id e ChaCha20-Poly1305 AEAD).
