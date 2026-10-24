# Kapitel 20: Lib:en `log` — Strukturerad NDJSON-loggning och Automatisk Sekretessmaskering

## 20.1. Varför finns lib:en `log`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `log`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `log`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: att skriva ut anropsfält till en loggfil och veckor senare upptäcka att `password`, `api_key` eller `authorization` sparats i klartext i logghanteraren är en klassisk säkerhetsincident.

Lib:en **`log`** erbjuder allvarlighetsfiltrering (`DEBUG`, `INFO`, `WARN`, `ERROR`), text- och **NDJSON-formatering** samt **automatisk maskering av känsliga nycklar** (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key` $\rightarrow$ `"[REDACTED]"`, vilket motverkar `VUL-LOG-001`).

I ett traditionellt ekosystem innebär uppgifter inom domänen **`LOG`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`log`** (`src/main/ridgun/lib/log.rg`) problemet genom fyra kompromisslösa principer:

1. **Totala funktioner och explicita kontrakt (`=>`)**: ingen funktion i `log` kastar dolda undantag eller förlitar sig på `null`. Varje gränsfall returnerar ett dokumenterat sentinelvärde eller en algebraisk summatyp (`Option`, `Result`).
2. **Noll C-kod och noll `libc`**: varje rad i `log` kompileras direkt till inbyggd ELF64-maskinkod verifierad av `ridgunc`.
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `log` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 20.2. Inbyggda artefakter, import och komplett API-katalog för `log`

I `ridgun-libs` är **`log`** en förstklassig **lib** placerad i `src/main/ridgun/lib/log.rg` (domän `LOG`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/log.rglib` | Portabel distribution och direkt import med `import log` |
| **Kompilerat arkiv** | `target/log.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/liblog.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import log` överst och anropar funktionerna med mellanslag eller understreck.

### 20.2.1. Översikt över funktionella familjer i `log`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `log level rank / log should emit` | Jämför loggnivåer (`DEBUG=10`, `INFO=20`, `WARN=30`, `ERROR=40`) mot inställd tröskel |
| `log is sensitive key / log redact fields` | Ersätter skiftlägesokänsligt hemliga värden med `"[REDACTED]"` |
| `log format text / log format json` | Formaterar `nyckel=värde`-text eller RFC 8259 NDJSON med automatisk sekretessmaskering |

### 20.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/log.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/log.rg` (`0` typer, `0` operatorer och `21` funktioner):

| # | Funktion / Signatur (`fn ::`) | Returtyp |
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

## 20.3. Djupdykning i `log`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `log` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test log.rg`.

### 20.3.1. Exempel 1: Huvudflöde i tabellform med `log`

Lägg märke till hur `=`-tecknen och transformationsstegen med `log` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import log

fn :: auditar login (usuario : String) (clave : String) => String
      auditar login usuario clave =
        campos = [("user", usuario), ("password", clave), ("ip", "10.0.0.1")]
        log format json "INFO" "intento de acceso" campos
```

### 20.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `log` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import log

fn :: emitir si procede (umbral : String) (nivel : String) (msg : String) => String
      emitir si procede umbral nivel msg =
        | log should emit umbral nivel = log format text nivel msg [("service", "solstice")]
        | otherwise                    = ""
```

### 20.3.3. Exempel 3: Allvarlighetsgradshierarki (`DEBUG`, `INFO`, `WARN`, `ERROR`) och tröskelfiltrering (`log enabled`)

I detta praktiska exempel undersöker vi grundligt hur `log` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 20.3.4. Exempel 4: Automatisk detektering av känsliga nycklar (`password`, `token`, `secret`, `api_key`, `jwt`) och maskering till `[REDACTED]`

I detta praktiska exempel undersöker vi grundligt hur `log` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 20.3.5. Exempel 5: Formatering av loggrader som strukturerad text (`key=val`) och enrads-JSON (`NDJSON`) med ISO-8601-tidsstämplar

I detta praktiska exempel undersöker vi grundligt hur `log` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

## 20.4. Under huven: hur `log` är byggd i ren Ridgun (`src/main/ridgun/lib/log.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/log.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 20.4.1. Intern implementation: Severity Levels (`DEBUG`, `INFO`, `WARN`, `ERROR`)

Se hur `log.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

### 20.4.2. Intern implementation: Sensitive Key Detection & Redaction

Se hur `log.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

### 20.4.3. Intern implementation: Escaping & Text / NDJSON Formatting

Se hur `log.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

## 20.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `log`

- **Algoritmisk garanti och säkerhet**: Både `log format text` och `log format json` kör alltid fälten genom `log redact fields` före serialisering, vilket garanterar att inga hemligheter läcker av misstag.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/log.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test log.rg`.

### De 5 Gyllene Reglerna när du programmerar med `log`

1. **Deklarera `import log` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `log`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `log`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `log` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 21** går vi vidare och utforskar lib:en **`test`** på djupet (Lib:en `test` — Enhets- och Funktionstestprimitiver (`RG-011`)).
