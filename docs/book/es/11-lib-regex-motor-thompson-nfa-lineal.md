# Capítulo 11: La lib `regex` — Motor de Expresiones Regulares Thompson NFA en Tiempo Lineal $O(N \cdot M)$

## 1. ¿Por qué existe la lib `regex`?

Seamos sinceros: los motores de expresiones regulares con *backtracking* han causado caídas globales famosas (como en Cloudflare o StackOverflow) cuando un patrón como `(a+)+b` recibe treinta `a` seguidas y entra en tiempo exponencial $O(2^N)$.

La lib **`regex`** compila tus expresiones regulares (`.`, `*`, `+`, `?`, `|`, `()`, `[a-z]`, `[^...]`, `^`, `$`, `\d`, `\w`, `\s`) a un **autómata finito no determinista de Thompson (NFA)** y avanza el conjunto de estados paso a paso en tiempo estrictamente lineal **$O(N \cdot M)$**, haciendo que los ataques **ReDoS sean matemáticamente imposibles**.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`regex`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/regex.rg` (dominio `REGEX`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/regex.rglib` | Distribución e importación directa con `import regex` |
| **Archivo compilado** | `target/regex.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libregex.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import regex` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `regex`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `regex match / regex is match` | Coincidencia de cadena completa y búsqueda de subcadena en tiempo lineal $O(N \cdot M)$ |
| `regex find / regex find all` | Extrae la primera o todas las subcadenas coincidentes sin solapamiento |
| `regex replace / regex replace all` | Reemplaza la primera o todas las coincidencias de la expresión regular |
| `regex split / regex escape` | Divide texto según un delimitador regex y escapa metacaracteres |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `regex`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import regex

fn :: extraer codigos postales (texto : String) => [String]
      extraer codigos postales texto =
        regex find all "\\d+" texto
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `regex` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import regex

fn :: censurar telefonos (comentario : String) => (Bool, String)
      censurar telefonos comentario =
        tiene = regex is match "\\d+-\\d+" comentario
        limpio = regex replace all "\\d+-\\d+" comentario "[TELEFONO]"
        (tiene, limpio)
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Simulación de conjunto de estados NFA sin recursión descontrolada de pila y tiempo $O(N \cdot M)$ garantizado incluso ante patrones patológicos `(a+)+b`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_regex.rg`.
