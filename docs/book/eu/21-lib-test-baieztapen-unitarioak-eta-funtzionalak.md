# 21. kapitulua: `test` lib-a — Baieztapen Unitario eta Funtzionalen Primitibak (`RG-011`)

## 21.1. Zergatik existitzen da `test` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `test` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `test`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: test framework batek makro magikoak, exekuzio-garaiko isla edo kanpoko runner astun bat eskatzen dituenean, probak idazteak berehalakoa izateari uzten dio.

**`test`** lib-ak (`RG-011`) baieztapen huts, polimorfiko eta motaren araberakoak eskaintzen ditu, espero zen eta lortutako balioekin `[FAIL]` diagnostiko argiak igorriz eta irteera-kode `1`-ekin amaituz.

Ekosistema tradizional batean, **`TST`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`test`** lib-ak (`src/main/ridgun/lib/test.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Funtzio osoak eta kontratu esplizituak (`=>`)**: `test`-eko funtzio bakar batek ere ez du ezkutuko salbuespenik jaurtitzen, ezta `null` erabiltzen ere. Muga-kasu orok dokumentatutako balio bat edo batura-mota aljebraiko bat (`Option`, `Result`) itzultzen du.
2. **Zero C kode eta zero `libc`**: `test`-eko kode guztia zuzenean ELF64 makina-kode natibora konpilatzen da, `ridgunc`-ek egiaztatuta.
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `test`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 21.2. Artefaktu natiboak, inportazioa eta `test` APIaren katalogo osoa

`ridgun-libs`-en, **`test`** lehen mailako **lib** bat da, `src/main/ridgun/lib/test.rg` bidean kokatua (`TST` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/test.rglib` | Banaketa eta inportazio zuzena `import test` bidez |
| **Fitxategi konpilatua** | `target/test.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libtest.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import test` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

### 21.2.1. `test`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `assert equals / assert eq : A -> A -> String -> ()` | Berdintasun-baieztapen polimorfikoa proba-kasuaren etiketa deskribatzailearekin |
| `assert int equals / assert str eq` | `Int` eta `String`-entzako berdintasun-baieztapen espezializatuak |
| `assert true / assert false / assert not` | Aldaezin boolearren baieztapenak (`True` / `False`) |
| `assert ok : Int -> String -> ()` | Sistema edo socket baten egoera-kodea `0` (`OK`) dela egiaztatzen du |

### 21.2.2. `src/main/ridgun/lib/test.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/test.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`0` mota, `0` eragile eta `12` funtzio):

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
|---|---|---|
| `1` | `fn :: fail test String` | `()` |
| `2` | `fn :: check eq A A` | `Bool` |
| `3` | `fn :: check str eq String String` | `Bool` |
| `4` | `fn :: check true Bool` | `Bool` |
| `5` | `fn :: assert true Bool String` | `()` |
| `6` | `fn :: assert false Bool String` | `()` |
| `7` | `fn :: assert equals A A String` | `()` |
| `8` | `fn :: assert str eq String String String` | `()` |
| `9` | `fn :: assert int equals Int Int String` | `()` |
| `10` | `fn :: assert ok Bool` | `()` |
| `11` | `fn :: assert not Bool` | `()` |
| `12` | `fn :: assert eq A A` | `()` |

---

## 21.3. `test` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `test` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test test.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 21.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `test` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `test` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import test
import math

fn :: suite matematicas () => ()
      suite matematicas =
        _ = assert int equals 12 (math gcd 36 60) "MCD de 36 y 60"
        _ = assert true (math is prime 97) "97 es primo"
        echo "[PASS] suite matematicas"
```

### 21.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`test` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import test

fn :: verificar codigo sistema (rc : Int) => ()
      verificar codigo sistema rc =
        assert ok rc "operacion de descriptor exitosa"
```

### 21.3.3. 3. adibidea: Predikatu boolearrak (`check eq`, `check str eq`, `check true`) eta diagnostikodun RG-011 asertzioak (`assert equals`, `assert str eq`, `assert int equals`)

Adibide praktiko honetan `test` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test rg011 assertions => ()
      test rg011 assertions =
        _ = assert equals 4 4 "math int equality"
        _ = assert equals "ok" "ok" "string equality"
        _ = assert equals True True "bool equality"
        _ = assert true (1 < 2) "1 < 2 holds"
        _ = assert false (1 > 2) "1 > 2 is false"
        _ = assert str eq "ridgun" "ridgun" "str eq helper"
        _ = assert int equals 42 42 "int eq helper"
        _ = assert eq 10 10
        _ = assert ok True
        _ = assert not False
        _ = assert true (check eq 2 2) "check eq True"
        _ = assert false (check eq 1 2) "check eq False"
        _ = assert true (check str eq "a" "a") "check str eq True"
        _ = assert false (check str eq "a" "b") "check str eq False"
        _ = assert true (check true True) "check true True"
        assert false (check true False) "check true False"
```

### 21.3.4. 4. adibidea: Suite unitario eta funtzionalen konposizioa predikatu hutsak eta asertzio laburrak (`assert ok`, `assert not`, `assert eq`) uztartuz

Adibide praktiko honetan `test` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
import test

fn :: validar invariantes de dominio (x : Int) (nombre : String) => Bool
      validar invariantes de dominio x nombre =
        ok_num = check eq (x * 2) (x + x)
        ok_str = check str eq nombre "ridgun"
        check true (ok_num and ok_str)

fn :: ejecutar suite de ejemplo => ()
      ejecutar suite de ejemplo =
        -- 1. Predicados puros sin salida del proceso (`check_*`)
        _ = assert true (validar invariantes de dominio 21 "ridgun") "predicado compuesto"
        -- 2. Aserciones anotadas con mensaje diagnóstico (`assert_*`)
        _ = assert int equals (20 + 22) 42 "suma entera exacta"
        _ = assert str eq "rglib" "rglib" "etiqueta de artefacto"
        -- 3. Aserciones concisas sin etiqueta (`assert ok`, `assert not`, `assert eq`)
        _ = assert ok (10 > 5)
        _ = assert not (10 < 5)
        _ = assert eq [1, 2, 3] [1, 2, 3]
        ()
```

---

## 21.4. Kaputaren azpian: nola dagoen eraikia `test` Ridgun hutsean (`src/main/ridgun/lib/test.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/test.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 21.4.1. Barne-inplementazioa: Non-Exiting Predicate Helpers

Ikusi nola `test.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: check eq A      A        => Bool
      check eq actual expected =  actual == expected

fn :: check str eq String String   => Bool
      check str eq actual expected =  actual == expected

fn :: check true Bool => Bool
      check true cond =  cond
```

### 21.4.2. Barne-inplementazioa: RG-011 Message-Annotated Assertions

Ikusi nola `test.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: assert true Bool String => ()
      assert true cond label  =
        | cond      = ()
        | otherwise = fail test "assert_true failed: {label}"

fn :: assert false Bool String => ()
      assert false cond label  =
        | not cond  = ()
        | otherwise = fail test "assert_false failed: {label}"

fn :: assert equals A      A        String => ()
      assert equals actual expected label  =
        | actual == expected = ()
        | otherwise          = fail test "assert_equals failed: {label}"

fn :: assert str eq String String String => ()
      assert str eq actual expected label =
        | actual == expected = ()
        | otherwise          = fail test "assert_str_eq failed ({label}): got '{actual}', expected '{expected}'"

fn :: assert int equals Int Int String => ()
      assert int equals actual expected label =
        | actual == expected = ()
        | otherwise          = fail test "assert_int_equals failed ({label}): got {actual}, expected {expected}"
```

### 21.4.3. Barne-inplementazioa: Concise Label-Free Assertion Helpers

Ikusi nola `test.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: assert ok Bool => ()
      assert ok cond =  assert true cond "assert_ok"

fn :: assert not Bool => ()
      assert not cond =  assert false cond "assert_not"

fn :: assert eq A      A        => ()
      assert eq actual expected =  assert equals actual expected "assert_eq"
```

---

## 21.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `test`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: `ridgun-libs`-eko 30 proba-suiteak (`src/test/ridgun/test_*.rg`, 4 000 lerro baino gehiago) lib honekin exekutatzen dira `stable test` bidez.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/test.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test test.rg` suite automatizatuaren bidez.

### `test`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import test` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `test`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `test`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `test` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**22. kapituluan** **`posix`** lib-a sakonki esploratuko dugu (`posix` lib-a — Plataforma Abstrakzio Geruza (PAL), Erlojuak, Seinaleak eta CSPRNG).
