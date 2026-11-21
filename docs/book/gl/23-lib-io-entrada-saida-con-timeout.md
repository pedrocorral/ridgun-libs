# Capítulo 23: A lib `io` — Erros Tipados `IoResult`, E/S con `with timeout` e Procesos

## 23.1. Por que existe a lib `io`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `io` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `io`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: unha chamada a `read()` ou un subproceso fillo sen data límite (`timeout`) é unha invitación a que un só recurso colgado esgote todos os traballadores do teu servidor.

A lib **`io`** modela cada operación do sistema con ADTs explícitos (`IoError`, `IoResult[A]`), combina `ppoll` non bloqueante con cotas léxicas `with timeout wait_ms do` de Ridgun e ofrece os operadores mixfix `read fd ... timeout` e `write fd ... timeout`.

Nun ecosistema tradicional, resolver as tarefas do dominio **`IO`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`io`** (`src/main/ridgun/lib/io.ridgun`) aborda o problema con catro principios innegociables:

1. **Declara `import io` (ou `import io as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: io` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `io` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 23.2. Artefactos nativos, importación e catálogo completo da API de `io`

En `ridgun-libs`, **`io`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/io.ridgun` (dominio `IO`). Ao compilar con `stable bundle`, empaquétase nun formato nativo:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/io.ridgunlib` | Distribución e importación directa con `import io` |

> Cada lib declara o seu propio espazo de nomes con `module :: io`: abonda con escribir `import io` (ou `import io as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 23.2.1. Resumo de familias funcionais de `io`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `IoError / IoResult` | Erros tipados (`Timeout`, `Eof`, `SysErr`, `NotFound`) e o resultado de cada operación |
| `io read with timeout / read fd N max M timeout T / write fd N data S timeout T` | Lecturas e escrituras de descritor acoutadas por un tempo límite, tamén como operadores mixfix (`op ::`) |
| `io exec timeout / exec with timeout` | Executa un comando externo acoutado por un tempo límite |
| `file exists / is file / is dir / is symlink / file size / file mtime / file mode` | Predicados e metadatos do sistema de ficheiros |
| `io read file safe / io read lines / io write lines / append file` | Lectura e escritura seguras de ficheiros completos e de liñas |
| `format io error / format io result` | Texto lexible para un erro ou para un resultado |

### 23.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/io.ridgun`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/io.ridgun` (`2` tipos, `2` operadores e `42` funcións):

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
| `16` | `fn :: append file step String String` | `Int` |
| `17` | `fn :: append file String String` | `Int` |
| `18` | `fn :: file exists String` | `Bool` |
| `19` | `fn :: is file String` | `Bool` |
| `20` | `fn :: is dir String` | `Bool` |
| `21` | `fn :: is symlink String` | `Bool` |
| `22` | `fn :: extract size (Bool String Int Int Int String String Int String)` | `Int` |
| `23` | `fn :: file size String` | `Int` |
| `24` | `fn :: extract mtime (Bool String Int Int Int String String Int String)` | `Int` |
| `25` | `fn :: file mtime String` | `Int` |
| `26` | `fn :: extract mode (Bool String Int Int Int String String Int String)` | `Int` |
| `27` | `fn :: file mode String` | `Int` |
| `28` | `fn :: io read file safe String` | `IoResult` |
| `29` | `fn :: split lines loop String Int Int Int` | `[String]` |
| `30` | `fn :: split non empty lines String Int` | `[String]` |
| `31` | `fn :: io read lines String` | `[String]` |
| `32` | `fn :: str list is empty [String]` | `Bool` |
| `33` | `fn :: join lines nl [String]` | `String` |
| `34` | `fn :: io write lines step String [String]` | `Int` |
| `35` | `fn :: io write lines String [String]` | `Int` |
| `36` | `fn :: io wrap chunk String` | `IoResult` |
| `37` | `fn :: io close and return Int IoResult` | `IoResult` |
| `38` | `fn :: io read chunk and close Int` | `IoResult` |
| `39` | `fn :: io read after poll Int Int` | `IoResult` |
| `40` | `fn :: io poll and read Int` | `IoResult` |
| `41` | `fn :: io read poll step Int` | `IoResult` |
| `42` | `fn :: io read with timeout String Int` | `IoResult` |

---

## 23.3. Explorando `io` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `io` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test io.ridgun`.

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

Toda función da lib `io` está deseñada para compoñerse con gardas booleanas `|` e co resto das 38 libs de `ridgun-libs`:

```ridgun
import io

fn :: describir fallo => String
      describir fallo =
        format io error (Timeout 250)
```

### 23.3.3. Exemplo 3: Xerarquía extensible de erros `IoError` (`Timeout`, `Eof`, `NotFound`, `SysErr`) e formatado `format io error`

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `io` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test io error formatting => ()
      test io error formatting =
        format io error (Timeout 500) -> assert str eq "timeout after 500 ms" "format Timeout 500"
        format io error Eof -> assert str eq "unexpected end of file" "format Eof"
        format io error (SysErr 9 "poll") -> assert str eq "syscall error 9 in poll" "format SysErr"
        format io error (NotFound "/missing") -> assert str eq "file not found: /missing" "format NotFound"
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
        rc -> assert eq 0

        -- 1. Empty pipe read with 50 ms timeout must time out within [40, 300) ms (TS-PERF-001 AC2)
        t3     = sys time ms
        r_to   = read fd rfd max 32 timeout 50
        t4     = sys time ms
        dt     = t4 - t3
        format io result r_to -> assert str eq "err:timeout after 50 ms" "empty pipe read Timeout 50"
        dt >= 40 and dt < 300 -> assert true "dt in [40, 300): {dt}"

        -- 2. Write payload via mixfix `write fd ... data ... timeout ...`
        w_res  = write fd wfd data "stream-ok" timeout 100
        format io result w_res -> assert str eq "ok:int:9" "write fd returns 9 bytes"

        -- 3. Read payload via mixfix `read fd ... max ... timeout ...`
        r_ok   = read fd rfd max 64 timeout 100
        format io result r_ok -> assert str eq "ok:str:stream-ok" "read fd returns stream-ok"

        -- 4. Close write end and verify subsequent read returns Eof
        posix close wfd
        r_eof  = read fd rfd max 64 timeout 100
        format io result r_eof -> assert str eq "err:unexpected end of file" "closed pipe read returns Eof"
        posix close rfd

        -- 5. Bad fd / invalid max_bytes
        r_bad  = read fd (0 - 1) max 64 timeout 50
        format io result r_bad -> assert str eq "err:syscall error 9 in read" "negative fd read SysErr 9"
        r_zero = read fd rfd max 0 timeout 50
        format io result r_zero -> assert str eq "err:syscall error 22 in read" "zero max_bytes read SysErr 22"
        ()
```

### 23.3.5. Exemplo 5: Execución segura de subprocesos con límite estrito de tempo (`io exec timeout`) e limpeza automática do fillo

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `io` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test io exec timeout => ()
      test io exec timeout =
        ok_res = io exec timeout "true" 500
        format io result ok_res -> assert str eq "ok:int:0" "io exec timeout true succeeds"
        to_res = io exec timeout "sleep 2" 40
        format io result to_res -> assert str eq "err:timeout after 40 ms" "io exec timeout sleep 2 times out"
        ()
```

### 23.3.6. Exemplo 6: Predicados de sistema de ficheiros (`file exists`, `is dir`, `is file`, `file size`), lectura por liñas (`io read lines`) e copia

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

        sys rmdir dpath
        posix mkdir dpath
        is dir dpath -> assert true "is dir dpath"
        is file dpath -> assert false "not is file dpath"

        -- 1. write_file + append_file + read_file
        write file fpath "hello "
        w2    = append file fpath "world"
        w2 -> assert eq 0
        read file fpath -> assert str eq "hello world" "write_file + append_file content"

        -- 2. write_bytes + read_bytes (`read bytes` returns Tensor[U8], ADR-0010)
        write bytes bpath [65, 66, 67, 0, 255]
        rb    = read bytes bpath
        bytes len rb -> assert eq 5
        tensor to list rb -> assert eq [65, 66, 67, 0, 255]
        rb_(4) -> assert eq 255
        write bytes bpath (tensor from str "A\nB")
        tensor to str (read bytes bpath) -> assert str eq "A\nB" "write bytes Tensor[U8] round trip"

        -- 3. symlink + metadata predicates
        sys symlink fpath spath -> assert true "sys symlink fpath spath"
        file exists fpath -> assert true "file exists fpath"
        is file fpath -> assert true "is file fpath"
        is symlink fpath -> assert false "not is symlink fpath"
        is symlink spath -> assert true "is symlink spath"
        file size fpath -> assert eq 11
        (file mtime fpath) > 1700000000 -> assert true "file mtime > 1700000000"
        (file mode fpath) > 0 -> assert true "file mode > 0"
        file exists "/tmp/rg_io_nonexistent_999999.txt" -> assert false "missing file exists False"

        -- 4. io read file safe + io write lines / io read lines
        miss  = io read file safe "/tmp/rg_io_missing_999.txt"
        format io result miss -> assert str eq "err:file not found: /tmp/rg_io_missing_999.txt" "NotFound missing file"
        hit   = io read file safe fpath
        format io result hit -> assert str eq "ok:str:hello world" "safe read existing file"

        io write lines lpath ["alpha", "beta", "gamma"]
        lines = io read lines lpath
        str list len lines -> assert eq 3

        -- 5. v0.9.5 PAL `io read with timeout` (`with timeout wait_ms do` + `sys open path 2048 0` + `sys poll fd 1 -1`)
        r_amb  = io read with timeout fpath 200_ms
        format io result r_amb -> assert str eq "ok:str:hello world" "io read with timeout 200_ms"
        r_miss = io read with timeout "/tmp/rg_io_missing_999.txt" 50_ms
        str starts with (format io result r_miss) "err:io error -" -> assert true "io read with timeout missing file -> IoError"

        -- Cleanup
        sys unlink spath
        sys unlink fpath
        sys unlink bpath
        sys unlink lpath
        sys rmdir dpath
        ()
```

---

## 23.4. Baixo o capó: como está construída `io` en Ridgun puro (`src/main/ridgun/lib/io.ridgun`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/io.ridgun` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 23.4.1. Implementación interna: Extensible I/O Error & Result Sum Types (§5.1)

Fíxate en como `io.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

Fíxate en como `io.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

Fíxate en como `io.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

Fíxate en como `io.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/io.ridgun` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test io.ridgun`.

### As 5 Regras de Ouro ao programar con `io`

1. **Declara `import io` ao inicio do ficheiro** e chama as súas funcións con espazos, tal como están declaradas, para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `io` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `io` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `io` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 24** pasaremos a explorar en profundidade a lib **`crypto`** (A lib `crypto` — Hashes, HMAC, HKDF, PBKDF2, Cifrados AEAD, X25519, Ed25519, ECDSA, RSA e X.509).
