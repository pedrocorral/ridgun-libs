# 13. kapitulua: `diff` lib-a — LCS Algoritmoa, Edizio-distantzia, Unified Diff eta Adabakiak

## 1. Zergatik existitzen da `diff` lib-a?

Izan gaitezen zintzoak: test batek huts egiten duenean edo konfigurazio-fitxategi bat aldatzen denean, 200 lerroko `"expected A, got B"` lehor batek zein lerro zehatz aldatu den bilatzen begiak uztera behartzen zaitu.

**`diff`** lib-ak **Azpisekuentzia Komun Luzeena (LCS)** kalkulatzen du 2D `Tensor[Int]` baten gainean edizio minimoak (`DiffKeep`, `DiffAdd`, `DiffDel`), edizio-distantzia, estatistikak, **Unified Diff** formatua eta `diff apply` bidezko berreraikuntza zehatza sortzeko.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`diff`** lehen mailako **lib** bat da, `src/main/ridgun/lib/diff.rg` bidean kokatua (`DIFF` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/diff.rglib` | Banaketa eta inportazio zuzena `import diff` bidez |
| **Fitxategi konpilatua** | `target/diff.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libdiff.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import diff` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `diff` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `type DiffOp` | `DiffKeep String | DiffDel String | DiffAdd String` |
| `diff lines / diff text` | `[String]` zerrenden edo lerro anitzeko testuen arteko LCS edizio-gidoi minimoa kalkulatzen du |
| `diff edit distance / diff stats` | Txertaketa+ezabaketa distantzia minimoa eta `(kept, added, deleted)` zenbaketa |
| `diff format / diff unified` | `+ / - /  ` lerro trinkoak edo goiburudun Unified Diff estandarra errenderizatzen ditu |
| `diff apply / diff apply text` | Helburuko dokumentua galerarik gabe berreraikitzen du edizio-gidoitik abiatuta |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `diff` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import diff

fn :: auditar cambio (antes : String) (despues : String) => (Int, String)
      auditar cambio antes despues =
        dist   = diff edit distance ( ["host=localhost", "port=8080"] ) ( ["host=0.0.0.0", "port=8080"] )
        parche = diff unified "config.old" "config.new" antes despues
        (dist, parche)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`diff` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import diff

fn :: verificar parche (orig : [String]) (nuevo : [String]) => [String]
      verificar parche orig nuevo =
        ops = diff lines orig nuevo
        diff apply ops
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: $diff\_edit\_distance(a, b) == |a| + |b| - 2 \cdot LCS(a, b)$ identitate matematiko bermatua eta galerarik gabeko berreraikuntza: `diff apply (diff lines a b) == b`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_diff.rg` suite automatizatuaren bidez.
