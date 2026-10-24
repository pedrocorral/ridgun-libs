# 01. kapitulua: `str` lib-a — Testu-manipulazioa, Bilaketa eta Formatu Taularatua

## 01.1. Zergatik existitzen da `str` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `str` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `str`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: C lengoaian `strtok` eta `strncpy` bidez kateak manipulatzea buffer-gainezkatzeen eta `NULL` erakusleen arteko mina-zelai batean ibiltzea da, eta beste lengoaia batzuetan hiru pakete inportatzen amaitzen duzu zutabeak lerrokatzeko.

**`str`** lib-ak kateak bilatu, moztu, zatitu, elkartu, letra larri/xeheetara bihurtu, $O(\log N)$ bikoizketa bitarrez errepikatu eta betetzeko primitiba huts eta aldaezin guztiak eskaintzen ditu.

Ekosistema tradizional batean, **`STR`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`str`** lib-ak (`src/main/ridgun/lib/str.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Funtzio osoak eta kontratu esplizituak (`=>`)**: `str`-eko funtzio bakar batek ere ez du ezkutuko salbuespenik jaurtitzen, ezta `null` erabiltzen ere. Muga-kasu orok dokumentatutako balio bat edo batura-mota aljebraiko bat (`Option`, `Result`) itzultzen du.
2. **Zero C kode eta zero `libc`**: `str`-eko kode guztia zuzenean ELF64 makina-kode natibora konpilatzen da, `ridgunc`-ek egiaztatuta.
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `str`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 01.2. Artefaktu natiboak, inportazioa eta `str` APIaren katalogo osoa

`ridgun-libs`-en, **`str`** lehen mailako **lib** bat da, `src/main/ridgun/lib/str.rg` bidean kokatua (`STR` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/str.rglib` | Banaketa eta inportazio zuzena `import str` bidez |
| **Fitxategi konpilatua** | `target/str.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libstr.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import str` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

### 01.2.1. `str`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `str index of : String -> String -> Int` | Azpikatearen lehen indizea (`-1` ez badago / `0` hutsa bada) |
| `str contains / str starts with / str ends with` | Azpikate, aurrizki eta atzizkien `Bool` predikatuak |
| `str trim / str trim left / str trim right` | ASCII zuriuneak kentzen ditu (` `, `\t`, `\n`, `\r`) |
| `str split / str lines / str words / str join` | `[String]` zerrendan zatitu eta bereizle batekin elkartzen ditu |
| `str replace / str to upper / str to lower` | Gainjartzerik gabeko ordezkapena eta ASCII letra larri/xeheen bihurketa |
| `str repeat / str pad left / str pad right` | $O(\log N)$ errepikapena eta zabaleraardatzeko zutabe-betegarria |

### 01.2.2. `src/main/ridgun/lib/str.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/str.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`0` mota, `0` eragile eta `39` funtzio):

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
|---|---|---|
| `1` | `fn :: is ascii space Int` | `Bool` |
| `2` | `fn :: is ascii lower Int` | `Bool` |
| `3` | `fn :: is ascii upper Int` | `Bool` |
| `4` | `fn :: to upper code Int` | `Int` |
| `5` | `fn :: to lower code Int` | `Int` |
| `6` | `fn :: str index of from String String Int Int Int` | `Int` |
| `7` | `fn :: str index of String String` | `Int` |
| `8` | `fn :: str ends with step String String Int Int` | `Bool` |
| `9` | `fn :: str ends with String String` | `Bool` |
| `10` | `fn :: str is empty String` | `Bool` |
| `11` | `fn :: first non space idx String Int Int` | `Int` |
| `12` | `fn :: last non space end String Int` | `Int` |
| `13` | `fn :: str trim left String` | `String` |
| `14` | `fn :: str trim right String` | `String` |
| `15` | `fn :: str trim slice String Int Int` | `String` |
| `16` | `fn :: str trim String` | `String` |
| `17` | `fn :: str is blank String` | `Bool` |
| `18` | `fn :: str replace loop String String String Int Int Int String` | `String` |
| `19` | `fn :: str replace step String String String Int` | `String` |
| `20` | `fn :: str replace String String String` | `String` |
| `21` | `fn :: str split chars String Int Int` | `[String]` |
| `22` | `fn :: str split loop String String Int Int Int Int` | `[String]` |
| `23` | `fn :: str split step String String Int Int` | `[String]` |
| `24` | `fn :: str split String String` | `[String]` |
| `25` | `fn :: str join tail [String] String` | `String` |
| `26` | `fn :: str join [String] String` | `String` |
| `27` | `fn :: upper char slice String Int` | `String` |
| `28` | `fn :: str to upper loop String Int Int String` | `String` |
| `29` | `fn :: str to upper String` | `String` |
| `30` | `fn :: lower char slice String Int` | `String` |
| `31` | `fn :: str to lower loop String Int Int String` | `String` |
| `32` | `fn :: str to lower String` | `String` |
| `33` | `fn :: str repeat loop String Int String` | `String` |
| `34` | `fn :: str repeat String Int` | `String` |
| `35` | `fn :: pad fill unit String` | `String` |
| `36` | `fn :: str pad left step String Int String Int` | `String` |
| `37` | `fn :: str pad left String Int String` | `String` |
| `38` | `fn :: str pad right step String Int String Int` | `String` |
| `39` | `fn :: str pad right String Int String` | `String` |

---

## 01.3. `str` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `str` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test str.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 01.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `str` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `str` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import str

fn :: normalizar cabecera (raw : String) => String
      normalizar cabecera raw =
        limpia = str to lower (str trim raw)
        partes = str words limpia
        slug   = str join partes "-"
        str pad right slug 24 "."
```

### 01.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`str` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import str

fn :: extraer dominio (correo : String) => String
      extraer dominio correo =
        pos = str index of correo "@"
        | pos < 0   = "sin-dominio"
        | otherwise =
          partes = str split correo "@"
          str replace (str to lower correo) "@" " en "
```

### 01.3.3. 3. adibidea: Azpikateen bilaketa (`str index of`), atzizkiak (`str ends with`) eta hutsik/zurizko predikatuak

Adibide praktiko honetan `str` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test str search and predicates => ()
      test str search and predicates =
        _ = assert equals (str index of "hello world" "world") 6 "AC1: index_of world"
        _ = assert equals (str index of "hello world" "hello") 0 "AC1: index_of hello at 0"
        _ = assert equals (str index of "ababa" "aba") 0 "AC1: index_of returns first occurrence"
        _ = assert equals (str index of "hello" "xyz") (0 - 1) "AC1: index_of missing"
        _ = assert equals (str index of "short" "much_longer_needle") (0 - 1) "AC1: needle longer than haystack -> -1"
        _ = assert equals (str index of "" "a") (0 - 1) "AC1: non-empty needle in empty haystack -> -1"
        _ = assert equals (str index of "" "") 0 "AC1: empty needle in empty haystack -> 0"
        _ = assert equals (str index of "abc" "") 0 "AC1: empty needle -> 0"

        _ = assert true (str ends with "archive.rglib" ".rglib") "AC1: ends_with true"
        _ = assert true (str ends with "exact" "exact") "AC1: ends_with full string"
        _ = assert true (str ends with "any" "") "AC1: ends_with empty suffix true"
        _ = assert false (str ends with "archive.rg" ".rglib") "AC1: ends_with false"
        _ = assert false (str ends with "short" "longer_suffix") "AC1: ends_with suffix longer than string"

        _ = assert true (str is empty "") "AC1: is_empty true"
        _ = assert false (str is empty " ") "AC1: space is not empty"
        _ = assert true (str is blank "") "AC1: empty is blank"
        _ = assert true (str is blank "   \t\n\r ") "AC1: whitespace-only is blank"
        _ = assert false (str is blank "  x ") "AC1: non-whitespace is not blank"
        ()
```

### 01.3.4. 4. adibidea: Zuriuneen mozketa (`trim`, `trim left`, `trim right`), ordezkapena (`str replace`), zatiketa (`str split`) eta lotura (`str join`)

Adibide praktiko honetan `str` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test str trim replace and split => ()
      test str trim replace and split =
        _ = assert equals (str trim "  \thi\n\r ") "hi" "AC2: str_trim mixed ASCII whitespace"
        _ = assert equals (str trim "   \t\r\n") "" "AC2: str_trim all whitespace -> empty"
        _ = assert equals (str trim "") "" "AC2: str_trim empty -> empty"
        _ = assert equals (str trim "no_ws") "no_ws" "AC2: str_trim no whitespace"
        _ = assert equals (str trim left "  abc  ") "abc  " "AC2: str_trim_left"
        _ = assert equals (str trim right "  abc  ") "  abc" "AC2: str_trim_right"

        _ = assert equals (str replace "a-b-c" "-" "_") "a_b_c" "AC2: str_replace single char"
        _ = assert equals (str replace "aaaa" "aa" "b") "bb" "AC2: str_replace non-overlapping left-to-right"
        _ = assert equals (str replace "Hello,World" "World" "") "Hello," "AC2: str_replace deletion to empty"
        _ = assert equals (str replace "abc" "" "x") "abc" "AC2: str_replace empty old leaves string unchanged"
        _ = assert equals (str replace "abc" "z" "y") "abc" "AC2: str_replace absent needle"

        _ = assert equals (str split "a,b,c" ",") ["a", "b", "c"] "AC2: str_split comma"
        _ = assert equals (str split "a,,b," ",") ["a", "", "b", ""] "AC2: str_split consecutive and trailing delim"
        _ = assert equals (str split ",a" ",") ["", "a"] "AC2: str_split leading delim"
        _ = assert equals (str split "a::b::c" "::") ["a", "b", "c"] "AC2: str_split multi-char delimiter"
        _ = assert equals (str split "ab" "") ["a", "b"] "AC2: str_split empty delim splits chars"
        _ = assert equals (str split "" "") [] "AC2: str_split empty string with empty delim -> []"

        _ = assert equals (str join [] "::") "" "AC2: str_join empty list"
        _ = assert equals (str join ["only"] "::") "only" "AC2: str_join singleton"
        _ = assert equals (str join ["alpha", "beta", "gamma"] "::") "alpha::beta::gamma" "AC2: str_join 3 items"
        ()
```

### 01.3.5. 5. adibidea: ASCII letra larri/xeheen bihurketa (`to upper`, `to lower`), $O(\log N)$ errepikapen bitarra (`str repeat`) eta lerrokatze taularatua (`pad left`, `pad right`)

Adibide praktiko honetan `str` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test str case repeat and padding => ()
      test str case repeat and padding =
        _ = assert equals (str to upper "Abc! 123 xyz") "ABC! 123 XYZ" "AC3: str_to_upper"
        _ = assert equals (str to lower "Abc! 123 XYZ") "abc! 123 xyz" "AC3: str_to_lower"
        _ = assert equals (str to upper "") "" "AC3: str_to_upper empty"

        _ = assert equals (str repeat "ab" 3) "ababab" "AC3: str_repeat 3"
        _ = assert equals (str repeat "ab" 1) "ab" "AC3: str_repeat 1"
        _ = assert equals (str repeat "ab" 0) "" "AC3: str_repeat 0"
        _ = assert equals (str repeat "ab" (0 - 5)) "" "AC3: str_repeat negative -> empty"
        _ = assert equals (str repeat "" 100) "" "AC3: str_repeat empty string -> empty"

        t0 = sys monotonic ms
        r64k = str repeat "x" 65536
        r256k = str repeat "x" 262144
        t1 = sys monotonic ms
        r8m = str repeat "x" 8000000
        _ = assert equals (str len r64k) 65536 "AC3: str_repeat 65536 length"
        _ = assert equals (str len r256k) 262144 "AC3: str_repeat 262144 length"
        _ = assert equals (str len r8m) 8000000 "AC3: RG-052 str_repeat 8000000 exact length without 1 MiB cap"
        _ = assert true ((t1 - t0) < 200) "AC3: LIB-9 str_repeat 64k+256k in < 200 ms"

        _ = assert equals (str pad left "7" 3 "0") "007" "AC3: str_pad_left"
        _ = assert equals (str pad right "7" 3 "0") "700" "AC3: str_pad_right"
        _ = assert equals (str pad left "7" 4 "") "   7" "AC3: str_pad_left empty pad_ch defaults to space"
        _ = assert equals (str pad left "7" 4 "xyz") "xxx7" "AC3: str_pad_left uses first char of pad_ch"
        _ = assert equals (str pad left "1234" 3 "0") "1234" "AC3: str_pad_left already wider than width"
        _ = assert equals (str pad right "1234" 3 "0") "1234" "AC3: str_pad_right already wider than width"
        ()
```

---

## 01.4. Kaputaren azpian: nola dagoen eraikia `str` Ridgun hutsean (`src/main/ridgun/lib/str.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/str.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 01.4.1. Barne-inplementazioa: ASCII Classification Helpers

Ikusi nola `str.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: is ascii space Int  => Bool
      is ascii space code =
        code == 32 or code == 9 or code == 10 or code == 13

fn :: is ascii lower Int  => Bool
      is ascii lower code =  code >= 97 and code <= 122

fn :: is ascii upper Int  => Bool
      is ascii upper code =  code >= 65 and code <= 90

fn :: to upper code Int  => Int
      to upper code code =
        | is ascii lower code = code - 32
        | otherwise           = code

fn :: to lower code Int  => Int
      to lower code code =
        | is ascii upper code = code + 32
        | otherwise           = code
```

### 01.4.2. Barne-inplementazioa: Whitespace Trimming

Ikusi nola `str.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: first non space idx String Int Int => Int
      first non space idx s idx len =
        | idx >= len                         = len
        | is ascii space (str char at s idx) = first non space idx s (idx + 1) len
        | otherwise                          = idx

fn :: last non space end String Int => Int
      last non space end s end =
        | end <= 0                                 = 0
        | is ascii space (str char at s (end - 1)) = last non space end s (end - 1)
        | otherwise                                = end

fn :: str trim left String => String
      str trim left s      =
        len   = str len s
        start = first non space idx s 0 len
        str slice s start len

fn :: str trim right String => String
      str trim right s      =
        len = str len s
        end = last non space end s len
        str slice s 0 end

fn :: str trim slice String Int Int => String
      str trim slice s start end =
        | start >= end = ""
        | otherwise    = str slice s start end

fn :: str trim String => String
      str trim s      =
        len   = str len s
        start = first non space idx s 0 len
        end   = last non space end s len
        str trim slice s start end

fn :: str is blank String => Bool
      str is blank s      =  (str len (str trim s)) == 0
```

### 01.4.3. Barne-inplementazioa: String Splitting & Joining

Ikusi nola `str.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: str split chars String Int Int => [String]
      str split chars s idx slen =
        | idx >= slen = []
        | otherwise   = [str slice s idx (idx + 1)] :: (str split chars s (idx + 1) slen)

fn :: str split loop String String Int Int Int Int => [String]
      str split loop s delim pos slen dlen seg_start =
        | pos + dlen > slen = [str slice s seg_start slen]
        | (str slice s pos (pos + dlen)) == delim =
          seg = str slice s seg_start pos
          [seg] :: (str split loop s delim (pos + dlen) slen dlen (pos + dlen))
        | otherwise =
          str split loop s delim (pos + 1) slen dlen seg_start

fn :: str split step String String Int Int => [String]
      str split step s delim slen dlen =
        | dlen == 0 = str split chars s 0 slen
        | otherwise = str split loop s delim 0 slen dlen 0

fn :: str split String String => [String]
      str split s      delim  =
        str split step s delim (str len s) (str len delim)

fn :: str join tail [String] String => String
      str join tail []       _      =  ""
      str join tail (x:xs)   sep    =  sep + x + (str join tail xs sep)

fn :: str join [String] String => String
      str join []       _      =  ""
      str join (x:xs)   sep    =  x + (str join tail xs sep)
```

### 01.4.4. Barne-inplementazioa: Repetition & Padding

Ikusi nola `str.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: str repeat loop String Int String => String
      str repeat loop cur n acc =
        | n <= 0       = acc
        | (n % 2) == 1 = str repeat loop (cur + cur) (n / 2) (acc + cur)
        | otherwise    = str repeat loop (cur + cur) (n / 2) acc

fn :: str repeat String Int => String
      str repeat s      n   =
        | n <= 0 or (str len s) == 0 = ""
        | otherwise                  = str repeat loop s n ""

fn :: pad fill unit String => String
      pad fill unit pad_ch =
        | (str len pad_ch) == 0 = " "
        | otherwise             = str slice pad_ch 0 1

fn :: str pad left step String Int String Int => String
      str pad left step s width pad_ch slen =
        | slen >= width = s
        | otherwise     = (str repeat (pad fill unit pad_ch) (width - slen)) + s

fn :: str pad left String Int String => String
      str pad left s width pad_ch =
        str pad left step s width pad_ch (str len s)

fn :: str pad right step String Int String Int => String
      str pad right step s width pad_ch slen =
        | slen >= width = s
        | otherwise     = s + (str repeat (pad fill unit pad_ch) (width - slen))

fn :: str pad right String Int String => String
      str pad right s width pad_ch =
        str pad right step s width pad_ch (str len s)
```

---

## 01.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `str`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: $O(\log N)$ errepikapena kateen bikoizketaren bidez, predikatu seguruak orratz hutsen aurrean eta zero mutazio bertan.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/str.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test str.rg` suite automatizatuaren bidez.

### `str`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import str` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `str`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `str`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `str` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**02. kapituluan** **`math`** lib-a sakonki esploratuko dugu (`math` lib-a — Aritmetika Segurua, Zenbaki-teoria eta Estatistika).
