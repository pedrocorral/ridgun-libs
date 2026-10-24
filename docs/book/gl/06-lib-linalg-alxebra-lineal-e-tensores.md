# Capítulo 06: A lib `linalg` — Álxebra Lineal sobre `Tensor[Real]`, Bareiss e Activacións

## 1. Por que existe a lib `linalg`?

Sexamos sinceros: cando queres calcular similitude coseno para embeddings, resolver $A x = b$ ou avaliar unha capa `softmax` nun binario lixeiro, non queres arrastrar 400 MB de PyTorch ou LAPACK.

A lib **`linalg`** constrúe álxebra lineal numérica sobre `Tensor[Real]` nativo: transposición, traza, identidade, produto interno/externo, multiplicación matriz-vector e matriz-matriz con notación de Einstein, normas ($L_1, L_2, L_\infty$, Frobenius), determinante e resolución lineal $A x = b$ mediante eliminación de **Bareiss/Gauss con pivoteo parcial**, e activacións neuronais (`relu`, `sigmoid`, `softmax`).

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`linalg`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/linalg.rg` (dominio `LINALG`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/linalg.rglib` | Distribución e importación directa con `import linalg` |
| **Ficheiro compilado** | `target/linalg.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/liblinalg.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import linalg` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `linalg`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `linalg vec from list / linalg mat from lists` | Constrúe `Tensor[Real]` 1D e 2D a partir de listas de Ridgun |
| `linalg transpose / linalg trace / linalg diag / linalg identity` | Transformacións estruturais de matrices e matriz identidade |
| `linalg dot / linalg outer / linalg matvec / linalg matmul` | Einstein contraction (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `linalg norm l1 / linalg norm l2 / linalg cosine similarity` | Normas vectoriais/matriciais, normalización e similitude coseno |
| `linalg det / linalg solve` | Determinante exacto de Bareiss e resolución $A x = b$ con pivoteo parcial (`Option[Tensor[Real]]`) |
| `linalg relu / linalg sigmoid / linalg softmax` | Activacións neuronais numericamente estables con desprazamento polo máximo |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `linalg`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import linalg

fn :: resolver sistema lineal () => Option[Tensor[Real]]
      resolver sistema lineal =
        -- Resuelve 2x + y = 5, x + 3y = 10 -> x = 1.0, y = 3.0
        a = linalg mat from lists [[2.0, 1.0], [1.0, 3.0]]
        b = linalg vec from list [5.0, 10.0]
        linalg solve a b
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `linalg` é compoñible co resto das 32 libs de `ridgun-libs`:

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

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: As matrices singulares devolven `None` limpamente en `linalg solve` (sen `NaN` silenciosos), e `linalg softmax` resta o máximo antes de exponenciar para evitar desbordamentos.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_linalg.rg`.
