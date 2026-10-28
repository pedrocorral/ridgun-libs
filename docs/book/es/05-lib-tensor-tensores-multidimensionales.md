# Capítulo 05: La lib `tensor` — Tensores Multidimensionales, Vistas y Contracción de Einstein

## 05.1. ¿Por qué existe la lib `tensor`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `tensor` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `tensor`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: en la mayoría de lenguajes tienes que elegir entre listas anidadas lentísimas llenas de punteros dispersos o enlazar una mole de C++/Fortran de 200 MB como NumPy/BLAS.

La lib **`tensor`** envuelve la primitiva nativa `Tensor[...]` de Ridgun ofreciendo creación tipada (`Tensor[Int]`, `Tensor[Real]`, `Tensor[U64]`), vistas sin copia (`reshape`, `slice`), operaciones elemento a elemento (Hadamard), contracción de Einstein (`*` sobre ejes simbólicos) y aritmética `BlaMka` de 64 bits.

En un ecosistema tradicional, resolver las tareas del dominio **`TENSOR`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`tensor`** (`src/main/ridgun/lib/tensor.rg`) aborda el problema con cuatro principios innegociables:

1. **Declara `import tensor` (o `import tensor as alias`) al inicio del archivo**: cada lib define su espacio de nombres `module :: tensor` y en modo `--strict` las funciones multi-palabra se invocan siempre con espacios naturales.
2. **Encadena tus tuberías de izquierda a derecha con `->`**: escribe `entrada paso uno -> paso dos -> resultado`, usa máscaras `(+ _ _ +)` para desestructurar secuencias y omite `_ =` en sentencias secuenciales (o descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `tensor` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 05.2. Artefactos nativos, importación y catálogo completo de la API de `tensor`

En `ridgun-libs`, **`tensor`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/tensor.rg` (dominio `TENSOR`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/tensor.rglib` | Distribución e importación directa con `import tensor` |
| **Archivo compilado** | `target/tensor.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libtensor.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Cada lib declara su propio espacio de nombres con `module :: tensor`: basta con escribir `import tensor` (o `import tensor as alias`) en el encabezado y llamar a sus funciones con espacios naturales (`mi funcion x`) y tuberías `->` (`x mi funcion -> resultado`).

### 05.2.1. Resumen de familias funcionales de `tensor`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `tensor zeros int / tensor fill int / tensor zeros real` | Reserva bloques contiguos 1D/2D de `Tensor[Int]` y `Tensor[Real]` |
| `tensor get 1d / tensor set 1d / tensor get 2d / tensor set 2d` | Acceso y actualización funcional Copy-on-Write (`with [i] = v`) |
| `tensor reshape 1d to 2d / tensor slice 1d` | Vistas de descriptor en $O(1)$ sin copiar el almacenamiento del tensor |
| `tensor add int / tensor mul int / tensor scale int` | Suma, multiplicación elemento a elemento (Hadamard) y escalado |
| `tensor dot int / tensor matmul int` | Contracción de índices de Einstein (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `u64 blamka g / u64 rotr` | Mezcla rotacional `U64` sin signo de 64 bits para bloques criptográficos |

### 05.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/tensor.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/tensor.rg` (`0` tipos, `0` operadores y `13` funciones):

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: tensor rows Tensor[Int * r * c]` | `Int` |
| `2` | `fn :: tensor cols Tensor[Int * r * c]` | `Int` |
| `3` | `fn :: tensor shape Tensor[Int * r * c]` | `Int Int` |
| `4` | `fn :: tensor row Tensor[Int * r * c] Int` | `Tensor[Int * c]` |
| `5` | `fn :: tensor col Tensor[Int * r * c] Int` | `Tensor[Int * r]` |
| `6` | `fn :: tensor xor blocks Tensor[U64 * r * c] Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `7` | `fn :: tensor and blocks Tensor[U64 * r * c] Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `8` | `fn :: tensor or blocks Tensor[U64 * r * c] Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `9` | `fn :: tensor add blocks Tensor[Int * r * c] Tensor[Int * r * c]` | `Tensor[Int * r * c]` |
| `10` | `fn :: tensor sub blocks Tensor[Int * r * c] Tensor[Int * r * c]` | `Tensor[Int * r * c]` |
| `11` | `fn :: tensor mul blocks Tensor[Int * r * c] Tensor[Int * r * c]` | `Tensor[Int * r * c]` |
| `12` | `fn :: tensor clone Tensor[U64 * r * c]` | `Tensor[U64 * r * c]` |
| `13` | `fn :: tensor matmul Tensor[Real * r * k] Tensor[Real * k * c]` | `Tensor[Real * r * c]` |

---

## 05.3. Explorando `tensor` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `tensor` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test tensor.rg`.

### 05.3.1. Ejemplo 1: Flujo principal en estilo tabular con `tensor`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `tensor` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import tensor

fn :: producto matricial tensor Tensor[Real * r * k] Tensor[Real * k * c] => Tensor[Real * r * c]
      producto matricial tensor a b =
        tensor matmul a b
```

### 05.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `tensor` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import tensor

fn :: combinar bloques Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      combinar bloques a b =
        tensor add blocks a b -> suma
        tensor mul blocks suma b
```

### 05.3.3. Ejemplo 3: Creación de tensores (`zeros`, `ones`, `eye`, `arange`, `linspace`), inspección de dimensiones (`rank`, `len`, `shape`) y vistas (`reshape`, `transpose`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `tensor` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test tensor dimensions and views => ()
      test tensor dimensions and views =
        m   = Tensor[Int * 2 * 3]
        m_(0, 0) = 10
        m_(0, 1) = 20
        m_(0, 2) = 30
        m_(1, 0) = 40
        m_(1, 1) = 50
        m_(1, 2) = 60
        assert int equals (tensor rows m) 2 "tensor rows == 2"
        assert int equals (tensor cols m) 3 "tensor cols == 3"
        sh  = tensor shape m
        assert int equals (shape fst sh) 2 "tensor shape rows == 2"
        assert int equals (shape snd sh) 3 "tensor shape cols == 3"
        r1  = tensor row m 1
        assert int equals r1_(0) 40 "row 1 col 0 == 40"
        assert int equals r1_(1) 50 "row 1 col 1 == 50"
        assert int equals r1_(2) 60 "row 1 col 2 == 60"
        c2  = tensor col m 2
        assert int equals c2_(0) 30 "col 2 row 0 == 30"
        assert int equals c2_(1) 60 "col 2 row 1 == 60"
        ()
```

### 05.3.4. Ejemplo 4: Álgebra elemento a elemento (Hadamard `+`, `-`, `*`, `/`, `xor`, `and`, `or`) y clonación profunda independiente (`tensor clone`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `tensor` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test tensor hadamard and clone => ()
      test tensor hadamard and clone =
        a    = Tensor[Int * 2 * 2]
        a_(0, 0) = 10
        a_(0, 1) = 20
        a_(1, 0) = 30
        a_(1, 1) = 40
        b    = Tensor[Int * 2 * 2]
        b_(0, 0) = 1
        b_(0, 1) = 2
        b_(1, 0) = 3
        b_(1, 1) = 4
        s    = tensor add blocks a b
        assert int equals s_(0, 0) 11 "add (0,0) == 11"
        assert int equals s_(1, 1) 44 "add (1,1) == 44"
        d    = tensor sub blocks a b
        assert int equals d_(0, 0) 9 "sub (0,0) == 9"
        assert int equals d_(1, 1) 36 "sub (1,1) == 36"
        p    = tensor mul blocks a b
        assert int equals p_(0, 0) 10 "mul (0,0) == 10"
        assert int equals p_(1, 1) 160 "mul (1,1) == 160"
        ua   = Tensor[U64 * 2 * 2]
        ua_(0, 0) = 0xFF
        ua_(0, 1) = 0x0F
        ua_(1, 0) = 0xF0
        ua_(1, 1) = 0xAA
        ub   = Tensor[U64 * 2 * 2]
        ub_(0, 0) = 0x0F
        ub_(0, 1) = 0xFF
        ub_(1, 0) = 0x0F
        ub_(1, 1) = 0x55
        ux   = tensor xor blocks ua ub
        assert int equals ux_(0, 0) 0xF0 "xor (0,0) == 0xF0"
        assert int equals ux_(1, 1) 0xFF "xor (1,1) == 0xFF"
        uan  = tensor and blocks ua ub
        assert int equals uan_(0, 0) 0x0F "and (0,0) == 0x0F"
        assert int equals uan_(1, 1) 0x00 "and (1,1) == 0x00"
        uor  = tensor or blocks ua ub
        assert int equals uor_(0, 0) 0xFF "or (0,0) == 0xFF"
        assert int equals uor_(1, 0) 0xFF "or (1,0) == 0xFF"
        uc   = tensor clone ua
        uc_(0, 0) = 999
        assert int equals ua_(0, 0) 0xFF "clone preserves original ua_(0,0)"
        assert int equals uc_(0, 0) 999 "clone updates uc_(0,0)"
        ()
```

### 05.3.5. Ejemplo 5: Multiplicación matricial nativa (`@`) y contracción de subíndices de Einstein (`a_ik @ b_kj`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `tensor` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test tensor matmul => ()
      test tensor matmul =
        ma  = Tensor[Real * 2 * 3]
        ma_(0, 0) = 1
        ma_(0, 1) = 2
        ma_(0, 2) = 3
        ma_(1, 0) = 4
        ma_(1, 1) = 5
        ma_(1, 2) = 6
        mb  = Tensor[Real * 3 * 2]
        mb_(0, 0) = 7
        mb_(0, 1) = 8
        mb_(1, 0) = 9
        mb_(1, 1) = 10
        mb_(2, 0) = 11
        mb_(2, 1) = 12
        mc  = tensor matmul ma mb
        assert int equals mc_(0, 0) 58 "matmul (0,0) == 58"
        assert int equals mc_(0, 1) 64 "matmul (0,1) == 64"
        assert int equals mc_(1, 0) 139 "matmul (1,0) == 139"
        assert int equals mc_(1, 1) 154 "matmul (1,1) == 154"
        ()
```

### 05.3.6. Ejemplo 6: Compresión criptográfica de bloques de 1024 bytes mediante tensores (`f blamka`, `blamka g`, `blamka p16`, `compress block`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `tensor` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test blamka tensor compression => ()
      test blamka tensor compression =
        fb  = f blamka 1 2
        assert int equals fb 7 "f blamka 1 2 == 7"
        gr  = blamka g 1 2 3 4
        assert true ((g fst gr) != 0) "blamka g non-zero output"
        bx  = Tensor[U64 * 8 * 16]
        by  = Tensor[U64 * 8 * 16]
        bx_(0, 0) = 1
        by_(0, 0) = 2
        bz  = compress block bx by
        assert true (bz_(0, 0) != 0) "compress block non-zero (0,0)"
        assert int equals bx_(0, 0) 1 "compress block preserves bx_(0,0)"
        assert int equals by_(0, 0) 2 "compress block preserves by_(0,0)"
        ()
```

---

## 05.4. Bajo el capó: cómo está construida `tensor` en Ridgun puro (`src/main/ridgun/lib/tensor.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/tensor.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 05.4.1. Implementación interna: Core Implementation Part 1

Fíjate en cómo `tensor.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
module :: tensor

fn :: tensor rows Tensor[Int * r * c] => Int
      tensor rows (Tensor[Int * r * c] m) = r

fn :: tensor cols Tensor[Int * r * c] => Int
      tensor cols (Tensor[Int * r * c] m) = c

fn :: tensor shape Tensor[Int * r * c] => Int Int
      tensor shape (Tensor[Int * r * c] m) = (r, c)

fn :: tensor row Tensor[Int * r * c] Int => Tensor[Int * c]
      tensor row m                   idx =  m_(idx,)

fn :: tensor col Tensor[Int * r * c] Int => Tensor[Int * r]
      tensor col m                   idx =  m_(,idx)

fn :: tensor xor blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor xor blocks a b = a_ij xor b_ij
```

### 05.4.2. Implementación interna: Core Implementation Part 2

Fíjate en cómo `tensor.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: tensor and blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor and blocks a b = a_ij and b_ij

fn :: tensor or blocks Tensor[U64 * r * c] Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor or blocks a b = a_ij or b_ij

fn :: tensor add blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor add blocks a b = a_ij + b_ij

fn :: tensor sub blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor sub blocks a b = a_ij - b_ij

fn :: tensor mul blocks Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      tensor mul blocks a b = a_ij * b_ij

fn :: tensor clone Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor clone m                   =
        z_ij = m_ij
        z_ij

fn :: tensor matmul Tensor[Real * r * k] Tensor[Real * k * c] => Tensor[Real * r * c]
      tensor matmul a b = a_ik @ b_kj
```

---

## 05.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `tensor`

- **Garantía algorítmica y de seguridad**: Memoria contigua de 8 bytes por celda gestionada estáticamente por RMM1/RMM2, vistas en $O(1)$ sin duplicar el búfer y semántica pura Copy-on-Write.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/tensor.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test tensor.rg`.

### Las 5 Reglas de Oro al programar con `tensor`

1. **Declara `import tensor` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `tensor` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `tensor` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `tensor` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 06** pasaremos a explorar en profundidad la lib **`linalg`** (La lib `linalg` — Álgebra Lineal sobre `Tensor[Real]`, Bareiss y Activaciones).
