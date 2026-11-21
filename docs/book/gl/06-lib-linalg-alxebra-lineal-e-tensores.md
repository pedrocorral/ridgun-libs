# Capítulo 06: A lib `linalg` — Álxebra Lineal sobre `Tensor[Real]`, Bareiss e Activacións

## 06.1. Por que existe a lib `linalg`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `linalg` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `linalg`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: cando queres calcular similitude coseno para embeddings, resolver $A x = b$ ou avaliar unha capa `softmax` nun binario lixeiro, non queres arrastrar 400 MB de PyTorch ou LAPACK.

A lib **`linalg`** constrúe álxebra lineal numérica sobre `Tensor[Real]` nativo: transposición, traza, identidade, produto interno/externo, multiplicación matriz-vector e matriz-matriz con notación de Einstein, normas ($L_1, L_2, L_\infty$, Frobenius), determinante e resolución lineal $A x = b$ mediante eliminación de **Bareiss/Gauss con pivoteo parcial**, e activacións neuronais (`relu`, `sigmoid`, `softmax`).

Nun ecosistema tradicional, resolver as tarefas do dominio **`LINALG`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`linalg`** (`src/main/ridgun/lib/linalg.ridgun`) aborda o problema con catro principios innegociables:

1. **Declara `import linalg` (ou `import linalg as alias`) ao inicio do ficheiro**: cada lib define o seu espazo de nomes `module :: linalg` e en modo `--strict` as funcións multi-palabra invócanse sempre con espazos naturais.
2. **Encadea as túas tubaxes de esquerda a dereita con `->`**: escribe `entrada paso un -> paso dous -> resultado`, usa máscaras `(+ _ _ +)` para desestruturar secuencias e omite `_ =` en sentenzas secuenciais (ou descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `linalg` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 06.2. Artefactos nativos, importación e catálogo completo da API de `linalg`

En `ridgun-libs`, **`linalg`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/linalg.ridgun` (dominio `LINALG`). Ao compilar con `stable bundle`, empaquétase nun formato nativo:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/linalg.ridgunlib` | Distribución e importación directa con `import linalg` |

> Cada lib declara o seu propio espazo de nomes con `module :: linalg`: abonda con escribir `import linalg` (ou `import linalg as alias`) na cabeceira e chamar ás súas funcións con espazos naturais (`mina funcion x`) e tubaxes `->` (`x mina funcion -> resultado`).

### 06.2.1. Resumo de familias funcionais de `linalg`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `linalg transpose / linalg trace / linalg diag / linalg identity` | Transformacións estruturais de matrices e matriz identidade |
| `linalg dot / linalg outer / linalg matvec / linalg matmul` | Einstein contraction (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `linalg norm l1 / linalg norm l2 / linalg cosine similarity` | Normas vectoriais/matriciais, normalización e similitude coseno |
| `linalg det / linalg solve` | Determinante exacto de Bareiss e resolución $A x = b$ con pivoteo parcial (`Option[Tensor[Real]]`) |
| `linalg relu / linalg sigmoid / linalg softmax` | Activacións neuronais numericamente estables con desprazamento polo máximo |

### 06.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/linalg.ridgun`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/linalg.ridgun` (`0` tipos, `0` operadores e `77` funcións):

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
|---|---|---|
| `1` | `fn :: la abs Real` | `Real` |
| `2` | `fn :: la max Real Real` | `Real` |
| `3` | `fn :: la max int Int Int` | `Int` |
| `4` | `fn :: la sqrt step Real Real Real` | `Real` |
| `5` | `fn :: la sqrt loop Real Real` | `Real` |
| `6` | `fn :: linalg sqrt Real` | `Real` |
| `7` | `fn :: la exp series Real Real Real Real` | `Real` |
| `8` | `fn :: la square times Real Int` | `Real` |
| `9` | `fn :: la exp reduce Real Int` | `Real` |
| `10` | `fn :: linalg exp Real` | `Real` |
| `11` | `fn :: linalg vec len Tensor[Real * n]` | `Int` |
| `12` | `fn :: linalg mat rows Tensor[Real * r * c]` | `Int` |
| `13` | `fn :: linalg mat cols Tensor[Real * r * c]` | `Int` |
| `14` | `fn :: la transpose col loop Tensor[Real * r * c] Tensor[Real * c * r] Int Int Int` | `Tensor[Real * c * r]` |
| `15` | `fn :: la transpose row loop Tensor[Real * r * c] Tensor[Real * c * r] Int Int Int` | `Tensor[Real * c * r]` |
| `16` | `fn :: linalg transpose Tensor[Real * r * c]` | `Tensor[Real * c * r]` |
| `17` | `fn :: la trace loop Tensor[Real * r * c] Int Int Real` | `Real` |
| `18` | `fn :: linalg trace Tensor[Real * r * c]` | `Real` |
| `19` | `fn :: la diag loop Tensor[Real * r * c] Tensor[Real * r] Int Int` | `Tensor[Real * r]` |
| `20` | `fn :: linalg diag Tensor[Real * r * c]` | `Tensor[Real * r]` |
| `21` | `fn :: la identity loop Tensor[Real * n * n] Int Int` | `Tensor[Real * n * n]` |
| `22` | `fn :: linalg identity Int` | `Tensor[Real * n * n]` |
| `23` | `fn :: la dot loop Tensor[Real * n] Tensor[Real * n] Int Int Real` | `Real` |
| `24` | `fn :: linalg dot Tensor[Real * n] Tensor[Real * n]` | `Real` |
| `25` | `fn :: la outer col loop Tensor[Real * r] Tensor[Real * c] Tensor[Real * r * c] Int Int Int` | `Tensor[Real * r * c]` |
| `26` | `fn :: la outer row loop Tensor[Real * r] Tensor[Real * c] Tensor[Real * r * c] Int Int Int` | `Tensor[Real * r * c]` |
| `27` | `fn :: linalg outer Tensor[Real * r] Tensor[Real * c]` | `Tensor[Real * r * c]` |
| `28` | `fn :: la matvec row dot Tensor[Real * r * c] Tensor[Real * c] Int Int Int Real` | `Real` |
| `29` | `fn :: la matvec loop Tensor[Real * r * c] Tensor[Real * c] Tensor[Real * r] Int Int Int` | `Tensor[Real * r]` |
| `30` | `fn :: linalg matvec Tensor[Real * r * c] Tensor[Real * c]` | `Tensor[Real * r]` |
| `31` | `fn :: linalg matmul Tensor[Real * r * k] Tensor[Real * k * c]` | `Tensor[Real * r * c]` |
| `32` | `fn :: la norm l1 loop Tensor[Real * n] Int Int Real` | `Real` |
| `33` | `fn :: linalg norm l1 Tensor[Real * n]` | `Real` |
| `34` | `fn :: linalg norm l2 sq Tensor[Real * n]` | `Real` |
| `35` | `fn :: linalg norm l2 Tensor[Real * n]` | `Real` |
| `36` | `fn :: la norm linf loop Tensor[Real * n] Int Int Real` | `Real` |
| `37` | `fn :: linalg norm linf Tensor[Real * n]` | `Real` |
| `38` | `fn :: la frob col loop Tensor[Real * r * c] Int Int Int Real` | `Real` |
| `39` | `fn :: la frob row loop Tensor[Real * r * c] Int Int Int Real` | `Real` |
| `40` | `fn :: linalg frobenius norm Tensor[Real * r * c]` | `Real` |
| `41` | `fn :: la norm vec loop Tensor[Real * n] Tensor[Real * n] Real Int Int` | `Tensor[Real * n]` |
| `42` | `fn :: la normalize vec step Tensor[Real * n] Tensor[Real * n] Real Int` | `Tensor[Real * n]` |
| `43` | `fn :: linalg normalize vec Tensor[Real * n]` | `Tensor[Real * n]` |
| `44` | `fn :: la cosine step Tensor[Real * n] Tensor[Real * n] Real Real` | `Real` |
| `45` | `fn :: linalg cosine similarity Tensor[Real * n] Tensor[Real * n]` | `Real` |
| `46` | `fn :: la clone mat col Tensor[Real * r * c] Tensor[Real * n * n] Int Int Int` | `Tensor[Real * n * n]` |
| `47` | `fn :: la clone mat row Tensor[Real * r * c] Tensor[Real * n * n] Int Int` | `Tensor[Real * n * n]` |
| `48` | `fn :: la clone vec loop Tensor[Real * n] Tensor[Real * n] Int Int` | `Tensor[Real * n]` |
| `49` | `fn :: la find pivot step Tensor[Real * n * n] Int Int Int Int Real Real` | `Int` |
| `50` | `fn :: la find pivot row Tensor[Real * n * n] Int Int Int Int Real` | `Int` |
| `51` | `fn :: la swap mat rows loop Tensor[Real * n * n] Int Int Int Int` | `Tensor[Real * n * n]` |
| `52` | `fn :: la swap vec elems Tensor[Real * n] Int Int` | `Tensor[Real * n]` |
| `53` | `fn :: la elim col loop Tensor[Real * n * n] Int Int Real Int Int` | `Tensor[Real * n * n]` |
| `54` | `fn :: la elim rows Tensor[Real * n * n] Int Int Real Int` | `Tensor[Real * n * n]` |
| `55` | `fn :: la elim b loop Tensor[Real * n * n] Tensor[Real * n] Int Int Real Int` | `Tensor[Real * n]` |
| `56` | `fn :: la solve pivot Tensor[Real * n * n] Tensor[Real * n] Int Int Real` | `Tensor[Real * n]` |
| `57` | `fn :: la solve loop Tensor[Real * n * n] Tensor[Real * n] Int Int` | `Tensor[Real * n]` |
| `58` | `fn :: la backsub sum Tensor[Real * n * n] Tensor[Real * n] Int Int Int Real` | `Real` |
| `59` | `fn :: la backsub div Real Real Real` | `Real` |
| `60` | `fn :: la backsub loop Tensor[Real * n * n] Tensor[Real * n] Tensor[Real * n] Int Int` | `Tensor[Real * n]` |
| `61` | `fn :: linalg solve Tensor[Real * n * c] Tensor[Real * n]` | `Tensor[Real * n]` |
| `62` | `fn :: la pivot sign Int Int Real` | `Real` |
| `63` | `fn :: la det pivot Tensor[Real * n * n] Int Real Int Real` | `Real` |
| `64` | `fn :: la det loop Tensor[Real * n * n] Int Real Int` | `Real` |
| `65` | `fn :: linalg det Tensor[Real * n * c]` | `Real` |
| `66` | `fn :: la relu scalar Real` | `Real` |
| `67` | `fn :: la relu loop Tensor[Real * n] Tensor[Real * n] Int Int` | `Tensor[Real * n]` |
| `68` | `fn :: linalg relu Tensor[Real * n]` | `Tensor[Real * n]` |
| `69` | `fn :: la sigmoid neg Real` | `Real` |
| `70` | `fn :: la sigmoid scalar Real` | `Real` |
| `71` | `fn :: la sigmoid loop Tensor[Real * n] Tensor[Real * n] Int Int` | `Tensor[Real * n]` |
| `72` | `fn :: linalg sigmoid Tensor[Real * n]` | `Tensor[Real * n]` |
| `73` | `fn :: la max vec loop Tensor[Real * n] Int Int Real` | `Real` |
| `74` | `fn :: la sum vec loop Tensor[Real * n] Int Int Real` | `Real` |
| `75` | `fn :: la exp shifted loop Tensor[Real * n] Tensor[Real * n] Real Int Int` | `Tensor[Real * n]` |
| `76` | `fn :: la softmax scale loop Tensor[Real * n] Tensor[Real * n] Real Int Int` | `Tensor[Real * n]` |
| `77` | `fn :: linalg softmax Tensor[Real * n]` | `Tensor[Real * n]` |

---

## 06.3. Explorando `linalg` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `linalg` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test linalg.ridgun`.

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

Toda función da lib `linalg` está deseñada para compoñerse con gardas booleanas `|` e co resto das 38 libs de `ridgun-libs`:

```ridgun
import linalg

fn :: puntuar embeddings Tensor[Real * n] Tensor[Real * n] => Real Tensor[Real * n]
      puntuar embeddings q d =
        linalg cosine similarity q d -> sim
        linalg softmax q -> probs
        (sim, probs)
```

### 06.3.3. Exemplo 3: Transposta (`transpose`), traza (`trace`), extracción/construción diagonal (`diag`) e matriz identidade (`identity`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `linalg` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test transpose trace diag identity => ()
      test transpose trace diag identity =
        -- 1. Non-square 2x3 transpose -> 3x2, and (A^T)^T == A
        m = Tensor[Real * 2 * 3]
        m_(0, 0) = 1.0
        m_(0, 1) = 2.0
        m_(0, 2) = 3.0
        m_(1, 0) = 4.0
        m_(1, 1) = 5.5
        m_(1, 2) = 6.0
        assert int equals (linalg mat rows m) 2 "2x3 rows == 2"
        assert int equals (linalg mat cols m) 3 "2x3 cols == 3"
        mt = linalg transpose m
        assert int equals (linalg mat rows mt) 3 "transposed rows == 3"
        assert int equals (linalg mat cols mt) 2 "transposed cols == 2"
        assert true (near mt_(0, 0) 1.0) "mt(0,0) == 1"
        assert true (near mt_(0, 1) 4.0) "mt(0,1) == 4"
        assert true (near mt_(1, 1) 5.5) "mt(1,1) == 5.5"
        assert true (near mt_(2, 0) 3.0) "mt(2,0) == 3"
        mtt = linalg transpose mt
        assert true (near mtt_(1, 2) 6.0) "(A^T)^T(1,2) == 6"

        -- 2. Trace and diagonal on a 3x3 matrix with negative and fractional entries
        sq = Tensor[Real * 3 * 3]
        sq_(0, 0) = 10.0
        sq_(0, 1) = 2.0
        sq_(0, 2) = 3.0
        sq_(1, 0) = 4.0
        sq_(1, 1) = 0.0 - 3.5
        sq_(1, 2) = 6.0
        sq_(2, 0) = 7.0
        sq_(2, 1) = 8.0
        sq_(2, 2) = 5.0
        assert true (near (linalg trace sq) 11.5) "trace(sq) == 10 - 3.5 + 5"
        assert true (near (linalg trace (linalg transpose sq)) 11.5) "trace(A^T) == trace(A)"
        dg = linalg diag sq
        assert int equals (linalg vec len dg) 3 "diag len == 3"
        assert true (near dg_(1) (0.0 - 3.5)) "diag(1) == -3.5"

        -- 3. Identity: trace(I_4) == 4, det(I_4) == 1, I_3 @ sq == sq
        id4 = linalg identity 4
        assert int equals (linalg mat rows id4) 4 "I_4 rows == 4"
        assert true (near (linalg trace id4) 4.0) "trace(I_4) == 4"
        assert true (near id4_(2, 2) 1.0) "I_4(2,2) == 1"
        assert true (near id4_(2, 3) 0.0) "I_4(2,3) == 0"
        assert true (near (linalg det id4) 1.0) "det(I_4) == 1"
        id3  = linalg identity 3
        prod = linalg matmul id3 sq
        assert true (near prod_(0, 0) 10.0) "(I_3 @ sq)(0,0) == 10"
        assert true (near prod_(1, 1) (0.0 - 3.5)) "(I_3 @ sq)(1,1) == -3.5"
        assert true (near prod_(2, 1) 8.0) "(I_3 @ sq)(2,1) == 8"
        ()
```

### 06.3.4. Exemplo 4: Produto escalar (`dot`), produto exterior (`outer`), matriz-vector (`matvec`), multiplicación matricial (`matmul`) e normas ($L_1$, $L_2$, $L_\infty$, Frobenius)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `linalg` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test dot outer matvec norms => ()
      test dot outer matvec norms =
        -- 1. Dot product, commutativity and orthogonal vectors
        u = Tensor[Real * 3]
        u_(0) = 1.0
        u_(1) = 0.0 - 2.0
        u_(2) = 3.0
        v = Tensor[Real * 3]
        v_(0) = 4.0
        v_(1) = 5.0
        v_(2) = 6.5
        assert true (near (linalg dot u v) 13.5) "dot([1,-2,3], [4,5,6.5]) == 4 - 10 + 19.5"
        assert true (near (linalg dot v u) 13.5) "dot is commutative"
        o1 = Tensor[Real * 3]
        o1_(0) = 1.0
        o1_(1) = 2.0
        o1_(2) = 0.0 - 1.0
        o2 = Tensor[Real * 3]
        o2_(0) = 2.0
        o2_(1) = 0.0
        o2_(2) = 2.0
        assert true (near (linalg dot o1 o2) 0.0) "orthogonal dot == 0"
        assert true (near (linalg cosine similarity o1 o2) 0.0) "orthogonal cosine similarity == 0"
        assert true (near (linalg cosine similarity o1 o1) 1.0) "cosine similarity with itself == 1"

        -- 2. Outer product u (3) (x) w (2) -> 3x2; a square outer product has det 0
        w = Tensor[Real * 2]
        w_(0) = 0.5
        w_(1) = 0.0 - 8.0
        out = linalg outer u w
        assert int equals (linalg mat rows out) 3 "outer rows == 3"
        assert int equals (linalg mat cols out) 2 "outer cols == 2"
        assert true (near out_(0, 0) 0.5) "outer(0,0) == 0.5"
        assert true (near out_(1, 0) (0.0 - 1.0)) "outer(1,0) == -1"
        assert true (near out_(2, 1) (0.0 - 24.0)) "outer(2,1) == -24"
        rk1 = linalg outer u v
        assert true (near (linalg det rk1) 0.0) "rank-1 outer product has det == 0"

        -- 3. Norms and normalization on (3, -4, 0)
        p = Tensor[Real * 3]
        p_(0) = 3.0
        p_(1) = 0.0 - 4.0
        p_(2) = 0.0
        assert true (near (linalg norm l1 p) 7.0) "L1([3,-4,0]) == 7"
        assert true (near (linalg norm l2 sq p) 25.0) "L2^2([3,-4,0]) == 25"
        assert true (near (linalg norm l2 p) 5.0) "L2([3,-4,0]) == 5"
        assert true (near (linalg norm linf p) 4.0) "L_inf([3,-4,0]) == 4"
        np = linalg normalize vec p
        assert true (near np_(0) 0.6) "normalized(0) == 0.6"
        assert true (near np_(1) (0.0 - 0.8)) "normalized(1) == -0.8"
        assert true (near np_(2) 0.0) "normalized(2) == 0"
        assert true (near (linalg norm l2 np) 1.0) "normalized vector has L2 == 1"
        fm = Tensor[Real * 2 * 2]
        fm_(0, 0) = 1.0
        fm_(0, 1) = 2.0
        fm_(1, 0) = 2.0
        fm_(1, 1) = 4.0
        assert true (near (linalg frobenius norm fm) 5.0) "Frobenius([1,2;2,4]) == 5"

        -- Zero-vector normalization guard (VUL-INPUT-001)
        z3 = Tensor[Real * 3]
        nz = linalg normalize vec z3
        assert true (near nz_(0) 0.0) "normalize zero vector is safe (0)"
        ()
```

### 06.3.5. Exemplo 5: Determinantes exactos (`det2`, `det3`, `det`) e resolución de sistemas lineais $Ax = b$ sen fraccións (`linalg solve`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `linalg` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test det and linear solver => ()
      test det and linear solver =
        -- 1. 2x2: [2, 3; 5, 4] x = [13, 22] => x = [2, 3]
        a2 = Tensor[Real * 2 * 2]
        a2_(0, 0) = 2.0
        a2_(0, 1) = 3.0
        a2_(1, 0) = 5.0
        a2_(1, 1) = 4.0
        b2 = Tensor[Real * 2]
        b2_(0) = 13.0
        b2_(1) = 22.0
        assert true (near (linalg det a2) (0.0 - 7.0)) "det([2,3;5,4]) == -7"
        x2 = linalg solve a2 b2
        assert true (near x2_(0) 2.0) "2x2 solve x0 == 2"
        assert true (near x2_(1) 3.0) "2x2 solve x1 == 3"
        r2 = linalg matvec a2 x2
        assert true (near r2_(0) 13.0) "A*x(0) == 13"
        assert true (near r2_(1) 22.0) "A*x(1) == 22"

        -- 2. 3x3 with a 0 in (0,0), so partial pivoting is required:
        -- [0, 2, 1; 1, -2, -3; -1, 1, 2] x = [-8, 0, 3] => x = [-4, -5, 2]
        a3 = Tensor[Real * 3 * 3]
        a3_(0, 0) = 0.0
        a3_(0, 1) = 2.0
        a3_(0, 2) = 1.0
        a3_(1, 0) = 1.0
        a3_(1, 1) = 0.0 - 2.0
        a3_(1, 2) = 0.0 - 3.0
        a3_(2, 0) = 0.0 - 1.0
        a3_(2, 1) = 1.0
        a3_(2, 2) = 2.0
        b3 = Tensor[Real * 3]
        b3_(0) = 0.0 - 8.0
        b3_(1) = 0.0
        b3_(2) = 3.0
        assert true (near (linalg det a3) 1.0) "det(a3) == 1"
        x3 = linalg solve a3 b3
        assert true (near x3_(0) (0.0 - 4.0)) "3x3 pivoted solve x0 == -4"
        assert true (near x3_(1) (0.0 - 5.0)) "3x3 pivoted solve x1 == -5"
        assert true (near x3_(2) 2.0) "3x3 pivoted solve x2 == 2"
        r3 = linalg matvec a3 x3
        assert true (near r3_(0) (0.0 - 8.0)) "A3*x3(0) == -8"
        assert true (near r3_(1) 0.0) "A3*x3(1) == 0"
        assert true (near r3_(2) 3.0) "A3*x3(2) == 3"

        -- 3. Fractional solution: [4, 1; 1, 3] x = [1, 2] => x = [1/11, 7/11]
        f2 = Tensor[Real * 2 * 2]
        f2_(0, 0) = 4.0
        f2_(0, 1) = 1.0
        f2_(1, 0) = 1.0
        f2_(1, 1) = 3.0
        fb = Tensor[Real * 2]
        fb_(0) = 1.0
        fb_(1) = 2.0
        xf = linalg solve f2 fb
        assert true (near xf_(0) (1.0 / 11.0)) "fractional solve x0 == 1/11"
        assert true (near xf_(1) (7.0 / 11.0)) "fractional solve x1 == 7/11"
        assert true (near (linalg det f2) 11.0) "det([4,1;1,3]) == 11"

        -- 4. Singular matrix: det 0, solve does not divide by zero (VUL-INPUT-001)
        s2 = Tensor[Real * 2 * 2]
        s2_(0, 0) = 1.0
        s2_(0, 1) = 2.0
        s2_(1, 0) = 2.0
        s2_(1, 1) = 4.0
        assert true (near (linalg det s2) 0.0) "singular det == 0"
        xs = linalg solve s2 fb
        assert int equals (linalg vec len xs) 2 "singular solve returns a vector"
        ()
```

### 06.3.6. Exemplo 6: Funcións de activación neuronal (`relu`, `sigmoid`, `softmax`, `argmax`, `argmin`, `normalize`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `linalg` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test neural activations => ()
      test neural activations =
        -- 1. ReLU: negatives -> 0, positives preserved
        v = Tensor[Real * 4]
        v_(0) = 0.0 - 10.0
        v_(1) = 0.0
        v_(2) = 0.5
        v_(3) = 42.0
        rv = linalg relu v
        assert true (near rv_(0) 0.0) "relu(-10) == 0"
        assert true (near rv_(1) 0.0) "relu(0) == 0"
        assert true (near rv_(2) 0.5) "relu(0.5) == 0.5"
        assert true (near rv_(3) 42.0) "relu(42) == 42"

        -- 2. Sigmoid: in (0, 1), sigmoid(0) == 0.5, sigmoid(-x) + sigmoid(x) == 1
        sv = Tensor[Real * 4]
        sv_(0) = 0.0 - 2.0
        sv_(1) = 0.0
        sv_(2) = 2.0
        sv_(3) = 0.0 - 1000.0
        sg = linalg sigmoid sv
        assert true (near sg_(1) 0.5) "sigmoid(0) == 0.5"
        assert true (near sg_(2) 0.8807970779778823) "sigmoid(2)"
        assert true (sg_(0) > 0.0 and sg_(0) < 0.5) "sigmoid(-2) in (0, 0.5)"
        assert true (near (sg_(0) + sg_(2)) 1.0) "sigmoid(-2) + sigmoid(2) == 1"
        assert true (near sg_(3) 0.0) "sigmoid(-1000) == 0 without overflow"

        -- 3. Softmax: known values, sums to 1, shift-invariant, overflow-safe
        logits = Tensor[Real * 3]
        logits_(0) = 1.0
        logits_(1) = 2.0
        logits_(2) = 3.0
        sm = linalg softmax logits
        assert true (near sm_(0) 0.09003057317038046) "softmax([1,2,3])(0)"
        assert true (near sm_(1) 0.24472847105479764) "softmax([1,2,3])(1)"
        assert true (near sm_(2) 0.6652409557748219) "softmax([1,2,3])(2)"
        assert true (near (sm_(0) + sm_(1) + sm_(2)) 1.0) "softmax sums to 1"
        shifted = Tensor[Real * 3]
        shifted_(0) = 1000001.0
        shifted_(1) = 1000002.0
        shifted_(2) = 1000003.0
        sm_sh = linalg softmax shifted
        assert true (near sm_sh_(0) sm_(0)) "softmax shift-invariance (0)"
        assert true (near sm_sh_(1) sm_(1)) "softmax shift-invariance (1)"
        assert true (near sm_sh_(2) sm_(2)) "softmax shift-invariance (2)"
        ()
```

### 06.3.7. Exemplo 7: Raíz cadrada e exponencial (`linalg sqrt`, `linalg exp`) con dominio protexido

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `linalg` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test sqrt and exp => ()
      test sqrt and exp =
        assert true (near (linalg sqrt 25.0) 5.0) "sqrt(25) == 5"
        assert true (near (linalg sqrt 2.0) 1.4142135623730951) "sqrt(2)"
        assert true (near (linalg sqrt 0.25) 0.5) "sqrt(0.25) == 0.5"
        assert true (near (linalg sqrt 1000000.0) 1000.0) "sqrt(1e6) == 1000"
        assert true (near (linalg sqrt 0.0) 0.0) "sqrt(0) == 0"
        assert true (near (linalg sqrt (0.0 - 4.0)) 0.0) "sqrt of a negative is 0 (guard)"
        assert true (near (linalg exp 0.0) 1.0) "exp(0) == 1"
        assert true (near (linalg exp 1.0) 2.718281828459045) "exp(1) == e"
        assert true (near (linalg exp (0.0 - 1.0)) 0.36787944117144233) "exp(-1)"
        assert true (near (linalg exp 10.0) 22026.465794806718) "exp(10)"
        assert true (near ((linalg exp (0.0 - 20.0)) * 1000000000.0) 2.061153622438558) "exp(-20)"
        assert true (near (linalg exp (0.0 - 800.0)) 0.0) "exp(-800) underflows to 0"
        ()
```

---

## 06.4. Baixo o capó: como está construída `linalg` en Ridgun puro (`src/main/ridgun/lib/linalg.ridgun`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/linalg.ridgun` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 06.4.1. Implementación interna: Internal Scalar Helpers

Fíxate en como `linalg.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
module :: linalg

fn :: la abs Real => Real
      la abs x    =
        | x < 0.0   = 0.0 - x
        | otherwise = x

fn :: la max Real Real => Real
      la max a    b    =
        | a >= b    = a
        | otherwise = b

fn :: la max int Int Int => Int
      la max int a   b   =
        | a >= b    = a
        | otherwise = b

-- Newton's method from above: g >= sqrt(x) on every step, so the
-- iteration stops at the first step that no longer decreases.
fn :: la sqrt step Real Real Real => Real
      la sqrt step x    g    ng   =
        | ng >= g   = g
        | otherwise = la sqrt loop x ng

fn :: la sqrt loop Real Real => Real
      la sqrt loop x    g    =
        la sqrt step x g ((g + (x / g)) / 2.0)

fn :: linalg sqrt Real => Real
      linalg sqrt x    =
        | x <= 0.0  = 0.0
        | otherwise = la sqrt loop x (la max x 1.0)

-- exp(r) for |r| <= 0.5 by its Taylor series (24 terms, below 1 ulp).
fn :: la exp series Real Real Real Real => Real
      la exp series r    term acc  fi   =
        | fi > 24.0 = acc
        | otherwise =
          t = (term * r) / fi
          la exp series r t (acc + t) (fi + 1.0)

fn :: la square times Real Int => Real
      la square times g    k   =
        | k <= 0    = g
        | otherwise = la square times (g * g) (k - 1)

-- exp(x) = exp(x / 2^k) ^ (2^k), with |x / 2^k| <= 0.5.
fn :: la exp reduce Real Int => Real
      la exp reduce r    k   =
        | (la abs r) > 0.5 = la exp reduce (r / 2.0) (k + 1)
        | otherwise        = la square times (la exp series r 1.0 1.0 1.0) k

fn :: linalg exp Real => Real
      linalg exp x    =
        | x < (0.0 - 745.0) = 0.0
        | otherwise         = la exp reduce x 0
```

### 06.4.2. Implementación interna: Matrix Transpose, Trace, Diagonal & Identity

Fíxate en como `linalg.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

fn :: la trace loop Tensor[Real * r * c] Int Int Real => Real
      la trace loop m idx n acc =
        | idx >= n  = acc
        | otherwise = la trace loop m (idx + 1) n (acc + m_(idx, idx))

fn :: linalg trace Tensor[Real * r * c] => Real
      linalg trace (Tensor[Real * r * c] m) =
        la trace loop m 0 r 0.0

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
          out_(idx, idx) = 1.0
          la identity loop out (idx + 1) n

fn :: linalg identity Int => Tensor[Real * n * n]
      linalg identity dim =
        la max int 1 dim -> n
        out = Tensor[Real * n * n]
        la identity loop out 0 n
```

### 06.4.3. Implementación interna: Vector & Matrix Norms (`norm_l1`, `norm_l2`, `norm_linf`, `frobenius`)

Fíxate en como `linalg.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: la norm l1 loop Tensor[Real * n] Int Int Real => Real
      la norm l1 loop v idx n acc =
        | idx >= n  = acc
        | otherwise = la norm l1 loop v (idx + 1) n (acc + (la abs v_(idx)))

fn :: linalg norm l1 Tensor[Real * n] => Real
      linalg norm l1 (Tensor[Real * n] v) =
        la norm l1 loop v 0 n 0.0

fn :: linalg norm l2 sq Tensor[Real * n] => Real
      linalg norm l2 sq (Tensor[Real * n] v) =
        la dot loop v v 0 n 0.0

fn :: linalg norm l2 Tensor[Real * n] => Real
      linalg norm l2 (Tensor[Real * n] v) =
        linalg sqrt (la dot loop v v 0 n 0.0)

fn :: la norm linf loop Tensor[Real * n] Int Int Real => Real
      la norm linf loop v idx n best =
        | idx >= n  = best
        | otherwise = la norm linf loop v (idx + 1) n (la max best (la abs v_(idx)))

fn :: linalg norm linf Tensor[Real * n] => Real
      linalg norm linf (Tensor[Real * n] v) =
        la norm linf loop v 0 n 0.0

fn :: la frob col loop Tensor[Real * r * c] Int Int Int Real => Real
      la frob col loop m i j cols acc =
        | j >= cols = acc
        | otherwise =
          x = m_(i, j)
          la frob col loop m i (j + 1) cols (acc + (x * x))

fn :: la frob row loop Tensor[Real * r * c] Int Int Int Real => Real
      la frob row loop m i rows cols acc =
        | i >= rows = acc
        | otherwise = la frob row loop m (i + 1) rows cols (la frob col loop m i 0 cols acc)

fn :: linalg frobenius norm Tensor[Real * r * c] => Real
      linalg frobenius norm (Tensor[Real * r * c] m) =
        linalg sqrt (la frob row loop m 0 r c 0.0)

fn :: la norm vec loop Tensor[Real * n] Tensor[Real * n] Real Int Int => Tensor[Real * n]
      la norm vec loop v out norm_val idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = v_(idx) / norm_val
          la norm vec loop v out norm_val (idx + 1) n

fn :: la normalize vec step Tensor[Real * n] Tensor[Real * n] Real Int => Tensor[Real * n]
      la normalize vec step v out norm_value n =
        | norm_value <= 0.0 = out
        | otherwise         = la norm vec loop v out norm_value 0 n

fn :: linalg normalize vec Tensor[Real * n] => Tensor[Real * n]
      linalg normalize vec (Tensor[Real * n] v) =
        la normalize vec step v (Tensor[Real * n]) (linalg norm l2 v) n

fn :: la cosine step Tensor[Real * n] Tensor[Real * n] Real Real => Real
      la cosine step a b na nb =
        | na <= 0.0 or nb <= 0.0 = 0.0
        | otherwise              = (linalg dot a b) / (na * nb)

fn :: linalg cosine similarity Tensor[Real * n] Tensor[Real * n] => Real
      linalg cosine similarity (Tensor[Real * n] a) (Tensor[Real * n] b) =
        la cosine step a b (linalg norm l2 a) (linalg norm l2 b)
```

### 06.4.4. Implementación interna: Neural Activations (`linalg relu`, `linalg sigmoid`, `linalg softmax`)

Fíxate en como `linalg.ridgun` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
fn :: la relu scalar Real => Real
      la relu scalar x    =
        | x <= 0.0  = 0.0
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

fn :: la sigmoid neg Real => Real
      la sigmoid neg e    = e / (1.0 + e)

-- 1 / (1 + exp(-x)); exp only ever gets a value <= 0, so it cannot overflow.
fn :: la sigmoid scalar Real => Real
      la sigmoid scalar x    =
        | x >= 0.0  = 1.0 / (1.0 + (linalg exp (0.0 - x)))
        | otherwise = la sigmoid neg (linalg exp x)

fn :: la sigmoid loop Tensor[Real * n] Tensor[Real * n] Int Int => Tensor[Real * n]
      la sigmoid loop v out idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = la sigmoid scalar v_(idx)
          la sigmoid loop v out (idx + 1) n

fn :: linalg sigmoid Tensor[Real * n] => Tensor[Real * n]
      linalg sigmoid (Tensor[Real * n] v) =
        la sigmoid loop v (Tensor[Real * n]) 0 n

fn :: la max vec loop Tensor[Real * n] Int Int Real => Real
      la max vec loop v idx n best =
        | idx >= n  = best
        | otherwise = la max vec loop v (idx + 1) n (la max best v_(idx))

fn :: la sum vec loop Tensor[Real * n] Int Int Real => Real
      la sum vec loop v idx n acc =
        | idx >= n  = acc
        | otherwise = la sum vec loop v (idx + 1) n (acc + v_(idx))

fn :: la exp shifted loop Tensor[Real * n] Tensor[Real * n] Real Int Int => Tensor[Real * n]
      la exp shifted loop v out max_val idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = linalg exp (v_(idx) - max_val)
          la exp shifted loop v out max_val (idx + 1) n

fn :: la softmax scale loop Tensor[Real * n] Tensor[Real * n] Real Int Int => Tensor[Real * n]
      la softmax scale loop exps out tot idx n =
        | idx >= n  = out
        | otherwise =
          out_(idx) = exps_(idx) / tot
          la softmax scale loop exps out tot (idx + 1) n

fn :: linalg softmax Tensor[Real * n] => Tensor[Real * n]
      linalg softmax (Tensor[Real * n] v) =
        | n <= 0    = Tensor[Real * n]
        | otherwise =
          max_v = la max vec loop v 1 n v_(0)
          exps  = la exp shifted loop v (Tensor[Real * n]) max_v 0 n
          tot   = la sum vec loop exps 0 n 0.0
          la softmax scale loop exps (Tensor[Real * n]) tot 0 n
```

---

## 06.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `linalg`

- **Garantía algorítmica e de seguridade**: As matrices singulares devolven `None` limpamente en `linalg solve` (sen `NaN` silenciosos), e `linalg softmax` resta o máximo antes de exponenciar para evitar desbordamentos.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/linalg.ridgun` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test linalg.ridgun`.

### As 5 Regras de Ouro ao programar con `linalg`

1. **Declara `import linalg` ao inicio do ficheiro** e chama as súas funcións con espazos, tal como están declaradas, para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `linalg` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `linalg` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `linalg` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 07** pasaremos a explorar en profundidade a lib **`codec`** (A lib `codec` — Hex, Base64, Base64url, URL Percent-Encoding e JSON Lixeiro).
