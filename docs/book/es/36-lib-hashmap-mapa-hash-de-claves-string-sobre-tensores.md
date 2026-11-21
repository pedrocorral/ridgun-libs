# Capítulo 36: La lib `hashmap` — Mapa Hash de Claves `String` a Cualquier Valor, sobre Tensores y con Semilla SipHash

## 36.1. ¿Por qué existe la lib `hashmap`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `hashmap` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `hashmap`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: contar palabras o agrupar cien mil registros con una lista de asociación es cuadrático, y un árbol ordenado paga un logaritmo y una asignación de memoria en cada inserción cuando lo único que necesitas es encontrar una clave.

La lib **`hashmap`** implementa `HashMap V`, un mapa de claves `String` a valores de cualquier tipo, construido sobre tensores: una tabla de ranuras con direccionamiento abierto y sondeo lineal, llena como máximo hasta la mitad, apunta a tensores densos de claves y de valores que se mantienen en orden de inserción. El hash de las claves se calcula con SipHash-1-3 (la lib `hash`) bajo una semilla aleatoria por mapa; `hashmap put`, `hashmap add`, `hashmap get` y `hashmap has` tardan un tiempo esperado constante, y `hashmap pairs` devuelve las entradas en orden de inserción.

En un ecosistema tradicional, resolver las tareas del dominio **`HASHMAP`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`hashmap`** (`src/main/ridgun/lib/hashmap.ridgun`) aborda el problema con cuatro principios innegociables:

