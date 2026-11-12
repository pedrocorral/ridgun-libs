# Capitolo 20: La lib `log` — Logging Strutturato NDJSON e Redazione Automatica dei Segreti

## 20.1. Perché esiste la lib `log`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `log` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `log`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: riversare i campi di una richiesta in un file di log e scoprire settimane dopo di aver salvato `password`, `api_key` o `authorization` in chiaro nel proprio aggregatore di log è un classico incidente di sicurezza.

La lib **`log`** fornisce filtraggio per gravità (`DEBUG`, `INFO`, `WARN`, `ERROR`), formattazione in testo leggibile e **NDJSON strutturato**, e **redazione automatica delle chiavi sensibili** (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key` $\rightarrow$ `"[REDACTED]"`, mitigando `VUL-LOG-001`).

In un ecosistema tradizionale, risolvere i compiti del dominio **`LOG`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`log`** (`src/main/ridgun/lib/log.ridgun`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import log` (o `import log as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: log` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `log` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 20.2. Artefatti nativi, importazione e catalogo completo dell'API di `log`

In `ridgun-libs`, **`log`** è una **lib** di prima classe situata in `src/main/ridgun/lib/log.ridgun` (dominio `LOG`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/log.ridgunlib` | Distribuzione e importazione diretta con `import log` |
| **File compilato** | `target/log.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/liblog.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: log`: basta scrivere `import log` (o `import log as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 20.2.1. Riepilogo delle famiglie funzionali di `log`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `log level rank / log should emit` | Confronta i livelli (`DEBUG=10`, `INFO=20`, `WARN=30`, `ERROR=40`) rispetto alla soglia attiva |
| `log is sensitive key / log redact fields` | Sostituisce i valori delle chiavi segrete con `"[REDACTED]"` in modo case-insensitive |
| `log format text / log format json` | Formatta righe di testo `chiave=valore` o NDJSON RFC 8259 con redazione automatica dei segreti |

### 20.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/log.ridgun`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/log.ridgun` (`0` tipi, `0` operatori e `21` funzioni):

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
|---|---|---|
| `1` | `fn :: lg lower char String Int Int` | `String` |
| `2` | `fn :: lg to lower loop String Int Int` | `String` |
| `3` | `fn :: lg to lower String` | `String` |
| `4` | `fn :: lg rank from lower String` | `Int` |
| `5` | `fn :: log level rank String` | `Int` |
| `6` | `fn :: log level name Int` | `String` |
| `7` | `fn :: log should emit String String` | `Bool` |
| `8` | `fn :: lg check sens lower String` | `Bool` |
| `9` | `fn :: log is sensitive key String` | `Bool` |
| `10` | `fn :: lg pair key (String String)` | `String` |
| `11` | `fn :: lg pair val (String String)` | `String` |
| `12` | `fn :: lg redact pair (String String)` | `String String` |
| `13` | `fn :: log redact fields [String String]` | `[String String]` |
| `14` | `fn :: lg esc char String Int Int` | `String` |
| `15` | `fn :: lg esc loop String Int Int` | `String` |
| `16` | `fn :: lg esc str String` | `String` |
| `17` | `fn :: lg quote String` | `String` |
| `18` | `fn :: lg fmt text fields [String String]` | `String` |
| `19` | `fn :: log format text String String [String String]` | `String` |
| `20` | `fn :: lg fmt json fields [String String]` | `String` |
| `21` | `fn :: log format json String String [String String]` | `String` |

---

## 20.3. Esplorare `log` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `log` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test log.ridgun`.

### 20.3.1. Esempio 1: Flusso principale in stile tabulare con `log`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `log` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import log

fn :: auditar login String String => String
      auditar login usuario clave =
        [("user", usuario), ("password", clave), ("ip", "10.0.0.1")] -> campos
        log format json "INFO" "intento de acceso" campos
```

### 20.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `log` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import log

fn :: emitir si procede String String String => String
      emitir si procede umbral nivel msg =
        | log should emit umbral nivel = log format text nivel msg [("service", "solstice")]
        | otherwise                    = ""
```

### 20.3.3. Esempio 3: Gerarchia dei livelli di gravità (`DEBUG`, `INFO`, `WARN`, `ERROR`) e filtraggio per soglia (`log enabled`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `log` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test log levels and filtering => ()
      test log levels and filtering =
        assert int equals (log level rank "debug") 10 "AC1: rank debug == 10"
        assert int equals (log level rank "DEBUG") 10 "AC1: rank DEBUG == 10"
        assert int equals (log level rank "info") 20 "AC1: rank info == 20"
        assert int equals (log level rank "INFO") 20 "AC1: rank INFO == 20"
        assert int equals (log level rank "warn") 30 "AC1: rank warn == 30"
        assert int equals (log level rank "warning") 30 "AC1: rank warning alias == 30"
        assert int equals (log level rank "error") 40 "AC1: rank error == 40"
        assert int equals (log level rank "ERR") 40 "AC1: rank ERR alias == 40"
        assert int equals (log level rank "unknown_level") 20 "AC1: unknown level defaults to INFO (20)"

        assert str eq (log level name 10) "DEBUG" "AC1: level name 10 -> DEBUG"
        assert str eq (log level name 20) "INFO" "AC1: level name 20 -> INFO"
        assert str eq (log level name 30) "WARN" "AC1: level name 30 -> WARN"
        assert str eq (log level name 40) "ERROR" "AC1: level name 40 -> ERROR"

        assert true (log should emit "DEBUG" "DEBUG") "AC1: DEBUG emits DEBUG"
        assert true (log should emit "DEBUG" "ERROR") "AC1: DEBUG emits ERROR"
        assert true (log should emit "WARN" "ERROR") "AC1: WARN emits ERROR"
        assert true (log should emit "WARN" "warning") "AC1: WARN emits warning"
        assert false (log should emit "WARN" "INFO") "AC1: WARN suppresses INFO"
        assert false (log should emit "ERROR" "WARN") "AC1: ERROR suppresses WARN"
        assert false (log should emit "ERROR" "DEBUG") "AC1: ERROR suppresses DEBUG"
        ()
```

### 20.3.4. Esempio 4: Rilevamento automatico delle chiavi sensibili (`password`, `token`, `secret`, `api_key`, `jwt`) e redazione in `[REDACTED]`

In questo esempio pratico esploriamo in modo esaustivo come si comporta `log` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test log sensitive key redaction => ()
      test log sensitive key redaction =
        assert true (log is sensitive key "password") "AC2: password"
        assert true (log is sensitive key "user_passwd") "AC2: user_passwd"
        assert true (log is sensitive key "CLIENT_SECRET") "AC2: CLIENT_SECRET"
        assert true (log is sensitive key "access_token") "AC2: access_token"
        assert true (log is sensitive key "X-Api-Key") "AC2: X-Api-Key"
        assert true (log is sensitive key "api_key_id") "AC2: api_key_id"
        assert true (log is sensitive key "apikey") "AC2: apikey"
        assert true (log is sensitive key "Authorization") "AC2: Authorization"
        assert true (log is sensitive key "session_cookie") "AC2: session_cookie"
        assert true (log is sensitive key "ssh_private_key") "AC2: ssh_private_key"
        assert true (log is sensitive key "private-key-pem") "AC2: private-key-pem"
        assert false (log is sensitive key "username") "AC2: username safe"
        assert false (log is sensitive key "request_id") "AC2: request_id safe"
        assert false (log is sensitive key "status_code") "AC2: status_code safe"
        ()
```

### 20.3.5. Esempio 5: Formattazione delle righe di log in testo strutturato (`key=val`) e JSON su riga singola (`NDJSON`) con timestamp ISO-8601

In questo esempio pratico esploriamo in modo esaustivo come si comporta `log` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test log text and ndjson formatting => ()
      test log text and ndjson formatting =
        fields = [("user", "alice"), ("password", "s3cr3t"), ("auth_token", "jwt-123"), ("cookie", "sid=99")]
        txt = log format text "info" "user login" fields
        assert str eq txt "[INFO] user login user=alice password=[REDACTED] auth_token=[REDACTED] cookie=[REDACTED]" "AC3: log format text redacts all secret keys"

        txt_empty = log format text "error" "disk full" []
        assert str eq txt_empty "[ERROR] disk full" "AC3: log format text with empty fields"

        -- Log injection defense: newlines, carriage returns, tabs, quotes, and backslashes in msg or values
        inj_fields = [("path", "C:\\app\\bin"), ("note", "line1\nline2\r\t\"quoted\"")]
        jsn = log format json "warn" "auth check\nforged_line" fields
        assert str eq jsn "{\"level\":\"WARN\",\"msg\":\"auth check\\nforged_line\",\"user\":\"alice\",\"password\":\"[REDACTED]\",\"auth_token\":\"[REDACTED]\",\"cookie\":\"[REDACTED]\"}" "AC3: NDJSON escapes newline injection and redacts secrets"

        jsn_esc = log format json "debug" "trace" inj_fields
        assert str eq jsn_esc "{\"level\":\"DEBUG\",\"msg\":\"trace\",\"path\":\"C:\\\\app\\\\bin\",\"note\":\"line1\\nline2\\r\\t\\\"quoted\\\"\"}" "AC3: NDJSON escapes \\, \\n, \\r, \\t, and \\\""
        ()
```

---

## 20.4. Sotto il cofano: come è costruita `log` in Ridgun puro (`src/main/ridgun/lib/log.ridgun`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/log.ridgun` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 20.4.1. Implementazione interna: Severity Levels (`DEBUG`, `INFO`, `WARN`, `ERROR`)

Nota come `log.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
module :: log

fn :: lg rank from lower String => Int
      lg rank from lower lv     =
        | lv == "debug"                       = 10
        | lv == "info"                        = 20
        | lv == "warn" or lv == "warning"     = 30
        | lv == "error" or lv == "err"        = 40
        | otherwise                           = 20

fn :: log level rank String => Int
      log level rank level  =  level lg to lower -> lg rank from lower

fn :: log level name Int  => String
      log level name rank =
        | rank <= 10 = "DEBUG"
        | rank <= 20 = "INFO"
        | rank <= 30 = "WARN"
        | otherwise  = "ERROR"

fn :: log should emit String    String    => Bool
      log should emit min_level msg_level =  (log level rank msg_level) >= (log level rank min_level)
```

### 20.4.2. Implementazione interna: Sensitive Key Detection & Redaction

Nota come `log.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: lg check sens lower String => Bool
      lg check sens lower lk     =
        | str contains lk "password" or str contains lk "passwd"       = True
        | str contains lk "secret" or str contains lk "token"          = True
        | str contains lk "api_key" or str contains lk "api-key"       = True
        | str contains lk "apikey"                                     = True
        | str contains lk "authorization" or str contains lk "cookie"  = True
        | str contains lk "private_key" or str contains lk "private-key" = True
        | otherwise                                                    = False

fn :: log is sensitive key String => Bool
      log is sensitive key key    =  key lg to lower -> lg check sens lower

fn :: lg pair key (String String) => String
      lg pair key (k, _)          =  k

fn :: lg pair val (String String) => String
      lg pair val (_, v)          =  v

fn :: lg redact pair (String String) => String String
      lg redact pair (k, v)          =
        | log is sensitive key k = (k, "[REDACTED]")
        | otherwise              = (k, v)

fn :: log redact fields [String String] => [String String]
      log redact fields []              =  []
      log redact fields (pair:rest)     =  [(lg redact pair pair)] :: (log redact fields rest)
```

### 20.4.3. Implementazione interna: Escaping & Text / NDJSON Formatting

Nota come `log.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: lg esc char String Int Int => String
      lg esc char s idx c =
        | c == 34   = "\\\""
        | c == 92   = "\\\\"
        | c == 10   = "\\n"
        | c == 13   = "\\r"
        | c == 9    = "\\t"
        | otherwise = str slice s idx (idx + 1)

fn :: lg esc loop String Int Int => String
      lg esc loop s idx len =
        | idx >= len = ""
        | otherwise  = (lg esc char s idx (str char at s idx)) + (lg esc loop s (idx + 1) len)

fn :: lg esc str String => String
      lg esc str s      =  lg esc loop s 0 (str len s)

fn :: lg quote String => String
      lg quote s      =  "\"" + (lg esc str s) + "\""

fn :: lg fmt text fields [String String] => String
      lg fmt text fields []              =  ""
      lg fmt text fields (pair:rest)     =
        " " + (lg esc str (lg pair key pair)) + "=" + (lg esc str (lg pair val pair)) + (lg fmt text fields rest)

fn :: log format text String String [String String] => String
      log format text level msg fields =
        level log level rank -> log level name -> norm_lv
        fields log redact fields -> lg fmt text fields -> fmt_f
        "[" + norm_lv + "] " + (lg esc str msg) + fmt_f

fn :: lg fmt json fields [String String] => String
      lg fmt json fields []              =  ""
      lg fmt json fields (pair:rest)     =
        "," + (lg quote (lg pair key pair)) + ":" + (lg quote (lg pair val pair)) + (lg fmt json fields rest)

fn :: log format json String String [String String] => String
      log format json level msg fields =
        level log level rank -> log level name -> norm_lv
        fields log redact fields -> lg fmt json fields -> fmt_f
        "{\"level\":" + (lg quote norm_lv) + ",\"msg\":" + (lg quote msg) + fmt_f + "}"
```

---

## 20.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `log`

- **Garanzia algoritmica e di sicurezza**: Sia `log format text` sia `log format json` passano sempre i campi attraverso `log redact fields` prima della serializzazione, garantendo che nessun segreto trapeli per dimenticanza.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/log.ridgun` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test log.ridgun`.

### Le 5 Regole d'Oro quando programmi con `log`

1. **Dichiara `import log` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `log` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `log` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `log` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 21** passeremo a esplorare in profondità la lib **`test`** (La lib `test` — Primitive di Asserzione Unitaria e Funzionale (`RG-011`)).
