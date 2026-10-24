# 11. kapitulua: `regex` lib-a — $O(N \cdot M)$ Denbora Linealeko Thompson NFA Adierazpen Erregularren Motorra

## 1. Zergatik existitzen da `regex` lib-a?

Izan gaitezen zintzoak: *backtracking* bidezko adierazpen erregularren motorrek erorketa global ospetsuak eragin dituzte (Cloudflare edo StackOverflow-n bezala) `(a+)+b` bezalako eredu batek hogeita hamar `a` jarraian jasotzen dituenean eta $O(2^N)$ denbora esponentzialean sartzen denean.

**`regex`** lib-ak zure adierazpen erregularrak (`.`, `*`, `+`, `?`, `|`, `()`, `[a-z]`, `[^...]`, `^`, `$`, `\d`, `\w`, `\s`) **Thompsonen automata finitu ez-determinista (NFA)** batera konpilatzen ditu eta egoera-multzoa urratsez urrats aurreratzen du **$O(N \cdot M)$** denbora lineal zorrotzean, **ReDoS erasoak matematikoki ezinezko** bihurtuz.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`regex`** lehen mailako **lib** bat da, `src/main/ridgun/lib/regex.rg` bidean kokatua (`REGEX` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/regex.rglib` | Banaketa eta inportazio zuzena `import regex` bidez |
| **Fitxategi konpilatua** | `target/regex.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libregex.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import regex` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `regex` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `regex match / regex is match` | Kate osoaren bat-etortzea eta azpikate-bilaketa $O(N \cdot M)$ denbora linealean |
| `regex find / regex find all` | Bat datorren lehen azpikatea edo gainjartzerik gabeko guztiak erauzten ditu |
| `regex replace / regex replace all` | Adierazpen erregularraren lehen bat-etortzea edo guztiak ordezkatzen ditu |
| `regex split / regex escape` | Testua regex bereizle baten arabera zatitzen du eta metakaraktereak ihes egiten ditu |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `regex` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import regex

fn :: extraer codigos postales (texto : String) => [String]
      extraer codigos postales texto =
        regex find all "\\d+" texto
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`regex` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import regex

fn :: censurar telefonos (comentario : String) => (Bool, String)
      censurar telefonos comentario =
        tiene = regex is match "\\d+-\\d+" comentario
        limpio = regex replace all "\\d+-\\d+" comentario "[TELEFONO]"
        (tiene, limpio)
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: NFA egoera-multzoaren simulazioa pilaren errekurtsio kontrolatu gaberik gabe eta $O(N \cdot M)$ denbora bermatua baita `(a+)+b` eredu patologikoen aurrean ere.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_regex.rg` suite automatizatuaren bidez.
