# Kapitel 07: Lib:en `codec` — RFC 4648 Hex, Base64, Base64url och URL-kodning

## 07.1. Varför finns lib:en `codec`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `codec`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `codec`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: inget kraschar en webbintegration snabbare än att blanda ihop standard-Base64 (`+/=`) med URL-säker Base64url (`-_` utan utfyllnad) i en JWT, eller att bygga query-strängar utan att koda specialtecken.

Lib:en **`codec`** implementerar **RFC 4648** (Hex, Base64 och Base64url), **RFC 3986** (procentkodning av URL:er samt `query encode` / `query decode`) och lättviktiga **RFC 8259 JSON**-byggare.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`CODEC`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`codec`** (`src/main/ridgun/lib/codec.rg`) problemet genom fyra kompromisslösa principer:

1. **Totala funktioner och explicita kontrakt (`=>`)**: ingen funktion i `codec` kastar dolda undantag eller förlitar sig på `null`. Varje gränsfall returnerar ett dokumenterat sentinelvärde eller en algebraisk summatyp (`Option`, `Result`).
2. **Noll C-kod och noll `libc`**: varje rad i `codec` kompileras direkt till inbyggd ELF64-maskinkod verifierad av `ridgunc`.
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `codec` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 07.2. Inbyggda artefakter, import och komplett API-katalog för `codec`

