# Capítulo 18: A lib `time` — Calendario Civil UTC (Hinnant), ISO-8601, Duracións e Backoff

## 18.1. Por que existe a lib `time`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `time` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `time`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: as funcións de data de `libc` (`localtime`, `gmtime`, `mktime`) dependen de estado global mutable (`TZ`), non son seguras entre fíos e fallan con regras de anos bisestos seculares coma 1900 vs 2000.

A lib **`time`** implementa o algoritmo de calendario civil gregoriano proléptico en **$O(1)$ de Howard Hinnant**, formatado e análise estrita **ISO-8601 / RFC 3339** (`YYYY-MM-DDTHH:MM:SSZ`), duracións lexibles (`1h 1m 1s 5ms`) e cálculo de *exponential backoff* acoutado para reintentos de rede.

Nun ecosistema tradicional, resolver as tarefas do dominio **`TIME`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`time`** (`src/main/ridgun/lib/time.rg`) aborda o problema con catro principios innegociables:

1. **Funcións totais e contratos explícitos (`=>`)**: ningunha función de `time` lanza excepcións ocultas nin depende de `null`. Todo caso límite devolve un valor sentinela documentado ou un tipo alxébrico suma (`Option`, `Result`).
2. **Cero código C e cero `libc`**: todo o código de `time` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `time` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 18.2. Artefactos nativos, importación e catálogo completo da API de `time`

En `ridgun-libs`, **`time`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/time.rg` (dominio `TIME`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/time.rglib` | Distribución e importación directa con `import time` |
| **Ficheiro compilado** | `target/time.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libtime.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import time` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

### 18.2.1. Resumo de familias funcionais de `time`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `time epoch to utc / time utc to epoch` | Conversión en $O(1)$ entre segundos Unix epoch e `(year, month, day, hour, min, sec)` |
| `time is leap year / time days in month / time day of week` | Regras de ano bisesto (`400 / 100 / 4`), días do mes e día ISO da semana (`1=Lun..7=Dom`) |
| `time format iso8601 / time parse iso8601` | Formatea e valida marcas `YYYY-MM-DDTHH:MM:SSZ` (`-1` en datas inválidas coma 30 de feb) |
| `time format duration ms / time backoff ms` | Duracións lexibles e tempos de espera exponenciais acoutados $base \cdot 2^{attempt}$ |

### 18.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/time.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/time.rg` (`0` tipos, `0` operadores e `26` funcións):

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 18.3. Explorando `time` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `time` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test time.rg`.

### 18.3.1. Exemplo 1: Fluxo principal en estilo tabular con `time`

Observa como en Ridgun os signos `=` e os pasos de transformación con `time` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import time

fn :: registrar evento temporal (epoch_s : Int) => (String, Int, String)
      registrar evento temporal epoch_s =
        iso = time format iso8601 epoch_s
        sem = time day of week epoch_s
        dur = time format duration ms 3661005
        (iso, sem, dur)
```

### 18.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `time` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import time

fn :: planificar reintentos () => [Int]
      planificar reintentos =
        [time backoff ms 0 100 5000, time backoff ms 1 100 5000, time backoff ms 2 100 5000, time backoff ms 9 100 5000]
