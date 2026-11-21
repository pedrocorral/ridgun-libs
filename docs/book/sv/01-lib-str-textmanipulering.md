# Kapitel 01: Lib:en `str` — Textmanipulering, Sökning och Tabelljustering

## 01.1. Varför finns lib:en `str`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `str`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `str`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: att manipulera strängar i C med `strtok` och `strncpy` är att vandra genom ett minfält av buffertspill och `NULL`-pekare, och i andra språk importerar man ofta externa paket bara för att fylla ut kolumner i $O(\log N)$.

Lib:en **`str`** tillhandahåller rena, oföränderliga primitiver för att söka, trimma, dela upp, slå samman, ändra skiftläge, upprepa med binär fördubbling $O(\log N)$ och fylla ut kolumner.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`STR`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`str`** (`src/main/ridgun/lib/str.ridgun`) problemet genom fyra kompromisslösa principer:

1. **Deklarera `import str` (eller `import str as alias`) överst i filen**: varje lib definierar sin `module :: str`-namnrymd och i `--strict`-läge anropas flerordsfunktioner alltid med naturliga mellanslag.
2. **Kedja dina datapipelines från vänster till höger med `->`**: skriv `indata steg ett -> steg två -> resultat`, använd `(+ _ _ +)`-sekvensmasker för att packa upp tupler och utelämna `_ =` vid sekventiella satser (eller kasta med `-> ()`).
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `str` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 01.2. Inbyggda artefakter, import och komplett API-katalog för `str`

I `ridgun-libs` är **`str`** en förstklassig **lib** placerad i `src/main/ridgun/lib/str.ridgun` (domän `STR`). När du bygger med `stable bundle` paketeras den i ett inbyggt format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/str.ridgunlib` | Portabel distribution och direkt import med `import str` |

> Varje lib deklarerar sin egen namnrymd med `module :: str`: skriv bara `import str` (eller `import str as alias`) överst och anropa dess funktioner med naturliga mellanslag (`min funktion x`) och `->`-pipelines (`x min funktion -> resultat`).

### 01.2.1. Översikt över funktionella familjer i `str`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `str index of : String -> String -> Int` | Första indexet för delsträngen (`-1` om den saknas / `0` om tom) |
| `str contains / str starts with / str ends with` | `Bool`-predikat för delsträng, prefix och suffix |
| `str trim / str trim left / str trim right` | Tar bort blanktecken i ASCII (` `, `\t`, `\n`, `\r`) |
| `str split / str split chars / str join` | Delar upp till `[String]` och slår ihop listor med avgränsare |
| `str replace / str to upper / str to lower` | Icke-överlappande ersättning och ASCII-skiftlägeskonvertering |
| `str repeat / str pad left / str pad right` | $O(\log N)$-upprepning och kolumnutfyllnad till fast bredd |

### 01.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/str.ridgun`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/str.ridgun` (`0` typer, `0` operatorer och `39` funktioner):

| # | Funktion / Signatur (`fn ::`) | Returtyp |
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
| `18` | `fn :: str replace step String String String Int` | `String` |
| `19` | `fn :: str replace String String String` | `String` |
| `20` | `fn :: str split chars String Int Int [String]` | `[String]` |
| `21` | `fn :: str split onech loop String Int Int Int Int [String]` | `[String]` |
| `22` | `fn :: str split loop String String Int Int Int Int Int [String]` | `[String]` |
| `23` | `fn :: str split step String String Int Int` | `[String]` |
| `24` | `fn :: str split String String` | `[String]` |
| `25` | `fn :: upper char code String Int Int` | `String` |
| `26` | `fn :: upper char slice String Int` | `String` |
| `27` | `fn :: str to upper range String Int Int` | `String` |
| `28` | `fn :: str to upper String` | `String` |
| `29` | `fn :: lower char code String Int Int` | `String` |
| `30` | `fn :: lower char slice String Int` | `String` |
| `31` | `fn :: str to lower range String Int Int` | `String` |
| `32` | `fn :: str to lower String` | `String` |
| `33` | `fn :: str repeat loop String Int String` | `String` |
| `34` | `fn :: str repeat String Int` | `String` |
| `35` | `fn :: pad fill unit String` | `String` |
| `36` | `fn :: str pad left step String Int String Int` | `String` |
| `37` | `fn :: str pad left String Int String` | `String` |
| `38` | `fn :: str pad right step String Int String Int` | `String` |
| `39` | `fn :: str pad right String Int String` | `String` |

---

## 01.3. Djupdykning i `str`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `str` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test str.ridgun`.

### 01.3.1. Exempel 1: Huvudflöde i tabellform med `str`

Lägg märke till hur `=`-tecknen och transformationsstegen med `str` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import str

fn :: normalizar cabecera String => String
      normalizar cabecera raw =
        raw str trim -> str to lower -> limpia
        limpia str split " " -> partes
        str join partes "-" -> slug
        str pad right slug 24 "."
```

### 01.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `str` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 38 libs i `ridgun-libs`:

```ridgun
import str

fn :: dominio desde String Int => String
      dominio desde correo pos =
        | pos < 0   = "sin-dominio"
        | otherwise = str replace (str to lower correo) "@" " en "

