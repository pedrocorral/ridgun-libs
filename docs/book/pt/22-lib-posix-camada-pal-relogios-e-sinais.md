# Capítulo 22: A lib `posix` — Camada de Abstração de Plataforma (PAL), Relógios, Sinais e CSPRNG

## 22.1. Por que existe a lib `posix`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `posix` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `posix`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: flags como `O_CREAT`, `O_NONBLOCK` ou números de syscall mudam entre Linux, macOS e arquiteturas (`X86_64` vs `Arm64`), e em C tudo se resolve com uma selva ilegível de `#ifdef`.

A lib **`posix`** implementa a **Camada de Abstração de Plataforma (PAL)** de 2 níveis do Ridgun usando guardas tabulares sobre `sys os` (`Linux | MacOS | Windows`) e `sys arch` (`X86_64 | Arm64 | RiscV64`), além de sondagem de descritores (`wait fd`), relógios monotónicos (`RGF-017`), sinais (`RGF-018`) e entropia CSPRNG do kernel (`sys random bytes`).

Num ecossistema tradicional, resolver as tarefas do domínio **`POSIX`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`posix`** (`src/main/ridgun/lib/posix.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Funções totais e contratos explícitos (`=>`)**: nenhuma função da `posix` lança exceções ocultas nem depende de `null`. Qualquer caso limite devolve um valor sentinela documentado ou um tipo algébrico soma (`Option`, `Result`).
2. **Zero código C e zero `libc`**: todo o código da `posix` compila diretamente para código máquina nativo ELF64 verificado pelo `ridgunc`.
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `posix` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 22.2. Artefactos nativos, importação e catálogo completo da API de `posix`

No `ridgun-libs`, **`posix`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/posix.rg` (domínio `POSIX`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/posix.rglib` | Distribuição e importação direta com `import posix` |
| **Ficheiro compilado** | `target/posix.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libposix.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import posix` no topo e invocar as suas funções com espaços ou underscores.

### 22.2.1. Resumo das famílias funcionais da `posix`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `pal open create trunc wr / pal o nonblock` | Tradução de flags do SO conforme `sys os` (`Linux | MacOS | Windows`) |
| `wait fd : Int -> Int -> Int -> PollStatus` | Sonda um descritor devolvendo `PollReady`, `PollTimeout` ou `PollError errno` |
| `clock monotonic ms / clock monotonic ns / clock wall ms` | Relógios monotónicos e relógio de parede UTC em milissegundos (`RGF-017`) |
| `signal watch / signal poll / sys random bytes` | Sondagem não bloqueante de sinais (`SIGINT`, `SIGTERM`) e bytes CSPRNG do kernel |
| `read text / write text / file exists / run cmd` | E/S de ficheiros de alto nível, diretórios e execução de subprocessos |

### 22.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/posix.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/posix.rg` (`2` tipos, `0` operadores e `92` funções):

**Tipos algébricos e registos (`type`) da `posix`:**

```ridgun
type PollStatus = PollReady Int | PollTimeout | PollError Int
type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int
```

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
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

## 22.3. Explorando a `posix` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `posix` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test posix.rg`.

### 22.3.1. Exemplo 1: Fluxo principal em estilo tabular com `posix`

Repare como em Ridgun os sinais `=` e os passos de transformação com `posix` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import posix

fn :: medir operacion () => (Int, Int)
      medir operacion =
        t0  = clock monotonic ms
        rnd = len (sys random bytes 32)
        t1  = clock monotonic ms
        (rnd, t1 - t0)
```

### 22.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `posix` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import posix

fn :: esperar lectura (fd : Int) => Bool
      esperar lectura fd =
        est = wait fd fd poll_in 100
        est == PollReady
```

### 22.3.3. Exemplo 3: Constantes POSIX (`O_*`, `POLL*`, `SIG*`), validação de caminhos seguros, pipes anónimos (`sys pipe`) e sondagem `sys poll status`

Neste exemplo prático exploramos de forma exaustiva como a `posix` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 22.3.4. Exemplo 4: Metadados `lstat`, relógios monotónicos e de parede (`clock_gettime`), sinais por descritor (`signalfd4`) e entropia do kernel (`sys random bytes`)

Neste exemplo prático exploramos de forma exaustiva como a `posix` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

### 22.3.5. Exemplo 5: Comunicação entre processos via pipe (`sys pipe`), sondagem não bloqueante (`sys poll status`) e temporização monotónica (`sys monotonic ns`)

Neste exemplo prático exploramos de forma exaustiva como a `posix` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

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

## 22.4. Debaixo do capô: como a `posix` é construída em Ridgun puro (`src/main/ridgun/lib/posix.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/posix.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 22.4.1. Implementação interna: Poll & Process Status ADTs

Observe como `posix.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
type PollStatus = PollReady Int | PollTimeout | PollError Int

type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int
```

### 22.4.2. Implementação interna: Path Safety Validation (VUL-INJ-002 / VUL-INPUT-001)

Observe como `posix.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

### 22.4.3. Implementação interna: RG-010 Filesystem & Process Operations

Observe como `posix.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

### 22.4.4. Implementação interna: Ridgun v0.9.5 Target OS / Arch & Process Probe Helpers

Observe como `posix.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

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

## 22.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `posix`

- **Garantia algorítmica e de segurança**: Os ramos de `sys os` e `sys arch` que não correspondem ao binário alvo são eliminados em tempo de compilação (Dead-Code Elimination) pelo `ridgunc`.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/posix.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test posix.rg`.

### As 5 Regras de Ouro ao programar com a `posix`

1. **Declare `import posix` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `posix` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `posix` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `posix` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 23** passaremos a explorar em profundidade a lib **`io`** (A lib `io` — Erros Tipados `IoResult`, E/S com `with timeout` e Processos).