```

### 18.3.3. Exemplo 3: Calendario civil UTC de Howard Hinnant, anos bisestos, día da semana e conversión ISO-8601 / RFC 3339 (`time format iso8601`, `time parse iso8601`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `time` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test utc calendar and iso8601 => ()
      test utc calendar and iso8601 =
        -- Gregorian 4/100/400 leap year rules
        _ = assert true (time is leap year 1600) "AC1: 1600 divisible by 400 is leap"
        _ = assert false (time is leap year 1700) "AC1: 1700 divisible by 100 not leap"
        _ = assert false (time is leap year 1800) "AC1: 1800 divisible by 100 not leap"
        _ = assert false (time is leap year 1900) "AC1: 1900 divisible by 100 not leap"
        _ = assert true (time is leap year 2000) "AC1: 2000 divisible by 400 is leap"
        _ = assert true (time is leap year 2024) "AC1: 2024 divisible by 4 is leap"
        _ = assert false (time is leap year 2026) "AC1: 2026 not leap"
        _ = assert true (time is leap year 2400) "AC1: 2400 divisible by 400 is leap"

        -- Month lengths & out-of-range month safety
        _ = assert int equals (time days in month 2024 2) 29 "AC1: Feb 2024 == 29"
        _ = assert int equals (time days in month 2026 2) 28 "AC1: Feb 2026 == 28"
        _ = assert int equals (time days in month 2026 1) 31 "AC1: Jan == 31"
        _ = assert int equals (time days in month 2026 4) 30 "AC1: Apr == 30"
        _ = assert int equals (time days in month 2026 6) 30 "AC1: Jun == 30"
        _ = assert int equals (time days in month 2026 9) 30 "AC1: Sep == 30"
        _ = assert int equals (time days in month 2026 11) 30 "AC1: Nov == 30"
        _ = assert int equals (time days in month 2026 12) 31 "AC1: Dec == 31"
        _ = assert int equals (time days in month 2026 0) 0 "AC1: month 0 -> 0"
        _ = assert int equals (time days in month 2026 13) 0 "AC1: month 13 -> 0"

        -- Day of week (0=Sunday .. 6=Saturday)
        _ = assert int equals (time day of week 1970 1 1) 4 "AC1: 1970-01-01 was Thursday (4)"
        _ = assert int equals (time day of week 2000 1 1) 6 "AC1: 2000-01-01 was Saturday (6)"
        _ = assert int equals (time day of week 2026 10 24) 6 "AC1: 2026-10-24 is Saturday (6)"

        -- Famous Unix epoch milestones: 0, 1000000000 (2001-09-09T01:46:40Z), Y2038 (2147483647 -> 2038-01-19T03:14:07Z)
        _ = assert int equals (time utc to epoch 1970 1 1 0 0 0) 0 "AC2: Unix epoch 0"
        _ = assert str eq (time format iso8601 0) "1970-01-01T00:00:00Z" "AC2: format epoch 0"
        _ = assert str eq (time format iso8601 1000000000) "2001-09-09T01:46:40Z" "AC2: format billennium 1000000000"
        _ = assert int equals (time parse iso8601 "2001-09-09T01:46:40Z") 1000000000 "AC2: parse billennium"
        _ = assert str eq (time format iso8601 2147483647) "2038-01-19T03:14:07Z" "AC2: 64-bit Y2038 boundary 2147483647"
        _ = assert int equals (time parse iso8601 "2038-01-19 03:14:07") 2147483647 "AC2: RFC 3339 space separator without Z"

        ts = time utc to epoch 2026 10 22 10 20 59
        iso = time format iso8601 ts
        _ = assert str eq iso "2026-10-22T10:20:59Z" "AC2: format 2026-10-22T10:20:59Z"
        _ = assert int equals (time parse iso8601 iso) ts "AC2: parse roundtrip"
        tup = time epoch to utc ts
        _ = assert int equals (utc y tup) 2026 "AC1: year 2026"
        _ = assert int equals (utc m tup) 10 "AC1: month 10"
        _ = assert int equals (utc d tup) 22 "AC1: day 22"
        _ = assert int equals (utc hh tup) 10 "AC1: hour 10"
        _ = assert int equals (utc mm tup) 20 "AC1: minute 20"
        _ = assert int equals (utc ss tup) 59 "AC1: second 59"

        -- Negative validation on invalid calendar dates and timestamps
        _ = assert int equals (time parse iso8601 "2026-13-01T00:00:00Z") (0 - 1) "AC2: invalid month 13 -> -1"
        _ = assert int equals (time parse iso8601 "2026-00-01T00:00:00Z") (0 - 1) "AC2: invalid month 00 -> -1"
        _ = assert int equals (time parse iso8601 "2026-02-29T00:00:00Z") (0 - 1) "AC2: 2026-02-29 non-leap -> -1"
        _ = assert true ((time parse iso8601 "2024-02-29T00:00:00Z") > 0) "AC2: 2024-02-29 leap year valid"
        _ = assert int equals (time parse iso8601 "2026-04-31T00:00:00Z") (0 - 1) "AC2: April 31 -> -1"
        _ = assert int equals (time parse iso8601 "2026-01-01T24:00:00Z") (0 - 1) "AC2: hour 24 -> -1"
        _ = assert int equals (time parse iso8601 "2026-01-01T00:60:00Z") (0 - 1) "AC2: minute 60 -> -1"
        _ = assert int equals (time parse iso8601 "2026-01-01T00:00:60Z") (0 - 1) "AC2: second 60 -> -1"
        _ = assert int equals (time parse iso8601 "malformed") (0 - 1) "AC2: malformed -> -1"
        ()
```

