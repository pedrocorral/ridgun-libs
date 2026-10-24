# 28. kapitulua: `http` lib-a — RFC 3986 URIak, RFC 9112 HTTP/1.1 Kodeka eta Zuzeneko TCP Bezeroa

## 1. Zergatik existitzen da `http` lib-a?

Izan gaitezen zintzoak: HTTP goiburuetako balioetan `\r\n` jauziak iragazten ez badituzu, erasotzaile batek goiburu faltsuak txerta ditzake (*CRLF Response Splitting*), eta `GET` edo `POST` soil bat egiteko `libcurl` estekatzea gehiegizkoa da.

**`http`** lib-ak **RFC 3986 URIen** deskonposizioa, **RFC 9112 HTTP/1.1** eskaera eta erantzunen eraikuntza zein analisia CRLF garbiketa automatikoarekin (`VUL-INJ-002`) eta `Content-Length` automatikoarekin, `Bearer` tokenen erauzketa eta **nukleoko TCP socketen gaineko zuzeneko HTTP/1.1 bezeroa** (`http get`, `http post`, `http request tcp`) inplementatzen ditu.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`http`** lehen mailako **lib** bat da, `src/main/ridgun/lib/http.rg` bidean kokatua (`HTTP` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/http.rglib` | Banaketa eta inportazio zuzena `import http` bidez |
| **Fitxategi konpilatua** | `target/http.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libhttp.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import http` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `http` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `uri parse / uri scheme / uri host / uri port / uri path / uri query` | RFC 3986 URIak deskonposatzen ditu lehenetsitako ataka automatikoekin (`80` / `443`) |
| `http build request / http parse request` | HTTP/1.1 eskaerak formateatu eta analizatzen ditu goiburuen CRLF garbiketarekin |
| `http build response / http parse response` | HTTP/1.1 erantzunak formateatu eta analizatzen ditu egoera-esaldiekin |
| `http header get / http bearer token` | Letra larri/xeheekiko sentikorra ez den goiburu-bilaketa eta `Bearer <token>` erauzketa |
| `http get / http post / http request tcp` | Zuzeneko HTTP/1.1 deiak exekutatzen ditu nukleoko TCP socketen gainean `timeout_ms`-rekin |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `http` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

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

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`http` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

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

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: `\r` eta `\n` karaktereen garbiketa automatikoa goiburu guztietan (`http sanitize header`) HTTP erantzun-zatikatze erasoak eragozteko.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_http.rg` suite automatizatuaren bidez.
