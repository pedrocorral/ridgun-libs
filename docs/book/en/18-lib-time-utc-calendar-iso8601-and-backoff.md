# Chapter 18: The `time` Lib — Howard Hinnant UTC Calendar, ISO-8601, Durations, and Backoff

## 18.1. Why Does the `time` Lib Exist? (The Real-World Problem & Ridgun Philosophy)

> *"Why do I need a `time` lib written from scratch in pure Ridgun instead of just linking a legacy C library?"*

That is the first question every systems engineer asks when meeting `time`. And the answer captures the entire philosophy of `ridgun-libs`:

Let's be honest: `libc` date functions (`localtime`, `gmtime`, `mktime`) rely on hidden mutable global state (`TZ`), aren't thread-safe, and trip developers up on century leap-year rules.

The **`time`** lib implements **Howard Hinnant's $O(1)$** proleptic Gregorian UTC civil calendar algorithm, strict **ISO-8601 / RFC 3339** formatting and parsing (`YYYY-MM-DDTHH:MM:SSZ`), human-readable durations (`1h 1m 1s 5ms`), and bounded exponential backoff.

In a traditional ecosystem, solving **`TIME`** tasks means pulling in external C dependencies, wrestling with raw pointers, opaque type conversions, unchecked exceptions, or unpredictable garbage-collector pauses. In Ridgun, the **`time`** lib (`src/main/ridgun/lib/time.rg`) tackles the problem with four non-negotiable principles:

1. **Declare `import time` (or `import time as alias`) at the top of your file**: every lib defines its `module :: time` namespace, and under `--strict` multi-word functions are always called with natural spaces.
2. **Chain your data pipelines left-to-right with `->`**: write `input step one -> step two -> result`, use `(+ _ _ +)` sequence masks to destructure tuples/lists, and omit `_ =` on sequential statements (or discard with `-> ()`).
3. **Tail-Call Optimization (TCO)**: all internal loops in `time` are tail-recursive and compile into native hardware loops using $O(1)$ stack space.
4. **Deterministic Memory (`RMM1` / `RMM2`)**: every intermediate allocation is reclaimed at the exact instruction where its last read finishes, with no Garbage Collector.

---

## 18.2. Native Artifacts, Imports, and Complete `time` API Catalog

