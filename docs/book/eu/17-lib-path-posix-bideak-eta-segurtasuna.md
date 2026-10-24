# 17. kapitulua: `path` lib-a — POSIX Normalizazioa (`path clean`) eta Path Traversal Aurkako Konfinamendua

## 1. Zergatik existitzen da `path` lib-a?

Izan gaitezen zintzoak: bideak `base + "/" + fitxategia` eginez lotzea, `..` segmentuak garbitu eta aurrizkiak baliozkotu gabe, zure web zerbitzarian norbaitek `../../etc/passwd` eskatzeko atea zabalik uztea bezala da.

**`path`** lib-ak POSIX normalizazio lexikoa (`path clean`, Go-ren `filepath.Clean` estiloan), lotura segurua (`path join`), deskonposizioa (`dirname`, `basename`, `stem`, `ext`, `replace ext`) eta direktorio-ihesen aurkako **`path is safe subpath`** (`VUL-INJ-001`) segurtasun-predikatua inplementatzen ditu.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`path`** lehen mailako **lib** bat da, `src/main/ridgun/lib/path.rg` bidean kokatua (`PATH` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/path.rglib` | Banaketa eta inportazio zuzena `import path` bidez |
| **Fitxategi konpilatua** | `target/path.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libpath.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import path` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `path` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `path clean / path join / path join list` | `//`, `.` eta `..` lexikoki kolapsatzen ditu eta bide-segmentuak lotzen ditu |
| `path dirname / path basename / path split` | Bide bat guraso-direktorioan eta azken fitxategi-izenean zatitzen du |
| `path ext / path stem / path replace ext` | Luzapena erauzi edo aldatzen du (`.bashrc` erro gisa eta `""` luzapen gisa tratatuz) |
| `path is safe subpath : String -> String -> Bool` | `rel` `base_dir` barruan zorrotz geratzen dela eta NUL byterik ez duela egiaztatzen du |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `path` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import path

fn :: resolver archivo estatico (raiz : String) (peticion : String) => (Bool, String)
      resolver archivo estatico raiz peticion =
        seguro = path is safe subpath raiz peticion
        ruta   = path join raiz peticion
        (seguro, ruta)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`path` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import path

fn :: cambiar salida a objeto (fuente : String) => (String, String, String)
      cambiar salida a objeto fuente =
        dir = path dirname fuente
        nom = path stem fuente
        obj = path replace ext (path clean fuente) ".rglib"
        (dir, nom, obj)
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: `path is safe subpath`-ek bide absolutuak, NUL byteak eta erro-direktoriotik zein `/srv/www-secret` bezalako aurrizki anaietatik ihes egiten saiatzen den edozein `..` sekuentzia ukatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_path.rg` suite automatizatuaren bidez.