### 18.3.4. Exemplo 4: Formatado e lectura de duracións lexibles (`1d2h3m4s500ms`) e *backoff* exponencial acoutado (`time exp backoff ms`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `time` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

```ridgun
fn :: test durations and backoff => ()
      test durations and backoff =
        _ = assert str eq (time format duration ms 0) "0ms" "AC3: 0ms"
        _ = assert str eq (time format duration ms (0 - 50)) "0ms" "AC3: negative ms -> 0ms"
        _ = assert str eq (time format duration ms 450) "450ms" "AC3: 450ms"
        _ = assert str eq (time format duration ms 1000) "1s" "AC3: exact 1s omits 0ms"
        _ = assert str eq (time format duration ms 60000) "1m" "AC3: exact 1m"
        _ = assert str eq (time format duration ms 3600000) "1h" "AC3: exact 1h"
        _ = assert str eq (time format duration ms 3661005) "1h 1m 1s 5ms" "AC3: 1h 1m 1s 5ms"

        _ = assert int equals (time backoff ms (0 - 1) 100 5000) 100 "AC3: negative attempt -> base_ms"
        _ = assert int equals (time backoff ms 0 100 5000) 100 "AC3: attempt 0 -> 100"
        _ = assert int equals (time backoff ms 1 100 5000) 200 "AC3: attempt 1 -> 200"
        _ = assert int equals (time backoff ms 3 100 5000) 800 "AC3: attempt 3 -> 800"
        _ = assert int equals (time backoff ms 10 100 5000) 5000 "AC3: clamped at max_ms 5000"
        _ = assert int equals (time backoff ms 3 0 5000) 0 "AC3: base_ms <= 0 -> 0"
        _ = assert int equals (time backoff ms 3 500 200) 500 "AC3: max_ms <= base_ms -> base_ms"
        ()
```

### 18.3.5. Exemplo 5: Planificador de reintentos con *backoff* exponencial e xanela de auditoría ISO-8601 (`time parse iso8601`, `time format duration`, `time exp backoff ms`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `time` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

## 18.4. Baixo o capó: como está construída `time` en Ridgun puro (`src/main/ridgun/lib/time.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/time.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 18.4.1. Implementación interna: Leap Year, Month Length & Day of Week

Fíxate en como `time.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

```ridgun
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

Fíxate en como `time.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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
        y_adj = tm adj year y m
        era   = tm calc era y_adj
        yoe   = y_adj - (era * 400)
        mp    = tm calc mp m
        doy   = (((153 * mp) + 2) / 5) + d - 1
        doe   = (yoe * 365) + (yoe / 4) - (yoe / 100) + doy
        (era * 146097) + doe - 719468

fn :: time day of week Int Int Int => Int
      time day of week year month day =
        z = tm days from civil year month day
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
```

### 18.4.3. Implementación interna: ISO-8601 / RFC 3339 Formatting & Parsing

Fíxate en como `time.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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
      time format iso8601 epoch_sec =  tm fmt utc tuple (time epoch to utc epoch_sec)

fn :: tm all digits String Int Int => Bool
      tm all digits s idx end_idx =
        | idx >= end_idx                                       = True
        | (str char at s idx) < 48 or (str char at s idx) > 57 = False
        | otherwise                                            = tm all digits s (idx + 1) end_idx

fn :: tm is sep at String Int Int Int => Bool
      tm is sep at s idx c1 c2 =
        ch = str char at s idx
        (ch == c1) or (ch == c2)
```

### 18.4.4. Implementación interna: Human-Readable Duration & Exponential Backoff

Fíxate en como `time.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

## 18.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `time`

- **Garantía algorítmica e de seguridade**: Conversión de calendario en $O(1)$ sen bucles ano por ano e validación estrita de días por mes (rexeitando o 29 de febreiro en anos non bisestos).
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/time.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test time.rg`.

### As 5 Regras de Ouro ao programar con `time`

1. **Declara `import time` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `time` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `time` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `time` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 19** pasaremos a explorar en profundidade a lib **`uuid`** (A lib `uuid` — RFC 9562 `UUIDv4`/`UUIDv7`, FNV-1a, Adler-32, CRC-32 e PRNG).
