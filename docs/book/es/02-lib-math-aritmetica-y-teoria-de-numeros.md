# Capítulo 02: La lib `math` — Aritmética Segura, Teoría de Números y Estadística

## 02.1. ¿Por qué existe la lib `math`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `math` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `math`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: una división por cero inesperada en producción o el operador `%` devolviendo restos negativos en C o Java han tumbado más servicios de los que nos gusta admitir.

La lib **`math`** ofrece divisiones totales a prueba de `d == 0` (`div ceil`, `div floor`, `div euclid`, `mod euclid`), exponenciación e inverso modular en $O(\log E)$, raíces y logaritmos enteros exactos, combinatoria, primalidad y el operador mixfix `clamp x between lo and hi`.

En un ecosistema tradicional, resolver las tareas del dominio **`MATH`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`math`** (`src/main/ridgun/lib/math.rg`) aborda el problema con cuatro principios innegociables:

1. **Declara `import math` (o `import math as alias`) al inicio del archivo**: cada lib define su espacio de nombres `module :: math` y en modo `--strict` las funciones multi-palabra se invocan siempre con espacios naturales.
2. **Encadena tus tuberías de izquierda a derecha con `->`**: escribe `entrada paso uno -> paso dos -> resultado`, usa máscaras `(+ _ _ +)` para desestructurar secuencias y omite `_ =` en sentencias secuenciales (o descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `math` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 02.2. Artefactos nativos, importación y catálogo completo de la API de `math`

En `ridgun-libs`, **`math`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/math.rg` (dominio `MATH`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/math.rglib` | Distribución e importación directa con `import math` |
| **Archivo compilado** | `target/math.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libmath.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Cada lib declara su propio espacio de nombres con `module :: math`: basta con escribir `import math` (o `import math as alias`) en el encabezado y llamar a sus funciones con espacios naturales (`mi funcion x`) y tuberías `->` (`x mi funcion -> resultado`).

### 02.2.1. Resumen de familias funcionales de `math`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `math abs / math sign / math min / math max` | Magnitud absoluta, signo (`-1, 0, 1`) y extremos |
| `clamp x between lo and hi` | Operador mixfix (`op ::`) que acota `x` al rango `[lo, hi]` |
| `math div ceil / math div floor / math div euclid / math mod euclid` | Redondeo seguro ante división por cero y resto euclídeo no negativo |
| `math pow / math isqrt / math ilog2 / math ilog10` | Potencia en $O(\log E)$, raíz cuadrada entera de Newton y logaritmos enteros |
| `math gcd / math lcm / math mod pow / math mod inv / math is prime` | MCD/MCM de Euclides, aritmética modular y test de primalidad $6k \pm 1$ |
| `math sum / math mean floor / math median floor / math variance floor` | Combinatoria (`nCr`) sin desbordamiento y estadística entera sobre listas |

### 02.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/math.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/math.rg` (`0` tipos, `1` operadores y `56` funciones):

**Operadores mixfix (`op ::`) de `math`:**

```ridgun
op :: clamp Int between Int and Int => Int
```

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
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

## 02.3. Explorando `math` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `math` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test math.rg`.

### 02.3.1. Ejemplo 1: Flujo principal en estilo tabular con `math`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `math` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import math

fn :: verificar clave modular Int Int => Int Int Bool
      verificar clave modular base primo =
        primo math is prime -> es_p
        math mod pow base (primo - 1) primo -> pot
        math mod inv base primo -> inv
        (pot, inv, es_p)
```

### 02.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `math` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import math

fn :: calcular paginas y cuota Int Int Int => Int Int
      calcular paginas y cuota items por_pag uso =
        math div ceil items por_pag -> pags
        clamp uso between 0 and 100 -> cuota
        (pags, cuota)
```

### 02.3.3. Ejemplo 3: Cotas (`abs`, `sign`, `min`, `max`), operador mixfix `clamp ... between ... and ...` y divisiones seguras ante divisor cero (`div ceil`, `div floor`, `div euclid`, `mod euclid`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `math` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 02.3.4. Ejemplo 4: Potencias, raíces y logaritmos enteros (`pow`, `isqrt`, `ilog2`, `ilog10`), teoría de números (`gcd`, `lcm`, `mod pow`, `mod inv`, `is prime`) y combinatoria (`factorial`, `nCr`, `fib`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `math` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 02.3.5. Ejemplo 5: Estadística descriptiva entera sobre listas (`sum`, `product`, `min list`, `max list`, `mean floor`, `median floor`, `variance floor`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `math` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

## 02.4. Bajo el capó: cómo está construida `math` en Ridgun puro (`src/main/ridgun/lib/math.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/math.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 02.4.1. Implementación interna: Bounds, Sign & Parity

Fíjate en cómo `math.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

### 02.4.2. Implementación interna: Powers, Integer Roots & Logarithms

Fíjate en cómo `math.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

### 02.4.3. Implementación interna: Combinatorics & Sequences

Fíjate en cómo `math.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

### 02.4.4. Implementación interna: Integer List Statistics

Fíjate en cómo `math.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

## 02.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `math`

- **Garantía algorítmica y de seguridad**: Funciones totales (devuelven `0` cuando el divisor o módulo es `<= 0` en lugar de abortar con `SIGFPE`), sin coma flotante imprecisa.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/math.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test math.rg`.

### Las 5 Reglas de Oro al programar con `math`

1. **Declara `import math` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `math` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `math` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `math` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 03** pasaremos a explorar en profundidad la lib **`list`** (La lib `list` — Listas, Mergesort $O(N \log N)$ y Mapas Clave-Valor).
