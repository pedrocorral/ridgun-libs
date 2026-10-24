# 12. kapitulua: `glob` lib-a — Komodin-ereduak (`*`, `?`, `[a-z]`) eta Zerrenden Iragazketa

## 1. Zergatik existitzen da `glob` lib-a?

Izan gaitezen zintzoak: fitxategi bat `*.rg`-rekin amaitzen den edo `test_[0-9]*.rg`-rekin hasten den egiaztatzeko adierazpen erregular oso bat erabiltzea euliak kanoikadaka hiltzea da.

**`glob`** lib-ak shell komodinen bat-etortze zehatza (`*`, `?`, `[a-z]` klaseak, `[!0-9]` / `[^a-z]` klase ukatuak), letra larri/xeheekiko aldaera sentikorrak (`glob match ci`) eta bide-zerrenden iragazketa zuzena inplementatzen ditu.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`glob`** lehen mailako **lib** bat da, `src/main/ridgun/lib/glob.rg` bidean kokatua (`GLOB` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/glob.rglib` | Banaketa eta inportazio zuzena `import glob` bidez |
| **Fitxategi konpilatua** | `target/glob.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libglob.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import glob` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `glob` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `glob match / glob match ci` | ASCII letra larri/xeheekiko sentikorra edo ez-sentikorra den glob bat-etortzea |
| `glob filter / glob any match` | `[String]` iragazten du edo zerrenda bateko ereduren bat bat datorren egiaztatzen du |
| `glob has magic` | Kate batek komodin-metakaraktereak (`*`, `?`, `[`) dituen detektatzen du |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `glob` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import glob

fn :: seleccionar fuentes ridgun (archivos : [String]) => [String]
      seleccionar fuentes ridgun archivos =
        glob filter "test_[a-z]*.rg" archivos
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`glob` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import glob

fn :: es ruta excluida (ruta : String) => Bool
      es ruta excluida ruta =
        glob any match ["*.tmp", "*.bak", "target/*"] ruta
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Ondoz ondoko izarren kolapso automatikoa (`***` $\rightarrow$ `*`) atzera-egite erredundanteak saihesteko eta itxi gabeko `[` kortxeteen kudeaketa segurua.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_glob.rg` suite automatizatuaren bidez.
