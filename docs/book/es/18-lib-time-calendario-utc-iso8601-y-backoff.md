# Capítulo 18: La lib `time` — Calendario Civil UTC (Hinnant), ISO-8601, Duraciones y Backoff

## 18.1. ¿Por qué existe la lib `time`? (El problema real y la filosofía Ridgun)

> *«¿Por qué necesito una lib `time` escrita desde cero en Ridgun puro en lugar de enlazar una librería de C de toda la vida?»*

Esa es la primera pregunta que se hace cualquier ingeniero de sistemas al llegar a `time`. Y la respuesta resume toda la filosofía de `ridgun-libs`:

Seamos sinceros: las funciones de fecha de `libc` (`localtime`, `gmtime`, `mktime`) dependen de estado global mutable (`TZ`), no son seguras entre hilos y fallan con reglas de años bisiestos seculares como 1900 vs 2000.

La lib **`time`** implementa el algoritmo de calendario civil gregoriano proléptico en **$O(1)$ de Howard Hinnant**, formateo y análisis estricto **ISO-8601 / RFC 3339** (`YYYY-MM-DDTHH:MM:SSZ`), duraciones legibles (`1h 1m 1s 5ms`) y cálculo de *exponential backoff* acotado para reintentos de red.

En un ecosistema tradicional, resolver las tareas del dominio **`TIME`** implica arrastrar dependencias externas en C, lidiar con punteros crudos, conversiones opacas de tipos, excepciones no verificadas o pausas impredecibles del recolector de basura. En Ridgun, la lib **`time`** (`src/main/ridgun/lib/time.rg`) aborda el problema con cuatro principios innegociables:

1. **Declara `import time` (o `import time as alias`) al inicio del archivo**: cada lib define su espacio de nombres `module :: time` y en modo `--strict` las funciones multi-palabra se invocan siempre con espacios naturales.
2. **Encadena tus tuberías de izquierda a derecha con `->`**: escribe `entrada paso uno -> paso dos -> resultado`, usa máscaras `(+ _ _ +)` para desestructurar secuencias y omite `_ =` en sentencias secuenciales (o descarta con `-> ()`).
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos los recorridos internos de `time` se compilan a bucles nativos en $O(1)$ espacio de pila.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estructura intermedia se libera en el instante exacto en que termina su última lectura, sin *Garbage Collector*.

---

## 18.2. Artefactos nativos, importación y catálogo completo de la API de `time`

En `ridgun-libs`, **`time`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/time.rg` (dominio `TIME`). Al compilar con `stable bundle`, se empaqueta en tres artefactos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/time.rglib` | Distribución e importación directa con `import time` |
| **Archivo compilado** | `target/time.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libtime.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Cada lib declara su propio espacio de nombres con `module :: time`: basta con escribir `import time` (o `import time as alias`) en el encabezado y llamar a sus funciones con espacios naturales (`mi funcion x`) y tuberías `->` (`x mi funcion -> resultado`).

### 18.2.1. Resumen de familias funcionales de `time`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `time epoch to utc / time utc to epoch` | Conversión en $O(1)$ entre segundos Unix epoch y `(year, month, day, hour, min, sec)` |
| `time is leap year / time days in month / time day of week` | Reglas de año bisiesto (`400 / 100 / 4`), días del mes y día ISO de la semana (`1=Lun..7=Dom`) |
| `time format iso8601 / time parse iso8601` | Formatea y valida marcas `YYYY-MM-DDTHH:MM:SSZ` (`-1` en fechas inválidas como 30 de feb) |
| `time format duration ms / time backoff ms` | Duraciones legibles y tiempos de espera exponenciales acotados $base \cdot 2^{attempt}$ |

### 18.2.2. Catálogo exhaustivo de tipos y firmas en `src/main/ridgun/lib/time.rg`

A continuación tienes el inventario completo de tipos algebraicos (`type`), operadores (`op ::`) y firmas de funciones (`fn ::`) definidos en `src/main/ridgun/lib/time.rg` (`0` tipos, `0` operadores y `26` funciones):

| # | Función / Firma (`fn ::`) | Tipo de Retorno |
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

## 18.3. Explorando `time` a fondo: Ejemplos paso a paso de cada funcionalidad

No basta con ver la tabla de firmas: vamos a explorar **cada una de las funcionalidades** de la lib `time` mediante ejemplos progresivos y ejecutables en Ridgun. Empezaremos por las dos recetas tabulares de uso cotidiano y después recorreremos en detalle todos los escenarios funcionales, transformaciones y casos límite verificados en `src/test/ridgun/test time.rg`.

### 18.3.1. Ejemplo 1: Flujo principal en estilo tabular con `time`

Observa cómo en Ridgun los signos `=` y los pasos de transformación con `time` quedan alineados como una tabla limpia, sin variables mutables innecesarias ni efectos laterales ocultos:

```ridgun
import time

