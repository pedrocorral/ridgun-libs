# 05. kapitulua: `tensor` lib-a — Dimentsio Anitzeko Tentsoreak, Bistak eta Einsteinen Uzkurdura

## 05.1. Zergatik existitzen da `tensor` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `tensor` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `tensor`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: lengoaia gehienetan erakusle sakabanatuz betetako zerrenda habiaratu motel-motelen edo NumPy/BLAS bezalako 200 MB-ko C++/Fortran bloke erraldoi bat estekatzearen artean aukeratu behar duzu.

**`tensor`** lib-ak Ridgunen `Tensor[...]` primitiba natiboa biltzen du, sorrera tipatua (`Tensor[Int]`, `Tensor[Real]`, `Tensor[U64]`), kopiarik gabeko bistak (`reshape`, `slice`), elementuz elementuko eragiketak (Hadamard), Einsteinen uzkurdura eta 64 biteko `BlaMka` aritmetika eskainiz.

Ekosistema tradizional batean, **`TENSOR`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`tensor`** lib-ak (`src/main/ridgun/lib/tensor.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Deklaratu `import tensor` (edo `import tensor as alias`) fitxategiaren hasieran**: lib bakoitzak `module :: tensor` izen-espazioa definitzen du eta `--strict` moduan hitz anitzeko funtzioei zuriune naturalekin deitzen zaie beti.
2. **Kateatu zure datu-hodiak ezkerretik eskuinera `->` bidez**: idatzi `sarrera lehen urratsa -> bigarren urratsa -> emaitza`, erabili `(+ _ _ +)` maskarak sekuentziak desegituratzeko eta kendu `_ =` sententzia sekuentzialetan (edo baztertu `-> ()` bidez).
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `tensor`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 05.2. Artefaktu natiboak, inportazioa eta `tensor` APIaren katalogo osoa

`ridgun-libs`-en, **`tensor`** lehen mailako **lib** bat da, `src/main/ridgun/lib/tensor.rg` bidean kokatua (`TENSOR` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/tensor.rglib` | Banaketa eta inportazio zuzena `import tensor` bidez |
| **Fitxategi konpilatua** | `target/tensor.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libtensor.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib bakoitzak bere izen-espazioa deklaratzen du `module :: tensor` bidez: nahikoa da goiburuan `import tensor` (edo `import tensor as alias`) idaztea eta bere funtzioei zuriune naturalekin (`nire funtzioa x`) eta `->` hodiekin (`x nire funtzioa -> emaitza`) deitzea.

### 05.2.1. `tensor`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `tensor zeros int / tensor fill int / tensor zeros real` | 1D/2D `Tensor[Int]` eta `Tensor[Real]` bloke jarraituak esleitzen ditu |
| `tensor get 1d / tensor set 1d / tensor get 2d / tensor set 2d` | Copy-on-Write (`with [i] = v`) elementuen sarbide eta eguneratze funtzionala |
| `tensor reshape 1d to 2d / tensor slice 1d` | $O(1)$ deskribatzaile-bistak tentsorearen biltegia kopiatu gabe |
| `tensor add int / tensor mul int / tensor scale int` | Elementuz elementuko batuketa, biderketa (Hadamard) eta eskalatzea |
| `tensor dot int / tensor matmul int` | Einsteinen indize-uzkurdura (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `u64 blamka g / u64 rotr` | 64 biteko zeinurik gabeko `U64` nahasketa birakaria bloke kriptografikoetarako |

### 05.2.2. `src/main/ridgun/lib/tensor.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/tensor.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`0` mota, `0` eragile eta `13` funtzio):

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
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

## 05.3. `tensor` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `tensor` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test tensor.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 05.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `tensor` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `tensor` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import tensor

fn :: producto matricial tensor Tensor[Real * r * k] Tensor[Real * k * c] => Tensor[Real * r * c]
      producto matricial tensor a b =
        tensor matmul a b
```

### 05.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`tensor` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import tensor

fn :: combinar bloques Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      combinar bloques a b =
        tensor add blocks a b -> suma
        tensor mul blocks suma b
```

### 05.3.3. 3. adibidea: Tentsoreen sorrera (`zeros`, `ones`, `eye`, `arange`, `linspace`), dimentsioen ikuskapena (`rank`, `len`, `shape`) eta bistak (`reshape`, `transpose`)

Adibide praktiko honetan `tensor` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 05.3.4. 4. adibidea: Elementuz elementuko aljebra (Hadamard `+`, `-`, `*`, `/`, `xor`, `and`, `or`) eta klonazio sakon independentea (`tensor clone`)

Adibide praktiko honetan `tensor` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 05.3.5. 5. adibidea: Matrize-biderketa natiboa (`@`) eta Einsteinen azpiindizeen uzkurdura (`a_ik @ b_kj`)

Adibide praktiko honetan `tensor` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

### 05.3.6. 6. adibidea: 1024 byteko blokeen konpresio kriptografikoa tentsoreen bidez (`f blamka`, `blamka g`, `blamka p16`, `compress block`)

Adibide praktiko honetan `tensor` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

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

## 05.4. Kaputaren azpian: nola dagoen eraikia `tensor` Ridgun hutsean (`src/main/ridgun/lib/tensor.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/tensor.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 05.4.1. Barne-inplementazioa: Core Implementation Part 1

Ikusi nola `tensor.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

### 05.4.2. Barne-inplementazioa: Core Implementation Part 2

Ikusi nola `tensor.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

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

## 05.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `tensor`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: RMM1/RMM2-k estatikoki kudeatutako gelaxkako 8 byteko memoria jarraitua, $O(1)$ bistak bufferra bikoiztu gabe eta Copy-on-Write semantika hutsa.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/tensor.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test tensor.rg` suite automatizatuaren bidez.

### `tensor`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import tensor` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `tensor`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `tensor`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `tensor` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**06. kapituluan** **`linalg`** lib-a sakonki esploratuko dugu (`linalg` lib-a — `Tensor[Real]` gaineko Aljebra Lineala, Bareiss eta Aktibazioak).
