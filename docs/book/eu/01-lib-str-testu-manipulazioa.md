# 01. kapitulua: `str` lib-a — Testu-manipulazioa, Bilaketa eta Formatu Taularatua

## 1. Zergatik existitzen da `str` lib-a?

Izan gaitezen zintzoak: C lengoaian `strtok` eta `strncpy` bidez kateak manipulatzea buffer-gainezkatzeen eta `NULL` erakusleen arteko mina-zelai batean ibiltzea da, eta beste lengoaia batzuetan hiru pakete inportatzen amaitzen duzu zutabeak lerrokatzeko.

**`str`** lib-ak kateak bilatu, moztu, zatitu, elkartu, letra larri/xeheetara bihurtu, $O(\log N)$ bikoizketa bitarrez errepikatu eta betetzeko primitiba huts eta aldaezin guztiak eskaintzen ditu.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`str`** lehen mailako **lib** bat da, `src/main/ridgun/lib/str.rg` bidean kokatua (`STR` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/str.rglib` | Banaketa eta inportazio zuzena `import str` bidez |
| **Fitxategi konpilatua** | `target/str.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libstr.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import str` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `str` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `str index of : String -> String -> Int` | Azpikatearen lehen indizea (`-1` ez badago / `0` hutsa bada) |
| `str contains / str starts with / str ends with` | Azpikate, aurrizki eta atzizkien `Bool` predikatuak |
| `str trim / str trim left / str trim right` | ASCII zuriuneak kentzen ditu (` `, `\t`, `\n`, `\r`) |
| `str split / str lines / str words / str join` | `[String]` zerrendan zatitu eta bereizle batekin elkartzen ditu |
| `str replace / str to upper / str to lower` | Gainjartzerik gabeko ordezkapena eta ASCII letra larri/xeheen bihurketa |
| `str repeat / str pad left / str pad right` | $O(\log N)$ errepikapena eta zabaleraardatzeko zutabe-betegarria |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `str` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import str

fn :: normalizar cabecera (raw : String) => String
      normalizar cabecera raw =
        limpia = str to lower (str trim raw)
        partes = str words limpia
        slug   = str join partes "-"
        str pad right slug 24 "."
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`str` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import str

fn :: extraer dominio (correo : String) => String
      extraer dominio correo =
        pos = str index of correo "@"
        | pos < 0   = "sin-dominio"
        | otherwise =
          partes = str split correo "@"
          str replace (str to lower correo) "@" " en "
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: $O(\log N)$ errepikapena kateen bikoizketaren bidez, predikatu seguruak orratz hutsen aurrean eta zero mutazio bertan.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_str.rg` suite automatizatuaren bidez.
