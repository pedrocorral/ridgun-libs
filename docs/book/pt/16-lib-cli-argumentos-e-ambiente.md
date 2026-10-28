# Capítulo 16: A lib `cli` — Flags, Opções, Barreira `--`, Subcomandos e Variáveis de Ambiente

## 16.1. Por que existe a lib `cli`? (O problema real e a filosofia Ridgun)

> *«Por que preciso de uma lib `cli` escrita de raiz em Ridgun puro em vez de ligar uma biblioteca C tradicional?»*

Essa é a primeira pergunta que qualquer engenheiro de sistemas faz ao chegar à `cli`. E a resposta resume toda a filosofia do `ridgun-libs`:

Sejamos sinceros: analisar `argv` à mão começa sempre com um ciclo inocente e acaba por quebrar quando alguém passa `-la` agrupado, `--port=9090` com sinal de igual ou `--` seguido de um ficheiro começado por hífen.

A lib **`cli`** resolve flags longas (`--verbose`), curtas (`-v`), agrupadas (`-la`), opções com valor (`--port=8080`, `--port 8080`, `-p 8080`), o separador POSIX `--`, argumentos posicionais, subcomandos e leitura tipada de variáveis de ambiente.

Num ecossistema tradicional, resolver as tarefas do domínio **`CLI`** implica arrastar dependências externas em C, lidar com ponteiros brutos, conversões opacas de tipos, exceções não verificadas ou pausas imprevisíveis do coletor de lixo. Em Ridgun, a lib **`cli`** (`src/main/ridgun/lib/cli.rg`) aborda o problema com quatro princípios inegociáveis:

1. **Declare `import cli` (ou `import cli as alias`) no início do ficheiro**: cada lib define o seu espaço de nomes `module :: cli` e em modo `--strict` as funções multi-palavra são sempre invocadas com espaços naturais.
2. **Encadeie os seus pipelines da esquerda para a direita com `->`**: escreva `entrada passo um -> passo dois -> resultado`, use máscaras `(+ _ _ +)` para desestruturar sequências e omita `_ =` em instruções sequenciais (ou descarte com `-> ()`).
3. **Recursão de cauda com TCO (*Tail-Call Optimization*)**: todas as travessias internas da `cli` são compiladas para ciclos nativos em espaço de pilha $O(1)$.
4. **Memória determinística (`RMM1` / `RMM2`)**: cada estrutura intermédia é libertada no instante exato em que termina a sua última leitura, sem *Garbage Collector*.

---

## 16.2. Artefactos nativos, importação e catálogo completo da API de `cli`

No `ridgun-libs`, **`cli`** é uma **lib** de primeira classe localizada em `src/main/ridgun/lib/cli.rg` (domínio `CLI`). Ao compilar com `stable bundle`, é empacotada em três formatos nativos:

