# Capitolo 18: La lib `time` — Calendario Civile UTC (Hinnant), ISO-8601, Durate e Backoff

## 18.1. Perché esiste la lib `time`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `time` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `time`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: le funzioni di data di `libc` (`localtime`, `gmtime`, `mktime`) dipendono da uno stato globale mutabile (`TZ`), non sono thread-safe e falliscono sulle regole degli anni bisestili secolari come il 1900 rispetto al 2000.

La lib **`time`** implementa l'algoritmo di calendario civile gregoriano prolettico in **$O(1)$ di Howard Hinnant**, formattazione e parsing rigoroso **ISO-8601 / RFC 3339** (`YYYY-MM-DDTHH:MM:SSZ`), durate leggibili (`1h 1m 1s 5ms`) e calcolo di *exponential backoff* limitato per i tentativi di rete.

In un ecosistema tradizionale, risolvere i compiti del dominio **`TIME`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`time`** (`src/main/ridgun/lib/time.ridgun`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import time` (o `import time as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: time` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `time` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 18.2. Artefatti nativi, importazione e catalogo completo dell'API di `time`

In `ridgun-libs`, **`time`** è una **lib** di prima classe situata in `src/main/ridgun/lib/time.ridgun` (dominio `TIME`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/time.ridgunlib` | Distribuzione e importazione diretta con `import time` |
| **File compilato** | `target/time.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libtime.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: time`: basta scrivere `import time` (o `import time as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 18.2.1. Riepilogo delle famiglie funzionali di `time`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `time epoch to utc / time utc to epoch` | Conversione in $O(1)$ tra secondi Unix epoch e `(year, month, day, hour, min, sec)` |
| `time is leap year / time days in month / time day of week` | Regole dell'anno bisestile (`400 / 100 / 4`), giorni del mese e giorno ISO della settimana (`1=Lun..7=Dom`) |
| `time format iso8601 / time parse iso8601` | Formatta e convalida timestamp `YYYY-MM-DDTHH:MM:SSZ` (`-1` su date non valide come il 30 feb) |
| `time format duration ms / time backoff ms` | Durate leggibili e tempi di attesa esponenziali limitati $base \cdot 2^{attempt}$ |

### 18.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/time.ridgun`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/time.ridgun` (`0` tipi, `0` operatori e `26` funzioni):

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
|---|---|---|
| `1` | `fn :: time is leap year Int` | `Bool` |
| `2` | `fn :: tm feb days Int` | `Int` |
| `3` | `fn :: time days in month Int Int` | `Int` |
| `4` | `fn :: tm adj year Int Int` | `Int` |
| `5` | `fn :: tm calc era Int` | `Int` |
| `6` | `fn :: tm calc mp Int` | `Int` |
| `7` | `fn :: tm days from civil Int Int Int` | `Int` |
| `8` | `fn :: time day of week Int Int Int` | `Int` |
| `9` | `fn :: time utc to epoch Int Int Int Int Int Int` | `Int` |
| `10` | `fn :: tm z era Int` | `Int` |
| `11` | `fn :: tm mp to month Int` | `Int` |
| `12` | `fn :: tm finish year Int Int` | `Int` |
| `13` | `fn :: tm civil from days Int Int Int Int` | `Int Int Int Int Int Int` |
| `14` | `fn :: time epoch to utc Int` | `Int Int Int Int Int Int` |
| `15` | `fn :: tm pad2 Int` | `String` |
| `16` | `fn :: tm pad4 Int` | `String` |
| `17` | `fn :: tm fmt utc tuple (Int Int Int Int Int Int)` | `String` |
| `18` | `fn :: time format iso8601 Int` | `String` |
| `19` | `fn :: tm all digits String Int Int` | `Bool` |
| `20` | `fn :: tm is sep at String Int Int Int` | `Bool` |
| `21` | `fn :: tm parse iso8601 len String Int` | `Int` |
| `22` | `fn :: time parse iso8601 String` | `Int` |
| `23` | `fn :: tm join part String Int String` | `String` |
| `24` | `fn :: time format duration ms Int` | `String` |
| `25` | `fn :: tm pow2 loop Int Int Int` | `Int` |
| `26` | `fn :: time backoff ms Int Int Int` | `Int` |

---

## 18.3. Esplorare `time` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `time` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test time.ridgun`.

### 18.3.1. Esempio 1: Flusso principale in stile tabulare con `time`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `time` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import time

fn :: registrar evento temporal Int => String Int String
      registrar evento temporal epoch_s =
        epoch_s time format iso8601 -> iso
        time day of week 2026 10 27 -> sem
        3661005 time format duration ms -> dur
        (iso, sem, dur)
```

### 18.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `time` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import time

fn :: planificar reintentos => [Int]
      planificar reintentos =
        [time backoff ms 0 100 5000, time backoff ms 1 100 5000, time backoff ms 2 100 5000, time backoff ms 9 100 5000]
```

### 18.3.3. Esempio 3: Calendario civile UTC di Howard Hinnant, anni bisestili, giorno della settimana e conversione ISO-8601 / RFC 3339 (`time format iso8601`, `time parse iso8601`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `time` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test utc calendar and iso8601 => ()
      test utc calendar and iso8601 =
        -- Gregorian 4/100/400 leap year rules
        assert true (time is leap year 1600) "AC1: 1600 divisible by 400 is leap"
        assert false (time is leap year 1700) "AC1: 1700 divisible by 100 not leap"
        assert false (time is leap year 1800) "AC1: 1800 divisible by 100 not leap"
        assert false (time is leap year 1900) "AC1: 1900 divisible by 100 not leap"
        assert true (time is leap year 2000) "AC1: 2000 divisible by 400 is leap"
        assert true (time is leap year 2024) "AC1: 2024 divisible by 4 is leap"
        assert false (time is leap year 2026) "AC1: 2026 not leap"
        assert true (time is leap year 2400) "AC1: 2400 divisible by 400 is leap"

        -- Month lengths & out-of-range month safety
        assert int equals (time days in month 2024 2) 29 "AC1: Feb 2024 == 29"
        assert int equals (time days in month 2026 2) 28 "AC1: Feb 2026 == 28"
        assert int equals (time days in month 2026 1) 31 "AC1: Jan == 31"
        assert int equals (time days in month 2026 4) 30 "AC1: Apr == 30"
        assert int equals (time days in month 2026 6) 30 "AC1: Jun == 30"
        assert int equals (time days in month 2026 9) 30 "AC1: Sep == 30"
        assert int equals (time days in month 2026 11) 30 "AC1: Nov == 30"
        assert int equals (time days in month 2026 12) 31 "AC1: Dec == 31"
        assert int equals (time days in month 2026 0) 0 "AC1: month 0 -> 0"
        assert int equals (time days in month 2026 13) 0 "AC1: month 13 -> 0"

        -- Day of week (0=Sunday .. 6=Saturday)
        assert int equals (time day of week 1970 1 1) 4 "AC1: 1970-01-01 was Thursday (4)"
        assert int equals (time day of week 2000 1 1) 6 "AC1: 2000-01-01 was Saturday (6)"
        assert int equals (time day of week 2026 10 24) 6 "AC1: 2026-10-24 is Saturday (6)"

        -- Famous Unix epoch milestones: 0, 1000000000 (2001-09-09T01:46:40Z), Y2038 (2147483647 -> 2038-01-19T03:14:07Z)
        assert int equals (time utc to epoch 1970 1 1 0 0 0) 0 "AC2: Unix epoch 0"
        assert str eq (time format iso8601 0) "1970-01-01T00:00:00Z" "AC2: format epoch 0"
        assert str eq (time format iso8601 1000000000) "2001-09-09T01:46:40Z" "AC2: format billennium 1000000000"
        assert int equals (time parse iso8601 "2001-09-09T01:46:40Z") 1000000000 "AC2: parse billennium"
        assert str eq (time format iso8601 2147483647) "2038-01-19T03:14:07Z" "AC2: 64-bit Y2038 boundary 2147483647"
        assert int equals (time parse iso8601 "2038-01-19 03:14:07") 2147483647 "AC2: RFC 3339 space separator without Z"

        ts = time utc to epoch 2026 10 22 10 20 59
        iso = time format iso8601 ts
        assert str eq iso "2026-10-22T10:20:59Z" "AC2: format 2026-10-22T10:20:59Z"
        assert int equals (time parse iso8601 iso) ts "AC2: parse roundtrip"
        tup = time epoch to utc ts
        assert int equals (utc y tup) 2026 "AC1: year 2026"
        assert int equals (utc m tup) 10 "AC1: month 10"
        assert int equals (utc d tup) 22 "AC1: day 22"
        assert int equals (utc hh tup) 10 "AC1: hour 10"
        assert int equals (utc mm tup) 20 "AC1: minute 20"
        assert int equals (utc ss tup) 59 "AC1: second 59"

        -- Negative validation on invalid calendar dates and timestamps
        assert int equals (time parse iso8601 "2026-13-01T00:00:00Z") (0 - 1) "AC2: invalid month 13 -> -1"
        assert int equals (time parse iso8601 "2026-00-01T00:00:00Z") (0 - 1) "AC2: invalid month 00 -> -1"
        assert int equals (time parse iso8601 "2026-02-29T00:00:00Z") (0 - 1) "AC2: 2026-02-29 non-leap -> -1"
        assert true ((time parse iso8601 "2024-02-29T00:00:00Z") > 0) "AC2: 2024-02-29 leap year valid"
        assert int equals (time parse iso8601 "2026-04-31T00:00:00Z") (0 - 1) "AC2: April 31 -> -1"
        assert int equals (time parse iso8601 "2026-01-01T24:00:00Z") (0 - 1) "AC2: hour 24 -> -1"
        assert int equals (time parse iso8601 "2026-01-01T00:60:00Z") (0 - 1) "AC2: minute 60 -> -1"
        assert int equals (time parse iso8601 "2026-01-01T00:00:60Z") (0 - 1) "AC2: second 60 -> -1"
        assert int equals (time parse iso8601 "malformed") (0 - 1) "AC2: malformed -> -1"
        ()
```

### 18.3.4. Esempio 4: Formattazione e lettura di durate leggibili (`1d2h3m4s500ms`) e *backoff* esponenziale limitato (`time exp backoff ms`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `time` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test durations and backoff => ()
      test durations and backoff =
        assert str eq (time format duration ms 0) "0ms" "AC3: 0ms"
        assert str eq (time format duration ms (0 - 50)) "0ms" "AC3: negative ms -> 0ms"
        assert str eq (time format duration ms 450) "450ms" "AC3: 450ms"
        assert str eq (time format duration ms 1000) "1s" "AC3: exact 1s omits 0ms"
        assert str eq (time format duration ms 60000) "1m" "AC3: exact 1m"
        assert str eq (time format duration ms 3600000) "1h" "AC3: exact 1h"
        assert str eq (time format duration ms 3661005) "1h 1m 1s 5ms" "AC3: 1h 1m 1s 5ms"

        assert int equals (time backoff ms (0 - 1) 100 5000) 100 "AC3: negative attempt -> base_ms"
        assert int equals (time backoff ms 0 100 5000) 100 "AC3: attempt 0 -> 100"
        assert int equals (time backoff ms 1 100 5000) 200 "AC3: attempt 1 -> 200"
        assert int equals (time backoff ms 3 100 5000) 800 "AC3: attempt 3 -> 800"
        assert int equals (time backoff ms 10 100 5000) 5000 "AC3: clamped at max_ms 5000"
        assert int equals (time backoff ms 3 0 5000) 0 "AC3: base_ms <= 0 -> 0"
        assert int equals (time backoff ms 3 500 200) 500 "AC3: max_ms <= base_ms -> base_ms"
        ()
```

### 18.3.5. Esempio 5: Pianificatore di tentativi con *backoff* esponenziale e finestra di audit ISO-8601 (`time parse iso8601`, `time format duration`, `time exp backoff ms`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `time` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
import time

fn :: planificar ventana reintentos (iso_inicio : String) => (String, String, Int, Int)
      planificar ventana reintentos iso_inicio =
        epoch_0  = time parse iso8601 iso_inicio
        espera_1 = time exp backoff ms 0 200 10000
        espera_4 = time exp backoff ms 4 200 10000
        dur_txt  = time format duration (espera_1 + espera_4)
        iso_fin  = time format iso8601 (epoch_0 + 3600)
        (iso_fin, dur_txt, espera_1, espera_4)
```

---

## 18.4. Sotto il cofano: come è costruita `time` in Ridgun puro (`src/main/ridgun/lib/time.ridgun`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/time.ridgun` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 18.4.1. Implementazione interna: Leap Year, Month Length & Day of Week

Nota come `time.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
module :: time

fn :: time is leap year Int  => Bool
      time is leap year year =
        | (year % 400) == 0 = True
        | (year % 100) == 0 = False
        | (year % 4) == 0   = True
        | otherwise         = False

fn :: tm feb days Int  => Int
      tm feb days year =
        | time is leap year year = 29
        | otherwise              = 28

fn :: time days in month Int Int => Int
      time days in month year month =
        | month < 1 or month > 12                                      = 0
        | month == 2                                                   = tm feb days year
        | month == 4 or month == 6 or month == 9 or month == 11        = 30
        | otherwise                                                    = 31
```

### 18.4.2. Implementazione interna: Howard Hinnant Civil Calendar <-> Epoch Days

Nota come `time.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: tm adj year Int Int => Int
      tm adj year y   m   =
        | m <= 2    = y - 1
        | otherwise = y

fn :: tm calc era Int   => Int
      tm calc era y_adj =
        | y_adj >= 0 = y_adj / 400
        | otherwise  = (y_adj - 399) / 400

fn :: tm calc mp Int => Int
      tm calc mp m   =
        | m > 2     = m - 3
        | otherwise = m + 9

fn :: tm days from civil Int Int Int => Int
      tm days from civil y m d =
        tm adj year y m -> y_adj
        y_adj tm calc era -> era
        y_adj - (era * 400) -> yoe
        m tm calc mp -> mp
        (((153 * mp) + 2) / 5) + d - 1 -> doy
        (yoe * 365) + (yoe / 4) - (yoe / 100) + doy -> doe
        (era * 146097) + doe - 719468

fn :: time day of week Int Int Int => Int
      time day of week year month day =
        tm days from civil year month day -> z
        (((z + 4) % 7) + 7) % 7

fn :: time utc to epoch Int Int Int Int Int Int => Int
      time utc to epoch y m d hh mm ss =
        | m < 1 or m > 12                          = 0 - 1
        | d < 1 or d > (time days in month y m)    = 0 - 1
        | hh < 0 or hh > 23                        = 0 - 1
        | mm < 0 or mm > 59                        = 0 - 1
        | ss < 0 or ss > 59                        = 0 - 1
        | otherwise =
          days = tm days from civil y m d
          (days * 86400) + (hh * 3600) + (mm * 60) + ss

fn :: tm z era Int     => Int
      tm z era z_shift =
        | z_shift >= 0 = z_shift / 146097
        | otherwise    = (z_shift - 146096) / 146097

fn :: tm mp to month Int => Int
      tm mp to month mp  =
        | mp < 10   = mp + 3
        | otherwise = mp - 9

fn :: tm finish year Int Int => Int
      tm finish year y0  m   =
        | m <= 2    = y0 + 1
        | otherwise = y0

fn :: tm civil from days Int Int Int Int => Int Int Int Int Int Int
      tm civil from days z hh mm ss =
        z_shift = z + 719468
        era     = tm z era z_shift
        doe     = z_shift - (era * 146097)
        yoe     = (doe - (doe / 1460) + (doe / 36524) - (doe / 146096)) / 365
        y0      = yoe + (era * 400)
        doy     = doe - ((365 * yoe) + (yoe / 4) - (yoe / 100))
        mp      = ((5 * doy) + 2) / 153
        d       = doy - (((153 * mp) + 2) / 5) + 1
        m       = tm mp to month mp
        y       = tm finish year y0 m
        (y, m, d, hh, mm, ss)

fn :: time epoch to utc Int       => Int Int Int Int Int Int
      time epoch to utc epoch_sec =
        rem_raw = ((epoch_sec % 86400) + 86400) % 86400
        days    = (epoch_sec - rem_raw) / 86400
        hh      = rem_raw / 3600
        mm      = (rem_raw % 3600) / 60
        ss      = rem_raw % 60
        tm civil from days days hh mm ss
```

### 18.4.3. Implementazione interna: ISO-8601 / RFC 3339 Formatting & Parsing

Nota come `time.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: tm pad2 Int => String
      tm pad2 n   =
        | n < 10    = "0" + (int to str n)
        | otherwise = int to str n

fn :: tm pad4 Int => String
      tm pad4 n   =
        | n < 10   = "000" + (int to str n)
        | n < 100  = "00" + (int to str n)
        | n < 1000 = "0" + (int to str n)
        | otherwise = int to str n

fn :: tm fmt utc tuple (Int Int Int Int Int Int) => String
      tm fmt utc tuple (y, m, d, hh, mm, ss)     =
        (tm pad4 y) + "-" + (tm pad2 m) + "-" + (tm pad2 d) + "T" + (tm pad2 hh) + ":" + (tm pad2 mm) + ":" + (tm pad2 ss) + "Z"

fn :: time format iso8601 Int       => String
      time format iso8601 epoch_sec =  epoch_sec time epoch to utc -> tm fmt utc tuple

fn :: tm all digits String Int Int => Bool
      tm all digits s idx end_idx =
        | idx >= end_idx                                       = True
        | (str char at s idx) < 48 or (str char at s idx) > 57 = False
        | otherwise                                            = tm all digits s (idx + 1) end_idx

fn :: tm is sep at String Int Int Int => Bool
      tm is sep at s idx c1 c2 =
        ch = str char at s idx
        (ch == c1) or (ch == c2)

fn :: tm parse iso8601 len String Int => Int
      tm parse iso8601 len s n =
        | n < 19 or n > 20                         = 0 - 1
        | not (tm all digits s 0 4)                = 0 - 1
        | (str char at s 4) != 45                  = 0 - 1
        | not (tm all digits s 5 7)                = 0 - 1
        | (str char at s 7) != 45                  = 0 - 1
        | not (tm all digits s 8 10)               = 0 - 1
        | not (tm is sep at s 10 84 32)            = 0 - 1
        | not (tm all digits s 11 13)              = 0 - 1
        | (str char at s 13) != 58                 = 0 - 1
        | not (tm all digits s 14 16)              = 0 - 1
        | (str char at s 16) != 58                 = 0 - 1
        | not (tm all digits s 17 19)              = 0 - 1
        | n == 20 and (str char at s 19) != 90     = 0 - 1
        | otherwise =
          y  = str to int (str slice s 0 4)
          m  = str to int (str slice s 5 7)
          d  = str to int (str slice s 8 10)
          hh = str to int (str slice s 11 13)
          mm = str to int (str slice s 14 16)
          ss = str to int (str slice s 17 19)
          time utc to epoch y m d hh mm ss

fn :: time parse iso8601 String => Int
      time parse iso8601 s      =  tm parse iso8601 len s (str len s)
```

### 18.4.4. Implementazione interna: Human-Readable Duration & Exponential Backoff

Nota come `time.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: tm join part String Int String => String
      tm join part acc val unit =
        | val <= 0           = acc
        | (str len acc) == 0 = (int to str val) + unit
        | otherwise          = acc + " " + (int to str val) + unit

fn :: time format duration ms Int => String
      time format duration ms ms  =
        | ms <= 0 = "0ms"
        | otherwise =
          h  = ms / 3600000
          m  = (ms % 3600000) / 60000
          s  = (ms % 60000) / 1000
          rm = ms % 1000
          p1 = tm join part "" h "h"
          p2 = tm join part p1 m "m"
          p3 = tm join part p2 s "s"
          tm join part p3 rm "ms"

fn :: tm pow2 loop Int Int Int => Int
      tm pow2 loop rem cur max_ms =
        | rem <= 0 or cur >= max_ms =
          | cur > max_ms = max_ms
          | otherwise    = cur |.
        | otherwise = tm pow2 loop (rem - 1) (cur * 2) max_ms

fn :: time backoff ms Int Int Int => Int
      time backoff ms attempt base_ms max_ms =
        | base_ms <= 0              = 0
        | max_ms <= base_ms         = base_ms
        | attempt <= 0              = base_ms
        | otherwise                 = tm pow2 loop attempt base_ms max_ms
```

---

## 18.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `time`

- **Garanzia algoritmica e di sicurezza**: Conversione del calendario in $O(1)$ senza cicli anno per anno e validazione rigorosa dei giorni per mese (rifiutando il 29 febbraio negli anni non bisestili).
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/time.ridgun` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test time.ridgun`.

### Le 5 Regole d'Oro quando programmi con `time`

1. **Dichiara `import time` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `time` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `time` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `time` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 19** passeremo a esplorare in profondità la lib **`uuid`** (La lib `uuid` — RFC 9562 `UUIDv4`/`UUIDv7`, FNV-1a, Adler-32, CRC-32 e PRNG).
