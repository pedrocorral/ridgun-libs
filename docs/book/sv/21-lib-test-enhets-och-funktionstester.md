# Kapitel 21: Lib:en `test` — Enhets- och Funktionstestprimitiver (`RG-011`)

## 1. Varför finns lib:en `test`?

Låt oss vara ärliga: när ett testramverk kräver magiska makron, körtidsreflektion eller en tung extern testkörare slutar testskrivande att kännas omedelbart.

Lib:en **`test`** (`RG-011`) tillhandahåller polymorfa och typspecifika assertioner som skriver ut tydliga `[FAIL]`-diagnostiker med förväntat kontra faktiskt värde och avslutar med kod `1` vid fel.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`test`** en förstklassig **lib** placerad i `src/main/ridgun/lib/test.rg` (domän `TST`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/test.rglib` | Portabel distribution och direkt import med `import test` |
| **Kompilerat arkiv** | `target/test.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libtest.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import test` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `test`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `assert equals / assert eq : A -> A -> String -> ()` | Polymorf likhetsassertion med beskrivande testetikett |
| `assert int equals / assert str eq` | Specialiserade likhetsassertioner för `Int` och `String` |
| `assert true / assert false / assert not` | Booleska invariantassertioner (`True` / `False`) |
| `assert ok : Int -> String -> ()` | Verifierar att en OS-/socket-statuskod är `0` (`OK`) |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `test`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import test
import math

fn :: suite matematicas () => ()
      suite matematicas =
        _ = assert int equals 12 (math gcd 36 60) "MCD de 36 y 60"
        _ = assert true (math is prime 97) "97 es primo"
        echo "[PASS] suite matematicas"
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `test` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import test

fn :: verificar codigo sistema (rc : Int) => ()
      verificar codigo sistema rc =
        assert ok rc "operacion de descriptor exitosa"
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Alla 30 automatiserade testsviter i `ridgun-libs` (`src/test/ridgun/test_*.rg`, över 4 000 rader tester) körs med exakt denna lib via `stable test`.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_test.rg`.