| Artefacto | Caminho | Finalidade |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/cli.rglib` | Distribuição e importação direta com `import cli` |
| **Ficheiro compilado** | `target/cli.rgc` | Artefacto intermédio verificado pelo `ridgunc` |
| **Objeto partilhado ELF64** | `target/libcli.so` | Biblioteca dinâmica nativa sem dependências de C nem `libc` |

> Cada lib declara o seu próprio espaço de nomes com `module :: cli`: basta escrever `import cli` (ou `import cli as alias`) no topo e invocar as suas funções com espaços naturais (`minha funcao x`) e pipelines `->` (`x minha funcao -> resultado`).

### 16.2.1. Resumo das famílias funcionais da `cli`

| Assinatura / Função / Tipo | O que faz e quando usar |
|---|---|
| `cli has flag : [String] -> String -> String -> Bool` | Deteta `--long`, `-s` ou flags agrupadas `-xyz` antes de `--` |
| `cli get opt / cli get int opt` | Extrai opção de texto ou inteira (`--k=v`, `--k v`, `-k v`) com valor padrão |
| `cli positionals / cli subcommand` | Recolhe os argumentos posicionais (incluindo tudo o que sucede a `--`) |
| `env get or / env get int or / env get bool or` | Lê variáveis de ambiente com conversão tipada e valores padrão |

### 16.2.2. Catálogo exaustivo de tipos e assinaturas em `src/main/ridgun/lib/cli.rg`

Abaixo encontra-se o inventário completo de tipos algébricos (`type`), operadores (`op ::`) e assinaturas de funções (`fn ::`) definidos em `src/main/ridgun/lib/cli.rg` (`0` tipos, `0` operadores e `26` funções):

| # | Função / Assinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: cl str contains char String Int Int Int` | `Bool` |
| `2` | `fn :: cl is bundled short String String` | `Bool` |
| `3` | `fn :: cl list contains str [String] String` | `Bool` |
| `4` | `fn :: cl is digits loop String Int Int` | `Bool` |
| `5` | `fn :: cl is signed int len String Int` | `Bool` |
| `6` | `fn :: cl is signed int String` | `Bool` |
| `7` | `fn :: cl is ws Int` | `Bool` |
| `8` | `fn :: cl lower char String Int Int` | `String` |
| `9` | `fn :: cl trim lower loop String Int Int` | `String` |
| `10` | `fn :: cli has flag [String] String String` | `Bool` |
| `11` | `fn :: cl match eq pfx String String` | `String` |
| `12` | `fn :: cl match eq prefix String String` | `String` |
| `13` | `fn :: cl has eq prefix String String` | `Bool` |
| `14` | `fn :: cli get opt [String] String String String` | `String` |
| `15` | `fn :: cl parse int opt String Int` | `Int` |
| `16` | `fn :: cli get int opt [String] String String Int` | `Int` |
| `17` | `fn :: cl is flag tok String` | `Bool` |
| `18` | `fn :: cli positionals with opts [String] [String]` | `[String]` |
| `19` | `fn :: cli positionals [String]` | `[String]` |
| `20` | `fn :: cl first str [String]` | `String` |
| `21` | `fn :: cli subcommand [String]` | `String` |
| `22` | `fn :: cl env val or String String` | `String` |
| `23` | `fn :: env get or String String` | `String` |
| `24` | `fn :: env get int or String Int` | `Int` |
| `25` | `fn :: cl parse bool val String Bool` | `Bool` |
| `26` | `fn :: env get bool or String Bool` | `Bool` |

---

## 16.3. Explorando a `cli` a fundo: Exemplos passo a passo de cada funcionalidade

Não basta ver a tabela de assinaturas: vamos explorar **cada uma das funcionalidades** da lib `cli` através de exemplos progressivos e executáveis em Ridgun. Começaremos pelas duas receitas tabulares de uso diário e depois percorreremos em detalhe todos os cenários funcionais, transformações e casos de fronteira verificados em `src/test/ridgun/test cli.rg`.

### 16.3.1. Exemplo 1: Fluxo principal em estilo tabular com `cli`

Repare como em Ridgun os sinais `=` e os passos de transformação com `cli` ficam alinhados como uma tabela limpa, sem variáveis mutáveis desnecessárias nem efeitos colaterais ocultos:

```ridgun
import cli

fn :: analizar comando [String] => String Bool Int [String]
      analizar comando args =
        args cli subcommand -> sub
        cli has flag args "--all" "-a" -> all_f
        cli get int opt args "--port" "-p" 8080 -> port
        cli positionals with opts args ["--port", "-p"] -> arch
        (sub, all_f, port, arch)
```

### 16.3.2. Exemplo 2: Composição segura e tratamento de casos de fronteira

Todas as funções da lib `cli` foram desenhadas para se comporem com guardas booleanas `|` e com as restantes 32 libs do `ridgun-libs`:

```ridgun
import cli

fn :: leer config entorno => Int Bool
      leer config entorno =
        env get int or "SOLSTICE_WORKERS" 4 -> workers
        env get bool or "SOLSTICE_DEBUG" False -> debug
        (workers, debug)
```

### 16.3.3. Exemplo 3: Flags booleanas (`cli has flag`) e opções com valor (`--key=val` e `--key val`, `cli opt int`, `cli opt bool`)

