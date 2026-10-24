# Capítulo 01: La lib `str` — Manipulación de Texto, Búsqueda y Formato Tabular

## 1. ¿Por qué existe la lib `str`?

Seamos sinceros: en C manipular cadenas con `strtok` y `strncpy` es caminar por un campo de minas de desbordamientos de búfer y punteros `NULL`, y en otros lenguajes acabas importando tres paquetes solo para alinear columnas o repetir un separador en $O(\log N)$.

La lib **`str`** proporciona todas las primitivas puras e inmutables para buscar, recortar, dividir, unir, cambiar mayúsculas/minúsculas, repetir por duplicación binaria $O(\log N)$ y rellenar cadenas.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`str`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/str.rg` (dominio `STR`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/str.rglib` | Distribución e importación directa con `import str` |
| **Archivo compilado** | `target/str.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libstr.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import str` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `str`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `str index of : String -> String -> Int` | Primer índice de la subcadena (`-1` si no existe / `0` si es vacía) |
| `str contains / str starts with / str ends with` | Predicados `Bool` de subcadena, prefijo y sufijo |
| `str trim / str trim left / str trim right` | Elimina espacios en blanco ASCII (` `, `\t`, `\n`, `\r`) |
| `str split / str lines / str words / str join` | Divide en `[String]` y une listas con un separador |
| `str replace / str to upper / str to lower` | Reemplazo sin solapamiento y conversión ASCII de mayúsculas/minúsculas |
| `str repeat / str pad left / str pad right` | Repetición en $O(\log N)$ y relleno de columnas a ancho fijo |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `str`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import str

fn :: normalizar cabecera (raw : String) => String
      normalizar cabecera raw =
        limpia = str to lower (str trim raw)
        partes = str words limpia
        slug   = str join partes "-"
        str pad right slug 24 "."
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `str` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import str

fn :: extraer dominio (correo : String) => String
      extraer dominio correo =
        pos = str index of correo "@"
        | pos < 0   = "sin-dominio"
        | otherwise =
          partes = str split correo "@"
          str replace (str to lower correo) "@" " en "
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Repetición en $O(\log N)$ mediante duplicación de cadenas, predicados seguros ante agujas vacías y cero mutación en el lugar.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_str.rg`.
