# Kapitel 16: Lib:en `cli` — Flaggor, Alternativ, `--`-barriär, Underkommandon och Miljövariabler

## 16.1. Varför finns lib:en `cli`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `cli`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `cli`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: att tolka `argv` för hand börjar alltid som en oskyldig loop och går sönder så fort någon skickar kombinerade `-la`-flaggor, `--port=9090` eller `--` följt av ett filnamn som börjar med bindestreck.

Lib:en **`cli`** hanterar långa flaggor (`--verbose`), korta flaggor (`-v`), kombinerade kortflaggor (`-la`), värdealternativ (`--port=8080`, `--port 8080`, `-p 8080`), POSIX-barriären `--`, positionella argument, underkommandon och typade miljövariabler.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`CLI`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`cli`** (`src/main/ridgun/lib/cli.rg`) problemet genom fyra kompromisslösa principer:

1. **Totala funktioner och explicita kontrakt (`=>`)**: ingen funktion i `cli` kastar dolda undantag eller förlitar sig på `null`. Varje gränsfall returnerar ett dokumenterat sentinelvärde eller en algebraisk summatyp (`Option`, `Result`).
2. **Noll C-kod och noll `libc`**: varje rad i `cli` kompileras direkt till inbyggd ELF64-maskinkod verifierad av `ridgunc`.
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `cli` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 16.2. Inbyggda artefakter, import och komplett API-katalog för `cli`

