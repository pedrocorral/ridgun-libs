# Capítol 13: La lib `diff` — Algorisme LCS, Distància d'Edició, Unified Diff i Pedaços

## 1. Per què existeix la lib `diff`?

Siguem sincers: quan un test falla o un fitxer de configuració canvia, un sec `"expected A, got B"` de 200 línies t'obliga a deixar-te les pestanyes buscant quina línia exacta ha canviat.

La lib **`diff`** calcula la **Subseqüència Comuna Més Llarga (LCS)** sobre `Tensor[Int]` 2D per produir edicions mínimes (`DiffKeep`, `DiffAdd`, `DiffDel`), distància d'edició, estadístiques, format **Unified Diff** (`---`/`+++`/`@@`) i reconstrucció exacta amb `diff apply`.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`diff`** és una **lib** de primera classe situada a `src/main/ridgun/lib/diff.rg` (domini `DIFF`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/diff.rglib` | Distribució i importació directa amb `import diff` |
| **Fitxer compilat** | `target/diff.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libdiff.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import diff` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `diff`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `type DiffOp` | `DiffKeep String | DiffDel String | DiffAdd String` |
| `diff lines / diff text` | Calcula el guió mínim d'edició LCS entre llistes `[String]` o textos multilínia |
| `diff edit distance / diff stats` | Distància mínima d'inserció+esborrat i recompte `(kept, added, deleted)` |
| `diff format / diff unified` | Formata línies compactes `+ / - /  ` o Unified Diff estàndard amb capçaleres |
| `diff apply / diff apply text` | Reconstrueix el document destí sense pèrdues a partir del guió d'edició |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `diff`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import diff

fn :: auditar cambio (antes : String) (despues : String) => (Int, String)
      auditar cambio antes despues =
        dist   = diff edit distance ( ["host=localhost", "port=8080"] ) ( ["host=0.0.0.0", "port=8080"] )
        parche = diff unified "config.old" "config.new" antes despues
        (dist, parche)
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `diff` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import diff

fn :: verificar parche (orig : [String]) (nuevo : [String]) => [String]
      verificar parche orig nuevo =
        ops = diff lines orig nuevo
        diff apply ops
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Identitat matemàtica garantida $diff\_edit\_distance(a, b) == |a| + |b| - 2 \cdot LCS(a, b)$ i reconstrucció sense pèrdues `diff apply (diff lines a b) == b`.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_diff.rg`.
