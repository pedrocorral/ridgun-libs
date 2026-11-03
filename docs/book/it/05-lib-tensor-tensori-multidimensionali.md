# Capitolo 05: La lib `tensor` — Tensori Multidimensionali, Viste e Contrazione di Einstein

## 05.1. Perché esiste la lib `tensor`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `tensor` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `tensor`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: nella maggior parte dei linguaggi devi scegliere tra liste annidate lentissime piene di puntatori sparsi o collegare un colosso C++/Fortran da 200 MB come NumPy/BLAS.

La lib **`tensor`** incapsula la primitiva nativa `Tensor[...]` di Ridgun offrendo creazione tipizzata (`Tensor[Int]`, `Tensor[Real]`, `Tensor[U64]`), viste zero-copy (`reshape`, `slice`), operazioni elemento per elemento (Hadamard), contrazione di Einstein (`*` su assi simbolici) e aritmetica `BlaMka` a 64 bit.

In un ecosistema tradizionale, risolvere i compiti del dominio **`TENSOR`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`tensor`** (`src/main/ridgun/lib/tensor.rg`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import tensor` (o `import tensor as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: tensor` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `tensor` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 05.2. Artefatti nativi, importazione e catalogo completo dell'API di `tensor`

In `ridgun-libs`, **`tensor`** è una **lib** di prima classe situata in `src/main/ridgun/lib/tensor.rg` (dominio `TENSOR`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/tensor.rglib` | Distribuzione e importazione diretta con `import tensor` |
| **File compilato** | `target/tensor.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libtensor.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: tensor`: basta scrivere `import tensor` (o `import tensor as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 05.2.1. Riepilogo delle famiglie funzionali di `tensor`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `tensor zeros int / tensor fill int / tensor zeros real` | Alloca blocchi contigui 1D/2D di `Tensor[Int]` e `Tensor[Real]` |
| `tensor get 1d / tensor set 1d / tensor get 2d / tensor set 2d` | Accesso e aggiornamento funzionale Copy-on-Write (`with [i] = v`) |
| `tensor reshape 1d to 2d / tensor slice 1d` | Viste descrittore in $O(1)$ senza copiare il buffer del tensore |
| `tensor add int / tensor mul int / tensor scale int` | Somma, moltiplicazione elemento per elemento (Hadamard) e scalatura |
| `tensor dot int / tensor matmul int` | Contrazione degli indici di Einstein (`a[i] * b[i]`, `a[i, k] * b[k, j]`) |
| `u64 blamka g / u64 rotr` | Mixing rotazionale `U64` senza segno a 64 bit per blocchi crittografici |

### 05.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/tensor.rg`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/tensor.rg` (`0` tipi, `0` operatori e `13` funzioni):

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
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

## 05.3. Esplorare `tensor` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `tensor` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test tensor.rg`.

### 05.3.1. Esempio 1: Flusso principale in stile tabulare con `tensor`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `tensor` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import tensor

fn :: producto matricial tensor Tensor[Real * r * k] Tensor[Real * k * c] => Tensor[Real * r * c]
      producto matricial tensor a b =
        tensor matmul a b
```

### 05.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `tensor` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import tensor

fn :: combinar bloques Tensor[Int * r * c] Tensor[Int * r * c] => Tensor[Int * r * c]
      combinar bloques a b =
        tensor add blocks a b -> suma
        tensor mul blocks suma b
```

### 05.3.3. Esempio 3: Creazione di tensori (`zeros`, `ones`, `eye`, `arange`, `linspace`), ispezione delle dimensioni (`rank`, `len`, `shape`) e viste (`reshape`, `transpose`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `tensor` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 05.3.4. Esempio 4: Algebra elemento per elemento (Hadamard `+`, `-`, `*`, `/`, `xor`, `and`, `or`) e clonazione profonda indipendente (`tensor clone`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `tensor` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 05.3.5. Esempio 5: Moltiplicazione matriciale nativa (`@`) e contrazione degli indici di Einstein (`a_ik @ b_kj`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `tensor` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

### 05.3.6. Esempio 6: Compressione crittografica di blocchi da 1024 byte tramite tensori (`f blamka`, `blamka g`, `blamka p16`, `compress block`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `tensor` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

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

## 05.4. Sotto il cofano: come è costruita `tensor` in Ridgun puro (`src/main/ridgun/lib/tensor.rg`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/tensor.rg` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 05.4.1. Implementazione interna: Core Implementation Part 1

Nota come `tensor.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

### 05.4.2. Implementazione interna: Core Implementation Part 2

Nota come `tensor.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

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

## 05.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `tensor`

- **Garanzia algoritmica e di sicurezza**: Memoria contigua da 8 byte per cella gestita staticamente da RMM1/RMM2, viste in $O(1)$ senza duplicare il buffer e semantica pura Copy-on-Write.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/tensor.rg` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test tensor.rg`.

### Le 5 Regole d'Oro quando programmi con `tensor`

1. **Dichiara `import tensor` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `tensor` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `tensor` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `tensor` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 06** passeremo a esplorare in profondità la lib **`linalg`** (La lib `linalg` — Algebra Lineare su `Tensor[Real]`, Bareiss e Attivazioni).
