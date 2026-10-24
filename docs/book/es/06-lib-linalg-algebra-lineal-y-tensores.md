# Capítulo 06: La lib `linalg` — Álgebra Lineal sobre `Tensor[Real]`, Bareiss y Activaciones

## 1. ¿Por qué existe la lib `linalg`?

Seamos sinceros: cuando quieres calcular similitud coseno para embeddings, resolver $A x = b$ o evaluar una capa `softmax` en un binario ligero, no quieres arrastrar 400 MB de PyTorch o LAPACK.

La lib **`linalg`** construye álgebra lineal numérica sobre `Tensor[Real]` nativo: transposición, traza, identidad, producto interno/externo, multiplicación matriz-vector y matriz-matriz con notación de Einstein, normas ($L_1, L_2, L_\infty$, Frobenius), determinante y resolución lineal $A x = b$ mediante eliminación de **Bareiss/Gauss con pivoteo parcial**, y activaciones neuronales (`relu`, `sigmoid`, `softmax`).

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`linalg`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/linalg.rg` (dominio `LINALG`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/linalg.rglib` | Distribución e importación directa con `import linalg` |
| **Archivo compilado** | `target/linalg.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/liblinalg.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import linalg` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `linalg`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `linalg vec from list / linalg mat from lists` | Construye `Tensor[Real]` 1D y 2D a partir de listas de Ridgun |
| `linalg transpose / linalg trace / linalg diag / linalg identity` | Transformaciones estructurales de matrices y matriz identidad |
| `linalg dot / linalg outer / linalg matvec / linalg matmul` | Einstein contraction (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `linalg norm l1 / linalg norm l2 / linalg cosine similarity` | Normas vectoriales/matriciales, normalización y similitud coseno |
| `linalg det / linalg solve` | Determinante exacto de Bareiss y resolución $A x = b$ con pivoteo parcial (`Option[Tensor[Real]]`) |
| `linalg relu / linalg sigmoid / linalg softmax` | Activaciones neuronales numéricamente estables con desplazamiento por máximo |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `linalg`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import linalg

fn :: resolver sistema lineal () => Option[Tensor[Real]]
      resolver sistema lineal =
        -- Resuelve 2x + y = 5, x + 3y = 10 -> x = 1.0, y = 3.0
        a = linalg mat from lists [[2.0, 1.0], [1.0, 3.0]]
        b = linalg vec from list [5.0, 10.0]
        linalg solve a b
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `linalg` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import linalg

fn :: puntuar embeddings () => (Real, Tensor[Real])
      puntuar embeddings =
        q     = linalg vec from list [1.0, 2.0, 3.0]
        d     = linalg vec from list [1.0, 2.0, 3.0]
        sim   = linalg cosine similarity q d
        probs = linalg softmax q
        (sim, probs)
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Las matrices singulares devuelven `None` limpiamente en `linalg solve` (sin `NaN` silenciosos), y `linalg softmax` resta el máximo antes de exponenciar para evitar desbordamientos.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_linalg.rg`.
