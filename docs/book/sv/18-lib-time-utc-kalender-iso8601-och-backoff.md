# Kapitel 18: Lib:en `time` — UTC-kalender (Hinnant), ISO-8601, Varaktigheter och Backoff

## 1. Varför finns lib:en `time`?

Låt oss vara ärliga: datumfunktionerna i `libc` (`localtime`, `gmtime`, `mktime`) förlitar sig på muterbart globalt tillstånd (`TZ`), är inte trådsäkra och snubblar lätt på skottårsregler.

Lib:en **`time`** implementerar **Howard Hinnants $O(1)$**-algoritm för den proleptiska gregorianska UTC-kalendern, strikt **ISO-8601 / RFC 3339**-formatering och tolkning (`YYYY-MM-DDTHH:MM:SSZ`), läsbara varaktigheter (`1h 1m 1s 5ms`) och exponentiell backoff.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`time`** en förstklassig **lib** placerad i `src/main/ridgun/lib/time.rg` (domän `TIME`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/time.rglib` | Portabel distribution och direkt import med `import time` |
| **Kompilerat arkiv** | `target/time.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libtime.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import time` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `time`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `time epoch to utc / time utc to epoch` | $O(1)$-konvertering mellan Unix epoch-sekunder och `(year, month, day, hour, min, sec)` |
| `time is leap year / time days in month / time day of week` | Skottårsregler (`400 / 100 / 4`), månadslängder och ISO-veckodag (`1=Mån..7=Sön`) |
| `time format iso8601 / time parse iso8601` | Formaterar och validerar `YYYY-MM-DDTHH:MM:SSZ`-tidsstämplar (`-1` vid ogiltiga datum som 30 feb) |
| `time format duration ms / time backoff ms` | Läsbara varaktigheter och begränsade exponentiella väntetider $base \cdot 2^{attempt}$ |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `time`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import time

fn :: registrar evento temporal (epoch_s : Int) => (String, Int, String)
      registrar evento temporal epoch_s =
        iso = time format iso8601 epoch_s
        sem = time day of week epoch_s
        dur = time format duration ms 3661005
        (iso, sem, dur)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `time` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import time

fn :: planificar reintentos () => [Int]
      planificar reintentos =
        [time backoff ms 0 100 5000, time backoff ms 1 100 5000, time backoff ms 2 100 5000, time backoff ms 9 100 5000]
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: $O(1)$-kalenderkonvertering utan år-för-år-loopar och strikt validering av dagar per månad (avvisar 29 februari under icke-skottår).
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_time.rg`.
