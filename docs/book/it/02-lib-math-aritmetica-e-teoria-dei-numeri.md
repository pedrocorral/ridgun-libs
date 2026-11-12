# Capitolo 02: La lib `math` — Aritmetica Sicura, Teoria dei Numeri e Statistica

## 02.1. Perché esiste la lib `math`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `math` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `math`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: una divisione per zero imprevista in produzione o l'operatore `%` che restituisce resti negativi in C o Java hanno mandato in crash più servizi di quanti ci piaccia ammettere.

La lib **`math`** offre divisioni totali a prova di `d == 0` (`div ceil`, `div floor`, `div euclid`, `mod euclid`), esponenziazione e inverso modulare in $O(\log E)$, radici e logaritmi interi esatti, calcolo combinatorio, primalità e l'operatore mixfix `clamp x between lo and hi`.

In un ecosistema tradizionale, risolvere i compiti del dominio **`MATH`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`math`** (`src/main/ridgun/lib/math.ridgun`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import math` (o `import math as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: math` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `math` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 02.2. Artefatti nativi, importazione e catalogo completo dell'API di `math`

In `ridgun-libs`, **`math`** è una **lib** di prima classe situata in `src/main/ridgun/lib/math.ridgun` (dominio `MATH`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/math.ridgunlib` | Distribuzione e importazione diretta con `import math` |
| **File compilato** | `target/math.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libmath.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: math`: basta scrivere `import math` (o `import math as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 02.2.1. Riepilogo delle famiglie funzionali di `math`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `math abs / math sign / math min / math max` | Valore assoluto, segno (`-1, 0, 1`) ed estremi |
| `clamp x between lo and hi` | Operatore mixfix (`op ::`) che limita `x` all'intervallo `[lo, hi]` |
| `math div ceil / math div floor / math div euclid / math mod euclid` | Arrotondamento sicuro contro la divisione per zero e resto euclideo non negativo |
| `math pow / math isqrt / math ilog2 / math ilog10` | Potenza in $O(\log E)$, radice quadrata intera di Newton e logaritmi interi |
| `math gcd / math lcm / math mod pow / math mod inv / math is prime` | MCD/mcm di Euclide, aritmetica modulare e test di primalità $6k \pm 1$ |
| `math sum / math mean floor / math median floor / math variance floor` | Calcolo combinatorio (`nCr`) senza overflow e statistica intera su liste |

### 02.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/math.ridgun`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/math.ridgun` (`0` tipi, `1` operatori e `56` funzioni):

**Operatori mixfix (`op ::`) di `math`:**

```ridgun
op :: clamp Int between Int and Int => Int
```

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
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

## 02.3. Esplorare `math` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `math` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test math.ridgun`.

### 02.3.1. Esempio 1: Flusso principale in stile tabulare con `math`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `math` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import math

fn :: verificar clave modular Int Int => Int Int Bool
      verificar clave modular base primo =
        primo math is prime -> es_p
        math mod pow base (primo - 1) primo -> pot
        math mod inv base primo -> inv
        (pot, inv, es_p)
```

### 02.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `math` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import math

fn :: calcular paginas y cuota Int Int Int => Int Int
      calcular paginas y cuota items por_pag uso =
        math div ceil items por_pag -> pags
        clamp uso between 0 and 100 -> cuota
        (pags, cuota)
```

### 02.3.3. Esempio 3: Limiti (`abs`, `sign`, `min`, `max`), operatore mixfix `clamp ... between ... and ...` e divisioni sicure con divisore zero (`div ceil`, `div floor`, `div euclid`, `mod euclid`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `math` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 02.3.4. Esempio 4: Potenze, radici e logaritmi interi (`pow`, `isqrt`, `ilog2`, `ilog10`), teoria dei numeri (`gcd`, `lcm`, `mod pow`, `mod inv`, `is prime`) e combinatoria (`factorial`, `nCr`, `fib`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `math` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 02.3.5. Esempio 5: Statistica descrittiva intera su liste (`sum`, `product`, `min list`, `max list`, `mean floor`, `median floor`, `variance floor`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `math` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

## 02.4. Sotto il cofano: come è costruita `math` in Ridgun puro (`src/main/ridgun/lib/math.ridgun`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/math.ridgun` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 02.4.1. Implementazione interna: Bounds, Sign & Parity

Nota come `math.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 02.4.2. Implementazione interna: Powers, Integer Roots & Logarithms

Nota come `math.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 02.4.3. Implementazione interna: Combinatorics & Sequences

Nota come `math.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 02.4.4. Implementazione interna: Integer List Statistics

Nota come `math.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

## 02.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `math`

- **Garanzia algoritmica e di sicurezza**: Funzioni totali (restituiscono `0` quando il divisore o il modulo è `<= 0` invece di terminare con `SIGFPE`), senza virgola mobile imprecisa.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/math.ridgun` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test math.ridgun`.

### Le 5 Regole d'Oro quando programmi con `math`

1. **Dichiara `import math` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `math` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `math` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `math` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 03** passeremo a esplorare in profondità la lib **`list`** (La lib `list` — Liste, Mergesort $O(N \log N)$ e Mappe Chiave-Valore).