fn :: registrar evento temporal Int => String Int String
      registrar evento temporal epoch_s =
        epoch_s time format iso8601 -> iso
        time day of week 2026 10 27 -> sem
        3661005 time format duration ms -> dur
        (iso, sem, dur)
```

### 18.3.2. Ejemplo 2: Composición segura y manejo de casos de borde

Toda función de la lib `time` está diseñada para componerse con guardas booleanas `|` y con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import time

fn :: planificar reintentos => [Int]
      planificar reintentos =
        [time backoff ms 0 100 5000, time backoff ms 1 100 5000, time backoff ms 2 100 5000, time backoff ms 9 100 5000]
```

### 18.3.3. Ejemplo 3: Calendario civil UTC de Howard Hinnant, años bisiestos, día de la semana y conversión ISO-8601 / RFC 3339 (`time format iso8601`, `time parse iso8601`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `time` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 18.3.4. Ejemplo 4: Formateo y lectura de duraciones legibles (`1d2h3m4s500ms`) y *backoff* exponencial acotado (`time exp backoff ms`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `time` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

### 18.3.5. Ejemplo 5: Planificador de reintentos con *backoff* exponencial y ventana de auditoría ISO-8601 (`time parse iso8601`, `time format duration`, `time exp backoff ms`)

En este ejemplo práctico exploramos de forma exhaustiva cómo se comporta `time` en este bloque funcional, incluyendo entradas estándar, combinaciones de parámetros y valores frontera:

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

## 18.4. Bajo el capó: cómo está construida `time` en Ridgun puro (`src/main/ridgun/lib/time.rg`)

Una de las mayores ventajas de `ridgun-libs` es que **no hay cajas negras en C**. Puedes abrir `src/main/ridgun/lib/time.rg` y leer exactamente cómo está implementada cada operación usando *pattern matching*, árboles de guardas `|` / `|.` y recursión de cola (TCO). Veamos las piezas clave de su implementación real:

### 18.4.1. Implementación interna: Leap Year, Month Length & Day of Week

Fíjate en cómo `time.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

### 18.4.2. Implementación interna: Howard Hinnant Civil Calendar <-> Epoch Days

Fíjate en cómo `time.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

### 18.4.3. Implementación interna: ISO-8601 / RFC 3339 Formatting & Parsing

Fíjate en cómo `time.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

### 18.4.4. Implementación interna: Human-Readable Duration & Exponential Backoff

Fíjate en cómo `time.rg` estructura las firmas `fn :: ... => ...` primero y resuelve cada caso mediante ecuaciones alineadas y llamadas de cola:

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

## 18.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` y las 5 Reglas de Oro de `time`

- **Garantía algorítmica y de seguridad**: Conversión de calendario en $O(1)$ sin bucles año por año y validación estricta de días por mes (rechazando el 29 de febrero en años no bisiestos).
- **Complejidad de pila $O(1)$ con TCO**: Todos los bucles recursivos en `src/main/ridgun/lib/time.rg` están en posición de cola, por lo que `ridgunc` los compila a saltos nativos sin crecimiento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test time.rg`.

### Las 5 Reglas de Oro al programar con `time`

1. **Declara `import time` al inicio del archivo** y aprovecha la equivalencia entre espacios y guiones bajos para que tu código se lea como prosa.
2. **Alinea tus tuberías de datos con `=`**: encadena las llamadas a `time` en pasos con nombre propio y deja que `stable format` alinee las columnas.
3. **Aprovecha las funciones totales de `time` en tus guardas `|`**: comprueba los valores de retorno o desenvuelve los ADTs con *pattern matching* en lugar de asumir que la entrada externa siempre es válida.
4. **Evita copiar grandes estructuras si solo necesitas consultar un campo**: recuerda que en `RMM2` los argumentos de entrada no incrementan ni decrementan contadores (`+0` / `-0`).
5. **Combina `time` con `test` (`import test`)**: escribe siempre aserciones con `assert equals` o `assert true` para fijar los invariantes de tu dominio.

---

En el **Capítulo 19** pasaremos a explorar en profundidad la lib **`uuid`** (La lib `uuid` — RFC 9562 `UUIDv4`/`UUIDv7`, FNV-1a, Adler-32, CRC-32 y PRNG).
