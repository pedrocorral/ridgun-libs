# Capítulo 08: La lib `json` — Árbol AST Recursivo RFC 8259, Pretty-Printer y Consultas por Ruta

## 1. ¿Por qué existe la lib `json`?

Seamos sinceros: navegar un JSON anidado en muchos lenguajes estáticos implica escribir tres pantallas de boilerplate o encadenar diez `.and_then()` antes de leer un simple puerto.

La lib **`json`** proporciona un analizador descendente recursivo completo para **RFC 8259** sobre el ADT algebraico `JsonVal` (`JnNull`, `JnBool`, `JnInt`, `JnStr`, `JnArr`, `JnObj`, `JnErr`), serialización compacta e indentada (`json pretty`) y consultas directas por ruta con puntos (`"server.http.port"`, `"users.0.name"`).

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`json`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/json.rg` (dominio `JSON`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/json.rglib` | Distribución e importación directa con `import json` |
| **Archivo compilado** | `target/json.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libjson.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import json` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `json`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `type JsonVal` | `JnNull | JnBool Bool | JnInt Int | JnStr String | JnArr [JsonVal] | JnObj [String JsonVal] | JnErr String` |
| `json parse / json is ok` | Analiza texto JSON en un árbol `JsonVal` y valida la ausencia de `JnErr` |
| `json stringify / json pretty` | Serializa `JsonVal` a JSON compacto o multilínea indentado |
| `json get path / json get str / json get int / json get bool` | Recorre objetos y listas anidados mediante rutas con puntos (`"a.b.0.c"`) |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `json`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import json

fn :: leer config servidor (raw : String) => (String, Int, Bool)
      leer config servidor raw =
        doc  = json parse raw
        host = json get str doc "server.host" "127.0.0.1"
        port = json get int doc "server.port" 8080
        tls  = json get bool doc "server.tls.enabled" False
        (host, port, tls)
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `json` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import json

fn :: construir manifiesto () => String
      construir manifiesto =
        nodo = JnObj [("app", JnStr "solstice"), ("workers", JnInt 8), ("tags", JnArr [JnStr "elf64", JnStr "rmm2"])]
        json pretty nodo 2
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Rechazo estricto de basura sobrante tras el valor raíz (`trailing garbage`), manejo completo de escapes y retorno seguro de `JnErr` sin excepciones.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_json.rg`.