1. **Declara `import hashmap` (o `import hashmap as alias`) al inicio del archivo**: cada lib define su espacio de nombres `module :: hashmap` y en modo `--strict` las funciones multi-palabra se invocan siempre con espacios naturales.
2. **Encadena tus tuberías de izquierda a derecha con `->`**: escribe `entrada paso uno -> paso dos -> resultado`, usa máscaras `(+ _ _ +)` para desestructurar secuencias y omite `_ =` en sentencias secuenciales (o descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `hashmap` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 36.2. Artefactos nativos, importación y catálogo completo de la API de `hashmap`

En `ridgun-libs`, **`hashmap`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/hashmap.ridgun` (dominio `HASHMAP`). Al compilar con `stable bundle`, se empaqueta en un artefacto nativo:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/hashmap.ridgunlib` | Distribución e importación directa con `import hashmap` |

> Cada lib declara su propio espacio de nombres con `module :: hashmap`: basta con escribir `import hashmap` (o `import hashmap as alias`) en el encabezado y llamar a sus funciones con espacios naturales (`mi funcion x`) y tuberías `->` (`x mi funcion -> resultado`).

### 36.2.1. Resumen de familias funcionales de `hashmap`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `hashmap empty` | Un mapa nuevo y vacío; el tipo de sus valores lo fija el primer valor almacenado |
| `hashmap put / hashmap get / hashmap has` | Inserta o reemplaza, lee con un valor por defecto y comprueba la pertenencia, en tiempo esperado constante |
| `hashmap add` | Suma un `Int` al valor de una clave (una clave ausente empieza en 0): un contador en un solo sondeo |
| `hashmap size / hashmap pairs` | El número de claves, y las entradas `[String V]` en orden de inserción |

### 36.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/hashmap.ridgun`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/hashmap.ridgun` (`1` tipos, `0` operadores y `35` funciones):

**Tipos algebraicos y registros (`type`) de `hashmap`:**

```ridgun
type HashMap V = fill: [V], vals: [Tensor[V * n]], slots: Tensor[Int * n], keys: Tensor[String * n], cap: Int, room: Int, count: Tensor[Int * k], seed: String
```

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: hm hash String String` | `Int` |
| `2` | `fn :: hm seed16 String` | `String` |
| `3` | `fn :: hm read seed Int` | `String` |
| `4` | `fn :: hm new seed` | `String` |
| `5` | `fn :: hm slot hash Int` | `Int` |
| `6` | `fn :: hm probe Tensor[Int * n] Tensor[String * m] Int String Int Int` | `Int` |
| `7` | `fn :: hm free Tensor[Int * n] Int Int` | `Int` |
| `8` | `fn :: hashmap empty` | `HashMap V` |
| `9` | `fn :: hm size (HashMap V)` | `Int` |
| `10` | `fn :: hm bump Tensor[Int * k]` | `()` |
| `11` | `fn :: hm vt [Tensor[V * n]]` | `Tensor[V * n]` |
| `12` | `fn :: hm rehash Tensor[Int * n] Tensor[Int * m] Int Int Int` | `()` |
| `13` | `fn :: hm grow slots (HashMap V)` | `HashMap V` |
| `14` | `fn :: hm copy Tensor[String * n] Tensor[V * n] Tensor[String * m] Tensor[V * m] Int Int` | `()` |
| `15` | `fn :: hm grow dense (HashMap V) [V]` | `HashMap V` |
| `16` | `fn :: hm make room (HashMap V)` | `HashMap V` |
| `17` | `fn :: hm room slots (HashMap V)` | `HashMap V` |
| `18` | `fn :: hm room dense (HashMap V)` | `HashMap V` |
| `19` | `fn :: hm ensure vals (HashMap V) V` | `HashMap V` |
| `20` | `fn :: hm insert Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] Int Int String V` | `()` |
| `21` | `fn :: hm put go (HashMap V) (HashMap V) String V` | `HashMap V` |
| `22` | `fn :: hm put at (HashMap V) Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String V Int Int` | `HashMap V` |
| `23` | `fn :: hm put slot (HashMap V) Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String V Int Int` | `HashMap V` |
| `24` | `fn :: hashmap put (HashMap V) String V` | `HashMap V` |
| `25` | `fn :: hm add go (HashMap Int) (HashMap Int) String Int` | `HashMap Int` |
| `26` | `fn :: hm add at (HashMap Int) Tensor[Int * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String Int Int Int` | `HashMap Int` |
| `27` | `fn :: hm add slot (HashMap Int) Tensor[Int * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String Int Int Int` | `HashMap Int` |
| `28` | `fn :: hashmap add (HashMap Int) String Int` | `HashMap Int` |
| `29` | `fn :: hm lookup Tensor[Int * c] Tensor[String * r] Int String Int` | `Int` |
| `30` | `fn :: hm get at Tensor[V * n] Int V` | `V` |
| `31` | `fn :: hashmap get (HashMap V) String V` | `V` |
| `32` | `fn :: hashmap has (HashMap V) String` | `Bool` |
| `33` | `fn :: hashmap size (HashMap V)` | `Int` |
| `34` | `fn :: hm pairs loop Tensor[String * n] Tensor[V * n] Int [String V]` | `[String V]` |
| `35` | `fn :: hashmap pairs (HashMap V)` | `[String V]` |

---

## 36.3. Explorando `hashmap` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `hashmap` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test hashmap.ridgun`.

### 36.3.1. Ejemplo 1: Flujo principal en estilo tabular con `hashmap`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `hashmap` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import hashmap

fn :: contar visitas [String]     (HashMap Int) => HashMap Int
      contar visitas []           m             =  m
      contar visitas (ruta:resto) m             =  contar visitas resto (hashmap add m ruta 1)
```

### 36.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `hashmap` está diseñada para componerse con guardas booleanas `|` y con el resto de las 38 libs de `ridgun-libs`:

```ridgun
import hashmap

fn :: visitas de (HashMap Int) String => Int
      visitas de m ruta =
        | hashmap has m ruta = hashmap get m ruta 0
        | otherwise          = 0
```

### 36.3.3. Ejemplo 3: El mapa vacío, `hashmap put`, reemplazo, `hashmap get` con valor por defecto y `hashmap pairs`

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `hashmap` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test hashmap basics => ()
      test hashmap basics =
        e = hashmap empty
        hashmap get e "a" 7 -> assert int equals 7 "AC1: get on empty gives the default"
        hashmap has e "a" -> assert false "AC1: has on empty"
        hashmap size e -> assert int equals 0 "AC1: size of empty"
        hashmap pairs e -> assert eq []

        m = hashmap put (hashmap put (hashmap put hashmap empty "b" 2) "a" 1) "c" 3
        m2 = hashmap put m "a" 10
        hashmap get m2 "a" 0 -> assert int equals 10 "AC1: put replaces the value"
        hashmap get m2 "b" 0 -> assert int equals 2 "AC1: get b"
        hashmap get m2 "zz" (0 - 1) -> assert int equals (0 - 1) "AC1: missing key gives the default"
        hashmap has m2 "c" -> assert true "AC1: has c"
        hashmap has m2 "zz" -> assert false "AC1: has missing"
        hashmap size m2 -> assert int equals 3 "AC1: replacing does not add a key"
        hashmap pairs m2 -> assert eq [("b", 2), ("a", 10), ("c", 3)]
        ()
```

### 36.3.4. Ejemplo 4: Contadores con `hashmap add`: sumas, claves ausentes y llegada a cero

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `hashmap` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test hashmap add => ()
      test hashmap add =
        m = hashmap add (hashmap add (hashmap add hashmap empty "x" 2) "y" 5) "x" 3
        hashmap get m "x" 0 -> assert int equals 5 "AC2: add sums"
        hashmap get m "y" 0 -> assert int equals 5 "AC2: a missing key starts at 0"
        m2 = hashmap add m "y" (0 - 5)
        hashmap get m2 "y" 99 -> assert int equals 0 "AC2: add can reach 0 and the key stays"
        hashmap has m2 "y" -> assert true "AC2: has after reaching 0"
        hashmap pairs m2 -> assert eq [("x", 5), ("y", 0)]
        ()
```

### 36.3.5. Ejemplo 5: Claves inusuales: la cadena vacía, bytes por encima de 127 y claves de 10 KB que difieren en el último byte

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `hashmap` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test hashmap unusual keys => ()
      test hashmap unusual keys =
        hi = (char from code 200) + (char from code 255)
        la = kb10 "a"
        lb = kb10 "b"
        m = hashmap put (hashmap put (hashmap put (hashmap put hashmap empty "" 1) hi 2) la 3) lb 4
        hashmap get m "" 0 -> assert int equals 1 "AC3: empty key"
        hashmap get m hi 0 -> assert int equals 2 "AC3: bytes >= 128"
        hashmap get m la 0 -> assert int equals 3 "AC3: 10 KB key"
        hashmap get m lb 0 -> assert int equals 4 "AC3: 10 KB key differing in the last byte"
        hashmap has m (kb10 "c") -> assert false "AC3: another 10 KB key is missing"
        hashmap has m (char from code 200) -> assert false "AC3: prefix of a key is missing"
        hashmap size m -> assert int equals 4 "AC3: four keys"
        ()
```

### 36.3.6. Ejemplo 6: Valores de tipo registro: un `HashMap` de registros definidos por el usuario

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `hashmap` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test hashmap record values => ()
      test hashmap record values =
        m = hashmap put (hashmap put (hashmap put hashmap empty "/a" (Visit "/a" 3)) "/b" (Visit "/b" 7)) "/a" (Visit "/a" 4)
        hashmap get m "/a" (Visit "" 0) -> assert eq (Visit "/a" 4)
        hashmap get m "/b" (Visit "" 0) -> assert eq (Visit "/b" 7)
        hashmap get m "/c" (Visit "" 0) -> assert eq (Visit "" 0)
        hits (hashmap get m "/a" (Visit "" 0)) -> assert int equals 4 "AC4: record field"
        ()
```

### 36.3.7. Ejemplo 7: Crecimiento: 20 000 claves, todas las claves encontradas y orden de inserción conservado

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `hashmap` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test hashmap growth => ()
      test hashmap growth =
        n = 20000
        m = put many hashmap empty 0 n
        hashmap size m -> assert int equals n "AC1: 20000 keys after growing"
        all found m 0 n -> assert true "AC1: every key found after growing"
        ps = hashmap pairs m
        sum values ps 0 -> assert int equals (n * (n - 1) / 2) "AC1: pairs hold every value"
        first keys ps 3 [] -> assert eq ["key 0", "key 1", "key 2"]
        fill 1 + count [] + str len seed -> assert int equals 7 "Program functions named like fields still work"
        ()
```

---

## 36.4. Bajo el capó: cómo está construida `hashmap` en Ridgun puro (`src/main/ridgun/lib/hashmap.ridgun`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/hashmap.ridgun` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 36.4.1. Implementación interna: Hash

Fíjate en cómo `hashmap.ridgun` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
-- 31 bits of SipHash-1-3 of the key, with the map's 16-byte seed as the hash key (the compiler's native
-- `siphash13 range low`, ridgunc 1.0.44), plus 1 so a used slot is never 0.
-- Keys are always compared when the hashes match.
-- The per-map random seed stops chosen keys from colliding on purpose.
fn :: hm hash String String => Int
      hm hash seed key =  ((siphash13 range low seed key 0 (str len key)) % 2147483648) + 1

-- Exactly 16 bytes: SipHash takes a 128-bit key.
fn :: hm seed16 String => String
      hm seed16 s =
        | (str len s) == 16 = s
        | otherwise         = str slice (s + "ridgun-hashmap-0") 0 16

fn :: hm read seed Int => String
      hm read seed fd =
        | fd < 0    = hm seed16 (int to str (sys time ms))
        | otherwise =
          s = sys read fd fd 16
          sys close fd -> ()
          hm seed16 s

fn :: hm new seed => String
      hm new seed = hm read seed (sys open mode "/dev/urandom" "r")
```

### 36.4.2. Implementación interna: Slots

Fíjate en cómo `hashmap.ridgun` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: hm slot hash Int => Int
      hm slot hash s = s / 2147483648

-- Slot of key k with hash h: the slot that holds it, or the free slot where it goes.
-- Hot path: the slot is decoded inline (each call costs about 20 ns).
fn :: hm probe Tensor[Int * n] Tensor[String * m] Int String Int Int => Int
      hm probe slots keys cap k h i =
        | slots_(i) == 0                          = i
        | slots_(i) / 2147483648 != h             = hm probe slots keys cap k h ((i + 1) % cap)
        | keys_(slots_(i) % 2147483648) == k      = i
        | otherwise                               = hm probe slots keys cap k h ((i + 1) % cap)

-- First free slot from i; for rehashing, where every key is known to be new.
fn :: hm free Tensor[Int * n] Int Int => Int
      hm free slots cap i =
        | slots_(i) == 0 = i
        | otherwise      = hm free slots cap ((i + 1) % cap)
```

### 36.4.3. Implementación interna: Table

Fíjate en cómo `hashmap.ridgun` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: hashmap empty => HashMap V
      hashmap empty = HashMap [] [] (Tensor[Int * 16]) (Tensor[String * 8]) 16 8 (Tensor[Int * 1]) (hm new seed)

fn :: hm size (HashMap V) => Int
      hm size m = (count m)_(0)

fn :: hm bump Tensor[Int * k] => ()
      hm bump t =
        t_(0) = t_(0) + 1

fn :: hm vt [Tensor[V * n]] => Tensor[V * n]
      hm vt (t:_) = t

-- Copies every used slot to the new table, by its stored hash. Int only.
fn :: hm rehash Tensor[Int * n] Tensor[Int * m] Int Int Int => ()
      hm rehash old new i ocap ncap =
        | i >= ocap     = ()
        | old_(i) == 0  = hm rehash old new (i + 1) ocap ncap
        | otherwise     =
          s = old_(i)
          new_(hm free new ncap ((hm slot hash s) % ncap)) = s
          hm rehash old new (i + 1) ocap ncap

fn :: hm grow slots (HashMap V) => HashMap V
      hm grow slots m =
        ncap = 2 * (cap m)
        ns   = Tensor[Int * ncap]
        hm rehash (slots m) ns 0 (cap m) ncap
        m with slots = ns, cap = ncap

fn :: hm copy Tensor[String * n] Tensor[V * n] Tensor[String * m] Tensor[V * m] Int Int => ()
      hm copy ok ov nk nv i n =
        | i >= n    = ()
        | otherwise =
          nk_(i) = ok_(i)
          nv_(i) = ov_(i)
          hm copy ok ov nk nv (i + 1) n

fn :: hm grow dense (HashMap V) [V] => HashMap V
      hm grow dense m (d:_) =
        nr = 2 * (room m)
        nk = Tensor[String * nr]
        nv = Tensor[V * nr] with d
        hm copy (keys m) (hm vt (vals m)) nk nv 0 (hm size m)
        m with keys = nk, vals = [nv], room = nr

-- Keeps the slot table at most half full and room for one more key.
fn :: hm make room (HashMap V) => HashMap V
      hm make room m = hm room dense (hm room slots m)

fn :: hm room slots (HashMap V) => HashMap V
      hm room slots m =
        | 2 * ((hm size m) + 1) > cap m = hm grow slots m
        | otherwise                      = m

fn :: hm room dense (HashMap V) => HashMap V
      hm room dense m =
        | (hm size m) + 1 > room m = hm grow dense m (fill m)
        | otherwise                  = m

-- The first insert supplies the fill value for the value tensor.
fn :: hm ensure vals (HashMap V) V => HashMap V
      hm ensure vals m v = m with fill = [v], vals = [Tensor[V * (room m)] with v]

-- Puts a new key at the next position and points slot i at it.
fn :: hm insert Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] Int Int String V => ()
      hm insert vt st kt cnt i h k v =
        pos = cnt_(0)
        kt_(pos) = k
        vt_(pos) = v
        st_(i) = h * 2147483648 + pos
        cnt_(0) = pos + 1