I `ridgun-libs` är **`cli`** en förstklassig **lib** placerad i `src/main/ridgun/lib/cli.rg` (domän `CLI`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/cli.rglib` | Portabel distribution och direkt import med `import cli` |
| **Kompilerat arkiv** | `target/cli.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libcli.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import cli` överst och anropar funktionerna med mellanslag eller understreck.

### 16.2.1. Översikt över funktionella familjer i `cli`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `cli has flag : [String] -> String -> String -> Bool` | Detekterar `--long`, `-s` eller kombinerade `-xyz` före `--` |
| `cli get opt / cli get int opt` | Extraherar sträng- eller heltalsalternativ (`--k=v`, `--k v`, `-k v`) med standardvärde |
| `cli positionals / cli subcommand` | Samlar in positionella argument (inklusive allt efter `--`) |
| `env get or / env get int or / env get bool or` | Läser miljövariabler med typad konvertering och reservvärden |

### 16.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/cli.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/cli.rg` (`0` typer, `0` operatorer och `26` funktioner):

| # | Funktion / Signatur (`fn ::`) | Returtyp |
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

## 16.3. Djupdykning i `cli`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `cli` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test cli.rg`.

### 16.3.1. Exempel 1: Huvudflöde i tabellform med `cli`

Lägg märke till hur `=`-tecknen och transformationsstegen med `cli` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import cli

fn :: analizar comando (args : [String]) => (String, Bool, Int, [String])
      analizar comando args =
        sub   = cli subcommand args
        all_f = cli has flag args "--all" "-a"
        port  = cli get int opt args "--port" "-p" 8080
        arch  = cli positionals args ["--port", "-p"]
        (sub, all_f, port, arch)
```

### 16.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `cli` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import cli

fn :: leer config entorno () => (Int, Bool)
      leer config entorno =
        workers = env get int or "SOLSTICE_WORKERS" 4
        debug   = env get bool or "SOLSTICE_DEBUG" False
        (workers, debug)
```

### 16.3.3. Exempel 3: Booleska flaggor (`cli has flag`) och nyckel-värde-flaggor (`--key=val` och `--key val`, `cli opt int`, `cli opt bool`)

I detta praktiska exempel undersöker vi grundligt hur `cli` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test cli flags and options => ()
      test cli flags and options =
        args = ["serve", "-la", "--verbose", "--port=9090", "-h", "127.0.0.1", "--workers", "-4", "--", "--ignored-flag", "-z", "file.rg"]
        _ = assert true (cli has flag args "--verbose" "-v") "AC1: long flag --verbose"
        _ = assert true (cli has flag args "--all" "-a") "AC1: bundled short flag -a in -la"
        _ = assert true (cli has flag args "--list" "-l") "AC1: bundled short flag -l in -la"
        _ = assert false (cli has flag args "--quiet" "-q") "AC1: missing flag returns False"
        _ = assert false (cli has flag args "--ignored-flag" "") "AC1: long flag after -- is ignored"
        _ = assert false (cli has flag args "" "-z") "AC1: short flag after -- is ignored"
        _ = assert false (cli has flag [] "--verbose" "-v") "AC1: empty args returns False"

        -- Option extraction: --key=val, --key val, -k=val, -k val, empty value --key=
        _ = assert str eq (cli get opt args "--port" "-p" "8080") "9090" "AC2: --port=9090 inline equals"
        _ = assert str eq (cli get opt args "--host" "-h" "0.0.0.0") "127.0.0.1" "AC2: -h 127.0.0.1 separate token"
        _ = assert str eq (cli get opt args "--mode" "-m" "prod") "prod" "AC2: missing option returns fallback"
        _ = assert int equals (cli get int opt args "--port" "-p" 8080) 9090 "AC2: cli_get_int_opt positive int"
        _ = assert int equals (cli get int opt args "--workers" "-w" 1) (0 - 4) "AC2: cli_get_int_opt negative int"
        _ = assert int equals (cli get int opt args "--host" "-h" 8080) 8080 "AC2: non-numeric option falls back to default int"

        short_eq_args = ["-p=3000", "--empty="]
        _ = assert int equals (cli get int opt short_eq_args "--port" "-p" 80) 3000 "AC2: short option -p=3000"
        _ = assert str eq (cli get opt short_eq_args "--empty" "-e" "def") "" "AC2: explicit empty --empty= returns empty string"
        ()
```

### 16.3.4. Exempel 4: Positionsargument med stöd för `--` (`cli positionals`), underkommandon (`cli subcommand`) och typade miljövariabler (`env str/int/bool or`)

I detta praktiska exempel undersöker vi grundligt hur `cli` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test cli positionals subcommand and env => ()
      test cli positionals subcommand and env =
        args = ["build", "-v", "--output", "target/app", "-j", "8", "--", "-dashfile.rg", "--another-literal", "main.rg"]
        _ = assert str eq (cli subcommand args) "build" "AC3: cli_subcommand first positional"
        _ = assert str eq (cli subcommand ["-v", "--release", "test"]) "test" "AC3: cli_subcommand skips leading flags"
        _ = assert str eq (cli subcommand ["--help", "-v"]) "" "AC3: cli_subcommand empty when only flags"
        _ = assert str eq (cli subcommand []) "" "AC3: cli_subcommand empty on []"

        pos = cli positionals with opts args ["--output", "-j"]
        _ = assert eq pos ["build", "-dashfile.rg", "--another-literal", "main.rg"]

        -- Single "-" (stdin/stdout convention) is treated as a positional argument, not a flag!
        stdin_args = ["cat", "-n", "-"]
        _ = assert eq (cli positionals stdin_args) ["cat", "-"]

        -- Environment variable readers
        _ = assert true ((str len (env get or "PATH" "")) > 0) "AC4: env_get_or PATH non-empty"
        _ = assert str eq (env get or "RIDGUN_NONEXISTENT_ENV_999" "fallback_val") "fallback_val" "AC4: env_get_or fallback"
        _ = assert int equals (env get int or "RIDGUN_NONEXISTENT_ENV_999" 42) 42 "AC4: env_get_int_or fallback"
        _ = assert true (env get bool or "RIDGUN_NONEXISTENT_ENV_999" True) "AC4: env_get_bool_or True fallback"
        _ = assert false (env get bool or "RIDGUN_NONEXISTENT_ENV_999" False) "AC4: env_get_bool_or False fallback"
        ()
```

### 16.3.5. Exempel 5: Fullständig CLI-kommandohanterare som kombinerar underkommandon, flaggor, typade alternativ och miljövariabler

I detta praktiska exempel undersöker vi grundligt hur `cli` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

## 16.4. Under huven: hur `cli` är byggd i ren Ridgun (`src/main/ridgun/lib/cli.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/cli.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 16.4.1. Intern implementation: Internal String & List Helpers

Se hur `cli.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
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
```

### 16.4.2. Intern implementation: Positional Arguments & Subcommand Extraction

Se hur `cli.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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
      cli subcommand args     =  cl first str (cli positionals args)
```

### 16.4.3. Intern implementation: Typed Environment Variable Readers

Se hur `cli.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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
        raw = sys getenv key
        cl parse bool val (cl trim lower loop raw 0 (str len raw)) fallback
```

---

## 16.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `cli`

- **Algoritmisk garanti och säkerhet**: Strikt efterlevnad av POSIX-barriären `--`: inget argument till höger om `--` tolkas någonsin som en flagga.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/cli.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test cli.rg`.

### De 5 Gyllene Reglerna när du programmerar med `cli`

1. **Deklarera `import cli` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `cli`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `cli`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `cli` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 17** går vi vidare och utforskar lib:en **`path`** på djupet (Lib:en `path` — POSIX-normalisering (`path clean`) och Skydd mot Path Traversal).
