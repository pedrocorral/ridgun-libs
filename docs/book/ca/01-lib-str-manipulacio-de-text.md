# Capítol 01: La lib `str` — Manipulació de Text, Cerca i Format Tabular

## 01.1. Per què existeix la lib `str`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `str` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `str`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: en C manipular cadenes amb `strtok` i `strncpy` és caminar per un camp de mines de desbordaments de memòria i punters `NULL`, i en altres llenguatges acabes important tres paquets només per alinear columnes o repetir un separador en $O(\log N)$.

La lib **`str`** proporciona totes les primitives pures i immutables per cercar, retallar, dividir, unir, canviar majúscules/minúscules, repetir per duplicació binària $O(\log N)$ i emplenar cadenes.

En un ecosistema tradicional, resoldre les tasques del domini **`STR`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`str`** (`src/main/ridgun/lib/str.rg`) aborda el problema amb quatre principis innegociables:

1. **Declara `import str` (o `import str as alias`) a l'inici del fitxer**: cada lib defineix el seu espai de noms `module :: str` i en mode `--strict` les funcions multi-paraula s'invoquen sempre amb espais naturals.
2. **Encadena les teves canonades d'esquerra a dreta amb `->`**: escriu `entrada pas u -> pas dos -> resultat`, fes servir màscares `(+ _ _ +)` per desestructurar seqüències i omet `_ =` en sentències seqüencials (o descarta amb `-> ()`).
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `str` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 01.2. Artefactes natius, importació i catàleg complet de l'API de `str`

