# Capítol 06: La lib `linalg` — Àlgebra Lineal sobre `Tensor[Real]`, Bareiss i Activacions

## 06.1. Per què existeix la lib `linalg`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `linalg` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `linalg`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: quan vols calcular similitud cosinus per a embeddings, resoldre $A x = b$ o avaluar una capa `softmax` en un binari lleuger, no vols arrossegar 400 MB de PyTorch o LAPACK.

La lib **`linalg`** construeix àlgebra lineal numèrica sobre `Tensor[Real]` natiu: transposició, traça, identitat, producte intern/extern, multiplicació matriu-vector i matriu-matriu amb notació d'Einstein, normes ($L_1, L_2, L_\infty$, Frobenius), determinant i resolució lineal $A x = b$ mitjançant eliminació de **Bareiss/Gauss amb pivotatge parcial**, i activacions neuronals (`relu`, `sigmoid`, `softmax`).

En un ecosistema tradicional, resoldre les tasques del domini **`LINALG`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`linalg`** (`src/main/ridgun/lib/linalg.ridgun`) aborda el problema amb quatre principis innegociables:

1. **Declara `import linalg` (o `import linalg as alias`) a l'inici del fitxer**: cada lib defineix el seu espai de noms `module :: linalg` i en mode `--strict` les funcions multi-paraula s'invoquen sempre amb espais naturals.
2. **Encadena les teves canonades d'esquerra a dreta amb `->`**: escriu `entrada pas u -> pas dos -> resultat`, fes servir màscares `(+ _ _ +)` per desestructurar seqüències i omet `_ =` en sentències seqüencials (o descarta amb `-> ()`).
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `linalg` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 06.2. Artefactes natius, importació i catàleg complet de l'API de `linalg`

A `ridgun-libs`, **`linalg`** és una **lib** de primera classe situada a `src/main/ridgun/lib/linalg.ridgun` (domini `LINALG`). En compilar amb `stable bundle`, s'empaqueta en un format natiu:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/linalg.ridgunlib` | Distribució i importació directa amb `import linalg` |

> Cada lib declara el seu propi espai de noms amb `module :: linalg`: n'hi ha prou d'escriure `import linalg` (o `import linalg as alias`) a la capçalera i cridar les seves funcions amb espais naturals (`la meva funcio x`) i canonades `->` (`x la meva funcio -> resultat`).

### 06.2.1. Resum de famílies funcionals de `linalg`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `linalg transpose / linalg trace / linalg diag / linalg identity` | Transformacions estructurals de matrius i matriu identitat |
| `linalg dot / linalg outer / linalg matvec / linalg matmul` | Einstein contraction (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `linalg norm l1 / linalg norm l2 / linalg cosine similarity` | Normes vectorials/matricials, normalització i similitud cosinus |
| `linalg det / linalg solve` | Determinant exacte de Bareiss i resolució $A x = b$ amb pivotatge parcial (`Option[Tensor[Real]]`) |
| `linalg relu / linalg sigmoid / linalg softmax` | Activacions neuronals numèricament estables amb desplaçament pel màxim |

### 06.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/linalg.ridgun`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/linalg.ridgun` (`0` tipus, `0` operadors i `77` funcions):

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 06.3. Explorant `linalg` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `linalg` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test linalg.ridgun`.

### 06.3.1. Exemple 1: Flux principal en estil tabular amb `linalg`

Observa com en Ridgun els signes `=` i els passos de transformació amb `linalg` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import linalg

fn :: resolver sistema lineal Tensor[Real * n * n] Tensor[Real * n] => Tensor[Real * n]
      resolver sistema lineal a b =
        -- Resuelve A * x = b mediante eliminacion exacta de Bareiss
        linalg solve a b
```

### 06.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `linalg` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 38 libs de `ridgun-libs`:

```ridgun
import linalg

fn :: puntuar embeddings Tensor[Real * n] Tensor[Real * n] => Real Tensor[Real * n]
      puntuar embeddings q d =
        linalg cosine similarity q d -> sim
        linalg softmax q -> probs
        (sim, probs)
```

### 06.3.3. Exemple 3: Transposada (`transpose`), traça (`trace`), extracció/construcció diagonal (`diag`) i matriu identitat (`identity`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `linalg` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 06.3.4. Exemple 4: Producte escalar (`dot`), producte exterior (`outer`), matriu-vector (`matvec`), multiplicació matricial (`matmul`) i normes ($L_1$, $L_2$, $L_\infty$, Frobenius)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `linalg` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 06.3.5. Exemple 5: Determinants exactes (`det2`, `det3`, `det`) i resolució de sistemes lineals $Ax = b$ sense fraccions (`linalg solve`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `linalg` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 06.3.6. Exemple 6: Funcions d'activació neuronal (`relu`, `sigmoid`, `softmax`, `argmax`, `argmin`, `normalize`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `linalg` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

### 06.3.7. Exemple 7: Arrel quadrada i exponencial (`linalg sqrt`, `linalg exp`) amb domini protegit

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `linalg` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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

## 06.4. Sota el capó: com està construïda `linalg` en Ridgun pur (`src/main/ridgun/lib/linalg.ridgun`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/linalg.ridgun` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 06.4.1. Implementació interna: Internal Scalar Helpers

Fixa't en com `linalg.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 06.4.2. Implementació interna: Matrix Transpose, Trace, Diagonal & Identity

Fixa't en com `linalg.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 06.4.3. Implementació interna: Vector & Matrix Norms (`norm_l1`, `norm_l2`, `norm_linf`, `frobenius`)

Fixa't en com `linalg.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 06.4.4. Implementació interna: Neural Activations (`linalg relu`, `linalg sigmoid`, `linalg softmax`)

Fixa't en com `linalg.ridgun` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

## 06.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `linalg`

- **Garantia algorísmica i de seguretat**: Les matrius singulars retornen `None` netament a `linalg solve` (sense `NaN` silenciosos), i `linalg softmax` resta el màxim abans d'exponenciar per evitar desbordaments.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/linalg.ridgun` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test linalg.ridgun`.

### Les 5 Regles d'Or en programar amb `linalg`

1. **Declara `import linalg` a l'inici del fitxer** i crida les seves funcions amb espais, tal com estan declarades, perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `linalg` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `linalg` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `linalg` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 07** passarem a explorar en profunditat la lib **`codec`** (La lib `codec` — Hex, Base64, Base64url, URL Percent-Encoding i JSON Lleuger).
