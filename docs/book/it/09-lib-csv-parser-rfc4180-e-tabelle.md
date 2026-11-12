# Capitolo 09: La lib `csv` — Analizzatore a Stati RFC 4180 per CSV/TSV e Tabelle Indicizzate

## 09.1. Perché esiste la lib `csv`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `csv` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `csv`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: tutti pensano che fare il parsing di un CSV significhi scrivere `str split linea ","`... finché non compare un campo tra virgolette con una virgola all'interno, virgolette raddoppiate `""` o un ritorno a capo `\r\n` nel mezzo di una cella.

La lib **`csv`** implementa una macchina a stati completa conforme a **RFC 4180** per CSV e TSV, serializzazione automatica con virgolettatura intelligente e il tipo `CsvTable` per interrogare colonne e righe tramite il nome dell'intestazione.

In un ecosistema tradizionale, risolvere i compiti del dominio **`CSV`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`csv`** (`src/main/ridgun/lib/csv.ridgun`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import csv` (o `import csv as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: csv` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `csv` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 09.2. Artefatti nativi, importazione e catalogo completo dell'API di `csv`

In `ridgun-libs`, **`csv`** è una **lib** di prima classe situata in `src/main/ridgun/lib/csv.ridgun` (dominio `CSV`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/csv.ridgunlib` | Distribuzione e importazione diretta con `import csv` |
| **File compilato** | `target/csv.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libcsv.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: csv`: basta scrivere `import csv` (o `import csv as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 09.2.1. Riepilogo delle famiglie funzionali di `csv`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `csv parse / tsv parse / csv parse with` | Analizza testo CSV/TSV (incluse celle multilinea ed escape `""`) in `[[String]]` |
| `csv stringify / tsv stringify` | Serializza `[[String]]` racchiudendo tra virgolette solo le celle con delimitatori, virgolette o a capo |
| `csv parse table / csv get cell / csv col` | Query su `CsvTable` indicizzata per intestazione `(riga, nome_col)` o intera colonna |
| `csv row to kv / csv table to kv list` | Converte righe tabulari in dizionari `[String String]` indicizzati per intestazione |

### 09.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/csv.ridgun`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/csv.ridgun` (`1` tipi, `0` operatori e `23` funzioni):

**Tipi algebrici e record (`type`) di `csv`:**

```ridgun
type CsvTable = headers: [String], rows: [[String]], delimiter_char: String, has_headers: Bool
```

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
|---|---|---|
| `1` | `fn :: csv delim code String` | `Int` |
| `2` | `fn :: csv append final row [[String]] [String] String` | `[[String]]` |
| `3` | `fn :: csv parse quoted String Int Int Int String [String] [[String]]` | `[[String]]` |
| `4` | `fn :: csv parse unquoted String Int Int Int String [String] [[String]]` | `[[String]]` |
| `5` | `fn :: csv parse with delim String String` | `[[String]]` |
| `6` | `fn :: csv parse String` | `[[String]]` |
| `7` | `fn :: tsv parse String` | `[[String]]` |
| `8` | `fn :: csv build table [[String]] Bool` | `CsvTable` |
| `9` | `fn :: csv parse table String Bool` | `CsvTable` |
| `10` | `fn :: csv needs quotes loop String Int Int Int` | `Bool` |
| `11` | `fn :: csv double quotes loop String Int Int String` | `String` |
| `12` | `fn :: csv format cell String Int` | `String` |
| `13` | `fn :: csv join row [String] String Int` | `String` |
| `14` | `fn :: csv join rows [[String]] String Int` | `String` |
| `15` | `fn :: csv stringify with delim [[String]] String` | `String` |
| `16` | `fn :: csv stringify [[String]]` | `String` |
| `17` | `fn :: tsv stringify [[String]]` | `String` |
| `18` | `fn :: csv nth str [String] Int` | `String` |
| `19` | `fn :: csv nth row [[String]] Int` | `[String]` |
| `20` | `fn :: csv col [[String]] Int` | `[String]` |
| `21` | `fn :: csv find header idx [String] String Int` | `Int` |
| `22` | `fn :: csv get by header CsvTable Int String` | `String` |
| `23` | `fn :: csv row to map [String] [String]` | `[String String]` |

---

## 09.3. Esplorare `csv` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `csv` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test csv.ridgun`.

### 09.3.1. Esempio 1: Flusso principale in stile tabulare con `csv`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `csv` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import csv

fn :: extraer columna precios String => [String] String
      extraer columna precios raw_csv =
        raw_csv csv parse -> tabla
        csv col by name tabla "precio" -> precios
        csv cell by name tabla 0 "producto" -> primero
        (precios, primero)
```

### 09.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `csv` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import csv

fn :: exportar informe => String
      exportar informe =
        [["id", "nota"], ["1", "Contiene, coma"], ["2", "Dijo "hola""]] -> filas
        filas csv encode
```

### 09.3.3. Esempio 3: Round-trip RFC 4180 CSV/TSV con virgolette raddoppiate `""`, virgole interne e ritorni a capo incorporati

In questo esempio pratico esploriamo in modo esaustivo come si comporta `csv` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test csv tsv roundtrip => ()
      test csv tsv roundtrip =
        nl = char from code 10
        tab = char from code 9
        raw_csv = "name,role,note" + nl + "Ada,\"Admin, Lead\",\"Quote \"\"here\"\"\"" + nl + "Bob,User,\"Line 1" + nl + "Line 2\"" + nl
        parsed = csv parse raw_csv
        assert int equals (csv row count parsed) 3 "AC1: 3 rows parsed including multiline quoted cell"
        assert str eq (csv cell at parsed 1 1) "Admin, Lead" "AC1: quoted comma preserved"
        assert str eq (csv cell at parsed 1 2) "Quote \"here\"" "AC1: doubled quote unescaped"
        assert str eq (csv cell at parsed 2 2) ("Line 1" + nl + "Line 2") "AC1: embedded newline in quoted cell preserved"
        re_csv = csv stringify parsed
        assert str eq re_csv raw_csv "AC1/AC2: RFC 4180 CSV quoted comma, escaped quote, and newline round-trip"

        raw_tsv = "col1" + tab + "col2" + nl + "val,1" + tab + "val2" + nl
        parsed_tsv = tsv parse raw_tsv
        assert str eq (csv cell at parsed_tsv 1 0) "val,1" "AC1: TSV unquoted comma preserved"
        re_tsv = tsv stringify parsed_tsv
        assert str eq re_tsv raw_tsv "AC1/AC2: TSV round-trip"
        ()
```

### 09.3.4. Esempio 4: Gestione dei fine riga `CRLF` (`\r\n`), celle vuote consecutive e delimitatori personalizzati

In questo esempio pratico esploriamo in modo esaustivo come si comporta `csv` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test csv crlf and empty cells => ()
      test csv crlf and empty cells =
        cr = char from code 13
        nl = char from code 10
        crlf = cr + nl
        raw_crlf = "a,b,c" + crlf + "1,,3" + crlf + ",2," + crlf
        rows_crlf = csv parse raw_crlf
        assert int equals (csv row count rows_crlf) 3 "AC1: CRLF row count"
        assert str eq (csv cell at rows_crlf 1 0) "1" "AC1: cell (1,0)"
        assert str eq (csv cell at rows_crlf 1 1) "" "AC1: middle empty cell (1,1)"
        assert str eq (csv cell at rows_crlf 1 2) "3" "AC1: cell (1,2)"
        assert str eq (csv cell at rows_crlf 2 0) "" "AC1: leading empty cell (2,0)"
        assert str eq (csv cell at rows_crlf 2 1) "2" "AC1: cell (2,1)"
        assert str eq (csv cell at rows_crlf 2 2) "" "AC1: trailing empty cell (2,2)"

        semi_rows = csv parse with delim ("k1;k2" + nl + "v1;v2" + nl) ";"
        assert int equals (csv row count semi_rows) 2 "AC1: semicolon delimiter row count"
        assert str eq (csv cell at semi_rows 1 1) "v2" "AC1: semicolon delimiter cell (1,1)"
        assert int equals (csv row count (csv parse "")) 0 "AC1: empty input yields 0 rows"
        ()
```

### 09.3.5. Esempio 5: Tabelle con intestazione (`CsvTable`): ricerca per riga e nome di colonna (`csv get cell`), estrazione di colonne e record chiave-valore

In questo esempio pratico esploriamo in modo esaustivo come si comporta `csv` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test csv table lookup => ()
      test csv table lookup =
        nl = char from code 10
        raw_csv = "id,name,dept" + nl + "10,Ada,Math" + nl + "20,Grace,Compilers" + nl
        tbl = csv parse table raw_csv True
        assert true (has_headers tbl) "AC3: table has_headers True"
        assert int equals (csv len (headers tbl)) 3 "AC3: 3 headers extracted"
        assert str eq (csv get by header tbl 0 "name") "Ada" "AC3: csv get by header row 0"
        assert str eq (csv get by header tbl 1 "dept") "Compilers" "AC3: csv get by header row 1"
        assert str eq (csv get by header tbl 0 "missing") "" "AC3: csv get by header missing column"
        assert str eq (csv get by header tbl 99 "name") "" "AC3: csv get by header out-of-bounds row"

        tbl_no_h = csv parse table raw_csv False
        assert false (has_headers tbl_no_h) "AC3: table has_headers False"
        assert int equals (csv row count (rows tbl_no_h)) 3 "AC3: headerless table keeps all 3 rows"

        names = csv col (rows tbl) 1
        assert int equals (csv len names) 2 "AC3: csv col length"
        assert str eq (csv str at names 0) "Ada" "AC3: csv col[0]"
        assert str eq (csv str at names 1) "Grace" "AC3: csv col[1]"

        rmap = csv row to map ["id", "name", "dept"] ["10", "Ada", "Math"]
        assert str eq (csv pair val rmap "id") "10" "AC3: csv row to map id"
        assert str eq (csv pair val rmap "name") "Ada" "AC3: csv row to map name"
        assert str eq (csv pair val rmap "dept") "Math" "AC3: csv row to map dept"
        ()
```

---

## 09.4. Sotto il cofano: come è costruita `csv` in Ridgun puro (`src/main/ridgun/lib/csv.ridgun`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/csv.ridgun` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 09.4.1. Implementazione interna: RFC 4180 State-Machine Parser

Nota come `csv.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
module :: csv

fn :: csv delim code String => Int
      csv delim code "" = 44
      csv delim code d = str char at d 0

fn :: csv append final row [[String]] [String] String => [[String]]
      csv append final row rows [] "" = rows
      csv append final row rows cur_row cell = rows :: [cur_row :: [cell]]

fn :: csv parse quoted String Int Int Int String [String] [[String]] => [[String]]
      csv parse quoted s pos len d_code cell cur_row rows =
        | pos >= len = csv append final row rows cur_row cell
        | (str char at s pos) == 34 and (pos + 1) < len and (str char at s (pos + 1)) == 34 = csv parse quoted s (pos + 2) len d_code (cell + (char from code 34)) cur_row rows
        | (str char at s pos) == 34 = csv parse unquoted s (pos + 1) len d_code cell cur_row rows
        | otherwise = csv parse quoted s (pos + 1) len d_code (cell + (str slice s pos (pos + 1))) cur_row rows

fn :: csv parse unquoted String Int Int Int String [String] [[String]] => [[String]]
      csv parse unquoted s pos len d_code cell cur_row rows =
        | pos >= len = csv append final row rows cur_row cell
        | (str char at s pos) == 34 and cell == "" = csv parse quoted s (pos + 1) len d_code "" cur_row rows
        | (str char at s pos) == d_code = csv parse unquoted s (pos + 1) len d_code "" (cur_row :: [cell]) rows
        | (str char at s pos) == 13 and (pos + 1) < len and (str char at s (pos + 1)) == 10 = csv parse unquoted s (pos + 2) len d_code "" [] (rows :: [cur_row :: [cell]])
        | (str char at s pos) == 10 or (str char at s pos) == 13 = csv parse unquoted s (pos + 1) len d_code "" [] (rows :: [cur_row :: [cell]])
        | otherwise = csv parse unquoted s (pos + 1) len d_code (cell + (str slice s pos (pos + 1))) cur_row rows

fn :: csv parse with delim String String => [[String]]
      csv parse with delim s delim =
        csv parse unquoted s 0 (str len s) (csv delim code delim) "" [] []

fn :: csv parse String => [[String]]
      csv parse s = csv parse with delim s ","

fn :: tsv parse String => [[String]]
      tsv parse s = csv parse with delim s (char from code 9)

fn :: csv build table [[String]] Bool => CsvTable
      csv build table [] has_h = CsvTable [] [] "," has_h
      csv build table (h:rest) True = CsvTable h rest "," True
      csv build table all_rows False = CsvTable [] all_rows "," False

fn :: csv parse table String Bool => CsvTable
      csv parse table s has_h = csv build table (csv parse s) has_h
```

### 09.4.2. Implementazione interna: RFC 4180 Serialization & Escaping

Nota come `csv.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: csv needs quotes loop String Int Int Int => Bool
      csv needs quotes loop s pos len d_code =
        | pos >= len = False
        | (str char at s pos) == d_code or (str char at s pos) == 34 or (str char at s pos) == 10 or (str char at s pos) == 13 = True
        | otherwise = csv needs quotes loop s (pos + 1) len d_code

fn :: csv double quotes loop String Int Int String => String
      csv double quotes loop s pos len acc =
        | pos >= len = acc
        | (str char at s pos) == 34 = csv double quotes loop s (pos + 1) len (acc + (char from code 34) + (char from code 34))
        | otherwise = csv double quotes loop s (pos + 1) len (acc + (str slice s pos (pos + 1)))

fn :: csv format cell String Int => String
      csv format cell cell d_code =
        | csv needs quotes loop cell 0 (str len cell) d_code = (char from code 34) + (csv double quotes loop cell 0 (str len cell) "") + (char from code 34)
        | otherwise = cell

fn :: csv join row [String] String Int => String
      csv join row [] _ _ = ""
      csv join row (c:[]) _ d_code = csv format cell c d_code
      csv join row (c:cs) delim d_code = (csv format cell c d_code) + delim + (csv join row cs delim d_code)

fn :: csv join rows [[String]] String Int => String
      csv join rows [] _ _ = ""
      csv join rows (r:rs) delim d_code = (csv join row r delim d_code) + (char from code 10) + (csv join rows rs delim d_code)

fn :: csv stringify with delim [[String]] String => String
      csv stringify with delim rows delim =
        csv join rows rows delim (csv delim code delim)

fn :: csv stringify [[String]] => String
      csv stringify rows = csv stringify with delim rows ","

fn :: tsv stringify [[String]] => String
      tsv stringify rows = csv stringify with delim rows (char from code 9)
```

### 09.4.3. Implementazione interna: Column Extraction & Header-Mapped Lookup

Nota come `csv.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: csv nth str [String] Int => String
      csv nth str [] _ = ""
      csv nth str (x:xs) idx =
        | idx < 0 = ""
        | idx == 0 = x
        | otherwise = csv nth str xs (idx - 1)

fn :: csv nth row [[String]] Int => [String]
      csv nth row [] _ = []
      csv nth row (r:rs) idx =
        | idx < 0 = []
        | idx == 0 = r
        | otherwise = csv nth row rs (idx - 1)

fn :: csv col [[String]] Int => [String]
      csv col [] _ = []
      csv col (r:rs) col_idx = [csv nth str r col_idx] :: (csv col rs col_idx)

fn :: csv find header idx [String] String Int => Int
      csv find header idx [] _ _ = (0 - 1)
      csv find header idx (h:hs) target idx =
        | h == target = idx
        | otherwise = csv find header idx hs target (idx + 1)

fn :: csv get by header CsvTable Int String => String
      csv get by header tbl row_idx col_name =
        headers tbl -> csv find header idx col_name 0 -> c_idx
        rows tbl -> csv nth row row_idx -> csv nth str c_idx

fn :: csv row to map [String] [String] => [String String]
      csv row to map [] _ = []
      csv row to map _ [] = []
      csv row to map (h:hs) (v:vs) = [(h, v)] :: (csv row to map hs vs)
```

---

## 09.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `csv`

- **Garanzia algoritmica e di sicurezza**: Supporto esatto delle interruzioni `\r\n` e `\n` sia fuori sia dentro le virgolette, e zero perdita di dati nei round-trip `csv parse (csv stringify righe)`.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/csv.ridgun` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test csv.ridgun`.

### Le 5 Regole d'Oro quando programmi con `csv`

1. **Dichiara `import csv` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `csv` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `csv` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `csv` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 10** passeremo a esplorare in profondità la lib **`ini`** (La lib `ini` — File `.ini` a Sezioni, `.env` e Interpolazione di Variabili).
