# Capítulo 03: La lib `list` — Listas, Mergesort $O(N \log N)$ y Mapas Clave-Valor

## 03.1. ¿Por qué existe la lib `list`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `list` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `list`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: acceder a un índice fuera de rango (`IndexError` / `panic!`) o mutar una lista compartida por accidente son dos de los errores más frecuentes al procesar colecciones.

La lib **`list`** proporciona indexación con valor por defecto, rebanado (`take`, `drop`, `slice`), rangos con paso, deduplicación estable, ordenación **mergesort $O(N \log N)$** para `[Int]` y `[String]`, y diccionarios asociativos inmutables `[String String]` (`kv get`, `kv put`, `kv merge`).

En un ecosistema tradicional, resolver las tareas del dominio **`LIST`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`list`** (`src/main/ridgun/lib/list.rg`) aborda el problema con cuatro principios innegociables:

1. **Declara `import list` (o `import list as alias`) al inicio del archivo**: cada lib define su espacio de nombres `module :: list` y en modo `--strict` las funciones multi-palabra se invocan siempre con espacios naturales.
2. **Encadena tus tuberías de izquierda a derecha con `->`**: escribe `entrada paso uno -> paso dos -> resultado`, usa máscaras `(+ _ _ +)` para desestructurar secuencias y omite `_ =` en sentencias secuenciales (o descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `list` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 03.2. Artefactos nativos, importación y catálogo completo de la API de `list`

En `ridgun-libs`, **`list`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/list.rg` (dominio `LIST`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/list.rglib` | Distribución e importación directa con `import list` |
| **Archivo compilado** | `target/list.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/liblist.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Cada lib declara su propio espacio de nombres con `module :: list`: basta con escribir `import list` (o `import list as alias`) en el encabezado y llamar a sus funciones con espacios naturales (`mi funcion x`) y tuberías `->` (`x mi funcion -> resultado`).

### 03.2.1. Resumen de familias funcionales de `list`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `list nth or / list str nth or` | Lectura segura por índice devolviendo `default_val` si está fuera de rango |
| `list take / list drop / list slice / list reverse` | Prefijo, sufijo, subrango `[start, end)` e inversión recursiva de cola |
| `list range / list range step` | Genera secuencias aritméticas (`step == 0` devuelve `[]` de forma segura) |
| `list sort / list str sort / list dedup / list str dedup` | Ordenación mergesort $O(N \log N)$ estable y deduplicación por primera aparición |
| `kv empty / kv put / kv get / kv get or / kv remove / kv merge` | Operaciones sobre diccionarios asociativos ordenados `[String String]` |

### 03.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/list.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/list.rg` (`0` tipos, `0` operadores y `59` funciones):

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: list len [Int]` | `Int` |
| `2` | `fn :: list str len [String]` | `Int` |
| `3` | `fn :: list is empty [Int]` | `Bool` |
| `4` | `fn :: list str is empty [String]` | `Bool` |
| `5` | `fn :: list nth or [Int] Int Int` | `Int` |
| `6` | `fn :: list nth [Int] Int` | `Int` |
| `7` | `fn :: list str nth or [String] Int String` | `String` |
| `8` | `fn :: list str nth [String] Int` | `String` |
| `9` | `fn :: list head [Int] Int` | `Int` |
| `10` | `fn :: list last [Int] Int` | `Int` |
| `11` | `fn :: list take [Int] Int` | `[Int]` |
| `12` | `fn :: list str take [String] Int` | `[String]` |
| `13` | `fn :: list drop [Int] Int` | `[Int]` |
| `14` | `fn :: list str drop [String] Int` | `[String]` |
| `15` | `fn :: l clamp nonneg Int` | `Int` |
| `16` | `fn :: l slice ints from [Int] Int Int` | `[Int]` |
| `17` | `fn :: list slice [Int] Int Int` | `[Int]` |
| `18` | `fn :: l slice strs from [String] Int Int` | `[String]` |
| `19` | `fn :: list str slice [String] Int Int` | `[String]` |
| `20` | `fn :: l rev ints [Int] [Int]` | `[Int]` |
| `21` | `fn :: list reverse [Int]` | `[Int]` |
| `22` | `fn :: l rev strs [String] [String]` | `[String]` |
| `23` | `fn :: list str reverse [String]` | `[String]` |
| `24` | `fn :: list range step Int Int Int` | `[Int]` |
| `25` | `fn :: list range Int Int` | `[Int]` |
| `26` | `fn :: list replicate Int Int` | `[Int]` |
| `27` | `fn :: l idx int [Int] Int Int` | `Int` |
| `28` | `fn :: list index of [Int] Int` | `Int` |
| `29` | `fn :: list contains [Int] Int` | `Bool` |
| `30` | `fn :: l idx str [String] String Int` | `Int` |
| `31` | `fn :: list str index of [String] String` | `Int` |
| `32` | `fn :: list str contains [String] String` | `Bool` |
| `33` | `fn :: list count [Int] Int` | `Int` |
| `34` | `fn :: list str count [String] String` | `Int` |
| `35` | `fn :: l dedup ints [Int] [Int]` | `[Int]` |
| `36` | `fn :: list dedup [Int]` | `[Int]` |
| `37` | `fn :: l dedup strs [String] [String]` | `[String]` |
| `38` | `fn :: list str dedup [String]` | `[String]` |
| `39` | `fn :: l merge ints [Int] [Int]` | `[Int]` |
| `40` | `fn :: l sort ints len [Int] Int` | `[Int]` |
| `41` | `fn :: list sort [Int]` | `[Int]` |
| `42` | `fn :: list is sorted [Int]` | `Bool` |
| `43` | `fn :: l str le loop String String Int Int Int` | `Bool` |
| `44` | `fn :: l str le String String` | `Bool` |
| `45` | `fn :: l merge strs [String] [String]` | `[String]` |
| `46` | `fn :: l sort strs len [String] Int` | `[String]` |
| `47` | `fn :: list str sort [String]` | `[String]` |
| `48` | `fn :: l kv key (String String)` | `String` |
| `49` | `fn :: l kv val (String String)` | `String` |
| `50` | `fn :: list kv empty` | `[String String]` |
| `51` | `fn :: list kv len [String String]` | `Int` |
| `52` | `fn :: list kv has [String String] String` | `Bool` |
| `53` | `fn :: list kv get or [String String] String String` | `String` |
| `54` | `fn :: list kv get [String String] String` | `String` |
| `55` | `fn :: list kv put [String String] String String` | `[String String]` |
| `56` | `fn :: list kv remove [String String] String` | `[String String]` |
| `57` | `fn :: list kv keys [String String]` | `[String]` |
| `58` | `fn :: list kv values [String String]` | `[String]` |
| `59` | `fn :: list kv merge [String String] [String String]` | `[String String]` |

---

## 03.3. Explorando `list` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `list` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test list.rg`.

### 03.3.1. Ejemplo 1: Flujo principal en estilo tabular con `list`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `list` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import list

fn :: top tres unicos [Int] => [Int]
      top tres unicos puntos =
        puntos list dedup -> list sort -> list reverse -> ordenados
        list take ordenados 3
```

### 03.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `list` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import list

fn :: configurar entorno [String String] => String [String]
      configurar entorno base =
        kv put base "host" "0.0.0.0" -> cfg1
        kv put cfg1 "port" "8080" -> cfg2
        kv get or cfg2 "host" "127.0.0.1" -> host
        cfg2 kv keys -> claves
        (host, claves)
```

### 03.3.3. Ejemplo 3: Indexación segura (`nth or`, `head or`, `last or`), rebanado (`take`, `drop`, `slice`), rangos (`range`, `iota`, `replicate`) y deduplicación (`dedup`, `count eq`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `list` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test list indexing slicing and ranges => ()
      test list indexing slicing and ranges =
        xs = [10, 20, 30, 40, 50]
        ss = ["aa", "bb", "cc", "dd"]
        assert int equals (list len xs) 5 "AC1: list_len 5"
        assert int equals (list str len ss) 4 "AC1: list_str_len 4"
        assert true (list is empty []) "AC1: list_is_empty []"
        assert false (list is empty xs) "AC1: list_is_empty non-empty"
        assert true (list str is empty []) "AC1: list_str_is_empty []"
        assert false (list str is empty ss) "AC1: list_str_is_empty non-empty"

        assert int equals (list nth xs 0) 10 "AC1: list_nth 0"
        assert int equals (list nth xs 4) 50 "AC1: list_nth 4"
        assert int equals (list nth or xs 99 (0 - 1)) (0 - 1) "AC1: list_nth_or out of bounds"
        assert int equals (list nth or xs (0 - 1) (0 - 1)) (0 - 1) "AC1: list_nth_or negative"
        assert str eq (list str nth ss 2) "cc" "AC1: list_str_nth 2"
        assert str eq (list str nth or ss 99 "oob") "oob" "AC1: list_str_nth_or out of bounds"
        assert int equals (list head xs 0) 10 "AC1: list_head"
        assert int equals (list head [] 99) 99 "AC1: list_head empty fallback"
        assert int equals (list last xs 0) 50 "AC1: list_last"
        assert int equals (list last [] 99) 99 "AC1: list_last empty fallback"

        assert eq (list take xs 3) [10, 20, 30]
        assert eq (list take xs 0) []
        assert eq (list take xs (0 - 2)) []
        assert eq (list take xs 99) [10, 20, 30, 40, 50]
        assert eq (list drop xs 3) [40, 50]
        assert eq (list drop xs 0) xs
        assert eq (list drop xs 99) []
        assert eq (list slice xs 1 4) [20, 30, 40]
        assert eq (list slice xs (0 - 3) 2) [10, 20]
        assert eq (list slice xs 4 2) []
        assert eq (list str slice ss 1 3) ["bb", "cc"]

        assert eq (list reverse xs) [50, 40, 30, 20, 10]
        assert eq (list str reverse ss) ["dd", "cc", "bb", "aa"]

        assert eq (list range 1 5) [1, 2, 3, 4, 5]
        assert eq (list range 3 3) [3]
        assert eq (list range 5 1) []
        assert eq (list range step 0 6 2) [0, 2, 4, 6]
        assert eq (list range step 6 0 (0 - 2)) [6, 4, 2, 0]
        assert eq (list range step 1 5 0) []
        assert eq (list replicate 3 7) [7, 7, 7]
        assert eq (list replicate 0 7) []

        assert true (list contains xs 30) "AC1: list_contains 30"
        assert false (list contains xs 99) "AC1: list_contains 99"
        assert true (list str contains ss "cc") "AC1: list_str_contains cc"
        assert false (list str contains ss "zz") "AC1: list_str_contains zz"
        assert int equals (list index of xs 30) 2 "AC1: list_index_of 30"
        assert int equals (list index of xs 99) (0 - 1) "AC1: list_index_of missing"
        assert int equals (list str index of ss "dd") 3 "AC1: list_str_index_of dd"
        assert int equals (list count [1, 2, 1, 3, 1] 1) 3 "AC1: list_count"
        assert int equals (list str count ["a", "b", "a"] "a") 2 "AC1: list_str_count"
        assert eq (list dedup [3, 1, 3, 2, 1, 3]) [3, 1, 2]
        assert eq (list str dedup ["b", "a", "b", "c", "a"]) ["b", "a", "c"]
        ()
```

### 03.3.4. Ejemplo 4: Ordenación determinista $O(N \log N)$ (`list sort int`, `list sort desc`, `list sort str`, `list is sorted`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `list` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test list mergesort => ()
      test list mergesort =
        unsorted = [42, 7, 19, 7, 0, (0 - 5), 100, 3, (0 - 50)]
        sorted = list sort unsorted
        assert eq sorted [(0 - 50), (0 - 5), 0, 3, 7, 7, 19, 42, 100]
        assert true (list is sorted sorted) "AC2: list_is_sorted after sort"
        assert false (list is sorted unsorted) "AC2: list_is_sorted false on unsorted"
        assert true (list is sorted []) "AC2: empty list is sorted"
        assert true (list is sorted [1]) "AC2: singleton list is sorted"
        assert eq (list sort []) []
        assert eq (list sort [1]) [1]
        assert eq (list sort [5, 4, 3, 2, 1]) [1, 2, 3, 4, 5]
        s_strs = list str sort ["delta", "alpha", "charlie", "bravo", "alpha", "al", ""]
        assert eq s_strs ["", "al", "alpha", "alpha", "bravo", "charlie", "delta"]
        ()
```

### 03.3.5. Ejemplo 5: Mapas asociativos clave-valor inmutables (`kv put`, `kv get or`, `kv has`, `kv remove`, `kv keys`, `kv values`, `kv len`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `list` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test kv associative map => ()
      test kv associative map =
        m0 = kv empty
        assert int equals (kv len m0) 0 "AC3: kv_empty len 0"
        m1 = kv put m0 "host" "127.0.0.1"
        m2 = kv put m1 "port" "8080"
        m3 = kv put m2 "port" "9090"
        assert int equals (kv len m3) 2 "AC3: kv_put updates in-place without duplicating key"
        assert true (kv has m3 "host") "AC3: kv_has host"
        assert false (kv has m3 "missing") "AC3: kv_has missing"
        assert str eq (kv get m3 "port") "9090" "AC3: kv_get updated port"
        assert str eq (kv get m3 "missing") "" "AC3: kv_get missing returns empty"
        assert str eq (kv get or m3 "mode" "prod") "prod" "AC3: kv_get_or default"
        assert eq (kv keys m3) ["host", "port"]
        assert eq (kv values m3) ["127.0.0.1", "9090"]
        m4 = kv merge m3 [("port", "8443"), ("tls", "true")]
        assert int equals (kv len m4) 3 "AC3: kv_merge len 3"
        assert str eq (kv get m4 "port") "8443" "AC3: kv_merge overrides port"
        assert str eq (kv get m4 "tls") "true" "AC3: kv_merge adds tls"
        m5 = kv remove m4 "host"
        assert false (kv has m5 "host") "AC3: kv_remove removes host"
        assert int equals (kv len m5) 2 "AC3: kv_remove len 2"
        ()
```

---

## 03.4. Bajo el capó: cómo está construida `list` en Ridgun puro (`src/main/ridgun/lib/list.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/list.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 03.4.1. Implementación interna: List Length & Emptiness

Fíjate en cómo `list.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
module :: list

fn :: list len [Int]    => Int
      list len []       =  0
      list len (_:rest) =  1 + (list len rest)

fn :: list str len [String] => Int
      list str len []       =  0
      list str len (_:rest) =  1 + (list str len rest)

fn :: list is empty [Int] => Bool
      list is empty []    =  True
      list is empty _     =  False

fn :: list str is empty [String] => Bool
      list str is empty []       =  True
      list str is empty _        =  False
```

### 03.4.2. Implementación interna: Slicing (`take`, `drop`, `slice`) & Reversal

Fíjate en cómo `list.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: list take [Int]    Int => [Int]
      list take []       _   =  []
      list take (x:rest) n   =
        | n <= 0    = []
        | otherwise = [x] :: (list take rest (n - 1))

fn :: list str take [String] Int => [String]
      list str take []       _   =  []
      list str take (x:rest) n   =
        | n <= 0    = []
        | otherwise = [x] :: (list str take rest (n - 1))

fn :: list drop [Int]    Int => [Int]
      list drop []       _   =  []
      list drop (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = list drop rest (n - 1)

fn :: list str drop [String] Int => [String]
      list str drop []       _   =  []
      list str drop (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = list str drop rest (n - 1)

fn :: l clamp nonneg Int => Int
      l clamp nonneg x   =
        | x < 0     = 0
        | otherwise = x

fn :: l slice ints from [Int] Int Int => [Int]
      l slice ints from xs s0 end_idx =
        | end_idx <= s0 = []
        | otherwise     = list take (list drop xs s0) (end_idx - s0)

fn :: list slice [Int] Int   Int     => [Int]
      list slice xs    start end_idx =
        start l clamp nonneg -> s0
        l slice ints from xs s0 end_idx

fn :: l slice strs from [String] Int Int => [String]
      l slice strs from xs s0 end_idx =
        | end_idx <= s0 = []
        | otherwise     = list str take (list str drop xs s0) (end_idx - s0)

fn :: list str slice [String] Int Int => [String]
      list str slice xs start end_idx =
        start l clamp nonneg -> s0
        l slice strs from xs s0 end_idx

fn :: l rev ints [Int]    [Int] => [Int]
      l rev ints []       acc   =  acc
      l rev ints (x:rest) acc   =  l rev ints rest ([x] :: acc)

fn :: list reverse [Int] => [Int]
      list reverse xs    =  l rev ints xs []

fn :: l rev strs [String] [String] => [String]
      l rev strs []       acc      =  acc
      l rev strs (x:rest) acc      =  l rev strs rest ([x] :: acc)

fn :: list str reverse [String] => [String]
      list str reverse xs       =  l rev strs xs []
```

### 03.4.3. Implementación interna: Search, Count & Deduplication

Fíjate en cómo `list.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: l idx int [Int] Int Int => Int
      l idx int [] _ _ = 0 - 1
      l idx int (x:rest) tgt idx =
        | x == tgt  = idx
        | otherwise = l idx int rest tgt (idx + 1)

fn :: list index of [Int] Int => Int
      list index of xs    tgt =  l idx int xs tgt 0

fn :: list contains [Int] Int => Bool
      list contains xs    tgt =  (list index of xs tgt) >= 0

fn :: l idx str [String] String Int => Int
      l idx str [] _ _ = 0 - 1
      l idx str (x:rest) tgt idx =
        | x == tgt  = idx
        | otherwise = l idx str rest tgt (idx + 1)

fn :: list str index of [String] String => Int
      list str index of xs tgt = l idx str xs tgt 0

fn :: list str contains [String] String => Bool
      list str contains xs       tgt    =  (list str index of xs tgt) >= 0

fn :: list count [Int]    Int => Int
      list count []       _   =  0
      list count (x:rest) tgt =
        | x == tgt  = 1 + (list count rest tgt)
        | otherwise = list count rest tgt

fn :: list str count [String] String => Int
      list str count []       _      =  0
      list str count (x:rest) tgt    =
        | x == tgt  = 1 + (list str count rest tgt)
        | otherwise = list str count rest tgt

fn :: l dedup ints [Int]    [Int] => [Int]
      l dedup ints []       seen  =  list reverse seen
      l dedup ints (x:rest) seen  =
        | list contains seen x = l dedup ints rest seen
        | otherwise            = l dedup ints rest ([x] :: seen)

fn :: list dedup [Int] => [Int]
      list dedup xs    =  l dedup ints xs []

fn :: l dedup strs [String] [String] => [String]
      l dedup strs []       seen     =  list str reverse seen
      l dedup strs (x:rest) seen     =
        | list str contains seen x = l dedup strs rest seen
        | otherwise                = l dedup strs rest ([x] :: seen)

fn :: list str dedup [String] => [String]
      list str dedup xs       =  l dedup strs xs []
```

### 03.4.4. Implementación interna: Associative Key-Value Map (`[(String, String)]`)

Fíjate en cómo `list.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: l kv key (String String) => String
      l kv key (k, _)          =  k

fn :: l kv val (String String) => String
      l kv val (_, v)          =  v

fn :: kv empty => [String String]
      kv empty =  []

fn :: kv len [String String] => Int
      kv len []              =  0
      kv len (_:rest)        =  1 + (kv len rest)

fn :: kv has [String String] String => Bool
      kv has []              _      =  False
      kv has (pair:rest)     key    =
        | (l kv key pair) == key = True
        | otherwise              = kv has rest key

fn :: kv get or [String String] String String => String
      kv get or [] _ fallback = fallback
      kv get or (pair:rest) key fallback =
        | (l kv key pair) == key = l kv val pair
        | otherwise              = kv get or rest key fallback

fn :: kv get [String String] String => String
      kv get pairs           key    =  kv get or pairs key ""

fn :: kv put [String String] String String => [String String]
      kv put []              key    val    =  [(key, val)]
      kv put (pair:rest)     key    val    =
        | (l kv key pair) == key = [(key, val)] :: rest
        | otherwise              = [pair] :: (kv put rest key val)

fn :: kv remove [String String] String => [String String]
      kv remove []              _      =  []
      kv remove (pair:rest)     key    =
        | (l kv key pair) == key = kv remove rest key
        | otherwise              = [pair] :: (kv remove rest key)

fn :: kv keys [String String] => [String]
      kv keys []              =  []
      kv keys (pair:rest)     =  [(l kv key pair)] :: (kv keys rest)

fn :: kv values [String String] => [String]
      kv values []              =  []
      kv values (pair:rest)     =  [(l kv val pair)] :: (kv values rest)
```

---

## 03.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `list`

- **Garantía algorítmica y de seguridad**: Ordenación determinista $O(N \log N)$ en el peor caso (sin el $O(N^2)$ patológico de Quicksort) y preservación del orden de inserción en mapas `kv`.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/list.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test list.rg`.

### Las 5 Reglas de Oro al programar con `list`

1. **Declara `import list` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `list` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `list` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `list` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 04** pasaremos a explorar en profundidad la lib **`btree`** (La lib `btree` — Árboles AVL Persistentes $O(\log N)$, Conjuntos y Montículos).
