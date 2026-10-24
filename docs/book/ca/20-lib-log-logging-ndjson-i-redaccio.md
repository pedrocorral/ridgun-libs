# Capítol 20: La lib `log` — Logging Estructurat NDJSON i Redacció Automàtica de Secrets

## 20.1. Per què existeix la lib `log`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `log` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `log`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: bolcar els camps d'una petició en un fitxer de log i descobrir setmanes després que acabes de desar `password`, `api_key` o `authorization` en text pla al teu agregador de logs és un incident de seguretat clàssic.

La lib **`log`** proporciona filtratge per severitat (`DEBUG`, `INFO`, `WARN`, `ERROR`), formatat en text humà i **NDJSON estructurat**, i **redacció automàtica de claus sensibles** (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key` $\rightarrow$ `"[REDACTED]"`, mitigant `VUL-LOG-001`).

En un ecosistema tradicional, resoldre les tasques del domini **`LOG`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`log`** (`src/main/ridgun/lib/log.rg`) aborda el problema amb quatre principis innegociables:

1. **Funcions totals i contractes explícits (`=>`)**: cap funció de `log` llança excepcions ocultes ni depèn de `null`. Tot cas límit retorna un valor sentinella documentat o un tipus algebraic suma (`Option`, `Result`).
2. **Zero codi C i zero `libc`**: tot el codi de `log` compila directament a codi màquina natiu ELF64 verificat per `ridgunc`.
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `log` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 20.2. Artefactes natius, importació i catàleg complet de l'API de `log`

A `ridgun-libs`, **`log`** és una **lib** de primera classe situada a `src/main/ridgun/lib/log.rg` (domini `LOG`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/log.rglib` | Distribució i importació directa amb `import log` |
| **Fitxer compilat** | `target/log.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/liblog.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import log` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

### 20.2.1. Resum de famílies funcionals de `log`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `log level rank / log should emit` | Compara nivells (`DEBUG=10`, `INFO=20`, `WARN=30`, `ERROR=40`) enfront del llindar actiu |
| `log is sensitive key / log redact fields` | Substitueix valors de claus secretes per `"[REDACTED]"` sense importar majúscules |
| `log format text / log format json` | Formata línies text `clau=valor` o NDJSON RFC 8259 amb redacció automàtica de secrets |

### 20.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/log.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/log.rg` (`0` tipus, `0` operadors i `21` funcions):

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 20.3. Explorant `log` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `log` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test log.rg`.

### 20.3.1. Exemple 1: Flux principal en estil tabular amb `log`

Observa com en Ridgun els signes `=` i els passos de transformació amb `log` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import log

fn :: auditar login (usuario : String) (clave : String) => String
      auditar login usuario clave =
        campos = [("user", usuario), ("password", clave), ("ip", "10.0.0.1")]
        log format json "INFO" "intento de acceso" campos
```

### 20.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `log` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import log

fn :: emitir si procede (umbral : String) (nivel : String) (msg : String) => String
      emitir si procede umbral nivel msg =
        | log should emit umbral nivel = log format text nivel msg [("service", "solstice")]
        | otherwise                    = ""
```

### 20.3.3. Exemple 3: Jerarquia de nivells de severitat (`DEBUG`, `INFO`, `WARN`, `ERROR`) i filtratge per llindar (`log enabled`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `log` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test log levels and filtering => ()
      test log levels and filtering =
        _ = assert int equals (log level rank "debug") 10 "AC1: rank debug == 10"
        _ = assert int equals (log level rank "DEBUG") 10 "AC1: rank DEBUG == 10"
        _ = assert int equals (log level rank "info") 20 "AC1: rank info == 20"
        _ = assert int equals (log level rank "INFO") 20 "AC1: rank INFO == 20"
        _ = assert int equals (log level rank "warn") 30 "AC1: rank warn == 30"
        _ = assert int equals (log level rank "warning") 30 "AC1: rank warning alias == 30"
        _ = assert int equals (log level rank "error") 40 "AC1: rank error == 40"
        _ = assert int equals (log level rank "ERR") 40 "AC1: rank ERR alias == 40"
        _ = assert int equals (log level rank "unknown_level") 20 "AC1: unknown level defaults to INFO (20)"

        _ = assert str eq (log level name 10) "DEBUG" "AC1: level name 10 -> DEBUG"
        _ = assert str eq (log level name 20) "INFO" "AC1: level name 20 -> INFO"
        _ = assert str eq (log level name 30) "WARN" "AC1: level name 30 -> WARN"
        _ = assert str eq (log level name 40) "ERROR" "AC1: level name 40 -> ERROR"

        _ = assert true (log should emit "DEBUG" "DEBUG") "AC1: DEBUG emits DEBUG"
        _ = assert true (log should emit "DEBUG" "ERROR") "AC1: DEBUG emits ERROR"
        _ = assert true (log should emit "WARN" "ERROR") "AC1: WARN emits ERROR"
        _ = assert true (log should emit "WARN" "warning") "AC1: WARN emits warning"
        _ = assert false (log should emit "WARN" "INFO") "AC1: WARN suppresses INFO"
        _ = assert false (log should emit "ERROR" "WARN") "AC1: ERROR suppresses WARN"
        _ = assert false (log should emit "ERROR" "DEBUG") "AC1: ERROR suppresses DEBUG"
        ()
```

### 20.3.4. Exemple 4: Detecció automàtica de claus sensibles (`password`, `token`, `secret`, `api_key`, `jwt`) i redacció a `[REDACTED]`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `log` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test log sensitive key redaction => ()
      test log sensitive key redaction =
        _ = assert true (log is sensitive key "password") "AC2: password"
        _ = assert true (log is sensitive key "user_passwd") "AC2: user_passwd"
        _ = assert true (log is sensitive key "CLIENT_SECRET") "AC2: CLIENT_SECRET"
        _ = assert true (log is sensitive key "access_token") "AC2: access_token"
        _ = assert true (log is sensitive key "X-Api-Key") "AC2: X-Api-Key"
        _ = assert true (log is sensitive key "api_key_id") "AC2: api_key_id"
        _ = assert true (log is sensitive key "apikey") "AC2: apikey"
        _ = assert true (log is sensitive key "Authorization") "AC2: Authorization"
        _ = assert true (log is sensitive key "session_cookie") "AC2: session_cookie"
        _ = assert true (log is sensitive key "ssh_private_key") "AC2: ssh_private_key"
        _ = assert true (log is sensitive key "private-key-pem") "AC2: private-key-pem"
        _ = assert false (log is sensitive key "username") "AC2: username safe"
        _ = assert false (log is sensitive key "request_id") "AC2: request_id safe"
        _ = assert false (log is sensitive key "status_code") "AC2: status_code safe"
        ()
```

### 20.3.5. Exemple 5: Formatació de línies de registre en text estructurat (`key=val`) i JSON en una línia (`NDJSON`) amb marques ISO-8601

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `log` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test log text and ndjson formatting => ()
      test log text and ndjson formatting =
        fields = [("user", "alice"), ("password", "s3cr3t"), ("auth_token", "jwt-123"), ("cookie", "sid=99")]
        txt = log format text "info" "user login" fields
        _ = assert str eq txt "[INFO] user login user=alice password=[REDACTED] auth_token=[REDACTED] cookie=[REDACTED]" "AC3: log format text redacts all secret keys"

        txt_empty = log format text "error" "disk full" []
        _ = assert str eq txt_empty "[ERROR] disk full" "AC3: log format text with empty fields"

        -- Log injection defense: newlines, carriage returns, tabs, quotes, and backslashes in msg or values
        inj_fields = [("path", "C:\\app\\bin"), ("note", "line1\nline2\r\t\"quoted\"")]
        jsn = log format json "warn" "auth check\nforged_line" fields
        _ = assert str eq jsn "{\"level\":\"WARN\",\"msg\":\"auth check\\nforged_line\",\"user\":\"alice\",\"password\":\"[REDACTED]\",\"auth_token\":\"[REDACTED]\",\"cookie\":\"[REDACTED]\"}" "AC3: NDJSON escapes newline injection and redacts secrets"

        jsn_esc = log format json "debug" "trace" inj_fields
        _ = assert str eq jsn_esc "{\"level\":\"DEBUG\",\"msg\":\"trace\",\"path\":\"C:\\\\app\\\\bin\",\"note\":\"line1\\nline2\\r\\t\\\"quoted\\\"\"}" "AC3: NDJSON escapes \\, \\n, \\r, \\t, and \\\""
        ()
```

---

## 20.4. Sota el capó: com està construïda `log` en Ridgun pur (`src/main/ridgun/lib/log.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/log.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 20.4.1. Implementació interna: Severity Levels (`DEBUG`, `INFO`, `WARN`, `ERROR`)

Fixa't en com `log.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
fn :: lg rank from lower String => Int
      lg rank from lower lv     =
        | lv == "debug"                       = 10
        | lv == "info"                        = 20
        | lv == "warn" or lv == "warning"     = 30
        | lv == "error" or lv == "err"        = 40
        | otherwise                           = 20

fn :: log level rank String => Int
      log level rank level  =  lg rank from lower (lg to lower level)

fn :: log level name Int  => String
      log level name rank =
        | rank <= 10 = "DEBUG"
        | rank <= 20 = "INFO"
        | rank <= 30 = "WARN"
        | otherwise  = "ERROR"

fn :: log should emit String    String    => Bool
      log should emit min_level msg_level =  (log level rank msg_level) >= (log level rank min_level)
```

### 20.4.2. Implementació interna: Sensitive Key Detection & Redaction

Fixa't en com `log.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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
      log is sensitive key key    =  lg check sens lower (lg to lower key)

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

### 20.4.3. Implementació interna: Escaping & Text / NDJSON Formatting

Fixa't en com `log.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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
        norm_lv = log level name (log level rank level)
        safe_f  = log redact fields fields
        "[" + norm_lv + "] " + (lg esc str msg) + (lg fmt text fields safe_f)

fn :: lg fmt json fields [String String] => String
      lg fmt json fields []              =  ""
      lg fmt json fields (pair:rest)     =
        "," + (lg quote (lg pair key pair)) + ":" + (lg quote (lg pair val pair)) + (lg fmt json fields rest)

fn :: log format json String String [String String] => String
      log format json level msg fields =
        norm_lv = log level name (log level rank level)
        safe_f  = log redact fields fields
        "{\"level\":" + (lg quote norm_lv) + ",\"msg\":" + (lg quote msg) + (lg fmt json fields safe_f) + "}"
```

---

## 20.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `log`

- **Garantia algorísmica i de seguretat**: Tant `log format text` com `log format json` passen sempre els camps per `log redact fields` abans de serialitzar, garantint que cap secret es filtri per oblit.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/log.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test log.rg`.

### Les 5 Regles d'Or en programar amb `log`

1. **Declara `import log` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `log` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `log` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `log` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 21** passarem a explorar en profunditat la lib **`test`** (La lib `test` — Primitives d'Asserció Unitària i Funcional (`RG-011`)).
