# Capitolo 21: La lib `test` — Primitive di Asserzione Unitaria e Funzionale (`RG-011`)

## 21.1. Perché esiste la lib `test`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `test` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `test`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: quando un framework di test richiede macro magiche, reflection a runtime o un pesante runner esterno, scrivere test smette di essere immediato.

La lib **`test`** (`RG-011`) fornisce asserzioni pure, polimorfiche e specifiche per tipo che emettono diagnostiche chiare `[FAIL]` con i valori atteso e ottenuto e terminano con codice di uscita `1` non appena un invariante fallisce.

In un ecosistema tradizionale, risolvere i compiti del dominio **`TST`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`test`** (`src/main/ridgun/lib/test.rg`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import test` (o `import test as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: test` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `test` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 21.2. Artefatti nativi, importazione e catalogo completo dell'API di `test`

In `ridgun-libs`, **`test`** è una **lib** di prima classe situata in `src/main/ridgun/lib/test.rg` (dominio `TST`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/test.rglib` | Distribuzione e importazione diretta con `import test` |
| **File compilato** | `target/test.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libtest.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: test`: basta scrivere `import test` (o `import test as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 21.2.1. Riepilogo delle famiglie funzionali di `test`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `assert equals / assert eq : A -> A -> String -> ()` | Asserzione polimorfica di uguaglianza con etichetta descrittiva del caso di test |
| `assert int equals / assert str eq` | Asserzioni specializzate di uguaglianza per `Int` e `String` |
| `assert true / assert false / assert not` | Asserzioni di invarianti booleani (`True` / `False`) |
| `assert ok : Int -> String -> ()` | Verifica che un codice di stato di sistema o socket sia `0` (`OK`) |

### 21.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/test.rg`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/test.rg` (`0` tipi, `0` operatori e `12` funzioni):

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
|---|---|---|
| `1` | `fn :: fail test String` | `()` |
| `2` | `fn :: check eq A A` | `Bool` |
| `3` | `fn :: check str eq String String` | `Bool` |
| `4` | `fn :: check true Bool` | `Bool` |
| `5` | `fn :: assert true Bool String` | `()` |
| `6` | `fn :: assert false Bool String` | `()` |
| `7` | `fn :: assert equals A A String` | `()` |
| `8` | `fn :: assert str eq String String String` | `()` |
| `9` | `fn :: assert int equals Int Int String` | `()` |
| `10` | `fn :: assert ok Bool` | `()` |
| `11` | `fn :: assert not Bool` | `()` |
| `12` | `fn :: assert eq A A` | `()` |

---

## 21.3. Esplorare `test` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `test` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test test.rg`.

### 21.3.1. Esempio 1: Flusso principale in stile tabulare con `test`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `test` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import test
import math

fn :: suite matematicas => ()
      suite matematicas =
        assert equals 12 (math gcd 36 60) "MCD de 36 y 60"
        assert true (math is prime 97) "97 es primo"
        echo "[PASS] suite matematicas"
```

### 21.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `test` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import test

fn :: verificar codigo sistema Int => ()
      verificar codigo sistema rc =
        assert equals rc 0 "operacion de descriptor exitosa"
```

### 21.3.3. Esempio 3: Predicati booleani (`check eq`, `check str eq`, `check true`) e asserzioni RG-011 con diagnostica (`assert equals`, `assert str eq`, `assert int equals`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `test` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test rg011 assertions => ()
      test rg011 assertions =
        assert equals 4 4 "math int equality"
        assert equals "ok" "ok" "string equality"
        assert equals True True "bool equality"
        assert true (1 < 2) "1 < 2 holds"
        assert false (1 > 2) "1 > 2 is false"
        assert str eq "ridgun" "ridgun" "str eq helper"
        assert int equals 42 42 "int eq helper"
        assert eq 10 10
        assert ok True
        assert not False
        assert true (check eq 2 2) "check eq True"
        assert false (check eq 1 2) "check eq False"
        assert true (check str eq "a" "a") "check str eq True"
        assert false (check str eq "a" "b") "check str eq False"
        assert true (check true True) "check true True"
        assert false (check true False) "check true False"
```

### 21.3.4. Esempio 4: Composizione di suite unitarie e funzionali combinando predicati puri e asserzioni concise (`assert ok`, `assert not`, `assert eq`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `test` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
import test

fn :: validar invariantes de dominio (x : Int) (nombre : String) => Bool
      validar invariantes de dominio x nombre =
        ok_num = check eq (x * 2) (x + x)
        ok_str = check str eq nombre "ridgun"
        check true (ok_num and ok_str)

fn :: ejecutar suite de ejemplo => ()
      ejecutar suite de ejemplo =
        -- 1. Predicados puros sin salida del proceso (`check_*`)
        assert true (validar invariantes de dominio 21 "ridgun") "predicado compuesto"
        -- 2. Aserciones anotadas con mensaje diagnóstico (`assert_*`)
        assert int equals (20 + 22) 42 "suma entera exacta"
        assert str eq "rglib" "rglib" "etiqueta de artefacto"
        -- 3. Aserciones concisas sin etiqueta (`assert ok`, `assert not`, `assert eq`)
        assert ok (10 > 5)
        assert not (10 < 5)
        assert eq [1, 2, 3] [1, 2, 3]
        ()
```

---

## 21.4. Sotto il cofano: come è costruita `test` in Ridgun puro (`src/main/ridgun/lib/test.rg`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/test.rg` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 21.4.1. Implementazione interna: Non-Exiting Predicate Helpers

Nota come `test.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
module :: test

fn :: check eq A      A        => Bool
      check eq actual expected =  actual == expected

fn :: check str eq String String   => Bool
      check str eq actual expected =  actual == expected

fn :: check true Bool => Bool
      check true cond =  cond
```

### 21.4.2. Implementazione interna: RG-011 Message-Annotated Assertions

Nota come `test.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: assert true Bool String => ()
      assert true cond label  =
        | cond      = ()
        | otherwise = fail test "assert_true failed: {label}"

fn :: assert false Bool String => ()
      assert false cond label  =
        | not cond  = ()
        | otherwise = fail test "assert_false failed: {label}"

fn :: assert equals A      A        String => ()
      assert equals actual expected label  =
        | actual == expected = ()
        | otherwise          = fail test "assert_equals failed: {label}"

fn :: assert str eq String String String => ()
      assert str eq actual expected label =
        | actual == expected = ()
        | otherwise          = fail test "assert_str_eq failed ({label}): got '{actual}', expected '{expected}'"

fn :: assert int equals Int Int String => ()
      assert int equals actual expected label =
        | actual == expected = ()
        | otherwise          = fail test "assert_int_equals failed ({label}): got {actual}, expected {expected}"
```

### 21.4.3. Implementazione interna: Concise Label-Free Assertion Helpers

Nota come `test.rg` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: assert ok Bool => ()
      assert ok cond =  assert true cond "assert_ok"

fn :: assert not Bool => ()
      assert not cond =  assert false cond "assert_not"

fn :: assert eq A      A        => ()
      assert eq actual expected =  assert equals actual expected "assert_eq"
```

---

## 21.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `test`

- **Garanzia algoritmica e di sicurezza**: Tutte le suite di test di `ridgun-libs` (`src/test/ridgun/test *.rg`, oltre 4 000 righe) vengono eseguite con questa stessa lib tramite `stable test`.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/test.rg` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test test.rg`.

### Le 5 Regole d'Oro quando programmi con `test`

1. **Dichiara `import test` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `test` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `test` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `test` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 22** passeremo a esplorare in profondità la lib **`posix`** (La lib `posix` — Livello di Astrazione della Piattaforma (PAL), Orologi, Segnali e CSPRNG).
