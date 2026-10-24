# Chapter 18: The `time` Lib — Howard Hinnant UTC Calendar, ISO-8601, Durations, and Backoff

## 1. Why Does the `time` Lib Exist?

Let's be honest: `libc` date functions (`localtime`, `gmtime`, `mktime`) rely on hidden mutable global state (`TZ`), aren't thread-safe, and trip developers up on century leap-year rules.

The **`time`** lib implements **Howard Hinnant's $O(1)$** proleptic Gregorian UTC civil calendar algorithm, strict **ISO-8601 / RFC 3339** formatting and parsing (`YYYY-MM-DDTHH:MM:SSZ`), human-readable durations (`1h 1m 1s 5ms`), and bounded exponential backoff.

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`time`** is a first-class **lib** located at `src/main/ridgun/lib/time.rg` (domain `TIME`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/time.rglib` | Portable distribution and direct `import time` resolution |
| **Compiled Archive** | `target/time.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libtime.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import time` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `time`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `time epoch to utc / time utc to epoch` | $O(1)$ conversion between Unix epoch seconds and `(year, month, day, hour, min, sec)` |
| `time is leap year / time days in month / time day of week` | Leap-year rules (`400 / 100 / 4`), month lengths, and ISO weekday (`1=Mon..7=Sun`) |
| `time format iso8601 / time parse iso8601` | Format and validate `YYYY-MM-DDTHH:MM:SSZ` timestamps (`-1` on invalid dates like Feb 30) |
| `time format duration ms / time backoff ms` | Human duration strings and capped $base \cdot 2^{attempt}$ retry delays |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `time`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import time

fn :: registrar evento temporal (epoch_s : Int) => (String, Int, String)
      registrar evento temporal epoch_s =
        iso = time format iso8601 epoch_s
        sem = time day of week epoch_s
        dur = time format duration ms 3661005
        (iso, sem, dur)
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `time` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import time

fn :: planificar reintentos () => [Int]
      planificar reintentos =
        [time backoff ms 0 100 5000, time backoff ms 1 100 5000, time backoff ms 2 100 5000, time backoff ms 9 100 5000]
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: $O(1)$ calendar conversion with zero year-by-year loops and strict per-month day validation (rejecting Feb 29 on non-leap years).
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_time.rg`.
