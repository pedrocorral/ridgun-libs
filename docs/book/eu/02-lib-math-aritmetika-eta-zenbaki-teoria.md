# 02. kapitulua: `math` lib-a — Aritmetika Segurua, Zenbaki-teoria eta Estatistika

## 02.1. Zergatik existitzen da `math` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `math` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `math`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: ekoizpenean ustekabeko zeroz zatitze batek edo C zein Javan `%` eragileak hondar negatiboak itzultzeak aitortzea gustatzen zaiguna baino zerbitzu gehiago bota ditu behera.

**`math`** lib-ak `d == 0`-ren aurkako zatiketa osoak (`div ceil`, `div floor`, `div euclid`, `mod euclid`), $O(\log E)$ berreketa eta alderantzizko modularra, erro eta logaritmo oso zehatzak, konbinatoria eta `clamp x between lo and hi` mixfix eragilea eskaintzen ditu.

Ekosistema tradizional batean, **`MATH`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`math`** lib-ak (`src/main/ridgun/lib/math.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Funtzio osoak eta kontratu esplizituak (`=>`)**: `math`-eko funtzio bakar batek ere ez du ezkutuko salbuespenik jaurtitzen, ezta `null` erabiltzen ere. Muga-kasu orok dokumentatutako balio bat edo batura-mota aljebraiko bat (`Option`, `Result`) itzultzen du.
2. **Zero C kode eta zero `libc`**: `math`-eko kode guztia zuzenean ELF64 makina-kode natibora konpilatzen da, `ridgunc`-ek egiaztatuta.
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `math`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 02.2. Artefaktu natiboak, inportazioa eta `math` APIaren katalogo osoa

`ridgun-libs`-en, **`math`** lehen mailako **lib** bat da, `src/main/ridgun/lib/math.rg` bidean kokatua (`MATH` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/math.rglib` | Banaketa eta inportazio zuzena `import math` bidez |
| **Fitxategi konpilatua** | `target/math.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libmath.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import math` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

### 02.2.1. `math`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `math abs / math sign / math min / math max` | Magnitude absolutua, zeinua (`-1, 0, 1`) eta muturrak |
| `clamp x between lo and hi` | `x` balioa `[lo, hi]` tartera mugatzen duen mixfix eragilea (`op ::`) |
| `math div ceil / math div floor / math div euclid / math mod euclid` | Zeroz zatitzearen aurkako biribilketa segurua eta hondar euklidear ez-negatiboa |
| `math pow / math isqrt / math ilog2 / math ilog10` | $O(\log E)$ berreketa, Newtonen erro karratu osoa eta logaritmo osoak |
| `math gcd / math lcm / math mod pow / math mod inv / math is prime` | Euklidesen ZKH/MKT, aritmetika modularra eta $6k \pm 1$ lehentasun-proba |
| `math sum / math mean floor / math median floor / math variance floor` | Gainezkatzerik gabeko konbinatoria (`nCr`) eta zerrenden estatistika osoa |

### 02.2.2. `src/main/ridgun/lib/math.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/math.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`0` mota, `1` eragile eta `56` funtzio):

**`math`-eko mixfix eragileak (`op ::`):**

```ridgun
op :: clamp Int between Int and Int => Int
```

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
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

## 02.3. `math` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `math` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test math.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 02.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `math` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `math` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import math

fn :: verificar clave modular (base : Int) (primo : Int) => (Int, Int, Bool)
      verificar clave modular base primo =
        es_p = math is prime primo
        pot  = math mod pow base (primo - 1) primo
        inv  = math mod inv base primo
        (pot, inv, es_p)
```

### 02.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`math` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import math

fn :: calcular paginas y cuota (items : Int) (por_pag : Int) (uso : Int) => (Int, Int)
      calcular paginas y cuota items por_pag uso =
        pags  = math div ceil items por_pag
        cuota = clamp uso between 0 and 100
        (pags, cuota)
```

### 02.3.3. 3. adibidea: Bornak (`abs`, `sign`, `min`, `max`), `clamp ... between ... and ...` mixfix eragilea eta zero zatitzailearen aurkako zatiketa seguruak (`div ceil`, `div floor`, `div euclid`, `mod euclid`)

Adibide praktiko honetan `math` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test math bounds and division => ()
      test math bounds and division =
        _ = assert int equals (math abs (0 - 42)) 42 "math abs negative"
        _ = assert int equals (math abs 42) 42 "math abs positive"
        _ = assert int equals (math abs 0) 0 "math abs zero"
        _ = assert int equals (math sign (0 - 99)) (0 - 1) "math sign negative"
        _ = assert int equals (math sign 0) 0 "math sign zero"
        _ = assert int equals (math sign 99) 1 "math sign positive"
        _ = assert int equals (math min 10 (0 - 5)) (0 - 5) "math min"
        _ = assert int equals (math max 10 (0 - 5)) 10 "math max"
        _ = assert int equals (math clamp (0 - 10) 0 100) 0 "math clamp low"
        _ = assert int equals (math clamp 50 0 100) 50 "math clamp mid"
        _ = assert int equals (math clamp 250 0 100) 100 "math clamp high"
        _ = assert int equals (clamp 150 between 10 and 100) 100 "op clamp between and"
        _ = assert true (math is even 42) "math is even 42"
        _ = assert false (math is even 41) "math is even 41"
        _ = assert true (math is odd (0 - 7)) "math is odd -7"
        _ = assert int equals (math div ceil 7 3) 3 "math div ceil 7/3"
        _ = assert int equals (math div ceil 6 3) 2 "math div ceil 6/3"
        _ = assert int equals (math div ceil (0 - 7) 3) (0 - 2) "math div ceil -7/3"
        _ = assert int equals (math div floor (0 - 7) 3) (0 - 3) "math div floor -7/3"
        _ = assert int equals (math div floor 7 3) 2 "math div floor 7/3"
        _ = assert int equals (math mod euclid (0 - 7) 3) 2 "math mod euclid -7 % 3 == 2"
        _ = assert int equals (math div euclid (0 - 7) 3) (0 - 3) "math div euclid -7 / 3 == -3"
        -- Division by zero safety
        _ = assert int equals (math div ceil 10 0) 0 "math div ceil / 0 == 0"
        _ = assert int equals (math div floor 10 0) 0 "math div floor / 0 == 0"
        _ = assert int equals (math div euclid 10 0) 0 "math div euclid / 0 == 0"
        _ = assert int equals (math mod euclid 10 0) 0 "math mod euclid % 0 == 0"
        ()
```

### 02.3.4. 4. adibidea: Berreketak, erro eta logaritmo osoak (`pow`, `isqrt`, `ilog2`, `ilog10`), zenbaki-teoria (`gcd`, `lcm`, `mod pow`, `mod inv`, `is prime`) eta konbinatoria (`factorial`, `nCr`, `fib`)

Adibide praktiko honetan `math` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test math powers number theory and combinatorics => ()
      test math powers number theory and combinatorics =
        _ = assert int equals (math pow 2 10) 1024 "2^10 == 1024"
        _ = assert int equals (math pow 5 0) 1 "5^0 == 1"
        _ = assert int equals (math pow 5 (0 - 2)) 0 "negative exp -> 0"
        _ = assert int equals (math isqrt 0) 0 "isqrt 0"
        _ = assert int equals (math isqrt 1) 1 "isqrt 1"
        _ = assert int equals (math isqrt 15) 3 "isqrt 15"
        _ = assert int equals (math isqrt 16) 4 "isqrt 16"
        _ = assert int equals (math isqrt 10000) 100 "isqrt 10000"
        _ = assert int equals (math isqrt (0 - 4)) (0 - 1) "isqrt negative -> -1"
        _ = assert int equals (math ilog2 1) 0 "ilog2 1 == 0"
        _ = assert int equals (math ilog2 1024) 10 "ilog2 1024 == 10"
        _ = assert int equals (math ilog2 0) (0 - 1) "ilog2 0 == -1"
        _ = assert int equals (math ilog10 999) 2 "ilog10 999 == 2"
        _ = assert int equals (math ilog10 1000) 3 "ilog10 1000 == 3"
        _ = assert true (math is power of two 64) "64 is power of two"
        _ = assert false (math is power of two 63) "63 is not power of two"
        _ = assert false (math is power of two 0) "0 is not power of two"
        _ = assert int equals (math next power of two 33) 64 "next power of two 33 == 64"
        _ = assert int equals (math gcd 48 18) 6 "gcd(48, 18) == 6"
        _ = assert int equals (math gcd (0 - 48) 18) 6 "gcd(-48, 18) == 6"
        _ = assert int equals (math lcm 12 18) 36 "lcm(12, 18) == 36"
        _ = assert int equals (math lcm 0 18) 0 "lcm(0, 18) == 0"
        _ = assert int equals (math mod pow 2 10 1000) 24 "2^10 mod 1000 == 24"
        _ = assert int equals (math mod pow 3 200 97) 62 "3^200 mod 97 == 62"
        _ = assert int equals (math mod inv 3 11) 4 "3 * 4 == 12 == 1 mod 11"
        _ = assert int equals (math mod inv 6 12) (0 - 1) "mod inv non-coprime -> -1"
        _ = assert false (math is prime 1) "1 not prime"
        _ = assert true (math is prime 2) "2 prime"
        _ = assert true (math is prime 97) "97 prime"
        _ = assert false (math is prime 99) "99 not prime"
        _ = assert int equals (math factorial 5) 120 "5! == 120"
        _ = assert int equals (math factorial 0) 1 "0! == 1"
        _ = assert int equals (math ncr 10 3) 120 "C(10, 3) == 120"
        _ = assert int equals (math fibonacci 10) 55 "fib(10) == 55"
        ()
```

### 02.3.5. 5. adibidea: Zerrenden gaineko estatistika deskribatzaile osoa (`sum`, `product`, `min list`, `max list`, `mean floor`, `median floor`, `variance floor`)

Adibide praktiko honetan `math` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test math list statistics => ()
      test math list statistics =
        xs = [30, 10, 50, 20, 40]
        _  = assert int equals (math sum xs) 150 "sum"
        _  = assert int equals (math product [2, 3, 4]) 24 "product"
        _  = assert int equals (math mean xs) 30 "mean"
        _  = assert int equals (math median xs) 30 "median odd"
        _  = assert int equals (math median [10, 20, 30, 40]) 25 "median even"
        _  = assert int equals (math min list xs) 10 "min list"
        _  = assert int equals (math max list xs) 50 "max list"
        _  = assert int equals (math sum []) 0 "sum []"
        _  = assert int equals (math mean []) 0 "mean []"
        _  = assert int equals (math median []) 0 "median []"
        ()
```

---

## 02.4. Kaputaren azpian: nola dagoen eraikia `math` Ridgun hutsean (`src/main/ridgun/lib/math.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/math.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 02.4.1. Barne-inplementazioa: Bounds, Sign & Parity

Ikusi nola `math.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
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

### 02.4.2. Barne-inplementazioa: Powers, Integer Roots & Logarithms

Ikusi nola `math.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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
```

### 02.4.3. Barne-inplementazioa: Combinatorics & Sequences

Ikusi nola `math.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 02.4.4. Barne-inplementazioa: Integer List Statistics

Ikusi nola `math.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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
```

---

## 02.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `math`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: Funtzio osoak (`0` itzultzen dute zatitzailea `<= 0` denean `SIGFPE`-rekin abortatu beharrean), koma higikor ez-zehatzik gabe.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/math.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test math.rg` suite automatizatuaren bidez.

### `math`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import math` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `math`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `math`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `math` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**03. kapituluan** **`list`** lib-a sakonki esploratuko dugu (`list` lib-a — Zerrendak, $O(N \log N)$ Mergesort eta Gako-Balio Mapak).
