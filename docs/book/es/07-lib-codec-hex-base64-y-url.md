# Capítulo 07: La lib `codec` — Hex, Base64, Base64url, URL Percent-Encoding y JSON Ligero

## 1. ¿Por qué existe la lib `codec`?

Seamos sinceros: nada rompe más rápido una integración web que confundir Base64 estándar (`+/=`) con Base64url (`-_` sin relleno) en un token JWT, o construir una query string concatenando cadenas sin escapar.

La lib **`codec`** implementa los estándares **RFC 4648** (Hex, Base64 y Base64url), **RFC 3986** (codificación porcentual de URLs y diccionarios `query encode` / `query decode`) y constructores/extractores rápidos de **JSON ligero (RFC 8259)**.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`codec`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/codec.rg` (dominio `CODEC`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/codec.rglib` | Distribución e importación directa con `import codec` |
| **Archivo compilado** | `target/codec.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libcodec.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import codec` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `codec`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `hex encode / hex decode / hex is valid` | Codificación hexadecimal RFC 4648 en minúsculas y decodificación validada |
| `base64 encode / base64 decode` | Base64 estándar RFC 4648 §4 con relleno `=` |
| `base64url encode / base64url decode` | Base64url seguro para URLs RFC 4648 §5 (`-`, `_`, sin relleno) |
| `url encode / url decode / query encode / query decode` | Codificación porcentual RFC 3986 y diccionarios de query string `k=v&...` |
| `json quote / json object / json get str / json get int` | Serialización JSON rápida sin AST y extracción de claves de primer nivel |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `codec`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import codec

fn :: empaquetar parametros (usuario : String) (redir : String) => String
      empaquetar parametros usuario redir =
        token_b64 = base64url encode usuario
        query encode [("token", token_b64), ("next", redir)]
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `codec` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import codec

fn :: construir respuesta rapida (id : Int) (nombre : String) => (String, Int)
      construir respuesta rapida id nombre =
        doc = json object [("id", json int id), ("name", json quote nombre), ("ok", json bool True)]
        leido = json get int doc "id" 0
        (doc, leido)
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Rechazo determinista de entradas hexadecimales o Base64 mal formadas (devolviendo `""` sin lecturas fuera de límites) y reversibilidad exacta $decode(encode(x)) == x$.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_codec.rg`.
