# Capítulo 15: La lib `fmt` — Formateador Tabular Canónico 2D y Resaltador de Sintaxis en 9 Formatos

## 1. ¿Por qué existe la lib `fmt`?

Seamos sinceros: la belleza del código Ridgun reside en sus columnas tabulares perfectamente alineadas (`::`, `=`, `|`, `->`, `--`), pero alinear espacios a mano o exportar código coloreado para terminal, HTML y LaTeX sin una herramienta dedicada es tedioso.

La lib **`fmt`** es el motor oficial de formateo tabular 2D y resaltado léxico de Ridgun: alinea firmas `fn ::`, ecuaciones, guardas `|` y comentarios `--`, y exporta a **9 formatos de salida** (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`).

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`fmt`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/fmt.rg` (dominio `FMT`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/fmt.rglib` | Distribución e importación directa con `import fmt` |
| **Archivo compilado** | `target/fmt.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libfmt.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import fmt` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `fmt`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `fmt source / fmt source with` | Formatea código fuente Ridgun usando la alineación tabular 2D canónica |
| `fmt check` | Devuelve `True` si el código ya cumple el formato tabular canónico de `fmt source` |
| `fmt render / fmt render with` | Formatea y colorea el código hacia cualquiera de los 9 formatos `FmtTarget` |
| `fmt tokenize line` | Tokeniza una línea en `TokKeyword`, `TokType`, `TokOperator`, `TokString`, `TokNumber`, `TokComment` |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `fmt`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import fmt

fn :: formatear y verificar (codigo : String) => (String, Bool)
      formatear y verificar codigo =
        limpio = fmt source codigo
        es_ok  = fmt check limpio
        (limpio, es_ok)
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `fmt` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import fmt

fn :: exportar bloque html (codigo : String) => String
      exportar bloque html codigo =
        fmt render codigo FmtHtmlCss
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Idempotencia estricta (`fmt source (fmt source s) == fmt source s`) y preservación del 100 % de los tokens semánticos.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_fmt.rg`.
