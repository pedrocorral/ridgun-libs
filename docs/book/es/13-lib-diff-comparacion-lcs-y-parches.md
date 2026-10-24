# Capítulo 13: La lib `diff` — Algoritmo LCS, Distancia de Edición, Unified Diff y Parches

## 1. ¿Por qué existe la lib `diff`?

Seamos sinceros: cuando un test falla o un archivo de configuración cambia, un seco `"expected A, got B"` de 200 líneas te obliga a dejarte las pestañas buscando qué línea exacta ha cambiado.

La lib **`diff`** calcula la **Subsecuencia Común Más Larga (LCS)** sobre `Tensor[Int]` 2D para producir ediciones mínimas (`DiffKeep`, `DiffAdd`, `DiffDel`), distancia de edición, estadísticas, formato **Unified Diff** (`---`/`+++`/`@@`) y reconstrucción exacta con `diff apply`.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`diff`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/diff.rg` (dominio `DIFF`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/diff.rglib` | Distribución e importación directa con `import diff` |
| **Archivo compilado** | `target/diff.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libdiff.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import diff` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `diff`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `type DiffOp` | `DiffKeep String | DiffDel String | DiffAdd String` |
| `diff lines / diff text` | Calcula el guion mínimo de edición LCS entre listas `[String]` o textos multilínea |
| `diff edit distance / diff stats` | Distancia mínima de inserción+borrado y recuento `(kept, added, deleted)` |
| `diff format / diff unified` | Formatea líneas compactas `+ / - /  ` o Unified Diff estándar con cabeceras |
| `diff apply / diff apply text` | Reconstruye el documento destino sin pérdidas a partir del guion de edición |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `diff`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import diff

fn :: auditar cambio (antes : String) (despues : String) => (Int, String)
      auditar cambio antes despues =
        dist   = diff edit distance ( ["host=localhost", "port=8080"] ) ( ["host=0.0.0.0", "port=8080"] )
        parche = diff unified "config.old" "config.new" antes despues
        (dist, parche)
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `diff` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import diff

fn :: verificar parche (orig : [String]) (nuevo : [String]) => [String]
      verificar parche orig nuevo =
        ops = diff lines orig nuevo
        diff apply ops
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Identidad matemática garantizada $diff\_edit\_distance(a, b) == |a| + |b| - 2 \cdot LCS(a, b)$ y reconstrucción sin pérdidas `diff apply (diff lines a b) == b`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_diff.rg`.
