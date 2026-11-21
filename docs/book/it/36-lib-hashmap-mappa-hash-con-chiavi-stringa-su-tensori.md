# Capitolo 36: La lib `hashmap` — Mappa Hash da Chiavi `String` a Qualsiasi Valore, su Tensori e con Seme SipHash

## 36.1. Perché esiste la lib `hashmap`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `hashmap` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `hashmap`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: contare parole o raggruppare centomila record con una lista di associazioni è quadratico, e un albero ordinato paga un logaritmo e un'allocazione a ogni inserimento quando tutto ciò che ti serve è trovare una chiave.

La lib **`hashmap`** implementa `HashMap V`, una mappa da chiavi `String` a valori di qualsiasi tipo, costruita su tensori: una tabella di slot a indirizzamento aperto e ispezione lineare, piena al massimo per metà, punta a tensori densi di chiavi e di valori mantenuti in ordine di inserimento. L'hash delle chiavi è calcolato con SipHash-1-3 (la lib `hash`) con un seme casuale per ogni mappa; `hashmap put`, `hashmap add`, `hashmap get` e `hashmap has` richiedono tempo atteso costante, e `hashmap pairs` restituisce le voci in ordine di inserimento.

In un ecosistema tradizionale, risolvere i compiti del dominio **`HASHMAP`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`hashmap`** (`src/main/ridgun/lib/hashmap.ridgun`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import hashmap` (o `import hashmap as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: hashmap` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `hashmap` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 36.2. Artefatti nativi, importazione e catalogo completo dell'API di `hashmap`

In `ridgun-libs`, **`hashmap`** è una **lib** di prima classe situata in `src/main/ridgun/lib/hashmap.ridgun` (dominio `HASHMAP`). Compilando con `stable bundle`, viene impacchettata in un artefatto nativo:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/hashmap.ridgunlib` | Distribuzione e importazione diretta con `import hashmap` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: hashmap`: basta scrivere `import hashmap` (o `import hashmap as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 36.2.1. Riepilogo delle famiglie funzionali di `hashmap`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `hashmap empty` | Una nuova mappa vuota; il tipo dei suoi valori è fissato dal primo valore memorizzato |
| `hashmap put / hashmap get / hashmap has` | Inserisce o sostituisce, legge con un valore predefinito e verifica l'appartenenza, in tempo atteso costante |
| `hashmap add` | Aggiunge un `Int` al valore di una chiave (una chiave mancante parte da 0): un contatore in una sola ispezione |
| `hashmap size / hashmap pairs` | Il numero di chiavi e le voci `[String V]` in ordine di inserimento |

### 36.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/hashmap.ridgun`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/hashmap.ridgun` (`1` tipi, `0` operatori e `35` funzioni):

**Tipi algebrici e record (`type`) di `hashmap`:**

```ridgun
type HashMap V = fill: [V], vals: [Tensor[V * n]], slots: Tensor[Int * n], keys: Tensor[String * n], cap: Int, room: Int, count: Tensor[Int * k], seed: String
```

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
|---|---|---|
| `1` | `fn :: hm hash String String` | `Int` |
| `2` | `fn :: hm seed16 String` | `String` |
| `3` | `fn :: hm read seed Int` | `String` |
| `4` | `fn :: hm new seed` | `String` |
| `5` | `fn :: hm slot hash Int` | `Int` |
| `6` | `fn :: hm probe Tensor[Int * n] Tensor[String * m] Int String Int Int` | `Int` |
| `7` | `fn :: hm free Tensor[Int * n] Int Int` | `Int` |
| `8` | `fn :: hashmap empty` | `HashMap V` |
| `9` | `fn :: hm size (HashMap V)` | `Int` |
| `10` | `fn :: hm bump Tensor[Int * k]` | `()` |
| `11` | `fn :: hm vt [Tensor[V * n]]` | `Tensor[V * n]` |
| `12` | `fn :: hm rehash Tensor[Int * n] Tensor[Int * m] Int Int Int` | `()` |
| `13` | `fn :: hm grow slots (HashMap V)` | `HashMap V` |
| `14` | `fn :: hm copy Tensor[String * n] Tensor[V * n] Tensor[String * m] Tensor[V * m] Int Int` | `()` |
| `15` | `fn :: hm grow dense (HashMap V) [V]` | `HashMap V` |
| `16` | `fn :: hm make room (HashMap V)` | `HashMap V` |
| `17` | `fn :: hm room slots (HashMap V)` | `HashMap V` |
| `18` | `fn :: hm room dense (HashMap V)` | `HashMap V` |
| `19` | `fn :: hm ensure vals (HashMap V) V` | `HashMap V` |
| `20` | `fn :: hm insert Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] Int Int String V` | `()` |
| `21` | `fn :: hm put go (HashMap V) (HashMap V) String V` | `HashMap V` |
| `22` | `fn :: hm put at (HashMap V) Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String V Int Int` | `HashMap V` |
| `23` | `fn :: hm put slot (HashMap V) Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String V Int Int` | `HashMap V` |
| `24` | `fn :: hashmap put (HashMap V) String V` | `HashMap V` |
| `25` | `fn :: hm add go (HashMap Int) (HashMap Int) String Int` | `HashMap Int` |
| `26` | `fn :: hm add at (HashMap Int) Tensor[Int * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String Int Int Int` | `HashMap Int` |
| `27` | `fn :: hm add slot (HashMap Int) Tensor[Int * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String Int Int Int` | `HashMap Int` |
| `28` | `fn :: hashmap add (HashMap Int) String Int` | `HashMap Int` |
| `29` | `fn :: hm lookup Tensor[Int * c] Tensor[String * r] Int String Int` | `Int` |
| `30` | `fn :: hm get at Tensor[V * n] Int V` | `V` |
| `31` | `fn :: hashmap get (HashMap V) String V` | `V` |
| `32` | `fn :: hashmap has (HashMap V) String` | `Bool` |
| `33` | `fn :: hashmap size (HashMap V)` | `Int` |
| `34` | `fn :: hm pairs loop Tensor[String * n] Tensor[V * n] Int [String V]` | `[String V]` |
| `35` | `fn :: hashmap pairs (HashMap V)` | `[String V]` |

---

## 36.3. Esplorare `hashmap` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `hashmap` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test hashmap.ridgun`.

### 36.3.1. Esempio 1: Flusso principale in stile tabulare con `hashmap`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `hashmap` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import hashmap

fn :: contar visitas [String]     (HashMap Int) => HashMap Int
      contar visitas []           m             =  m
      contar visitas (ruta:resto) m             =  contar visitas resto (hashmap add m ruta 1)
```

### 36.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `hashmap` è progettata per comporsi con le guardie booleane `|` e con il resto delle 38 lib di `ridgun-libs`:

```ridgun
import hashmap

fn :: visitas de (HashMap Int) String => Int
      visitas de m ruta =
        | hashmap has m ruta = hashmap get m ruta 0
        | otherwise          = 0
```

### 36.3.3. Esempio 3: La mappa vuota, `hashmap put`, sostituzione, `hashmap get` con un valore predefinito e `hashmap pairs`

In questo esempio pratico esploriamo in modo esaustivo come si comporta `hashmap` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test hashmap basics => ()
      test hashmap basics =
        e = hashmap empty
        hashmap get e "a" 7 -> assert int equals 7 "AC1: get on empty gives the default"
        hashmap has e "a" -> assert false "AC1: has on empty"
        hashmap size e -> assert int equals 0 "AC1: size of empty"
        hashmap pairs e -> assert eq []

        m = hashmap put (hashmap put (hashmap put hashmap empty "b" 2) "a" 1) "c" 3
        m2 = hashmap put m "a" 10
        hashmap get m2 "a" 0 -> assert int equals 10 "AC1: put replaces the value"
        hashmap get m2 "b" 0 -> assert int equals 2 "AC1: get b"
        hashmap get m2 "zz" (0 - 1) -> assert int equals (0 - 1) "AC1: missing key gives the default"
        hashmap has m2 "c" -> assert true "AC1: has c"
        hashmap has m2 "zz" -> assert false "AC1: has missing"
        hashmap size m2 -> assert int equals 3 "AC1: replacing does not add a key"
        hashmap pairs m2 -> assert eq [("b", 2), ("a", 10), ("c", 3)]
        ()
```

### 36.3.4. Esempio 4: Contatori con `hashmap add`: somme, chiavi mancanti e arrivo a zero

In questo esempio pratico esploriamo in modo esaustivo come si comporta `hashmap` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test hashmap add => ()
      test hashmap add =
        m = hashmap add (hashmap add (hashmap add hashmap empty "x" 2) "y" 5) "x" 3
        hashmap get m "x" 0 -> assert int equals 5 "AC2: add sums"
        hashmap get m "y" 0 -> assert int equals 5 "AC2: a missing key starts at 0"
        m2 = hashmap add m "y" (0 - 5)
        hashmap get m2 "y" 99 -> assert int equals 0 "AC2: add can reach 0 and the key stays"
        hashmap has m2 "y" -> assert true "AC2: has after reaching 0"
        hashmap pairs m2 -> assert eq [("x", 5), ("y", 0)]
        ()
```

### 36.3.5. Esempio 5: Chiavi insolite: la stringa vuota, byte sopra 127 e chiavi da 10 KB che differiscono nell'ultimo byte

In questo esempio pratico esploriamo in modo esaustivo come si comporta `hashmap` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test hashmap unusual keys => ()
      test hashmap unusual keys =
        hi = (char from code 200) + (char from code 255)
        la = kb10 "a"
        lb = kb10 "b"
        m = hashmap put (hashmap put (hashmap put (hashmap put hashmap empty "" 1) hi 2) la 3) lb 4
        hashmap get m "" 0 -> assert int equals 1 "AC3: empty key"
        hashmap get m hi 0 -> assert int equals 2 "AC3: bytes >= 128"
        hashmap get m la 0 -> assert int equals 3 "AC3: 10 KB key"
        hashmap get m lb 0 -> assert int equals 4 "AC3: 10 KB key differing in the last byte"
        hashmap has m (kb10 "c") -> assert false "AC3: another 10 KB key is missing"
        hashmap has m (char from code 200) -> assert false "AC3: prefix of a key is missing"
        hashmap size m -> assert int equals 4 "AC3: four keys"
        ()
```

### 36.3.6. Esempio 6: Valori record: una `HashMap` di record definiti dall'utente

In questo esempio pratico esploriamo in modo esaustivo come si comporta `hashmap` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test hashmap record values => ()
      test hashmap record values =
        m = hashmap put (hashmap put (hashmap put hashmap empty "/a" (Visit "/a" 3)) "/b" (Visit "/b" 7)) "/a" (Visit "/a" 4)
        hashmap get m "/a" (Visit "" 0) -> assert eq (Visit "/a" 4)
        hashmap get m "/b" (Visit "" 0) -> assert eq (Visit "/b" 7)
        hashmap get m "/c" (Visit "" 0) -> assert eq (Visit "" 0)
        hits (hashmap get m "/a" (Visit "" 0)) -> assert int equals 4 "AC4: record field"
        ()
```

### 36.3.7. Esempio 7: Crescita: 20 000 chiavi, ogni chiave trovata e ordine di inserimento preservato

In questo esempio pratico esploriamo in modo esaustivo come si comporta `hashmap` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test hashmap growth => ()
      test hashmap growth =
        n = 20000
        m = put many hashmap empty 0 n
        hashmap size m -> assert int equals n "AC1: 20000 keys after growing"
        all found m 0 n -> assert true "AC1: every key found after growing"
        ps = hashmap pairs m
        sum values ps 0 -> assert int equals (n * (n - 1) / 2) "AC1: pairs hold every value"
        first keys ps 3 [] -> assert eq ["key 0", "key 1", "key 2"]
        fill 1 + count [] + str len seed -> assert int equals 7 "Program functions named like fields still work"
        ()
```

---

## 36.4. Sotto il cofano: come è costruita `hashmap` in Ridgun puro (`src/main/ridgun/lib/hashmap.ridgun`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/hashmap.ridgun` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 36.4.1. Implementazione interna: Hash

Nota come `hashmap.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
-- 31 bits of SipHash-1-3 of the key, with the map's 16-byte seed as the hash key (the compiler's native
-- `siphash13 range low`, ridgunc 1.0.44), plus 1 so a used slot is never 0.
-- Keys are always compared when the hashes match.
-- The per-map random seed stops chosen keys from colliding on purpose.
fn :: hm hash String String => Int
      hm hash seed key =  ((siphash13 range low seed key 0 (str len key)) % 2147483648) + 1

-- Exactly 16 bytes: SipHash takes a 128-bit key.
fn :: hm seed16 String => String
      hm seed16 s =
        | (str len s) == 16 = s
        | otherwise         = str slice (s + "ridgun-hashmap-0") 0 16

fn :: hm read seed Int => String
      hm read seed fd =
        | fd < 0    = hm seed16 (int to str (sys time ms))
        | otherwise =
          s = sys read fd fd 16
          sys close fd -> ()
          hm seed16 s

fn :: hm new seed => String
      hm new seed = hm read seed (sys open mode "/dev/urandom" "r")
```

### 36.4.2. Implementazione interna: Slots

Nota come `hashmap.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: hm slot hash Int => Int
      hm slot hash s = s / 2147483648

-- Slot of key k with hash h: the slot that holds it, or the free slot where it goes.
-- Hot path: the slot is decoded inline (each call costs about 20 ns).
fn :: hm probe Tensor[Int * n] Tensor[String * m] Int String Int Int => Int
      hm probe slots keys cap k h i =
        | slots_(i) == 0                          = i
        | slots_(i) / 2147483648 != h             = hm probe slots keys cap k h ((i + 1) % cap)
        | keys_(slots_(i) % 2147483648) == k      = i
        | otherwise                               = hm probe slots keys cap k h ((i + 1) % cap)

-- First free slot from i; for rehashing, where every key is known to be new.
fn :: hm free Tensor[Int * n] Int Int => Int
      hm free slots cap i =
        | slots_(i) == 0 = i
        | otherwise      = hm free slots cap ((i + 1) % cap)
```

### 36.4.3. Implementazione interna: Table

Nota come `hashmap.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: hashmap empty => HashMap V
      hashmap empty = HashMap [] [] (Tensor[Int * 16]) (Tensor[String * 8]) 16 8 (Tensor[Int * 1]) (hm new seed)

fn :: hm size (HashMap V) => Int
      hm size m = (count m)_(0)

fn :: hm bump Tensor[Int * k] => ()
      hm bump t =
        t_(0) = t_(0) + 1

fn :: hm vt [Tensor[V * n]] => Tensor[V * n]
      hm vt (t:_) = t

-- Copies every used slot to the new table, by its stored hash. Int only.
fn :: hm rehash Tensor[Int * n] Tensor[Int * m] Int Int Int => ()
      hm rehash old new i ocap ncap =
        | i >= ocap     = ()
        | old_(i) == 0  = hm rehash old new (i + 1) ocap ncap
        | otherwise     =
          s = old_(i)
          new_(hm free new ncap ((hm slot hash s) % ncap)) = s
          hm rehash old new (i + 1) ocap ncap

fn :: hm grow slots (HashMap V) => HashMap V
      hm grow slots m =
        ncap = 2 * (cap m)
        ns   = Tensor[Int * ncap]
        hm rehash (slots m) ns 0 (cap m) ncap
        m with slots = ns, cap = ncap

fn :: hm copy Tensor[String * n] Tensor[V * n] Tensor[String * m] Tensor[V * m] Int Int => ()
      hm copy ok ov nk nv i n =
        | i >= n    = ()
        | otherwise =
          nk_(i) = ok_(i)
          nv_(i) = ov_(i)
          hm copy ok ov nk nv (i + 1) n

fn :: hm grow dense (HashMap V) [V] => HashMap V
      hm grow dense m (d:_) =
        nr = 2 * (room m)
        nk = Tensor[String * nr]
        nv = Tensor[V * nr] with d
        hm copy (keys m) (hm vt (vals m)) nk nv 0 (hm size m)
        m with keys = nk, vals = [nv], room = nr

-- Keeps the slot table at most half full and room for one more key.
fn :: hm make room (HashMap V) => HashMap V
      hm make room m = hm room dense (hm room slots m)

fn :: hm room slots (HashMap V) => HashMap V
      hm room slots m =
        | 2 * ((hm size m) + 1) > cap m = hm grow slots m
        | otherwise                      = m

fn :: hm room dense (HashMap V) => HashMap V
      hm room dense m =
        | (hm size m) + 1 > room m = hm grow dense m (fill m)
        | otherwise                  = m

-- The first insert supplies the fill value for the value tensor.
fn :: hm ensure vals (HashMap V) V => HashMap V
      hm ensure vals m v = m with fill = [v], vals = [Tensor[V * (room m)] with v]

-- Puts a new key at the next position and points slot i at it.
fn :: hm insert Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] Int Int String V => ()
      hm insert vt st kt cnt i h k v =
        pos = cnt_(0)
        kt_(pos) = k
        vt_(pos) = v
        st_(i) = h * 2147483648 + pos
        cnt_(0) = pos + 1

-- The hot paths take the record apart once in the clause: each field accessor
-- is a call of about 40 ns.

fn :: hm put go (HashMap V) (HashMap V) String V => HashMap V
      hm put go m (HashMap []   _      _  _  _   _    _   _   ) k v = hashmap put (hm ensure vals m v) k v
      hm put go m (HashMap _ (vt:_) st kt cap room cnt seed) k v =
        | 2 * (cnt_(0) + 1) > cap or cnt_(0) + 1 > room = hashmap put (hm make room m) k v
        | otherwise = hm put at m vt st kt cnt k v (hm hash seed k) cap

fn :: hm put at (HashMap V) Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String V Int Int => HashMap V
      hm put at m vt st kt cnt k v h cap = hm put slot m vt st kt cnt k v h (hm probe st kt cap k h (h % cap))

fn :: hm put slot (HashMap V) Tensor[V * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String V Int Int => HashMap V
      hm put slot m vt st kt cnt k v h i =
        | st_(i) == 0 =
          hm insert vt st kt cnt i h k v
          m
        | otherwise =
          vt_(st_(i) % 2147483648) = v
          m

fn :: hashmap put (HashMap V) String V => HashMap V
      hashmap put m k v = hm put go m m k v

fn :: hm add go (HashMap Int) (HashMap Int) String Int => HashMap Int
      hm add go m (HashMap []   _      _  _  _   _    _   _   ) k d = hashmap add (hm ensure vals m 0) k d
      hm add go m (HashMap _ (vt:_) st kt cap room cnt seed) k d =
        | 2 * (cnt_(0) + 1) > cap or cnt_(0) + 1 > room = hashmap add (hm make room m) k d
        | otherwise = hm add at m vt st kt cnt k d (hm hash seed k) cap

fn :: hm add at (HashMap Int) Tensor[Int * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String Int Int Int => HashMap Int
      hm add at m vt st kt cnt k d h cap = hm add slot m vt st kt cnt k d h (hm probe st kt cap k h (h % cap))

fn :: hm add slot (HashMap Int) Tensor[Int * n] Tensor[Int * c] Tensor[String * r] Tensor[Int * k] String Int Int Int => HashMap Int
      hm add slot m vt st kt cnt k d h i =
        | st_(i) == 0 =
          hm insert vt st kt cnt i h k d
          m
        | otherwise =
          p = st_(i) % 2147483648
          vt_(p) = vt_(p) + d
          m

-- Adds d to the value of k; a missing key starts at 0. For counting.
fn :: hashmap add (HashMap Int) String Int => HashMap Int
      hashmap add m k d = hm add go m m k d

-- Slot content for k: 0 when k is missing, otherwise hash * 2^31 + position.
fn :: hm lookup Tensor[Int * c] Tensor[String * r] Int String Int => Int
      hm lookup st kt cap k h = st_(hm probe st kt cap k h (h % cap))

fn :: hm get at Tensor[V * n] Int V => V
      hm get at vt s d =
        | s == 0    = d
        | otherwise = vt_(s % 2147483648)

-- The value of k, or d when k is missing.
fn :: hashmap get (HashMap V) String V => V
      hashmap get (HashMap _ []     _  _  _   _ _   _   ) k d = d
      hashmap get (HashMap _ (vt:_) st kt cap _ _   seed) k d = hm get at vt (hm lookup st kt cap k (hm hash seed k)) d

fn :: hashmap has (HashMap V) String => Bool
      hashmap has (HashMap _ []     _  _  _   _ _ _   ) k = False
      hashmap has (HashMap _ (vt:_) st kt cap _ _ seed) k = hm lookup st kt cap k (hm hash seed k) != 0

fn :: hashmap size (HashMap V) => Int
      hashmap size m = hm size m

fn :: hm pairs loop Tensor[String * n] Tensor[V * n] Int [String V] => [String V]
      hm pairs loop ks vt i acc =
        | i < 0     = acc
        | otherwise = hm pairs loop ks vt (i - 1) ([(ks_(i), vt_(i))] :: acc)

-- Every (key, value) pair, in the order the keys were first inserted.
fn :: hashmap pairs (HashMap V) => [String V]
      hashmap pairs m =
        | hm size m == 0 = []
        | otherwise      = hm pairs loop (keys m) (hm vt (vals m)) ((hm size m) - 1) []
```

---

## 36.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `hashmap`

- **Garanzia algoritmica e di sicurezza**: La mappa viene aggiornata sul posto e cresce per raddoppio, quindi `n` inserimenti costano $O(n)$ in totale; usa sempre la mappa restituita da un'operazione (`ADR-0009`). Un seme casuale per ogni mappa impedisce a un attaccante di scegliere chiavi che collidono.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/hashmap.ridgun` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test hashmap.ridgun`.

### Le 5 Regole d'Oro quando programmi con `hashmap`

1. **Dichiara `import hashmap` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `hashmap` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `hashmap` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `hashmap` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 37** passeremo a esplorare in profondità la lib **`tls`** (La lib `tls` — Client TLS 1.3 e TLS 1.2, Validazione della Catena X.509 e Verifica dell'Hostname).
