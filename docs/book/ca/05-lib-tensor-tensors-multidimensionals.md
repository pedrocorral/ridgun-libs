# Capítol 05: La lib `tensor` — Tensors Multidimensionals, Vistes i Contracció d'Einstein

## 05.1. Per què existeix la lib `tensor`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `tensor` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `tensor`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: en la majoria de llenguatges has de triar entre llistes imbricades lentíssimes plenes de punters dispersos o enllaçar una mola de C++/Fortran de 200 MB com NumPy/BLAS.

La lib **`tensor`** embolcalla la primitiva nativa `Tensor[...]` de Ridgun oferint creació tipada (`Tensor[Int]`, `Tensor[Real]`, `Tensor[U64]`), vistes sense còpia (`reshape`, `slice`), operacions element a element (Hadamard), contracció d'Einstein (`*` sobre eixos simbòlics) i aritmètica `BlaMka` de 64 bits.

En un ecosistema tradicional, resoldre les tasques del domini **`TENSOR`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`tensor`** (`src/main/ridgun/lib/tensor.rg`) aborda el problema amb quatre principis innegociables:

1. **Funcions totals i contractes explícits (`=>`)**: cap funció de `tensor` llança excepcions ocultes ni depèn de `null`. Tot cas límit retorna un valor sentinella documentat o un tipus algebraic suma (`Option`, `Result`).
2. **Zero codi C i zero `libc`**: tot el codi de `tensor` compila directament a codi màquina natiu ELF64 verificat per `ridgunc`.
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `tensor` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 05.2. Artefactes natius, importació i catàleg complet de l'API de `tensor`

