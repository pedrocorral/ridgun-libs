# Capitolo 17: La lib `path` — Normalizzazione POSIX (`path clean`) e Confinamento contro Path Traversal

## 17.1. Perché esiste la lib `path`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `path` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `path`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: unire percorsi con `base + "/" + file` senza ripulire i segmenti `..` né convalidare i prefissi è come lasciare la porta aperta a chiunque richieda `../../etc/passwd` sul tuo server web.

La lib **`path`** implementa la normalizzazione lessicale POSIX (`path clean` nello stile di `filepath.Clean` in Go), l'unione sicura (`path join`), la scomposizione (`dirname`, `basename`, `stem`, `ext`, `replace ext`) e il predicato di sicurezza **`path is safe subpath`** (`VUL-INJ-001`) contro le evasioni di directory.

In un ecosistema tradizionale, risolvere i compiti del dominio **`PATH`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`path`** (`src/main/ridgun/lib/path.ridgun`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import path` (o `import path as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: path` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `path` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 17.2. Artefatti nativi, importazione e catalogo completo dell'API di `path`

In `ridgun-libs`, **`path`** è una **lib** di prima classe situata in `src/main/ridgun/lib/path.ridgun` (dominio `PATH`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/path.ridgunlib` | Distribuzione e importazione diretta con `import path` |
| **File compilato** | `target/path.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libpath.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: path`: basta scrivere `import path` (o `import path as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 17.2.1. Riepilogo delle famiglie funzionali di `path`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `path clean / path join / path join list` | Collassa lessicalmente `//`, `.` e `..` e unisce i segmenti di percorso |
| `path dirname / path basename / path split` | Divide un percorso nella directory padre e nel nome file finale |
| `path ext / path stem / path replace ext` | Estrae o sostituisce l'estensione (trattando `.bashrc` come radice `.bashrc` ed estensione `""`) |
| `path is safe subpath : String -> String -> Bool` | Verifica che `rel` rimanga strettamente all'interno di `base_dir` e senza byte NUL |

### 17.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/path.ridgun`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/path.ridgun` (`0` tipi, `0` operatori e `30` funzioni):

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
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

## 17.3. Esplorare `path` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `path` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test path.ridgun`.

### 17.3.1. Esempio 1: Flusso principale in stile tabulare con `path`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `path` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import path

fn :: resolver archivo estatico String String => Bool String
      resolver archivo estatico raiz peticion =
        path is safe subpath raiz peticion -> seguro
        path join raiz peticion -> ruta
        (seguro, ruta)
```

### 17.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `path` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import path

fn :: cambiar salida a objeto String => String String String
      cambiar salida a objeto fuente =
        fuente path dirname -> dir
        fuente path stem -> nom
        fuente path clean -> limpio
        path with ext limpio ".ridgunlib" -> obj
        (dir, nom, obj)
```

### 17.3.3. Esempio 3: Normalizzazione lessicale POSIX (`path clean`) e unione sicura di segmenti (`path join`, `path join all`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `path` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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
        assert str eq (path join list ["src", "main", "ridgun", "lib", "path.ridgun"]) "src/main/ridgun/lib/path.ridgun" "AC1: join_list 5 segments"
        ()
```

### 17.3.4. Esempio 4: Scomposizione (`dirname`, `basename`, `ext`, `stem`) e confinamento contro *path traversal* (`path is safe rel`, `path resolve under`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `path` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test path components and confinement => ()
      test path components and confinement =
        p = "/home/boogie/ridgun-libs/src/socket.ridgun"
        assert true (path is abs p) "AC2: path_is_abs true"
        assert false (path is rel p) "AC2: path_is_rel false"
        assert false (path is abs "") "AC2: empty is not abs"
        assert true (path is rel "src/socket.ridgun") "AC2: relative path_is_rel"
        assert str eq (path dirname p) "/home/boogie/ridgun-libs/src" "AC2: dirname"
        assert str eq (path basename p) "socket.ridgun" "AC2: basename"
        sp = path split p
        assert str eq (pair fst sp) "/home/boogie/ridgun-libs/src" "AC2: split dirname"
        assert str eq (pair snd sp) "socket.ridgun" "AC2: split basename"
        assert str eq (path dirname "/") "/" "AC2: dirname of / is /"
        assert str eq (path basename "/") "/" "AC2: basename of / is /"
        assert str eq (path dirname "/top") "/" "AC2: dirname of /top is /"
        assert str eq (path dirname "barefile.txt") "." "AC2: dirname of bare filename is ."

        -- Multi-dot filenames, dotfiles, and extension replacement
        assert str eq (path stem p) "socket" "AC2: stem"
        assert str eq (path ext p) ".ridgun" "AC2: ext"
        assert str eq (path stem "archive.tar.gz") "archive.tar" "AC2: multi-dot stem"
        assert str eq (path ext "archive.tar.gz") ".gz" "AC2: multi-dot ext"
        assert str eq (path stem ".gitignore") ".gitignore" "AC2: dotfile stem"
        assert str eq (path ext ".gitignore") "" "AC2: dotfile empty ext"
        assert str eq (path replace ext p "ridgunlib") "/home/boogie/ridgun-libs/src/socket.ridgunlib" "AC2: replace_ext without leading dot"
        assert str eq (path replace ext p ".so") "/home/boogie/ridgun-libs/src/socket.so" "AC2: replace_ext with leading dot"
        assert str eq (path replace ext "main.ridgun" "") "main" "AC2: replace_ext with empty removes extension"

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

### 17.3.5. Esempio 5: Risolutore di file statici in *sandbox*: validazione contro risalite `..`, byte nulli ed estrazione di `dirname`/`basename`/`ext`/`stem`

In questo esempio pratico esploriamo in modo esaustivo come si comporta `path` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

## 17.4. Sotto il cofano: come è costruita `path` in Ridgun puro (`src/main/ridgun/lib/path.ridgun`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/path.ridgun` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 17.4.1. Implementazione interna: Core Implementation Part 1

Nota come `path.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 17.4.2. Implementazione interna: Core Implementation Part 2

Nota come `path.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 17.4.3. Implementazione interna: Core Implementation Part 4

Nota come `path.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 17.4.4. Implementazione interna: Core Implementation Part 5

Nota come `path.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

## 17.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `path`

- **Garanzia algoritmica e di sicurezza**: `path is safe subpath` rifiuta percorsi assoluti, byte NUL e qualsiasi sequenza `..` che tenti di uscire dalla directory radice o di accedere a un prefisso fratello (`/srv/www-secret`).
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/path.ridgun` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test path.ridgun`.

### Le 5 Regole d'Oro quando programmi con `path`

1. **Dichiara `import path` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `path` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `path` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `path` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 18** passeremo a esplorare in profondità la lib **`time`** (La lib `time` — Calendario Civile UTC (Hinnant), ISO-8601, Durate e Backoff).
