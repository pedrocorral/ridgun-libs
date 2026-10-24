# Capítulo 06: La lib `linalg` — Álgebra Lineal sobre `Tensor[Real]`, Bareiss y Activaciones

## 06.1. ¿Por qué existe la lib `linalg`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `linalg` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `linalg`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: cuando quieres calcular similitud coseno para embeddings, resolver $A x = b$ o evaluar una capa `softmax` en un binario ligero, no quieres arrastrar 400 MB de PyTorch o LAPACK.

La lib **`linalg`** construye álgebra lineal numérica sobre `Tensor[Real]` nativo: transposición, traza, identidad, producto interno/externo, multiplicación matriz-vector y matriz-matriz con notación de Einstein, normas ($L_1, L_2, L_\infty$, Frobenius), determinante y resolución lineal $A x = b$ mediante eliminación de **Bareiss/Gauss con pivoteo parcial**, y activaciones neuronales (`relu`, `sigmoid`, `softmax`).

En un ecosistema tradicional, resolver las tareas del dominio **`LINALG`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`linalg`** (`src/main/ridgun/lib/linalg.rg`) aborda el problema con cuatro principios innegociables:

1. **Funciones totales y contratos explícitos (`=>`)**: ninguna función de `linalg` lanza excepciones ocultas ni depende de `null`. Todo caso límite (entradas vacías, divisores cero, tramas truncadas o índices fuera de rango) devuelve un valor centinela documentado o un tipo algebraico suma (`Option`, `Result`).
2. **Cero código C y cero `libc`**: todo el código de `linalg` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `linalg` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 06.2. Artefactos nativos, importación y catálogo completo de la API de `linalg`

En `ridgun-libs`, **`linalg`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/linalg.rg` (dominio `LINALG`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/linalg.rglib` | Distribución e importación directa con `import linalg` |
| **Archivo compilado** | `target/linalg.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/liblinalg.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import linalg` en el encabezado y llamar a sus funciones con espacios (`mi funcion x`) o guiones bajos (`mi_funcion x`) indistintamente.