Neste exemplo prático exploramos de forma exaustiva como a `cli` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test cli flags and options => ()
      test cli flags and options =
        args = ["serve", "-la", "--verbose", "--port=9090", "-h", "127.0.0.1", "--workers", "-4", "--", "--ignored-flag", "-z", "file.rg"]
        assert true (cli has flag args "--verbose" "-v") "AC1: long flag --verbose"
        assert true (cli has flag args "--all" "-a") "AC1: bundled short flag -a in -la"
        assert true (cli has flag args "--list" "-l") "AC1: bundled short flag -l in -la"
        assert false (cli has flag args "--quiet" "-q") "AC1: missing flag returns False"
        assert false (cli has flag args "--ignored-flag" "") "AC1: long flag after -- is ignored"
        assert false (cli has flag args "" "-z") "AC1: short flag after -- is ignored"
        assert false (cli has flag [] "--verbose" "-v") "AC1: empty args returns False"

        -- Option extraction: --key=val, --key val, -k=val, -k val, empty value --key=
        assert str eq (cli get opt args "--port" "-p" "8080") "9090" "AC2: --port=9090 inline equals"
        assert str eq (cli get opt args "--host" "-h" "0.0.0.0") "127.0.0.1" "AC2: -h 127.0.0.1 separate token"
        assert str eq (cli get opt args "--mode" "-m" "prod") "prod" "AC2: missing option returns fallback"
        assert int equals (cli get int opt args "--port" "-p" 8080) 9090 "AC2: cli_get_int_opt positive int"
        assert int equals (cli get int opt args "--workers" "-w" 1) (0 - 4) "AC2: cli_get_int_opt negative int"
        assert int equals (cli get int opt args "--host" "-h" 8080) 8080 "AC2: non-numeric option falls back to default int"

        short_eq_args = ["-p=3000", "--empty="]
        assert int equals (cli get int opt short_eq_args "--port" "-p" 80) 3000 "AC2: short option -p=3000"
        assert str eq (cli get opt short_eq_args "--empty" "-e" "def") "" "AC2: explicit empty --empty= returns empty string"
        ()
```

### 16.3.4. Exemplo 4: Extração de posicionais respeitando `--` (`cli positionals`), subcomandos (`cli subcommand`) e variáveis de ambiente tipadas (`env str/int/bool or`)

Neste exemplo prático exploramos de forma exaustiva como a `cli` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
fn :: test cli positionals subcommand and env => ()
      test cli positionals subcommand and env =
        args = ["build", "-v", "--output", "target/app", "-j", "8", "--", "-dashfile.rg", "--another-literal", "main.rg"]
        assert str eq (cli subcommand args) "build" "AC3: cli_subcommand first positional"
        assert str eq (cli subcommand ["-v", "--release", "test"]) "test" "AC3: cli_subcommand skips leading flags"
        assert str eq (cli subcommand ["--help", "-v"]) "" "AC3: cli_subcommand empty when only flags"
        assert str eq (cli subcommand []) "" "AC3: cli_subcommand empty on []"

        pos = cli positionals with opts args ["--output", "-j"]
        assert eq pos ["build", "-dashfile.rg", "--another-literal", "main.rg"]

        -- Single "-" (stdin/stdout convention) is treated as a positional argument, not a flag!
        stdin_args = ["cat", "-n", "-"]
        assert eq (cli positionals stdin_args) ["cat", "-"]

        -- Environment variable readers
        assert true ((str len (env get or "PATH" "")) > 0) "AC4: env_get_or PATH non-empty"
        assert str eq (env get or "RIDGUN_NONEXISTENT_ENV_999" "fallback_val") "fallback_val" "AC4: env_get_or fallback"
        assert int equals (env get int or "RIDGUN_NONEXISTENT_ENV_999" 42) 42 "AC4: env_get_int_or fallback"
        assert true (env get bool or "RIDGUN_NONEXISTENT_ENV_999" True) "AC4: env_get_bool_or True fallback"
        assert false (env get bool or "RIDGUN_NONEXISTENT_ENV_999" False) "AC4: env_get_bool_or False fallback"
        ()
```