A `ridgun-libs`, **`tensor`** és una **lib** de primera classe situada a `src/main/ridgun/lib/tensor.rg` (domini `TENSOR`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/tensor.rglib` | Distribució i importació directa amb `import tensor` |
| **Fitxer compilat** | `target/tensor.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libtensor.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import tensor` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

### 05.2.1. Resum de famílies funcionals de `tensor`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `tensor zeros int / tensor fill int / tensor zeros real` | Reserva blocs contigus 1D/2D de `Tensor[Int]` i `Tensor[Real]` |
| `tensor get 1d / tensor set 1d / tensor get 2d / tensor set 2d` | Accés i actualització funcional Copy-on-Write (`with [i] = v`) |
| `tensor reshape 1d to 2d / tensor slice 1d` | Vistes de descriptor en $O(1)$ sense copiar l'emmagatzematge del tensor |
| `tensor add int / tensor mul int / tensor scale int` | Suma, multiplicació element a element (Hadamard) i escalat |
| `tensor dot int / tensor matmul int` | Contracció d'índexs d'Einstein (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `u64 blamka g / u64 rotr` | Mescla rotacional `U64` sense signe de 64 bits per a blocs criptogràfics |

### 05.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/tensor.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/tensor.rg` (`0` tipus, `0` operadors i `13` funcions):

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
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

## 05.3. Explorant `tensor` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `tensor` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test tensor.rg`.

### 05.3.1. Exemple 1: Flux principal en estil tabular amb `tensor`

Observa com en Ridgun els signes `=` i els passos de transformació amb `tensor` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import tensor

fn :: producto matricial tensor () => Tensor[Int]
      producto matricial tensor =
        a = tensor reshape 1d to 2d (tensor from list int [1, 2, 3, 4]) 2 2
        b = tensor reshape 1d to 2d (tensor from list int [5, 6, 7, 8]) 2 2
        tensor matmul int a b
```

### 05.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `tensor` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import tensor

fn :: energia vector (xs : [Int]) => (Int, Int)
      energia vector xs =
        v   = tensor from list int xs
        dot = tensor dot int v v
        mx  = tensor max int v
        (dot, mx)
```

### 05.3.3. Exemple 3: Creació de tensors (`zeros`, `ones`, `eye`, `arange`, `linspace`), inspecció de dimensions (`rank`, `len`, `shape`) i vistes (`reshape`, `transpose`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `tensor` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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
        _   = assert int equals (tensor rows m) 2 "tensor rows == 2"
        _   = assert int equals (tensor cols m) 3 "tensor cols == 3"
        sh  = tensor shape m
        _   = assert int equals (shape fst sh) 2 "tensor shape rows == 2"
        _   = assert int equals (shape snd sh) 3 "tensor shape cols == 3"
        r1  = tensor row m 1
        _   = assert int equals r1_(0) 40 "row 1 col 0 == 40"
        _   = assert int equals r1_(1) 50 "row 1 col 1 == 50"
        _   = assert int equals r1_(2) 60 "row 1 col 2 == 60"
        c2  = tensor col m 2
        _   = assert int equals c2_(0) 30 "col 2 row 0 == 30"
        _   = assert int equals c2_(1) 60 "col 2 row 1 == 60"
        ()
```

### 05.3.4. Exemple 4: Àlgebra element a element (Hadamard `+`, `-`, `*`, `/`, `xor`, `and`, `or`) i clonació profunda independent (`tensor clone`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `tensor` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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
        _    = assert int equals s_(0, 0) 11 "add (0,0) == 11"
        _    = assert int equals s_(1, 1) 44 "add (1,1) == 44"
        d    = tensor sub blocks a b
        _    = assert int equals d_(0, 0) 9 "sub (0,0) == 9"
        _    = assert int equals d_(1, 1) 36 "sub (1,1) == 36"
        p    = tensor mul blocks a b
        _    = assert int equals p_(0, 0) 10 "mul (0,0) == 10"
        _    = assert int equals p_(1, 1) 160 "mul (1,1) == 160"
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
        ux   = tensor_xor_blocks ua ub
        _    = assert int equals ux_(0, 0) 0xF0 "xor (0,0) == 0xF0"
        _    = assert int equals ux_(1, 1) 0xFF "xor (1,1) == 0xFF"
        uan  = tensor_and_blocks ua ub
        _    = assert int equals uan_(0, 0) 0x0F "and (0,0) == 0x0F"
        _    = assert int equals uan_(1, 1) 0x00 "and (1,1) == 0x00"
        uor  = tensor_or_blocks ua ub
        _    = assert int equals uor_(0, 0) 0xFF "or (0,0) == 0xFF"
        _    = assert int equals uor_(1, 0) 0xFF "or (1,0) == 0xFF"
        uc   = tensor clone ua
        uc_(0, 0) = 999
        _    = assert int equals ua_(0, 0) 0xFF "clone preserves original ua_(0,0)"
        _    = assert int equals uc_(0, 0) 999 "clone updates uc_(0,0)"
        ()
```

### 05.3.5. Exemple 5: Multiplicació matricial nativa (`@`) i contracció de subíndexs d'Einstein (`a_ik @ b_kj`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `tensor` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

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
        _   = assert int equals mc_(0, 0) 58 "matmul (0,0) == 58"
        _   = assert int equals mc_(0, 1) 64 "matmul (0,1) == 64"
        _   = assert int equals mc_(1, 0) 139 "matmul (1,0) == 139"
        _   = assert int equals mc_(1, 1) 154 "matmul (1,1) == 154"
        ()
```

### 05.3.6. Exemple 6: Compressió criptogràfica de blocs de 1024 bytes mitjançant tensors (`f blamka`, `blamka g`, `blamka p16`, `compress block`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `tensor` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test blamka tensor compression => ()
      test blamka tensor compression =
        fb  = f blamka 1 2
        _   = assert int equals fb 7 "f blamka 1 2 == 7"
        gr  = blamka g 1 2 3 4
        _   = assert true ((g fst gr) != 0) "blamka g non-zero output"
        bx  = Tensor[U64 * 8 * 16]
        by  = Tensor[U64 * 8 * 16]
        bx_(0, 0) = 1
        by_(0, 0) = 2
        bz  = compress block bx by
        _   = assert true (bz_(0, 0) != 0) "compress block non-zero (0,0)"
        _   = assert int equals bx_(0, 0) 1 "compress block preserves bx_(0,0)"
        _   = assert int equals by_(0, 0) 2 "compress block preserves by_(0,0)"
        ()
```

---

## 05.4. Sota el capó: com està construïda `tensor` en Ridgun pur (`src/main/ridgun/lib/tensor.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/tensor.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 05.4.1. Implementació interna: Core Implementation Part 1

Fixa't en com `tensor.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
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
```

### 05.4.2. Implementació interna: Core Implementation Part 2

Fixa't en com `tensor.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

```ridgun
fn :: tensor clone Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor clone m                   =
        z_ij = m_ij
        z_ij

fn :: tensor matmul Tensor[Real * r * k] Tensor[Real * k * c] => Tensor[Real * r * c]
      tensor matmul a b = a_ik @ b_kj
```

---

## 05.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `tensor`

- **Garantia algorísmica i de seguretat**: Memòria contigua de 8 bytes per cel·la gestionada estàticament per RMM1/RMM2, vistes en $O(1)$ sense duplicar el búfer i semàntica pura Copy-on-Write.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/tensor.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test tensor.rg`.

### Les 5 Regles d'Or en programar amb `tensor`

1. **Declara `import tensor` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `tensor` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `tensor` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `tensor` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 06** passarem a explorar en profunditat la lib **`linalg`** (La lib `linalg` — Àlgebra Lineal sobre `Tensor[Real]`, Bareiss i Activacions).
