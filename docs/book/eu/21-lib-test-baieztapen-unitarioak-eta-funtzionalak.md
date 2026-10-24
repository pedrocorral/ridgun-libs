# 21. kapitulua: `test` lib-a — Baieztapen Unitario eta Funtzionalen Primitibak (`RG-011`)

## 1. Zergatik existitzen da `test` lib-a?

Izan gaitezen zintzoak: test framework batek makro magikoak, exekuzio-garaiko isla edo kanpoko runner astun bat eskatzen dituenean, probak idazteak berehalakoa izateari uzten dio.

**`test`** lib-ak (`RG-011`) baieztapen huts, polimorfiko eta motaren araberakoak eskaintzen ditu, espero zen eta lortutako balioekin `[FAIL]` diagnostiko argiak igorriz eta irteera-kode `1`-ekin amaituz.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`test`** lehen mailako **lib** bat da, `src/main/ridgun/lib/test.rg` bidean kokatua (`TST` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/test.rglib` | Banaketa eta inportazio zuzena `import test` bidez |
| **Fitxategi konpilatua** | `target/test.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libtest.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import test` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `test` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `assert equals / assert eq : A -> A -> String -> ()` | Berdintasun-baieztapen polimorfikoa proba-kasuaren etiketa deskribatzailearekin |
| `assert int equals / assert str eq` | `Int` eta `String`-entzako berdintasun-baieztapen espezializatuak |
| `assert true / assert false / assert not` | Aldaezin boolearren baieztapenak (`True` / `False`) |
| `assert ok : Int -> String -> ()` | Sistema edo socket baten egoera-kodea `0` (`OK`) dela egiaztatzen du |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `test` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import test
import math

fn :: suite matematicas () => ()
      suite matematicas =
        _ = assert int equals 12 (math gcd 36 60) "MCD de 36 y 60"
        _ = assert true (math is prime 97) "97 es primo"
        echo "[PASS] suite matematicas"
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`test` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import test

fn :: verificar codigo sistema (rc : Int) => ()
      verificar codigo sistema rc =
        assert ok rc "operacion de descriptor exitosa"
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: `ridgun-libs`-eko 30 proba-suiteak (`src/test/ridgun/test_*.rg`, 4 000 lerro baino gehiago) lib honekin exekutatzen dira `stable test` bidez.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_test.rg` suite automatizatuaren bidez.
