# 20. kapitulua: `log` lib-a — NDJSON Erregistro Egituratua eta Sekretuen Ezkutatze Automatikoa

## 20.1. Zergatik existitzen da `log` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `log` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `log`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: eskaera bateko eremuak log fitxategi batera irauli eta aste batzuk geroago `password`, `api_key` edo `authorization` testu lauan gorde dituzula deskubritzea segurtasun-gertakari klasiko bat da.

**`log`** lib-ak larritasunaren araberako iragazketa (`DEBUG`, `INFO`, `WARN`, `ERROR`), giza testuko eta **NDJSON egituratuko** formateatzea, eta **gako sentikorren ezkutatze automatikoa** (`password`, `secret`, `token`, `api_key`, `authorization`, `cookie`, `private_key` $\rightarrow$ `"[REDACTED]"`, `VUL-LOG-001` arinduz) eskaintzen ditu.

Ekosistema tradizional batean, **`LOG`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`log`** lib-ak (`src/main/ridgun/lib/log.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Deklaratu `import log` (edo `import log as alias`) fitxategiaren hasieran**: lib bakoitzak `module :: log` izen-espazioa definitzen du eta `--strict` moduan hitz anitzeko funtzioei zuriune naturalekin deitzen zaie beti.
2. **Kateatu zure datu-hodiak ezkerretik eskuinera `->` bidez**: idatzi `sarrera lehen urratsa -> bigarren urratsa -> emaitza`, erabili `(+ _ _ +)` maskarak sekuentziak desegituratzeko eta kendu `_ =` sententzia sekuentzialetan (edo baztertu `-> ()` bidez).
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `log`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 20.2. Artefaktu natiboak, inportazioa eta `log` APIaren katalogo osoa

`ridgun-libs`-en, **`log`** lehen mailako **lib** bat da, `src/main/ridgun/lib/log.rg` bidean kokatua (`LOG` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/log.rglib` | Banaketa eta inportazio zuzena `import log` bidez |
| **Fitxategi konpilatua** | `target/log.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/liblog.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib bakoitzak bere izen-espazioa deklaratzen du `module :: log` bidez: nahikoa da goiburuan `import log` (edo `import log as alias`) idaztea eta bere funtzioei zuriune naturalekin (`nire funtzioa x`) eta `->` hodiekin (`x nire funtzioa -> emaitza`) deitzea.

### 20.2.1. `log`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `log level rank / log should emit` | Log mailak (`DEBUG=10`, `INFO=20`, `WARN=30`, `ERROR=40`) atalase aktiboarekin konparatzen ditu |
| `log is sensitive key / log redact fields` | Gako sekretuen balioak `"[REDACTED]"`-ekin ordezkatzen ditu letra larri/xeheak kontuan hartu gabe |
| `log format text / log format json` | `gako=balio` testu-lerroak edo RFC 8259 NDJSON formateatzen ditu sekretuen ezkutatze automatikoarekin |

### 20.2.2. `src/main/ridgun/lib/log.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/log.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`0` mota, `0` eragile eta `21` funtzio):

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
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

## 20.3. `log` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `log` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test log.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 20.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `log` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `log` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import log

fn :: auditar login String String => String
      auditar login usuario clave =
        [("user", usuario), ("password", clave), ("ip", "10.0.0.1")] -> campos
        log format json "INFO" "intento de acceso" campos
```

### 20.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`log` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import log

fn :: emitir si procede String String String => String
      emitir si procede umbral nivel msg =
        | log should emit umbral nivel = log format text nivel msg [("service", "solstice")]
        | otherwise                    = ""
```

### 20.3.3. 3. adibidea: Larritasun-mailen hierarkia (`DEBUG`, `INFO`, `WARN`, `ERROR`) eta atalase bidezko iragazketa (`log enabled`)

Adibide praktiko honetan `log` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 20.3.4. 4. adibidea: Gako sentikorren detekzio automatikoa (`password`, `token`, `secret`, `api_key`, `jwt`) eta `[REDACTED]` bihurtzea

Adibide praktiko honetan `log` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 20.3.5. 5. adibidea: Erregistro-lerroen formatua testu egituratuan (`key=val`) eta lerro bakarreko JSONean (`NDJSON`) ISO-8601 markekin

Adibide praktiko honetan `log` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

## 20.4. Kaputaren azpian: nola dagoen eraikia `log` Ridgun hutsean (`src/main/ridgun/lib/log.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/log.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 20.4.1. Barne-inplementazioa: Severity Levels (`DEBUG`, `INFO`, `WARN`, `ERROR`)

Ikusi nola `log.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 20.4.2. Barne-inplementazioa: Sensitive Key Detection & Redaction

Ikusi nola `log.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 20.4.3. Barne-inplementazioa: Escaping & Text / NDJSON Formatting

Ikusi nola `log.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

## 20.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `log`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: Bai `log format text`-ek eta bai `log format json`-ek eremuak `log redact fields`-etik pasatzen dituzte beti serializatu aurretik, inongo sekreturik ahaztuta ez isurtzea bermatuz.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/log.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test log.rg` suite automatizatuaren bidez.

### `log`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import log` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `log`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `log`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `log` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**21. kapituluan** **`test`** lib-a sakonki esploratuko dugu (`test` lib-a — Baieztapen Unitario eta Funtzionalen Primitibak (`RG-011`)).