fn :: extraer dominio String => String
      extraer dominio correo =
        dominio desde correo (str index of correo "@")
```

### 01.3.3. Exempel 3: Delsträngssökning (`str index of`), suffix (`str ends with`) och predikat för tomma/blanka strängar

I detta praktiska exempel undersöker vi grundligt hur `str` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test str search and predicates => ()
      test str search and predicates =
        str index of "hello world" "world" -> assert equals 6 "AC1: index_of world"
        str index of "hello world" "hello" -> assert equals 0 "AC1: index_of hello at 0"
        str index of "ababa" "aba" -> assert equals 0 "AC1: index_of returns first occurrence"
        str index of "hello" "xyz" -> assert equals (0 - 1) "AC1: index_of missing"
        str index of "short" "much_longer_needle" -> assert equals (0 - 1) "AC1: needle longer than haystack -> -1"
        str index of "" "a" -> assert equals (0 - 1) "AC1: non-empty needle in empty haystack -> -1"
        str index of "" "" -> assert equals 0 "AC1: empty needle in empty haystack -> 0"
        str index of "abc" "" -> assert equals 0 "AC1: empty needle -> 0"

        str ends with "archive.ridgunlib" ".ridgunlib" -> assert true "AC1: ends_with true"
        str ends with "exact" "exact" -> assert true "AC1: ends_with full string"
        str ends with "any" "" -> assert true "AC1: ends_with empty suffix true"
        str ends with "archive.ridgun" ".ridgunlib" -> assert false "AC1: ends_with false"
        str ends with "short" "longer_suffix" -> assert false "AC1: ends_with suffix longer than string"

        str is empty "" -> assert true "AC1: is_empty true"
        str is empty " " -> assert false "AC1: space is not empty"
        str is blank "" -> assert true "AC1: empty is blank"
        str is blank "   \t\n\r " -> assert true "AC1: whitespace-only is blank"
        str is blank "  x " -> assert false "AC1: non-whitespace is not blank"
        ()
```

### 01.3.4. Exempel 4: Trimning av blanksteg (`trim`, `str trim left`, `str trim right`), ersättning (`str replace`), uppdelning (`str split`) och sammanslagning (`str join`)

I detta praktiska exempel undersöker vi grundligt hur `str` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test str trim replace and split => ()
      test str trim replace and split =
        str trim "  \thi\n\r " -> assert equals "hi" "AC2: str_trim mixed ASCII whitespace"
        str trim "   \t\r\n" -> assert equals "" "AC2: str_trim all whitespace -> empty"
        str trim "" -> assert equals "" "AC2: str_trim empty -> empty"
        str trim "no_ws" -> assert equals "no_ws" "AC2: str_trim no whitespace"
        str trim left "  abc  " -> assert equals "abc  " "AC2: str_trim_left"
        str trim right "  abc  " -> assert equals "  abc" "AC2: str_trim_right"

        str replace "a-b-c" "-" "_" -> assert equals "a_b_c" "AC2: str_replace single char"
        str replace "aaaa" "aa" "b" -> assert equals "bb" "AC2: str_replace non-overlapping left-to-right"
        str replace "Hello,World" "World" "" -> assert equals "Hello," "AC2: str_replace deletion to empty"
        str replace "abc" "" "x" -> assert equals "abc" "AC2: str_replace empty old leaves string unchanged"
        str replace "abc" "z" "y" -> assert equals "abc" "AC2: str_replace absent needle"

        str split "a,b,c" "," -> assert equals ["a", "b", "c"] "AC2: str_split comma"
        str split "a,,b," "," -> assert equals ["a", "", "b", ""] "AC2: str_split consecutive and trailing delim"
        str split ",a" "," -> assert equals ["", "a"] "AC2: str_split leading delim"
        str split "a::b::c" "::" -> assert equals ["a", "b", "c"] "AC2: str_split multi-char delimiter"
        str split "ab" "" -> assert equals ["a", "b"] "AC2: str_split empty delim splits chars"
        str split "" "" -> assert equals [] "AC2: str_split empty string with empty delim -> []"

        str join [] "::" -> assert equals "" "AC2: str_join empty list"
        str join ["only"] "::" -> assert equals "only" "AC2: str_join singleton"
        str join ["alpha", "beta", "gamma"] "::" -> assert equals "alpha::beta::gamma" "AC2: str_join 3 items"
        ()
