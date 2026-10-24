# 23. kapitulua: `io` lib-a — `IoResult` Errore Tipatuak, `with timeout` bidezko S/I eta Prozesuak

## 1. Zergatik existitzen da `io` lib-a?

Izan gaitezen zintzoak: epemugarik (`timeout`) gabeko `read()` dei bat edo ume-azpiprozesu bat zintzilikatutako baliabide bakar batek zure zerbitzariko langile guztiak agortzeko gonbidapena da.

**`io`** lib-ak sistemaren eragiketa bakoitza ADT esplizituekin modelatzen du (`IoError`, `IoResult[A]`), blokeatzailea ez den `ppoll` Ridgunen `with timeout wait_ms do` kuota lexikoekin uztartzen du eta `read fd ... timeout` zein `write fd ... timeout` mixfix eragileak eskaintzen ditu.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`io`** lehen mailako **lib** bat da, `src/main/ridgun/lib/io.rg` bidean kokatua (`IO` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/io.rglib` | Banaketa eta inportazio zuzena `import io` bidez |
| **Fitxategi konpilatua** | `target/io.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libio.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import io` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `io` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `type IoError / type IoResult[A]` | `IoNotFound | IoPermission | IoTimeout | IoRefused | IoReset | IoEOF | IoInvalid | IoSysError` |
| `io read with timeout / io write with timeout` | `wait_ms` bidez mugatutako deskribatzaileen irakurketa/idazketa ez-blokeatzailea |
| `read fd N max M timeout T / write fd N data S timeout T` | Epemugadun deskribatzaileen S/I-rako mixfix eragile ergonomikoak (`op ::`) |
| `io read file / io write file / io read lines` | `IoResult` itzultzen duten fitxategi eta lerro-korronteen funtzio seguruak |
| `exec with timeout : String -> Int -> IoResult[ProcStatus]` | Kanpoko komando bat exekutatzen du `with timeout` kuota lexiko batez mugatuta |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `io` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import io

fn :: leer peticion segura (fd : Int) => String
      leer peticion segura fd =
        res = read fd fd max 4096 timeout 250
        io unwrap or res ""
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`io` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import io

fn :: describir fallo () => String
      describir fallo =
        format io error (IoTimeout "read" 250)
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: `wait_ms` kuotarekin `io` bidez exekutatutako inongo irakurketa, idazketa edo komandok ezin du deitzen duen haria edo aktorea mugagabe blokeatu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_io.rg` suite automatizatuaren bidez.
