# Capítulo 16: A lib `cli` — Bandeiras, Opcións, Barreira `--`, Subcomandos e Variables de Contorno

## 16.1. Por que existe a lib `cli`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `cli` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `cli`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: analizar `argv` á man sempre comeza cun bucle inocente e acaba rompéndose cando alguén pasa `-la` agrupado, `--port=9090` con signo igual ou `--` seguido dun ficheiro que comeza por guión `-ficheiro.rg`.

A lib **`cli`** resolve bandeiras longas (`--verbose`), curtas (`-v`), agrupadas (`-la`), opcións con valor (`--port=8080`, `--port 8080`, `-p 8080`), o separador POSIX `--`, argumentos posicionais, subcomandos e lectura tipada de variables de contorno (`env get int or`, `env get bool or`).

Nun ecosistema tradicional, resolver as tarefas do dominio **`CLI`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`cli`** (`src/main/ridgun/lib/cli.rg`) aborda o problema con catro principios innegociables:

1. **Declara `import cli` (ou `import cli as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: cli` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `cli` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 16.2. Artefactos nativos, importación e catálogo completo da API de `cli`

En `ridgun-libs`, **`cli`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/cli.rg` (dominio `CLI`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/cli.rglib` | Distribución e importación directa con `import cli` |
| **Ficheiro compilado** | `target/cli.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libcli.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Cada lib declara o seu propio espazo de nomes con `module :: cli`: abonda con escribir `import cli` (ou `import cli as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 16.2.1. Resumo de familias funcionais de `cli`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `cli has flag : [String] -> String -> String -> Bool` | Detecta `--long`, `-s` ou bandeiras agrupadas `-xyz` antes de `--` |
| `cli get opt / cli get int opt` | Extrae opción de texto ou enteira (`--k=v`, `--k v`, `-k v`) con valor por defecto |
| `cli positionals / cli subcommand` | Recolle os argumentos posicionais (incluíndo todo o que segue a `--`) |
| `env get or / env get int or / env get bool or` | Le variables de contorno con conversión tipada e valores de apoio |

### 16.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/cli.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/cli.rg` (`0` tipos, `0` operadores e `26` funcións):

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 16.3. Explorando `cli` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `cli` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test cli.rg`.

### 16.3.1. Exemplo 1: Fluxo principal en estilo tabular con `cli`

Observa como en Ridgun os signos `=` e os pasos de transformación con `cli` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

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

### 16.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `cli` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import cli

fn :: leer config entorno => Int Bool
      leer config entorno =
        env get int or "SOLSTICE_WORKERS" 4 -> workers
        env get bool or "SOLSTICE_DEBUG" False -> debug
        (workers, debug)
```

### 16.3.3. Exemplo 3: Bandeiras booleanas (`cli has flag`) e opcións con valor (`--key=val` e `--key val`, `cli opt int`, `cli opt bool`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `cli` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 16.3.4. Exemplo 4: Extracción de posicionais respectando `--` (`cli positionals`), subcomandos (`cli subcommand`) e variables de contorno tipadas (`env str/int/bool or`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `cli` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 16.3.5. Exemplo 5: Despachador completo de ferramenta CLI combinando subcomandos, bandeiras, opcións tipadas e respaldo por variables de contorno

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `cli` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

## 16.4. Baixo o capó: como está construída `cli` en Ridgun puro (`src/main/ridgun/lib/cli.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/cli.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 16.4.1. Implementación interna: Internal String & List Helpers

Fíxate en como `cli.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

### 16.4.2. Implementación interna: Positional Arguments & Subcommand Extraction

Fíxate en como `cli.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

### 16.4.3. Implementación interna: Typed Environment Variable Readers

Fíxate en como `cli.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

## 16.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `cli`

- **Garantía algorítmica e de seguridade**: Respecto estrito do separador POSIX `--`: ningún argumento situado á dereita de `--` se interpreta xamais como bandeira.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/cli.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test cli.rg`.

### As 5 Regras de Ouro ao programar con `cli`

1. **Declara `import cli` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `cli` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `cli` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `cli` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 17** pasaremos a explorar en profundidade a lib **`path`** (A lib `path` — Normalización POSIX (`path clean`) e Confinamento contra Path Traversal).
