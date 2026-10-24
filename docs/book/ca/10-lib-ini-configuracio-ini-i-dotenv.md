# Capítol 10: La lib `ini` — Fitxers `.ini` per Seccions, `.env` i Interpolació de Variables

## 10.1. Per què existeix la lib `ini`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `ini` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `ini`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: els fitxers `.env` i `.ini` semblen trivials fins que algú hi afegeix `export KEY="valor # amb coixinet"`, comentaris `;` al final de la línia o referències creuades entre variables.

La lib **`ini`** analitza configuracions `.ini` amb seccions (`[database]`) i fitxers `.env` amb prefixos `export`, preservant símbols `#` i `;` dins de cometes i resolent interpolacions de variables a `dotenv parse`.

En un ecosistema tradicional, resoldre les tasques del domini **`INI`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`ini`** (`src/main/ridgun/lib/ini.rg`) aborda el problema amb quatre principis innegociables:

1. **Funcions totals i contractes explícits (`=>`)**: cap funció de `ini` llança excepcions ocultes ni depèn de `null`. Tot cas límit retorna un valor sentinella documentat o un tipus algebraic suma (`Option`, `Result`).
2. **Zero codi C i zero `libc`**: tot el codi de `ini` compila directament a codi màquina natiu ELF64 verificat per `ridgunc`.
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `ini` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 10.2. Artefactes natius, importació i catàleg complet de l'API de `ini`

A `ridgun-libs`, **`ini`** és una **lib** de primera classe situada a `src/main/ridgun/lib/ini.rg` (domini `INI`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/ini.rglib` | Distribució i importació directa amb `import ini` |
| **Fitxer compilat** | `target/ini.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libini.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import ini` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

### 10.2.1. Resum de famílies funcionals de `ini`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `ini parse / ini stringify` | Analitza text `.ini` per seccions en `IniDoc` i el serialitza de tornada |
| `ini get / ini get int / ini get bool / ini set` | Consultes tipades per secció+clau (`""` per a secció global) i actualització immutable |
| `ini sections / ini section map` | Llista els noms de secció o extreu el mapa `[String String]` d'una secció |
| `dotenv parse` | Analitza fitxers `.env` (`export K=V`, cometes, comentaris i expansió de variables) |

### 10.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/ini.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/ini.rg` (`3` tipus, `0` operadors i `44` funcions):

**Tipus algebraics i registres (`type`) de `ini`:**

```ridgun
type IniEntry = IniEntry String String
type IniSection = section_name: String, entries: [IniEntry]
type IniDoc = sections: [IniSection]
```

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 10.3. Explorant `ini` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `ini` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test ini.rg`.

### 10.3.1. Exemple 1: Flux principal en estil tabular amb `ini`

Observa com en Ridgun els signes `=` i els passos de transformació amb `ini` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

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

### 10.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `ini` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import ini

fn :: actualizar puerto (doc : IniDoc) (nuevo : String) => String
      actualizar puerto doc nuevo =
        doc2 = ini set doc "database" "port" nuevo
        ini stringify doc2
```

### 10.3.3. Exemple 3: Seccions `[seccio]`, comentaris (`;` i `#`), lectures tipades (`get str`, `get int`, `get bool`) i actualització immutable (`ini set`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `ini` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 10.3.4. Exemple 4: Fitxers `.env` amb `export`, cometes, interpolació de variables `${VAR}` i serialització canònica (`ini stringify`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `ini` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 10.3.5. Exemple 5: Configuració jeràrquica d'un servei: fusió de `.env` amb interpolació `${VAR}` i seccions `[database]` / `[server]` en INI

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `ini` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

## 10.4. Sota el capó: com està construïda `ini` en Ridgun pur (`src/main/ridgun/lib/ini.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/ini.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 10.4.1. Implementació interna: Whitespace, Comment & Line Helpers

Fixa't en com `ini.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 10.4.2. Implementació interna: Key-Value Pair Helpers (`[IniEntry]`)

Fixa't en com `ini.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 10.4.3. Implementació interna: Sectioned INI Document Helpers

Fixa't en com `ini.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 10.4.4. Implementació interna: Queries, Updates & Serialization

Fixa't en com `ini.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

## 10.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `ini`

- **Garantia algorísmica i de seguretat**: Respecte total pels caràcters `#` i `;` quan apareixen entre cometes simples o dobles, i conversió booleana flexible (`true/1/yes/on` vs `false/0/no/off`).
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/ini.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test ini.rg`.

### Les 5 Regles d'Or en programar amb `ini`

1. **Declara `import ini` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `ini` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `ini` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `ini` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 11** passarem a explorar en profunditat la lib **`regex`** (La lib `regex` — Motor d'Expressions Regulars Thompson NFA en Temps Lineal $O(N \cdot M)$).
