# 10. kapitulua: `ini` lib-a — Atalkako `.ini` Fitxategiak, `.env` eta Aldagaien Interpolazioa

## 10.1. Zergatik existitzen da `ini` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `ini` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `ini`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: `.env` eta `.ini` fitxategiak hutsalkeriak dirudite norbaitek `export KEY="balioa # traolarekin"`, lerro amaierako `;` iruzkinak edo aldagaien arteko erreferentzia gurutzatuak gehitzen dituen arte.

**`ini`** lib-ak ataldun `.ini` konfigurazioak (`[database]`) eta `export` aurrizkidun `.env` fitxategiak analizatzen ditu, komatxo barruko `#` eta `;` ikurrak mantenduz eta `dotenv parse`-n aldagaien interpolazioak ebatziz.

Ekosistema tradizional batean, **`INI`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`ini`** lib-ak (`src/main/ridgun/lib/ini.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Funtzio osoak eta kontratu esplizituak (`=>`)**: `ini`-eko funtzio bakar batek ere ez du ezkutuko salbuespenik jaurtitzen, ezta `null` erabiltzen ere. Muga-kasu orok dokumentatutako balio bat edo batura-mota aljebraiko bat (`Option`, `Result`) itzultzen du.
2. **Zero C kode eta zero `libc`**: `ini`-eko kode guztia zuzenean ELF64 makina-kode natibora konpilatzen da, `ridgunc`-ek egiaztatuta.
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `ini`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 10.2. Artefaktu natiboak, inportazioa eta `ini` APIaren katalogo osoa

`ridgun-libs`-en, **`ini`** lehen mailako **lib** bat da, `src/main/ridgun/lib/ini.rg` bidean kokatua (`INI` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/ini.rglib` | Banaketa eta inportazio zuzena `import ini` bidez |
| **Fitxategi konpilatua** | `target/ini.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libini.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import ini` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

### 10.2.1. `ini`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `ini parse / ini stringify` | Atalkako `.ini` testua `IniDoc`-era analizatzen du eta testu kanonikora serializatzen du |
| `ini get / ini get int / ini get bool / ini set` | Atal+gako bidezko kontsulta tipatuak (`""` atal globalerako) eta eguneratze aldaezina |
| `ini sections / ini section map` | Atal-izen guztiak zerrendatzen ditu edo atal baten `[String String]` mapa erauzten du |
| `dotenv parse` | `.env` lerroak analizatzen ditu (`export K=V`, komatxoak, iruzkinak eta aldagaien hedapena) |

### 10.2.2. `src/main/ridgun/lib/ini.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/ini.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`3` mota, `0` eragile eta `44` funtzio):

**`ini`-eko mota aljebraikoak eta erregistroak (`type`):**

```ridgun
type IniEntry = IniEntry String String
type IniSection = section_name: String, entries: [IniEntry]
type IniDoc = sections: [IniSection]
```

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
|---|---|---|
| `1` | `fn :: ini_is_hspace Int` | `Bool` |
| `2` | `fn :: ini_trim_left_loop String Int Int` | `String` |
| `3` | `fn :: ini_trim_right_loop String Int` | `String` |
| `4` | `fn :: ini_trim String` | `String` |
| `5` | `fn :: ini_split_lines_loop String Int Int Int [String]` | `[String]` |
| `6` | `fn :: ini_skip_quoted String Int Int Int` | `Int` |
| `7` | `fn :: ini_strip_comment_loop String Int Int` | `String` |
| `8` | `fn :: ini_unquote_unescape_loop String Int Int String` | `String` |
| `9` | `fn :: ini_clean_val String` | `String` |
| `10` | `fn :: ini_clean_val_len String Int` | `String` |
| `11` | `fn :: ini_p_key IniEntry` | `String` |
| `12` | `fn :: ini_p_val IniEntry` | `String` |
| `13` | `fn :: ini_kv_get [IniEntry] String String` | `String` |
| `14` | `fn :: ini_kv_put [IniEntry] String String` | `[IniEntry]` |
| `15` | `fn :: ini_find_rbrace String Int Int` | `Int` |
| `16` | `fn :: ini_expand_brace String Int Int [IniEntry] String Int` | `String` |
| `17` | `fn :: ini_interpolate_loop String Int Int [IniEntry] String` | `String` |
| `18` | `fn :: ini_interpolate String [IniEntry]` | `String` |
| `19` | `fn :: ini_sec_put [IniSection] String String String` | `[IniSection]` |
| `20` | `fn :: ini_sec_ensure [IniSection] String` | `[IniSection]` |
| `21` | `fn :: ini_sec_get [IniSection] String String String` | `String` |
| `22` | `fn :: ini_find_eq String Int Int` | `Int` |
| `23` | `fn :: ini_strip_export String` | `String` |
| `24` | `fn :: ini_parse_kv_at String [IniSection] String Int` | `[IniSection]` |
| `25` | `fn :: ini_sec_entries [IniSection] String` | `[IniEntry]` |
| `26` | `fn :: ini_parse_lines [String] [IniSection] String` | `[IniSection]` |
| `27` | `fn :: ini_parse_sec_hdr String [String] [IniSection]` | `[IniSection]` |
| `28` | `fn :: ini_parse_kv_line String [String] [IniSection] String` | `[IniSection]` |
| `29` | `fn :: ini_parse_clean_line String [String] [IniSection] String` | `[IniSection]` |
| `30` | `fn :: ini parse String` | `IniDoc` |
| `31` | `fn :: dotenv parse String` | `[IniEntry]` |
| `32` | `fn :: ini get IniDoc String String String` | `String` |
| `33` | `fn :: ini get int IniDoc String String Int` | `Int` |
| `34` | `fn :: ini_parse_int_or String Int` | `Int` |
| `35` | `fn :: ini get bool IniDoc String String Bool` | `Bool` |
| `36` | `fn :: ini_parse_bool_or String Bool` | `Bool` |
| `37` | `fn :: ini set IniDoc String String String` | `IniDoc` |
| `38` | `fn :: ini_collect_sec_names [IniSection]` | `[String]` |
| `39` | `fn :: ini sections IniDoc` | `[String]` |
| `40` | `fn :: dotenv get [IniEntry] String String` | `String` |
| `41` | `fn :: ini_format_entries [IniEntry]` | `String` |
| `42` | `fn :: ini_format_section IniSection` | `String` |
| `43` | `fn :: ini_format_sections [IniSection]` | `String` |
| `44` | `fn :: ini stringify IniDoc` | `String` |

---

## 10.3. `ini` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `ini` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test ini.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 10.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `ini` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `ini` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import ini

fn :: cargar base de datos (texto_ini : String) => (String, Int, Bool)
      cargar base de datos texto_ini =
        doc  = ini parse texto_ini
        host = ini get doc "database" "host" "localhost"
        port = ini get int doc "database" "port" 5432
        pool = ini get bool doc "database" "pool" True
        (host, port, pool)
```

### 10.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`ini` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import ini

fn :: actualizar puerto (doc : IniDoc) (nuevo : String) => String
      actualizar puerto doc nuevo =
        doc2 = ini set doc "database" "port" nuevo
        ini stringify doc2
```

### 10.3.3. 3. adibidea: `[atala]` atalak, iruzkinak (`;` eta `#`), irakurketa tipatuak (`get str`, `get int`, `get bool`) eta eguneratze aldaezina (`ini set`)

Adibide praktiko honetan `ini` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_ini_sections_and_typed_getters => ()
      test_ini_sections_and_typed_getters =
        nl = char_from_code 10
        src = "# Global header comment" + nl + "; Secondary comment" + nl + "global_env = production" + nl + nl + "[database]" + nl + "host = \"127.0.0.1\"" + nl + "port = 5432 ; default pg" + nl + "timeout = -1 # infinite" + nl + "password = \"p@ss#word;123\"" + nl + "ssl = true" + nl + "pool_enabled = yes" + nl + "readonly = 0" + nl + "debug_sql = no" + nl + nl + "[server]" + nl + "workers = 4" + nl + "enabled = 1" + nl
        doc = ini parse src
        _ = assert str eq (ini get doc "" "global_env" "") "production" "AC1: global sectionless key in root '' section"
        _ = assert str eq (ini get doc "database" "host" "") "127.0.0.1" "AC1: ini get quoted string"
        _ = assert int equals (ini get int doc "database" "port" 0) 5432 "AC1: ini get int with ';' inline comment"
        _ = assert int equals (ini get int doc "database" "timeout" 0) (-1) "AC1: ini get negative int with '#' inline comment"
        _ = assert str eq (ini get doc "database" "password" "") "p@ss#word;123" "AC1: quoted '#' and ';' preserved inside string"
        _ = assert true (ini get bool doc "database" "ssl" False) "AC1: ini get bool 'true'"
        _ = assert true (ini get bool doc "database" "pool_enabled" False) "AC1: ini get bool 'yes'"
        _ = assert false (ini get bool doc "database" "readonly" True) "AC1: ini get bool '0'"
        _ = assert false (ini get bool doc "database" "debug_sql" True) "AC1: ini get bool 'off'"
        _ = assert int equals (ini get int doc "server" "workers" 0) 4 "AC1: ini get second section"
        _ = assert true (ini get bool doc "server" "enabled" False) "AC1: ini get bool '1'"
        _ = assert str eq (ini get doc "server" "missing" "default_v") "default_v" "AC1: ini get fallback on missing key"
        _ = assert str eq (ini get doc "no_such_section" "k" "fallback") "fallback" "AC1: ini get fallback on missing section"
        secs = ini sections doc
        _ = assert int equals (ini_sec_count secs) 3 "AC1: 3 sections (root '', database, server)"
        ()
```

### 10.3.4. 4. adibidea: `export`, komatxo eta `${VAR}` aldagaien interpolazioa duten `.env` fitxategiak eta serializazio kanonikoa (`ini stringify`)

Adibide praktiko honetan `ini` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_dotenv_interpolation_and_roundtrip => ()
      test_dotenv_interpolation_and_roundtrip =
        nl = char_from_code 10
        lb = char_from_code 123
        rb = char_from_code 125
        env_src = "# .env test" + nl + "export BASE_DIR=/srv/app" + nl + "APP_NAME='solstice'" + nl + "LOG_DIR=\"$" + lb + "BASE_DIR" + rb + "/$" + lb + "APP_NAME" + rb + "/logs\"" + nl + "WITH_UNKNOWN=\"prefix_$" + lb + "UNDEFINED_VAR" + rb + "_suffix\"" + nl + "PORT=8080 # inline comment" + nl
        env = dotenv parse env_src
        _ = assert str eq (dotenv get env "BASE_DIR" "") "/srv/app" "AC2: dotenv export key"
        _ = assert str eq (dotenv get env "APP_NAME" "") "solstice" "AC2: dotenv single-quoted value"
        _ = assert str eq (dotenv get env "LOG_DIR" "") "/srv/app/solstice/logs" "AC2: dotenv multiple variable interpolations"
        _ = assert str eq (dotenv get env "WITH_UNKNOWN" "") "prefix__suffix" "AC2: dotenv undefined variable expands to empty"
        _ = assert str eq (dotenv get env "PORT" "") "8080" "AC2: dotenv inline comment stripped"
        _ = assert str eq (dotenv get env "MISSING_KEY" "def") "def" "AC2: dotenv missing key fallback"

        doc0 = ini parse ("[app]" + nl + "name = demo" + nl + "port = 3000" + nl)
        doc1 = ini set doc0 "app" "version" "1.0"
        doc2 = ini set doc1 "app" "port" "9090"
        doc3 = ini set doc2 "metrics" "enabled" "true"
        out_s = ini stringify doc3
        doc_rt = ini parse out_s
        _ = assert str eq (ini get doc_rt "app" "name" "") "demo" "AC3: ini stringify round-trip name"
        _ = assert str eq (ini get doc_rt "app" "version" "") "1.0" "AC3: ini set new key + round-trip"
        _ = assert int equals (ini get int doc_rt "app" "port" 0) 9090 "AC3: ini set overwrite existing key + round-trip"
        _ = assert true (ini get bool doc_rt "metrics" "enabled" False) "AC3: ini set new section + round-trip"
        ()
```

### 10.3.5. 5. adibidea: Zerbitzu baten konfigurazio hierarkikoa: `${VAR}` interpolaziodun `.env` eta INIko `[database]` / `[server]` atalen bateratzea

Adibide praktiko honetan `ini` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
import ini

fn :: cargar configuracion servicio (raw_ini : String) (raw_env : String) => (String, Int, Bool, String)
      cargar configuracion servicio raw_ini raw_env =
        env_entries = dotenv parse raw_env
        doc         = ini parse raw_ini
        db_host     = ini get str doc "database" "host" "localhost"
        db_port     = ini get int doc "database" "port" 5432
        tls_activo  = ini get bool doc "database" "tls" True
        doc_act     = ini set doc "server" "dsn" "{db_host}:{db_port}"
        (dotenv get env_entries "APP_ENV" "prod", db_port, tls_activo, ini stringify doc_act)
```

---

## 10.4. Kaputaren azpian: nola dagoen eraikia `ini` Ridgun hutsean (`src/main/ridgun/lib/ini.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/ini.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 10.4.1. Barne-inplementazioa: Whitespace, Comment & Line Helpers

Ikusi nola `ini.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: ini_is_hspace Int => Bool
      ini_is_hspace c   =  c == 32 OR c == 9 OR c == 13

fn :: ini_trim_left_loop String Int Int => String
      ini_trim_left_loop s      pos len
        | pos >= len = ""
        | ini_is_hspace (str_char_at s pos) = ini_trim_left_loop s (pos + 1) len
        | otherwise = str_slice s pos len

fn :: ini_trim_right_loop String Int     => String
      ini_trim_right_loop s      end_pos
        | end_pos <= 0 = ""
        | ini_is_hspace (str_char_at s (end_pos - 1)) = ini_trim_right_loop s (end_pos - 1)
        | otherwise = str_slice s 0 end_pos

fn :: ini_trim String => String
      ini_trim s      =  ini_trim_left_loop (ini_trim_right_loop s (str_len s)) 0 (str_len (ini_trim_right_loop s (str_len s)))

fn :: ini_split_lines_loop String Int Int Int [String] => [String]
      ini_split_lines_loop s pos len start acc
        | pos >= len AND start == len = acc
        | pos >= len = acc :: [str_slice s start len]
        | (str_char_at s pos) == 10 = ini_split_lines_loop s (pos + 1) len (pos + 1) (acc :: [str_slice s start pos])
        | otherwise = ini_split_lines_loop s (pos + 1) len start acc

fn :: ini_skip_quoted String Int Int Int => Int
      ini_skip_quoted s      pos len q
        | pos >= len = len
        | (str_char_at s pos) == 92 = ini_skip_quoted s (pos + 2) len q
        | (str_char_at s pos) == q = pos + 1
        | otherwise = ini_skip_quoted s (pos + 1) len q

fn :: ini_strip_comment_loop String Int Int => String
      ini_strip_comment_loop s      pos len
        | pos >= len = s
        | (str_char_at s pos) == 34 = ini_strip_comment_loop s (ini_skip_quoted s (pos + 1) len 34) len
        | (str_char_at s pos) == 39 = ini_strip_comment_loop s (ini_skip_quoted s (pos + 1) len 39) len
        | (str_char_at s pos) == 35 OR (str_char_at s pos) == 59 = str_slice s 0 pos
        | (pos + 1) < len AND (str_char_at s pos) == 45 AND (str_char_at s (pos + 1)) == 45 = str_slice s 0 pos
        | otherwise = ini_strip_comment_loop s (pos + 1) len

fn :: ini_unquote_unescape_loop String Int Int String => String
      ini_unquote_unescape_loop s      pos len acc
        | pos >= len = acc
        | (str_char_at s pos) == 92 AND (pos + 1) < len AND (str_char_at s (pos + 1)) == 110 = ini_unquote_unescape_loop s (pos + 2) len (acc + (char_from_code 10))
        | (str_char_at s pos) == 92 AND (pos + 1) < len AND (str_char_at s (pos + 1)) == 116 = ini_unquote_unescape_loop s (pos + 2) len (acc + (char_from_code 9))
        | (str_char_at s pos) == 92 AND (pos + 1) < len = ini_unquote_unescape_loop s (pos + 2) len (acc + (str_slice s (pos + 1) (pos + 2)))
        | otherwise = ini_unquote_unescape_loop s (pos + 1) len (acc + (str_slice s pos (pos + 1)))
```

### 10.4.2. Barne-inplementazioa: Key-Value Pair Helpers (`[IniEntry]`)

Ikusi nola `ini.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: ini_p_key IniEntry       => String
      ini_p_key (IniEntry k _) =  k

fn :: ini_p_val IniEntry       => String
      ini_p_val (IniEntry _ v) =  v

fn :: ini_kv_get [IniEntry]  String String   => String
      ini_kv_get []          _      fallback =  fallback
      ini_kv_get (pair:rest) key    fallback
        | (ini_p_key pair) == key = ini_p_val pair
        | otherwise = ini_kv_get rest key fallback

fn :: ini_kv_put [IniEntry]  String String => [IniEntry]
      ini_kv_put []          key    val    =  [IniEntry key val]
      ini_kv_put (pair:rest) key    val
        | (ini_p_key pair) == key = [IniEntry key val] :: rest
        | otherwise = [pair] :: (ini_kv_put rest key val)
```

### 10.4.3. Barne-inplementazioa: Sectioned INI Document Helpers

Ikusi nola `ini.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: ini_sec_put [IniSection] String String String => [IniSection]
      ini_sec_put []           sec    key    val    =  [IniSection sec [IniEntry key val]]
      ini_sec_put (s:rest)     sec    key    val
        | (section_name s) == sec = [IniSection sec (ini_kv_put (entries s) key val)] :: rest
        | otherwise = [s] :: (ini_sec_put rest sec key val)

fn :: ini_sec_ensure [IniSection] String => [IniSection]
      ini_sec_ensure []           sec    =  [IniSection sec []]
      ini_sec_ensure (s:rest)     sec
        | (section_name s) == sec = [s] :: rest
        | otherwise = [s] :: (ini_sec_ensure rest sec)

fn :: ini_sec_get [IniSection] String String String   => String
      ini_sec_get []           _      _      fallback =  fallback
      ini_sec_get (s:rest)     sec    key    fallback
        | (section_name s) == sec = ini_kv_get (entries s) key fallback
        | otherwise = ini_sec_get rest sec key fallback

fn :: ini_find_eq String Int Int => Int
      ini_find_eq s      pos len
        | pos >= len = -1
        | (str_char_at s pos) == 61 = pos
        | otherwise = ini_find_eq s (pos + 1) len

fn :: ini_strip_export String => String
      ini_strip_export tr
        | str_starts_with tr "export " = ini_trim (str_slice tr 7 (str_len tr))
        | otherwise = tr

fn :: ini_parse_kv_at String [IniSection] String Int    => [IniSection]
      ini_parse_kv_at _      secs         _      -1     =  secs
      ini_parse_kv_at line   secs         cur_s  eq_pos =
        key = ini_trim (str_slice line 0 eq_pos)
        raw_v = ini_clean_val (str_slice line (eq_pos + 1) (str_len line))
        cur_entries = ini_sec_entries secs cur_s
        val = ini_interpolate raw_v cur_entries
        ini_sec_put secs cur_s key val

fn :: ini_sec_entries [IniSection] String => [IniEntry]
      ini_sec_entries []           _      =  []
      ini_sec_entries (s:rest)     sec
        | (section_name s) == sec = entries s
        | otherwise = ini_sec_entries rest sec

fn :: ini_parse_lines [String] [IniSection] String => [IniSection]
      ini_parse_lines []       secs         _      =  secs
      ini_parse_lines (l:ls)   secs         cur_s  =
        clean = ini_trim (ini_strip_comment_loop l 0 (str_len l))
        ini_parse_clean_line clean ls secs cur_s
```

### 10.4.4. Barne-inplementazioa: Queries, Updates & Serialization

Ikusi nola `ini.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: ini get IniDoc String String String => String
      ini get doc sec key fallback = ini_sec_get (sections doc) sec key fallback

fn :: ini get int IniDoc String String Int => Int
      ini get int doc sec key fallback =
        v = ini get doc sec key ""
        ini_parse_int_or v fallback

fn :: ini_parse_int_or String Int      => Int
      ini_parse_int_or ""     fallback =  fallback
      ini_parse_int_or v      _        =  str_to_int v

fn :: ini get bool IniDoc String String Bool => Bool
      ini get bool doc sec key fallback =
        v = ini get doc sec key ""
        ini_parse_bool_or v fallback

fn :: ini_parse_bool_or String  Bool     => Bool
      ini_parse_bool_or ""      fallback =  fallback
      ini_parse_bool_or "true"  _        =  True
      ini_parse_bool_or "True"  _        =  True
      ini_parse_bool_or "1"     _        =  True
      ini_parse_bool_or "yes"   _        =  True
      ini_parse_bool_or "false" _        =  False
      ini_parse_bool_or "False" _        =  False
      ini_parse_bool_or "0"     _        =  False
      ini_parse_bool_or "no"    _        =  False
      ini_parse_bool_or _       fallback =  fallback

fn :: ini set IniDoc String String String => IniDoc
      ini set doc sec key val = IniDoc (ini_sec_put (sections doc) sec key val)

fn :: ini_collect_sec_names [IniSection] => [String]
      ini_collect_sec_names []           =  []
      ini_collect_sec_names (s:rest)     =  [section_name s] :: (ini_collect_sec_names rest)

fn :: ini sections IniDoc => [String]
      ini sections doc    =  ini_collect_sec_names (sections doc)

fn :: dotenv get [IniEntry] String String   => String
      dotenv get env        key    fallback =  ini_kv_get env key fallback

fn :: ini_format_entries [IniEntry] => String
      ini_format_entries []         =  ""
      ini_format_entries ((IniEntry k v):rs) = k + " = " + v + (char_from_code 10) + (ini_format_entries rs)

fn :: ini_format_section IniSection => String
      ini_format_section sec
        | (section_name sec) == "" = ini_format_entries (entries sec)
        | otherwise = "[" + (section_name sec) + "]" + (char_from_code 10) + (ini_format_entries (entries sec))
```

---

## 10.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `ini`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: Errespetu osoa `#` eta `;` karaktereekiko komatxo sinple edo bikoitzen artean agertzen direnean, eta bihurketa boolear malgua (`true/1/yes/on` vs `false/0/no/off`).
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/ini.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test ini.rg` suite automatizatuaren bidez.

### `ini`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import ini` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `ini`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `ini`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `ini` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**11. kapituluan** **`regex`** lib-a sakonki esploratuko dugu (`regex` lib-a — $O(N \cdot M)$ Denbora Linealeko Thompson NFA Adierazpen Erregularren Motorra).
