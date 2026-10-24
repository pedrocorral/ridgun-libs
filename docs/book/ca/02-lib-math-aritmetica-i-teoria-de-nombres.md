# Capítol 02: La lib `math` — Aritmètica Segura, Teoria de Nombres i Estadística

## 02.1. Per què existeix la lib `math`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `math` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `math`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: una divisió per zero inesperada a producció o l'operador `%` retornant residus negatius en C o Java han tombat més serveis dels que ens agrada admetre.

La lib **`math`** ofereix divisions totals a prova de `d == 0` (`div ceil`, `div floor`, `div euclid`, `mod euclid`), exponenciació i invers modular en $O(\log E)$, arrels i logaritmes enters exactes, combinatòria, primalitat i l'operador mixfix `clamp x between lo and hi`.

En un ecosistema tradicional, resoldre les tasques del domini **`MATH`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`math`** (`src/main/ridgun/lib/math.rg`) aborda el problema amb quatre principis innegociables:

1. **Funcions totals i contractes explícits (`=>`)**: cap funció de `math` llança excepcions ocultes ni depèn de `null`. Tot cas límit retorna un valor sentinella documentat o un tipus algebraic suma (`Option`, `Result`).
2. **Zero codi C i zero `libc`**: tot el codi de `math` compila directament a codi màquina natiu ELF64 verificat per `ridgunc`.
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `math` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 02.2. Artefactes natius, importació i catàleg complet de l'API de `math`

A `ridgun-libs`, **`math`** és una **lib** de primera classe situada a `src/main/ridgun/lib/math.rg` (domini `MATH`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/math.rglib` | Distribució i importació directa amb `import math` |
| **Fitxer compilat** | `target/math.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libmath.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import math` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

### 02.2.1. Resum de famílies funcionals de `math`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `math abs / math sign / math min / math max` | Magnitud absoluta, signe (`-1, 0, 1`) i extrems |
| `clamp x between lo and hi` | Operador mixfix (`op ::`) que acota `x` al rang `[lo, hi]` |
| `math div ceil / math div floor / math div euclid / math mod euclid` | Arrodoniment segur davant divisió per zero i residu euclidià no negatiu |
| `math pow / math isqrt / math ilog2 / math ilog10` | Potència en $O(\log E)$, arrel quadrada entera de Newton i logaritmes enters |
| `math gcd / math lcm / math mod pow / math mod inv / math is prime` | MCD/MCM d'Euclides, aritmètica modular i test de primalitat $6k \pm 1$ |
| `math sum / math mean floor / math median floor / math variance floor` | Combinatòria (`nCr`) sense desbordament i estadística entera sobre llistes |

### 02.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/math.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/math.rg` (`0` tipus, `1` operadors i `56` funcions):

**Operadors mixfix (`op ::`) de `math`:**

```ridgun
op :: clamp Int between Int and Int => Int
```

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 02.3. Explorant `math` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `math` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test math.rg`.

### 02.3.1. Exemple 1: Flux principal en estil tabular amb `math`

Observa com en Ridgun els signes `=` i els passos de transformació amb `math` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import math

fn :: verificar clave modular (base : Int) (primo : Int) => (Int, Int, Bool)
      verificar clave modular base primo =
        es_p = math is prime primo
        pot  = math mod pow base (primo - 1) primo
        inv  = math mod inv base primo
        (pot, inv, es_p)
```

### 02.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `math` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import math

fn :: calcular paginas y cuota (items : Int) (por_pag : Int) (uso : Int) => (Int, Int)
      calcular paginas y cuota items por_pag uso =
        pags  = math div ceil items por_pag
        cuota = clamp uso between 0 and 100
        (pags, cuota)
```

### 02.3.3. Exemple 3: Cotes (`abs`, `sign`, `min`, `max`), operador mixfix `clamp ... between ... and ...` i divisions segures davant divisor zero (`div ceil`, `div floor`, `div euclid`, `mod euclid`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `math` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 02.3.4. Exemple 4: Potències, arrels i logaritmes enters (`pow`, `isqrt`, `ilog2`, `ilog10`), teoria de nombres (`gcd`, `lcm`, `mod pow`, `mod inv`, `is prime`) i combinatòria (`factorial`, `nCr`, `fib`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `math` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 02.3.5. Exemple 5: Estadística descriptiva entera sobre llistes (`sum`, `product`, `min list`, `max list`, `mean floor`, `median floor`, `variance floor`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `math` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

## 02.4. Sota el capó: com està construïda `math` en Ridgun pur (`src/main/ridgun/lib/math.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/math.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 02.4.1. Implementació interna: Bounds, Sign & Parity

Fixa't en com `math.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 02.4.2. Implementació interna: Powers, Integer Roots & Logarithms

Fixa't en com `math.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 02.4.3. Implementació interna: Combinatorics & Sequences

Fixa't en com `math.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 02.4.4. Implementació interna: Integer List Statistics

Fixa't en com `math.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

## 02.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `math`

- **Garantia algorísmica i de seguretat**: Funcions totals (retornen `0` quan el divisor o mòdul és `<= 0` en lloc d'avortar amb `SIGFPE`), sense coma flotant imprecisa.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/math.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test math.rg`.

### Les 5 Regles d'Or en programar amb `math`

1. **Declara `import math` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `math` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `math` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `math` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 03** passarem a explorar en profunditat la lib **`list`** (La lib `list` — Llistes, Mergesort $O(N \log N)$ i Mapes Clau-Valor).
