# Capitolo 12: La lib `glob` — Pattern di Metacaratteri (`*`, `?`, `[a-z]`) e Filtraggio di Liste

## 12.1. Perché esiste la lib `glob`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `glob` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `glob`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: usare un'espressione regolare completa solo per verificare se un file termina con `*.rg` o inizia per `test_[0-9]*.rg` è come sparare alle mosche con un cannone.

La lib **`glob`** implementa la corrispondenza esatta dei metacaratteri da shell (`*`, `?`, classi `[a-z]`, classi negate `[!0-9]` / `[^a-z]`), varianti case-insensitive (`glob match ci`) e il filtraggio diretto di liste di percorsi o nomi.

In un ecosistema tradizionale, risolvere i compiti del dominio **`GLOB`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`glob`** (`src/main/ridgun/lib/glob.rg`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import glob` (o `import glob as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: glob` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `glob` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 12.2. Artefatti nativi, importazione e catalogo completo dell'API di `glob`

In `ridgun-libs`, **`glob`** è una **lib** di prima classe situata in `src/main/ridgun/lib/glob.rg` (dominio `GLOB`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/glob.rglib` | Distribuzione e importazione diretta con `import glob` |
| **File compilato** | `target/glob.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libglob.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: glob`: basta scrivere `import glob` (o `import glob as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 12.2.1. Riepilogo delle famiglie funzionali di `glob`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `glob match / glob match ci` | Corrispondenza di pattern glob case-sensitive e case-insensitive ASCII |
| `glob filter / glob any match` | Filtra `[String]` secondo un pattern o verifica se corrisponde almeno un pattern di una lista |
| `glob has magic` | Rileva se una stringa contiene metacaratteri jolly (`*`, `?`, `[`) |

### 12.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/glob.rg`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/glob.rg` (`0` tipi, `0` operatori e `18` funzioni):

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
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

## 12.3. Esplorare `glob` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `glob` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test glob.rg`.

### 12.3.1. Esempio 1: Flusso principale in stile tabulare con `glob`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `glob` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import glob

fn :: seleccionar fuentes ridgun [String] => [String]
      seleccionar fuentes ridgun archivos =
        glob filter "test_[a-z]*.rg" archivos
```

### 12.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `glob` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import glob

fn :: es ruta excluida String => Bool
      es ruta excluida ruta =
        glob any match ["*.tmp", "*.bak", "target/*"] ruta
```

### 12.3.3. Esempio 3: Metacaratteri `*` e `?`, corrispondenza esatta degli estremi e casi limite con pattern vuoti

In questo esempio pratico esploriamo in modo esaustivo come si comporta `glob` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 12.3.4. Esempio 4: Classi di caratteri `[a-z]`, intervalli negati `[!0-9]` / `[^0-9]` e corrispondenza case-insensitive (`glob match ci`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `glob` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 12.3.5. Esempio 5: Filtraggio massivo di liste di percorsi (`glob filter`) e verifica su pattern multipli (`glob any match`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `glob` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

## 12.4. Sotto il cofano: come è costruita `glob` in Ridgun puro (`src/main/ridgun/lib/glob.rg`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/glob.rg` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 12.4.1. Implementazione interna: Bracket Character Class `[...]` Matching

Nota come `glob.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 12.4.2. Implementazione interna: Wildcard (`*`, `?`, `[...]`) Matcher

Nota come `glob.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

## 12.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `glob`

- **Garanzia algoritmica e di sicurezza**: Collasso automatico di asterischi consecutivi (`***` $\rightarrow$ `*`) per evitare backtracking ridondante e gestione sicura delle parentesi quadre non chiuse `[`.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/glob.rg` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test glob.rg`.

### Le 5 Regole d'Oro quando programmi con `glob`

1. **Dichiara `import glob` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `glob` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `glob` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `glob` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 13** passeremo a esplorare in profondità la lib **`diff`** (La lib `diff` — Algoritmo LCS, Distanza di Modifica, Unified Diff e Patch).
