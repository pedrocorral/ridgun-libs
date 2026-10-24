# Capítulo 28: La lib `http` — URIs RFC 3986, Codec HTTP/1.1 RFC 9112 y Cliente TCP en Vivo

## 1. ¿Por qué existe la lib `http`?

Seamos sinceros: si no filtras saltos `\r\n` en los valores de las cabeceras HTTP, un atacante puede inyectar cabeceras falsas o dividir la respuesta (*CRLF Response Splitting*), y enlazar `libcurl` para hacer un simple `GET` o `POST` es excesivo.

La lib **`http`** implementa descomposición de **URIs RFC 3986**, construcción y análisis de peticiones y respuestas **HTTP/1.1 RFC 9112** con sanitización automática de CRLF (`VUL-INJ-002`) y `Content-Length` automático, extracción de tokens `Bearer` y un **cliente HTTP/1.1 en vivo sobre sockets TCP del kernel** (`http get`, `http post`, `http request tcp`).

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`http`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/http.rg` (dominio `HTTP`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/http.rglib` | Distribución e importación directa con `import http` |
| **Archivo compilado** | `target/http.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libhttp.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import http` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `http`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `uri parse / uri scheme / uri host / uri port / uri path / uri query` | Descompone URIs RFC 3986 con puertos por defecto automáticos (`80` en `http`, `443` en `https`) |
| `http build request / http parse request` | Formatea y analiza peticiones HTTP/1.1 con sanitización CRLF de cabeceras |
| `http build response / http parse response` | Formatea y analiza respuestas HTTP/1.1 con frases de estado estándar |
| `http header get / http bearer token` | Búsqueda de cabeceras insensible a mayúsculas y extracción de `Authorization: Bearer <token>` |
| `http get / http post / http request tcp` | Ejecuta llamadas HTTP/1.1 en vivo sobre sockets TCP del kernel con `timeout_ms` |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `http`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

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

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `http` es componible con el resto de las 32 libs de `ridgun-libs`:

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

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Sanitización automática de `\r` y `\n` en todas las cabeceras (`http sanitize header`) para impedir ataques de división de respuesta HTTP.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_http.rg`.