I `ridgun-libs` är **`codec`** en förstklassig **lib** placerad i `src/main/ridgun/lib/codec.rg` (domän `CODEC`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/codec.rglib` | Portabel distribution och direkt import med `import codec` |
| **Kompilerat arkiv** | `target/codec.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libcodec.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import codec` överst och anropar funktionerna med mellanslag eller understreck.

### 07.2.1. Översikt över funktionella familjer i `codec`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `hex encode / hex decode / hex is valid` | Hexadecimal kodning i gemener enligt RFC 4648 och validerad avkodning |
| `base64 encode / base64 decode` | Standard Base64 enligt RFC 4648 §4 med `=`-utfyllnad |
| `base64url encode / base64url decode` | URL-säker RFC 4648 §5 Base64url (`-`, `_`, utan utfyllnad) |
| `url encode / url decode / query encode / query decode` | RFC 3986-procentkodning och `k=v&...` query-strängkonvertering |
| `json quote / json object / json get str / json get int` | Snabb JSON-serialisering utan AST och nyckeluppslagning på toppnivå |

### 07.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/codec.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/codec.rg` (`0` typer, `0` operatorer och `86` funktioner):

| # | Funktion / Signatur (`fn ::`) | Returtyp |
|---|---|---|
| `1` | `fn :: cd raw byte ub Int` | `String` |
| `2` | `fn :: cd raw byte Int` | `String` |
| `3` | `fn :: cd hex lut Int` | `String` |
| `4` | `fn :: cd hex up lut Int` | `String` |
| `5` | `fn :: cd b64 lut Int` | `String` |
| `6` | `fn :: cd b64url lut Int` | `String` |
| `7` | `fn :: cd index of loop String String Int Int Int` | `Int` |
| `8` | `fn :: cd index of String String` | `Int` |
| `9` | `fn :: cd split char loop String Int Int Int Int` | `[String]` |
| `10` | `fn :: cd hex val Int` | `Int` |
| `11` | `fn :: cd valid hex loop String Int Int` | `Bool` |
| `12` | `fn :: cd is valid hex len String Int` | `Bool` |
| `13` | `fn :: is valid hex String` | `Bool` |
| `14` | `fn :: cd hex enc byte Int` | `String` |
| `15` | `fn :: cd hex enc loop String Int Int` | `String` |
| `16` | `fn :: hex encode String` | `String` |
| `17` | `fn :: cd hex dec loop String Int Int` | `String` |
| `18` | `fn :: hex decode String` | `String` |
| `19` | `fn :: cd b64 char String Int` | `String` |
| `20` | `fn :: cd b64 pad suffix String Bool` | `String` |
| `21` | `fn :: cd b64 enc step String Int String Bool Int` | `String` |
| `22` | `fn :: cd b64 enc rem String Int String Bool` | `String` |
| `23` | `fn :: base64 encode String` | `String` |
| `24` | `fn :: base64url encode String` | `String` |
| `25` | `fn :: cd b64 val Int` | `Int` |
| `26` | `fn :: cd strip b64 pad String Int` | `String` |
| `27` | `fn :: cd valid b64 body String Int Int` | `Bool` |
| `28` | `fn :: cd valid b64 raw String Int` | `Bool` |
| `29` | `fn :: is valid base64 String` | `Bool` |
| `30` | `fn :: cd b64 dec step String Int Int Int` | `String` |
| `31` | `fn :: cd b64 dec loop String Int Int` | `String` |
| `32` | `fn :: base64 decode String` | `String` |
| `33` | `fn :: base64url decode String` | `String` |
| `34` | `fn :: cd is unreserved Int` | `Bool` |
| `35` | `fn :: cd pct byte Int` | `String` |
| `36` | `fn :: cd url enc char String Int Int` | `String` |
| `37` | `fn :: cd url enc loop String Int Int` | `String` |
| `38` | `fn :: url encode String` | `String` |
| `39` | `fn :: cd url dec pct String Int Int Int Int` | `String` |
| `40` | `fn :: cd url dec at String Int Int Int` | `String` |
| `41` | `fn :: cd url dec loop String Int Int` | `String` |
| `42` | `fn :: url decode String` | `String` |
| `43` | `fn :: cd pair key (String String)` | `String` |
| `44` | `fn :: cd pair val (String String)` | `String` |
| `45` | `fn :: query string encode [String String]` | `String` |
| `46` | `fn :: cd parse kv at String Int` | `String String` |
| `47` | `fn :: cd parse kv item String` | `String String` |
| `48` | `fn :: cd parse qs list [String]` | `[String String]` |
| `49` | `fn :: cd strip leading q String` | `String` |
| `50` | `fn :: cd decode clean qs String` | `[String String]` |
| `51` | `fn :: query string decode String` | `[String String]` |
| `52` | `fn :: cd json esc code String Int Int` | `String` |
| `53` | `fn :: cd json esc loop String Int Int` | `String` |
| `54` | `fn :: json escape String` | `String` |
| `55` | `fn :: cd json unesc next String Int Int Int` | `String` |
| `56` | `fn :: cd json unesc loop String Int Int` | `String` |
| `57` | `fn :: json unescape String` | `String` |
| `58` | `fn :: json quote String` | `String` |
| `59` | `fn :: json int Int` | `String` |
| `60` | `fn :: json bool Bool` | `String` |
| `61` | `fn :: json null` | `String` |
| `62` | `fn :: cd join json items [String]` | `String` |
| `63` | `fn :: json array [String]` | `String` |
| `64` | `fn :: cd join json pairs [String String]` | `String` |
| `65` | `fn :: json object [String String]` | `String` |
| `66` | `fn :: cd quote pair vals [String String]` | `[String String]` |
| `67` | `fn :: json str object [String String]` | `String` |
| `68` | `fn :: cd is json ws Int` | `Bool` |
| `69` | `fn :: cd skip key sep String Int Int` | `Int` |
| `70` | `fn :: cd scan json str end String Int Int` | `Int` |
| `71` | `fn :: cd is tok delim Int` | `Bool` |
| `72` | `fn :: cd scan json tok end String Int Int` | `Int` |
| `73` | `fn :: cd extract json str vend String Int Int` | `String` |
| `74` | `fn :: cd extract json str vstart String Int` | `String` |
| `75` | `fn :: cd extract json str kpos String String Int` | `String` |
| `76` | `fn :: json get str String String` | `String` |
| `77` | `fn :: cd is signed int loop String Int Int` | `Bool` |
| `78` | `fn :: cd is valid int len String Int` | `Bool` |
| `79` | `fn :: cd is valid int str String` | `Bool` |
| `80` | `fn :: cd raw tok vstart String Int` | `String` |
| `81` | `fn :: cd raw tok kpos String String Int` | `String` |
| `82` | `fn :: cd raw json token String String` | `String` |
| `83` | `fn :: cd parse tok int String Int` | `Int` |
| `84` | `fn :: json get int String String Int` | `Int` |
| `85` | `fn :: cd parse tok bool String Bool` | `Bool` |
| `86` | `fn :: json get bool String String Bool` | `Bool` |

---

## 07.3. Djupdykning i `codec`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `codec` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test codec.rg`.

### 07.3.1. Exempel 1: Huvudflöde i tabellform med `codec`

Lägg märke till hur `=`-tecknen och transformationsstegen med `codec` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import codec

fn :: empaquetar parametros (usuario : String) (redir : String) => String
      empaquetar parametros usuario redir =
        token_b64 = base64url encode usuario
        query encode [("token", token_b64), ("next", redir)]
```

### 07.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `codec` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import codec

fn :: construir respuesta rapida (id : Int) (nombre : String) => (String, Int)
      construir respuesta rapida id nombre =
        doc = json object [("id", json int id), ("name", json quote nombre), ("ok", json bool True)]
        leido = json get int doc "id" 0
        (doc, leido)
```

### 07.3.3. Exempel 3: RFC 4648 Hexadecimal, standard Base64 och URL-säker Base64url-kodning och avkodning

I detta praktiska exempel undersöker vi grundligt hur `codec` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test rfc4648 hex and base64 => ()
      test rfc4648 hex and base64 =
        -- 1. Hexadecimal RFC 4648 test vectors & negative validation
        _ = assert str eq (hex encode "") "" "hex_encode empty"
        _ = assert str eq (hex encode "foobar") "666f6f626172" "hex_encode foobar"
        _ = assert str eq (hex decode "666f6f626172") "foobar" "hex_decode lowercase"
        _ = assert str eq (hex decode "666F6F626172") "foobar" "hex_decode uppercase"
        _ = assert true (is valid hex "deadBEEF09") "is_valid_hex valid"
        _ = assert false (is valid hex "abc") "is_valid_hex odd length"
        _ = assert false (is valid hex "deadZZ") "is_valid_hex invalid chars"
        _ = assert str eq (hex decode "abc") "" "hex_decode odd -> empty"

        -- 2. Base64 & Base64url RFC 4648 test vectors
        _ = assert str eq (base64 encode "") "" "b64 empty"
        _ = assert str eq (base64 encode "f") "Zg==" "b64 f"
        _ = assert str eq (base64 encode "fo") "Zm8=" "b64 fo"
        _ = assert str eq (base64 encode "foo") "Zm9v" "b64 foo"
        _ = assert str eq (base64 encode "foob") "Zm9vYg==" "b64 foob"
        _ = assert str eq (base64 encode "fooba") "Zm9vYmE=" "b64 fooba"
        _ = assert str eq (base64 encode "foobar") "Zm9vYmFy" "b64 foobar"
        _ = assert str eq (base64 decode "Zg==") "f" "b64 dec f"
        _ = assert str eq (base64 decode "Zm8=") "fo" "b64 dec fo"
        _ = assert str eq (base64 decode "Zm9v") "foo" "b64 dec foo"
        _ = assert str eq (base64 decode "Zm9vYg==") "foob" "b64 dec foob"
        _ = assert str eq (base64 decode "Zm9vYmE=") "fooba" "b64 dec fooba"
        _ = assert str eq (base64 decode "Zm9vYmFy") "foobar" "b64 dec foobar"
        _ = assert str eq (base64url encode "foob") "Zm9vYg" "b64url nopad"
        _ = assert str eq (base64url decode "Zm9vYg") "foob" "b64url dec"
        _ = assert false (is valid base64 "A") "invalid base64 len%4==1"
        _ = assert false (is valid base64 "Zm$v") "invalid base64 char"
        _ = assert str eq (base64 decode "Zm$v") "" "invalid base64 -> empty"

        -- 3. LIB-8: Binary-safe decoding for raw octets >= 0x80 and 0x00
        raw4 = hex decode "c800ff41"
        _    = assert int equals (str len raw4) 4 "str_len (hex_decode c800ff41) == 4"
        _    = assert int equals (str char at raw4 0) 200 "raw4[0] == 0xc8"
        _    = assert int equals (str char at raw4 1) 0 "raw4[1] == 0x00"
        _    = assert int equals (str char at raw4 2) 255 "raw4[2] == 0xff"
        _    = assert int equals (str char at raw4 3) 65 "raw4[3] == 0x41"
        _    = assert str eq (hex encode raw4) "c800ff41" "hex_encode raw4 == c800ff41"
        _    = check binary roundtrip loop 10
        ()
```

### 07.3.4. Exempel 4: RFC 3986 procentkodning (`url encode`, `url decode`) och frågesträngar (`query encode`, `query get`)

I detta praktiska exempel undersöker vi grundligt hur `codec` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test rfc3986 url and query strings => ()
      test rfc3986 url and query strings =
        raw = "hello world&x=1+2%"
        enc = url encode raw
        _   = assert str eq enc "hello%20world%26x%3D1%2B2%25" "url_encode"
        _   = assert str eq (url decode enc) raw "url_decode roundtrip"
        _   = assert str eq (url decode "a+b%20c") "a b c" "url_decode plus as space"
        qs  = query string encode [("q", "ridgun libs"), ("page", "2")]
        _   = assert str eq qs "q=ridgun%20libs&page=2" "query_string_encode"
        dec = query string decode ("?" + qs)
        _   = assert eq dec [("q", "ridgun libs"), ("page", "2")]
        ()
```

### 07.3.5. Exempel 5: RFC 8259 lättvikts-JSON-flyktsekvenser och fältextraktion (`json escape`, `json unescape`, `json encode kv`, `json get str/int/bool`)

I detta praktiska exempel undersöker vi grundligt hur `codec` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test rfc8259 lightweight json => ()
      test rfc8259 lightweight json =
        esc = json escape "line1\n\"quoted\"\\tab\t"
        _   = assert str eq esc "line1\\n\\\"quoted\\\"\\\\tab\\t" "json_escape"
        _   = assert str eq (json unescape esc) "line1\n\"quoted\"\\tab\t" "json_unescape"
        doc = json object [("service", json quote "solstice"), ("port", json int 8443), ("tls", json bool True), ("extra", json null)]
        _   = assert str eq doc "{\"service\":\"solstice\",\"port\":8443,\"tls\":true,\"extra\":null}" "json_object"
        _   = assert str eq (json get str doc "service") "solstice" "json_get_str"
        _   = assert str eq (json get str doc "missing") "" "json_get_str missing"
        _   = assert int equals (json get int doc "port" 80) 8443 "json_get_int"
        _   = assert int equals (json get int doc "missing" 80) 80 "json_get_int fallback"
        _   = assert int equals (json get int doc "service" 80) 80 "json_get_int non-int fallback"
        _   = assert true (json get bool doc "tls" False) "json_get_bool"
        _   = assert false (json get bool doc "missing" False) "json_get_bool fallback"
        arr = json array [json int 1, json int 2, json quote "three"]
        _   = assert str eq arr "[1,2,\"three\"]" "json_array"
        s_o = json str object [("k1", "v1"), ("k2", "v\"2")]
        _   = assert str eq (json get str s_o "k2") "v\"2" "json_str_object escaped roundtrip"
        ()
```

---

## 07.4. Under huven: hur `codec` är byggd i ren Ridgun (`src/main/ridgun/lib/codec.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/codec.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 07.4.1. Intern implementation: RFC 4648 Hexadecimal Encoding & Decoding

Se hur `codec.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: cd hex val Int => Int
      cd hex val c   =
        | c >= 48 and c <= 57  = c - 48
        | c >= 65 and c <= 70  = (c - 65) + 10
        | c >= 97 and c <= 102 = (c - 97) + 10
        | otherwise            = 0 - 1

fn :: cd valid hex loop String Int Int => Bool
      cd valid hex loop s idx len =
        | idx >= len                           = True
        | (cd hex val (str char at s idx)) < 0 = False
        | otherwise                            = cd valid hex loop s (idx + 1) len

fn :: cd is valid hex len String Int => Bool
      cd is valid hex len s n =
        | (n % 2) != 0 = False
        | otherwise    = cd valid hex loop s 0 n

fn :: is valid hex String => Bool
      is valid hex s      =  cd is valid hex len s (str len s)

fn :: cd hex enc byte Int => String
      cd hex enc byte b   =
        ub  = ((b % 256) + 256) % 256
        hi  = ub / 16
        lo  = ub % 16
        tbl = cd hex lut 0
        (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1))

fn :: cd hex enc loop String Int Int => String
      cd hex enc loop s idx len =
        | idx >= len = ""
        | otherwise  = (cd hex enc byte (str char at s idx)) + (cd hex enc loop s (idx + 1) len)

fn :: hex encode String => String
      hex encode s      =  cd hex enc loop s 0 (str len s)

fn :: cd hex dec loop String Int Int => String
      cd hex dec loop s idx len =
        | idx >= len = ""
        | otherwise =
          hi = cd hex val (str char at s idx)
          lo = cd hex val (str char at s (idx + 1))
          (cd raw byte ((hi * 16) + lo)) + (cd hex dec loop s (idx + 2) len)

fn :: hex decode String => String
      hex decode s      =
        | not (is valid hex s) = ""
        | otherwise            = cd hex dec loop s 0 (str len s)
```

### 07.4.2. Intern implementation: RFC 4648 Standard Base64 & URL-Safe Base64url

Se hur `codec.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: cd b64 char String Int => String
      cd b64 char tbl    idx =
        i = idx % 64
        str slice tbl i (i + 1)

fn :: cd b64 pad suffix String Bool => String
      cd b64 pad suffix suffix True = suffix
      cd b64 pad suffix _ False = ""

fn :: cd b64 enc step String Int String Bool Int => String
      cd b64 enc step s idx tbl pad rem =
        | rem <= 0 = ""
        | rem == 1 =
          b0   = str char at s idx
          out2 = (cd b64 char tbl (b0 / 4)) + (cd b64 char tbl ((b0 % 4) * 16))
          out2 + (cd b64 pad suffix "==" pad)
        | rem == 2 =
          b0   = str char at s idx
          b1   = str char at s (idx + 1)
          n    = (b0 * 256) + b1
          out3 = (cd b64 char tbl (n / 1024)) + (cd b64 char tbl ((n / 16) % 64)) + (cd b64 char tbl ((n % 16) * 4))
          out3 + (cd b64 pad suffix "=" pad)
        | otherwise =
          b0   = str char at s idx
          b1   = str char at s (idx + 1)
          b2   = str char at s (idx + 2)
          n    = (b0 * 65536) + (b1 * 256) + b2
          out4 = (cd b64 char tbl (n / 262144)) + (cd b64 char tbl ((n / 4096) % 64)) + (cd b64 char tbl ((n / 64) % 64)) + (cd b64 char tbl (n % 64))
          out4 + (cd b64 enc rem s (idx + 3) tbl pad)

fn :: cd b64 enc rem String Int String Bool => String
      cd b64 enc rem s idx tbl pad = cd b64 enc step s idx tbl pad ((str len s) - idx)

fn :: base64 encode String => String
      base64 encode s      =  cd b64 enc rem s 0 (cd b64 lut 0) True

fn :: base64url encode String => String
      base64url encode s      =  cd b64 enc rem s 0 (cd b64url lut 0) False

fn :: cd b64 val Int => Int
      cd b64 val c   =
        | c >= 65 and c <= 90  = c - 65
        | c >= 97 and c <= 122 = (c - 97) + 26
        | c >= 48 and c <= 57  = (c - 48) + 52
        | c == 43 or c == 45   = 62
        | c == 47 or c == 95   = 63
        | otherwise            = 0 - 1
```

### 07.4.3. Intern implementation: RFC 3986 URL Percent-Encoding & Query Strings

Se hur `codec.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: cd is unreserved Int => Bool
      cd is unreserved c   =
        | c >= 65 and c <= 90                        = True
        | c >= 97 and c <= 122                       = True
        | c >= 48 and c <= 57                        = True
        | c == 45 or c == 95 or c == 46 or c == 126  = True
        | otherwise                                  = False

fn :: cd pct byte Int => String
      cd pct byte b   =
        ub  = ((b % 256) + 256) % 256
        hi  = ub / 16
        lo  = ub % 16
        tbl = cd hex up lut 0
        "%" + (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1))

fn :: cd url enc char String Int Int => String
      cd url enc char s idx c =
        | cd is unreserved c = str slice s idx (idx + 1)
        | otherwise          = cd pct byte c

fn :: cd url enc loop String Int Int => String
      cd url enc loop s idx len =
        | idx >= len = ""
        | otherwise  = (cd url enc char s idx (str char at s idx)) + (cd url enc loop s (idx + 1) len)

fn :: url encode String => String
      url encode s      =  cd url enc loop s 0 (str len s)

fn :: cd url dec pct String Int Int Int Int => String
      cd url dec pct s idx len hi lo =
        | hi >= 0 and lo >= 0 = (cd raw byte ((hi * 16) + lo)) + (cd url dec loop s (idx + 3) len)
        | otherwise           = "%" + (cd url dec loop s (idx + 1) len)

fn :: cd url dec at String Int Int Int => String
      cd url dec at s idx len c =
        | c == 43                     = " " + (cd url dec loop s (idx + 1) len)
        | c == 37 and (idx + 2) < len = cd url dec pct s idx len (cd hex val (str char at s (idx + 1))) (cd hex val (str char at s (idx + 2)))
        | otherwise                   = (str slice s idx (idx + 1)) + (cd url dec loop s (idx + 1) len)

fn :: cd url dec loop String Int Int => String
      cd url dec loop s idx len =
        | idx >= len = ""
        | otherwise  = cd url dec at s idx len (str char at s idx)

fn :: url decode String => String
      url decode s      =  cd url dec loop s 0 (str len s)

fn :: cd pair key (String String) => String
      cd pair key (k, _)          =  k
```

### 07.4.4. Intern implementation: RFC 8259 Lightweight JSON Formatting & Field Extraction

Se hur `codec.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: cd json esc code String Int Int => String
      cd json esc code s idx c =
        | c == 34   = "\\\""
        | c == 92   = "\\\\"
        | c == 10   = "\\n"
        | c == 13   = "\\r"
        | c == 9    = "\\t"
        | otherwise = str slice s idx (idx + 1)

fn :: cd json esc loop String Int Int => String
      cd json esc loop s idx len =
        | idx >= len = ""
        | otherwise  = (cd json esc code s idx (str char at s idx)) + (cd json esc loop s (idx + 1) len)

fn :: json escape String => String
      json escape s      =  cd json esc loop s 0 (str len s)

fn :: cd json unesc next String Int Int Int => String
      cd json unesc next s idx len nc =
        | nc == 34  = "\"" + (cd json unesc loop s (idx + 2) len)
        | nc == 92  = "\\" + (cd json unesc loop s (idx + 2) len)
        | nc == 110 = "\n" + (cd json unesc loop s (idx + 2) len)
        | nc == 114 = "\r" + (cd json unesc loop s (idx + 2) len)
        | nc == 116 = "\t" + (cd json unesc loop s (idx + 2) len)
        | otherwise = (str slice s (idx + 1) (idx + 2)) + (cd json unesc loop s (idx + 2) len)

fn :: cd json unesc loop String Int Int => String
      cd json unesc loop s idx len =
        | idx >= len                                    = ""
        | (str char at s idx) == 92 and (idx + 1) < len = cd json unesc next s idx len (str char at s (idx + 1))
        | otherwise                                     = (str slice s idx (idx + 1)) + (cd json unesc loop s (idx + 1) len)

fn :: json unescape String => String
      json unescape s      =  cd json unesc loop s 0 (str len s)

fn :: json quote String => String
      json quote s      =  "\"" + (json escape s) + "\""

fn :: json int Int => String
      json int n   =  int to str n

fn :: json bool Bool  => String
      json bool True  =  "true"
      json bool False =  "false"

fn :: json null => String
      json null =  "null"
```

---

## 07.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `codec`

- **Algoritmisk garanti och säkerhet**: Deterministiskt avvisande av felformade Hex- eller Base64-indata (returnerar `""` utan läsningar utanför gränserna) och exakt $decode(encode(x)) == x$-rundresa.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/codec.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test codec.rg`.

### De 5 Gyllene Reglerna när du programmerar med `codec`

1. **Deklarera `import codec` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `codec`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `codec`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `codec` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 08** går vi vidare och utforskar lib:en **`json`** på djupet (Lib:en `json` — Rekursiv RFC 8259 AST-tolk, Pretty-Printer och Sökvägsfrågor).
