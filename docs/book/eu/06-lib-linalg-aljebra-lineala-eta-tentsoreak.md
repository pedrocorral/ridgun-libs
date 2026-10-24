# 06. kapitulua: `linalg` lib-a — `Tensor[Real]` gaineko Aljebra Lineala, Bareiss eta Aktibazioak

## 1. Zergatik existitzen da `linalg` lib-a?

Izan gaitezen zintzoak: embedding-etarako kosinu-antzekotasuna kalkulatu, $A x = b$ ebatzi edo bitar arin batean `softmax` geruza bat ebaluatu nahi duzunean, ez dituzu PyTorch edo LAPACKen 400 MB arrastaka eraman nahi.

**`linalg`** lib-ak zenbakizko aljebra lineala eraikitzen du `Tensor[Real]` natiboaren gainean: iraulketa, aztarna, identitatea, biderkadura eskalarrak eta matrizialak Einsteinen notazioarekin, normak ($L_1, L_2, L_\infty$, Frobenius), determinantea eta $A x = b$ ebazpena **Bareiss/Gauss** algoritmoarekin, eta aktibazio neuronalak (`relu`, `sigmoid`, `softmax`).

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`linalg`** lehen mailako **lib** bat da, `src/main/ridgun/lib/linalg.rg` bidean kokatua (`LINALG` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/linalg.rglib` | Banaketa eta inportazio zuzena `import linalg` bidez |
| **Fitxategi konpilatua** | `target/linalg.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/liblinalg.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import linalg` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `linalg` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `linalg vec from list / linalg mat from lists` | Ridgun zerrendetatik 1D eta 2D `Tensor[Real]` eraikitzen ditu |
| `linalg transpose / linalg trace / linalg diag / linalg identity` | Matrizeen egitura-eraldaketak eta identitate-matrizea |
| `linalg dot / linalg outer / linalg matvec / linalg matmul` | Einstein contraction (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `linalg norm l1 / linalg norm l2 / linalg cosine similarity` | Bektore/matrize normak, normalizazioa eta kosinu-antzekotasuna |
| `linalg det / linalg solve` | Bareissen determinante zehatza eta $A x = b$ ebazlea pibotatze partzialarekin (`Option[Tensor[Real]]`) |
| `linalg relu / linalg sigmoid / linalg softmax` | Maximoaren bidezko desplazamendudun aktibazio neuronal zenbakiz egonkorrak |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `linalg` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import linalg

fn :: resolver sistema lineal () => Option[Tensor[Real]]
      resolver sistema lineal =
        -- Resuelve 2x + y = 5, x + 3y = 10 -> x = 1.0, y = 3.0
        a = linalg mat from lists [[2.0, 1.0], [1.0, 3.0]]
        b = linalg vec from list [5.0, 10.0]
        linalg solve a b
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`linalg` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

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

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Matrize singularrek `None` itzultzen dute garbi `linalg solve`-n (`NaN` isilik gabe), eta `linalg softmax`-ek maximoa kentzen du berreketa aurretik gainezkatzeak saihesteko.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_linalg.rg` suite automatizatuaren bidez.
