# Kapitel 28: Lib:en `http` — RFC 3986 URI, RFC 9112 HTTP/1.1-kodek och Direkt TCP-klient

## 28.1. Varför finns lib:en `http`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `http`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `http`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: om man inte rensar bort `\r\n` i HTTP-headers kan en angripare injicera egna headers (*CRLF Response Splitting*), och att länka in `libcurl` bara för att göra ett `GET`- eller `POST`-anrop är överdrivet.

Lib:en **`http`** implementerar **RFC 3986 URI**-tolkning, **RFC 9112 HTTP/1.1**-formatering och tolkning med automatisk CRLF-sanering (`VUL-INJ-002`) och automatisk `Content-Length`, extrahering av `Bearer`-tokens samt en **direkt HTTP/1.1-klient över kärnans TCP-sockets** (`http get`, `http post`, `http request tcp`).

I ett traditionellt ekosystem innebär uppgifter inom domänen **`HTTP`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`http`** (`src/main/ridgun/lib/http.rg`) problemet genom fyra kompromisslösa principer:

1. **Totala funktioner och explicita kontrakt (`=>`)**: ingen funktion i `http` kastar dolda undantag eller förlitar sig på `null`. Varje gränsfall returnerar ett dokumenterat sentinelvärde eller en algebraisk summatyp (`Option`, `Result`).
2. **Noll C-kod och noll `libc`**: varje rad i `http` kompileras direkt till inbyggd ELF64-maskinkod verifierad av `ridgunc`.
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `http` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 28.2. Inbyggda artefakter, import och komplett API-katalog för `http`

