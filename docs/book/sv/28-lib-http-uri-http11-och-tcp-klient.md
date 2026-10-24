# Kapitel 28: Lib:en `http` — RFC 3986 URI, RFC 9112 HTTP/1.1-kodek och Direkt TCP-klient

## 1. Varför finns lib:en `http`?

Låt oss vara ärliga: om man inte rensar bort `\r\n` i HTTP-headers kan en angripare injicera egna headers (*CRLF Response Splitting*), och att länka in `libcurl` bara för att göra ett `GET`- eller `POST`-anrop är överdrivet.

Lib:en **`http`** implementerar **RFC 3986 URI**-tolkning, **RFC 9112 HTTP/1.1**-formatering och tolkning med automatisk CRLF-sanering (`VUL-INJ-002`) och automatisk `Content-Length`, extrahering av `Bearer`-tokens samt en **direkt HTTP/1.1-klient över kärnans TCP-sockets** (`http get`, `http post`, `http request tcp`).

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`http`** en förstklassig **lib** placerad i `src/main/ridgun/lib/http.rg` (domän `HTTP`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/http.rglib` | Portabel distribution och direkt import med `import http` |
| **Kompilerat arkiv** | `target/http.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libhttp.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import http` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `http`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `uri parse / uri scheme / uri host / uri port / uri path / uri query` | Delar upp RFC 3986-URI:er med automatiska standardportar (`80` för `http`, `443` för `https`) |
| `http build request / http parse request` | Formaterar och tolkar HTTP/1.1-anrop med CRLF-sanering av headers |
| `http build response / http parse response` | Formaterar och tolkar HTTP/1.1-svar med standardiserade statusfraser |
| `http header get / http bearer token` | Skiftlägesokänslig header-uppslagning och extrahering av `Authorization: Bearer <token>` |
| `http get / http post / http request tcp` | Kör direkta HTTP/1.1-anrop över kärnans TCP-sockets med `timeout_ms` |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `http`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

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

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `http` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import http

fn :: extraer credenciales (raw_req : String) => (String, String)
      extraer credenciales raw_req =
        (metodo, ruta, _, hdrs_raw, _) = http parse request raw_req
        hdrs = http parse headers hdrs_raw
        tok  = http bearer token hdrs
        (metodo + " " + ruta, tok)
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Automatisk borttagning av `\r` och `\n` i alla headers (`http sanitize header`) för att förhindra HTTP response-splitting.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_http.rg`.
