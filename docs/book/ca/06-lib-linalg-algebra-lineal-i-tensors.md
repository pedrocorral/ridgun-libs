# Capítol 06: La lib `linalg` — Àlgebra Lineal sobre `Tensor[Real]`, Bareiss i Activacions

## 1. Per què existeix la lib `linalg`?

Siguem sincers: quan vols calcular similitud cosinus per a embeddings, resoldre $A x = b$ o avaluar una capa `softmax` en un binari lleuger, no vols arrossegar 400 MB de PyTorch o LAPACK.

La lib **`linalg`** construeix àlgebra lineal numèrica sobre `Tensor[Real]` natiu: transposició, traça, identitat, producte intern/extern, multiplicació matriu-vector i matriu-matriu amb notació d'Einstein, normes ($L_1, L_2, L_\infty$, Frobenius), determinant i resolució lineal $A x = b$ mitjançant eliminació de **Bareiss/Gauss amb pivotatge parcial**, i activacions neuronals (`relu`, `sigmoid`, `softmax`).

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`linalg`** és una **lib** de primera classe situada a `src/main/ridgun/lib/linalg.rg` (domini `LINALG`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/linalg.rglib` | Distribució i importació directa amb `import linalg` |
| **Fitxer compilat** | `target/linalg.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/liblinalg.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import linalg` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `linalg`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `linalg vec from list / linalg mat from lists` | Construeix `Tensor[Real]` 1D i 2D a partir de llistes de Ridgun |
| `linalg transpose / linalg trace / linalg diag / linalg identity` | Transformacions estructurals de matrius i matriu identitat |
| `linalg dot / linalg outer / linalg matvec / linalg matmul` | Einstein contraction (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `linalg norm l1 / linalg norm l2 / linalg cosine similarity` | Normes vectorials/matricials, normalització i similitud cosinus |
| `linalg det / linalg solve` | Determinant exacte de Bareiss i resolució $A x = b$ amb pivotatge parcial (`Option[Tensor[Real]]`) |
| `linalg relu / linalg sigmoid / linalg softmax` | Activacions neuronals numèricament estables amb desplaçament pel màxim |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `linalg`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import linalg

fn :: resolver sistema lineal () => Option[Tensor[Real]]
      resolver sistema lineal =
        -- Resuelve 2x + y = 5, x + 3y = 10 -> x = 1.0, y = 3.0
        a = linalg mat from lists [[2.0, 1.0], [1.0, 3.0]]
        b = linalg vec from list [5.0, 10.0]
        linalg solve a b
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `linalg` és componible amb la resta de les 32 libs de `ridgun-libs`:

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

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Les matrius singulars retornen `None` netament a `linalg solve` (sense `NaN` silenciosos), i `linalg softmax` resta el màxim abans d'exponenciar per evitar desbordaments.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_linalg.rg`.
