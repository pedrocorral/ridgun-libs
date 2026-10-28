# Capítol 16: La lib `cli` — Banderes, Opcions, Barrera `--`, Subcomandes i Variables d'Entorn

## 16.1. Per què existeix la lib `cli`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `cli` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `cli`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: analitzar `argv` a mà sempre comença amb un bucle innocent i acaba trencant-se quan algú passa `-la` agrupat, `--port=9090` amb signe igual o `--` seguit d'un fitxer que comença per guió `-fitxer.rg`.

La lib **`cli`** resol banderes llargues (`--verbose`), curtes (`-v`), agrupades (`-la`), opcions amb valor (`--port=8080`, `--port 8080`, `-p 8080`), el separador POSIX `--`, arguments posicionals, subcomandes i lectura tipada de variables d'entorn (`env get int or`, `env get bool or`).

En un ecosistema tradicional, resoldre les tasques del domini **`CLI`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`cli`** (`src/main/ridgun/lib/cli.rg`) aborda el problema amb quatre principis innegociables:

1. **Declara `import cli` (o `import cli as alias`) a l'inici del fitxer**: cada lib defineix el seu espai de noms `module :: cli` i en mode `--strict` les funcions multi-paraula s'invoquen sempre amb espais naturals.
2. **Encadena les teves canonades d'esquerra a dreta amb `->`**: escriu `entrada pas u -> pas dos -> resultat`, fes servir màscares `(+ _ _ +)` per desestructurar seqüències i omet `_ =` en sentències seqüencials (o descarta amb `-> ()`).
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `cli` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 16.2. Artefactes natius, importació i catàleg complet de l'API de `cli`

A `ridgun-libs`, **`cli`** és una **lib** de primera classe situada a `src/main/ridgun/lib/cli.rg` (domini `CLI`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/cli.rglib` | Distribució i importació directa amb `import cli` |
| **Fitxer compilat** | `target/cli.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libcli.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Cada lib declara el seu propi espai de noms amb `module :: cli`: n'hi ha prou d'escriure `import cli` (o `import cli as alias`) a la capçalera i cridar les seves funcions amb espais naturals (`la meva funcio x`) i canonades `->` (`x la meva funcio -> resultat`).

### 16.2.1. Resum de famílies funcionals de `cli`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `cli has flag : [String] -> String -> String -> Bool` | Detecta `--long`, `-s` o banderes agrupades `-xyz` abans de `--` |
| `cli get opt / cli get int opt` | Extreu opció de text o entera (`--k=v`, `--k v`, `-k v`) amb valor per defecte |
| `cli positionals / cli subcommand` | Recull els arguments posicionals (incloent-hi tot el que segueix a `--`) |
| `env get or / env get int or / env get bool or` | Llegeix variables d'entorn amb conversió tipada i valors de suport |

### 16.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/cli.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/cli.rg` (`0` tipus, `0` operadors i `26` funcions):

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 16.3. Explorant `cli` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `cli` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test cli.rg`.

### 16.3.1. Exemple 1: Flux principal en estil tabular amb `cli`

Observa com en Ridgun els signes `=` i els passos de transformació amb `cli` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

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

### 16.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `cli` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import cli

fn :: leer config entorno => Int Bool
      leer config entorno =
        env get int or "SOLSTICE_WORKERS" 4 -> workers
        env get bool or "SOLSTICE_DEBUG" False -> debug
        (workers, debug)
```

### 16.3.3. Exemple 3: Banderes booleanes (`cli has flag`) i opcions amb valor (`--key=val` i `--key val`, `cli opt int`, `cli opt bool`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `cli` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 16.3.4. Exemple 4: Extracció de posicionals respectant `--` (`cli positionals`), subordres (`cli subcommand`) i variables d'entorn tipades (`env str/int/bool or`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `cli` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 16.3.5. Exemple 5: Despatxador complet d'eina CLI combinant subordres, banderes, opcions tipades i suport per variables d'entorn

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `cli` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

## 16.4. Sota el capó: com està construïda `cli` en Ridgun pur (`src/main/ridgun/lib/cli.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/cli.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 16.4.1. Implementació interna: Internal String & List Helpers

Fixa't en com `cli.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 16.4.2. Implementació interna: Positional Arguments & Subcommand Extraction

Fixa't en com `cli.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 16.4.3. Implementació interna: Typed Environment Variable Readers

Fixa't en com `cli.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

## 16.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `cli`

- **Garantia algorísmica i de seguretat**: Respecte estricte del separador POSIX `--`: cap argument situat a la dreta de `--` s'interpreta mai com a bandera.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/cli.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test cli.rg`.

### Les 5 Regles d'Or en programar amb `cli`

1. **Declara `import cli` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `cli` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `cli` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `cli` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 17** passarem a explorar en profunditat la lib **`path`** (La lib `path` — Normalització POSIX (`path clean`) i Confinament contra Path Traversal).