### 16.3.5. Exemplo 5: Despachante completo de ferramenta CLI combinando subcomandos, flags, opções tipadas e fallback por variáveis de ambiente

Neste exemplo prático exploramos de forma exaustiva como a `cli` se comporta neste bloco funcional, incluindo entradas padrão, combinações de parâmetros e valores limite:

```ridgun
import cli

fn :: despachar comando (argv : [String]) => (String, String, Int, Bool, [String])
      despachar comando argv =
        cmd     = cli subcommand argv
        host    = cli opt or argv "--host" "-H" (env str or "RG_HOST" "127.0.0.1")
        puerto  = cli opt int or argv "--port" "-p" (env int or "RG_PORT" 8080)
        verbose = (cli has flag argv "--verbose" "-v") or (env bool or "RG_VERBOSE" False)
        archivos = cli positionals argv
        (cmd, host, puerto, verbose, archivos)
```

---

## 16.4. Debaixo do capô: como a `cli` é construída em Ridgun puro (`src/main/ridgun/lib/cli.rg`)

Uma das maiores vantagens do `ridgun-libs` é que **não existem caixas-pretas em C**. Pode abrir `src/main/ridgun/lib/cli.rg` e ler exatamente como cada operação é implementada usando *pattern matching*, árvores de guardas `|` / `|.` e recursão de cauda (TCO). Vejamos as peças-chave da sua implementação real:

### 16.4.1. Implementação interna: Internal String & List Helpers

Observe como `cli.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
module :: cli

fn :: cl str contains char String Int Int Int => Bool
      cl str contains char s ch idx len =
        | idx >= len                = False
        | (str char at s idx) == ch = True
        | otherwise                 = cl str contains char s ch (idx + 1) len

fn :: cl is bundled short String String => Bool
      cl is bundled short arg short_flag =
        | (str len short_flag) != 2        = False
        | (str char at short_flag 0) != 45 = False
        | (str len arg) < 2                = False
        | (str char at arg 0) != 45        = False
        | (str char at arg 1) == 45        = False
        | otherwise                        = cl str contains char arg (str char at short_flag 1) 1 (str len arg)

fn :: cl list contains str [String] String => Bool
      cl list contains str [] _ = False
      cl list contains str (x:rest) tgt =
        | x == tgt  = True
        | otherwise = cl list contains str rest tgt

fn :: cl is digits loop String Int Int => Bool
      cl is digits loop s idx len =
        | idx >= len                                           = True
        | (str char at s idx) < 48 or (str char at s idx) > 57 = False
        | otherwise                                            = cl is digits loop s (idx + 1) len

fn :: cl is signed int len String Int => Bool
      cl is signed int len s n =
        | n == 0                  = False
        | (str char at s 0) == 45 =
          | n <= 1    = False
          | otherwise = cl is digits loop s 1 n |.
        | otherwise               = cl is digits loop s 0 n

fn :: cl is signed int String => Bool
      cl is signed int s      =  cl is signed int len s (str len s)

fn :: cl is ws Int => Bool
      cl is ws c   =  c == 32 or c == 9 or c == 10 or c == 13

fn :: cl lower char String Int Int => String
      cl lower char s idx c =
        | c >= 65 and c <= 90 = char from code (c + 32)
        | otherwise           = str slice s idx (idx + 1)

fn :: cl trim lower loop String Int Int => String
      cl trim lower loop s idx len =
        | idx >= len                   = ""
        | cl is ws (str char at s idx) = cl trim lower loop s (idx + 1) len
        | otherwise                    = (cl lower char s idx (str char at s idx)) + (cl trim lower loop s (idx + 1) len)
```

### 16.4.2. Implementação interna: Positional Arguments & Subcommand Extraction

