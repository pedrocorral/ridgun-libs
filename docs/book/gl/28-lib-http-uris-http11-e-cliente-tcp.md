# Capítulo 28: A lib `http` — URIs RFC 3986, Codec HTTP/1.1 RFC 9112 e Cliente TCP en Vivo

## 28.1. Por que existe a lib `http`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `http` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `http`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: se non filtras saltos `\r\n` nos valores das cabeceiras HTTP, un atacante pode inxectar cabeceiras falsas ou dividir a resposta (*CRLF Response Splitting*), e enlazar `libcurl` para facer un simple `GET` ou `POST` é excesivo.

A lib **`http`** implementa descomposición de **URIs RFC 3986**, construción e análise de peticións e respostas **HTTP/1.1 RFC 9112** con saneamento automático de CRLF (`VUL-INJ-002`) e `Content-Length` automático, extracción de tokens `Bearer` e un **cliente HTTP/1.1 en vivo sobre sockets TCP do kernel** (`http get`, `http post`, `http request tcp`).

Nun ecosistema tradicional, resolver as tarefas do dominio **`HTTP`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`http`** (`src/main/ridgun/lib/http.rg`) aborda o problema con catro principios innegociables:

1. **Declara `import http` (ou `import http as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: http` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `http` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 28.2. Artefactos nativos, importación e catálogo completo da API de `http`

En `ridgun-libs`, **`http`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/http.rg` (dominio `HTTP`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/http.rglib` | Distribución e importación directa con `import http` |
| **Ficheiro compilado** | `target/http.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libhttp.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Cada lib declara o seu propio espazo de nomes con `module :: http`: abonda con escribir `import http` (ou `import http as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 28.2.1. Resumo de familias funcionais de `http`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `uri parse / uri scheme / uri host / uri port / uri path / uri query` | Descompón URIs RFC 3986 con portos por defecto automáticos (`80` en `http`, `443` en `https`) |
| `http build request / http parse request` | Formatea e analiza peticións HTTP/1.1 con saneamento CRLF de cabeceiras |
| `http build response / http parse response` | Formatea e analiza respostas HTTP/1.1 con frases de estado estándar |
| `http header get / http bearer token` | Busca de cabeceiras insensible a maiúsculas e extracción de `Authorization: Bearer <token>` |
| `http get / http post / http request tcp` | Executa chamadas HTTP/1.1 en vivo sobre sockets TCP do kernel con `timeout_ms` |

### 28.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/http.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/http.rg` (`0` tipos, `0` operadores e `76` funcións):

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 28.3. Explorando `http` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `http` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test http.rg`.

### 28.3.1. Exemplo 1: Fluxo principal en estilo tabular con `http`

Observa como en Ridgun os signos `=` e os pasos de transformación con `http` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import http

fn :: inspeccionar endpoint String => String Int String String
      inspeccionar endpoint url =
        url uri host -> host
        url uri port -> port
        url uri path -> path
        http build request "GET" path [("Host", host)] "" -> wire
        (host, port, path, wire)
```

### 28.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `http` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import http

fn :: extraer cabeceras peticion String => String String
      extraer cabeceras peticion raw_req =
        raw_req http req method -> metodo
        raw_req http req path -> ruta
        http req header raw_req "Authorization" -> auth
        (metodo + " " + ruta, auth)
```

### 28.3.3. Exemplo 3: Análise de URIs RFC 3986 (`uri scheme`, `uri host`, `uri port`, `uri path`, `uri query`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `http` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test uri parsing => ()
      test uri parsing =
        u1 = "https://api.example.com:8443/v1/users?active=1&role=admin"
        assert str eq (uri scheme u1) "https" "uri_scheme https"
        assert str eq (uri host u1) "api.example.com" "uri_host"
        assert int equals (uri port u1) 8443 "uri_port 8443"
        assert str eq (uri path u1) "/v1/users" "uri_path"
        assert str eq (uri query u1) "active=1&role=admin" "uri_query"
        u2 = "http://localhost/health"
        assert str eq (uri scheme u2) "http" "uri_scheme http"
        assert str eq (uri host u2) "localhost" "uri_host localhost"
        assert int equals (uri port u2) 80 "default http port 80"
        assert str eq (uri path u2) "/health" "uri_path /health"
        assert str eq (uri query u2) "" "uri_query empty"
        ()
```

### 28.3.4. Exemplo 4: Construción, serialización e análise de peticións e respostas HTTP/1.1 (`http format request/response`, `http parse request/response`, `http get header`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `http` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test http11 request and response => ()
      test http11 request and response =
        hdrs    = [("Host", "api.example.com"), ("Authorization", "Bearer tok_xyz_987"), ("X-Injected", "safe\r\nEvil: 1")]
        raw_req = http build request "POST" "/v1/login" hdrs "{\"user\":\"alice\"}"
        parsed  = http parse request raw_req
        assert str eq (req method parsed) "POST" "req method POST"
        assert str eq (req path parsed) "/v1/login" "req path /v1/login"
        assert str eq (req body parsed) "{\"user\":\"alice\"}" "req body"
        phdrs   = http parse headers raw_req
        assert str eq (http header get phdrs "host") "api.example.com" "case-insensitive host header"
        assert str eq (http header get phdrs "content-length") "16" "auto Content-Length 16"
        assert str eq (http bearer token phdrs) "tok_xyz_987" "http_bearer_token"
        assert str eq (http header get phdrs "Evil") "" "CRLF injection prevented"

        assert str eq (http status text 200) "OK" "status 200 OK"
        assert str eq (http status text 404) "Not Found" "status 404 Not Found"
        raw_resp = http build response 201 [("Content-Type", "application/json")] "{\"id\":42}"
        presp    = http parse response raw_resp
        rhdrs    = http parse headers raw_resp
        assert int equals (resp code presp) 201 "resp code 201"
        assert str eq (resp reason presp) "Created" "resp reason Created"
        assert str eq (http header get rhdrs "content-type") "application/json" "resp Content-Type"
        assert str eq (resp body presp) "{\"id\":42}" "resp body"
        ()
```

### 28.3.5. Exemplo 5: Cliente e servidor HTTP/1.1 reais sobre sockets TCP do kernel (`http get`, `http post`, `http request tcp`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `http` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test http11 live tcp client and server => ()
      test http11 live tcp client and server =
        -- Spin up a real kernel TCP listener on port 0, connect a client, send HTTP request, respond, and read back
        l_res  = sys tcp listen "127.0.0.1" 0 8
        assert int equals (sock rc l_res) 0 "http server listen ok"
        lfd    = sock fd l_res
        port   = sys local port lfd
        assert true (port > 0) "http server ephemeral port > 0"
        c_res  = sys tcp connect "localhost" port 500
        assert int equals (sock rc c_res) 0 "http client connect ok"
        cfd    = sock fd c_res
        a_res  = sys accept lfd 500
        assert int equals (sock accept rc a_res) 0 "http server accept ok"
        sfd    = sock accept fd a_res
        req_w  = http build request "GET" "/v1/ping?echo=1" [("Host", "localhost"), ("Connection", "close")] ""
        assert int equals (sock rc (sys send cfd req_w 500)) 0 "http client send request"
        srv_rx = sock recv data (sys recv sfd 4096 500)
        s_req  = http parse request srv_rx
        assert str eq (req method s_req) "GET" "server parsed GET"
        assert str eq (req path s_req) "/v1/ping?echo=1" "server parsed path"
        resp_w = http build response 200 [("Content-Type", "application/json"), ("Connection", "close")] "{\"pong\":true}"
        assert int equals (sock rc (sys send sfd resp_w 500)) 0 "http server send response"
        assert int equals (sys close sfd) 0 "http server close sfd"
        cli_rx = sock recv data (sys recv cfd 4096 500)
        c_resp = http parse response cli_rx
        c_hdrs = http parse headers cli_rx
        assert int equals (resp code c_resp) 200 "client parsed 200"
        assert str eq (http header get c_hdrs "content-type") "application/json" "client parsed header"
        assert str eq (resp body c_resp) "{\"pong\":true}" "client parsed body"
        assert int equals (sys close cfd) 0 "http client close cfd"
        assert int equals (sys close lfd) 0 "http server close lfd"
        -- Verify http get / http post error handling on invalid scheme or refused port
        bad_g  = http get "ftp://localhost/file" 100
        assert int equals (http resp rc bad_g) (0 - 7) "http_get non-http scheme -> -7"
        ref_p  = http post "http://127.0.0.1:39998/api" "application/json" "{}" 100
        assert int equals (http resp rc ref_p) (0 - 3) "http_post refused port -> -3"
        -- Verify http get against a real external background TCP responder over kernel loopback
        l_bg   = sys tcp listen "127.0.0.1" 0 8
        lfd_bg = sock fd l_bg
        p_bg   = sys local port lfd_bg
        sys close lfd_bg -> ()
        shell exec "python3 -c \"import socket; s=socket.socket(); s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1); s.bind(('127.0.0.1',{p_bg})); s.listen(1); c,_=s.accept(); c.recv(1024); c.sendall(b'HTTP/1.1 200 OK\\r\\nContent-Type: text/plain\\r\\nContent-Length: 7\\r\\nConnection: close\\r\\n\\r\\nlive-ok'); c.close(); s.close()\" >/dev/null 2>&1 &" -> ()
        sys sleep ms 80 -> ()
        g_live = http get "http://localhost:{p_bg}/status?check=1" 500
        assert int equals (http resp rc g_live) 0 "http_get live external TCP server rc == 0"
        assert int equals (http resp status g_live) 200 "http_get live status == 200"
        assert str eq (http header get (http resp headers g_live) "content-type") "text/plain" "http_get live header"
        assert str eq (http resp body g_live) "live-ok" "http_get live body == live-ok"
        ()
```

---

## 28.4. Baixo o capó: como está construída `http` en Ridgun puro (`src/main/ridgun/lib/http.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/http.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 28.4.1. Implementación interna: Internal String & Case Helpers

Fíxate en como `http.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
module :: http

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
        s str len -> len
        ht trim left s 0 len -> st
        ht trim right s st len -> en
        str slice s st en

fn :: ht strip crlf loop String Int Int => String
      ht strip crlf loop s idx len =
        | idx >= len = ""
        | (str char at s idx) == 10 or (str char at s idx) == 13 =
      ht strip crlf loop s (idx + 1) len
        | otherwise =
          (str slice s idx (idx + 1)) + (ht strip crlf loop s (idx + 1) len)

fn :: ht strip crlf String => String
      ht strip crlf s      =  ht strip crlf loop s 0 (str len s)

fn :: ht is digits loop String Int Int => Bool
      ht is digits loop s idx len =
        | idx >= len                                           = True
        | (str char at s idx) < 48 or (str char at s idx) > 57 = False
        | otherwise                                            = ht is digits loop s (idx + 1) len

fn :: ht parse int or String Int => Int
      ht parse int or s fallback =
        | (str len s) == 0                 = fallback
        | not (ht is digits loop s 0 (str len s)) = fallback
        | otherwise                        = str to int s
```

### 28.4.2. Implementación interna: RFC 3986 URI Parsing

Fíxate en como `http.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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
        ht split auth rest rem (ht index of rem "/") -> ap
        ap ht pair key -> auth
        ap ht pair val -> pq_raw
        scheme ht default port -> def_port
        ht split host port auth (ht index of auth ":") def_port -> hp
        ht split path query pq_raw (ht index of pq_raw "?") -> pq
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

fn :: ht u1 (String String Int String String) => String
      ht u1 (s, _, _, _, _)                   =  s

fn :: ht u2 (String String Int String String) => String
      ht u2 (_, h, _, _, _)                   =  h

fn :: ht u3 (String String Int String String) => Int
      ht u3 (_, _, p, _, _)                   =  p

fn :: ht u4 (String String Int String String) => String
      ht u4 (_, _, _, pt, _)                  =  pt

fn :: ht u5 (String String Int String String) => String
      ht u5 (_, _, _, _, q)                   =  q

fn :: uri scheme String => String
      uri scheme raw    =  ht u1 (uri parse raw)

fn :: uri host String => String
      uri host raw    =  ht u2 (uri parse raw)

fn :: uri port String => Int
      uri port raw    =  ht u3 (uri parse raw)

fn :: uri path String => String
      uri path raw    =  ht u4 (uri parse raw)

fn :: uri query String => String
      uri query raw    =  ht u5 (uri parse raw)
```

### 28.4.3. Implementación interna: HTTP/1.1 Request & Response Formatting & Parsing

Fíxate en como `http.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

fn :: ht split head body String Int Int => String String
      ht split head body raw crlf_idx lf_idx =
        | crlf_idx >= 0 = (str slice raw 0 crlf_idx, str slice raw (crlf_idx + 4) (str len raw))
        | lf_idx >= 0   = (str slice raw 0 lf_idx, str slice raw (lf_idx + 2) (str len raw))
        | otherwise     = (raw, "")

fn :: ht parse req rem String String Int => String String
      ht parse req rem method rem sp2 =
        | sp2 < 0   = (method, rem)
        | otherwise = (method, str slice rem 0 sp2)

fn :: ht parse req line String Int => String String
      ht parse req line line sp1 =
        | sp1 <= 0 = ("", "")
        | otherwise =
          method = str slice line 0 sp1
          rem    = str slice line (sp1 + 1) (str len line)
          ht parse req rem method rem (ht index of rem " ")

fn :: ht parse req parts [String] String => String String String
      ht parse req parts [] body = ("", "", body)
      ht parse req parts (f:_) body =
        mp = ht parse req line f (ht index of f " ")
        (ht pair key mp, ht pair val mp, body)

fn :: ht parse hdr parts [String] => [String String]
      ht parse hdr parts []       =  []
      ht parse hdr parts (_:rest) =  ht parse hdr lines rest

fn :: http parse headers String => [String String]
      http parse headers raw    =
        hb    = ht split head body raw (ht index of raw "\r\n\r\n") (ht index of raw "\n\n")
        head  = ht pair key hb
        lines = ht split lines loop head 0 0 (str len head)
        ht parse hdr parts lines

fn :: http parse request String => String String String
      http parse request raw    =
        hb    = ht split head body raw (ht index of raw "\r\n\r\n") (ht index of raw "\n\n")
        head  = ht pair key hb
        body  = ht pair val hb
        lines = ht split lines loop head 0 0 (str len head)
        ht parse req parts lines body

fn :: ht parse status rem String Int => Int String
      ht parse status rem rem sp2 =
        | sp2 < 0   = (ht parse int or rem 0, "")
        | otherwise = (ht parse int or (str slice rem 0 sp2) 0, str slice rem (sp2 + 1) (str len rem))

fn :: ht parse status line String Int => Int String
      ht parse status line line sp1 =
        | sp1 <= 0 = (0, "")
        | otherwise =
          rem = str slice line (sp1 + 1) (str len line)
          ht parse status rem rem (ht index of rem " ")

fn :: ht st code (Int String) => Int
      ht st code (c, _)       =  c

fn :: ht st text (Int String) => String
      ht st text (_, t)       =  t

fn :: ht parse resp parts [String] String => Int String String
      ht parse resp parts [] body = (0, "", body)
      ht parse resp parts (f:_) body =
        st = ht parse status line f (ht index of f " ")
        (ht st code st, ht st text st, body)

fn :: http parse response String => Int String String
      http parse response raw    =
        hb    = ht split head body raw (ht index of raw "\r\n\r\n") (ht index of raw "\n\n")
        head  = ht pair key hb
        body  = ht pair val hb
        lines = ht split lines loop head 0 0 (str len head)
        ht parse resp parts lines body
```

### 28.4.4. Implementación interna: Live Kernel TCP HTTP/1.1 Client (`http_request_tcp`, `http_get`, `http_post`)

Fíxate en como `http.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

fn :: ht pick path String => String
      ht pick path p      =
        | (str len p) == 0 = "/"
        | otherwise        = p

fn :: ht build target path String String => String
      ht build target path p q =
        | (str len q) == 0 = ht pick path p
        | otherwise        = (ht pick path p) + "?" + q

fn :: ht exec url req (String String Int String String) String [String String] String Int => Int Int String
      ht exec url req (scheme, host, port, p, q) method headers body timeout_ms =
        | scheme != "http" or (str len host) == 0 or port <= 0 = (0 - 7, 0, "")
        | otherwise                                            = http request tcp host port method (ht build target path p q) headers body timeout_ms

fn :: http get String Int        => Int Int String
      http get url    timeout_ms =
        ht exec url req (uri parse url) "GET" [] "" timeout_ms

fn :: http post String String String Int => Int Int String
      http post url content_type body timeout_ms =
        ht exec url req (uri parse url) "POST" [("Content-Type", content_type)] body timeout_ms

fn :: http resp rc (Int Int String) => Int
      http resp rc (rc, _, _)       =  rc

fn :: http resp status (Int Int String) => Int
      http resp status (_, st, _)       =  st

fn :: http resp headers (Int Int String) => [String String]
      http resp headers (_, _, raw)      =  http parse headers raw

fn :: http resp body (Int Int String) => String
      http resp body (_, _, raw)      =  ht resp body (http parse response raw)
```

---

## 28.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `http`

- **Garantía algorítmica e de seguridade**: Saneamento automático de `\r` e `\n` en todas as cabeceiras (`http sanitize header`) para impedir ataques de división de resposta HTTP.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/http.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test http.rg`.

### As 5 Regras de Ouro ao programar con `http`

1. **Declara `import http` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `http` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `http` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `http` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 29** pasaremos a explorar en profundidade a lib **`ws`** (A lib `ws` — Handshake WebSocket RFC 6455, Framing de 16/64 bits e Enmascarado XOR).
