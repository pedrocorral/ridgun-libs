# Kapitel 05: Lib:en `tensor` — Flerdimensionella Tensorer, Vyer och Einsteinkontraktion

## 05.1. Varför finns lib:en `tensor`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `tensor`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `tensor`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: i de flesta språk måste du välja mellan långsamma nästlade listor fulla av pekare eller att länka in ett C++/Fortran-paket på 200 MB som NumPy/BLAS.

Lib:en **`tensor`** kapslar in Ridguns inbyggda `Tensor[...]`-primitiv med typade konstruktörer (`Tensor[Int]`, `Tensor[Real]`, `Tensor[U64]`), kopieringsfria vyer (`reshape`, `slice`), elementvisa Hadamard-operationer, Einsteinkontraktion och 64-bitars `BlaMka`-aritmetik.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`TENSOR`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`tensor`** (`src/main/ridgun/lib/tensor.rg`) problemet genom fyra kompromisslösa principer:

1. **Totala funktioner och explicita kontrakt (`=>`)**: ingen funktion i `tensor` kastar dolda undantag eller förlitar sig på `null`. Varje gränsfall returnerar ett dokumenterat sentinelvärde eller en algebraisk summatyp (`Option`, `Result`).
2. **Noll C-kod och noll `libc`**: varje rad i `tensor` kompileras direkt till inbyggd ELF64-maskinkod verifierad av `ridgunc`.
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `tensor` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 05.2. Inbyggda artefakter, import och komplett API-katalog för `tensor`

I `ridgun-libs` är **`tensor`** en förstklassig **lib** placerad i `src/main/ridgun/lib/tensor.rg` (domän `TENSOR`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/tensor.rglib` | Portabel distribution och direkt import med `import tensor` |
| **Kompilerat arkiv** | `target/tensor.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libtensor.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import tensor` överst och anropar funktionerna med mellanslag eller understreck.

### 05.2.1. Översikt över funktionella familjer i `tensor`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `tensor zeros int / tensor fill int / tensor zeros real` | Allokerar sammanhängande 1D/2D-block av `Tensor[Int]` och `Tensor[Real]` |
| `tensor get 1d / tensor set 1d / tensor get 2d / tensor set 2d` | Funktionell Copy-on-Write-åtkomst och uppdatering (`with [i] = v`) |
| `tensor reshape 1d to 2d / tensor slice 1d` | $O(1)$-deskriptorvyer utan att kopiera tensorns underliggande lagring |
| `tensor add int / tensor mul int / tensor scale int` | Elementvis Hadamard-addition, multiplikation och skalning |
| `tensor dot int / tensor matmul int` | Einsteinkontraktion över index (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `u64 blamka g / u64 rotr` | 64-bitars teckenlös `U64`-rotationsblandning för kryptografiska block |

### 05.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/tensor.rg`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/tensor.rg` (`0` typer, `0` operatorer och `13` funktioner):

| # | Funktion / Signatur (`fn ::`) | Returtyp |
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

## 05.3. Djupdykning i `tensor`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `tensor` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test tensor.rg`.

### 05.3.1. Exempel 1: Huvudflöde i tabellform med `tensor`

Lägg märke till hur `=`-tecknen och transformationsstegen med `tensor` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import tensor

fn :: producto matricial tensor () => Tensor[Int]
      producto matricial tensor =
        a = tensor reshape 1d to 2d (tensor from list int [1, 2, 3, 4]) 2 2
        b = tensor reshape 1d to 2d (tensor from list int [5, 6, 7, 8]) 2 2
        tensor matmul int a b
```

### 05.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `tensor` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 32 libs i `ridgun-libs`:

```ridgun
import tensor

fn :: energia vector (xs : [Int]) => (Int, Int)
      energia vector xs =
        v   = tensor from list int xs
        dot = tensor dot int v v
        mx  = tensor max int v
        (dot, mx)
```

### 05.3.3. Exempel 3: Skapande av tensorer (`zeros`, `ones`, `eye`, `arange`, `linspace`), dimensionsinspektion (`rank`, `len`, `shape`) och vyer (`reshape`, `transpose`)

I detta praktiska exempel undersöker vi grundligt hur `tensor` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 05.3.4. Exempel 4: Elementvis Hadamard-algebra (`+`, `-`, `*`, `/`, `xor`, `and`, `or`) och djup oberoende kloning (`tensor clone`)

I detta praktiska exempel undersöker vi grundligt hur `tensor` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 05.3.5. Exempel 5: Inbyggd matrismultiplikation (`@`) och Einsteins indexkontraktion (`a_ik @ b_kj`)

I detta praktiska exempel undersöker vi grundligt hur `tensor` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

### 05.3.6. Exempel 6: Kryptografisk komprimering av 1024-bytesblock med tensorer (`f blamka`, `blamka g`, `blamka p16`, `compress block`)

I detta praktiska exempel undersöker vi grundligt hur `tensor` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

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

## 05.4. Under huven: hur `tensor` är byggd i ren Ridgun (`src/main/ridgun/lib/tensor.rg`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/tensor.rg` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 05.4.1. Intern implementation: Core Implementation Part 1

Se hur `tensor.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

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

### 05.4.2. Intern implementation: Core Implementation Part 2

Se hur `tensor.rg` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: tensor clone Tensor[U64 * r * c] => Tensor[U64 * r * c]
      tensor clone m                   =
        z_ij = m_ij
        z_ij

fn :: tensor matmul Tensor[Real * r * k] Tensor[Real * k * c] => Tensor[Real * r * c]
      tensor matmul a b = a_ik @ b_kj
```

---

## 05.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `tensor`

- **Algoritmisk garanti och säkerhet**: Sammanhängande 8-bytesjusterat minne statiskt hanterat av RMM1/RMM2, $O(1)$-vyer utan buffertkopiering och ren Copy-on-Write-semantik.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/tensor.rg` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test tensor.rg`.

### De 5 Gyllene Reglerna när du programmerar med `tensor`

1. **Deklarera `import tensor` överst i filen** och utnyttja att mellanslag och understreck är utbytbara så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `tensor`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `tensor`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `tensor` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 06** går vi vidare och utforskar lib:en **`linalg`** på djupet (Lib:en `linalg` — Linjär Algebra över `Tensor[Real]`, Bareiss-lösare och Aktiveringar).
