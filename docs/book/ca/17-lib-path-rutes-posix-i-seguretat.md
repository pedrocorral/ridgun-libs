# Capítol 17: La lib `path` — Normalització POSIX (`path clean`) i Confinament contra Path Traversal

## 17.1. Per què existeix la lib `path`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `path` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `path`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: unir rutes amb `base + "/" + fitxer` sense netejar segments `..` ni validar prefixos és com deixar la porta oberta perquè algú demani `../../etc/passwd` al teu servidor web.

La lib **`path`** implementa normalització lèxica POSIX (`path clean` a l'estil `filepath.Clean` de Go), unió segura (`path join`), descomposició (`dirname`, `basename`, `stem`, `ext`, `replace ext`) i el predicat de seguretat **`path is safe subpath`** (`VUL-INJ-001`) contra escapaments de directori.

En un ecosistema tradicional, resoldre les tasques del domini **`PATH`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`path`** (`src/main/ridgun/lib/path.rg`) aborda el problema amb quatre principis innegociables:

1. **Declara `import path` (o `import path as alias`) a l'inici del fitxer**: cada lib defineix el seu espai de noms `module :: path` i en mode `--strict` les funcions multi-paraula s'invoquen sempre amb espais naturals.
2. **Encadena les teves canonades d'esquerra a dreta amb `->`**: escriu `entrada pas u -> pas dos -> resultat`, fes servir màscares `(+ _ _ +)` per desestructurar seqüències i omet `_ =` en sentències seqüencials (o descarta amb `-> ()`).
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `path` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 17.2. Artefactes natius, importació i catàleg complet de l'API de `path`

A `ridgun-libs`, **`path`** és una **lib** de primera classe situada a `src/main/ridgun/lib/path.rg` (domini `PATH`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/path.rglib` | Distribució i importació directa amb `import path` |
| **Fitxer compilat** | `target/path.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libpath.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Cada lib declara el seu propi espai de noms amb `module :: path`: n'hi ha prou d'escriure `import path` (o `import path as alias`) a la capçalera i cridar les seves funcions amb espais naturals (`la meva funcio x`) i canonades `->` (`x la meva funcio -> resultat`).

### 17.2.1. Resum de famílies funcionals de `path`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `path clean / path join / path join list` | Col·lapsa `//`, `.` i `..` lèxicament i uneix segments de ruta |
| `path dirname / path basename / path split` | Divideix una ruta en directori pare i nom de fitxer final |
| `path ext / path stem / path replace ext` | Extreu o canvia l'extensió (tractant `.bashrc` com a arrel `.bashrc` i ext `""`) |
| `path is safe subpath : String -> String -> Bool` | Verifica que `rel` romangui estrictament dins de `base_dir` i sense bytes NUL |

### 17.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/path.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/path.rg` (`0` tipus, `0` operadors i `30` funcions):

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 17.3. Explorant `path` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `path` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test path.rg`.

### 17.3.1. Exemple 1: Flux principal en estil tabular amb `path`

Observa com en Ridgun els signes `=` i els passos de transformació amb `path` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import path

fn :: resolver archivo estatico String String => Bool String
      resolver archivo estatico raiz peticion =
        path is safe subpath raiz peticion -> seguro
        path join raiz peticion -> ruta
        (seguro, ruta)
```

### 17.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `path` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

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

### 17.3.3. Exemple 3: Normalització lèxica POSIX (`path clean`) i unió segura de segments (`path join`, `path join all`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `path` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 17.3.4. Exemple 4: Descomposició (`dirname`, `basename`, `ext`, `stem`) i confinament contra *path traversal* (`path is safe rel`, `path resolve under`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `path` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 17.3.5. Exemple 5: Resoledor de fitxers estàtics en *sandbox*: validació contra salts `..`, bytes nuls i extracció de `dirname`/`basename`/`ext`/`stem`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `path` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

## 17.4. Sota el capó: com està construïda `path` en Ridgun pur (`src/main/ridgun/lib/path.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/path.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 17.4.1. Implementació interna: Core Implementation Part 1

Fixa't en com `path.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 17.4.2. Implementació interna: Core Implementation Part 2

Fixa't en com `path.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 17.4.3. Implementació interna: Core Implementation Part 4

Fixa't en com `path.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 17.4.4. Implementació interna: Core Implementation Part 5

Fixa't en com `path.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

## 17.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `path`

- **Garantia algorísmica i de seguretat**: `path is safe subpath` rebutja rutes absolutes, bytes NUL i qualsevol seqüència `..` que intenti escapar del directori arrel o d'un prefix germà (`/srv/www-secret`).
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/path.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test path.rg`.

### Les 5 Regles d'Or en programar amb `path`

1. **Declara `import path` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `path` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `path` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `path` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 18** passarem a explorar en profunditat la lib **`time`** (La lib `time` — Calendari Civil UTC (Hinnant), ISO-8601, Durades i Backoff).
