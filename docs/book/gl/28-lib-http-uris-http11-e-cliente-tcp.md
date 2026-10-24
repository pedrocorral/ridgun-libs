# Capítulo 28: A lib `http` — URIs RFC 3986, Codec HTTP/1.1 RFC 9112 e Cliente TCP en Vivo

## 1. Por que existe a lib `http`?

Sexamos sinceros: se non filtras saltos `\r\n` nos valores das cabeceiras HTTP, un atacante pode inxectar cabeceiras falsas ou dividir a resposta (*CRLF Response Splitting*), e enlazar `libcurl` para facer un simple `GET` ou `POST` é excesivo.

A lib **`http`** implementa descomposición de **URIs RFC 3986**, construción e análise de peticións e respostas **HTTP/1.1 RFC 9112** con saneamento automático de CRLF (`VUL-INJ-002`) e `Content-Length` automático, extracción de tokens `Bearer` e un **cliente HTTP/1.1 en vivo sobre sockets TCP do kernel** (`http get`, `http post`, `http request tcp`).

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`http`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/http.rg` (dominio `HTTP`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/http.rglib` | Distribución e importación directa con `import http` |
| **Ficheiro compilado** | `target/http.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libhttp.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import http` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `http`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `uri parse / uri scheme / uri host / uri port / uri path / uri query` | Descompón URIs RFC 3986 con portos por defecto automáticos (`80` en `http`, `443` en `https`) |
| `http build request / http parse request` | Formatea e analiza peticións HTTP/1.1 con saneamento CRLF de cabeceiras |
| `http build response / http parse response` | Formatea e analiza respostas HTTP/1.1 con frases de estado estándar |
| `http header get / http bearer token` | Busca de cabeceiras insensible a maiúsculas e extracción de `Authorization: Bearer <token>` |
| `http get / http post / http request tcp` | Executa chamadas HTTP/1.1 en vivo sobre sockets TCP do kernel con `timeout_ms` |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `http`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

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

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `http` é compoñible co resto das 32 libs de `ridgun-libs`:

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

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Saneamento automático de `\r` e `\n` en todas as cabeceiras (`http sanitize header`) para impedir ataques de división de resposta HTTP.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_http.rg`.
