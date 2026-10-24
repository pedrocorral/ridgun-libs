# Capítulo 23: A lib `io` — Erros Tipados `IoResult`, E/S com `with timeout` e Processos

## 23.1. Por que existe a lib `io`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `io` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `io`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: uma chamada `read()` ou um subprocesso filho sem prazo limite (`timeout`) é um convite para que um único recurso pendurado esgote todos os trabalhadores do seu servidor.

A lib **`io`** modela cada operação do sistema com ADTs explícitos (`IoError`, `IoResult[A]`), combina `ppoll` não bloqueante com quotas léxicas `with timeout wait_ms do` do Ridgun e oferece os operadores mixfix `read fd ... timeout` e `write fd ... timeout`.

Num ecossistema tradicional, resolver as tarefas do domínio **`IO`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`io`** (`src/main/ridgun/lib/io.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Funções totais e contratos explícitos (`=>`)**: nenhuma função da `io` lança exceções ocultas nem depende de `null`. Qualquer caso limite devolve um valor sentinela documentado ou um tipo algébrico soma (`Option`, `Result`).
2. **Zero código C e zero `libc`**: todo o código da `io` compila diretamente para código máquina nativo ELF64 verificado pelo `ridgunc`.
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `io` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 23.2. Artefactos nativos, importação e catálogo completo da API de `io`

No `ridgun-libs`, **`io`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/io.rg` (domínio `IO`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/io.rglib` | Distribuição e importação direta com `import io` |
| **Ficheiro compilado** | `target/io.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libio.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import io` no topo e invocar as suas funções com espaços ou underscores.

### 23.2.1. Resumo das famílias funcionais da `io`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `type IoError / type IoResult[A]` | `IoNotFound | IoPermission | IoTimeout | IoRefused | IoReset | IoEOF | IoInvalid | IoSysError` |
| `io read with timeout / io write with timeout` | Leitura/escrita não bloqueante de descritor limitada por `wait_ms` |
| `read fd N max M timeout T / write fd N data S timeout T` | Operadores mixfix ergonómicos (`op ::`) para E/S de descritor com prazo limite |
| `io read file / io write file / io read lines` | Funções seguras de ficheiros e fluxos de linhas que devolvem `IoResult` |
| `exec with timeout : String -> Int -> IoResult[ProcStatus]` | Executa um comando externo limitado por uma quota léxica `with timeout` |

### 23.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/io.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/io.rg` (`2` tipos, `2` operadores e `37` funções):

**Tipos algébricos e registos (`type`) da `io`:**

```ridgun
type IoError = Timeout Int | Eof | SysErr Int String | NotFound String
type IoResult = String | Int | Timeout Int | Eof | SysErr Int String | NotFound String | IoErr IoError | IoOk String | IoTimeout | IoEof | IoError Int
```

**Operadores mixfix (`op ::`) da `io`:**

```ridgun
op :: read fd Int max Int timeout Int => IoResult
op :: write fd Int data String timeout Int => IoResult
```

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
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

## 23.3. Explorando a `io` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `io` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test io.rg`.

### 23.3.1. Exemplo 1: Fluxo principal em estilo tabular com `io`

Repare como em Ridgun os sinais `=` e os passos de transformação com `io` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import io

fn :: leer peticion segura (fd : Int) => String
      leer peticion segura fd =
        res = read fd fd max 4096 timeout 250
        io unwrap or res ""
```

### 23.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `io` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import io

fn :: describir fallo () => String
      describir fallo =
        format io error (IoTimeout "read" 250)
```

### 23.3.3. Exemplo 3: Hierarquia extensível de erros `IoError` (`Timeout`, `Eof`, `InvalidInput`, `PermissionDenied`, `NotFound`, `PosixErrno`) e formatação `io error message`

Neste exemplo prático exploramos de forma exaustiva como a `io` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test io error formatting => ()
      test io error formatting =
        _ = assert str eq (format io error (Timeout 500)) "timeout after 500 ms" "format Timeout 500"
        _ = assert str eq (format io error Eof) "unexpected end of file" "format Eof"
        _ = assert str eq (format io error (SysErr 9 "poll")) "syscall error 9 in poll" "format SysErr"
        _ = assert str eq (format io error (NotFound "/missing")) "file not found: /missing" "format NotFound"
        ()
```

### 23.3.4. Exemplo 4: Leitura e escrita em descritores limitadas por prazo (`read fd ... timeout`, `write fd ... timeout`, `with timeout`) e deteção de `Eof`

Neste exemplo prático exploramos de forma exaustiva como a `io` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test io pipe timeout and eof => ()
      test io pipe timeout and eof =
        pt     = posix pipe
        rc     = pipe rc3 pt
        rfd    = pipe rfd3 pt
        wfd    = pipe wfd3 pt
        _      = assert eq rc 0

        -- 1. Empty pipe read with 50 ms timeout must time out within [40, 300) ms (TS-PERF-001 AC2)
        t3     = sys monotonic ms
        r_to   = read fd rfd max 32 timeout 50
        t4     = sys monotonic ms
        dt     = t4 - t3
        _      = assert str eq (format io result r_to) "err:timeout after 50 ms" "empty pipe read Timeout 50"
        _      = assert true (dt >= 40 and dt < 300) "dt in [40, 300): {dt}"

        -- 2. Write payload via mixfix `write fd ... data ... timeout ...`
        w_res  = write fd wfd data "stream-ok" timeout 100
        _      = assert str eq (format io result w_res) "ok:int:9" "write fd returns 9 bytes"

        -- 3. Read payload via mixfix `read fd ... max ... timeout ...`
        r_ok   = read fd rfd max 64 timeout 100
        _      = assert str eq (format io result r_ok) "ok:str:stream-ok" "read fd returns stream-ok"

        -- 4. Close write end and verify subsequent read returns Eof
        _      = posix close wfd
        r_eof  = read fd rfd max 64 timeout 100
        _      = assert str eq (format io result r_eof) "err:unexpected end of file" "closed pipe read returns Eof"
        _      = posix close rfd

        -- 5. Bad fd / invalid max_bytes
        r_bad  = read fd (0 - 1) max 64 timeout 50
        _      = assert str eq (format io result r_bad) "err:syscall error 9 in read" "negative fd read SysErr 9"
        r_zero = read fd rfd max 0 timeout 50
        _      = assert str eq (format io result r_zero) "err:syscall error 22 in read" "zero max_bytes read SysErr 22"
        ()
```

### 23.3.5. Exemplo 5: Execução segura de subprocessos com limite estrito de tempo (`io exec timeout`) e limpeza automática do processo filho

Neste exemplo prático exploramos de forma exaustiva como a `io` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test io exec timeout => ()
      test io exec timeout =
        ok_res = io exec timeout "true" 500
        _      = assert str eq (format io result ok_res) "ok:int:0" "io exec timeout true succeeds"
        to_res = io exec timeout "sleep 2" 40
        _      = assert str eq (format io result to_res) "err:timeout after 40 ms" "io exec timeout sleep 2 times out"
        ()
```

### 23.3.6. Exemplo 6: Predicados de sistema de ficheiros (`file exists`, `is dir`, `is regular file`, `file size`), leitura por linhas (`io read lines`) e cópia (`copy file`)

Neste exemplo prático exploramos de forma exaustiva como a `io` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test io file and metadata => ()
      test io file and metadata =
        pid   = sys getpid
        dpath = "/tmp/rg_io_dir_{pid}"
        fpath = "{dpath}/file.txt"
        spath = "{dpath}/sym.txt"
        bpath = "{dpath}/bytes.bin"
        lpath = "{dpath}/lines.txt"

        _     = sys rmdir dpath
        _     = posix mkdir dpath
        _     = assert true (is dir dpath) "is dir dpath"
        _     = assert false (is file dpath) "not is file dpath"

        -- 1. write_file + append_file + read_file
        _     = write file fpath "hello "
        w2    = append file fpath "world"
        _     = assert eq w2 0
        _     = assert str eq (read file fpath) "hello world" "write_file + append_file content"

        -- 2. write_bytes + read_bytes
        _     = write bytes bpath [65, 66, 67, 0, 255]
        rb    = read bytes bpath
        _     = assert eq (int list len rb) 5

        -- 3. symlink + metadata predicates
        _     = assert true (sys symlink fpath spath) "sys symlink fpath spath"
        _     = assert true (file exists fpath) "file exists fpath"
        _     = assert true (is file fpath) "is file fpath"
        _     = assert false (is symlink fpath) "not is symlink fpath"
        _     = assert true (is symlink spath) "is symlink spath"
        _     = assert eq (file size fpath) 11
        _     = assert true ((file mtime fpath) > 1700000000) "file mtime > 1700000000"
        _     = assert true ((file mode fpath) > 0) "file mode > 0"
        _     = assert false (file exists "/tmp/rg_io_nonexistent_999999.txt") "missing file exists False"

        -- 4. io read file safe + io write lines / io read lines
        miss  = io read file safe "/tmp/rg_io_missing_999.txt"
        _     = assert str eq (format io result miss) "err:file not found: /tmp/rg_io_missing_999.txt" "NotFound missing file"
        hit   = io read file safe fpath
        _     = assert str eq (format io result hit) "ok:str:hello world" "safe read existing file"

        _     = io write lines lpath ["alpha", "beta", "gamma"]
        lines = io read lines lpath
        _     = assert eq (str list len lines) 3

        -- 5. v0.9.5 PAL `io read with timeout` (`with timeout wait_ms do` + `sys open path 2048 0` + `sys poll fd 1 -1`)
        r_amb  = io read with timeout fpath 200_ms
        _      = assert str eq (format io result r_amb) "ok:str:hello world" "io read with timeout 200_ms"
        r_miss = io read with timeout "/tmp/rg_io_missing_999.txt" 50_ms
        _      = assert true (str starts with (format io result r_miss) "err:io error -") "io read with timeout missing file -> IoError"

        -- Cleanup
        _     = sys unlink spath
        _     = sys unlink fpath
        _     = sys unlink bpath
        _     = sys unlink lpath
        _     = sys rmdir dpath
        ()
```

---

## 23.4. Debaixo do capô: como a `io` é construída em Ridgun puro (`src/main/ridgun/lib/io.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/io.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 23.4.1. Implementação interna: Extensible I/O Error & Result Sum Types (§5.1)

Observe como `io.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
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

### 23.4.2. Implementação interna: Timeout-Bounded Command Execution (§5.2)

Observe como `io.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

### 23.4.3. Implementação interna: Safe File Read & Line-Stream Helpers

Observe como `io.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

fn :: io write lines String [String] => Int
      io write lines path   lines    =
        | not (is safe posix path path) = 0 - 22
        | otherwise                     =
          _ = write file path (join lines nl lines)
          0
```

### 23.4.4. Implementação interna: Ridgun v0.9.5 PAL & Ambient Deadline `io read with timeout` (§3.1)

Observe como `io.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: io wrap chunk String => IoResult
      io wrap chunk ""     =  IoEof
      io wrap chunk s      =  IoOk s

fn :: io read after poll Int Int => IoResult
      io read after poll fd ev =
        | ev == 0 =
          _ = sys close fd
          IoTimeout
        | ev < 0 =
          _ = sys close fd
          IoError ev
        | otherwise =
          chunk = sys read fd fd 65536
          _     = sys close fd
          io wrap chunk chunk

fn :: io read poll step Int => IoResult
      io read poll step fd  =
        | fd < 0    = IoError fd
        | otherwise =
          ev = sys poll fd 1 (0 - 1)
          io read after poll fd ev

fn :: io read with timeout String Int => IoResult
      io read with timeout path wait_ms =
        with timeout wait_ms do
          fd = sys open path 2048 0
          io read poll step fd
```

---

## 23.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `io`

- **Garantia algorítmica e de segurança**: Nenhuma leitura, escrita ou comando executado através de `io` com quota `wait_ms` pode bloquear indefinidamente a thread ou ator chamador.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/io.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test io.rg`.

### As 5 Regras de Ouro ao programar com a `io`

1. **Declare `import io` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `io` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `io` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `io` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 24** passaremos a explorar em profundidade a lib **`crypto`** (A lib `crypto` — SHA-256, HMAC, PBKDF2, Argon2id e ChaCha20-Poly1305 AEAD).
