# 15. kapitulua: `fmt` lib-a — 2D Formateatzaile Taularatu Kanonikoa eta 9 Formatuko Sintaxi-nabarmentzailea

## 1. Zergatik existitzen da `fmt` lib-a?

Izan gaitezen zintzoak: Ridgun kodearen edertasuna ezin hobeto lerrokatutako zutabe taularatuetan datza (`::`, `=`, `|`, `->`, `--`), baina zuriuneak eskuz lerrokatzea edo kode koloreztatua terminal, HTML eta LaTeXerako esportatzea neketsua da.

**`fmt`** lib-a Ridgunen 2D formateatze taularatuko eta nabarmentze lexikoko motor ofiziala da: `fn ::` sinadurak, ekuazioak, `|` zainak eta `--` iruzkinak lerrokatzen ditu, eta **9 irteera-formatutara** esportatzen du (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`).

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`fmt`** lehen mailako **lib** bat da, `src/main/ridgun/lib/fmt.rg` bidean kokatua (`FMT` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/fmt.rglib` | Banaketa eta inportazio zuzena `import fmt` bidez |
| **Fitxategi konpilatua** | `target/fmt.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libfmt.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import fmt` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `fmt` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `fmt source / fmt source with` | Ridgun iturburu-kodea formateatzen du 2D zutabe-lerrokatze taularatu kanonikoarekin |
| `fmt check` | `True` itzultzen du kodeak dagoeneko `fmt source` diseinu kanonikoa betetzen badu |
| `fmt render / fmt render with` | Kodea formateatu eta koloreztatzen du 9 `FmtTarget` irteera-formatuetako edozeinetara |
| `fmt tokenize line` | Lerro bat `TokKeyword`, `TokType`, `TokOperator`, `TokString`, `TokNumber`, `TokComment`-etan tokenizatzen du |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `fmt` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import fmt

fn :: formatear y verificar (codigo : String) => (String, Bool)
      formatear y verificar codigo =
        limpio = fmt source codigo
        es_ok  = fmt check limpio
        (limpio, es_ok)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`fmt` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import fmt

fn :: exportar bloque html (codigo : String) => String
      exportar bloque html codigo =
        fmt render codigo FmtHtmlCss
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Idempotentzia zorrotza (`fmt source (fmt source s) == fmt source s`) eta token semantikoen % 100eko kontserbazioa.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_fmt.rg` suite automatizatuaren bidez.
