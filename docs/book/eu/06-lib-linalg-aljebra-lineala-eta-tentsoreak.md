# 06. kapitulua: `linalg` lib-a — `Tensor[Real]` gaineko Aljebra Lineala, Bareiss eta Aktibazioak

## 06.1. Zergatik existitzen da `linalg` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `linalg` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `linalg`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: embedding-etarako kosinu-antzekotasuna kalkulatu, $A x = b$ ebatzi edo bitar arin batean `softmax` geruza bat ebaluatu nahi duzunean, ez dituzu PyTorch edo LAPACKen 400 MB arrastaka eraman nahi.

**`linalg`** lib-ak zenbakizko aljebra lineala eraikitzen du `Tensor[Real]` natiboaren gainean: iraulketa, aztarna, identitatea, biderkadura eskalarrak eta matrizialak Einsteinen notazioarekin, normak ($L_1, L_2, L_\infty$, Frobenius), determinantea eta $A x = b$ ebazpena **Bareiss/Gauss** algoritmoarekin, eta aktibazio neuronalak (`relu`, `sigmoid`, `softmax`).

Ekosistema tradizional batean, **`LINALG`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`linalg`** lib-ak (`src/main/ridgun/lib/linalg.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Deklaratu `import linalg` (edo `import linalg as alias`) fitxategiaren hasieran**: lib bakoitzak `module :: linalg` izen-espazioa definitzen du eta `--strict` moduan hitz anitzeko funtzioei zuriune naturalekin deitzen zaie beti.
2. **Kateatu zure datu-hodiak ezkerretik eskuinera `->` bidez**: idatzi `sarrera lehen urratsa -> bigarren urratsa -> emaitza`, erabili `(+ _ _ +)` maskarak sekuentziak desegituratzeko eta kendu `_ =` sententzia sekuentzialetan (edo baztertu `-> ()` bidez).
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `linalg`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 06.2. Artefaktu natiboak, inportazioa eta `linalg` APIaren katalogo osoa

`ridgun-libs`-en, **`linalg`** lehen mailako **lib** bat da, `src/main/ridgun/lib/linalg.rg` bidean kokatua (`LINALG` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/linalg.rglib` | Banaketa eta inportazio zuzena `import linalg` bidez |
| **Fitxategi konpilatua** | `target/linalg.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/liblinalg.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib bakoitzak bere izen-espazioa deklaratzen du `module :: linalg` bidez: nahikoa da goiburuan `import linalg` (edo `import linalg as alias`) idaztea eta bere funtzioei zuriune naturalekin (`nire funtzioa x`) eta `->` hodiekin (`x nire funtzioa -> emaitza`) deitzea.

### 06.2.1. `linalg`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `linalg vec from list / linalg mat from lists` | Ridgun zerrendetatik 1D eta 2D `Tensor[Real]` eraikitzen ditu |
| `linalg transpose / linalg trace / linalg diag / linalg identity` | Matrizeen egitura-eraldaketak eta identitate-matrizea |
| `linalg dot / linalg outer / linalg matvec / linalg matmul` | Einstein contraction (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `linalg norm l1 / linalg norm l2 / linalg cosine similarity` | Bektore/matrize normak, normalizazioa eta kosinu-antzekotasuna |
| `linalg det / linalg solve` | Bareissen determinante zehatza eta $A x = b$ ebazlea pibotatze partzialarekin (`Option[Tensor[Real]]`) |
| `linalg relu / linalg sigmoid / linalg softmax` | Maximoaren bidezko desplazamendudun aktibazio neuronal zenbakiz egonkorrak |

### 06.2.2. `src/main/ridgun/lib/linalg.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/linalg.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`0` mota, `0` eragile eta `76` funtzio):

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
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

## 06.3. `linalg` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `linalg` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test linalg.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 06.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `linalg` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `linalg` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import linalg

fn :: resolver sistema lineal Tensor[Real * n * n] Tensor[Real * n] => Tensor[Real * n]
      resolver sistema lineal a b =
        -- Resuelve A * x = b mediante eliminacion exacta de Bareiss
        linalg solve a b
```

### 06.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`linalg` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import linalg

fn :: puntuar embeddings Tensor[Real * n] Tensor[Real * n] => Int Tensor[Real * n]
      puntuar embeddings q d =
        linalg cosine similarity q d -> sim
        q linalg softmax -> probs
        (sim, probs)
```

### 06.3.3. 3. adibidea: Iraulia (`transpose`), aztarna (`trace`), diagonalaren erauzketa/eraikuntza (`diag`, `from diag`) eta identitate-matrizea (`identity`)

Adibide praktiko honetan `linalg` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 06.3.4. 4. adibidea: Biderkadura eskalarra (`dot`), kanpo-biderkadura (`outer`), matrize-bektorea (`matvec`), matrize-biderketa (`matmul`) eta normak ($L_1$, $L_2$, $L_\infty$, Frobenius)

Adibide praktiko honetan `linalg` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 06.3.5. 5. adibidea: Determinante zehatzak (`det2`, `det3`, `det`) eta zatikirik gabeko $Ax = b$ sistema linealen ebazpena (`linalg solve`)

Adibide praktiko honetan `linalg` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 06.3.6. 6. adibidea: Aktibazio neuronaleko funtzioak (`relu`, `leaky relu`, `sigmoid`, `softmax`, `argmax`, `argmin`, `normalize`)

Adibide praktiko honetan `linalg` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

## 06.4. Kaputaren azpian: nola dagoen eraikia `linalg` Ridgun hutsean (`src/main/ridgun/lib/linalg.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/linalg.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 06.4.1. Barne-inplementazioa: Internal Scalar Helpers

Ikusi nola `linalg.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 06.4.2. Barne-inplementazioa: Matrix Transpose, Trace, Diagonal & Identity

Ikusi nola `linalg.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 06.4.3. Barne-inplementazioa: Vector & Matrix Norms (`norm_l1`, `norm_l2`, `norm_linf`, `frobenius`)

Ikusi nola `linalg.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 06.4.4. Barne-inplementazioa: Neural Activations (`linalg relu`, `linalg sigmoid`, `linalg softmax`)

Ikusi nola `linalg.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

## 06.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `linalg`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: Matrize singularrek `None` itzultzen dute garbi `linalg solve`-n (`NaN` isilik gabe), eta `linalg softmax`-ek maximoa kentzen du berreketa aurretik gainezkatzeak saihesteko.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/linalg.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test linalg.rg` suite automatizatuaren bidez.

### `linalg`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import linalg` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `linalg`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `linalg`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `linalg` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**07. kapituluan** **`codec`** lib-a sakonki esploratuko dugu (`codec` lib-a — Hex, Base64, Base64url, URL Percent-Encoding eta JSON Arina).
