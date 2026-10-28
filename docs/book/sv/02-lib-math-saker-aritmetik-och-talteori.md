# Kapitel 02: Lib:en `math` — Säker Aritmetik, Talteori och Statistik

## 02.1. Varför finns lib:en `math`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `math`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `math`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: en oväntad division med noll i produktion eller `%`-operatorn som returnerar negativa rester i C eller Java har sänkt fler tjänster än vi vill erkänna.

Lib:en **`math`** erbjuder totala divisioner säkra mot `d == 0` (`div ceil`, `div floor`, `div euclid`, `mod euclid`), modulär exponentiering och invers i $O(\log E)$, heltalsrötter och logaritmer, kombinatorik samt mixfix-operatorn `clamp x between lo and hi`.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`MATH`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`math`** (`src/main/ridgun/lib/math.rg`) problemet genom fyra kompromisslösa principer:

1. **Deklarera `import math` (eller `import math as alias`) överst i filen**: varje lib definierar sin `module :: math`-namnrymd och i `--strict`-läge anropas flerordsfunktioner alltid med naturliga mellanslag.
2. **Kedja dina datapipelines från vänster till höger med `->`**: skriv `indata steg ett -> steg två -> resultat`, använd `(+ _ _ +)`-sekvensmasker för att packa upp tupler och utelämna `_ =` vid sekventiella satser (eller kasta med `-> ()`).
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `math` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 02.2. Inbyggda artefakter, import och komplett API-katalog för `math`