```

### 01.3.5. Exempel 5: ASCII-skiftlägeskonvertering (`str to upper`, `str to lower`), $O(\log N)$ binär upprepning (`str repeat`) och kolumnutfyllnad (`str pad left`, `str pad right`)

I detta praktiska exempel undersöker vi grundligt hur `str` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test str case repeat and padding => ()
      test str case repeat and padding =
        str to upper "Abc! 123 xyz" -> assert equals "ABC! 123 XYZ" "AC3: str_to_upper"
        str to lower "Abc! 123 XYZ" -> assert equals "abc! 123 xyz" "AC3: str_to_lower"
        str to upper "" -> assert equals "" "AC3: str_to_upper empty"

        str repeat "ab" 3 -> assert equals "ababab" "AC3: str_repeat 3"
        str repeat "ab" 1 -> assert equals "ab" "AC3: str_repeat 1"
        str repeat "ab" 0 -> assert equals "" "AC3: str_repeat 0"
        str repeat "ab" (0 - 5) -> assert equals "" "AC3: str_repeat negative -> empty"
        str repeat "" 100 -> assert equals "" "AC3: str_repeat empty string -> empty"

        t0 = sys monotonic ms
        r64k = str repeat "x" 65536
        r256k = str repeat "x" 262144
        t1 = sys monotonic ms
        r8m = str repeat "x" 8000000
        str len r64k -> assert equals 65536 "AC3: str_repeat 65536 length"
        str len r256k -> assert equals 262144 "AC3: str_repeat 262144 length"
        str len r8m -> assert equals 8000000 "AC3: RG-052 str_repeat 8000000 exact length without 1 MiB cap"
        (t1 - t0) < 200 -> assert true "AC3: LIB-9 str_repeat 64k+256k in < 200 ms"

        str pad left "7" 3 "0" -> assert equals "007" "AC3: str_pad_left"
        str pad right "7" 3 "0" -> assert equals "700" "AC3: str_pad_right"
        str pad left "7" 4 "" -> assert equals "   7" "AC3: str_pad_left empty pad_ch defaults to space"
        str pad left "7" 4 "xyz" -> assert equals "xxx7" "AC3: str_pad_left uses first char of pad_ch"
        str pad left "1234" 3 "0" -> assert equals "1234" "AC3: str_pad_left already wider than width"
        str pad right "1234" 3 "0" -> assert equals "1234" "AC3: str_pad_right already wider than width"
        ()
```

---

## 01.4. Under huven: hur `str` är byggd i ren Ridgun (`src/main/ridgun/lib/str.ridgun`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/str.ridgun` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 01.4.1. Intern implementation: ASCII Classification Helpers

Se hur `str.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
module :: str

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

### 01.4.2. Intern implementation: Whitespace Trimming

Se hur `str.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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
        s str len -> len
        first non space idx s 0 len -> start
        str slice s start len

fn :: str trim right String => String
      str trim right s      =
        s str len -> len
        last non space end s len -> end
        str slice s 0 end

fn :: str trim slice String Int Int => String
      str trim slice s start end =
        | start >= end = ""
        | otherwise    = str slice s start end

fn :: str trim String => String
      str trim s      =
        s str len -> len
        first non space idx s 0 len -> start
        last non space end s len -> end
        str trim slice s start end

fn :: str is blank String => Bool
      str is blank s      =  s str trim -> str is empty
```

### 01.4.3. Intern implementation: String Splitting & Joining

Se hur `str.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: str split chars String Int Int [String] => [String]
      str split chars s idx slen acc =
        | idx >= slen = acc
        | otherwise   = str split chars s (idx + 1) slen (acc :: [str slice s idx (idx + 1)])

fn :: str split onech loop String Int Int Int Int [String] => [String]
      str split onech loop s d0 pos slen seg_start acc =
        | pos >= slen = acc :: [str slice s seg_start slen]
        | (str char at s pos) == d0 =
          seg = str slice s seg_start pos
          str split onech loop s d0 (pos + 1) slen (pos + 1) (acc :: [seg])
        | otherwise =
          str split onech loop s d0 (pos + 1) slen seg_start acc

fn :: str split loop String String Int Int Int Int Int [String] => [String]
      str split loop s delim d0 pos slen dlen seg_start acc =
        | pos + dlen > slen = acc :: [str slice s seg_start slen]
        | (str char at s pos) == d0 and (str slice s pos (pos + dlen)) == delim =
          seg = str slice s seg_start pos
          str split loop s delim d0 (pos + dlen) slen dlen (pos + dlen) (acc :: [seg])
        | otherwise =
          str split loop s delim d0 (pos + 1) slen dlen seg_start acc

fn :: str split step String String Int Int => [String]
      str split step s delim slen dlen =
        | dlen == 0 = str split chars s 0 slen []
        | dlen == 1 = str split onech loop s (str char at delim 0) 0 slen 0 []
        | otherwise = str split loop s delim (str char at delim 0) 0 slen dlen 0 []

fn :: str split String String => [String]
      str split s      delim  =
        str split step s delim (str len s) (str len delim)

-- `str join [String] String => String` is the compiler prelude's (ridgunc 0.9.55).
```

### 01.4.4. Intern implementation: Repetition & Padding

Se hur `str.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

## 01.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `str`

- **Algoritmisk garanti och säkerhet**: $O(\log N)$-upprepning via binär strängfördubbling, säker hantering av tomma söksträngar och noll mutering på plats.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/str.ridgun` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test str.ridgun`.

### De 5 Gyllene Reglerna när du programmerar med `str`

1. **Deklarera `import str` överst i filen** och anropa dess funktioner med mellanslag, precis som de är deklarerade, så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `str`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `str`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `str` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 02** går vi vidare och utforskar lib:en **`math`** på djupet (Lib:en `math` — Säker Aritmetik, Talteori och Statistik).
