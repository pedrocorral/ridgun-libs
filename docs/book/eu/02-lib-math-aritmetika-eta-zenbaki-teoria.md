# 02. kapitulua: `math` lib-a — Aritmetika Segurua, Zenbaki-teoria eta Estatistika

## 1. Zergatik existitzen da `math` lib-a?

Izan gaitezen zintzoak: ekoizpenean ustekabeko zeroz zatitze batek edo C zein Javan `%` eragileak hondar negatiboak itzultzeak aitortzea gustatzen zaiguna baino zerbitzu gehiago bota ditu behera.

**`math`** lib-ak `d == 0`-ren aurkako zatiketa osoak (`div ceil`, `div floor`, `div euclid`, `mod euclid`), $O(\log E)$ berreketa eta alderantzizko modularra, erro eta logaritmo oso zehatzak, konbinatoria eta `clamp x between lo and hi` mixfix eragilea eskaintzen ditu.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`math`** lehen mailako **lib** bat da, `src/main/ridgun/lib/math.rg` bidean kokatua (`MATH` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/math.rglib` | Banaketa eta inportazio zuzena `import math` bidez |
| **Fitxategi konpilatua** | `target/math.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libmath.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import math` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `math` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `math abs / math sign / math min / math max` | Magnitude absolutua, zeinua (`-1, 0, 1`) eta muturrak |
| `clamp x between lo and hi` | `x` balioa `[lo, hi]` tartera mugatzen duen mixfix eragilea (`op ::`) |
| `math div ceil / math div floor / math div euclid / math mod euclid` | Zeroz zatitzearen aurkako biribilketa segurua eta hondar euklidear ez-negatiboa |
| `math pow / math isqrt / math ilog2 / math ilog10` | $O(\log E)$ berreketa, Newtonen erro karratu osoa eta logaritmo osoak |
| `math gcd / math lcm / math mod pow / math mod inv / math is prime` | Euklidesen ZKH/MKT, aritmetika modularra eta $6k \pm 1$ lehentasun-proba |
| `math sum / math mean floor / math median floor / math variance floor` | Gainezkatzerik gabeko konbinatoria (`nCr`) eta zerrenden estatistika osoa |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `math` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import math

fn :: verificar clave modular (base : Int) (primo : Int) => (Int, Int, Bool)
      verificar clave modular base primo =
        es_p = math is prime primo
        pot  = math mod pow base (primo - 1) primo
        inv  = math mod inv base primo
        (pot, inv, es_p)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`math` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import math

fn :: calcular paginas y cuota (items : Int) (por_pag : Int) (uso : Int) => (Int, Int)
      calcular paginas y cuota items por_pag uso =
        pags  = math div ceil items por_pag
        cuota = clamp uso between 0 and 100
        (pags, cuota)
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Funtzio osoak (`0` itzultzen dute zatitzailea `<= 0` denean `SIGFPE`-rekin abortatu beharrean), koma higikor ez-zehatzik gabe.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_math.rg` suite automatizatuaren bidez.