I `ridgun-libs` är **`math`** en förstklassig **lib** placerad i `src/main/ridgun/lib/math.rg` (domän `MATH`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/math.rglib` | Portabel distribution och direkt import med `import math` |
| **Kompilerat arkiv** | `target/math.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libmath.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> Varje lib deklarerar sin egen namnrymd med `module :: math`: skriv bara `import math` (eller `import math as alias`) överst och anropa dess funktioner med naturliga mellanslag (`min funktion x`) och `->`-pipelines (`x min funktion -> resultat`).

### 02.2.1. Översikt över funktionella familjer i `math`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `math abs / math sign / math min / math max` | Absolutbelopp, tecken (`-1, 0, 1`) och extremvärden |
| `clamp x between lo and hi` | Mixfix-operator (`op ::`) som begränsar `x` till intervallet `[lo, hi]` |
| `math div ceil / math div floor / math div euclid / math mod euclid` | Nolldivisionssäker avrundning och icke-negativ euklidisk rest |
| `math pow / math isqrt / math ilog2 / math ilog10` | $O(\log E)$-potens, Newtons heltalskvadratrot och heltalslogaritmer |
| `math gcd / math lcm / math mod pow / math mod inv / math is prime` | Euklidisk SGD/MGM, modulär aritmetik och $6k \pm 1$-primtalstest |
| `math sum / math mean floor / math median floor / math variance floor` | Spillsäker kombinatorik (`nCr`) och heltalsstatistik över listor |

### 02.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/math.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/math.rg` (`0` typer, `1` operatorer och `56` funktioner):

**Mixfix-operatorer (`op ::`) i `math`:**

```ridgun
op :: clamp Int between Int and Int => Int
```

| # | Funktion / Signatur (`fn ::`) | Returtyp |
|---|---|---|
| `1` | `fn :: math abs Int` | `Int` |
| `2` | `fn :: math sign Int` | `Int` |
| `3` | `fn :: math min Int Int` | `Int` |
| `4` | `fn :: math max Int Int` | `Int` |
| `5` | `fn :: math clamp Int Int Int` | `Int` |
| `6` | `fn :: math is even Int` | `Bool` |
| `7` | `fn :: math is odd Int` | `Bool` |
| `8` | `fn :: m fix mod Int Int` | `Int` |
| `9` | `fn :: math mod euclid Int Int` | `Int` |
| `10` | `fn :: math div euclid Int Int` | `Int` |
| `11` | `fn :: m adjust floor Int Int Int Int` | `Int` |
| `12` | `fn :: math div floor Int Int` | `Int` |
| `13` | `fn :: m adjust ceil Int Int Int Int` | `Int` |
| `14` | `fn :: math div ceil Int Int` | `Int` |
| `15` | `fn :: m pow loop Int Int Int` | `Int` |
| `16` | `fn :: math pow Int Int` | `Int` |
| `17` | `fn :: m isqrt step Int Int Int` | `Int` |
| `18` | `fn :: m isqrt loop Int Int` | `Int` |
| `19` | `fn :: math isqrt Int` | `Int` |
| `20` | `fn :: m ilog2 loop Int Int` | `Int` |
| `21` | `fn :: math ilog2 Int` | `Int` |
| `22` | `fn :: m ilog10 loop Int Int` | `Int` |
| `23` | `fn :: math ilog10 Int` | `Int` |
| `24` | `fn :: m next pow2 loop Int Int` | `Int` |
| `25` | `fn :: math next power of two Int` | `Int` |
| `26` | `fn :: math is power of two Int` | `Bool` |
| `27` | `fn :: m gcd loop Int Int` | `Int` |
| `28` | `fn :: math gcd Int Int` | `Int` |
| `29` | `fn :: math lcm Int Int` | `Int` |
| `30` | `fn :: m mod pow loop Int Int Int Int` | `Int` |
| `31` | `fn :: math mod pow Int Int Int` | `Int` |
| `32` | `fn :: m egcd loop Int Int Int Int` | `Int Int` |
| `33` | `fn :: m finish mod inv (Int Int) Int` | `Int` |
| `34` | `fn :: math mod inv Int Int` | `Int` |
| `35` | `fn :: m prime loop Int Int` | `Bool` |
| `36` | `fn :: math is prime Int` | `Bool` |
| `37` | `fn :: m fact loop Int Int` | `Int` |
| `38` | `fn :: math factorial Int` | `Int` |
| `39` | `fn :: m ncr loop Int Int Int Int` | `Int` |
| `40` | `fn :: math ncr Int Int` | `Int` |
| `41` | `fn :: m fib loop Int Int Int` | `Int` |
| `42` | `fn :: math fibonacci Int` | `Int` |
| `43` | `fn :: m list len [Int]` | `Int` |
| `44` | `fn :: m nth int [Int] Int` | `Int` |
| `45` | `fn :: math sum [Int]` | `Int` |
| `46` | `fn :: math product [Int]` | `Int` |
| `47` | `fn :: m mean len [Int] Int` | `Int` |
| `48` | `fn :: math mean [Int]` | `Int` |
| `49` | `fn :: m min loop [Int] Int` | `Int` |
| `50` | `fn :: math min list [Int]` | `Int` |
| `51` | `fn :: m max loop [Int] Int` | `Int` |
| `52` | `fn :: math max list [Int]` | `Int` |
| `53` | `fn :: m insert sorted Int [Int]` | `[Int]` |
| `54` | `fn :: m sort ints [Int]` | `[Int]` |
| `55` | `fn :: m median sorted [Int] Int Int` | `Int` |
| `56` | `fn :: math median [Int]` | `Int` |

---

## 02.3. Djupdykning i `math`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `math` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test math.rg`.

### 02.3.1. Exempel 1: Huvudflöde i tabellform med `math`

Lägg märke till hur `=`-tecknen och transformationsstegen med `math` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import math

fn :: verificar clave modular Int Int => Int Int Bool
      verificar clave modular base primo =
        primo math is prime -> es_p
        math mod pow base (primo - 1) primo -> pot
        math mod inv base primo -> inv
        (pot, inv, es_p)
```

### 02.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `math` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import math

fn :: calcular paginas y cuota Int Int Int => Int Int
      calcular paginas y cuota items por_pag uso =
        math div ceil items por_pag -> pags
        clamp uso between 0 and 100 -> cuota
        (pags, cuota)
```

### 02.3.3. Exempel 3: Gränser (`abs`, `sign`, `min`, `max`), mixfix-operatorn `clamp ... between ... and ...` och nolldivisionssäkra divisioner (`div ceil`, `div floor`, `div euclid`, `mod euclid`)

I detta praktiska exempel undersöker vi grundligt hur `math` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test math bounds and division => ()
      test math bounds and division =
        assert int equals (math abs (0 - 42)) 42 "math abs negative"
        assert int equals (math abs 42) 42 "math abs positive"
        assert int equals (math abs 0) 0 "math abs zero"
        assert int equals (math sign (0 - 99)) (0 - 1) "math sign negative"
        assert int equals (math sign 0) 0 "math sign zero"
        assert int equals (math sign 99) 1 "math sign positive"
        assert int equals (math min 10 (0 - 5)) (0 - 5) "math min"
        assert int equals (math max 10 (0 - 5)) 10 "math max"
        assert int equals (math clamp (0 - 10) 0 100) 0 "math clamp low"
        assert int equals (math clamp 50 0 100) 50 "math clamp mid"
        assert int equals (math clamp 250 0 100) 100 "math clamp high"
        assert int equals (clamp 150 between 10 and 100) 100 "op clamp between and"
        assert true (math is even 42) "math is even 42"
        assert false (math is even 41) "math is even 41"
        assert true (math is odd (0 - 7)) "math is odd -7"
        assert int equals (math div ceil 7 3) 3 "math div ceil 7/3"
        assert int equals (math div ceil 6 3) 2 "math div ceil 6/3"
        assert int equals (math div ceil (0 - 7) 3) (0 - 2) "math div ceil -7/3"
        assert int equals (math div floor (0 - 7) 3) (0 - 3) "math div floor -7/3"
        assert int equals (math div floor 7 3) 2 "math div floor 7/3"
        assert int equals (math mod euclid (0 - 7) 3) 2 "math mod euclid -7 % 3 == 2"
        assert int equals (math div euclid (0 - 7) 3) (0 - 3) "math div euclid -7 / 3 == -3"
        -- Division by zero safety
        assert int equals (math div ceil 10 0) 0 "math div ceil / 0 == 0"
        assert int equals (math div floor 10 0) 0 "math div floor / 0 == 0"
        assert int equals (math div euclid 10 0) 0 "math div euclid / 0 == 0"
        assert int equals (math mod euclid 10 0) 0 "math mod euclid % 0 == 0"
        ()
```

### 02.3.4. Exempel 4: Potenser, heltalsrötter och logaritmer (`pow`, `isqrt`, `ilog2`, `ilog10`), talteori (`gcd`, `lcm`, `mod pow`, `mod inv`, `is prime`) och kombinatorik (`factorial`, `nCr`, `fib`)

I detta praktiska exempel undersöker vi grundligt hur `math` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test math powers number theory and combinatorics => ()
      test math powers number theory and combinatorics =
        assert int equals (math pow 2 10) 1024 "2^10 == 1024"
        assert int equals (math pow 5 0) 1 "5^0 == 1"
        assert int equals (math pow 5 (0 - 2)) 0 "negative exp -> 0"
        assert int equals (math isqrt 0) 0 "isqrt 0"
        assert int equals (math isqrt 1) 1 "isqrt 1"
        assert int equals (math isqrt 15) 3 "isqrt 15"
        assert int equals (math isqrt 16) 4 "isqrt 16"
        assert int equals (math isqrt 10000) 100 "isqrt 10000"
        assert int equals (math isqrt (0 - 4)) (0 - 1) "isqrt negative -> -1"
        assert int equals (math ilog2 1) 0 "ilog2 1 == 0"
        assert int equals (math ilog2 1024) 10 "ilog2 1024 == 10"
        assert int equals (math ilog2 0) (0 - 1) "ilog2 0 == -1"
        assert int equals (math ilog10 999) 2 "ilog10 999 == 2"
        assert int equals (math ilog10 1000) 3 "ilog10 1000 == 3"
        assert true (math is power of two 64) "64 is power of two"
        assert false (math is power of two 63) "63 is not power of two"
        assert false (math is power of two 0) "0 is not power of two"
        assert int equals (math next power of two 33) 64 "next power of two 33 == 64"
        assert int equals (math gcd 48 18) 6 "gcd(48, 18) == 6"
        assert int equals (math gcd (0 - 48) 18) 6 "gcd(-48, 18) == 6"
        assert int equals (math lcm 12 18) 36 "lcm(12, 18) == 36"
        assert int equals (math lcm 0 18) 0 "lcm(0, 18) == 0"
        assert int equals (math mod pow 2 10 1000) 24 "2^10 mod 1000 == 24"
        assert int equals (math mod pow 3 200 97) 62 "3^200 mod 97 == 62"
        assert int equals (math mod inv 3 11) 4 "3 * 4 == 12 == 1 mod 11"
        assert int equals (math mod inv 6 12) (0 - 1) "mod inv non-coprime -> -1"
        assert false (math is prime 1) "1 not prime"
        assert true (math is prime 2) "2 prime"
        assert true (math is prime 97) "97 prime"
        assert false (math is prime 99) "99 not prime"
        assert int equals (math factorial 5) 120 "5! == 120"
        assert int equals (math factorial 0) 1 "0! == 1"
        assert int equals (math ncr 10 3) 120 "C(10, 3) == 120"
        assert int equals (math fibonacci 10) 55 "fib(10) == 55"
        ()
```

### 02.3.5. Exempel 5: Deskriptiv heltalsstatistik över listor (`sum`, `product`, `min list`, `max list`, `mean floor`, `median floor`, `variance floor`)

I detta praktiska exempel undersöker vi grundligt hur `math` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test math list statistics => ()
      test math list statistics =
        xs = [30, 10, 50, 20, 40]
        assert int equals (math sum xs) 150 "sum"
        assert int equals (math product [2, 3, 4]) 24 "product"
        assert int equals (math mean xs) 30 "mean"
        assert int equals (math median xs) 30 "median odd"
        assert int equals (math median [10, 20, 30, 40]) 25 "median even"
        assert int equals (math min list xs) 10 "min list"
        assert int equals (math max list xs) 50 "max list"
        assert int equals (math sum []) 0 "sum []"
        assert int equals (math mean []) 0 "mean []"
        assert int equals (math median []) 0 "median []"
        ()
```

---

## 02.4. Under huven: hur `math` är byggd i ren Ridgun (`src/main/ridgun/lib/math.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/math.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 02.4.1. Intern implementation: Bounds, Sign & Parity

Se hur `math.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
module :: math

fn :: math abs Int => Int
      math abs x   =
        | x < 0     = 0 - x
        | otherwise = x

fn :: math sign Int => Int
      math sign x   =
        | x < 0     = 0 - 1
        | x > 0     = 1
        | otherwise = 0

fn :: math min Int Int => Int
      math min a   b   =
        | a <= b    = a
        | otherwise = b

fn :: math max Int Int => Int
      math max a   b   =
        | a >= b    = a
        | otherwise = b

fn :: math clamp Int Int Int => Int
      math clamp x   lo  hi  =
        | x < lo    = lo
        | x > hi    = hi
        | otherwise = x

op :: clamp Int between Int and Int => Int
      clamp x   between lo  and hi  =  math clamp x lo hi

fn :: math is even Int => Bool
      math is even x   =  (x % 2) == 0

fn :: math is odd Int => Bool
      math is odd x   =  (x % 2) != 0
```

### 02.4.2. Intern implementation: Powers, Integer Roots & Logarithms

Se hur `math.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: m pow loop Int Int Int => Int
      m pow loop base exp acc =
        | exp <= 0       = acc
        | (exp % 2) == 1 = m pow loop (base * base) (exp / 2) (acc * base)
        | otherwise      = m pow loop (base * base) (exp / 2) acc

fn :: math pow Int  Int => Int
      math pow base exp =
        | exp < 0   = 0
        | exp == 0  = 1
        | otherwise = m pow loop base exp 1

fn :: m isqrt step Int Int Int => Int
      m isqrt step n x nx =
        | nx >= x   = x
        | otherwise = m isqrt loop n nx

fn :: m isqrt loop Int Int => Int
      m isqrt loop n   x   =  m isqrt step n x ((x + (n / x)) / 2)

fn :: math isqrt Int => Int
      math isqrt n   =
        | n < 0     = 0 - 1
        | n == 0    = 0
        | n < 4     = 1
        | otherwise = m isqrt loop n (n / 2)

fn :: m ilog2 loop Int Int => Int
      m ilog2 loop n   acc =
        | n <= 1    = acc
        | otherwise = m ilog2 loop (n / 2) (acc + 1)

fn :: math ilog2 Int => Int
      math ilog2 n   =
        | n <= 0    = 0 - 1
        | otherwise = m ilog2 loop n 0

fn :: m ilog10 loop Int Int => Int
      m ilog10 loop n   acc =
        | n < 10    = acc
        | otherwise = m ilog10 loop (n / 10) (acc + 1)

fn :: math ilog10 Int => Int
      math ilog10 n   =
        | n <= 0    = 0 - 1
        | otherwise = m ilog10 loop n 0

fn :: m next pow2 loop Int Int => Int
      m next pow2 loop target cur =
        | cur >= target = cur
        | otherwise     = m next pow2 loop target (cur * 2)

fn :: math next power of two Int => Int
      math next power of two n =
        | n <= 1    = 1
        | otherwise = m next pow2 loop n 1

fn :: math is power of two Int => Bool
      math is power of two n =
        | n <= 0    = False
        | otherwise = (math next power of two n) == n
```

### 02.4.3. Intern implementation: Combinatorics & Sequences

Se hur `math.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: m fact loop Int Int => Int
      m fact loop n   acc =
        | n <= 1    = acc
        | otherwise = m fact loop (n - 1) (acc * n)

fn :: math factorial Int => Int
      math factorial n   =
        | n < 0     = 0
        | otherwise = m fact loop n 1

fn :: m ncr loop Int Int Int Int => Int
      m ncr loop n k idx acc =
        | idx > k   = acc
        | otherwise = m ncr loop n k (idx + 1) ((acc * ((n - k) + idx)) / idx)

fn :: math ncr Int Int => Int
      math ncr n   k   =
        | k < 0 or n < 0 or k > n = 0
        | k == 0 or k == n        = 1
        | otherwise =
          eff_k = math min k (n - k)
          m ncr loop n eff_k 1 1

fn :: m fib loop Int Int Int => Int
      m fib loop rem a b =
        | rem <= 0  = a
        | otherwise = m fib loop (rem - 1) b (a + b)

fn :: math fibonacci Int => Int
      math fibonacci n   =
        | n <= 0    = 0
        | otherwise = m fib loop n 0 1
```

### 02.4.4. Intern implementation: Integer List Statistics

Se hur `math.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: m list len [Int]    => Int
      m list len []       =  0
      m list len (_:rest) =  1 + (m list len rest)

fn :: m nth int [Int]    Int => Int
      m nth int []       _   =  0
      m nth int (x:rest) idx =
        | idx <= 0  = x
        | otherwise = m nth int rest (idx - 1)

fn :: math sum [Int]    => Int
      math sum []       =  0
      math sum (x:rest) =  x + (math sum rest)

fn :: math product [Int]    => Int
      math product []       =  1
      math product (x:rest) =  x * (math product rest)

fn :: m mean len [Int] Int => Int
      m mean len xs    n   =
        | n == 0    = 0
        | otherwise = (math sum xs) / n

fn :: math mean [Int] => Int
      math mean xs    =  m mean len xs (m list len xs)

fn :: m min loop [Int]    Int => Int
      m min loop []       cur =  cur
      m min loop (x:rest) cur =  m min loop rest (math min cur x)

fn :: math min list [Int]    => Int
      math min list []       =  0
      math min list (x:rest) =  m min loop rest x

fn :: m max loop [Int]    Int => Int
      m max loop []       cur =  cur
      m max loop (x:rest) cur =  m max loop rest (math max cur x)

fn :: math max list [Int]    => Int
      math max list []       =  0
      math max list (x:rest) =  m max loop rest x

fn :: m insert sorted Int [Int]    => [Int]
      m insert sorted v   []       =  [v]
      m insert sorted v   (x:rest) =
        | v <= x    = [v, x] :: rest
        | otherwise = [x] :: (m insert sorted v rest)

fn :: m sort ints [Int]    => [Int]
      m sort ints []       =  []
      m sort ints (x:rest) =  m insert sorted x (m sort ints rest)

fn :: m median sorted [Int] Int Int => Int
      m median sorted sorted n mid =
        | n == 0       = 0
        | (n % 2) == 1 = m nth int sorted mid
        | otherwise    = ((m nth int sorted (mid - 1)) + (m nth int sorted mid)) / 2

fn :: math median [Int] => Int
      math median xs    =
        n = m list len xs
        m median sorted (m sort ints xs) n (n / 2)
```

---

## 02.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `math`

- **Algoritmisk garanti och säkerhet**: Totala funktioner (returnerar `0` när divisorn är `<= 0` istället för att krascha med `SIGFPE`), helt utan flyttalsavrundningsfel.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/math.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test math.rg`.

### De 5 Gyllene Reglerna när du programmerar med `math`

1. **Deklarera `import math` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `math`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `math`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `math` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 03** går vi vidare och utforskar lib:en **`list`** på djupet (Lib:en `list` — Listor, $O(N \log N)$ Mergesort och Nyckel-Värde-Mappar).
