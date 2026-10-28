# Kapitel 21: Lib:en `test` — Enhets- och Funktionstestprimitiver (`RG-011`)

## 21.1. Varför finns lib:en `test`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `test`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `test`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: när ett testramverk kräver magiska makron, körtidsreflektion eller en tung extern testkörare slutar testskrivande att kännas omedelbart.

Lib:en **`test`** (`RG-011`) tillhandahåller polymorfa och typspecifika assertioner som skriver ut tydliga `[FAIL]`-diagnostiker med förväntat kontra faktiskt värde och avslutar med kod `1` vid fel.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`TST`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`test`** (`src/main/ridgun/lib/test.rg`) problemet genom fyra kompromisslösa principer:

1. **Deklarera `import test` (eller `import test as alias`) överst i filen**: varje lib definierar sin `module :: test`-namnrymd och i `--strict`-läge anropas flerordsfunktioner alltid med naturliga mellanslag.
2. **Kedja dina datapipelines från vänster till höger med `->`**: skriv `indata steg ett -> steg två -> resultat`, använd `(+ _ _ +)`-sekvensmasker för att packa upp tupler och utelämna `_ =` vid sekventiella satser (eller kasta med `-> ()`).
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `test` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 21.2. Inbyggda artefakter, import och komplett API-katalog för `test`

I `ridgun-libs` är **`test`** en förstklassig **lib** placerad i `src/main/ridgun/lib/test.rg` (domän `TST`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/test.rglib` | Portabel distribution och direkt import med `import test` |
| **Kompilerat arkiv** | `target/test.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libtest.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> Varje lib deklarerar sin egen namnrymd med `module :: test`: skriv bara `import test` (eller `import test as alias`) överst och anropa dess funktioner med naturliga mellanslag (`min funktion x`) och `->`-pipelines (`x min funktion -> resultat`).

### 21.2.1. Översikt över funktionella familjer i `test`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `assert equals / assert eq : A -> A -> String -> ()` | Polymorf likhetsassertion med beskrivande testetikett |
| `assert int equals / assert str eq` | Specialiserade likhetsassertioner för `Int` och `String` |
| `assert true / assert false / assert not` | Booleska invariantassertioner (`True` / `False`) |
| `assert ok : Int -> String -> ()` | Verifierar att en OS-/socket-statuskod är `0` (`OK`) |

### 21.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/test.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/test.rg` (`0` typer, `0` operatorer och `12` funktioner):

| # | Funktion / Signatur (`fn ::`) | Returtyp |
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

## 21.3. Djupdykning i `test`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `test` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test test.rg`.

### 21.3.1. Exempel 1: Huvudflöde i tabellform med `test`

Lägg märke till hur `=`-tecknen och transformationsstegen med `test` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import test
import math

fn :: suite matematicas => ()
      suite matematicas =
        assert equals 12 (math gcd 36 60) "MCD de 36 y 60"
        assert true (math is prime 97) "97 es primo"
        echo "[PASS] suite matematicas"
```

### 21.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `test` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import test

fn :: verificar codigo sistema Int => ()
      verificar codigo sistema rc =
        assert equals rc 0 "operacion de descriptor exitosa"
```

### 21.3.3. Exempel 3: Booleska predikat (`check eq`, `check str eq`, `check true`) och diagnostiska RG-011-assertioner (`assert equals`, `assert str eq`, `assert int equals`)

I detta praktiska exempel undersöker vi grundligt hur `test` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test rg011 assertions => ()
      test rg011 assertions =
        assert equals 4 4 "math int equality"
        assert equals "ok" "ok" "string equality"
        assert equals True True "bool equality"
        assert true (1 < 2) "1 < 2 holds"
        assert false (1 > 2) "1 > 2 is false"
        assert str eq "ridgun" "ridgun" "str eq helper"
        assert int equals 42 42 "int eq helper"
        assert eq 10 10
        assert ok True
        assert not False
        assert true (check eq 2 2) "check eq True"
        assert false (check eq 1 2) "check eq False"
        assert true (check str eq "a" "a") "check str eq True"
        assert false (check str eq "a" "b") "check str eq False"
        assert true (check true True) "check true True"
        assert false (check true False) "check true False"
```

### 21.3.4. Exempel 4: Sammansättning av enhets- och funktionssviter med rena predikat och koncisa assertioner (`assert ok`, `assert not`, `assert eq`)

I detta praktiska exempel undersöker vi grundligt hur `test` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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
        assert true (validar invariantes de dominio 21 "ridgun") "predicado compuesto"
        -- 2. Aserciones anotadas con mensaje diagnóstico (`assert_*`)
        assert int equals (20 + 22) 42 "suma entera exacta"
        assert str eq "rglib" "rglib" "etiqueta de artefacto"
        -- 3. Aserciones concisas sin etiqueta (`assert ok`, `assert not`, `assert eq`)
        assert ok (10 > 5)
        assert not (10 < 5)
        assert eq [1, 2, 3] [1, 2, 3]
        ()
```

---

## 21.4. Under huven: hur `test` är byggd i ren Ridgun (`src/main/ridgun/lib/test.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/test.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 21.4.1. Intern implementation: Non-Exiting Predicate Helpers

Se hur `test.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
module :: test

fn :: check eq A      A        => Bool
      check eq actual expected =  actual == expected

fn :: check str eq String String   => Bool
      check str eq actual expected =  actual == expected

fn :: check true Bool => Bool
      check true cond =  cond
```

### 21.4.2. Intern implementation: RG-011 Message-Annotated Assertions

Se hur `test.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

### 21.4.3. Intern implementation: Concise Label-Free Assertion Helpers

Se hur `test.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: assert ok Bool => ()
      assert ok cond =  assert true cond "assert_ok"

fn :: assert not Bool => ()
      assert not cond =  assert false cond "assert_not"

fn :: assert eq A      A        => ()
      assert eq actual expected =  assert equals actual expected "assert_eq"
```

---

## 21.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `test`

- **Algoritmisk garanti och säkerhet**: Alla 30 automatiserade testsviter i `ridgun-libs` (`src/test/ridgun/test_*.rg`, över 4 000 rader tester) körs med exakt denna lib via `stable test`.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/test.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test test.rg`.

### De 5 Gyllene Reglerna när du programmerar med `test`

1. **Deklarera `import test` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `test`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `test`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `test` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 22** går vi vidare och utforskar lib:en **`posix`** på djupet (Lib:en `posix` — Plattformslager (PAL), Klockor, Signaler och CSPRNG).
