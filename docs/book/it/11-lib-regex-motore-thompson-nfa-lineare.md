# Capitolo 11: La lib `regex` — Motore di Espressioni Regolari Thompson NFA in Tempo Lineare $O(N \cdot M)$

## 11.1. Perché esiste la lib `regex`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `regex` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `regex`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: i motori di espressioni regolari basati su *backtracking* hanno causato famosi disservizi globali (come in Cloudflare o StackOverflow) quando un pattern come `(a+)+b` riceve trenta `a` consecutive ed entra in tempo esponenziale $O(2^N)$.

La lib **`regex`** compila le espressioni regolari (`.`, `*`, `+`, `?`, `|`, `()`, `[a-z]`, `[^...]`, `^`, `$`, `\d`, `\w`, `\s`) in un **automa finito non deterministico di Thompson (NFA)** e fa avanzare l'insieme degli stati passo dopo passo in tempo strettamente lineare **$O(N \cdot M)$**, rendendo gli attacchi **ReDoS matematicamente impossibili**.

In un ecosistema tradizionale, risolvere i compiti del dominio **`REGEX`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`regex`** (`src/main/ridgun/lib/regex.rg`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import regex` (o `import regex as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: regex` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `regex` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 11.2. Artefatti nativi, importazione e catalogo completo dell'API di `regex`

In `ridgun-libs`, **`regex`** è una **lib** di prima classe situata in `src/main/ridgun/lib/regex.rg` (dominio `REGEX`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/regex.rglib` | Distribuzione e importazione diretta con `import regex` |
| **File compilato** | `target/regex.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libregex.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: regex`: basta scrivere `import regex` (o `import regex as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 11.2.1. Riepilogo delle famiglie funzionali di `regex`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `regex match / regex is match` | Corrispondenza sull'intera stringa e ricerca di sottostringa in tempo lineare $O(N \cdot M)$ |
| `regex find / regex find all` | Estrae la prima o tutte le sottostringhe corrispondenti senza sovrapposizioni |
| `regex replace / regex replace all` | Sostituisce la prima o tutte le corrispondenze dell'espressione regolare |
| `regex split / regex escape` | Divide il testo secondo un delimitatore regex ed esegue l'escape dei metacaratteri |

### 11.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/regex.rg`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/regex.rg` (`4` tipi, `0` operatori e `70` funzioni):

**Tipi algebrici e record (`type`) di `regex`:**

```ridgun
type RegexMatch = matched: Bool, match_start: Int, match_end: Int, text: String
type ReNode = ReEmpty | ReChar Int | ReAny | ReClass Bool [Int] | ReShort Int | ReBol | ReEol | ReStar ReNode | RePlus ReNode | ReOpt ReNode | ReSeq ReNode ReNode | ReAlt ReNode ReNode
type ReParseRes = ReParseRes ReNode Int
type NfaInst = InstChar Int Int | InstAny Int | InstClass Bool [Int] Int | InstShort Int Int | InstBol Int | InstEol Int | InstSplit Int Int | InstJump Int | InstMatch
```

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
|---|---|---|
| `1` | `fn :: re is digit Int` | `Bool` |
| `2` | `fn :: re is word Int` | `Bool` |
| `3` | `fn :: re is space Int` | `Bool` |
| `4` | `fn :: re match short Int Int` | `Bool` |
| `5` | `fn :: re in ranges Int [Int]` | `Bool` |
| `6` | `fn :: re escape char Int` | `ReNode` |
| `7` | `fn :: re class char String Int Int` | `(Int Int)` |
| `8` | `fn :: re fst int (Int Int)` | `Int` |
| `9` | `fn :: re snd int (Int Int)` | `Int` |
| `10` | `fn :: re parse class items String Int Int [Int]` | `([Int] Int)` |
| `11` | `fn :: re parse class item step String Int Int [Int]` | `([Int] Int)` |
| `12` | `fn :: re parse class range check String Int Int Int [Int]` | `([Int] Int)` |
| `13` | `fn :: re parse class range hi String Int Int Int [Int]` | `([Int] Int)` |
| `14` | `fn :: re fst ranges ([Int] Int)` | `[Int]` |
| `15` | `fn :: re snd pos ([Int] Int)` | `Int` |
| `16` | `fn :: re parse class String Int Int` | `ReParseRes` |
| `17` | `fn :: re finish class Bool ([Int] Int)` | `ReParseRes` |
| `18` | `fn :: re res node ReParseRes` | `ReNode` |
| `19` | `fn :: re res pos ReParseRes` | `Int` |
| `20` | `fn :: re parse group String Int Int` | `ReParseRes` |
| `21` | `fn :: re close group ReNode String Int Int` | `ReParseRes` |
| `22` | `fn :: re parse atom String Int Int` | `ReParseRes` |
| `23` | `fn :: re parse postfix ReNode String Int Int` | `ReParseRes` |
| `24` | `fn :: re parse factor String Int Int` | `ReParseRes` |
| `25` | `fn :: re is seq stop Int` | `Bool` |
| `26` | `fn :: re parse seq loop ReNode String Int Int` | `ReParseRes` |
| `27` | `fn :: re parse seq step ReNode String Int Int` | `ReParseRes` |
| `28` | `fn :: re parse seq String Int Int` | `ReParseRes` |
| `29` | `fn :: re parse seq first String Int Int` | `ReParseRes` |
| `30` | `fn :: re parse alt loop ReNode String Int Int` | `ReParseRes` |
| `31` | `fn :: re parse alt branch ReNode String Int Int` | `ReParseRes` |
| `32` | `fn :: re parse alt String Int Int` | `ReParseRes` |
| `33` | `fn :: nfa len [NfaInst]` | `Int` |
| `34` | `fn :: re compile seq ReNode ReNode Int` | `[NfaInst]` |
| `35` | `fn :: re compile opt ReNode Int` | `[NfaInst]` |
| `36` | `fn :: re compile star ReNode Int` | `[NfaInst]` |
| `37` | `fn :: re compile plus ReNode Int` | `[NfaInst]` |
| `38` | `fn :: re compile alt ReNode ReNode Int` | `[NfaInst]` |
| `39` | `fn :: re compile node ReNode Int` | `[NfaInst]` |
| `40` | `fn :: re compile String` | `[NfaInst]` |
| `41` | `fn :: nfa inst at [NfaInst] Int` | `NfaInst` |
| `42` | `fn :: nfa set has [Int] Int` | `Bool` |
| `43` | `fn :: nfa closure [NfaInst] [Int] Int Int [Int]` | `[Int]` |
| `44` | `fn :: nfa closure inst [NfaInst] Int [Int] Int Int [Int] NfaInst` | `[Int]` |
| `45` | `fn :: nfa step one NfaInst Int` | `[Int]` |
| `46` | `fn :: nfa step [NfaInst] [Int] Int` | `[Int]` |
| `47` | `fn :: nfa is match inst NfaInst` | `Bool` |
| `48` | `fn :: nfa has match [NfaInst] [Int]` | `Bool` |
| `49` | `fn :: nfa update last [NfaInst] [Int] Int Int` | `Int` |
| `50` | `fn :: nfa sim loop [NfaInst] String Int Int [Int] Int` | `Int` |
| `51` | `fn :: nfa sim step [NfaInst] String Int Int [Int] Int` | `Int` |
| `52` | `fn :: nfa longest from [NfaInst] String Int Int` | `Int` |
| `53` | `fn :: nfa full loop [NfaInst] String Int Int [Int]` | `Bool` |
| `54` | `fn :: nfa full step [NfaInst] String Int Int [Int]` | `Bool` |
| `55` | `fn :: regex match String String` | `Bool` |
| `56` | `fn :: nfa find from [NfaInst] String Int Int` | `RegexMatch` |
| `57` | `fn :: nfa find check [NfaInst] String Int Int Int` | `RegexMatch` |
| `58` | `fn :: regex find String String` | `RegexMatch` |
| `59` | `fn :: regex is match String String` | `Bool` |
| `60` | `fn :: nfa find all loop [NfaInst] String Int Int [RegexMatch]` | `[RegexMatch]` |
| `61` | `fn :: nfa find all step [NfaInst] String Int Int [RegexMatch] Int` | `[RegexMatch]` |
| `62` | `fn :: regex find all String String` | `[RegexMatch]` |
| `63` | `fn :: regex replace String String String` | `String` |
| `64` | `fn :: re apply replace RegexMatch String String` | `String` |
| `65` | `fn :: nfa replace all loop [NfaInst] String String Int Int String` | `String` |
| `66` | `fn :: nfa replace all step [NfaInst] String String Int Int String Int` | `String` |
| `67` | `fn :: regex replace all String String String` | `String` |
| `68` | `fn :: nfa split loop [NfaInst] String Int Int Int [String]` | `[String]` |
| `69` | `fn :: nfa split step [NfaInst] String Int Int Int [String] Int` | `[String]` |
| `70` | `fn :: regex split String String` | `[String]` |

---

## 11.3. Esplorare `regex` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `regex` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test regex.rg`.

### 11.3.1. Esempio 1: Flusso principale in stile tabulare con `regex`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `regex` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import regex

fn :: extraer codigos postales String => [String]
      extraer codigos postales texto =
        regex find all "\d+" texto
```

### 11.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `regex` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import regex

fn :: censurar telefonos String => Bool String
      censurar telefonos comentario =
        regex is match "\d+-\d+" comentario -> tiene
        regex replace all "\d+-\d+" comentario "[TELEFONO]" -> limpio
        (tiene, limpio)
```

### 11.3.3. Esempio 3: Ancore (`^`, `$`), quantificatori (`*`, `+`, `?`), alternanza (`|`), gruppi `(...)`, classi `[a-z0-9]` e scorciatoie (`\d`, `\w`, `\s`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `regex` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test regex operators and classes => ()
      test regex operators and classes =
        assert true (regex match "" "") "AC1: empty pattern matches empty string"
        assert false (regex match "" "nonempty") "AC1: empty pattern rejects non-empty on full match"
        assert true (regex match 'a(b|c)+d?e*' "abcbdeee") "AC1: alternation group plus opt star"
        assert true (regex match 'a(b|c)+d?e*' "ac") "AC1: opt and star match zero occurrences"
        assert false (regex match 'a(b|c)+d?e*' "ade") "AC1: plus requires at least one"
        assert true (regex match '(foo|bar|baz)+' "barfoobazbar") "AC1: multi-branch alternation with plus"
        assert false (regex match '(foo|bar|baz)+' "barquxfoo") "AC1: multi-branch alternation rejects unknown"
        assert true (regex match '[a-zA-Z_][a-zA-Z0-9_]*' "_valid_Identifier_99") "AC1: identifier character class"
        assert false (regex match '[a-zA-Z_][a-zA-Z0-9_]*' "9invalid") "AC1: identifier rejects leading digit"
        assert true (regex match '[^0-9]+' "hello_world") "AC1: negated char class"
        assert false (regex match '[^0-9]+' "hello42") "AC1: negated char class rejects digits"
        assert true (regex match '\w+\s+\d+' "agent   007") "AC1: shorthand escapes \\w \\s \\d"
        assert true (regex match '\D+\S+' "abc_123") "AC1: negated shorthand escapes \\D \\S"
        assert true (regex match 'v\d+\.\d+\.\d+' "v0.9.16") "AC1: escaped dot literal"
        assert false (regex match 'v\d+\.\d+\.\d+' "v0X9Y16") "AC1: escaped dot rejects non-dot"
        assert true (regex is match '^hello' "hello world") "AC1: bol anchor matches start"
        assert false (regex is match '^world' "hello world") "AC1: bol anchor rejects middle"
        assert true (regex is match 'world$' "hello world") "AC1: eol anchor matches end"
        assert false (regex is match 'hello$' "hello world") "AC1: eol anchor rejects prefix"
        assert true (regex is match '^exact$' "exact") "AC1: anchored ^exact$ matches full string"
        assert false (regex is match '^exact$' "not exact") "AC1: anchored ^exact$ rejects extra chars"
        -- Russ Cox pathological backtracking benchmarks (exponential in backtracking engines, O(N*M) in Thompson NFA)
        assert false (regex match '(a+)+b' "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaac") "AC1: Thompson NFA immune to (a+)+b ReDoS"
        assert false (regex match '(a|aa)+b' "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaac") "AC1: Thompson NFA immune to (a|aa)+b ReDoS"
        assert true (regex match 'a?a?a?a?a?a?a?a?aaaaaaaa' "aaaaaaaa") "AC1: Russ Cox a?^n a^n vector"
        ()
```

### 11.3.4. Esempio 4: Estrazione di corrispondenze (`regex find`, `regex find all`), sostituzione (`regex replace`, `regex replace all`) e divisione (`regex split`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `regex` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test regex find replace split => ()
      test regex find replace split =
        m1 = regex find '\d+' "item #42 and #99"
        assert true (matched m1) "AC2: find matched"
        assert int equals (match_start m1) 6 "AC2: find start"
        assert int equals (match_end m1) 8 "AC2: find end"
        assert str eq (text m1) "42" "AC2: find text"

        m_none = regex find '\d+' "no digits here"
        assert false (matched m_none) "AC2: find returns matched=False when absent"

        all_m = regex find all '[a-z]+=\d+' "id=10, port=8080, ttl=60"
        assert int equals (re match count all_m) 3 "AC2: find all key=val count"
        assert str eq (text (re match at all_m 0)) "id=10" "AC2: find all first match"
        assert str eq (text (re match at all_m 1)) "port=8080" "AC2: find all second match"
        assert str eq (text (re match at all_m 2)) "ttl=60" "AC2: find all third match"

        r1 = regex replace '\d+' "X" "v1.2.3"
        assert str eq r1 "vX.2.3" "AC3: replace first"
        r_no = regex replace '\d+' "X" "abc"
        assert str eq r_no "abc" "AC3: replace with no match returns original"
        r2 = regex replace all '\d+' "X" "v1.22.333"
        assert str eq r2 "vX.X.X" "AC3: replace all"

        parts = regex split '\s*[,;]\s*' "alpha, beta ;  gamma,delta"
        assert int equals (re str count parts) 4 "AC3: split count"
        assert str eq (re str at parts 0) "alpha" "AC3: split[0]"
        assert str eq (re str at parts 1) "beta" "AC3: split[1]"
        assert str eq (re str at parts 2) "gamma" "AC3: split[2]"
        assert str eq (re str at parts 3) "delta" "AC3: split[3]"
        ()
```

### 11.3.5. Esempio 5: Validatore di identificatori e anonimizzatore di log in tempo lineare $O(N \cdot M)$ con Thompson NFA (`regex is match`, `regex replace all`, `regex split`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `regex` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
import regex

fn :: limpiar traza y validar id (usuario_id : String) (linea_log : String) => (Bool, String, [String])
      limpiar traza y validar id usuario_id linea_log =
        id_valido = regex is match "^usr_[a-z0-9]+$" usuario_id
        sin_ips   = regex replace all "\d+\.\d+\.\d+\.\d+" linea_log "[IP-REDACTADA]"
        tokens    = regex split "\s+" sin_ips
        (id_valido, sin_ips, tokens)
```

---

## 11.4. Sotto il cofano: come è costruita `regex` in Ridgun puro (`src/main/ridgun/lib/regex.rg`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/regex.rg` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 11.4.1. Implementazione interna: Character Class & Shorthand Helpers

Nota come `regex.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
module :: regex

fn :: re is digit Int => Bool
      re is digit c = c >= 48 and c <= 57

fn :: re is word Int => Bool
      re is word c = (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95

fn :: re is space Int => Bool
      re is space c = c == 32 or c == 9 or c == 10 or c == 13 or c == 11 or c == 12

fn :: re match short Int Int => Bool
      re match short 100 c = re is digit c
      re match short 68 c = not (re is digit c)
      re match short 119 c = re is word c
      re match short 87 c = not (re is word c)
      re match short 115 c = re is space c
      re match short 83 c = not (re is space c)
      re match short _ _ = False

fn :: re in ranges Int [Int] => Bool
      re in ranges _ [] = False
      re in ranges _ (_:[]) = False
      re in ranges c (lo:hi:rs) =
        | c >= lo and c <= hi = True
        | otherwise = re in ranges c rs
```

### 11.4.2. Implementazione interna: Thompson NFA Compiler (`ReNode` -> `[NfaInst]`)

Nota come `regex.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: nfa len [NfaInst] => Int
      nfa len [] = 0
      nfa len (_:rest) = 1 + (nfa len rest)

fn :: re compile seq ReNode ReNode Int => [NfaInst]
      re compile seq a b start_id =
        insts_a = re compile node a start_id
        mid_id = start_id + (nfa len insts_a)
        insts_b = re compile node b mid_id
        insts_a :: insts_b

fn :: re compile opt ReNode Int => [NfaInst]
      re compile opt a start_id =
        body = re compile node a (start_id + 1)
        end_id = start_id + 1 + (nfa len body)
        [InstSplit (start_id + 1) end_id] :: body

fn :: re compile star ReNode Int => [NfaInst]
      re compile star a start_id =
        body = re compile node a (start_id + 1)
        end_id = start_id + 2 + (nfa len body)
        ([InstSplit (start_id + 1) end_id] :: body) :: [InstJump start_id]

fn :: re compile plus ReNode Int => [NfaInst]
      re compile plus a start_id =
        body = re compile node a start_id
        split_id = start_id + (nfa len body)
        body :: [InstSplit start_id (split_id + 1)]

fn :: re compile alt ReNode ReNode Int => [NfaInst]
      re compile alt a b start_id =
        body_a = re compile node a (start_id + 1)
        jump_id = start_id + 1 + (nfa len body_a)
        start_b = jump_id + 1
        body_b = re compile node b start_b
        end_id = start_b + (nfa len body_b)
        (([InstSplit (start_id + 1) start_b] :: body_a) :: [InstJump end_id]) :: body_b

fn :: re compile node ReNode Int => [NfaInst]
      re compile node ReEmpty _ = []
      re compile node (ReChar c) start_id = [InstChar c (start_id + 1)]
      re compile node ReAny start_id = [InstAny (start_id + 1)]
      re compile node (ReClass neg rngs) start_id = [InstClass neg rngs (start_id + 1)]
      re compile node (ReShort k) start_id = [InstShort k (start_id + 1)]
      re compile node ReBol start_id = [InstBol (start_id + 1)]
      re compile node ReEol start_id = [InstEol (start_id + 1)]
      re compile node (ReOpt a) start_id = re compile opt a start_id
      re compile node (ReStar a) start_id = re compile star a start_id
      re compile node (RePlus a) start_id = re compile plus a start_id
      re compile node (ReSeq a b) start_id = re compile seq a b start_id
      re compile node (ReAlt a b) start_id = re compile alt a b start_id

fn :: re compile String => [NfaInst]
      re compile pat =
        re parse alt pat 0 (str len pat) -> parsed
        (re compile node (re res node parsed) 0) :: [InstMatch]
```

### 11.4.3. Implementazione interna: Linear-Time Thompson NFA State-Set Simulation

Nota come `regex.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: nfa inst at [NfaInst] Int => NfaInst
      nfa inst at [] _ = InstMatch
      nfa inst at (i:_) 0 = i
      nfa inst at (_:rest) idx = nfa inst at rest (idx - 1)

fn :: nfa set has [Int] Int => Bool
      nfa set has [] _ = False
      nfa set has (x:xs) v =
        | x == v = True
        | otherwise = nfa set has xs v

fn :: nfa closure [NfaInst] [Int] Int Int [Int] => [Int]
      nfa closure _ [] _ _ visited = visited
      nfa closure prog (s:ss) pos len visited =
        | nfa set has visited s = nfa closure prog ss pos len visited
        | otherwise = nfa closure inst prog s ss pos len (visited :: [s]) (nfa inst at prog s)

fn :: nfa closure inst [NfaInst] Int [Int] Int Int [Int] NfaInst => [Int]
      nfa closure inst prog _ ss pos len vis (InstJump out) = nfa closure prog ([out] :: ss) pos len vis
      nfa closure inst prog _ ss pos len vis (InstSplit o1 o2) = nfa closure prog ([o1, o2] :: ss) pos len vis
      nfa closure inst prog _ ss pos len vis (InstBol out) =
        | pos == 0 = nfa closure prog ([out] :: ss) pos len vis
        | otherwise = nfa closure prog ss pos len vis
      nfa closure inst prog _ ss pos len vis (InstEol out) =
        | pos == len = nfa closure prog ([out] :: ss) pos len vis
        | otherwise = nfa closure prog ss pos len vis
      nfa closure inst prog _ ss pos len vis _ = nfa closure prog ss pos len vis

fn :: nfa step one NfaInst Int => [Int]
      nfa step one (InstChar expected out) c =
        | c == expected = [out]
        | otherwise = []
      nfa step one (InstAny out) c =
        | c != 10 = [out]
        | otherwise = []
      nfa step one (InstClass neg rngs out) c =
        | (re in ranges c rngs) != neg = [out]
        | otherwise = []
      nfa step one (InstShort kind out) c =
        | re match short kind c = [out]
        | otherwise = []
      nfa step one _ _ = []

fn :: nfa step [NfaInst] [Int] Int => [Int]
      nfa step _ [] _ = []
      nfa step prog (s:ss) c = (nfa step one (nfa inst at prog s) c) :: (nfa step prog ss c)

fn :: nfa is match inst NfaInst => Bool
      nfa is match inst InstMatch = True
      nfa is match inst _ = False

fn :: nfa has match [NfaInst] [Int] => Bool
      nfa has match _ [] = False
      nfa has match prog (s:ss) =
        | nfa is match inst (nfa inst at prog s) = True
        | otherwise = nfa has match prog ss

fn :: nfa update last [NfaInst] [Int] Int Int => Int
      nfa update last prog active cand cur =
        | nfa has match prog active = cand
        | otherwise = cur

fn :: nfa sim loop [NfaInst] String Int Int [Int] Int => Int
      nfa sim loop _ _ _ _ [] last_m = last_m
      nfa sim loop prog input pos len active last_m =
        | pos >= len = last_m
        | otherwise = nfa sim step prog input pos len active last_m

fn :: nfa sim step [NfaInst] String Int Int [Int] Int => Int
      nfa sim step prog input pos len active last_m =
        str char at input pos -> c
        nfa closure prog (nfa step prog active c) (pos + 1) len [] -> next_act
        nfa update last prog next_act (pos + 1) last_m -> next_last
        nfa sim loop prog input (pos + 1) len next_act next_last

fn :: nfa longest from [NfaInst] String Int Int => Int
      nfa longest from prog input pos len =
        nfa closure prog [0] pos len [] -> init_act
        nfa update last prog init_act pos (0 - 1) -> init_last
        nfa sim loop prog input pos len init_act init_last

fn :: nfa full loop [NfaInst] String Int Int [Int] => Bool
      nfa full loop _ _ _ _ [] = False
      nfa full loop prog input pos len active =
        | pos >= len = nfa has match prog active
        | otherwise = nfa full step prog input pos len active

fn :: nfa full step [NfaInst] String Int Int [Int] => Bool
      nfa full step prog input pos len active =
        str char at input pos -> c
        nfa closure prog (nfa step prog active c) (pos + 1) len [] -> next_act
        nfa full loop prog input (pos + 1) len next_act
```

### 11.4.4. Implementazione interna: Public Regex API (`API-REGEX-001`)

Nota come `regex.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: regex match String String => Bool
      regex match pat input =
        pat re compile -> prog
        input str len -> len
        nfa closure prog [0] 0 len [] -> init_act
        nfa full loop prog input 0 len init_act

fn :: nfa find from [NfaInst] String Int Int => RegexMatch
      nfa find from prog input pos len =
        | pos > len = RegexMatch False (0 - 1) (0 - 1) ""
        | otherwise = nfa find check prog input pos len (nfa longest from prog input pos len)

fn :: nfa find check [NfaInst] String Int Int Int => RegexMatch
      nfa find check prog input pos len end_pos =
        | end_pos >= pos = RegexMatch True pos end_pos (str slice input pos end_pos)
        | otherwise = nfa find from prog input (pos + 1) len

fn :: regex find String String => RegexMatch
      regex find pat input =
        pat re compile -> prog
        nfa find from prog input 0 (str len input)

fn :: regex is match String String => Bool
      regex is match pat input = regex find pat input -> matched

fn :: nfa find all loop [NfaInst] String Int Int [RegexMatch] => [RegexMatch]
      nfa find all loop prog input pos len acc =
        | pos > len = acc
        | otherwise = nfa find all step prog input pos len acc (nfa longest from prog input pos len)

fn :: nfa find all step [NfaInst] String Int Int [RegexMatch] Int => [RegexMatch]
      nfa find all step prog input pos len acc end_pos =
        | end_pos > pos = nfa find all loop prog input end_pos len (acc :: [RegexMatch True pos end_pos (str slice input pos end_pos)])
        | end_pos == pos = nfa find all loop prog input (pos + 1) len (acc :: [RegexMatch True pos pos ""])
        | otherwise = nfa find all loop prog input (pos + 1) len acc

fn :: regex find all String String => [RegexMatch]
      regex find all pat input =
        pat re compile -> prog
        nfa find all loop prog input 0 (str len input) []

fn :: regex replace String String String => String
      regex replace pat repl input =
        regex find pat input -> m
        re apply replace m repl input

fn :: re apply replace RegexMatch String String => String
      re apply replace m repl input =
        | not (matched m) = input
        | otherwise = (str slice input 0 (match_start m)) + repl + (str slice input (match_end m) (str len input))

fn :: nfa replace all loop [NfaInst] String String Int Int String => String
      nfa replace all loop prog repl input pos len acc =
        | pos >= len = acc
        | otherwise = nfa replace all step prog repl input pos len acc (nfa longest from prog input pos len)

fn :: nfa replace all step [NfaInst] String String Int Int String Int => String
      nfa replace all step prog repl input pos len acc end_pos =
        | end_pos > pos = nfa replace all loop prog repl input end_pos len (acc + repl)
        | otherwise = nfa replace all loop prog repl input (pos + 1) len (acc + (str slice input pos (pos + 1)))

fn :: regex replace all String String String => String
      regex replace all pat repl input =
        pat re compile -> prog
        nfa replace all loop prog repl input 0 (str len input) ""

fn :: nfa split loop [NfaInst] String Int Int Int [String] => [String]
      nfa split loop prog input pos len last_s acc =
        | pos >= len = acc :: [str slice input last_s len]
        | otherwise = nfa split step prog input pos len last_s acc (nfa longest from prog input pos len)

fn :: nfa split step [NfaInst] String Int Int Int [String] Int => [String]
      nfa split step prog input pos len last_s acc end_pos =
        | end_pos > pos = nfa split loop prog input end_pos len end_pos (acc :: [str slice input last_s pos])
        | otherwise = nfa split loop prog input (pos + 1) len last_s acc

fn :: regex split String String => [String]
      regex split pat input =
        pat re compile -> prog
        nfa split loop prog input 0 (str len input) 0 []
```

---

## 11.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `regex`

- **Garanzia algoritmica e di sicurezza**: Simulazione dell'insieme di stati NFA senza ricorsione incontrollata dello stack e tempo $O(N \cdot M)$ garantito anche su pattern patologici `(a+)+b`.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/regex.rg` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test regex.rg`.

### Le 5 Regole d'Oro quando programmi con `regex`

1. **Dichiara `import regex` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `regex` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `regex` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `regex` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 12** passeremo a esplorare in profondità la lib **`glob`** (La lib `glob` — Pattern di Metacaratteri (`*`, `?`, `[a-z]`) e Filtraggio di Liste).
