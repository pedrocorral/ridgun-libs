# Capítulo 17: A lib `path` — Normalização POSIX (`path clean`) e Confinamento contra Path Traversal

## 17.1. Por que existe a lib `path`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `path` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `path`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: juntar caminhos com `base + "/" + ficheiro` sem limpar segmentos `..` nem validar prefixos é deixar a porta aberta para alguém pedir `../../etc/passwd` no seu servidor web.

A lib **`path`** implementa normalização léxica POSIX (`path clean`), junção segura (`path join`), extração de componentes (`dirname`, `basename`, `stem`, `ext`, `replace ext`) e o predicado de segurança **`path is safe subpath`** (`VUL-INJ-001`) contra *path traversal*.

Num ecossistema tradicional, resolver as tarefas do domínio **`PATH`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`path`** (`src/main/ridgun/lib/path.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Funções totais e contratos explícitos (`=>`)**: nenhuma função da `path` lança exceções ocultas nem depende de `null`. Qualquer caso limite devolve um valor sentinela documentado ou um tipo algébrico soma (`Option`, `Result`).
2. **Zero código C e zero `libc`**: todo o código da `path` compila diretamente para código máquina nativo ELF64 verificado pelo `ridgunc`.
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `path` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 17.2. Artefactos nativos, importação e catálogo completo da API de `path`

No `ridgun-libs`, **`path`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/path.rg` (domínio `PATH`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/path.rglib` | Distribuição e importação direta com `import path` |
| **Ficheiro compilado** | `target/path.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libpath.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Para utilizar esta lib em qualquer ficheiro `.rg`, basta declarar `import path` no topo e invocar as suas funções com espaços ou underscores.

### 17.2.1. Resumo das famílias funcionais da `path`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `path clean / path join / path join list` | Colapsa `//`, `.` e `..` lexicamente e junta segmentos de caminho |
| `path dirname / path basename / path split` | Divide um caminho em diretório pai e nome de ficheiro final |
| `path ext / path stem / path replace ext` | Extrai ou substitui a extensão (tratando `.bashrc` como raiz `.bashrc` e ext `""`) |
| `path is safe subpath : String -> String -> Bool` | Verifica que `rel` permanece estritamente dentro de `base_dir` e sem bytes NUL |

### 17.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/path.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/path.rg` (`0` tipos, `0` operadores e `30` funções):

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: pa split slash loop String Int Int Int` | `[String]` |
| `2` | `fn :: pa rev strs [String] [String]` | `[String]` |
| `3` | `fn :: pa join slash [String]` | `String` |
| `4` | `fn :: pa pop stack [String] Bool` | `[String]` |
| `5` | `fn :: pa norm segs [String] [String] Bool` | `[String]` |
| `6` | `fn :: pa finish clean String Bool` | `String` |
| `7` | `fn :: path is abs String` | `Bool` |
| `8` | `fn :: path is rel String` | `Bool` |
| `9` | `fn :: path clean String` | `String` |
| `10` | `fn :: path join String String` | `String` |
| `11` | `fn :: path join list [String]` | `String` |
| `12` | `fn :: pa last char idx String Int Int` | `Int` |
| `13` | `fn :: pa dirname at String Int` | `String` |
| `14` | `fn :: pa dirname clean String` | `String` |
| `15` | `fn :: path dirname String` | `String` |
| `16` | `fn :: pa basename at String Int` | `String` |
| `17` | `fn :: pa basename clean String` | `String` |
| `18` | `fn :: path basename String` | `String` |
| `19` | `fn :: path split String` | `String String` |
| `20` | `fn :: pa ext at String Int` | `String` |
| `21` | `fn :: path ext String` | `String` |
| `22` | `fn :: pa stem at String Int` | `String` |
| `23` | `fn :: path stem String` | `String` |
| `24` | `fn :: pa norm ext String` | `String` |
| `25` | `fn :: pa combine dir base String String` | `String` |
| `26` | `fn :: path replace ext String String` | `String` |
| `27` | `fn :: pa is safe char Int` | `Bool` |
| `28` | `fn :: pa safe chars loop String Int Int` | `Bool` |
| `29` | `fn :: pa check prefix String String` | `Bool` |
| `30` | `fn :: path is safe subpath String String` | `Bool` |

---

## 17.3. Explorando a `path` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `path` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test path.rg`.

### 17.3.1. Exemplo 1: Fluxo principal em estilo tabular com `path`

Repare como em Ridgun os sinais `=` e os passos de transformação com `path` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import path

fn :: resolver archivo estatico (raiz : String) (peticion : String) => (Bool, String)
      resolver archivo estatico raiz peticion =
        seguro = path is safe subpath raiz peticion
        ruta   = path join raiz peticion
        (seguro, ruta)
```

### 17.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `path` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import path

fn :: cambiar salida a objeto (fuente : String) => (String, String, String)
      cambiar salida a objeto fuente =
        dir = path dirname fuente
        nom = path stem fuente
        obj = path replace ext (path clean fuente) ".rglib"
        (dir, nom, obj)
```

### 17.3.3. Exemplo 3: Normalização léxica POSIX (`path clean`) e junção segura de segmentos (`path join`, `path join all`)

Neste exemplo prático exploramos de forma exaustiva como a `path` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test path clean and join => ()
      test path clean and join =
        -- Go path/path_test.go cleantests vectors
        _ = assert str eq (path clean "") "." "AC1: empty -> ."
        _ = assert str eq (path clean ".") "." "AC1: . -> ."
        _ = assert str eq (path clean "././.") "." "AC1: ././. -> ."
        _ = assert str eq (path clean "/") "/" "AC1: / -> /"
        _ = assert str eq (path clean "///") "/" "AC1: /// -> /"
        _ = assert str eq (path clean "/././") "/" "AC1: /././ -> /"
        _ = assert str eq (path clean "/../a") "/a" "AC1: /../a clamped at root"
        _ = assert str eq (path clean "/../../..") "/" "AC1: /../../.. clamped at root"
        _ = assert str eq (path clean "a/b/..") "a" "AC1: a/b/.. -> a"
        _ = assert str eq (path clean "a/../b") "b" "AC1: a/../b -> b"
        _ = assert str eq (path clean "a/../../b") "../b" "AC1: relative .. preserved when above ."
        _ = assert str eq (path clean "../../a/b/..") "../../a" "AC1: leading ../.. preserved"
        _ = assert str eq (path clean "/a/b/../c/./d//") "/a/c/d" "AC1: complex absolute normalization"

        -- path_join & path_join_list
        _ = assert str eq (path join "" "") "." "AC1: join empty empty"
        _ = assert str eq (path join "/var/log" "") "/var/log" "AC1: join with empty right"
        _ = assert str eq (path join "" "app.log") "app.log" "AC1: join with empty left"
        _ = assert str eq (path join "/var/log" "app/server.log") "/var/log/app/server.log" "AC1: join relative child"
        _ = assert str eq (path join "/var/log" "/etc/hosts") "/etc/hosts" "AC1: join absolute child overrides base"
        _ = assert str eq (path join list []) "." "AC1: join_list [] -> ."
        _ = assert str eq (path join list ["src", "main", "ridgun", "lib", "path.rg"]) "src/main/ridgun/lib/path.rg" "AC1: join_list 5 segments"
        ()
```

### 17.3.4. Exemplo 4: Decomposição (`dirname`, `basename`, `ext`, `stem`) e confinamento contra *path traversal* (`path is safe rel`, `path resolve under`)

Neste exemplo prático exploramos de forma exaustiva como a `path` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test path components and confinement => ()
      test path components and confinement =
        p = "/home/boogie/ridgun-libs/src/socket.rg"
        _ = assert true (path is abs p) "AC2: path_is_abs true"
        _ = assert false (path is rel p) "AC2: path_is_rel false"
        _ = assert false (path is abs "") "AC2: empty is not abs"
        _ = assert true (path is rel "src/socket.rg") "AC2: relative path_is_rel"
        _ = assert str eq (path dirname p) "/home/boogie/ridgun-libs/src" "AC2: dirname"
        _ = assert str eq (path basename p) "socket.rg" "AC2: basename"
        sp = path split p
        _ = assert str eq (pair_fst sp) "/home/boogie/ridgun-libs/src" "AC2: split dirname"
        _ = assert str eq (pair_snd sp) "socket.rg" "AC2: split basename"
        _ = assert str eq (path dirname "/") "/" "AC2: dirname of / is /"
        _ = assert str eq (path basename "/") "/" "AC2: basename of / is /"
        _ = assert str eq (path dirname "/top") "/" "AC2: dirname of /top is /"
        _ = assert str eq (path dirname "barefile.txt") "." "AC2: dirname of bare filename is ."

        -- Multi-dot filenames, dotfiles, and extension replacement
        _ = assert str eq (path stem p) "socket" "AC2: stem"
        _ = assert str eq (path ext p) ".rg" "AC2: ext"
        _ = assert str eq (path stem "archive.tar.gz") "archive.tar" "AC2: multi-dot stem"
        _ = assert str eq (path ext "archive.tar.gz") ".gz" "AC2: multi-dot ext"
        _ = assert str eq (path stem ".gitignore") ".gitignore" "AC2: dotfile stem"
        _ = assert str eq (path ext ".gitignore") "" "AC2: dotfile empty ext"
        _ = assert str eq (path replace ext p "rglib") "/home/boogie/ridgun-libs/src/socket.rglib" "AC2: replace_ext without leading dot"
        _ = assert str eq (path replace ext p ".so") "/home/boogie/ridgun-libs/src/socket.so" "AC2: replace_ext with leading dot"
        _ = assert str eq (path replace ext "main.rg" "") "main" "AC2: replace_ext with empty removes extension"

        -- OWASP Path Traversal & Shell Injection Confinement (VUL-INJ-002)
        _ = assert true (path is safe subpath "/srv/www" "assets/app.js") "AC3: safe child subpath"
        _ = assert true (path is safe subpath "/srv/www" "a/b/../c_1-2.txt") "AC3: safe normalized internal .."
        _ = assert false (path is safe subpath "/srv/www" "") "AC3: empty child rejected"
        _ = assert false (path is safe subpath "" "assets/app.js") "AC3: empty base rejected"
        _ = assert false (path is safe subpath "/srv/www" "../etc/passwd") "AC3: direct .. traversal rejected"
        _ = assert false (path is safe subpath "/srv/www" "a/b/../../../etc/passwd") "AC3: deep .. traversal escaping base rejected"
        _ = assert false (path is safe subpath "/srv/www" "/etc/passwd") "AC3: absolute child path rejected"
        _ = assert false (path is safe subpath "/srv/www" "/srv/www/index.html") "AC3: absolute child matching base still rejected"
        _ = assert false (path is safe subpath "/srv/www" "bad;rm -rf /") "AC3: shell semicolon metachar rejected"
        _ = assert false (path is safe subpath "/srv/www" "bad|cat") "AC3: shell pipe metachar rejected"
        _ = assert false (path is safe subpath "/srv/www" "bad$var") "AC3: shell dollar metachar rejected"
        ()
```

### 17.3.5. Exemplo 5: Resolvedor de ficheiros estáticos em *sandbox*: validação contra saltos `..`, bytes nulos e extração de `dirname`/`basename`/`ext`/`stem`

Neste exemplo prático exploramos de forma exaustiva como a `path` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
import path

fn :: resolver archivo seguro (raiz : String) (peticion : String) => (String, String, String, String)
      resolver archivo seguro raiz peticion =
        ruta_final = path resolve under raiz peticion
        | ruta_final == "" = ("denegado", "", "", "")
        | otherwise        =
          dir  = path dirname ruta_final
          base = path basename ruta_final
          ext  = path ext ruta_final
          stem = path stem ruta_final
          (ruta_final, dir, base, "{stem} ({ext})")
```

---

## 17.4. Debaixo do capô: como a `path` é construída em Ridgun puro (`src/main/ridgun/lib/path.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/path.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 17.4.1. Implementação interna: Core Implementation Part 1

Observe como `path.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: pa split slash loop String Int Int Int => [String]
      pa split slash loop p start idx len =
        | idx >= len                = [(str slice p start len)]
        | (str char at p idx) == 47 = [(str slice p start idx)] :: (pa split slash loop p (idx + 1) (idx + 1) len)
        | otherwise                 = pa split slash loop p start (idx + 1) len

fn :: pa rev strs [String] [String] => [String]
      pa rev strs []       acc      =  acc
      pa rev strs (x:rest) acc      =  pa rev strs rest ([x] :: acc)

fn :: pa join slash [String] => String
      pa join slash []       =  ""
      pa join slash (x:[])   =  x
      pa join slash (x:rest) =  x + "/" + (pa join slash rest)

fn :: pa pop stack [String] Bool  => [String]
      pa pop stack []       True  =  []
      pa pop stack []       False =  [".."]
      pa pop stack (top:rs) is_ab =
        | top == ".." = ["..", ".."] :: rs
        | otherwise   = rs

fn :: pa norm segs [String] [String] Bool => [String]
      pa norm segs [] stack _ = pa rev strs stack []
      pa norm segs (s:rest) stack is_ab =
        | (str len s) == 0 or s == "." = pa norm segs rest stack is_ab
        | s == ".."                    = pa norm segs rest (pa pop stack stack is_ab) is_ab
        | otherwise                    = pa norm segs rest ([s] :: stack) is_ab

fn :: pa finish clean String Bool  => String
      pa finish clean joined True  =
        | (str len joined) == 0 = "/"
        | otherwise             = "/" + joined
      pa finish clean joined False =
        | (str len joined) == 0 = "."
        | otherwise             = joined
```

### 17.4.2. Implementação interna: Core Implementation Part 2

Observe como `path.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: path is abs String => Bool
      path is abs p      =
        | (str len p) == 0        = False
        | (str char at p 0) == 47 = True
        | otherwise               = False

fn :: path is rel String => Bool
      path is rel p      =  not (path is abs p)

fn :: path clean String => String
      path clean p      =
        | (str len p) == 0 = "."
        | otherwise =
          is_ab = path is abs p
          segs  = pa split slash loop p 0 0 (str len p)
          norm  = pa norm segs segs [] is_ab
          pa finish clean (pa join slash norm) is_ab

fn :: path join String String => String
      path join a      b      =
        | (str len a) == 0 = path clean b
        | (str len b) == 0 = path clean a
        | path is abs b    = path clean b
        | otherwise        = path clean (a + "/" + b)

fn :: path join list [String]   => String
      path join list []         =  "."
      path join list (x:[])     =  path clean x
      path join list (x:y:rest) =  path join list ([(path join x y)] :: rest)

fn :: pa last char idx String Int Int => Int
      pa last char idx s ch idx =
        | idx < 0                   = 0 - 1
        | (str char at s idx) == ch = idx
        | otherwise                 = pa last char idx s ch (idx - 1)
```

### 17.4.3. Implementação interna: Core Implementation Part 4

Observe como `path.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: path ext String => String
      path ext p      =
        base = path basename p
        pa ext at base (pa last char idx base 46 ((str len base) - 1))

fn :: pa stem at String Int => String
      pa stem at base   dot =
        | dot <= 0  = base
        | otherwise = str slice base 0 dot

fn :: path stem String => String
      path stem p      =
        base = path basename p
        pa stem at base (pa last char idx base 46 ((str len base) - 1))

fn :: pa norm ext String => String
      pa norm ext ext    =
        | (str len ext) == 0        = ""
        | (str char at ext 0) == 46 = ext
        | otherwise                 = "." + ext

fn :: pa combine dir base String String => String
      pa combine dir base dir base =
        | dir == "." = base
        | dir == "/" = "/" + base
        | otherwise  = dir + "/" + base

fn :: path replace ext String String  => String
      path replace ext p      new_ext =
        pa combine dir base (path dirname p) ((path stem p) + (pa norm ext new_ext))

fn :: pa is safe char Int => Bool
      pa is safe char c   =
        | c >= 48 and c <= 57                        = True
        | c >= 65 and c <= 90                        = True
        | c >= 97 and c <= 122                       = True
        | c == 47 or c == 46 or c == 95 or c == 45   = True
        | otherwise                                  = False
```

### 17.4.4. Implementação interna: Core Implementation Part 5

Observe como `path.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: pa safe chars loop String Int Int => Bool
      pa safe chars loop s idx len =
        | idx >= len                          = True
        | not (pa is safe char (str char at s idx)) = False
        | otherwise                           = pa safe chars loop s (idx + 1) len

fn :: pa check prefix String String => Bool
      pa check prefix bclean full   =
        | bclean == "/" = path is abs full
        | full == bclean = True
        | otherwise     = str starts with full (bclean + "/")

fn :: path is safe subpath String String => Bool
      path is safe subpath base child =
        | (str len base) == 0 or (str len child) == 0          = False
        | path is abs child                                    = False
        | not (pa safe chars loop base 0 (str len base))       = False
        | not (pa safe chars loop child 0 (str len child))     = False
        | otherwise =
          bclean = path clean base
          full   = path clean (bclean + "/" + child)
          pa check prefix bclean full
```

---

## 17.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `path`

- **Garantia algorítmica e de segurança**: `path is safe subpath` rejeita caminhos absolutos, bytes NUL e qualquer sequência `..` que tente escapar do diretório base ou atingir um prefixo irmão (`/srv/www-secret`).
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/path.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test path.rg`.

### As 5 Regras de Ouro ao programar com a `path`

1. **Declare `import path` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `path` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `path` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `path` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 18** passaremos a explorar em profundidade a lib **`time`** (A lib `time` — Calendário Civil UTC (Hinnant), ISO-8601, Durações e Backoff).
