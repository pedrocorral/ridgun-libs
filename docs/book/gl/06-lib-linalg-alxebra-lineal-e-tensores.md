# Capítulo 06: A lib `linalg` — Álxebra Lineal sobre `Tensor[Real]`, Bareiss e Activacións

## 06.1. Por que existe a lib `linalg`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `linalg` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `linalg`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: cando queres calcular similitude coseno para embeddings, resolver $A x = b$ ou avaliar unha capa `softmax` nun binario lixeiro, non queres arrastrar 400 MB de PyTorch ou LAPACK.

A lib **`linalg`** constrúe álxebra lineal numérica sobre `Tensor[Real]` nativo: transposición, traza, identidade, produto interno/externo, multiplicación matriz-vector e matriz-matriz con notación de Einstein, normas ($L_1, L_2, L_\infty$, Frobenius), determinante e resolución lineal $A x = b$ mediante eliminación de **Bareiss/Gauss con pivoteo parcial**, e activacións neuronais (`relu`, `sigmoid`, `softmax`).

Nun ecosistema tradicional, resolver as tarefas do dominio **`LINALG`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`linalg`** (`src/main/ridgun/lib/linalg.rg`) aborda o problema con catro principios innegociables:

1. **Declara `import linalg` (ou `import linalg as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: linalg` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `linalg` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 06.2. Artefactos nativos, importación e catálogo completo da API de `linalg`

En `ridgun-libs`, **`linalg`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/linalg.rg` (dominio `LINALG`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/linalg.rglib` | Distribución e importación directa con `import linalg` |
| **Ficheiro compilado** | `target/linalg.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/liblinalg.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Cada lib declara o seu propio espazo de nomes con `module :: linalg`: abonda con escribir `import linalg` (ou `import linalg as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 06.2.1. Resumo de familias funcionais de `linalg`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `linalg vec from list / linalg mat from lists` | Constrúe `Tensor[Real]` 1D e 2D a partir de listas de Ridgun |
| `linalg transpose / linalg trace / linalg diag / linalg identity` | Transformacións estruturais de matrices e matriz identidade |
| `linalg dot / linalg outer / linalg matvec / linalg matmul` | Einstein contraction (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `linalg norm l1 / linalg norm l2 / linalg cosine similarity` | Normas vectoriais/matriciais, normalización e similitude coseno |
| `linalg det / linalg solve` | Determinante exacto de Bareiss e resolución $A x = b$ con pivoteo parcial (`Option[Tensor[Real]]`) |
| `linalg relu / linalg sigmoid / linalg softmax` | Activacións neuronais numericamente estables con desprazamento polo máximo |

### 06.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/linalg.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/linalg.rg` (`0` tipos, `0` operadores e `76` funcións):

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 06.3. Explorando `linalg` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `linalg` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test linalg.rg`.

### 06.3.1. Exemplo 1: Fluxo principal en estilo tabular con `linalg`

Observa como en Ridgun os signos `=` e os pasos de transformación con `linalg` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import linalg

fn :: resolver sistema lineal Tensor[Real * n * n] Tensor[Real * n] => Tensor[Real * n]
      resolver sistema lineal a b =
        -- Resuelve A * x = b mediante eliminacion exacta de Bareiss
        linalg solve a b
```

### 06.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `linalg` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import linalg

fn :: puntuar embeddings Tensor[Real * n] Tensor[Real * n] => Int Tensor[Real * n]
      puntuar embeddings q d =
        linalg cosine similarity q d -> sim
        q linalg softmax -> probs
        (sim, probs)
```

### 06.3.3. Exemplo 3: Transposta (`transpose`), traza (`trace`), extracción/construción diagonal (`diag`, `from diag`) e matriz identidade (`identity`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `linalg` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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
        assert int equals (linalg mat rows m) 2 "2x3 rows == 2"
        assert int equals (linalg mat cols m) 3 "2x3 cols == 3"
        mt = linalg transpose m
        assert int equals (linalg mat rows mt) 3 "transposed rows == 3"
        assert int equals (linalg mat cols mt) 2 "transposed cols == 2"
        assert int equals mt_(0, 0) 1 "mt(0,0) == 1"
        assert int equals mt_(0, 1) 4 "mt(0,1) == 4"
        assert int equals mt_(1, 0) 2 "mt(1,0) == 2"
        assert int equals mt_(1, 1) 5 "mt(1,1) == 5"
        assert int equals mt_(2, 0) 3 "mt(2,0) == 3"
        assert int equals mt_(2, 1) 6 "mt(2,1) == 6"
        mtt = linalg transpose mt
        assert int equals mtt_(1, 2) 6 "(A^T)^T(1,2) == 6"

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
        assert int equals (linalg trace sq) 12 "trace(sq) == 10 - 3 + 5 == 12"
        assert int equals (linalg trace (linalg transpose sq)) 12 "trace(A^T) == trace(A)"
        dg = linalg diag sq
        assert int equals (linalg vec len dg) 3 "diag len == 3"
        assert int equals dg_(0) 10 "diag(0) == 10"
        assert int equals dg_(1) (0 - 3) "diag(1) == -3"
        assert int equals dg_(2) 5 "diag(2) == 5"

        -- 3. Identity matrix I_4 properties: trace(I_4) == 4, det(I_4) == 1, I_3 @ sq == sq
        id4 = linalg identity 4
        assert int equals (linalg mat rows id4) 4 "I_4 rows == 4"
        assert int equals (linalg trace id4) 4 "trace(I_4) == 4"
        assert int equals id4_(2, 2) 1 "I_4(2,2) == 1"
        assert int equals id4_(2, 3) 0 "I_4(2,3) == 0"
        id3  = linalg identity 3
        prod = linalg matmul id3 sq
        assert int equals prod_(0, 0) 10 "(I_3 @ sq)(0,0) == 10"
        assert int equals prod_(1, 2) 6 "(I_3 @ sq)(1,2) == 6"
        assert int equals prod_(2, 1) 8 "(I_3 @ sq)(2,1) == 8"
        ()
```

### 06.3.4. Exemplo 4: Produto escalar (`dot`), produto exterior (`outer`), matriz-vector (`matvec`), multiplicación matricial (`matmul`) e normas ($L_1$, $L_2$, $L_\infty$, Frobenius)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `linalg` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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
        assert int equals (linalg dot u v) 12 "dot([1,-2,3], [4,5,6]) == 4 - 10 + 18 == 12"
        assert int equals (linalg dot v u) 12 "dot is commutative"

        -- Orthogonal vectors: [1, 2, -1] . [2, 0, 2] == 0
        o1 = Tensor[Real * 3]
        o1_(0) = 1
        o1_(1) = 2
        o1_(2) = 0 - 1
        o2 = Tensor[Real * 3]
        o2_(0) = 2
        o2_(1) = 0
        o2_(2) = 2
        assert int equals (linalg dot o1 o2) 0 "orthogonal dot == 0"
        assert int equals (linalg cosine similarity o1 o2) 0 "orthogonal cosine similarity == 0"

        -- 2. Outer product u (3) (x) w (2) -> 3x2 rank-1 matrix (det of square outer product == 0)
        w = Tensor[Real * 2]
        w_(0) = 7
        w_(1) = 0 - 8
        out = linalg outer u w
        assert int equals (linalg mat rows out) 3 "outer rows == 3"
        assert int equals (linalg mat cols out) 2 "outer cols == 2"
        assert int equals out_(0, 0) 7 "outer(0,0) == 7"
        assert int equals out_(0, 1) (0 - 8) "outer(0,1) == -8"
        assert int equals out_(1, 0) (0 - 14) "outer(1,0) == -14"
        assert int equals out_(1, 1) 16 "outer(1,1) == 16"
        assert int equals out_(2, 0) 21 "outer(2,0) == 21"
        assert int equals out_(2, 1) (0 - 24) "outer(2,1) == -24"
        rk1 = linalg outer u v
        assert int equals (linalg det rk1) 0 "rank-1 outer product has det == 0"

        -- 3. Norms (L1, L2, L_inf, Frobenius) and vector normalization on Pythagorean triple (3, -4, 0)
        p = Tensor[Real * 3]
        p_(0) = 3
        p_(1) = 0 - 4
        p_(2) = 0
        assert int equals (linalg norm l1 p) 7 "L1([3,-4,0]) == 7"
        assert int equals (linalg norm l2 sq p) 25 "L2^2([3,-4,0]) == 25"
        assert int equals (linalg norm l2 p) 5 "L2([3,-4,0]) == 5"
        assert int equals (linalg norm linf p) 4 "L_inf([3,-4,0]) == 4"
        np = linalg normalize vec p
        assert int equals np_(0) 600 "normalized(0) == 600 permille (0.6)"
        assert int equals np_(1) (0 - 800) "normalized(1) == -800 permille (-0.8)"
        assert int equals np_(2) 0 "normalized(2) == 0"

        -- Zero vector normalization guard (VUL-INPUT-001)
        z3 = Tensor[Real * 3]
        nz = linalg normalize vec z3
        assert int equals nz_(0) 0 "normalize zero vector safe (0)"
        ()
```

### 06.3.5. Exemplo 5: Determinantes exactos (`det2`, `det3`, `det`) e resolución de sistemas lineais $Ax = b$ sen fraccións (`linalg solve`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `linalg` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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
        assert int equals (linalg det a2) (0 - 7) "det([2,3;5,4]) == -7"
        x2 = linalg solve a2 b2
        assert int equals x2_(0) 2 "2x2 solve x0 == 2"
        assert int equals x2_(1) 3 "2x2 solve x1 == 3"
        r2 = linalg matvec a2 x2
        assert int equals r2_(0) 13 "A*x(0) == 13"
        assert int equals r2_(1) 22 "A*x(1) == 22"

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
        assert int equals x3_(0) (0 - 4) "3x3 pivoted solve x0 == -4"
        assert int equals x3_(1) (0 - 5) "3x3 pivoted solve x1 == -5"
        assert int equals x3_(2) 2 "3x3 pivoted solve x2 == 2"
        r3 = linalg matvec a3 x3
        assert int equals r3_(0) (0 - 8) "A3*x3(0) == -8"
        assert int equals r3_(1) 0 "A3*x3(1) == 0"
        assert int equals r3_(2) 3 "A3*x3(2) == 3"
        ()
```

### 06.3.6. Exemplo 6: Funcións de activación neuronal (`relu`, `leaky relu`, `sigmoid`, `softmax`, `argmax`, `argmin`, `normalize`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `linalg` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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
        assert int equals rv_(0) 0 "relu(-10) == 0"
        assert int equals rv_(1) 0 "relu(0) == 0"
        assert int equals rv_(2) 5 "relu(5) == 5"
        assert int equals rv_(3) 42 "relu(42) == 42"

        -- 2. Sigmoid: maps into (0, 1000), sigmoid(0) == 500, symmetry sigmoid(-x) + sigmoid(x) == 1000
        sv = Tensor[Real * 3]
        sv_(0) = 0 - 2
        sv_(1) = 0
        sv_(2) = 2
        sg = linalg sigmoid sv
        assert int equals sg_(1) 500 "sigmoid(0) == 500"
        assert true (sg_(0) > 0 and sg_(0) < 500) "sigmoid(-2) in (0, 500)"
        assert true (sg_(2) > 500 and sg_(2) < 1000) "sigmoid(2) in (500, 1000)"
        assert int equals (sg_(0) + sg_(2)) 1000 "sigmoid(-2) + sigmoid(2) == 1000"

        -- 3. Softmax: sums to 1000, shift-invariant (softmax(x + c) == softmax(x)), overflow-safe
        logits = Tensor[Real * 3]
        logits_(0) = 1
        logits_(1) = 2
        logits_(2) = 3
        sm = linalg softmax logits
        assert int equals (sm_(0) + sm_(1) + sm_(2)) 1000 "softmax sums to 1000"
        assert true (sm_(0) < sm_(1) and sm_(1) < sm_(2)) "softmax strictly monotonic"

        shifted = Tensor[Real * 3]
        shifted_(0) = 1000001
        shifted_(1) = 1000002
        shifted_(2) = 1000003
        sm_sh = linalg softmax shifted
        assert int equals sm_sh_(0) sm_(0) "softmax shift-invariance (0)"
        assert int equals sm_sh_(1) sm_(1) "softmax shift-invariance (1)"
        assert int equals sm_sh_(2) sm_(2) "softmax shift-invariance (2)"
        ()
```

---

## 06.4. Baixo o capó: como está construída `linalg` en Ridgun puro (`src/main/ridgun/lib/linalg.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/linalg.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 06.4.1. Implementación interna: Internal Scalar Helpers

Fíxate en como `linalg.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
module :: linalg

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

Fíxate en como `linalg.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

fn :: linalg identity Int => Tensor[Real * n * n]
      linalg identity dim =
        la max 1 dim -> n
        out = Tensor[Real * n * n]
        la identity loop out 0 n
```

### 06.4.3. Implementación interna: Vector & Matrix Norms (`norm_l1`, `norm_l2`, `norm_linf`, `frobenius`)

Fíxate en como `linalg.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

fn :: la normalize vec step Tensor[Real * n] Tensor[Real * n] Int Int => Tensor[Real * n]
      la normalize vec step v out norm_value n =
        | norm_value <= 0 = out
        | otherwise       = la norm vec loop v out norm_value 0 n

fn :: linalg normalize vec Tensor[Real * n] => Tensor[Real * n]
      linalg normalize vec (Tensor[Real * n] v) =
        la normalize vec step v (Tensor[Real * n]) (linalg norm l2 v) n

fn :: la cosine step Tensor[Real * n] Tensor[Real * n] Int Int => Int
      la cosine step a b na nb =
        | na <= 0 or nb <= 0 = 0
        | otherwise          = ((linalg dot a b) * 1000) / (na * nb)

fn :: linalg cosine similarity Tensor[Real * n] Tensor[Real * n] => Int
      linalg cosine similarity (Tensor[Real * n] a) (Tensor[Real * n] b) =
        la cosine step a b (linalg norm l2 a) (linalg norm l2 b)
```

### 06.4.4. Implementación interna: Neural Activations (`linalg relu`, `linalg sigmoid`, `linalg softmax`)

Fíxate en como `linalg.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

fn :: la exp shifted loop Tensor[Real * n] Tensor[Real * n] Int Int Int => Tensor[Real * n]
      la exp shifted loop v out max_val idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = la exp neg scaled (v_(idx) - max_val)
          la exp shifted loop v out max_val (idx + 1) n

fn :: la softmax scale loop Tensor[Real * n] Tensor[Real * n] Int Int Int => Tensor[Real * n]
      la softmax scale loop exps out tot idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = (exps_(idx) * 1000) / tot
          la softmax scale loop exps out tot (idx + 1) n

fn :: la argmax vec loop Tensor[Real * n] Int Int Int Int => Int
      la argmax vec loop v idx n best_idx best_val =
        | idx >= n           = best_idx
        | v_(idx) > best_val = la argmax vec loop v (idx + 1) n idx v_(idx)
        | otherwise          = la argmax vec loop v (idx + 1) n best_idx best_val

fn :: la softmax finish Tensor[Real * n] Tensor[Real * n] Int Int => Tensor[Real * n]
      la softmax finish v exps n tot =
        | tot <= 0  = Tensor[Real * n]
        | otherwise =
          out            = la softmax scale loop exps (Tensor[Real * n]) tot 0 n
          sum_p          = la sum vec loop out 0 n 0
          best_idx       = la argmax vec loop v 1 n 0 v_(0)
          out_(best_idx) = out_(best_idx) + (1000 - sum_p)
          out

fn :: linalg softmax Tensor[Real * n] => Tensor[Real * n]
      linalg softmax (Tensor[Real * n] v) =
        | n <= 0    = Tensor[Real * n]
        | otherwise =
          max_v = la max vec loop v 1 n v_(0)
          exps  = la exp shifted loop v (Tensor[Real * n]) max_v 0 n
          tot   = la sum vec loop exps 0 n 0
          la softmax finish v exps n tot
```

---

## 06.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `linalg`

- **Garantía algorítmica e de seguridade**: As matrices singulares devolven `None` limpamente en `linalg solve` (sen `NaN` silenciosos), e `linalg softmax` resta o máximo antes de exponenciar para evitar desbordamentos.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/linalg.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test linalg.rg`.

### As 5 Regras de Ouro ao programar con `linalg`

1. **Declara `import linalg` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `linalg` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `linalg` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `linalg` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 07** pasaremos a explorar en profundidade a lib **`codec`** (A lib `codec` — Hex, Base64, Base64url, URL Percent-Encoding e JSON Lixeiro).