In `ridgun-libs`, **`time`** is a first-class **lib** located at `src/main/ridgun/lib/time.rg` (domain `TIME`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/time.rglib` | Portable distribution and direct `import time` resolution |
| **Compiled Archive** | `target/time.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libtime.so` | Native dynamic shared library with zero C or `libc` dependencies |

> Every lib declares its own namespace via `module :: time`: simply write `import time` (or `import time as alias`) at the top and call its functions with natural spaces (`my fn x`) and left-to-right `->` pipelines (`x my fn -> result`).

### 18.2.1. Summary of `time` Functional Families

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `time epoch to utc / time utc to epoch` | $O(1)$ conversion between Unix epoch seconds and `(year, month, day, hour, min, sec)` |
| `time is leap year / time days in month / time day of week` | Leap-year rules (`400 / 100 / 4`), month lengths, and ISO weekday (`1=Mon..7=Sun`) |
| `time format iso8601 / time parse iso8601` | Format and validate `YYYY-MM-DDTHH:MM:SSZ` timestamps (`-1` on invalid dates like Feb 30) |
| `time format duration ms / time backoff ms` | Human duration strings and capped $base \cdot 2^{attempt}$ retry delays |

### 18.2.2. Exhaustive Catalog of Types and Signatures in `src/main/ridgun/lib/time.rg`

Below is the complete inventory of algebraic data types (`type`), mixfix operators (`op ::`), and function signatures (`fn ::`) defined in `src/main/ridgun/lib/time.rg` (`0` types, `0` operators, and `26` functions):

| # | Function / Signature (`fn ::`) | Return Type |
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

## 18.3. Deep Dive into `time`: Step-by-Step Examples for Every Feature

A signature table alone is never enough: let's explore **every capability** of the `time` lib through progressive, runnable Ridgun examples. We will start with two everyday tabular recipes and then walk through every functional scenario, transformation, and boundary condition verified in `src/test/ridgun/test time.rg`.

### 18.3.1. Example 1: Core Tabular Workflow with `time`

Notice how in Ridgun the `=` signs and transformation steps using `time` align into a clean, scannable table without unnecessary mutable variables or hidden side effects:

```ridgun
import time

fn :: registrar evento temporal Int => String Int String
      registrar evento temporal epoch_s =
        epoch_s time format iso8601 -> iso
        time day of week 2026 10 27 -> sem
        3661005 time format duration ms -> dur
        (iso, sem, dur)
```

### 18.3.2. Example 2: Safe Composition and Boundary Handling

Every function in the `time` lib is designed to compose cleanly with boolean guards `|` and with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import time

fn :: planificar reintentos => [Int]
      planificar reintentos =
        [time backoff ms 0 100 5000, time backoff ms 1 100 5000, time backoff ms 2 100 5000, time backoff ms 9 100 5000]
```

### 18.3.3. Example 3: Howard Hinnant's Civil UTC Calendar, Leap Years, Day of Week, and ISO-8601 / RFC 3339 Conversion (`time format iso8601`, `time parse iso8601`)

In this hands-on walkthrough we thoroughly exercise how `time` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

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

### 18.3.4. Example 4: Human-Readable Duration Formatting/Parsing (`1d2h3m4s500ms`) and Capped Exponential Backoff (`time exp backoff ms`)

In this hands-on walkthrough we thoroughly exercise how `time` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

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

### 18.3.5. Example 5: Retry Scheduler with Exponential Backoff and ISO-8601 Audit Windows (`time parse iso8601`, `time format duration`, `time exp backoff ms`)

In this hands-on walkthrough we thoroughly exercise how `time` behaves across this functional area, covering standard inputs, parameter combinations, and corner cases:

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

## 18.4. Under the Hood: How `time` Is Built in Pure Ridgun (`src/main/ridgun/lib/time.rg`)

One of the biggest advantages of `ridgun-libs` is that **there are no C black boxes**. You can open `src/main/ridgun/lib/time.rg` and read exactly how every operation is implemented using pattern matching, `|` / `|.` guard trees, and tail-call optimization (TCO). Let's inspect the key building blocks of its real implementation:

### 18.4.1. Internal Implementation: Leap Year, Month Length & Day of Week

Observe how `time.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

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

### 18.4.2. Internal Implementation: Howard Hinnant Civil Calendar <-> Epoch Days

Observe how `time.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

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

### 18.4.3. Internal Implementation: ISO-8601 / RFC 3339 Formatting & Parsing

Observe how `time.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

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

### 18.4.4. Internal Implementation: Human-Readable Duration & Exponential Backoff

Observe how `time.rg` declares explicit `fn :: ... => ...` contracts first and resolves each case through aligned equations and tail calls:

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

## 18.5. Algorithmic Guarantees, `RMM1`/`RMM2` Memory, and the 5 Golden Rules of `time`

- **Algorithmic & Safety Guarantee**: $O(1)$ calendar conversion with zero year-by-year loops and strict per-month day validation (rejecting Feb 29 on non-leap years).
- **$O(1)$ Stack Complexity via TCO**: Every recursive loop in `src/main/ridgun/lib/time.rg` is in tail position, so `ridgunc` compiles them into native jumps with zero stack growth.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test time.rg`.

### The 5 Golden Rules When Programming with `time`

1. **Declare `import time` at the top of your file** and take advantage of space/underscore equivalence so your code reads like natural prose.
2. **Align your data pipelines with `=`**: chain `time` calls into named intermediate steps and let `stable format` align the columns.
3. **Leverage `time`'s total functions inside `|` guards**: inspect return values or unwrap ADTs via pattern matching rather than assuming external input is valid.
4. **Avoid cloning large structures when only reading**: remember that under `RMM2`, function input arguments incur zero reference-count overhead (`+0` / `-0`).
5. **Pair `time` with `test` (`import test`)**: always lock in your domain invariants with `assert equals` or `assert true`.

---

In **Chapter 19**, we will explore the **`uuid`** lib in full depth (The `uuid` Lib — RFC 9562 `UUIDv4`/`UUIDv7`, Checksums (`CRC-32`), and PRNG).
