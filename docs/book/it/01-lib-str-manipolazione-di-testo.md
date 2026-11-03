# Capitolo 01: La lib `str` — Manipolazione di Testo, Ricerca e Formattazione Tabulare

## 01.1. Perché esiste la lib `str`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `str` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `str`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: in C manipolare stringhe con `strtok` e `strncpy` significa camminare in un campo minato di buffer overflow e puntatori `NULL`, e in altri linguaggi finisci per importare tre pacchetti solo per allineare colonne o ripetere un separatore in $O(\log N)$.

La lib **`str`** fornisce tutte le primitive pure e immutabili per cercare, ritagliare, dividere, unire, convertire maiuscole/minuscole, ripetere per raddoppio binario $O(\log N)$ e riempire stringhe.

In un ecosistema tradizionale, risolvere i compiti del dominio **`STR`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`str`** (`src/main/ridgun/lib/str.rg`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import str` (o `import str as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: str` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `str` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 01.2. Artefatti nativi, importazione e catalogo completo dell'API di `str`

In `ridgun-libs`, **`str`** è una **lib** di prima classe situata in `src/main/ridgun/lib/str.rg` (dominio `STR`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/str.rglib` | Distribuzione e importazione diretta con `import str` |
| **File compilato** | `target/str.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libstr.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: str`: basta scrivere `import str` (o `import str as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 01.2.1. Riepilogo delle famiglie funzionali di `str`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `str index of : String -> String -> Int` | Primo indice della sottostringa (`-1` se assente / `0` se vuota) |
| `str contains / str starts with / str ends with` | Predicati `Bool` di sottostringa, prefisso e suffisso |
| `str trim / str trim left / str trim right` | Rimuove gli spazi bianchi ASCII (` `, `\t`, `\n`, `\r`) |
| `str split / str lines / str words / str join` | Divide in `[String]` e unisce liste con un separatore |
| `str replace / str to upper / str to lower` | Sostituzione senza sovrapposizioni e conversione ASCII maiuscole/minuscole |
| `str repeat / str pad left / str pad right` | Ripetizione in $O(\log N)$ e riempimento di colonne a larghezza fissa |

### 01.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/str.rg`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/str.rg` (`0` tipi, `0` operatori e `42` funzioni):

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
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

## 01.3. Esplorare `str` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `str` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test str.rg`.

### 01.3.1. Esempio 1: Flusso principale in stile tabulare con `str`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `str` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import str

fn :: normalizar cabecera String => String
      normalizar cabecera raw =
        raw str trim -> str to lower -> limpia
        limpia str split " " -> partes
        str join partes "-" -> slug
        str pad right slug 24 "."
```

### 01.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `str` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

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

### 01.3.3. Esempio 3: Ricerca di sottostringhe (`str index of`), suffissi (`str ends with`) e predicati di vuoto/bianco

In questo esempio pratico esploriamo in modo esaustivo come si comporta `str` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 01.3.4. Esempio 4: Ritaglio degli spazi (`trim`, `trim left`, `trim right`), sostituzione (`str replace`), divisione (`str split`) e unione (`str join`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `str` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 01.3.5. Esempio 5: Conversione ASCII maiuscole/minuscole (`to upper`, `to lower`), ripetizione binaria $O(\log N)$ (`str repeat`) e allineamento tabulare (`pad left`, `pad right`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `str` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

## 01.4. Sotto il cofano: come è costruita `str` in Ridgun puro (`src/main/ridgun/lib/str.rg`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/str.rg` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 01.4.1. Implementazione interna: ASCII Classification Helpers

Nota come `str.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 01.4.2. Implementazione interna: Whitespace Trimming

Nota come `str.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 01.4.3. Implementazione interna: String Splitting & Joining

Nota come `str.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 01.4.4. Implementazione interna: Repetition & Padding

Nota come `str.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

## 01.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `str`

- **Garanzia algoritmica e di sicurezza**: Ripetizione in $O(\log N)$ tramite raddoppio di stringhe, predicati sicuri con sottostringhe vuote e zero mutazione in-place.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/str.rg` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test str.rg`.

### Le 5 Regole d'Oro quando programmi con `str`

1. **Dichiara `import str` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `str` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `str` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `str` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 02** passeremo a esplorare in profondità la lib **`math`** (La lib `math` — Aritmetica Sicura, Teoria dei Numeri e Statistica).
