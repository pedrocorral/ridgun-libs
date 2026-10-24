# 16. kapitulua: `cli` lib-a — Banderak, Aukerak, `--` Hesia, Azpikomandoak eta Ingurune-aldagaiak

## 16.1. Zergatik existitzen da `cli` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `cli` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `cli`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: `argv` eskuz analizatzea begizta xalo batekin hasten da beti, eta apurtzen amaitzen du norbaitek `-la` elkartuta, `--port=9090` berdin ikurrarekin edo `--` eta jarraian marratxoz hasten den `-fitxategia.rg` bat pasatzen duenean.

**`cli`** lib-ak bandera luzeak (`--verbose`), laburrak (`-v`), elkartuak (`-la`), baliodun aukerak (`--port=8080`, `--port 8080`, `-p 8080`), POSIX `--` bereizlea, argumentu posizionalak, azpikomandoak eta ingurune-aldagaien irakurketa tipatua ebazten ditu.

Ekosistema tradizional batean, **`CLI`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`cli`** lib-ak (`src/main/ridgun/lib/cli.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Funtzio osoak eta kontratu esplizituak (`=>`)**: `cli`-eko funtzio bakar batek ere ez du ezkutuko salbuespenik jaurtitzen, ezta `null` erabiltzen ere. Muga-kasu orok dokumentatutako balio bat edo batura-mota aljebraiko bat (`Option`, `Result`) itzultzen du.
2. **Zero C kode eta zero `libc`**: `cli`-eko kode guztia zuzenean ELF64 makina-kode natibora konpilatzen da, `ridgunc`-ek egiaztatuta.
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `cli`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 16.2. Artefaktu natiboak, inportazioa eta `cli` APIaren katalogo osoa

`ridgun-libs`-en, **`cli`** lehen mailako **lib** bat da, `src/main/ridgun/lib/cli.rg` bidean kokatua (`CLI` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/cli.rglib` | Banaketa eta inportazio zuzena `import cli` bidez |
| **Fitxategi konpilatua** | `target/cli.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libcli.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import cli` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

### 16.2.1. `cli`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `cli has flag : [String] -> String -> String -> Bool` | `--` aurretik `--long`, `-s` edo `-xyz` bandera elkartuak detektatzen ditu |
| `cli get opt / cli get int opt` | Testuzko edo zenbaki osozko aukera (`--k=v`, `--k v`, `-k v`) erauzten du lehenetsitako balioarekin |
| `cli positionals / cli subcommand` | Argumentu posizionalak biltzen ditu (`--` ondorengo guztia barne) |
| `env get or / env get int or / env get bool or` | Ingurune-aldagaiak irakurtzen ditu bihurketa tipatu eta ordezko balioekin |

### 16.2.2. `src/main/ridgun/lib/cli.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/cli.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`0` mota, `0` eragile eta `26` funtzio):

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
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

## 16.3. `cli` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `cli` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test cli.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 16.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `cli` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `cli` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

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

### 16.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`cli` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import cli

fn :: leer config entorno () => (Int, Bool)
      leer config entorno =
        workers = env get int or "SOLSTICE_WORKERS" 4
        debug   = env get bool or "SOLSTICE_DEBUG" False
        (workers, debug)
```

### 16.3.3. 3. adibidea: Bandera boolearrak (`cli has flag`) eta baliodun aukerak (`--key=val` eta `--key val`, `cli opt int`, `cli opt bool`)

Adibide praktiko honetan `cli` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 16.3.4. 4. adibidea: `--` errespetatzen duten posizionalen erauzketa (`cli positionals`), azpikomandoak (`cli subcommand`) eta ingurune-aldagai tipatuak (`env str/int/bool or`)

Adibide praktiko honetan `cli` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 16.3.5. 5. adibidea: CLI tresna baten bideratzaile osoa azpikomandoak, banderak, aukera tipatuak eta ingurune-aldagaien babesa uztartuz

Adibide praktiko honetan `cli` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

## 16.4. Kaputaren azpian: nola dagoen eraikia `cli` Ridgun hutsean (`src/main/ridgun/lib/cli.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/cli.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 16.4.1. Barne-inplementazioa: Internal String & List Helpers

Ikusi nola `cli.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 16.4.2. Barne-inplementazioa: Positional Arguments & Subcommand Extraction

Ikusi nola `cli.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 16.4.3. Barne-inplementazioa: Typed Environment Variable Readers

Ikusi nola `cli.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

## 16.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `cli`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: POSIX `--` bereizlearen errespetu zorrotza: `--`-ren eskuinean dagoen inongo argumenturik ez da inoiz banderatzat hartzen.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/cli.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test cli.rg` suite automatizatuaren bidez.

### `cli`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import cli` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `cli`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `cli`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `cli` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**17. kapituluan** **`path`** lib-a sakonki esploratuko dugu (`path` lib-a — POSIX Normalizazioa (`path clean`) eta Path Traversal Aurkako Konfinamendua).