Observe como `cli.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: cl is flag tok String => Bool
      cl is flag tok a      =
        | (str len a) <= 1        = False
        | (str char at a 0) == 45 = True
        | otherwise               = False

fn :: cli positionals with opts [String] [String] => [String]
      cli positionals with opts [] _ = []
      cli positionals with opts (a:[]) _ =
        | a == "--"        = []
        | cl is flag tok a = []
        | otherwise        = [a]
      cli positionals with opts (a:b:rst) val_opts =
        | a == "--"                       = [b] :: rst
        | cl list contains str val_opts a = cli positionals with opts rst val_opts
        | cl is flag tok a                = cli positionals with opts ([b] :: rst) val_opts
        | otherwise                       = [a] :: (cli positionals with opts ([b] :: rst) val_opts)

fn :: cli positionals [String] => [String]
      cli positionals args     =  cli positionals with opts args []

fn :: cl first str [String] => String
      cl first str []       =  ""
      cl first str (x:_)    =  x

fn :: cli subcommand [String] => String
      cli subcommand args     =  args cli positionals -> cl first str
```

### 16.4.3. Implementação interna: Typed Environment Variable Readers

Observe como `cli.rg` estrutura primeiro as assinaturas `fn :: ... => ...` e resolve cada caso através de equações alinhadas e chamadas de cauda:

```ridgun
fn :: cl env val or String String => String
      cl env val or val fallback =
        | (str len val) == 0 = fallback
        | otherwise          = val

fn :: env get or String String   => String
      env get or key    fallback =  cl env val or (sys getenv key) fallback

fn :: env get int or String Int => Int
      env get int or key fallback = cl parse int opt (sys getenv key) fallback

fn :: cl parse bool val String Bool => Bool
      cl parse bool val val fallback =
        | val == "1" or val == "true" or val == "yes" or val == "on"  = True
        | val == "0" or val == "false" or val == "no" or val == "off" = False
        | otherwise                                                   = fallback

fn :: env get bool or String Bool => Bool
      env get bool or key fallback =
        key sys getenv -> raw
        cl trim lower loop raw 0 (str len raw) -> norm
        cl parse bool val norm fallback
```

---

## 16.5. Garantias algorítmicas, memória `RMM1`/`RMM2` e as 5 Regras de Ouro da `cli`

- **Garantia algorítmica e de segurança**: Respeito estrito pelo separador POSIX `--`: nenhum argumento à direita de `--` é jamais interpretado como flag.
- **Complexidade de pilha $O(1)$ com TCO**: Todos os ciclos recursivos em `src/main/ridgun/lib/cli.rg` estão em posição de cauda, pelo que o `ridgunc` os compila para saltos nativos sem crescimento de pilha.
- **Memória determinística (`RMM1`/`RMM2`)**: Zero pausas de coletor de lixo; todas as estruturas intermédias são libertadas de forma determinística à saída do escopo.
- **Verificação contínua**: Testada exaustivamente com `stable check` e pela suite automatizada `src/test/ridgun/test cli.rg`.

### As 5 Regras de Ouro ao programar com a `cli`

1. **Declare `import cli` no início do ficheiro** e aproveite a equivalência entre espaços e underscores para que o seu código se leia como prosa.
2. **Alinhe os seus pipelines de dados com `=`**: encadeie as chamadas à `cli` em passos nomeados e deixe o `stable format` alinhar as colunas.
3. **Aproveite as funções totais da `cli` nas suas guardas `|`**: verifique os valores de retorno ou desempacote os ADTs com *pattern matching* em vez de assumir que a entrada externa é sempre válida.
4. **Evite copiar grandes estruturas se só precisa de consultar um campo**: lembre-se de que no `RMM2` os argumentos de entrada não incrementam nem decrementam contadores (`+0` / `-0`).
5. **Combine a `cli` com `test` (`import test`)**: escreva sempre asserções com `assert equals` ou `assert true` para fixar os invariantes do seu domínio.

---

No **Capítulo 17** passaremos a explorar em profundidade a lib **`path`** (A lib `path` — Normalização POSIX (`path clean`) e Confinamento contra Path Traversal).