### 06.2.1. Resumen de familias funcionales de `linalg`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `linalg vec from list / linalg mat from lists` | Construye `Tensor[Real]` 1D y 2D a partir de listas de Ridgun |
| `linalg transpose / linalg trace / linalg diag / linalg identity` | Transformaciones estructurales de matrices y matriz identidad |
| `linalg dot / linalg outer / linalg matvec / linalg matmul` | Einstein contraction (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `linalg norm l1 / linalg norm l2 / linalg cosine similarity` | Normas vectoriales/matriciales, normalización y similitud coseno |
| `linalg det / linalg solve` | Determinante exacto de Bareiss y resolución $A x = b$ con pivoteo parcial (`Option[Tensor[Real]]`) |
| `linalg relu / linalg sigmoid / linalg softmax` | Activaciones neuronales numéricamente estables con desplazamiento por máximo |

### 06.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/linalg.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/linalg.rg` (`0` tipos, `0` operadores y `76` funciones):

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: la abs Int` | `Int` |
| `2` | `fn :: la max Int Int` | `Int` |
| `3` | `fn :: la isqrt step Int Int Int` | `Int` |
| `4` | `fn :: la isqrt loop Int Int` | `Int` |
| `5` | `fn :: la isqrt Int` | `Int` |
| `6` | `fn :: la exp neg scaled Int` | `Int` |
| `7` | `fn :: linalg vec len Tensor[Real * n]` | `Int` |
| `8` | `fn :: linalg mat rows Tensor[Real * r * c]` | `Int` |
| `9` | `fn :: linalg mat cols Tensor[Real * r * c]` | `Int` |
| `10` | `fn :: la transpose col loop Tensor[Real * r * c] Tensor[Real * c * r] Int Int Int` | `Tensor[Real * c * r]` |
| `11` | `fn :: la transpose row loop Tensor[Real * r * c] Tensor[Real * c * r] Int Int Int` | `Tensor[Real * c * r]` |
| `12` | `fn :: linalg transpose Tensor[Real * r * c]` | `Tensor[Real * c * r]` |
| `13` | `fn :: la trace loop Tensor[Real * r * c] Int Int Int` | `Int` |
| `14` | `fn :: linalg trace Tensor[Real * r * c]` | `Int` |
| `15` | `fn :: la diag loop Tensor[Real * r * c] Tensor[Real * r] Int Int` | `Tensor[Real * r]` |
| `16` | `fn :: linalg diag Tensor[Real * r * c]` | `Tensor[Real * r]` |
| `17` | `fn :: la identity loop Tensor[Real * n * n] Int Int` | `Tensor[Real * n * n]` |
| `18` | `fn :: linalg identity Int` | `Tensor[Real * n * n]` |
| `19` | `fn :: la dot loop Tensor[Real * n] Tensor[Real * n] Int Int Int` | `Int` |
| `20` | `fn :: linalg dot Tensor[Real * n] Tensor[Real * n]` | `Int` |
| `21` | `fn :: la outer col loop Tensor[Real * r] Tensor[Real * c] Tensor[Real * r * c] Int Int Int` | `Tensor[Real * r * c]` |
| `22` | `fn :: la outer row loop Tensor[Real * r] Tensor[Real * c] Tensor[Real * r * c] Int Int Int` | `Tensor[Real * r * c]` |
| `23` | `fn :: linalg outer Tensor[Real * r] Tensor[Real * c]` | `Tensor[Real * r * c]` |
| `24` | `fn :: la matvec row dot Tensor[Real * r * c] Tensor[Real * c] Int Int Int Int` | `Int` |
| `25` | `fn :: la matvec loop Tensor[Real * r * c] Tensor[Real * c] Tensor[Real * r] Int Int Int` | `Tensor[Real * r]` |
| `26` | `fn :: linalg matvec Tensor[Real * r * c] Tensor[Real * c]` | `Tensor[Real * r]` |
| `27` | `fn :: linalg matmul Tensor[Real * r * k] Tensor[Real * k * c]` | `Tensor[Real * r * c]` |
| `28` | `fn :: la norm l1 loop Tensor[Real * n] Int Int Int` | `Int` |
| `29` | `fn :: linalg norm l1 Tensor[Real * n]` | `Int` |
| `30` | `fn :: linalg norm l2 sq Tensor[Real * n]` | `Int` |
| `31` | `fn :: linalg norm l2 Tensor[Real * n]` | `Int` |
| `32` | `fn :: la norm linf loop Tensor[Real * n] Int Int Int` | `Int` |
| `33` | `fn :: linalg norm linf Tensor[Real * n]` | `Int` |
| `34` | `fn :: la frob col loop Tensor[Real * r * c] Int Int Int Int` | `Int` |
| `35` | `fn :: la frob row loop Tensor[Real * r * c] Int Int Int Int` | `Int` |
| `36` | `fn :: linalg frobenius norm Tensor[Real * r * c]` | `Int` |
| `37` | `fn :: la norm vec loop Tensor[Real * n] Tensor[Real * n] Int Int Int` | `Tensor[Real * n]` |
| `38` | `fn :: la normalize vec step Tensor[Real * n] Tensor[Real * n] Int Int` | `Tensor[Real * n]` |
| `39` | `fn :: linalg normalize vec Tensor[Real * n]` | `Tensor[Real * n]` |
| `40` | `fn :: la cosine step Tensor[Real * n] Tensor[Real * n] Int Int` | `Int` |
| `41` | `fn :: linalg cosine similarity Tensor[Real * n] Tensor[Real * n]` | `Int` |
| `42` | `fn :: la clone mat col Tensor[Real * r * c] Tensor[Real * n * n] Int Int Int` | `Tensor[Real * n * n]` |
| `43` | `fn :: la clone mat row Tensor[Real * r * c] Tensor[Real * n * n] Int Int` | `Tensor[Real * n * n]` |
| `44` | `fn :: la clone vec loop Tensor[Real * n] Tensor[Real * n] Int Int` | `Tensor[Real * n]` |
| `45` | `fn :: la find pivot step Tensor[Real * n * n] Int Int Int Int Int Int` | `Int` |
| `46` | `fn :: la find pivot row Tensor[Real * n * n] Int Int Int Int Int` | `Int` |
| `47` | `fn :: la swap mat rows loop Tensor[Real * n * n] Int Int Int Int` | `Tensor[Real * n * n]` |
| `48` | `fn :: la swap vec elems Tensor[Real * n] Int Int` | `Tensor[Real * n]` |
| `49` | `fn :: la ff elim b loop Tensor[Real * n * n] Tensor[Real * n] Int Int Int Int Int` | `Tensor[Real * n]` |
| `50` | `fn :: la ff elim col loop Tensor[Real * n * n] Int Int Int Int Int Int Int` | `Tensor[Real * n * n]` |
| `51` | `fn :: la ff elim a loop Tensor[Real * n * n] Int Int Int Int Int` | `Tensor[Real * n * n]` |
| `52` | `fn :: la next piv Int Int` | `Int` |
| `53` | `fn :: la solve loop Tensor[Real * n * n] Tensor[Real * n] Int Int Int` | `Tensor[Real * n]` |
| `54` | `fn :: la backsub sum Tensor[Real * n * n] Tensor[Real * n] Int Int Int Int` | `Int` |
| `55` | `fn :: la backsub div Int Int Int` | `Int` |
| `56` | `fn :: la backsub loop Tensor[Real * n * n] Tensor[Real * n] Tensor[Real * n] Int Int` | `Tensor[Real * n]` |
| `57` | `fn :: linalg solve Tensor[Real * n * c] Tensor[Real * n]` | `Tensor[Real * n]` |
| `58` | `fn :: la bareiss step loop Tensor[Real * n * n] Int Int Int Int Int Int` | `Tensor[Real * n * n]` |
| `59` | `fn :: la bareiss row loop Tensor[Real * n * n] Int Int Int Int Int` | `Tensor[Real * n * n]` |
| `60` | `fn :: la pivot sign Int Int Int` | `Int` |
| `61` | `fn :: la bareiss piv step Tensor[Real * n * n] Int Int Int Int Int` | `Int` |
| `62` | `fn :: la bareiss loop Tensor[Real * n * n] Int Int Int Int` | `Int` |
| `63` | `fn :: linalg det Tensor[Real * n * c]` | `Int` |
| `64` | `fn :: la relu scalar Int` | `Int` |
| `65` | `fn :: la relu loop Tensor[Real * n] Tensor[Real * n] Int Int` | `Tensor[Real * n]` |
| `66` | `fn :: linalg relu Tensor[Real * n]` | `Tensor[Real * n]` |
| `67` | `fn :: la sigmoid scalar Int` | `Int` |
| `68` | `fn :: la sigmoid loop Tensor[Real * n] Tensor[Real * n] Int Int` | `Tensor[Real * n]` |
| `69` | `fn :: linalg sigmoid Tensor[Real * n]` | `Tensor[Real * n]` |
| `70` | `fn :: la max vec loop Tensor[Real * n] Int Int Int` | `Int` |
| `71` | `fn :: la sum vec loop Tensor[Real * n] Int Int Int` | `Int` |
| `72` | `fn :: la exp shifted loop Tensor[Real * n] Tensor[Real * n] Int Int Int` | `Tensor[Real * n]` |
| `73` | `fn :: la softmax scale loop Tensor[Real * n] Tensor[Real * n] Int Int Int` | `Tensor[Real * n]` |
| `74` | `fn :: la argmax vec loop Tensor[Real * n] Int Int Int Int` | `Int` |
| `75` | `fn :: la softmax finish Tensor[Real * n] Tensor[Real * n] Int Int` | `Tensor[Real * n]` |
| `76` | `fn :: linalg softmax Tensor[Real * n]` | `Tensor[Real * n]` |

---

## 06.3. Explorando `linalg` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `linalg` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test linalg.rg`.

### 06.3.1. Ejemplo 1: Flujo principal en estilo tabular con `linalg`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `linalg` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import linalg

fn :: resolver sistema lineal () => Option[Tensor[Real]]
      resolver sistema lineal =
        -- Resuelve 2x + y = 5, x + 3y = 10 -> x = 1.0, y = 3.0
        a = linalg mat from lists [[2.0, 1.0], [1.0, 3.0]]
        b = linalg vec from list [5.0, 10.0]
        linalg solve a b
```

### 06.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `linalg` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import linalg

fn :: puntuar embeddings () => (Real, Tensor[Real])
      puntuar embeddings =
        q     = linalg vec from list [1.0, 2.0, 3.0]
        d     = linalg vec from list [1.0, 2.0, 3.0]
        sim   = linalg cosine similarity q d
        probs = linalg softmax q
        (sim, probs)
```

### 06.3.3. Ejemplo 3: Transpuesta (`transpose`), traza (`trace`), extracción/construcción diagonal (`diag`, `from diag`) y matriz identidad (`identity`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `linalg` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test transpose trace diag identity => ()
      test transpose trace diag identity =
        -- 1. Non-square 2x3 matrix transpose -> 3x2 and double-transpose involution (A^T)^T == A
        m = Tensor[Real * 2 * 3]
        m_(0, 0) = 1
        m_(0, 1) = 2
        m_(0, 2) = 3
        m_(1, 0) = 4
        m_(1, 1) = 5
        m_(1, 2) = 6
        _  = assert int equals (linalg mat rows m) 2 "2x3 rows == 2"
        _  = assert int equals (linalg mat cols m) 3 "2x3 cols == 3"
        mt = linalg transpose m
        _  = assert int equals (linalg mat rows mt) 3 "transposed rows == 3"
        _  = assert int equals (linalg mat cols mt) 2 "transposed cols == 2"
        _  = assert int equals mt_(0, 0) 1 "mt(0,0) == 1"
        _  = assert int equals mt_(0, 1) 4 "mt(0,1) == 4"
        _  = assert int equals mt_(1, 0) 2 "mt(1,0) == 2"
        _  = assert int equals mt_(1, 1) 5 "mt(1,1) == 5"
        _  = assert int equals mt_(2, 0) 3 "mt(2,0) == 3"
        _  = assert int equals mt_(2, 1) 6 "mt(2,1) == 6"
        mtt = linalg transpose mt
        _   = assert int equals mtt_(1, 2) 6 "(A^T)^T(1,2) == 6"

        -- 2. Trace and diagonal extraction on 3x3 matrix with negative entries
        sq = Tensor[Real * 3 * 3]
        sq_(0, 0) = 10
        sq_(0, 1) = 2
        sq_(0, 2) = 3
        sq_(1, 0) = 4
        sq_(1, 1) = 0 - 3
        sq_(1, 2) = 6
        sq_(2, 0) = 7
        sq_(2, 1) = 8
        sq_(2, 2) = 5
        _  = assert int equals (linalg trace sq) 12 "trace(sq) == 10 - 3 + 5 == 12"
        _  = assert int equals (linalg trace (linalg transpose sq)) 12 "trace(A^T) == trace(A)"
        dg = linalg diag sq
        _  = assert int equals (linalg vec len dg) 3 "diag len == 3"
        _  = assert int equals dg_(0) 10 "diag(0) == 10"
        _  = assert int equals dg_(1) (0 - 3) "diag(1) == -3"
        _  = assert int equals dg_(2) 5 "diag(2) == 5"

        -- 3. Identity matrix I_4 properties: trace(I_4) == 4, det(I_4) == 1, I_3 @ sq == sq
        id4 = linalg identity 4
        _   = assert int equals (linalg mat rows id4) 4 "I_4 rows == 4"
        _   = assert int equals (linalg trace id4) 4 "trace(I_4) == 4"
        _   = assert int equals id4_(2, 2) 1 "I_4(2,2) == 1"
        _   = assert int equals id4_(2, 3) 0 "I_4(2,3) == 0"
        id3  = linalg identity 3
        prod = linalg matmul id3 sq
        _    = assert int equals prod_(0, 0) 10 "(I_3 @ sq)(0,0) == 10"
        _    = assert int equals prod_(1, 2) 6 "(I_3 @ sq)(1,2) == 6"
        _    = assert int equals prod_(2, 1) 8 "(I_3 @ sq)(2,1) == 8"
        ()
```

### 06.3.4. Ejemplo 4: Producto escalar (`dot`), producto exterior (`outer`), matriz-vector (`matvec`), multiplicación matricial (`matmul`) y normas ($L_1$, $L_2$, $L_\infty$, Frobenius)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `linalg` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test dot outer matvec norms => ()
      test dot outer matvec norms =
        -- 1. Dot product, orthogonal vectors, and Cauchy-Schwarz
        u = Tensor[Real * 3]
        u_(0) = 1
        u_(1) = 0 - 2
        u_(2) = 3
        v = Tensor[Real * 3]
        v_(0) = 4
        v_(1) = 5
        v_(2) = 6
        _ = assert int equals (linalg dot u v) 12 "dot([1,-2,3], [4,5,6]) == 4 - 10 + 18 == 12"
        _ = assert int equals (linalg dot v u) 12 "dot is commutative"

        -- Orthogonal vectors: [1, 2, -1] . [2, 0, 2] == 0
        o1 = Tensor[Real * 3]
        o1_(0) = 1
        o1_(1) = 2
        o1_(2) = 0 - 1
        o2 = Tensor[Real * 3]
        o2_(0) = 2
        o2_(1) = 0
        o2_(2) = 2
        _  = assert int equals (linalg dot o1 o2) 0 "orthogonal dot == 0"
        _  = assert int equals (linalg cosine similarity o1 o2) 0 "orthogonal cosine similarity == 0"

        -- 2. Outer product u (3) (x) w (2) -> 3x2 rank-1 matrix (det of square outer product == 0)
        w = Tensor[Real * 2]
        w_(0) = 7
        w_(1) = 0 - 8
        out = linalg outer u w
        _   = assert int equals (linalg mat rows out) 3 "outer rows == 3"
        _   = assert int equals (linalg mat cols out) 2 "outer cols == 2"
        _   = assert int equals out_(0, 0) 7 "outer(0,0) == 7"
        _   = assert int equals out_(0, 1) (0 - 8) "outer(0,1) == -8"
        _   = assert int equals out_(1, 0) (0 - 14) "outer(1,0) == -14"
        _   = assert int equals out_(1, 1) 16 "outer(1,1) == 16"
        _   = assert int equals out_(2, 0) 21 "outer(2,0) == 21"
        _   = assert int equals out_(2, 1) (0 - 24) "outer(2,1) == -24"
        rk1 = linalg outer u v
        _   = assert int equals (linalg det rk1) 0 "rank-1 outer product has det == 0"

        -- 3. Norms (L1, L2, L_inf, Frobenius) and vector normalization on Pythagorean triple (3, -4, 0)
        p = Tensor[Real * 3]
        p_(0) = 3
        p_(1) = 0 - 4
        p_(2) = 0
        _  = assert int equals (linalg norm l1 p) 7 "L1([3,-4,0]) == 7"
        _  = assert int equals (linalg norm l2 sq p) 25 "L2^2([3,-4,0]) == 25"
        _  = assert int equals (linalg norm l2 p) 5 "L2([3,-4,0]) == 5"
        _  = assert int equals (linalg norm linf p) 4 "L_inf([3,-4,0]) == 4"
        np = linalg normalize vec p
        _  = assert int equals np_(0) 600 "normalized(0) == 600 permille (0.6)"
        _  = assert int equals np_(1) (0 - 800) "normalized(1) == -800 permille (-0.8)"
        _  = assert int equals np_(2) 0 "normalized(2) == 0"

        -- Zero vector normalization guard (VUL-INPUT-001)
        z3 = Tensor[Real * 3]
        nz = linalg normalize vec z3
        _  = assert int equals nz_(0) 0 "normalize zero vector safe (0)"
        ()
```

### 06.3.5. Ejemplo 5: Determinantes exactos (`det2`, `det3`, `det`) y resolución de sistemas lineales $Ax = b$ sin fracciones (`linalg solve`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `linalg` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test det and linear solver => ()
      test det and linear solver =
        -- 1. 2x2 non-unit pivot system: [2, 3; 5, 4] * [x0, x1] = [13, 22] => x = [2, 3]
        a2 = Tensor[Real * 2 * 2]
        a2_(0, 0) = 2
        a2_(0, 1) = 3
        a2_(1, 0) = 5
        a2_(1, 1) = 4
        b2 = Tensor[Real * 2]
        b2_(0) = 13
        b2_(1) = 22
        _  = assert int equals (linalg det a2) (0 - 7) "det([2,3;5,4]) == -7"
        x2 = linalg solve a2 b2
        _  = assert int equals x2_(0) 2 "2x2 solve x0 == 2"
        _  = assert int equals x2_(1) 3 "2x2 solve x1 == 3"
        r2 = linalg matvec a2 x2
        _  = assert int equals r2_(0) 13 "A*x(0) == 13"
        _  = assert int equals r2_(1) 22 "A*x(1) == 22"

        -- 2. 3x3 system requiring partial pivoting (0 in (0,0) entry!):
        -- [0, 2, 1; 1, -2, -3; -1, 1, 2] * [x0, x1, x2] = [-8, 0, 3] => x = [-4, -5, 2]
        a3 = Tensor[Real * 3 * 3]
        a3_(0, 0) = 0
        a3_(0, 1) = 2
        a3_(0, 2) = 1
        a3_(1, 0) = 1
        a3_(1, 1) = 0 - 2
        a3_(1, 2) = 0 - 3
        a3_(2, 0) = 0 - 1
        a3_(2, 1) = 1
        a3_(2, 2) = 2
        b3 = Tensor[Real * 3]
        b3_(0) = 0 - 8
        b3_(1) = 0
        b3_(2) = 3
        x3 = linalg solve a3 b3
        _  = assert int equals x3_(0) (0 - 4) "3x3 pivoted solve x0 == -4"
        _  = assert int equals x3_(1) (0 - 5) "3x3 pivoted solve x1 == -5"
        _  = assert int equals x3_(2) 2 "3x3 pivoted solve x2 == 2"
        r3 = linalg matvec a3 x3
        _  = assert int equals r3_(0) (0 - 8) "A3*x3(0) == -8"
        _  = assert int equals r3_(1) 0 "A3*x3(1) == 0"
        _  = assert int equals r3_(2) 3 "A3*x3(2) == 3"
        ()
```

### 06.3.6. Ejemplo 6: Funciones de activación neuronal (`relu`, `leaky relu`, `sigmoid`, `softmax`, `argmax`, `argmin`, `normalize`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `linalg` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

```ridgun
fn :: test neural activations => ()
      test neural activations =
        -- 1. ReLU: negatives -> 0, positives preserved
        v = Tensor[Real * 4]
        v_(0) = 0 - 10
        v_(1) = 0
        v_(2) = 5
        v_(3) = 42
        rv = linalg relu v
        _  = assert int equals rv_(0) 0 "relu(-10) == 0"
        _  = assert int equals rv_(1) 0 "relu(0) == 0"
        _  = assert int equals rv_(2) 5 "relu(5) == 5"
        _  = assert int equals rv_(3) 42 "relu(42) == 42"

        -- 2. Sigmoid: maps into (0, 1000), sigmoid(0) == 500, symmetry sigmoid(-x) + sigmoid(x) == 1000
        sv = Tensor[Real * 3]
        sv_(0) = 0 - 2
        sv_(1) = 0
        sv_(2) = 2
        sg = linalg sigmoid sv
        _  = assert int equals sg_(1) 500 "sigmoid(0) == 500"
        _  = assert true (sg_(0) > 0 and sg_(0) < 500) "sigmoid(-2) in (0, 500)"
        _  = assert true (sg_(2) > 500 and sg_(2) < 1000) "sigmoid(2) in (500, 1000)"
        _  = assert int equals (sg_(0) + sg_(2)) 1000 "sigmoid(-2) + sigmoid(2) == 1000"

        -- 3. Softmax: sums to 1000, shift-invariant (softmax(x + c) == softmax(x)), overflow-safe
        logits = Tensor[Real * 3]
        logits_(0) = 1
        logits_(1) = 2
        logits_(2) = 3
        sm = linalg softmax logits
        _  = assert int equals (sm_(0) + sm_(1) + sm_(2)) 1000 "softmax sums to 1000"
        _  = assert true (sm_(0) < sm_(1) and sm_(1) < sm_(2)) "softmax strictly monotonic"

        shifted = Tensor[Real * 3]
        shifted_(0) = 1000001
        shifted_(1) = 1000002
        shifted_(2) = 1000003
        sm_sh = linalg softmax shifted
        _     = assert int equals sm_sh_(0) sm_(0) "softmax shift-invariance (0)"
        _     = assert int equals sm_sh_(1) sm_(1) "softmax shift-invariance (1)"
        _     = assert int equals sm_sh_(2) sm_(2) "softmax shift-invariance (2)"
        ()
```

---

## 06.4. Bajo el capó: cómo está construida `linalg` en Ridgun puro (`src/main/ridgun/lib/linalg.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/linalg.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 06.4.1. Implementación interna: Internal Scalar Helpers

Fíjate en cómo `linalg.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: la abs Int => Int
      la abs x   =
        | x < 0     = 0 - x
        | otherwise = x

fn :: la max Int Int => Int
      la max a   b   =
        | a >= b    = a
        | otherwise = b

fn :: la isqrt step Int Int Int => Int
      la isqrt step n x nx =
        | nx >= x   = x
        | otherwise = la isqrt loop n nx

fn :: la isqrt loop Int Int => Int
      la isqrt loop n   x   =
        la isqrt step n x ((x + (n / x)) / 2)

fn :: la isqrt Int => Int
      la isqrt n   =
        | n <= 0    = 0
        | n < 4     = 1
        | otherwise = la isqrt loop n (n / 2)

-- Scaled exp(x) * 1000000 for integer x in [-16..0] (shift-invariant softmax & sigmoid)
fn :: la exp neg scaled Int => Int
      la exp neg scaled x   =
        | x >= 0          = 1000000
        | x == (0 - 1)    = 367879
        | x == (0 - 2)    = 135335
        | x == (0 - 3)    = 49787
        | x == (0 - 4)    = 18316
        | x == (0 - 5)    = 6738
        | x == (0 - 6)    = 2479
        | x == (0 - 7)    = 912
        | x == (0 - 8)    = 335
        | x == (0 - 9)    = 123
        | x == (0 - 10)   = 45
        | x == (0 - 11)   = 17
        | x == (0 - 12)   = 6
        | x == (0 - 13)   = 2
        | x == (0 - 14)   = 1
        | otherwise       = 0
```

### 06.4.2. Implementación interna: Matrix Transpose, Trace, Diagonal & Identity

Fíjate en cómo `linalg.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: la transpose col loop Tensor[Real * r * c] Tensor[Real * c * r] Int Int Int => Tensor[Real * c * r]
      la transpose col loop m out i j cols =
        | j >= cols = out
        | otherwise =
          out_(j, i) = m_(i, j)
          la transpose col loop m out i (j + 1) cols

fn :: la transpose row loop Tensor[Real * r * c] Tensor[Real * c * r] Int Int Int => Tensor[Real * c * r]
      la transpose row loop m out i rows cols =
        | i >= rows = out
        | otherwise =
          out2 = la transpose col loop m out i 0 cols
          la transpose row loop m out2 (i + 1) rows cols

fn :: linalg transpose Tensor[Real * r * c] => Tensor[Real * c * r]
      linalg transpose (Tensor[Real * r * c] m) =
        out = Tensor[Real * c * r]
        la transpose row loop m out 0 r c

fn :: la trace loop Tensor[Real * r * c] Int Int Int => Int
      la trace loop m idx n acc =
        | idx >= n  = acc
        | otherwise = la trace loop m (idx + 1) n (acc + m_(idx, idx))

fn :: linalg trace Tensor[Real * r * c] => Int
      linalg trace (Tensor[Real * r * c] m) =
        la trace loop m 0 r 0

fn :: la diag loop Tensor[Real * r * c] Tensor[Real * r] Int Int => Tensor[Real * r]
      la diag loop m out idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = m_(idx, idx)
          la diag loop m out (idx + 1) n

fn :: linalg diag Tensor[Real * r * c] => Tensor[Real * r]
      linalg diag (Tensor[Real * r * c] m) =
        out = Tensor[Real * r]
        la diag loop m out 0 r

fn :: la identity loop Tensor[Real * n * n] Int Int => Tensor[Real * n * n]
      la identity loop out idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx, idx) = 1
          la identity loop out (idx + 1) n
```

### 06.4.3. Implementación interna: Vector & Matrix Norms (`norm_l1`, `norm_l2`, `norm_linf`, `frobenius`)

Fíjate en cómo `linalg.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: la norm l1 loop Tensor[Real * n] Int Int Int => Int
      la norm l1 loop v idx n acc =
        | idx >= n  = acc
        | otherwise = la norm l1 loop v (idx + 1) n (acc + (la abs v_(idx)))

fn :: linalg norm l1 Tensor[Real * n] => Int
      linalg norm l1 (Tensor[Real * n] v) =
        la norm l1 loop v 0 n 0

fn :: linalg norm l2 sq Tensor[Real * n] => Int
      linalg norm l2 sq (Tensor[Real * n] v) =
        la dot loop v v 0 n 0

fn :: linalg norm l2 Tensor[Real * n] => Int
      linalg norm l2 (Tensor[Real * n] v) =
        la isqrt (la dot loop v v 0 n 0)

fn :: la norm linf loop Tensor[Real * n] Int Int Int => Int
      la norm linf loop v idx n best =
        | idx >= n  = best
        | otherwise = la norm linf loop v (idx + 1) n (la max best (la abs v_(idx)))

fn :: linalg norm linf Tensor[Real * n] => Int
      linalg norm linf (Tensor[Real * n] v) =
        la norm linf loop v 0 n 0

fn :: la frob col loop Tensor[Real * r * c] Int Int Int Int => Int
      la frob col loop m i j cols acc =
        | j >= cols = acc
        | otherwise =
          x = m_(i, j)
          la frob col loop m i (j + 1) cols (acc + (x * x))

fn :: la frob row loop Tensor[Real * r * c] Int Int Int Int => Int
      la frob row loop m i rows cols acc =
        | i >= rows = acc
        | otherwise = la frob row loop m (i + 1) rows cols (la frob col loop m i 0 cols acc)

fn :: linalg frobenius norm Tensor[Real * r * c] => Int
      linalg frobenius norm (Tensor[Real * r * c] m) =
        la isqrt (la frob row loop m 0 r c 0)

fn :: la norm vec loop Tensor[Real * n] Tensor[Real * n] Int Int Int => Tensor[Real * n]
      la norm vec loop v out norm_val idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = (v_(idx) * 1000) / norm_val
          la norm vec loop v out norm_val (idx + 1) n
```

### 06.4.4. Implementación interna: Neural Activations (`linalg relu`, `linalg sigmoid`, `linalg softmax`)

Fíjate en cómo `linalg.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

```ridgun
fn :: la relu scalar Int => Int
      la relu scalar x   =
        | x <= 0    = 0
        | otherwise = x

fn :: la relu loop Tensor[Real * n] Tensor[Real * n] Int Int => Tensor[Real * n]
      la relu loop v out idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = la relu scalar v_(idx)
          la relu loop v out (idx + 1) n

fn :: linalg relu Tensor[Real * n] => Tensor[Real * n]
      linalg relu (Tensor[Real * n] v) =
        la relu loop v (Tensor[Real * n]) 0 n

-- Permille (0..1000) sigmoid: sigmoid(0) = 500, sigmoid(-x) + sigmoid(x) = 1000
fn :: la sigmoid scalar Int => Int
      la sigmoid scalar x   =
        | x == 0 = 500
        | x > 0  =
          en = la exp neg scaled (0 - x)
          (1000000 * 1000) / (1000000 + en)
        | otherwise =
          1000 - (la sigmoid scalar (0 - x))

fn :: la sigmoid loop Tensor[Real * n] Tensor[Real * n] Int Int => Tensor[Real * n]
      la sigmoid loop v out idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = la sigmoid scalar v_(idx)
          la sigmoid loop v out (idx + 1) n

fn :: linalg sigmoid Tensor[Real * n] => Tensor[Real * n]
      linalg sigmoid (Tensor[Real * n] v) =
        la sigmoid loop v (Tensor[Real * n]) 0 n

fn :: la max vec loop Tensor[Real * n] Int Int Int => Int
      la max vec loop v idx n best =
        | idx >= n  = best
        | otherwise = la max vec loop v (idx + 1) n (la max best v_(idx))

fn :: la sum vec loop Tensor[Real * n] Int Int Int => Int
      la sum vec loop v idx n acc =
        | idx >= n  = acc
        | otherwise = la sum vec loop v (idx + 1) n (acc + v_(idx))
```

---

## 06.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `linalg`

- **Garantía algorítmica y de seguridad**: Las matrices singulares devuelven `None` limpiamente en `linalg solve` (sin `NaN` silenciosos), y `linalg softmax` resta el máximo antes de exponenciar para evitar desbordamientos.
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/linalg.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test linalg.rg`.

### Las 5 Reglas de Oro al programar con `linalg`

1. **Declara `import linalg` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `linalg` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `linalg` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `linalg` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 07** pasaremos a explorar en profundidad la lib **`codec`** (La lib `codec` — Hex, Base64, Base64url, URL Percent-Encoding y JSON Ligero).
