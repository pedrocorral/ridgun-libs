# Capítol 12: La lib `glob` — Patrons de Comodins (`*`, `?`, `[a-z]`) i Filtratge de Llistes

## 12.1. Per què existeix la lib `glob`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `glob` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `glob`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: fer servir una expressió regular completa només per comprovar si un fitxer acaba en `*.rg` o comença per `test_[0-9]*.rg` és matar mosques a canonades.

La lib **`glob`** implementa coincidència exacta de comodins de shell (`*`, `?`, classes `[a-z]`, classes negades `[!0-9]` / `[^a-z]`), variants insensibles a majúscules (`glob match ci`) i filtratge directe de llistes de rutes o noms.

En un ecosistema tradicional, resoldre les tasques del domini **`GLOB`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`glob`** (`src/main/ridgun/lib/glob.rg`) aborda el problema amb quatre principis innegociables:

1. **Declara `import glob` (o `import glob as alias`) a l'inici del fitxer**: cada lib defineix el seu espai de noms `module :: glob` i en mode `--strict` les funcions multi-paraula s'invoquen sempre amb espais naturals.
2. **Encadena les teves canonades d'esquerra a dreta amb `->`**: escriu `entrada pas u -> pas dos -> resultat`, fes servir màscares `(+ _ _ +)` per desestructurar seqüències i omet `_ =` en sentències seqüencials (o descarta amb `-> ()`).
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `glob` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 12.2. Artefactes natius, importació i catàleg complet de l'API de `glob`

