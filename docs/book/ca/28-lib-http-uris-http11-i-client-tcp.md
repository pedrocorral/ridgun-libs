# Capítol 28: La lib `http` — URIs RFC 3986, Codec HTTP/1.1 RFC 9112 i Client TCP en Viu

## 1. Per què existeix la lib `http`?

Siguem sincers: si no filtres salts `\r\n` en els valors de les capçaleres HTTP, un atacant pot injectar capçaleres falses o dividir la resposta (*CRLF Response Splitting*), i enllaçar `libcurl` per fer un simple `GET` o `POST` és excessiu.

La lib **`http`** implementa descomposició d'**URIs RFC 3986**, construcció i anàlisi de peticions i respostes **HTTP/1.1 RFC 9112** amb sanejament automàtic de CRLF (`VUL-INJ-002`) i `Content-Length` automàtic, extracció de tokens `Bearer` i un **client HTTP/1.1 en viu sobre sockets TCP del nucli** (`http get`, `http post`, `http request tcp`).

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`http`** és una **lib** de primera classe situada a `src/main/ridgun/lib/http.rg` (domini `HTTP`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/http.rglib` | Distribució i importació directa amb `import http` |
| **Fitxer compilat** | `target/http.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libhttp.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import http` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `http`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `uri parse / uri scheme / uri host / uri port / uri path / uri query` | Descompon URIs RFC 3986 amb ports per defecte automàtics (`80` en `http`, `443` en `https`) |
| `http build request / http parse request` | Formata i analitza peticions HTTP/1.1 amb sanejament CRLF de capçaleres |
| `http build response / http parse response` | Formata i analitza respostes HTTP/1.1 amb frases d'estat estàndard |
| `http header get / http bearer token` | Cerca de capçaleres insensible a majúscules i extracció d'`Authorization: Bearer <token>` |
| `http get / http post / http request tcp` | Executa crides HTTP/1.1 en viu sobre sockets TCP del nucli amb `timeout_ms` |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `http`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

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

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `http` és componible amb la resta de les 32 libs de `ridgun-libs`:

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

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Sanejament automàtic de `\r` i `\n` en totes les capçaleres (`http sanitize header`) per impedir atacs de divisió de resposta HTTP.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_http.rg`.
