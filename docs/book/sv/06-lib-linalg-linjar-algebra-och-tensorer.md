# Kapitel 06: Lib:en `linalg` — Linjär Algebra över `Tensor[Real]`, Bareiss-lösare och Aktiveringar

## 1. Varför finns lib:en `linalg`?

Låt oss vara ärliga: när du vill beräkna cosinuslikhet för embeddings, lösa $A x = b$ eller köra ett `softmax`-lager i en lättviktig tjänst vill du inte släpa med 400 MB PyTorch eller LAPACK.

Lib:en **`linalg`** bygger numerisk linjär algebra direkt på inbyggda `Tensor[Real]`: transponering, spår, identitetsmatris, inre/yttre produkt, Einsteinkontraherad `matvec` och `matmul`, normer ($L_1, L_2, L_\infty$, Frobenius), **Bareiss/Gauss**-determinant och $A x = b$-lösare samt neuronnätsaktiveringar (`relu`, `sigmoid`, `softmax`).

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`linalg`** en förstklassig **lib** placerad i `src/main/ridgun/lib/linalg.rg` (domän `LINALG`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/linalg.rglib` | Portabel distribution och direkt import med `import linalg` |
| **Kompilerat arkiv** | `target/linalg.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/liblinalg.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import linalg` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `linalg`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `linalg vec from list / linalg mat from lists` | Konstruerar 1D- och 2D-`Tensor[Real]` från Ridgun-listor |
| `linalg transpose / linalg trace / linalg diag / linalg identity` | Strukturella matristransformationer och identitetsmatriser |
| `linalg dot / linalg outer / linalg matvec / linalg matmul` | Einstein contraction (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `linalg norm l1 / linalg norm l2 / linalg cosine similarity` | Vektor-/matrisnormer, normalisering och cosinuslikhet |
| `linalg det / linalg solve` | Exakt Bareiss-determinant och $A x = b$-lösare med partiell pivotering (`Option[Tensor[Real]]`) |
| `linalg relu / linalg sigmoid / linalg softmax` | Numeriskt stabila neuronnätsaktiveringar med max-förskjutning |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `linalg`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import linalg

fn :: resolver sistema lineal () => Option[Tensor[Real]]
      resolver sistema lineal =
        -- Resuelve 2x + y = 5, x + 3y = 10 -> x = 1.0, y = 3.0
        a = linalg mat from lists [[2.0, 1.0], [1.0, 3.0]]
        b = linalg vec from list [5.0, 10.0]
        linalg solve a b
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `linalg` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

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

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Singulära matriser returnerar `None` rent i `linalg solve` (inga tysta `NaN`), och `linalg softmax` subtraherar maxvärdet före exponentiering för att förhindra spill.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_linalg.rg`.