A `ridgun-libs`, **`glob`** és una **lib** de primera classe situada a `src/main/ridgun/lib/glob.rg` (domini `GLOB`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/glob.rglib` | Distribució i importació directa amb `import glob` |
| **Fitxer compilat** | `target/glob.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libglob.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Cada lib declara el seu propi espai de noms amb `module :: glob`: n'hi ha prou d'escriure `import glob` (o `import glob as alias`) a la capçalera i cridar les seves funcions amb espais naturals (`la meva funcio x`) i canonades `->` (`x la meva funcio -> resultat`).

### 12.2.1. Resum de famílies funcionals de `glob`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `glob match / glob match ci` | Coincidència de patrons glob sensible i insensible a majúscules ASCII |
| `glob filter / glob any match` | Filtra `[String]` segons un patró o comprova si coincideix algun patró d'una llista |
| `glob has magic` | Detecta si una cadena conté metacaràcters de comodí (`*`, `?`, `[`) |

### 12.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/glob.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/glob.rg` (`0` tipus, `0` operadors i `18` funcions):

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
|---|---|---|
| `1` | `fn :: gl lower char String Int Int` | `String` |
| `2` | `fn :: gl to lower loop String Int Int` | `String` |
| `3` | `fn :: gl to lower String` | `String` |
| `4` | `fn :: gl find close bracket String Int Int` | `Int` |
| `5` | `fn :: gl match range String Int Int Int Int Int` | `Bool` |
| `6` | `fn :: gl match class body String Int Int Int` | `Bool` |
| `7` | `fn :: gl eval bracket char String Int Int Int Int` | `Bool` |
| `8` | `fn :: gl eval bracket String Int Int Int` | `Bool` |
| `9` | `fn :: gl skip stars String Int Int` | `Int` |
| `10` | `fn :: gl match star String Int Int String Int Int` | `Bool` |
| `11` | `fn :: gl match star at String Int Int String Int Int` | `Bool` |
| `12` | `fn :: gl match bracket step String Int Int String Int Int Int` | `Bool` |
| `13` | `fn :: gl match step String Int Int String Int Int Int` | `Bool` |
| `14` | `fn :: gl match loop String Int Int String Int Int` | `Bool` |
| `15` | `fn :: glob match String String` | `Bool` |
| `16` | `fn :: glob match ci String String` | `Bool` |
| `17` | `fn :: glob filter String [String]` | `[String]` |
| `18` | `fn :: glob any match [String] String` | `Bool` |

---

## 12.3. Explorant `glob` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `glob` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test glob.rg`.

### 12.3.1. Exemple 1: Flux principal en estil tabular amb `glob`

Observa com en Ridgun els signes `=` i els passos de transformació amb `glob` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import glob

fn :: seleccionar fuentes ridgun [String] => [String]
      seleccionar fuentes ridgun archivos =
        glob filter "test_[a-z]*.rg" archivos
```

### 12.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `glob` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import glob

fn :: es ruta excluida String => Bool
      es ruta excluida ruta =
        glob any match ["*.tmp", "*.bak", "target/*"] ruta
```

### 12.3.3. Exemple 3: Comodins `*` i `?`, coincidència exacta d'extrems i casos límit amb patrons buits

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `glob` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test glob wildcards and boundaries => ()
      test glob wildcards and boundaries =
        assert true (glob match "" "") "AC1: empty pattern matches empty string"
        assert false (glob match "" "a") "AC1: empty pattern rejects non-empty"
        assert true (glob match "*" "") "AC1: * matches empty string"
        assert true (glob match "***" "") "AC1: *** matches empty string"
        assert true (glob match "*" "anything.rg") "AC1: * matches full filename"
        assert true (glob match "*.rg" "socket.rg") "AC1: *.rg matches socket.rg"
        assert true (glob match "*.rg" ".rg") "AC1: *.rg matches leading dot .rg"
        assert false (glob match "*.rg" "README.md") "AC1: *.rg rejects README.md"
        assert false (glob match "*.rg" "socket.rg.bak") "AC1: *.rg rejects trailing suffix"
        assert true (glob match "test_?.rg" "test_a.rg") "AC1: ? matches single char"
        assert false (glob match "test_?.rg" "test_.rg") "AC1: ? rejects zero chars"
        assert false (glob match "test_?.rg" "test_ab.rg") "AC1: ? rejects two chars"
        assert true (glob match "???" "abc") "AC1: ??? matches 3 chars"
        assert false (glob match "???" "ab") "AC1: ??? rejects 2 chars"
        assert true (glob match "a*b*c" "abc") "AC1: multiple * matching zero chars"
        assert true (glob match "a*b*c" "axxxbyyyc") "AC1: multiple * matching substrings"
        assert true (glob match "a*b*c" "abbc") "AC1: backtracking * across repeated b"
        assert false (glob match "a*b*c" "axxxbyyy") "AC1: missing trailing literal after *"
        assert true (glob match "a***b" "axyzb") "AC1: collapsed *** matches"
        -- Pathological backtracking immunity via gl skip stars
        assert false (glob match "****************a" "bbbbbbbbbbbbbbbbbbbbbbbbbbbb") "AC1: collapsed stars avoid exponential backtracking"
        ()
```

### 12.3.4. Exemple 4: Classes de caràcters `[a-z]`, rangs negats `[!0-9]` / `[^0-9]` i coincidència insensible a majúscules (`glob match ci`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `glob` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test glob classes and case insensitivity => ()
      test glob classes and case insensitivity =
        assert true (glob match "file_[0-9].txt" "file_0.txt") "AC2: [0-9] lower bound 0"
        assert true (glob match "file_[0-9].txt" "file_9.txt") "AC2: [0-9] upper bound 9"
        assert false (glob match "file_[0-9].txt" "file_a.txt") "AC2: [0-9] rejects alpha"
        assert true (glob match "id_[a-zA-Z0-9].rg" "id_Z.rg") "AC2: multi-range [a-zA-Z0-9] matches Z"
        assert true (glob match "id_[a-zA-Z0-9].rg" "id_5.rg") "AC2: multi-range [a-zA-Z0-9] matches 5"
        assert false (glob match "id_[a-zA-Z0-9].rg" "id__.rg") "AC2: multi-range [a-zA-Z0-9] rejects _"
        assert true (glob match "v[135].rg" "v3.rg") "AC2: discrete character set [135]"
        assert false (glob match "v[135].rg" "v2.rg") "AC2: discrete character set rejects 2"
        assert true (glob match "file_[!0-9].txt" "file_a.txt") "AC2: [!0-9] POSIX negated class"
        assert false (glob match "file_[!0-9].txt" "file_7.txt") "AC2: [!0-9] rejects digit"
        assert true (glob match "file_[^0-9].txt" "file_z.txt") "AC2: [^0-9] caret negated class"
        assert false (glob match "file_[^0-9].txt" "file_0.txt") "AC2: [^0-9] rejects digit"
        assert true (glob match "a[b" "a[b") "AC2: unclosed '[' matches literally"
        assert false (glob match "a[b" "axb") "AC2: unclosed '[' rejects non-bracket"

        -- Case-insensitive matching
        assert true (glob match ci "*.RG" "socket.rg") "AC2: glob_match_ci *.RG on lowercase"
        assert true (glob match ci "*.rg" "SOCKET.RG") "AC2: glob_match_ci *.rg on uppercase"
        assert true (glob match ci "src/**/Test_[A-Z]*.rg" "SRC/main/test_crypto.RG") "AC2: glob_match_ci mixed case"
        ()
```

### 12.3.5. Exemple 5: Filtratge massiu de llistes de rutes (`glob filter`) i comprovació contra múltiples patrons (`glob any match`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `glob` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test glob filter and any match => ()
      test glob filter and any match =
        files = ["socket.rg", "README.md", "test_socket.rg", "crypto.rg", "build.sh"]
        assert eq (glob filter "*.rg" files) ["socket.rg", "test_socket.rg", "crypto.rg"]
        assert eq (glob filter "test_*.rg" files) ["test_socket.rg"]
        assert eq (glob filter "*.nomatch" files) []
        assert eq (glob filter "*.rg" []) []
        assert true (glob any match ["*.md", "*.txt", "*.sh"] "README.md") "AC3: glob_any_match first pattern"
        assert true (glob any match ["*.md", "*.txt", "*.sh"] "build.sh") "AC3: glob_any_match last pattern"
        assert false (glob any match ["*.md", "*.txt"] "socket.rg") "AC3: glob_any_match no match"
        assert false (glob any match [] "socket.rg") "AC3: glob_any_match empty pattern list"
        ()
```

---

## 12.4. Sota el capó: com està construïda `glob` en Ridgun pur (`src/main/ridgun/lib/glob.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/glob.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 12.4.1. Implementació interna: Bracket Character Class `[...]` Matching

Fixa't en com `glob.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
module :: glob

fn :: gl find close bracket String Int Int => Int
      gl find close bracket pat idx plen =
        | idx >= plen                  = 0 - 1
        | (str char at pat idx) == 93  = idx
        | otherwise                    = gl find close bracket pat (idx + 1) plen

fn :: gl match range String Int Int Int Int Int => Bool
      gl match range pat idx end_idx tc lo hi =
        | tc >= lo and tc <= hi = True
        | otherwise             = gl match class body pat (idx + 3) end_idx tc

fn :: gl match class body String Int Int Int => Bool
      gl match class body pat idx end_idx tc =
        | idx >= end_idx = False
        | ((idx + 2) < end_idx) and ((str char at pat (idx + 1)) == 45) =
          gl match range pat idx end_idx tc (str char at pat idx) (str char at pat (idx + 2))
        | (str char at pat idx) == tc = True
        | otherwise                   = gl match class body pat (idx + 1) end_idx tc

fn :: gl eval bracket char String Int Int Int Int => Bool
      gl eval bracket char pat pstart close_idx tc c0 =
        | c0 == 33 or c0 == 94 = not (gl match class body pat (pstart + 1) close_idx tc)
        | otherwise            = gl match class body pat pstart close_idx tc

fn :: gl eval bracket String Int Int Int => Bool
      gl eval bracket pat pstart close_idx tc =
        gl eval bracket char pat pstart close_idx tc (str char at pat pstart)
```

### 12.4.2. Implementació interna: Wildcard (`*`, `?`, `[...]`) Matcher

Fixa't en com `glob.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
fn :: gl skip stars String Int Int => Int
      gl skip stars pat pidx plen =
        | pidx >= plen                 = pidx
        | (str char at pat pidx) == 42 = gl skip stars pat (pidx + 1) plen
        | otherwise                    = pidx

fn :: gl match star String Int Int String Int Int => Bool
      gl match star pat pidx plen txt tidx tlen =
        | gl match loop pat pidx plen txt tidx tlen = True
        | tidx >= tlen                              = False
        | otherwise                                 = gl match star pat pidx plen txt (tidx + 1) tlen

fn :: gl match star at String Int Int String Int Int => Bool
      gl match star at pat next_p plen txt tidx tlen =
        | next_p >= plen = True
        | otherwise      = gl match star pat next_p plen txt tidx tlen

fn :: gl match bracket step String Int Int String Int Int Int => Bool
      gl match bracket step pat pidx plen txt tidx tlen close_idx =
        | close_idx < 0 =
          | (str char at txt tidx) == 91 = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
          | otherwise                    = False |.
        | gl eval bracket pat (pidx + 1) close_idx (str char at txt tidx) =
          gl match loop pat (close_idx + 1) plen txt (tidx + 1) tlen
        | otherwise = False

fn :: gl match step String Int Int String Int Int Int => Bool
      gl match step pat pidx plen txt tidx tlen pc =
        | pc == 42                     = gl match star at pat (gl skip stars pat (pidx + 1) plen) plen txt tidx tlen
        | tidx >= tlen                 = False
        | pc == 63                     = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
        | pc == 91                     = gl match bracket step pat pidx plen txt tidx tlen (gl find close bracket pat (pidx + 1) plen)
        | pc == (str char at txt tidx) = gl match loop pat (pidx + 1) plen txt (tidx + 1) tlen
        | otherwise                    = False

fn :: gl match loop String Int Int String Int Int => Bool
      gl match loop pat pidx plen txt tidx tlen =
        | pidx >= plen = tidx >= tlen
        | otherwise    = gl match step pat pidx plen txt tidx tlen (str char at pat pidx)

fn :: glob match String String => Bool
      glob match pat    txt    =  gl match loop pat 0 (str len pat) txt 0 (str len txt)

fn :: glob match ci String String => Bool
      glob match ci pat    txt    =
        pat gl to lower -> lpat
        txt gl to lower -> ltxt
        glob match lpat ltxt

fn :: glob filter String [String] => [String]
      glob filter _      []       =  []
      glob filter pat    (x:rest) =
        | glob match pat x = [x] :: (glob filter pat rest)
        | otherwise        = glob filter pat rest

fn :: glob any match [String] String => Bool
      glob any match []       _      =  False
      glob any match (p:rest) txt    =
        | glob match p txt = True
        | otherwise        = glob any match rest txt
```

---

## 12.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `glob`

- **Garantia algorísmica i de seguretat**: Col·lapse automàtic d'estrelles consecutives (`***` $\rightarrow$ `*`) per evitar retrocessos redundants i maneig segur de claudàtors sense tancar `[`.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/glob.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test glob.rg`.

### Les 5 Regles d'Or en programar amb `glob`

1. **Declara `import glob` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `glob` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `glob` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `glob` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 13** passarem a explorar en profunditat la lib **`diff`** (La lib `diff` — Algorisme LCS, Distància d'Edició, Unified Diff i Pedaços).
