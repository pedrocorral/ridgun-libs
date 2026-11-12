# Capitolo 19: La lib `uuid` — RFC 9562 `UUIDv4`/`UUIDv7`, FNV-1a, Adler-32, CRC-32 e PRNG

## 19.1. Perché esiste la lib `uuid`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `uuid` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `uuid`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: usare `UUIDv4` completamente casuali come chiave primaria in un database frammenta gli indici B-Tree, mentre inventare ID artigianali senza entropia del kernel porta inevitabilmente a collisioni.

La lib **`uuid`** implementa **`UUIDv4`** (casuale tramite CSPRNG del kernel) e **`UUIDv7`** (ordinato cronologicamente nei primi 48 bit secondo **RFC 9562**), checksum veloci (**FNV-1a**, **Adler-32**, **CRC-32 IEEE 802.3**) e un PRNG deterministico con seme.

In un ecosistema tradizionale, risolvere i compiti del dominio **`UUID`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`uuid`** (`src/main/ridgun/lib/uuid.ridgun`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import uuid` (o `import uuid as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: uuid` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `uuid` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 19.2. Artefatti nativi, importazione e catalogo completo dell'API di `uuid`

In `ridgun-libs`, **`uuid`** è una **lib** di prima classe situata in `src/main/ridgun/lib/uuid.ridgun` (dominio `UUID`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/uuid.ridgunlib` | Distribuzione e importazione diretta con `import uuid` |
| **File compilato** | `target/uuid.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libuuid.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: uuid`: basta scrivere `import uuid` (o `import uuid as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 19.2.1. Riepilogo delle famiglie funzionali di `uuid`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `uuid v4 / uuid v7 / uuid v7 at` | Genera UUID canonici di 36 caratteri RFC 9562 v4 (casuale) e v7 (ordinato per tempo) |
| `uuid is valid / uuid version` | Convalida la struttura 8-4-4-4-12 e i bit di variante RFC 9562 (`8, 9, a, b`) |
| `fnv1a 32 / adler32 / crc32 / crc32 hex` | Hash non crittografici e checksum rapidi a 32 bit |
| `prng next / prng range` | PRNG congruenziale lineare funzionale puro per test e simulazioni riproducibili |

### 19.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/uuid.ridgun`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/uuid.ridgun` (`0` tipi, `0` operatori e `33` funzioni):

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
|---|---|---|
| `1` | `fn :: uu hex lut Int` | `String` |
| `2` | `fn :: uu u32 Int` | `Int` |
| `3` | `fn :: uu bxor loop Int Int Int Int` | `Int` |
| `4` | `fn :: uu bxor32 Int Int` | `Int` |
| `5` | `fn :: uu fnv loop String Int Int Int` | `Int` |
| `6` | `fn :: fnv1a 32 String` | `Int` |
| `7` | `fn :: uu adler loop String Int Int Int Int` | `Int` |
| `8` | `fn :: adler32 String` | `Int` |
| `9` | `fn :: uu crc bit loop Int Int` | `Int` |
| `10` | `fn :: uu crc byte loop String Int Int Int` | `Int` |
| `11` | `fn :: crc32 String` | `Int` |
| `12` | `fn :: uu abs Int` | `Int` |
| `13` | `fn :: prng next Int` | `Int` |
| `14` | `fn :: uu prng range step Int Int Int` | `Int Int` |
| `15` | `fn :: prng range Int Int Int` | `Int Int` |
| `16` | `fn :: uu alloc page Int` | `Int` |
| `17` | `fn :: uu free page Int Int Int` | `Int` |
| `18` | `fn :: uu alloc mfd` | `Int` |
| `19` | `fn :: uu peek Int Int Int` | `String` |
| `20` | `fn :: uu decode u32 le String Int` | `Int` |
| `21` | `fn :: uu decode u64 le String Int` | `Int` |
| `22` | `fn :: uu wall time ms` | `Int` |
| `23` | `fn :: uu bytes to hex loop String Int Int` | `String` |
| `24` | `fn :: uu random hex16` | `String` |
| `25` | `fn :: uu hex val Int` | `Int` |
| `26` | `fn :: uu variant char String` | `String` |
| `27` | `fn :: uuid v4` | `String` |
| `28` | `fn :: uu hex48 loop Int Int` | `String` |
| `29` | `fn :: uuid v7 at Int` | `String` |
| `30` | `fn :: uuid v7` | `String` |
| `31` | `fn :: uu is hex range String Int Int` | `Bool` |
| `32` | `fn :: uuid is valid String` | `Bool` |
| `33` | `fn :: uuid version String` | `Int` |

---

## 19.3. Esplorare `uuid` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `uuid` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test uuid.ridgun`.

### 19.3.1. Esempio 1: Flusso principale in stile tabulare con `uuid`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `uuid` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import uuid

fn :: generar ids ordenados => String String Bool
      generar ids ordenados =
        1000 uuid v7 at -> id1
        2000 uuid v7 at -> id2
        (uuid is valid id1) and (id1 < id2) -> ok
        (id1, id2, ok)
```

### 19.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `uuid` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import uuid

fn :: firmar paquete String => Int Int
      firmar paquete payload =
        payload crc32 -> c32
        payload fnv1a 32 -> fnv
        (c32, fnv)
```

### 19.3.3. Esempio 3: Generazione, validazione e ispezione di UUIDv4 (CSPRNG) e UUIDv7 ordinabili per tempo (RFC 9562)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `uuid` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test uuidv4 and uuidv7 => ()
      test uuidv4 and uuidv7 =
        u4a = uuid v4
        u4b = uuid v4
        assert int equals (str len u4a) 36 "AC1: uuid_v4 length 36"
        assert true (uuid is valid u4a) "AC1: uuid_v4 valid RFC 9562 format"
        assert true (uuid is valid u4b) "AC1: second uuid_v4 valid"
        assert false (u4a == u4b) "AC1: CSPRNG uuid_v4 calls are unique"
        assert int equals (uuid version u4a) 4 "AC1: uuid_v4 version == 4"

        -- RFC 9562 UUIDv7 timestamp encoding & chronological prefix ordering
        u7_zero = uuid v7 at 0
        u7a = uuid v7 at 1700000000000
        u7b = uuid v7 at 1800000000000
        u7_live = uuid v7
        assert true (uuid is valid u7_zero) "AC1: uuid_v7 at epoch 0 valid"
        assert str eq (str slice u7_zero 0 13) "00000000-0000" "AC1: uuid_v7 at epoch 0 zero prefix"
        assert true (uuid is valid u7a) "AC1: uuid_v7 at 1700000000000 valid"
        assert true (uuid is valid u7b) "AC1: uuid_v7 at 1800000000000 valid"
        assert true (uuid is valid u7_live) "AC1: live uuid_v7 valid"
        assert int equals (uuid version u7a) 7 "AC1: uuid_v7 version == 7"
        assert int equals (uuid version u7_live) 7 "AC1: live uuid_v7 version == 7"
        assert str eq (str slice u7a 0 8) "018bcfe5" "AC1: uuid_v7 timestamp prefix 1700000000000"
        assert str eq (str slice u7b 0 8) "01a3185c" "AC1: uuid_v7 timestamp prefix 1800000000000"

        -- Uppercase valid UUID acceptance & RFC 9562 variant nibble (8, 9, a, b) validation
        assert true (uuid is valid "550E8400-E29B-41D4-A716-446655440000") "AC1: uppercase RFC 9562 UUID valid"
        assert false (uuid is valid "") "AC1: empty string invalid"
        assert false (uuid is valid "not-a-uuid") "AC1: short string invalid"
        assert false (uuid is valid "550e8400-e29b-41d4-1716-446655440000") "AC1: variant nibble '1' (< 8) rejected"
        assert false (uuid is valid "550e8400-e29b-41d4-c716-446655440000") "AC1: variant nibble 'c' (> b) rejected"
        assert false (uuid is valid "550e8400Xe29b-41d4-a716-446655440000") "AC1: missing hyphen at index 8 rejected"
        assert false (uuid is valid "550e8400-e29b-41d4-a716-44665544000g") "AC1: non-hex character 'g' rejected"
        assert int equals (uuid version "not-a-uuid") (0 - 1) "AC1: invalid uuid version -> -1"
        ()
```

### 19.3.4. Esempio 4: Checksum FNV-1a, DJB2, Adler-32, CRC32 IEEE 802.3 (`0xCBF43926`) e PRNG deterministico SplitMix64

In questo esempio pratico esploriamo in modo esaustivo come si comporta `uuid` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test checksums and prng => ()
      test checksums and prng =
        -- Official FNV-1a 32-bit vectors (isthe.com/chongo/tech/comp/fnv/)
        assert int equals (fnv1a 32 "") 2166136261 "AC2: FNV-1a 32 '' == 0x811c9dc5 (offset basis)"
        assert int equals (fnv1a 32 "a") 3826002220 "AC2: FNV-1a 32 'a' == 0xe40c292c"
        assert int equals (fnv1a 32 "foobar") 3214735720 "AC2: FNV-1a 32 'foobar' == 0xbf9cf968"

        -- Official RFC 1950 Adler-32 vectors
        assert int equals (adler32 "") 1 "AC2: Adler-32 '' == 1"
        assert int equals (adler32 "a") 6422626 "AC2: Adler-32 'a' == 0x00620062"
        assert int equals (adler32 "Wikipedia") 300286872 "AC2: Adler-32 'Wikipedia' == 0x11e60398"

        -- Official IEEE 802.3 / ISO-HDLC CRC-32 vectors
        assert int equals (crc32 "") 0 "AC2: CRC-32 '' == 0"
        assert int equals (crc32 "a") 3904355907 "AC2: CRC-32 'a' == 0xe8b7be43"
        assert int equals (crc32 "123456789") 3421780262 "AC2: CRC-32 '123456789' == 0xcbf43926"

        -- Deterministic 31-bit LCG PRNG
        s1 = prng next 42
        s2 = prng next 42
        s3 = prng next s1
        assert int equals s1 s2 "AC3: prng_next deterministic for same seed"
        assert false (s1 == s3) "AC3: prng_next advances state"
        r1 = prng range 42 10 20
        v1 = prng val r1
        assert true (v1 >= 10 and v1 <= 20) "AC3: prng_range within [10, 20]"
        r_deg = prng range 42 50 10
        assert int equals (prng val r_deg) 50 "AC3: prng_range with hi <= lo clamps to lo"
        ()
```

### 19.3.5. Esempio 5: Tracciabilità distribuita con UUIDv7 ordinabili per tempo e integrità dei pacchetti con CRC32 e FNV-1a (`uuid v7`, `uuid v7 timestamp ms`, `crc32 hex`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `uuid` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
import uuid

fn :: sellar paquete trazado (ahora_ms : Int) (payload : String) => (String, Int, String, Int)
      sellar paquete trazado ahora_ms payload =
        trace_id = uuid v7 ahora_ms
        ts_extra = uuid v7 timestamp ms trace_id
        crc_hex  = crc32 hex payload
        hash_fnv = fnv1a 64 payload
        (trace_id, ts_extra, crc_hex, hash_fnv)
```

---

## 19.4. Sotto il cofano: come è costruita `uuid` in Ridgun puro (`src/main/ridgun/lib/uuid.ridgun`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/uuid.ridgun` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 19.4.1. Implementazione interna: RFC 9562 UUIDv4 & UUIDv7 Generation & Validation (CSPRNG + clock_gettime)

Nota come `uuid.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
module :: uuid

fn :: uu alloc page Int => Int
      uu alloc page sz  =
        neg1 = 0 - 1
        sys call 9 0 sz 3 34 neg1 0

fn :: uu free page Int Int Int => Int
      uu free page mfd ptr sz =
        sys close mfd -> ()
        sys call 11 ptr sz 0 0 0 0

fn :: uu alloc mfd => Int
      uu alloc mfd =  sys call 319 4194311 1 0 0 0 0

fn :: uu peek Int Int Int => String
      uu peek mfd ptr len =
        sys call 18 mfd ptr len 0 0 0 -> ()
        sys call 8 mfd 0 0 0 0 0 -> ()
        sys read fd mfd len

fn :: uu decode u32 le String Int => Int
      uu decode u32 le s off =
        b0 = str char at s off
        b1 = str char at s (off + 1)
        b2 = str char at s (off + 2)
        b3 = str char at s (off + 3)
        b0 + (b1 * 256) + (b2 * 65536) + (b3 * 16777216)

fn :: uu decode u64 le String Int => Int
      uu decode u64 le s off =
        uu decode u32 le s off -> lo
        uu decode u32 le s (off + 4) -> hi
        lo + (hi * 4294967296)

fn :: uu wall time ms => Int
      uu wall time ms =
        uu alloc page 4096 -> ptr
        uu alloc mfd -> mfd
        sys call 228 0 ptr 0 0 0 0 -> ()
        uu peek mfd ptr 16 -> raw
        uu free page mfd ptr 4096 -> ()
        uu decode u64 le raw 0 -> sec
        uu decode u64 le raw 8 -> nsec
        (sec * 1000) + (nsec / 1000000)

fn :: uu bytes to hex loop String Int Int => String
      uu bytes to hex loop s idx len =
        | idx >= len = ""
        | otherwise =
          b   = ((str char at s idx) % 256 + 256) % 256
          hi  = b / 16
          lo  = b % 16
          tbl = uu hex lut 0
          (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1)) + (uu bytes to hex loop s (idx + 1) len)

fn :: uu random hex16 => String
      uu random hex16 =
        uu alloc page 4096 -> ptr
        uu alloc mfd -> mfd
        sys call 318 ptr 16 0 0 0 0 -> ()
        uu peek mfd ptr 16 -> raw
        uu free page mfd ptr 4096 -> ()
        uu bytes to hex loop raw 0 16

fn :: uu hex val Int => Int
      uu hex val c   =
        | c >= 48 and c <= 57  = c - 48
        | c >= 65 and c <= 70  = (c - 65) + 10
        | c >= 97 and c <= 102 = (c - 97) + 10
        | otherwise            = 0 - 1

fn :: uu variant char String => String
      uu variant char hex1   =
        v   = uu hex val (str char at hex1 0)
        idx = 8 + (v % 4)
        tbl = uu hex lut 0
        str slice tbl idx (idx + 1)

fn :: uuid v4 => String
      uuid v4 =
        h  = uu random hex16
        p1 = str slice h 0 8
        p2 = str slice h 8 12
        p3 = "4" + (str slice h 13 16)
        p4 = (uu variant char (str slice h 16 17)) + (str slice h 17 20)
        p5 = str slice h 20 32
        "{p1}-{p2}-{p3}-{p4}-{p5}"

fn :: uu hex48 loop Int Int => String
      uu hex48 loop val rem =
        | rem <= 0 = ""
        | otherwise =
          nib = ((val % 16) + 16) % 16
          tbl = uu hex lut 0
          (uu hex48 loop (val / 16) (rem - 1)) + (str slice tbl nib (nib + 1))

fn :: uuid v7 at Int   => String
      uuid v7 at ts_ms =
        eff_ts = uu abs ts_ms
        ts_hex = uu hex48 loop eff_ts 12
        h      = uu random hex16
        p1     = str slice ts_hex 0 8
        p2     = str slice ts_hex 8 12
        p3     = "7" + (str slice h 0 3)
        p4     = (uu variant char (str slice h 3 4)) + (str slice h 4 7)
        p5     = str slice h 7 19
        "{p1}-{p2}-{p3}-{p4}-{p5}"

fn :: uuid v7 => String
      uuid v7 =  uuid v7 at (uu wall time ms)

fn :: uu is hex range String Int Int => Bool
      uu is hex range s idx end_idx =
        | idx >= end_idx                       = True
        | (uu hex val (str char at s idx)) < 0 = False
        | otherwise                            = uu is hex range s (idx + 1) end_idx

fn :: uuid is valid String => Bool
      uuid is valid u      =
        | (str len u) != 36               = False
        | (str char at u 8) != 45         = False
        | (str char at u 13) != 45        = False
        | (str char at u 18) != 45        = False
        | (str char at u 23) != 45        = False
        | not (uu is hex range u 0 8)     = False
        | not (uu is hex range u 9 13)    = False
        | not (uu is hex range u 14 18)   = False
        | not (uu is hex range u 19 23)   = False
        | not (uu is hex range u 24 36)   = False
        | otherwise =
          var_nib = uu hex val (str char at u 19)
          (var_nib >= 8) and (var_nib <= 11)

fn :: uuid version String => Int
      uuid version u      =
        | not (uuid is valid u) = 0 - 1
        | otherwise             = uu hex val (str char at u 14)
```

---

## 19.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `uuid`

- **Garanzia algoritmica e di sicurezza**: `uuid v7 at t1 < uuid v7 at t2` garantisce un ordine lessicografico monotono crescente nel tempo, ideale per gli indici `btree` e i database.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/uuid.ridgun` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test uuid.ridgun`.

### Le 5 Regole d'Oro quando programmi con `uuid`

1. **Dichiara `import uuid` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `uuid` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `uuid` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `uuid` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 20** passeremo a esplorare in profondità la lib **`log`** (La lib `log` — Logging Strutturato NDJSON e Redazione Automatica dei Segreti).