A `ridgun-libs`, **`str`** és una **lib** de primera classe situada a `src/main/ridgun/lib/str.rg` (domini `STR`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/str.rglib` | Distribució i importació directa amb `import str` |
| **Fitxer compilat** | `target/str.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libstr.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Cada lib declara el seu propi espai de noms amb `module :: str`: n'hi ha prou d'escriure `import str` (o `import str as alias`) a la capçalera i cridar les seves funcions amb espais naturals (`la meva funcio x`) i canonades `->` (`x la meva funcio -> resultat`).

### 01.2.1. Resum de famílies funcionals de `str`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `str index of : String -> String -> Int` | Primer índex de la subcadena (`-1` si no existeix / `0` si és buida) |
| `str contains / str starts with / str ends with` | Predicats `Bool` de subcadena, prefix i sufix |
| `str trim / str trim left / str trim right` | Elimina espais en blanc ASCII (` `, `\t`, `\n`, `\r`) |
| `str split / str lines / str words / str join` | Divideix en `[String]` i uneix llistes amb un separador |
| `str replace / str to upper / str to lower` | Reemplaçament sense solapament i conversió ASCII de majúscules/minúscules |
| `str repeat / str pad left / str pad right` | Repetició en $O(\log N)$ i farciment de columnes a amplada fixa |

### 01.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/str.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/str.rg` (`0` tipus, `0` operadors i `42` funcions):

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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
| `25` | `fn :: str join pair step [String] String [String]` | `[String]` |
| `26` | `fn :: str join pairs [String] String` | `String` |
| `27` | `fn :: str join [String] String` | `String` |
| `28` | `fn :: upper char code String Int Int` | `String` |
| `29` | `fn :: upper char slice String Int` | `String` |
| `30` | `fn :: str to upper range String Int Int` | `String` |
| `31` | `fn :: str to upper String` | `String` |
| `32` | `fn :: lower char code String Int Int` | `String` |
| `33` | `fn :: lower char slice String Int` | `String` |
| `34` | `fn :: str to lower range String Int Int` | `String` |
| `35` | `fn :: str to lower String` | `String` |
| `36` | `fn :: str repeat loop String Int String` | `String` |
| `37` | `fn :: str repeat String Int` | `String` |
| `38` | `fn :: pad fill unit String` | `String` |
| `39` | `fn :: str pad left step String Int String Int` | `String` |
| `40` | `fn :: str pad left String Int String` | `String` |
| `41` | `fn :: str pad right step String Int String Int` | `String` |
| `42` | `fn :: str pad right String Int String` | `String` |

---

## 01.3. Explorant `str` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `str` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test str.rg`.

### 01.3.1. Exemple 1: Flux principal en estil tabular amb `str`

Observa com en Ridgun els signes `=` i els passos de transformació amb `str` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import str

fn :: normalizar cabecera String => String
      normalizar cabecera raw =
        raw str trim -> str to lower -> limpia
        limpia str split " " -> partes
        str join partes "-" -> slug
        str pad right slug 24 "."
```

### 01.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `str` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import str

fn :: extraer dominio String => String
      extraer dominio correo =
        str index of correo "@" -> pos
        | pos < 0   = "sin-dominio"
        | otherwise =
          correo str to lower -> minusc
          str replace minusc "@" " en "
```

### 01.3.3. Exemple 3: Cerca de subcadenes (`str index of`), sufixos (`str ends with`) i predicats de buit/blanc

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `str` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test str search and predicates => ()
      test str search and predicates =
        assert equals (str index of "hello world" "world") 6 "AC1: index_of world"
        assert equals (str index of "hello world" "hello") 0 "AC1: index_of hello at 0"
        assert equals (str index of "ababa" "aba") 0 "AC1: index_of returns first occurrence"
        assert equals (str index of "hello" "xyz") (0 - 1) "AC1: index_of missing"
        assert equals (str index of "short" "much_longer_needle") (0 - 1) "AC1: needle longer than haystack -> -1"
        assert equals (str index of "" "a") (0 - 1) "AC1: non-empty needle in empty haystack -> -1"
        assert equals (str index of "" "") 0 "AC1: empty needle in empty haystack -> 0"
        assert equals (str index of "abc" "") 0 "AC1: empty needle -> 0"

        assert true (str ends with "archive.rglib" ".rglib") "AC1: ends_with true"
        assert true (str ends with "exact" "exact") "AC1: ends_with full string"
        assert true (str ends with "any" "") "AC1: ends_with empty suffix true"
        assert false (str ends with "archive.rg" ".rglib") "AC1: ends_with false"
        assert false (str ends with "short" "longer_suffix") "AC1: ends_with suffix longer than string"

        assert true (str is empty "") "AC1: is_empty true"
        assert false (str is empty " ") "AC1: space is not empty"
        assert true (str is blank "") "AC1: empty is blank"
        assert true (str is blank "   \t\n\r ") "AC1: whitespace-only is blank"
        assert false (str is blank "  x ") "AC1: non-whitespace is not blank"
        ()
```

### 01.3.4. Exemple 4: Retall d'espais (`trim`, `trim left`, `trim right`), reemplaçament (`str replace`), divisió (`str split`) i unió (`str join`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `str` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test str trim replace and split => ()
      test str trim replace and split =
        assert equals (str trim "  \thi\n\r ") "hi" "AC2: str_trim mixed ASCII whitespace"
        assert equals (str trim "   \t\r\n") "" "AC2: str_trim all whitespace -> empty"
        assert equals (str trim "") "" "AC2: str_trim empty -> empty"
        assert equals (str trim "no_ws") "no_ws" "AC2: str_trim no whitespace"
        assert equals (str trim left "  abc  ") "abc  " "AC2: str_trim_left"
        assert equals (str trim right "  abc  ") "  abc" "AC2: str_trim_right"

        assert equals (str replace "a-b-c" "-" "_") "a_b_c" "AC2: str_replace single char"
        assert equals (str replace "aaaa" "aa" "b") "bb" "AC2: str_replace non-overlapping left-to-right"
        assert equals (str replace "Hello,World" "World" "") "Hello," "AC2: str_replace deletion to empty"
        assert equals (str replace "abc" "" "x") "abc" "AC2: str_replace empty old leaves string unchanged"
        assert equals (str replace "abc" "z" "y") "abc" "AC2: str_replace absent needle"

        assert equals (str split "a,b,c" ",") ["a", "b", "c"] "AC2: str_split comma"
        assert equals (str split "a,,b," ",") ["a", "", "b", ""] "AC2: str_split consecutive and trailing delim"
        assert equals (str split ",a" ",") ["", "a"] "AC2: str_split leading delim"
        assert equals (str split "a::b::c" "::") ["a", "b", "c"] "AC2: str_split multi-char delimiter"
        assert equals (str split "ab" "") ["a", "b"] "AC2: str_split empty delim splits chars"
        assert equals (str split "" "") [] "AC2: str_split empty string with empty delim -> []"

        assert equals (str join [] "::") "" "AC2: str_join empty list"
        assert equals (str join ["only"] "::") "only" "AC2: str_join singleton"
        assert equals (str join ["alpha", "beta", "gamma"] "::") "alpha::beta::gamma" "AC2: str_join 3 items"
        ()
```

### 01.3.5. Exemple 5: Conversió de caixa ASCII (`to upper`, `to lower`), repetició binària $O(\log N)$ (`str repeat`) i alineació tabular (`pad left`, `pad right`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `str` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test str case repeat and padding => ()
      test str case repeat and padding =
        assert equals (str to upper "Abc! 123 xyz") "ABC! 123 XYZ" "AC3: str_to_upper"
        assert equals (str to lower "Abc! 123 XYZ") "abc! 123 xyz" "AC3: str_to_lower"
        assert equals (str to upper "") "" "AC3: str_to_upper empty"

        assert equals (str repeat "ab" 3) "ababab" "AC3: str_repeat 3"
        assert equals (str repeat "ab" 1) "ab" "AC3: str_repeat 1"
        assert equals (str repeat "ab" 0) "" "AC3: str_repeat 0"
        assert equals (str repeat "ab" (0 - 5)) "" "AC3: str_repeat negative -> empty"
        assert equals (str repeat "" 100) "" "AC3: str_repeat empty string -> empty"

        t0 = sys monotonic ms
        r64k = str repeat "x" 65536
        r256k = str repeat "x" 262144
        t1 = sys monotonic ms
        r8m = str repeat "x" 8000000
        assert equals (str len r64k) 65536 "AC3: str_repeat 65536 length"
        assert equals (str len r256k) 262144 "AC3: str_repeat 262144 length"
        assert equals (str len r8m) 8000000 "AC3: RG-052 str_repeat 8000000 exact length without 1 MiB cap"
        assert true ((t1 - t0) < 200) "AC3: LIB-9 str_repeat 64k+256k in < 200 ms"

        assert equals (str pad left "7" 3 "0") "007" "AC3: str_pad_left"
        assert equals (str pad right "7" 3 "0") "700" "AC3: str_pad_right"
        assert equals (str pad left "7" 4 "") "   7" "AC3: str_pad_left empty pad_ch defaults to space"
        assert equals (str pad left "7" 4 "xyz") "xxx7" "AC3: str_pad_left uses first char of pad_ch"
        assert equals (str pad left "1234" 3 "0") "1234" "AC3: str_pad_left already wider than width"
        assert equals (str pad right "1234" 3 "0") "1234" "AC3: str_pad_right already wider than width"
        ()
```

---

## 01.4. Sota el capó: com està construïda `str` en Ridgun pur (`src/main/ridgun/lib/str.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/str.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 01.4.1. Implementació interna: ASCII Classification Helpers

Fixa't en com `str.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 01.4.2. Implementació interna: Whitespace Trimming

Fixa't en com `str.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 01.4.3. Implementació interna: String Splitting & Joining

Fixa't en com `str.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

fn :: str join pair step [String] String [String] => [String]
      str join pair step []         _   acc =  acc
      str join pair step (a:[])     _   acc =  acc :: [a]
      str join pair step (a:b:rest) sep acc =
        str join pair step rest sep (acc :: [a + sep + b])

fn :: str join pairs [String] String => String
      str join pairs []       _   =  ""
      str join pairs (x:[])   _   =  x
      str join pairs (x:y:[]) sep =  x + sep + y
      str join pairs xs       sep =
        str join pairs (str join pair step xs sep []) sep

fn :: str join [String] String => String
      str join xs       sep    =  str join pairs xs sep
```

### 01.4.4. Implementació interna: Repetition & Padding

Fixa't en com `str.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

## 01.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `str`

- **Garantia algorísmica i de seguretat**: Repetició en $O(\log N)$ mitjançant duplicació de cadenes, predicats segurs davant agulles buides i zero mutació al lloc.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/str.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test str.rg`.

### Les 5 Regles d'Or en programar amb `str`

1. **Declara `import str` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `str` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `str` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `str` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 02** passarem a explorar en profunditat la lib **`math`** (La lib `math` — Aritmètica Segura, Teoria de Nombres i Estadística).