-- The hot paths take the record apart once in the clause: each field accessor
-- is a call of about 40 ns.

fn :: hm put go (HashMap V) (HashMap V) String V => HashMap V
      hm put go m (HashMap []   _      _  _  _   _    _   _   ) k v = hashmap put (hm ensure vals m v) k v
      hm put go m (HashMap _ (vt:_) st kt cap room cnt seed) k v =
        | 2 * (cnt_(0) + 1) > cap or cnt_(0) + 1 > room = hashmap put (hm make room m) k v
        | otherwise = hm put at m vt st kt cnt k v (hm hash seed k) cap

fn :: hm put at (HashMap V) Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String V Int Int => HashMap V
      hm put at m vt st kt cnt k v h cap = hm put slot m vt st kt cnt k v h (hm probe st kt cap k h (h % cap))

fn :: hm put slot (HashMap V) Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String V Int Int => HashMap V
      hm put slot m vt st kt cnt k v h i =
        | st_(i) == 0 =
          hm insert vt st kt cnt i h k v
          m
        | otherwise =
          vt_(st_(i) % 2147483648) = v
          m

fn :: hashmap put (HashMap V) String V => HashMap V
      hashmap put m k v = hm put go m m k v

fn :: hm add go (HashMap Int) (HashMap Int) String Int => HashMap Int
      hm add go m (HashMap []   _      _  _  _   _    _   _   ) k d = hashmap add (hm ensure vals m 0) k d
      hm add go m (HashMap _ (vt:_) st kt cap room cnt seed) k d =
        | 2 * (cnt_(0) + 1) > cap or cnt_(0) + 1 > room = hashmap add (hm make room m) k d
        | otherwise = hm add at m vt st kt cnt k d (hm hash seed k) cap

