# Kapitel 02: Lib:en `math` — Säker Aritmetik, Talteori och Statistik

## 1. Varför finns lib:en `math`?

Låt oss vara ärliga: en oväntad division med noll i produktion eller `%`-operatorn som returnerar negativa rester i C eller Java har sänkt fler tjänster än vi vill erkänna.

Lib:en **`math`** erbjuder totala divisioner säkra mot `d == 0` (`div ceil`, `div floor`, `div euclid`, `mod euclid`), modulär exponentiering och invers i $O(\log E)$, heltalsrötter och logaritmer, kombinatorik samt mixfix-operatorn `clamp x between lo and hi`.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`math`** en förstklassig **lib** placerad i `src/main/ridgun/lib/math.rg` (domän `MATH`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/math.rglib` | Portabel distribution och direkt import med `import math` |
| **Kompilerat arkiv** | `target/math.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libmath.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import math` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `math`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `math abs / math sign / math min / math max` | Absolutbelopp, tecken (`-1, 0, 1`) och extremvärden |
| `clamp x between lo and hi` | Mixfix-operator (`op ::`) som begränsar `x` till intervallet `[lo, hi]` |
| `math div ceil / math div floor / math div euclid / math mod euclid` | Nolldivisionssäker avrundning och icke-negativ euklidisk rest |
| `math pow / math isqrt / math ilog2 / math ilog10` | $O(\log E)$-potens, Newtons heltalskvadratrot och heltalslogaritmer |
| `math gcd / math lcm / math mod pow / math mod inv / math is prime` | Euklidisk SGD/MGM, modulär aritmetik och $6k \pm 1$-primtalstest |
| `math sum / math mean floor / math median floor / math variance floor` | Spillsäker kombinatorik (`nCr`) och heltalsstatistik över listor |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `math`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import math

fn :: verificar clave modular (base : Int) (primo : Int) => (Int, Int, Bool)
      verificar clave modular base primo =
        es_p = math is prime primo
        pot  = math mod pow base (primo - 1) primo
        inv  = math mod inv base primo
        (pot, inv, es_p)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `math` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import math

fn :: calcular paginas y cuota (items : Int) (por_pag : Int) (uso : Int) => (Int, Int)
      calcular paginas y cuota items por_pag uso =
        pags  = math div ceil items por_pag
        cuota = clamp uso between 0 and 100
        (pags, cuota)
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Totala funktioner (returnerar `0` när divisorn är `<= 0` istället för att krascha med `SIGFPE`), helt utan flyttalsavrundningsfel.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_math.rg`.
