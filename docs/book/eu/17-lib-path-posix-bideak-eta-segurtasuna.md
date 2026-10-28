# 17. kapitulua: `path` lib-a — POSIX Normalizazioa (`path clean`) eta Path Traversal Aurkako Konfinamendua

## 17.1. Zergatik existitzen da `path` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `path` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `path`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: bideak `base + "/" + fitxategia` eginez lotzea, `..` segmentuak garbitu eta aurrizkiak baliozkotu gabe, zure web zerbitzarian norbaitek `../../etc/passwd` eskatzeko atea zabalik uztea bezala da.

**`path`** lib-ak POSIX normalizazio lexikoa (`path clean`, Go-ren `filepath.Clean` estiloan), lotura segurua (`path join`), deskonposizioa (`dirname`, `basename`, `stem`, `ext`, `replace ext`) eta direktorio-ihesen aurkako **`path is safe subpath`** (`VUL-INJ-001`) segurtasun-predikatua inplementatzen ditu.

Ekosistema tradizional batean, **`PATH`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`path`** lib-ak (`src/main/ridgun/lib/path.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Deklaratu `import path` (edo `import path as alias`) fitxategiaren hasieran**: lib bakoitzak `module :: path` izen-espazioa definitzen du eta `--strict` moduan hitz anitzeko funtzioei zuriune naturalekin deitzen zaie beti.
2. **Kateatu zure datu-hodiak ezkerretik eskuinera `->` bidez**: idatzi `sarrera lehen urratsa -> bigarren urratsa -> emaitza`, erabili `(+ _ _ +)` maskarak sekuentziak desegituratzeko eta kendu `_ =` sententzia sekuentzialetan (edo baztertu `-> ()` bidez).
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `path`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 17.2. Artefaktu natiboak, inportazioa eta `path` APIaren katalogo osoa

`ridgun-libs`-en, **`path`** lehen mailako **lib** bat da, `src/main/ridgun/lib/path.rg` bidean kokatua (`PATH` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/path.rglib` | Banaketa eta inportazio zuzena `import path` bidez |
| **Fitxategi konpilatua** | `target/path.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libpath.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib bakoitzak bere izen-espazioa deklaratzen du `module :: path` bidez: nahikoa da goiburuan `import path` (edo `import path as alias`) idaztea eta bere funtzioei zuriune naturalekin (`nire funtzioa x`) eta `->` hodiekin (`x nire funtzioa -> emaitza`) deitzea.

### 17.2.1. `path`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `path clean / path join / path join list` | `//`, `.` eta `..` lexikoki kolapsatzen ditu eta bide-segmentuak lotzen ditu |
| `path dirname / path basename / path split` | Bide bat guraso-direktorioan eta azken fitxategi-izenean zatitzen du |
| `path ext / path stem / path replace ext` | Luzapena erauzi edo aldatzen du (`.bashrc` erro gisa eta `""` luzapen gisa tratatuz) |
| `path is safe subpath : String -> String -> Bool` | `rel` `base_dir` barruan zorrotz geratzen dela eta NUL byterik ez duela egiaztatzen du |

### 17.2.2. `src/main/ridgun/lib/path.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/path.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`0` mota, `0` eragile eta `30` funtzio):

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
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

## 17.3. `path` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `path` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test path.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 17.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `path` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `path` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import path

fn :: resolver archivo estatico String String => Bool String
      resolver archivo estatico raiz peticion =
        path is safe subpath raiz peticion -> seguro
        path join raiz peticion -> ruta
        (seguro, ruta)
```

### 17.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`path` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import path

fn :: cambiar salida a objeto String => String String String
      cambiar salida a objeto fuente =
        fuente path dirname -> dir
        fuente path stem -> nom
        fuente path clean -> limpio
        path with ext limpio ".rglib" -> obj
        (dir, nom, obj)
```

### 17.3.3. 3. adibidea: POSIX normalizazio lexikoa (`path clean`) eta segmentuen lotura segurua (`path join`, `path join all`)

Adibide praktiko honetan `path` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test path clean and join => ()
      test path clean and join =
        -- Go path/path_test.go cleantests vectors
        assert str eq (path clean "") "." "AC1: empty -> ."
        assert str eq (path clean ".") "." "AC1: . -> ."
        assert str eq (path clean "././.") "." "AC1: ././. -> ."
        assert str eq (path clean "/") "/" "AC1: / -> /"
        assert str eq (path clean "///") "/" "AC1: /// -> /"
        assert str eq (path clean "/././") "/" "AC1: /././ -> /"
        assert str eq (path clean "/../a") "/a" "AC1: /../a clamped at root"
        assert str eq (path clean "/../../..") "/" "AC1: /../../.. clamped at root"
        assert str eq (path clean "a/b/..") "a" "AC1: a/b/.. -> a"
        assert str eq (path clean "a/../b") "b" "AC1: a/../b -> b"
        assert str eq (path clean "a/../../b") "../b" "AC1: relative .. preserved when above ."
        assert str eq (path clean "../../a/b/..") "../../a" "AC1: leading ../.. preserved"
        assert str eq (path clean "/a/b/../c/./d//") "/a/c/d" "AC1: complex absolute normalization"

        -- path join & path join list
        assert str eq (path join "" "") "." "AC1: join empty empty"
        assert str eq (path join "/var/log" "") "/var/log" "AC1: join with empty right"
        assert str eq (path join "" "app.log") "app.log" "AC1: join with empty left"
        assert str eq (path join "/var/log" "app/server.log") "/var/log/app/server.log" "AC1: join relative child"
        assert str eq (path join "/var/log" "/etc/hosts") "/etc/hosts" "AC1: join absolute child overrides base"
        assert str eq (path join list []) "." "AC1: join_list [] -> ."
        assert str eq (path join list ["src", "main", "ridgun", "lib", "path.rg"]) "src/main/ridgun/lib/path.rg" "AC1: join_list 5 segments"
        ()
```

### 17.3.4. 4. adibidea: Deskonposizioa (`dirname`, `basename`, `ext`, `stem`) eta *path traversal*-en aurkako konfinamendua (`path is safe rel`, `path resolve under`)

Adibide praktiko honetan `path` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test path components and confinement => ()
      test path components and confinement =
        p = "/home/boogie/ridgun-libs/src/socket.rg"
        assert true (path is abs p) "AC2: path_is_abs true"
        assert false (path is rel p) "AC2: path_is_rel false"
        assert false (path is abs "") "AC2: empty is not abs"
        assert true (path is rel "src/socket.rg") "AC2: relative path_is_rel"
        assert str eq (path dirname p) "/home/boogie/ridgun-libs/src" "AC2: dirname"
        assert str eq (path basename p) "socket.rg" "AC2: basename"
        sp = path split p
        assert str eq (pair_fst sp) "/home/boogie/ridgun-libs/src" "AC2: split dirname"
        assert str eq (pair_snd sp) "socket.rg" "AC2: split basename"
        assert str eq (path dirname "/") "/" "AC2: dirname of / is /"
        assert str eq (path basename "/") "/" "AC2: basename of / is /"
        assert str eq (path dirname "/top") "/" "AC2: dirname of /top is /"
        assert str eq (path dirname "barefile.txt") "." "AC2: dirname of bare filename is ."

        -- Multi-dot filenames, dotfiles, and extension replacement
        assert str eq (path stem p) "socket" "AC2: stem"
        assert str eq (path ext p) ".rg" "AC2: ext"
        assert str eq (path stem "archive.tar.gz") "archive.tar" "AC2: multi-dot stem"
        assert str eq (path ext "archive.tar.gz") ".gz" "AC2: multi-dot ext"
        assert str eq (path stem ".gitignore") ".gitignore" "AC2: dotfile stem"
        assert str eq (path ext ".gitignore") "" "AC2: dotfile empty ext"
        assert str eq (path replace ext p "rglib") "/home/boogie/ridgun-libs/src/socket.rglib" "AC2: replace_ext without leading dot"
        assert str eq (path replace ext p ".so") "/home/boogie/ridgun-libs/src/socket.so" "AC2: replace_ext with leading dot"
        assert str eq (path replace ext "main.rg" "") "main" "AC2: replace_ext with empty removes extension"

        -- OWASP Path Traversal & Shell Injection Confinement (VUL-INJ-002)
        assert true (path is safe subpath "/srv/www" "assets/app.js") "AC3: safe child subpath"
        assert true (path is safe subpath "/srv/www" "a/b/../c_1-2.txt") "AC3: safe normalized internal .."
        assert false (path is safe subpath "/srv/www" "") "AC3: empty child rejected"
        assert false (path is safe subpath "" "assets/app.js") "AC3: empty base rejected"
        assert false (path is safe subpath "/srv/www" "../etc/passwd") "AC3: direct .. traversal rejected"
        assert false (path is safe subpath "/srv/www" "a/b/../../../etc/passwd") "AC3: deep .. traversal escaping base rejected"
        assert false (path is safe subpath "/srv/www" "/etc/passwd") "AC3: absolute child path rejected"
        assert false (path is safe subpath "/srv/www" "/srv/www/index.html") "AC3: absolute child matching base still rejected"
        assert false (path is safe subpath "/srv/www" "bad;rm -rf /") "AC3: shell semicolon metachar rejected"
        assert false (path is safe subpath "/srv/www" "bad|cat") "AC3: shell pipe metachar rejected"
        assert false (path is safe subpath "/srv/www" "bad$var") "AC3: shell dollar metachar rejected"
        ()
```

### 17.3.5. 5. adibidea: *Sandbox*-eko fitxategi estatikoen ebazlea: `..` jauzien eta byte nuluen aurkako baliozkotzea eta `dirname`/`basename`/`ext`/`stem` erauzketa

Adibide praktiko honetan `path` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

## 17.4. Kaputaren azpian: nola dagoen eraikia `path` Ridgun hutsean (`src/main/ridgun/lib/path.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/path.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 17.4.1. Barne-inplementazioa: Core Implementation Part 1

Ikusi nola `path.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
module :: path

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
          p path is abs -> is_ab
          pa split slash loop p 0 0 (str len p) -> segs
          pa norm segs segs [] is_ab -> norm
          norm pa join slash -> pa finish clean is_ab

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

fn :: pa dirname at String Int => String
      pa dirname at cp     idx =
        | idx < 0   = "."
        | idx == 0  = "/"
        | otherwise = str slice cp 0 idx

fn :: pa dirname clean String => String
      pa dirname clean cp     =
        | cp == "/" = "/"
        | otherwise = pa dirname at cp (pa last char idx cp 47 ((str len cp) - 1))

fn :: path dirname String => String
      path dirname p      =  pa dirname clean (path clean p)
```

### 17.4.2. Barne-inplementazioa: Core Implementation Part 2

Ikusi nola `path.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: pa basename at String Int => String
      pa basename at cp     idx =
        | idx < 0   = cp
        | otherwise = str slice cp (idx + 1) (str len cp)

fn :: pa basename clean String => String
      pa basename clean cp     =
        | cp == "/" = "/"
        | otherwise = pa basename at cp (pa last char idx cp 47 ((str len cp) - 1))

fn :: path basename String => String
      path basename p      =  pa basename clean (path clean p)

fn :: path split String => String String
      path split p      =  (path dirname p, path basename p)

fn :: pa ext at String Int => String
      pa ext at base   dot =
        | dot <= 0  = ""
        | otherwise = str slice base dot (str len base)

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

### 17.4.3. Barne-inplementazioa: Core Implementation Part 4

Ikusi nola `path.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 17.4.4. Barne-inplementazioa: Core Implementation Part 5

Ikusi nola `path.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

## 17.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `path`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: `path is safe subpath`-ek bide absolutuak, NUL byteak eta erro-direktoriotik zein `/srv/www-secret` bezalako aurrizki anaietatik ihes egiten saiatzen den edozein `..` sekuentzia ukatzen ditu.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/path.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test path.rg` suite automatizatuaren bidez.

### `path`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import path` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `path`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `path`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `path` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**18. kapituluan** **`time`** lib-a sakonki esploratuko dugu (`time` lib-a — UTC Egutegi Zibila (Hinnant), ISO-8601, Iraupenak eta Backoff-a).