fn :: hm add at (HashMap Int) Tensor[Int * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String Int Int Int => HashMap Int
      hm add at m vt st kt cnt k d h cap = hm add slot m vt st kt cnt k d h (hm probe st kt cap k h (h % cap))

fn :: hm add slot (HashMap Int) Tensor[Int * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String Int Int Int => HashMap Int
      hm add slot m vt st kt cnt k d h i =
        | st_(i) == 0 =
          hm insert vt st kt cnt i h k d
          m
        | otherwise =
          p = st_(i) % 2147483648
          vt_(p) = vt_(p) + d
          m

-- Adds d to the value of k; a missing key starts at 0. For counting.
fn :: hashmap add (HashMap Int) String Int => HashMap Int
      hashmap add m k d = hm add go m m k d

-- Slot content for k: 0 when k is missing, otherwise hash * 2^31 + position.
fn :: hm lookup Tensor[Int * c] Tensor[String * r] Int String Int => Int
      hm lookup st kt cap k h = st_(hm probe st kt cap k h (h % cap))

fn :: hm get at Tensor[V * n] Int V => V
      hm get at vt s d =
        | s == 0    = d
        | otherwise = vt_(s % 2147483648)

-- The value of k, or d when k is missing.
fn :: hashmap get (HashMap V) String V => V
      hashmap get (HashMap _ []     _  _  _   _ _   _   ) k d = d
      hashmap get (HashMap _ (vt:_) st kt cap _ _   seed) k d = hm get at vt (hm lookup st kt cap k (hm hash seed k)) d

fn :: hashmap has (HashMap V) String => Bool
      hashmap has (HashMap _ []     _  _  _   _ _ _   ) k = False
      hashmap has (HashMap _ (vt:_) st kt cap _ _ seed) k = hm lookup st kt cap k (hm hash seed k) != 0

fn :: hashmap size (HashMap V) => Int
      hashmap size m = hm size m

fn :: hm pairs loop Tensor[String * n] Tensor[V * n] Int [String V] => [String V]
      hm pairs loop ks vt i acc =
        | i < 0     = acc
        | otherwise = hm pairs loop ks vt (i - 1) ([(ks_(i), vt_(i))] :: acc)

-- Every (key, value) pair, in the order the keys were first inserted.
fn :: hashmap pairs (HashMap V) => [String V]
      hashmap pairs m =
        | hm size m == 0 = []
        | otherwise      = hm pairs loop (keys m) (hm vt (vals m)) ((hm size m) - 1) []
```

---

## 36.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `hashmap`

- **Garantía algorítmica y de seguridad**: El mapa se actualiza in situ y crece duplicando su tamaño, de modo que `n` inserciones cuestan $O(n)$ en total; usa siempre el mapa que devuelve una operación (`ADR-0009`). Una semilla aleatoria por mapa impide que un atacante elija claves que colisionen.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/hashmap.ridgun` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test hashmap.ridgun`.

### Las 5 Reglas de Oro al programar con `hashmap`

1. **Declara `import hashmap` al inicio del archivo** y llama a sus funciones con espacios, tal como están declaradas, para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `hashmap` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `hashmap` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `hashmap` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 37** pasaremos a explorar en profundidad la lib **`tls`** (La lib `tls` — Cliente TLS 1.3 y TLS 1.2, Validación de Cadenas X.509 y Verificación del Nombre de Host).
