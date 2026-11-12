# Capitolo 08: La lib `json` — Albero AST Ricorsivo RFC 8259, Pretty-Printer e Query per Percorso

## 08.1. Perché esiste la lib `json`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `json` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `json`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: esplorare un JSON annidato in molti linguaggi statici comporta scrivere tre schermate di codice boilerplate o concatenare dieci `.and_then()` prima di leggere una semplice porta.

La lib **`json`** fornisce un parser a discesa ricorsiva completo per **RFC 8259** sull'ADT algebrico `JsonVal` (`JnNull`, `JnBool`, `JnInt`, `JnStr`, `JnArr`, `JnObj`, `JnErr`), serializzazione compatta e indentata (`json pretty`) e query dirette tramite percorso puntato (`"server.http.port"`, `"users.0.name"`).

In un ecosistema tradizionale, risolvere i compiti del dominio **`JSON`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`json`** (`src/main/ridgun/lib/json.ridgun`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import json` (o `import json as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: json` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `json` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 08.2. Artefatti nativi, importazione e catalogo completo dell'API di `json`

In `ridgun-libs`, **`json`** è una **lib** di prima classe situata in `src/main/ridgun/lib/json.ridgun` (dominio `JSON`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/json.ridgunlib` | Distribuzione e importazione diretta con `import json` |
| **File compilato** | `target/json.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libjson.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: json`: basta scrivere `import json` (o `import json as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 08.2.1. Riepilogo delle famiglie funzionali di `json`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `type JsonVal` | `JnNull | JnBool Bool | JnInt Int | JnStr String | JnArr [JsonVal] | JnObj [String JsonVal] | JnErr String` |
| `json parse / json is ok` | Analizza testo JSON in un albero `JsonVal` e convalida l'assenza di `JnErr` |
| `json stringify / json pretty` | Serializza `JsonVal` in JSON compatto o multilinea indentato |
| `json get path / json get str / json get int / json get bool` | Attraversa oggetti e liste annidati tramite percorsi puntati (`"a.b.0.c"`) |

### 08.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/json.ridgun`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/json.ridgun` (`7` tipi, `0` operatori e `118` funzioni):

**Tipi algebrici e record (`type`) di `json`:**

```ridgun
type JsonField = JsonField String JsonVal
type JsonVal = JsonNull | JsonBool Bool | JsonInt Int | JsonStr String | JsonArr [JsonVal] | JsonObj [JsonField]
type JsonRes = JsonOk JsonVal | JsonErr String
type JsonStep = JStepOk JsonVal Int | JStepErr String
type JsonArrStep = JArrOk [JsonVal] Int | JArrErr String
type JsonObjStep = JObjOk [JsonField] Int | JObjErr String
type JsonStrStep = JStrOk String Int | JStrErr String
```

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
|---|---|---|
| `1` | `fn :: j is ws Int` | `Bool` |
| `2` | `fn :: j is digit Int` | `Bool` |
| `3` | `fn :: j skip ws String Int Int` | `Int` |
| `4` | `fn :: j spaces Int` | `String` |
| `5` | `fn :: j escape loop String Int Int String` | `String` |
| `6` | `fn :: j escape str String` | `String` |
| `7` | `fn :: j unescape char Int` | `String` |
| `8` | `fn :: j parse str loop String Int Int String` | `JsonStrStep` |
| `9` | `fn :: j parse string String Int Int` | `JsonStrStep` |
| `10` | `fn :: j scan digits String Int Int` | `Int` |
| `11` | `fn :: j parse number String Int Int` | `JsonStep` |
| `12` | `fn :: j finish neg num String Int Int` | `JsonStep` |
| `13` | `fn :: j finish pos num String Int Int` | `JsonStep` |
| `14` | `fn :: j parse val String Int Int` | `JsonStep` |
| `15` | `fn :: j parse val at String Int Int` | `JsonStep` |
| `16` | `fn :: j wrap str step JsonStrStep` | `JsonStep` |
| `17` | `fn :: j parse arr open String Int Int` | `JsonStep` |
| `18` | `fn :: j parse arr first String Int Int` | `JsonStep` |
| `19` | `fn :: j finish arr step JsonArrStep` | `JsonStep` |
| `20` | `fn :: j parse arr items String Int Int [JsonVal]` | `JsonArrStep` |
| `21` | `fn :: j parse arr after item String Int [JsonVal] JsonStep` | `JsonArrStep` |
| `22` | `fn :: j parse arr delim String Int Int [JsonVal]` | `JsonArrStep` |
| `23` | `fn :: j parse obj open String Int Int` | `JsonStep` |
| `24` | `fn :: j parse obj first String Int Int` | `JsonStep` |
| `25` | `fn :: j finish obj step JsonObjStep` | `JsonStep` |
| `26` | `fn :: j parse obj fields String Int Int [JsonField]` | `JsonObjStep` |
| `27` | `fn :: j parse obj after key String Int [JsonField] JsonStrStep` | `JsonObjStep` |
| `28` | `fn :: j parse obj colon String Int Int String [JsonField]` | `JsonObjStep` |
| `29` | `fn :: j parse obj after val String Int String [JsonField] JsonStep` | `JsonObjStep` |
| `30` | `fn :: j parse obj delim String Int Int [JsonField]` | `JsonObjStep` |
| `31` | `fn :: j check eof String Int JsonStep` | `JsonRes` |
| `32` | `fn :: j check eof pos Int Int JsonVal` | `JsonRes` |
| `33` | `fn :: json parse String` | `JsonRes` |
| `34` | `fn :: j join arr [JsonVal]` | `String` |
| `35` | `fn :: j join obj [JsonField]` | `String` |
| `36` | `fn :: json stringify JsonVal` | `String` |
| `37` | `fn :: j pretty arr [JsonVal] Int Int` | `String` |
| `38` | `fn :: j pretty obj [JsonField] Int Int` | `String` |
| `39` | `fn :: j pretty val JsonVal Int Int` | `String` |
| `40` | `fn :: json pretty JsonVal Int` | `String` |
| `41` | `fn :: j find field [JsonField] String` | `JsonVal` |
| `42` | `fn :: json get field JsonVal String` | `JsonVal` |
| `43` | `fn :: j nth val [JsonVal] Int` | `JsonVal` |
| `44` | `fn :: json get index JsonVal Int` | `JsonVal` |
| `45` | `fn :: j split dots loop String Int Int Int [String]` | `[String]` |
| `46` | `fn :: j step path JsonVal String` | `JsonVal` |
| `47` | `fn :: j walk path JsonVal [String]` | `JsonVal` |
| `48` | `fn :: json get path JsonVal String` | `JsonVal` |
| `49` | `fn :: json get str JsonVal String String` | `String` |
| `50` | `fn :: j unwrap str JsonVal String` | `String` |
| `51` | `fn :: json get int JsonVal String Int` | `Int` |
| `52` | `fn :: j unwrap int JsonVal Int` | `Int` |
| `53` | `fn :: json get bool JsonVal String Bool` | `Bool` |
| `54` | `fn :: j unwrap bool JsonVal Bool` | `Bool` |
| `55` | `fn :: j put field [JsonField] String JsonVal` | `[JsonField]` |
| `56` | `fn :: json set field JsonVal String JsonVal` | `JsonVal` |

---

## 08.3. Esplorare `json` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `json` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test json.ridgun`.

### 08.3.1. Esempio 1: Flusso principale in stile tabulare con `json`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `json` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import json

fn :: leer config servidor JsonVal => String Int Bool
      leer config servidor doc =
        json get str doc "server.host" "127.0.0.1" -> host
        json get int doc "server.port" 8080 -> port
        json get bool doc "server.tls.enabled" False -> tls
        (host, port, tls)
```

### 08.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `json` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import json

fn :: construir manifiesto => String
      construir manifiesto =
        JsonObj [JsonField "app" (JsonStr "solstice"), JsonField "workers" (JsonInt 8)] -> nodo
        json pretty nodo 2
```

### 08.3.3. Esempio 3: Analisi sintattica (`json parse`), serializzazione compatta (`json stringify`) e stampa indentata (`json pretty`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `json` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test json parse stringify and pretty => ()
      test json parse stringify and pretty =
        lb = char from code 123
        rb = char from code 125
        raw = lb + "\"user\":" + lb + "\"name\":\"Ada \\\"Lovelace\\\"\",\"age\":36,\"active\":true,\"roles\":[\"admin\",\"math\"],\"meta\":null" + rb + rb
        res = json parse raw
        assert true (is json ok res) "AC1: json parse nested object and array"
        val = unwrap json res

        compact = json stringify val
        assert str eq compact raw "AC1: json stringify lossless round-trip"

        pretty_s = json pretty val 2
        res2 = json parse pretty_s
        assert true (is json ok res2) "AC1: json pretty output parses back cleanly"
        assert str eq (json stringify (unwrap json res2)) raw "AC1: json pretty round-trip equality"
        ()
```

### 08.3.4. Esempio 4: Primitive JSON (`null`, `bool`, `int`, `str`), sequenze di escape e contenitori vuoti (`[]`, `{}`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `json` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test json primitives escapes and empty containers => ()
      test json primitives escapes and empty containers =
        lb = char from code 123
        rb = char from code 125
        bs = char from code 92
        nl = char from code 10
        tab = char from code 9
        assert str eq (json stringify (unwrap json (json parse (lb + rb)))) (lb + rb) "AC1: empty object {}"
        assert str eq (json stringify (unwrap json (json parse "[]"))) "[]" "AC1: empty array []"
        assert str eq (json stringify (unwrap json (json parse ("  " + lb + "  " + rb + "  ")))) (lb + rb) "AC1: whitespace-padded empty object"
        assert true (is json null (unwrap json (json parse "null"))) "AC1: root null literal"
        assert str eq (json stringify (unwrap json (json parse "true"))) "true" "AC1: root true literal"
        assert str eq (json stringify (unwrap json (json parse "false"))) "false" "AC1: root false literal"
        assert str eq (json stringify (unwrap json (json parse "0"))) "0" "AC1: root zero integer"
        assert str eq (json stringify (unwrap json (json parse "-42000"))) "-42000" "AC1: root negative integer"

        esc_json = lb + "\"msg\":\"line1" + bs + "nline2" + bs + "t" + bs + bs + "slash\"" + rb
        esc_val = unwrap json (json parse esc_json)
        assert str eq (json get str esc_val "msg" "") ("line1" + nl + "line2" + tab + bs + "slash") "AC1: unescape \\n, \\t, \\\\ in JSON strings"
        assert str eq (json stringify esc_val) esc_json "AC1: re-escape \\n, \\t, \\\\ on stringify"
        ()
```

### 08.3.5. Esempio 5: Query profonde per percorso puntato (`json query`, `json query str/int/bool`) e aggiornamento funzionale (`json set field`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `json` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test json dot path queries and updates => ()
      test json dot path queries and updates =
        lb = char from code 123
        rb = char from code 125
        raw = lb + "\"user\":" + lb + "\"name\":\"Ada\",\"age\":36,\"active\":true,\"roles\":[\"admin\",\"math\"],\"matrix\":[[10,20],[30,40]]" + rb + ",\"count\":-7,\"disabled\":false" + rb
        val = unwrap json (json parse raw)

        assert str eq (json get str val "user.name" "") "Ada" "AC2: json get str dot path"
        assert int equals (json get int val "user.age" 0) 36 "AC2: json get int dot path"
        assert int equals (json get int val "count" 0) (-7) "AC2: json get int negative"
        assert true (json get bool val "user.active" False) "AC2: json get bool true"
        assert false (json get bool val "disabled" True) "AC2: json get bool false"
        assert str eq (json get str val "user.roles.0" "") "admin" "AC2: json get str array index 0"
        assert str eq (json get str val "user.roles.1" "") "math" "AC2: json get str array index 1"
        assert int equals (json get int val "user.matrix.1.0" 0) 30 "AC2: nested 2D array index user.matrix.1.0"
        assert int equals (json get int val "user.matrix.1.1" 0) 40 "AC2: nested 2D array index user.matrix.1.1"
        assert str eq (json get str val "user.roles.99" "oob") "oob" "AC2: out-of-bounds array index fallback"
        assert str eq (json get str val "user.missing.deep" "fallback") "fallback" "AC2: missing deep dot-path fallback"

        updated = json set field val "version" (JsonInt 2)
        assert int equals (json get int updated "version" 0) 2 "AC2: json set field adds new key"
        overwritten = json set field updated "count" (JsonInt 99)
        assert int equals (json get int overwritten "count" 0) 99 "AC2: json set field overwrites existing key"
        ()
```

### 08.3.6. Esempio 6: Rilevamento sicuro di input JSON malformati (`JsonErr`) senza panic né eccezioni

In questo esempio pratico esploriamo in modo esaustivo come si comporta `json` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test json malformed inputs => ()
      test json malformed inputs =
        lb = char from code 123
        rb = char from code 125
        assert false (is json ok (json parse "")) "AC3: reject empty input"
        assert false (is json ok (json parse "   ")) "AC3: reject whitespace-only input"
        assert false (is json ok (json parse (lb + "\"unclosed\":1"))) "AC3: reject unclosed object"
        assert false (is json ok (json parse "[1, 2, 3")) "AC3: reject unclosed array"
        assert false (is json ok (json parse "\"unterminated string")) "AC3: reject unterminated string"
        assert false (is json ok (json parse (lb + "unquoted: 1" + rb))) "AC3: reject unquoted object key"
        assert false (is json ok (json parse (lb + "\"k\" 1" + rb))) "AC3: reject missing colon in object"
        assert false (is json ok (json parse "[1, 2] trailing")) "AC3: reject trailing garbage token"
        assert false (is json ok (json parse "tru")) "AC3: reject truncated boolean literal"
        assert false (is json ok (json parse "nul")) "AC3: reject truncated null literal"
        ()
```

---

## 08.4. Sotto il cofano: come è costruita `json` in Ridgun puro (`src/main/ridgun/lib/json.ridgun`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/json.ridgun` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 08.4.1. Implementazione interna: Whitespace & Character Helpers

Nota come `json.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
module :: json

fn :: j is ws Int => Bool
      j is ws c   =  c == 32 OR c == 9 OR c == 10 OR c == 13

fn :: j is digit Int => Bool
      j is digit c   =  c >= 48 AND c <= 57

fn :: j skip ws String Int Int => Int
      j skip ws s      pos len
        | pos >= len = len
        | j is ws (str char at s pos) = j skip ws s (pos + 1) len
        | otherwise = pos

fn :: j spaces Int => String
      j spaces n
        | n <= 0 = ""
        | otherwise = " " + (j spaces (n - 1))
```

### 08.4.2. Implementazione interna: Integer Literal Parsing

Nota come `json.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: j scan digits String Int Int => Int
      j scan digits s      pos len
        | pos >= len = len
        | j is digit (str char at s pos) = j scan digits s (pos + 1) len
        | otherwise = pos

fn :: j parse number String Int Int => JsonStep
      j parse number s      pos len
        | (str char at s pos) == 45 = j finish neg num s pos (j scan digits s (pos + 1) len)
        | otherwise = j finish pos num s pos (j scan digits s pos len)

fn :: j finish neg num String Int Int     => JsonStep
      j finish neg num s      pos end_pos
        | end_pos <= (pos + 1) = JStepErr "invalid negative number"
        | otherwise = JStepOk (JsonInt (str to int (str slice s pos end_pos))) end_pos

fn :: j finish pos num String Int Int     => JsonStep
      j finish pos num s      pos end_pos
        | end_pos <= pos = JStepErr "expected number"
        | otherwise = JStepOk (JsonInt (str to int (str slice s pos end_pos))) end_pos
```

### 08.4.3. Implementazione interna: Serialization & Pretty-Printing

Nota come `json.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: j join arr loop [JsonVal] String String String String => String
      j join arr loop []     c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j join arr loop (v:vs) c0 c1 c2 c3 =
        n0, n1, n2, n3 = j sb append ("," + (json stringify v)) c0 c1 c2 c3
        j join arr loop vs n0 n1 n2 n3

fn :: j join arr [JsonVal] => String
      j join arr []        =  ""
      j join arr (v:vs)    =  j join arr loop vs (json stringify v) "" "" ""

fn :: j join obj loop [JsonField] String String String String => String
      j join obj loop []                     c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j join obj loop ((JsonField k v):rest) c0 c1 c2 c3 =
        item = "," + (j escape str k) + ":" + (json stringify v)
        n0, n1, n2, n3 = j sb append item c0 c1 c2 c3
        j join obj loop rest n0 n1 n2 n3

fn :: j join obj [JsonField] => String
      j join obj []                     =  ""
      j join obj ((JsonField k v):rest) =
        first = (j escape str k) + ":" + (json stringify v)
        j join obj loop rest first "" "" ""

fn :: j pos int to str Int String => String
      j pos int to str n acc =
        | n <= 0    = acc
        | otherwise = j pos int to str (n / 10) ((char from code (48 + (n % 10))) + acc)

fn :: j int to str Int => String
      j int to str n =
        | n == 0         = "0"
        | n > 0          = j pos int to str n ""
        | n > (0 - 10)   = "-" + (char from code (48 + (0 - n)))
        | otherwise      = "-" + (j pos int to str (0 - (n / 10)) (char from code (48 + (0 - (n % 10)))))

fn :: json stringify JsonVal          => String
      json stringify JsonNull         =  "null"
      json stringify (JsonBool True)  =  "true"
      json stringify (JsonBool False) =  "false"
      json stringify (JsonInt n)      =  j int to str n
      json stringify (JsonStr s)      =  j escape str s
      json stringify (JsonArr items)  =  "[" + (j join arr items) + "]"
      json stringify (JsonObj fields) =  (char from code 123) + (j join obj fields) + (char from code 125)

fn :: j pretty arr loop [JsonVal] Int Int String String String String => String
      j pretty arr loop []     _   _   c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j pretty arr loop (v:vs) ind cur c0 c1 c2 c3 =
        item = "," + (char from code 10) + (j spaces (cur + ind)) + (j pretty val v ind (cur + ind))
        n0, n1, n2, n3 = j sb append item c0 c1 c2 c3
        j pretty arr loop vs ind cur n0 n1 n2 n3

fn :: j pretty arr [JsonVal] Int Int => String
      j pretty arr []     _   _   =  ""
      j pretty arr (v:vs) ind cur =
        first = (j spaces (cur + ind)) + (j pretty val v ind (cur + ind))
        j pretty arr loop vs ind cur first "" "" ""

fn :: j pretty obj loop [JsonField] Int Int String String String String => String
      j pretty obj loop []                     _   _   c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j pretty obj loop ((JsonField k v):rest) ind cur c0 c1 c2 c3 =
        item = "," + (char from code 10) + (j spaces (cur + ind)) + (j escape str k) + ": " + (j pretty val v ind (cur + ind))
        n0, n1, n2, n3 = j sb append item c0 c1 c2 c3
        j pretty obj loop rest ind cur n0 n1 n2 n3

fn :: j pretty obj [JsonField] Int Int => String
      j pretty obj []                     _   _   =  ""
      j pretty obj ((JsonField k v):rest) ind cur =
        first = (j spaces (cur + ind)) + (j escape str k) + ": " + (j pretty val v ind (cur + ind))
        j pretty obj loop rest ind cur first "" "" ""

fn :: j pretty val JsonVal          Int Int => String
      j pretty val (JsonArr [])     _   _   =  "[]"
      j pretty val (JsonArr items)  ind cur =
        nl = char from code 10
        "[" + nl + (j pretty arr items ind cur) + nl + (j spaces cur) + "]"
      j pretty val (JsonObj [])     _   _   =  (char from code 123) + (char from code 125)
      j pretty val (JsonObj fields) ind cur =
        nl = char from code 10
        (char from code 123) + nl + (j pretty obj fields ind cur) + nl + (j spaces cur) + (char from code 125)
      j pretty val v                _   _   =  json stringify v

fn :: json pretty JsonVal Int => String
      json pretty val     ind =  j pretty val val ind 0
```

### 08.4.4. Implementazione interna: Dot-Path Queries & Field Updates

Nota come `json.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: j find field [JsonField] String => JsonVal
      j find field []                   _   =  JsonNull
      j find field ((JsonField k v):fs) key =
        | k == key  = v
        | otherwise = j find field fs key

fn :: json get field JsonVal          String => JsonVal
      json get field (JsonObj fields) key    =  j find field fields key
      json get field _                _      =  JsonNull

fn :: j nth val [JsonVal] Int => JsonVal
      j nth val []     _   =  JsonNull
      j nth val (v:vs) idx =
        | idx < 0   = JsonNull
        | idx == 0  = v
        | otherwise = j nth val vs (idx - 1)

fn :: json get index JsonVal         Int => JsonVal
      json get index (JsonArr items) idx =  j nth val items idx
      json get index _               _   =  JsonNull

fn :: j split dots loop String Int Int Int [String] => [String]
      j split dots loop s pos len start acc =
        | pos >= len                = acc :: [str slice s start len]
        | (str char at s pos) == 46 = j split dots loop s (pos + 1) len (pos + 1) (acc :: [str slice s start pos])
        | otherwise                 = j split dots loop s (pos + 1) len start acc

fn :: j step path JsonVal          String => JsonVal
      j step path (JsonObj fields) seg    =  j find field fields seg
      j step path (JsonArr items)  seg    =
        | seg != "" and (j scan digits seg 0 (str len seg)) == (str len seg) and (j digits fit i64 seg False) = j nth val items (str to int seg)
        | otherwise = JsonNull
      j step path _                _      =  JsonNull

fn :: j walk path JsonVal [String]   => JsonVal
      j walk path val     []         =  val
      j walk path val     ("":rest)  =  j walk path val rest
      j walk path val     (seg:rest) =  j walk path (j step path val seg) rest

fn :: json get path JsonVal String   => JsonVal
      json get path val     ""       =  val
      json get path val     dot_path =
        j split dots loop dot_path 0 (str len dot_path) 0 [] -> segs
        j walk path val segs

fn :: json get str JsonVal String String => String
      json get str val dot_path fallback =
        json get path val dot_path -> target
        j unwrap str target fallback

fn :: j unwrap str JsonVal     String   => String
      j unwrap str (JsonStr s) _        =  s
      j unwrap str _           fallback =  fallback

fn :: json get int JsonVal String Int => Int
      json get int val dot_path fallback =
        json get path val dot_path -> target
        j unwrap int target fallback

fn :: j unwrap int JsonVal     Int      => Int
      j unwrap int (JsonInt n) _        =  n
      j unwrap int _           fallback =  fallback

fn :: json get bool JsonVal String Bool => Bool
      json get bool val dot_path fallback =
        json get path val dot_path -> target
        j unwrap bool target fallback

fn :: j unwrap bool JsonVal      Bool     => Bool
      j unwrap bool (JsonBool b) _        =  b
      j unwrap bool _            fallback =  fallback

fn :: j put field [JsonField] String JsonVal => [JsonField]
      j put field []                   key new_val = [JsonField key new_val]
      j put field ((JsonField k v):fs) key new_val =
        | k == key  = [JsonField key new_val] :: fs
        | otherwise = [JsonField k v] :: (j put field fs key new_val)

fn :: json set field JsonVal String JsonVal => JsonVal
      json set field (JsonObj fields) key new_val = JsonObj (j put field fields key new_val)
      json set field _ key new_val = JsonObj [JsonField key new_val]
```

---

## 08.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `json`

- **Garanzia algoritmica e di sicurezza**: Rifiuto rigoroso di caratteri residui dopo il valore radice (`trailing garbage`), gestione completa degli escape e restituzione sicura di `JnErr` senza eccezioni.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/json.ridgun` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test json.ridgun`.

### Le 5 Regole d'Oro quando programmi con `json`

1. **Dichiara `import json` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `json` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `json` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `json` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 09** passeremo a esplorare in profondità la lib **`csv`** (La lib `csv` — Analizzatore a Stati RFC 4180 per CSV/TSV e Tabelle Indicizzate).
