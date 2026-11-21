# Capitolo 35: La lib `hash` — Hashing con Chiave SipHash-1-3 per Tabelle Hash

## 35.1. Perché esiste la lib `hash`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `hash` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `hash`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: quando la funzione di hash di una tabella hash è pubblica, chi controlla le chiavi può inviarne migliaia che finiscono nello stesso slot, e una sola richiesta costa allora quanto dovrebbe costarne un milione (hash flooding).

La lib **`hash`** implementa **SipHash-1-3** (Aumasson & Bernstein) con una chiave a 128 bit e un risultato a 64 bit. `siphash13` calcola l'hash di un'intera stringa; le operazioni native del compilatore `siphash13 range` e `siphash13 range low` (ridgunc 1.0.44) calcolano l'hash di un intervallo di byte in alcune decine di nanosecondi; `siphash13 reference` è lo stesso hash scritto in Ridgun semplice, da leggere e da usare come termine di confronto nei test; e `siphash new key` estrae dal sistema una chiave casuale di 16 byte.

In un ecosistema tradizionale, risolvere i compiti del dominio **`HASH`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`hash`** (`src/main/ridgun/lib/hash.ridgun`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import hash` (o `import hash as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: hash` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `hash` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 35.2. Artefatti nativi, importazione e catalogo completo dell'API di `hash`

In `ridgun-libs`, **`hash`** è una **lib** di prima classe situata in `src/main/ridgun/lib/hash.ridgun` (dominio `HASH`). Compilando con `stable bundle`, viene impacchettata in un artefatto nativo:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/hash.ridgunlib` | Distribuzione e importazione diretta con `import hash` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: hash`: basta scrivere `import hash` (o `import hash as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 35.2.1. Riepilogo delle famiglie funzionali di `hash`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `siphash13` | SipHash-1-3 di un'intera stringa con una chiave di 16 byte, come `Int` a 64 bit |
| `siphash13 range / siphash13 range low` | Operazioni native del compilatore: i 64 bit, o i 32 bit bassi, dell'hash di un intervallo di byte |
| `siphash13 reference` | Lo stesso hash in Ridgun semplice, su metà da 32 bit: la definizione rispetto alla quale viene testata l'operazione nativa |
| `siphash new key` | Una chiave casuale di 16 byte dalla sorgente di casualità del sistema (`""` quando non può essere letta) |

### 35.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/hash.ridgun`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/hash.ridgun` (`0` tipi, `0` operatori e `11` funzioni):

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
|---|---|---|
| `1` | `fn :: hs byte String Int` | `Int` |
| `2` | `fn :: hs tail String Int Int` | `Int` |
| `3` | `fn :: hs pick Int Int Int` | `Int` |
| `4` | `fn :: hs key word String Int` | `Int` |
| `5` | `fn :: siphash13 loop String Int Int Int Int Int Int Int Int Int Int Int Int Int` | `Int` |
| `6` | `fn :: siphash13 last String Int Int Int Int Int Int Int Int Int Int Int Int` | `Int` |
| `7` | `fn :: siphash13 start String String Int Int Int` | `Int` |
| `8` | `fn :: siphash13 String String` | `Int` |
| `9` | `fn :: siphash13 reference String String Int Int Int` | `Int` |
| `10` | `fn :: siphash new key` | `String` |
| `11` | `fn :: hs key of (Int String)` | `String` |

---

## 35.3. Esplorare `hash` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `hash` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test hash.ridgun`.

### 35.3.1. Esempio 1: Flusso principale in stile tabulare con `hash`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `hash` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import hash

fn :: cubo de clave String String Int => Int
      cubo de clave semilla clave cubos =
        siphash13 range low semilla clave 0 (str len clave) -> h
        h % cubos
```

### 35.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `hash` è progettata per comporsi con le guardie booleane `|` e con il resto delle 38 lib di `ridgun-libs`:

```ridgun
import hash

fn :: huella segura String String => Int
      huella segura semilla dato =
        | (str len semilla) != 16 = 0
        | otherwise               = siphash13 semilla dato
```

### 35.3.3. Esempio 3: Vettori SipHash-1-3 per input da 0 a 64 byte: le metà bassa e alta da 32 bit

In questo esempio pratico esploriamo in modo esaustivo come si comporta `hash` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test siphash13 vectors => ()
      test siphash13 vectors =
        key = tensor to str (seq bytes (Tensor[U8 * 16]) 0 16)
        msg = tensor to str (seq bytes (Tensor[U8 * 64]) 0 64)
        siphash13 range low key msg 0 0 -> assert int equals 84919516 "low 32 bits, 0 bytes"
        (siphash13 range key msg 0 0) shr 32 -> assert int equals 2880176472 "high 32 bits, 0 bytes"
        siphash13 range low key msg 0 1 -> assert int equals 2102905491 "low 32 bits, 1 bytes"
        (siphash13 range key msg 0 1) shr 32 -> assert int equals 3388251123 "high 32 bits, 1 bytes"
        siphash13 range low key msg 0 7 -> assert int equals 2612072768 "low 32 bits, 7 bytes"
        (siphash13 range key msg 0 7) shr 32 -> assert int equals 3549592984 "high 32 bits, 7 bytes"
        siphash13 range low key msg 0 8 -> assert int equals 2368313998 "low 32 bits, 8 bytes"
        (siphash13 range key msg 0 8) shr 32 -> assert int equals 915445009 "high 32 bits, 8 bytes"
        siphash13 range low key msg 0 9 -> assert int equals 1812348388 "low 32 bits, 9 bytes"
        (siphash13 range key msg 0 9) shr 32 -> assert int equals 631541427 "high 32 bits, 9 bytes"
        siphash13 range low key msg 0 15 -> assert int equals 709990742 "low 32 bits, 15 bytes"
        (siphash13 range key msg 0 15) shr 32 -> assert int equals 3542145133 "high 32 bits, 15 bytes"
        siphash13 range low key msg 0 16 -> assert int equals 2106624870 "low 32 bits, 16 bytes"
        (siphash13 range key msg 0 16) shr 32 -> assert int equals 3427786010 "high 32 bits, 16 bytes"
        siphash13 range low key msg 0 17 -> assert int equals 1675352076 "low 32 bits, 17 bytes"
        (siphash13 range key msg 0 17) shr 32 -> assert int equals 2633132176 "high 32 bits, 17 bytes"
        siphash13 range low key msg 0 25 -> assert int equals 1885014393 "low 32 bits, 25 bytes"
        (siphash13 range key msg 0 25) shr 32 -> assert int equals 1171085608 "high 32 bits, 25 bytes"
        siphash13 range low key msg 0 63 -> assert int equals 3082531752 "low 32 bits, 63 bytes"
        (siphash13 range key msg 0 63) shr 32 -> assert int equals 2635698274 "high 32 bits, 63 bytes"
        siphash13 range low key msg 0 64 -> assert int equals 1263165541 "low 32 bits, 64 bytes"
        (siphash13 range key msg 0 64) shr 32 -> assert int equals 4051277804 "high 32 bits, 64 bytes"
        (siphash13 range key msg 0 15) == (siphash13 key (str slice msg 0 15)) -> assert true "whole data equals the range"
        siphash13 range low key ("xx" + msg) 2 27 -> assert int equals 1885014393 "a range inside a longer string"
        siphash13 range low "0123456789abcdef" "abc" 0 3 -> assert int equals 1783201848 "printable key"
        siphash13 range "short" msg 0 8 -> assert int equals 0 "a key that is not 16 bytes gives 0"
        siphash13 range key msg 9 8 -> assert int equals 0 "a reversed range gives 0"
        siphash13 range key msg 0 65 -> assert int equals 0 "a range past the data gives 0"
        (siphash13 range low key msg 0 8) != (siphash13 range low "0123456789abcdef" msg 0 8) -> assert true "another key, another hash"
        k1 = siphash new key
        k2 = siphash new key
        str len k1 -> assert int equals 16 "a new key has 16 bytes"
        k1 != k2 -> assert true "two new keys differ"
```

### 35.3.4. Esempio 4: L'operazione nativa a confronto con il riferimento in Ridgun semplice a qualsiasi offset

In questo esempio pratico esploriamo in modo esaustivo come si comporta `hash` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test native matches reference => ()
      test native matches reference =
        key = "0123456789abcdef"
        msg = tensor to str (seq bytes (Tensor[U8 * 96]) 0 96)
        same as reference key msg 0 0 0 -> assert int equals 0 "native equals reference, offset 0"
        same as reference key msg 3 0 0 -> assert int equals 0 "native equals reference, offset 3"
        same as reference key msg 25 0 0 -> assert int equals 0 "native equals reference, offset 25"
```

---

## 35.4. Sotto il cofano: come è costruita `hash` in Ridgun puro (`src/main/ridgun/lib/hash.ridgun`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/hash.ridgun` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 35.4.1. Implementazione interna: SipRound on 32-Bit Halves: One Message Word per Turn

Nota come `hash.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
-- The byte at `i` as 0..255.
fn :: hs byte String Int => Int
      hs byte s i =  (str char at s i) and 255

-- The byte at `i`, or 0 at or after `to`.
fn :: hs tail String Int Int => Int
      hs tail s i to =
        | i >= to   = 0
        | otherwise = (str char at s i) and 255

fn :: hs pick Int Int Int => Int
      hs pick want hi lo =
        | want == 0 = lo
        | otherwise = (hi shl 32) or lo

-- Little-endian 32-bit word of the key at `off`.
fn :: hs key word String Int => Int
      hs key word k off =  (hs byte k off) or ((hs byte k (off + 1)) shl 8) or ((hs byte k (off + 2)) shl 16) or ((hs byte k (off + 3)) shl 24)

-- One message word per turn: v3 ^= m, 1 round(s), v0 ^= m. The 8 state values are the halves of v0..v3.
fn :: siphash13 loop String Int Int Int Int Int Int Int Int Int Int Int Int Int => Int
      siphash13 loop s off full to n want a0 b0 a1 b1 a2 b2 a3 b3 =
        | off >= full = siphash13 last s off to n want a0 b0 a1 b1 a2 b2 a3 b3
        | otherwise   =
          t1 = (hs byte s off) or ((hs byte s (off + 1)) shl 8) or ((hs byte s (off + 2)) shl 16) or ((hs byte s (off + 3)) shl 24)
          t2 = (hs byte s (off + 4)) or ((hs byte s (off + 5)) shl 8) or ((hs byte s (off + 6)) shl 16) or ((hs byte s (off + 7)) shl 24)
          t3 = a3 xor t2
          t4 = b3 xor t1
          t5 = b0 + b1
          t6 = ((a0 + a1) + (t5 shr 32)) and 0xFFFFFFFF
          t7 = t5 and 0xFFFFFFFF
          t8 = ((a1 shl 13) or (b1 shr 19)) and 0xFFFFFFFF
          t9 = ((b1 shl 13) or (a1 shr 19)) and 0xFFFFFFFF
          t10 = t8 xor t6
          t11 = t9 xor t7
          t12 = b2 + t4
          t13 = ((a2 + t3) + (t12 shr 32)) and 0xFFFFFFFF
          t14 = t12 and 0xFFFFFFFF
          t15 = ((t3 shl 16) or (t4 shr 16)) and 0xFFFFFFFF
          t16 = ((t4 shl 16) or (t3 shr 16)) and 0xFFFFFFFF
          t17 = t15 xor t13
          t18 = t16 xor t14
          t19 = t6 + t18
          t20 = ((t7 + t17) + (t19 shr 32)) and 0xFFFFFFFF
          t21 = t19 and 0xFFFFFFFF
          t22 = ((t17 shl 21) or (t18 shr 11)) and 0xFFFFFFFF
          t23 = ((t18 shl 21) or (t17 shr 11)) and 0xFFFFFFFF
          t24 = t22 xor t20
          t25 = t23 xor t21
          t26 = t14 + t11
          t27 = ((t13 + t10) + (t26 shr 32)) and 0xFFFFFFFF
          t28 = t26 and 0xFFFFFFFF
          t29 = ((t10 shl 17) or (t11 shr 15)) and 0xFFFFFFFF
          t30 = ((t11 shl 17) or (t10 shr 15)) and 0xFFFFFFFF
          t31 = t29 xor t27
          t32 = t30 xor t28
          t33 = t20 xor t2
          t34 = t21 xor t1
          siphash13 loop s (off + 8) full to n want t33 t34 t31 t32 t28 t27 t24 t25
```

### 35.4.2. Implementazione interna: Public API: `siphash13`, the Plain-Ridgun Reference, and Random Keys

Nota come `hash.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
-- v0..v3 from the key (k0 = bytes 0-7, k1 = bytes 8-15, little-endian) and the constants "somepseudorandomlygeneratedbytes".
fn :: siphash13 start String String Int Int Int => Int
      siphash13 start key s from to want =
        k0l = hs key word key 0
        k0h = hs key word key 4
        k1l = hs key word key 8
        k1h = hs key word key 12
        n   = to - from
        siphash13 loop s from (from + ((n shr 3) shl 3)) to n want (k0h xor 0x736f6d65) (k0l xor 0x70736575) (k1h xor 0x646f7261) (k1l xor 0x6e646f6d) (k0h xor 0x6c796765) (k0l xor 0x6e657261) (k1h xor 0x74656462) (k1l xor 0x79746573)

-- `siphash13 range key data from to` (64 bits) and `siphash13 range low key data from to` (the low 32 bits)
-- are operations of the compiler since ridgunc 1.0.44: native, some tens of ns for a short key. They take
-- a 16-byte key and the bytes `from` (included) to `to` (excluded) of `data`; a key of another length or a
-- range outside `data` gives 0. This lib does not define them, so that the native ones are used.

-- SipHash-1-3 of the whole of `data`.
fn :: siphash13 String String => Int
      siphash13 key data =  siphash13 range key data 0 (str len data)

-- The same hash written in plain Ridgun (about 2 µs for a 25-byte key): the definition the native operation
-- is tested against, and the one to read. `want` 0 gives the low 32 bits, anything else the 64 bits.
fn :: siphash13 reference String String Int Int Int => Int
      siphash13 reference key data from to want =
        | (str len key) != 16 or from < 0 or to < from or to > (str len data) = 0
        | otherwise = siphash13 start key data from to want

-- A new random 16-byte key (from the system random source). "" when it cannot be read.
fn :: siphash new key => String
      siphash new key =  hs key of (sys random bytes 16)

fn :: hs key of (Int String) => String
      hs key of (rc, k) =
        | rc == 0 and (str len k) == 16 = k
        | otherwise                     = ""
```

---

## 35.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `hash`

- **Garanzia algoritmica e di sicurezza**: Una chiave di un'altra lunghezza, o un intervallo fuori dai dati, dà `0` invece di leggere fuori dai limiti, e l'operazione nativa restituisce gli stessi 64 bit del riferimento in Ridgun semplice per ogni lunghezza e ogni offset testati.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/hash.ridgun` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test hash.ridgun`.

### Le 5 Regole d'Oro quando programmi con `hash`

1. **Dichiara `import hash` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `hash` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `hash` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `hash` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 36** passeremo a esplorare in profondità la lib **`hashmap`** (La lib `hashmap` — Mappa Hash da Chiavi `String` a Qualsiasi Valore, su Tensori e con Seme SipHash).
