# Kapitel 13: Lib:en `diff` — LCS-raddiff, Redigeringsavstånd, Unified Diff och Patchning

## 1. Varför finns lib:en `diff`?

Låt oss vara ärliga: när ett test fallerar eller en konfigurationsfil ändras tvingar en rå 200-raders `"expected A, got B"`-utskrift dig att kisa mot skärmen för att hitta exakt vilken rad som ändrats.

Lib:en **`diff`** beräknar **Longest Common Subsequence (LCS)** över en 2D `Tensor[Int]`-tabell för att skapa minimala redigeringssekvenser (`DiffKeep`, `DiffAdd`, `DiffDel`), redigeringsavstånd, **Unified Diff** (`---`/`+++`/`@@`) och förlustfri patchning (`diff apply`).

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`diff`** en förstklassig **lib** placerad i `src/main/ridgun/lib/diff.rg` (domän `DIFF`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/diff.rglib` | Portabel distribution och direkt import med `import diff` |
| **Kompilerat arkiv** | `target/diff.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libdiff.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import diff` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `diff`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `type DiffOp` | `DiffKeep String | DiffDel String | DiffAdd String` |
| `diff lines / diff text` | Beräknar minimalt LCS-redigeringsskript mellan `[String]`-listor eller flerradiga texter |
| `diff edit distance / diff stats` | Minimalt insättnings-/borttagningsavstånd och `(kept, added, deleted)`-antal |
| `diff format / diff unified` | Renderar kompakta `+ / - /  `-rader eller standard Unified Diff med rubriker |
| `diff apply / diff apply text` | Återskapar måldokumentet förlustfritt från ett redigeringsskript |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `diff`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import diff

fn :: auditar cambio (antes : String) (despues : String) => (Int, String)
      auditar cambio antes despues =
        dist   = diff edit distance ( ["host=localhost", "port=8080"] ) ( ["host=0.0.0.0", "port=8080"] )
        parche = diff unified "config.old" "config.new" antes despues
        (dist, parche)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `diff` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import diff

fn :: verificar parche (orig : [String]) (nuevo : [String]) => [String]
      verificar parche orig nuevo =
        ops = diff lines orig nuevo
        diff apply ops
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Garanterad matematisk identitet $diff\_edit\_distance(a, b) == |a| + |b| - 2 \cdot LCS(a, b)$ och förlustfri rekonstruktion `diff apply (diff lines a b) == b`.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_diff.rg`.