I `ridgun-libs` är **`http`** en förstklassig **lib** placerad i `src/main/ridgun/lib/http.rg` (domän `HTTP`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/http.rglib` | Portabel distribution och direkt import med `import http` |
| **Kompilerat arkiv** | `target/http.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libhttp.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import http` överst och anropar funktionerna med mellanslag eller understreck.

### 28.2.1. Översikt över funktionella familjer i `http`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `uri parse / uri scheme / uri host / uri port / uri path / uri query` | Delar upp RFC 3986-URI:er med automatiska standardportar (`80` för `http`, `443` för `https`) |
| `http build request / http parse request` | Formaterar och tolkar HTTP/1.1-anrop med CRLF-sanering av headers |
| `http build response / http parse response` | Formaterar och tolkar HTTP/1.1-svar med standardiserade statusfraser |
| `http header get / http bearer token` | Skiftlägesokänslig header-uppslagning och extrahering av `Authorization: Bearer <token>` |
| `http get / http post / http request tcp` | Kör direkta HTTP/1.1-anrop över kärnans TCP-sockets med `timeout_ms` |

### 28.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/http.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/http.rg` (`0` typer, `0` operatorer och `76` funktioner):

| # | Funktion / Signatur (`fn ::`) | Returtyp |
|---|---|---|
| `1` | `fn :: ht index of loop String String Int Int Int` | `Int` |
| `2` | `fn :: ht index of String String` | `Int` |
| `3` | `fn :: ht lower char String Int Int` | `String` |
| `4` | `fn :: ht to lower loop String Int Int` | `String` |
| `5` | `fn :: ht to lower String` | `String` |
| `6` | `fn :: ht is ws Int` | `Bool` |
| `7` | `fn :: ht trim left String Int Int` | `Int` |
| `8` | `fn :: ht trim right String Int Int` | `Int` |
| `9` | `fn :: ht trim String` | `String` |
| `10` | `fn :: ht strip crlf loop String Int Int` | `String` |
| `11` | `fn :: ht strip crlf String` | `String` |
| `12` | `fn :: ht is digits loop String Int Int` | `Bool` |
| `13` | `fn :: ht parse int or String Int` | `Int` |
| `14` | `fn :: ht default port String` | `Int` |
| `15` | `fn :: ht split host port String Int Int` | `String Int` |
| `16` | `fn :: ht split path query String Int` | `String String` |
| `17` | `fn :: ht split auth rest String Int` | `String String` |
| `18` | `fn :: ht finish uri String (String Int) (String String)` | `String String Int String String` |
| `19` | `fn :: ht parse uri after scheme String String` | `String String Int String String` |
| `20` | `fn :: ht parse uri at String Int` | `String String Int String String` |
| `21` | `fn :: uri parse String` | `String String Int String String` |
| `22` | `fn :: ht u1 (String String Int String String)` | `String` |
| `23` | `fn :: ht u2 (String String Int String String)` | `String` |
| `24` | `fn :: ht u3 (String String Int String String)` | `Int` |
| `25` | `fn :: ht u4 (String String Int String String)` | `String` |
| `26` | `fn :: ht u5 (String String Int String String)` | `String` |
| `27` | `fn :: uri scheme String` | `String` |
| `28` | `fn :: uri host String` | `String` |
| `29` | `fn :: uri port String` | `Int` |
| `30` | `fn :: uri path String` | `String` |
| `31` | `fn :: uri query String` | `String` |
| `32` | `fn :: http status text Int` | `String` |
| `33` | `fn :: ht pair key (String String)` | `String` |
| `34` | `fn :: ht pair val (String String)` | `String` |
| `35` | `fn :: ht hdr get lower [String String] String` | `String` |
| `36` | `fn :: http header get [String String] String` | `String` |
| `37` | `fn :: ht extract bearer String` | `String` |
| `38` | `fn :: http bearer token [String String]` | `String` |
| `39` | `fn :: ht fmt headers [String String]` | `String` |
| `40` | `fn :: ht auto cl [String String] String` | `String` |
| `41` | `fn :: http build request String String [String String] String` | `String` |
| `42` | `fn :: http build response Int [String String] String` | `String` |
| `43` | `fn :: ht split lines loop String Int Int Int` | `[String]` |
| `44` | `fn :: ht parse hdr line String Int` | `[String String]` |
| `45` | `fn :: ht parse hdr lines [String]` | `[String String]` |
| `46` | `fn :: ht split head body String Int Int` | `String String` |
| `47` | `fn :: ht parse req rem String String Int` | `String String` |
| `48` | `fn :: ht parse req line String Int` | `String String` |
| `49` | `fn :: ht parse req parts [String] String` | `String String String` |
| `50` | `fn :: ht parse hdr parts [String]` | `[String String]` |
| `51` | `fn :: http parse headers String` | `[String String]` |
| `52` | `fn :: http parse request String` | `String String String` |
| `53` | `fn :: ht parse status rem String Int` | `Int String` |
| `54` | `fn :: ht parse status line String Int` | `Int String` |
| `55` | `fn :: ht st code (Int String)` | `Int` |
| `56` | `fn :: ht st text (Int String)` | `String` |
| `57` | `fn :: ht parse resp parts [String] String` | `Int String String` |
| `58` | `fn :: http parse response String` | `Int String String` |
| `59` | `fn :: ht ensure hdr [String String] String String` | `[String String]` |
| `60` | `fn :: ht read tcp step Int Int String (Int String)` | `String` |
| `61` | `fn :: ht read tcp loop Int Int String` | `String` |
| `62` | `fn :: ht resp code (Int String String)` | `Int` |
| `63` | `fn :: ht resp body (Int String String)` | `String` |
| `64` | `fn :: ht finish tcp resp String` | `Int Int String` |
| `65` | `fn :: ht send read step Int Int (Int Int)` | `Int Int String` |
| `66` | `fn :: ht connect send tcp Int Int String Int` | `Int Int String` |
| `67` | `fn :: http request tcp String Int String String [String String] String Int` | `Int Int String` |
| `68` | `fn :: ht pick path String` | `String` |
| `69` | `fn :: ht build target path String String` | `String` |
| `70` | `fn :: ht exec url req (String String Int String String) String [String String] String Int` | `Int Int String` |
| `71` | `fn :: http get String Int` | `Int Int String` |
| `72` | `fn :: http post String String String Int` | `Int Int String` |
| `73` | `fn :: http resp rc (Int Int String)` | `Int` |
| `74` | `fn :: http resp status (Int Int String)` | `Int` |
| `75` | `fn :: http resp headers (Int Int String)` | `[String String]` |
| `76` | `fn :: http resp body (Int Int String)` | `String` |

---

## 28.3. Djupdykning i `http`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `http` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test http.rg`.

### 28.3.1. Exempel 1: Huvudflöde i tabellform med `http`

Lägg märke till hur `=`-tecknen och transformationsstegen med `http` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import http

fn :: inspeccionar endpoint (url : String) => (String, Int, String, String)
      inspeccionar endpoint url =
        host = uri host url
        port = uri port url
        path = uri path url
        wire = http build request "GET" path [("Host", host)] ""
        (host, port, path, wire)
```

### 28.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `http` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import http

fn :: extraer credenciales (raw_req : String) => (String, String)
      extraer credenciales raw_req =
        (metodo, ruta, _, hdrs_raw, _) = http parse request raw_req
        hdrs = http parse headers hdrs_raw
        tok  = http bearer token hdrs
        (metodo + " " + ruta, tok)
```

### 28.3.3. Exempel 3: RFC 3986 URI-tolkning (`uri scheme`, `uri host`, `uri port`, `uri path`, `uri query`)

I detta praktiska exempel undersöker vi grundligt hur `http` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test uri parsing => ()
      test uri parsing =
        u1 = "https://api.example.com:8443/v1/users?active=1&role=admin"
        _  = assert str eq (uri scheme u1) "https" "uri_scheme https"
        _  = assert str eq (uri host u1) "api.example.com" "uri_host"
        _  = assert int equals (uri port u1) 8443 "uri_port 8443"
        _  = assert str eq (uri path u1) "/v1/users" "uri_path"
        _  = assert str eq (uri query u1) "active=1&role=admin" "uri_query"
        u2 = "http://localhost/health"
        _  = assert str eq (uri scheme u2) "http" "uri_scheme http"
        _  = assert str eq (uri host u2) "localhost" "uri_host localhost"
        _  = assert int equals (uri port u2) 80 "default http port 80"
        _  = assert str eq (uri path u2) "/health" "uri_path /health"
        _  = assert str eq (uri query u2) "" "uri_query empty"
        ()
```

### 28.3.4. Exempel 4: Formatering, tolkning och skiftlägesokänslig rubriksökning för HTTP/1.1-anrop och svar (`http format request/response`, `http parse request/response`, `http get header`)

I detta praktiska exempel undersöker vi grundligt hur `http` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test http11 request and response => ()
      test http11 request and response =
        hdrs    = [("Host", "api.example.com"), ("Authorization", "Bearer tok_xyz_987"), ("X-Injected", "safe\r\nEvil: 1")]
        raw_req = http build request "POST" "/v1/login" hdrs "{\"user\":\"alice\"}"
        parsed  = http parse request raw_req
        _       = assert str eq (req method parsed) "POST" "req method POST"
        _       = assert str eq (req path parsed) "/v1/login" "req path /v1/login"
        _       = assert str eq (req body parsed) "{\"user\":\"alice\"}" "req body"
        phdrs   = http parse headers raw_req
        _       = assert str eq (http header get phdrs "host") "api.example.com" "case-insensitive host header"
        _       = assert str eq (http header get phdrs "content-length") "16" "auto Content-Length 16"
        _       = assert str eq (http bearer token phdrs) "tok_xyz_987" "http_bearer_token"
        _       = assert str eq (http header get phdrs "Evil") "" "CRLF injection prevented"

        _        = assert str eq (http status text 200) "OK" "status 200 OK"
        _        = assert str eq (http status text 404) "Not Found" "status 404 Not Found"
        raw_resp = http build response 201 [("Content-Type", "application/json")] "{\"id\":42}"
        presp    = http parse response raw_resp
        rhdrs    = http parse headers raw_resp
        _        = assert int equals (resp code presp) 201 "resp code 201"
        _        = assert str eq (resp reason presp) "Created" "resp reason Created"
        _        = assert str eq (http header get rhdrs "content-type") "application/json" "resp Content-Type"
        _        = assert str eq (resp body presp) "{\"id\":42}" "resp body"
        ()
```

### 28.3.5. Exempel 5: Riktig HTTP/1.1-klient och server över kärnans TCP-sockets (`http get`, `http post`, `http request tcp`)

I detta praktiska exempel undersöker vi grundligt hur `http` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test http11 live tcp client and server => ()
      test http11 live tcp client and server =
        -- Spin up a real kernel TCP listener on port 0, connect a client, send HTTP request, respond, and read back
        l_res  = sys tcp listen "127.0.0.1" 0 8
        _      = assert int equals (sock rc l_res) 0 "http server listen ok"
        lfd    = sock fd l_res
        port   = sys local port lfd
        _      = assert true (port > 0) "http server ephemeral port > 0"
        c_res  = sys tcp connect "localhost" port 500
        _      = assert int equals (sock rc c_res) 0 "http client connect ok"
        cfd    = sock fd c_res
        a_res  = sys accept lfd 500
        _      = assert int equals (sock accept rc a_res) 0 "http server accept ok"
        sfd    = sock accept fd a_res
        req_w  = http build request "GET" "/v1/ping?echo=1" [("Host", "localhost"), ("Connection", "close")] ""
        _      = assert int equals (sock rc (sys send cfd req_w 500)) 0 "http client send request"
        srv_rx = sock recv data (sys recv sfd 4096 500)
        s_req  = http parse request srv_rx
        _      = assert str eq (req method s_req) "GET" "server parsed GET"
        _      = assert str eq (req path s_req) "/v1/ping?echo=1" "server parsed path"
        resp_w = http build response 200 [("Content-Type", "application/json"), ("Connection", "close")] "{\"pong\":true}"
        _      = assert int equals (sock rc (sys send sfd resp_w 500)) 0 "http server send response"
        _      = assert int equals (sys close sfd) 0 "http server close sfd"
        cli_rx = sock recv data (sys recv cfd 4096 500)
        c_resp = http parse response cli_rx
        c_hdrs = http parse headers cli_rx
        _      = assert int equals (resp code c_resp) 200 "client parsed 200"
        _      = assert str eq (http header get c_hdrs "content-type") "application/json" "client parsed header"
        _      = assert str eq (resp body c_resp) "{\"pong\":true}" "client parsed body"
        _      = assert int equals (sys close cfd) 0 "http client close cfd"
        _      = assert int equals (sys close lfd) 0 "http server close lfd"
        -- Verify http_get / http_post error handling on invalid scheme or refused port
        bad_g  = http get "ftp://localhost/file" 100
        _      = assert int equals (http resp rc bad_g) (0 - 7) "http_get non-http scheme -> -7"
        ref_p  = http post "http://127.0.0.1:39998/api" "application/json" "{}" 100
        _      = assert int equals (http resp rc ref_p) (0 - 3) "http_post refused port -> -3"
        -- Verify http_get against a real external background TCP responder over kernel loopback
        l_bg   = sys tcp listen "127.0.0.1" 0 8
        lfd_bg = sock fd l_bg
        p_bg   = sys local port lfd_bg
        _      = sys close lfd_bg
        _      = shell exec "python3 -c \"import socket; s=socket.socket(); s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1); s.bind(('127.0.0.1',{p_bg})); s.listen(1); c,_=s.accept(); c.recv(1024); c.sendall(b'HTTP/1.1 200 OK\\r\\nContent-Type: text/plain\\r\\nContent-Length: 7\\r\\nConnection: close\\r\\n\\r\\nlive-ok'); c.close(); s.close()\" >/dev/null 2>&1 &"
        _      = sys sleep ms 80
        g_live = http get "http://localhost:{p_bg}/status?check=1" 500
        _      = assert int equals (http resp rc g_live) 0 "http_get live external TCP server rc == 0"
        _      = assert int equals (http resp status g_live) 200 "http_get live status == 200"
        _      = assert str eq (http header get (http resp headers g_live) "content-type") "text/plain" "http_get live header"
        _      = assert str eq (http resp body g_live) "live-ok" "http_get live body == live-ok"
        ()
```

---

## 28.4. Under huven: hur `http` är byggd i ren Ridgun (`src/main/ridgun/lib/http.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/http.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 28.4.1. Intern implementation: Internal String & Case Helpers

Se hur `http.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: ht index of loop String String Int Int Int => Int
      ht index of loop s sub idx slen sublen =
        | (idx + sublen) > slen                   = 0 - 1
        | (str slice s idx (idx + sublen)) == sub = idx
        | otherwise                               = ht index of loop s sub (idx + 1) slen sublen

fn :: ht index of String String => Int
      ht index of s      sub    =
        | (str len sub) == 0 = 0
        | otherwise          = ht index of loop s sub 0 (str len s) (str len sub)

fn :: ht lower char String Int Int => String
      ht lower char s idx c =
        | c >= 65 and c <= 90 = char from code (c + 32)
        | otherwise           = str slice s idx (idx + 1)

fn :: ht to lower loop String Int Int => String
      ht to lower loop s idx len =
        | idx >= len = ""
        | otherwise  = (ht lower char s idx (str char at s idx)) + (ht to lower loop s (idx + 1) len)

fn :: ht to lower String => String
      ht to lower s      =  ht to lower loop s 0 (str len s)

fn :: ht is ws Int => Bool
      ht is ws c   =  c == 32 or c == 9 or c == 10 or c == 13

fn :: ht trim left String Int Int => Int
      ht trim left s idx len =
        | idx >= len                   = len
        | ht is ws (str char at s idx) = ht trim left s (idx + 1) len
        | otherwise                    = idx

fn :: ht trim right String Int Int => Int
      ht trim right s start end_pos =
        | end_pos <= start                       = start
        | ht is ws (str char at s (end_pos - 1)) = ht trim right s start (end_pos - 1)
        | otherwise                              = end_pos

fn :: ht trim String => String
      ht trim s      =
        st = ht trim left s 0 (str len s)
        en = ht trim right s st (str len s)
        str slice s st en
```

### 28.4.2. Intern implementation: RFC 3986 URI Parsing

Se hur `http.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: ht default port String => Int
      ht default port scheme =
        | scheme == "https" or scheme == "wss" = 443
        | scheme == "http" or scheme == "ws"   = 80
        | otherwise                            = 0

fn :: ht split host port String Int Int => String Int
      ht split host port auth colon_idx def_port =
        | colon_idx < 0 = (auth, def_port)
        | otherwise =
          h = str slice auth 0 colon_idx
          p = ht parse int or (str slice auth (colon_idx + 1) (str len auth)) def_port
          (h, p)

fn :: ht split path query String Int => String String
      ht split path query pq q_idx =
        | q_idx < 0 = (pq, "")
        | otherwise = (str slice pq 0 q_idx, str slice pq (q_idx + 1) (str len pq))

fn :: ht split auth rest String Int => String String
      ht split auth rest rem slash_idx =
        | slash_idx < 0 = (rem, "/")
        | otherwise     = (str slice rem 0 slash_idx, str slice rem slash_idx (str len rem))

fn :: ht finish uri String (String Int) (String String) => String String Int String String
      ht finish uri scheme (host, port) (path, query) =
        (scheme, host, port, path, query)

fn :: ht parse uri after scheme String String => String String Int String String
      ht parse uri after scheme scheme rem =
        ap       = ht split auth rest rem (ht index of rem "/")
        auth     = ht pair key ap
        pq_raw   = ht pair val ap
        def_port = ht default port scheme
        hp       = ht split host port auth (ht index of auth ":") def_port
        pq       = ht split path query pq_raw (ht index of pq_raw "?")
        ht finish uri scheme hp pq

fn :: ht parse uri at String Int => String String Int String String
      ht parse uri at raw sep_idx =
        | sep_idx < 0 =
          pq = ht split path query raw (ht index of raw "?")
          ("", "", 0, ht pair key pq, ht pair val pq)
        | otherwise =
          scheme = ht to lower (str slice raw 0 sep_idx)
          rem    = str slice raw (sep_idx + 3) (str len raw)
          ht parse uri after scheme scheme rem

fn :: uri parse String => String String Int String String
      uri parse raw    =  ht parse uri at raw (ht index of raw "://")
```

### 28.4.3. Intern implementation: HTTP/1.1 Request & Response Formatting & Parsing

Se hur `http.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: ht fmt headers [String String] => String
      ht fmt headers []              =  ""
      ht fmt headers (pair:rest)     =
        k = ht strip crlf (ht pair key pair)
        v = ht strip crlf (ht pair val pair)
        k + ": " + v + "\r\n" + (ht fmt headers rest)

fn :: ht auto cl [String String] String => String
      ht auto cl headers         body   =
        | (str len body) == 0                                  = ""
        | (str len (http header get headers "Content-Length")) > 0 = ""
        | otherwise                                            = "Content-Length: " + (int to str (str len body)) + "\r\n"

fn :: http build request String String [String String] String => String
      http build request method path headers body =
        m  = ht strip crlf method
        p  = ht strip crlf path
        cl = ht auto cl headers body
        m + " " + p + " HTTP/1.1\r\n" + (ht fmt headers headers) + cl + "\r\n" + body

fn :: http build response Int [String String] String => String
      http build response code headers body =
        reason = http status text code
        cl     = ht auto cl headers body
        "HTTP/1.1 " + (int to str code) + " " + reason + "\r\n" + (ht fmt headers headers) + cl + "\r\n" + body

fn :: ht split lines loop String Int Int Int => [String]
      ht split lines loop s start idx len =
        | idx >= len                = [(ht strip crlf (str slice s start len))]
        | (str char at s idx) == 10 = [(ht strip crlf (str slice s start idx))] :: (ht split lines loop s (idx + 1) (idx + 1) len)
        | otherwise                 = ht split lines loop s start (idx + 1) len

fn :: ht parse hdr line String Int => [String String]
      ht parse hdr line line cidx =
        | cidx <= 0 = []
        | otherwise =
          k = ht trim (str slice line 0 cidx)
          v = ht trim (str slice line (cidx + 1) (str len line))
          [(k, v)]

fn :: ht parse hdr lines [String] => [String String]
      ht parse hdr lines []       =  []
      ht parse hdr lines (l:rest) =
        | (str len l) == 0 = ht parse hdr lines rest
        | otherwise        = (ht parse hdr line l (ht index of l ":")) :: (ht parse hdr lines rest)
```

### 28.4.4. Intern implementation: Live Kernel TCP HTTP/1.1 Client (`http_request_tcp`, `http_get`, `http_post`)

Se hur `http.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: ht ensure hdr [String String] String String => [String String]
      ht ensure hdr headers key val =
        | (str len (http header get headers key)) > 0 = headers
        | otherwise                                   = headers :: [(key, val)]

fn :: ht read tcp step Int Int String (Int String) => String
      ht read tcp step fd timeout_ms acc (rc, chunk) =
        | rc != 0   = acc
        | otherwise = ht read tcp loop fd timeout_ms (acc + chunk)

fn :: ht read tcp loop Int Int String => String
      ht read tcp loop fd timeout_ms acc =
        ht read tcp step fd timeout_ms acc (sys recv fd 16384 timeout_ms)

fn :: ht resp code (Int String String) => Int
      ht resp code (c, _, _)           =  c

fn :: ht resp body (Int String String) => String
      ht resp body (_, _, b)           =  b

fn :: ht finish tcp resp String => Int Int String
      ht finish tcp resp raw    =
        | (str len raw) == 0 = (0 - 1, 0, "")
        | otherwise =
          pr   = http parse response raw
          code = ht resp code pr
          (0, code, raw)

fn :: ht send read step Int Int (Int Int) => Int Int String
      ht send read step cfd timeout_ms (s_rc, _) =
        | s_rc != 0 =
          _ = sys close cfd
          (s_rc, 0, "")
        | otherwise =
          raw = ht read tcp loop cfd timeout_ms ""
          _   = sys close cfd
          ht finish tcp resp raw

fn :: ht connect send tcp Int Int String Int => Int Int String
      ht connect send tcp c_rc cfd wire timeout_ms =
        | c_rc != 0 = (c_rc, 0, "")
        | otherwise = ht send read step cfd timeout_ms (sys send cfd wire timeout_ms)

fn :: http request tcp String Int String String [String String] String Int => Int Int String
      http request tcp host port method path headers body timeout_ms =
        c_res = sys tcp connect host port timeout_ms
        hdrs1 = ht ensure hdr headers "Host" host
        hdrs2 = ht ensure hdr hdrs1 "Connection" "close"
        wire  = http build request method path hdrs2 body
        ht connect send tcp (sock rc c_res) (sock fd c_res) wire timeout_ms
```

---

## 28.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `http`

- **Algoritmisk garanti och säkerhet**: Automatisk borttagning av `\r` och `\n` i alla headers (`http sanitize header`) för att förhindra HTTP response-splitting.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/http.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test http.rg`.

### De 5 Gyllene Reglerna när du programmerar med `http`

1. **Deklarera `import http` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `http`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `http`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `http` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 29** går vi vidare och utforskar lib:en **`ws`** på djupet (Lib:en `ws` — RFC 6455 WebSocket-handskakning, 16/64-bitars Ramkodek och XOR-maskering).
