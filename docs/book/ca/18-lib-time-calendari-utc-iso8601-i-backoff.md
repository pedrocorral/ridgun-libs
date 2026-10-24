# Capítol 18: La lib `time` — Calendari Civil UTC (Hinnant), ISO-8601, Durades i Backoff

## 1. Per què existeix la lib `time`?

Siguem sincers: les funcions de data de `libc` (`localtime`, `gmtime`, `mktime`) depenen d'estat global mutable (`TZ`), no són segures entre fils i fallen amb regles d'anys de traspàs seculars com 1900 vs 2000.

La lib **`time`** implementa l'algorisme de calendari civil gregorià prolèptic en **$O(1)$ de Howard Hinnant**, formatat i anàlisi estricta **ISO-8601 / RFC 3339** (`YYYY-MM-DDTHH:MM:SSZ`), durades llegibles (`1h 1m 1s 5ms`) i càlcul d'*exponential backoff* acotat per a reintents de xarxa.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`time`** és una **lib** de primera classe situada a `src/main/ridgun/lib/time.rg` (domini `TIME`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/time.rglib` | Distribució i importació directa amb `import time` |
| **Fitxer compilat** | `target/time.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libtime.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import time` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `time`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `time epoch to utc / time utc to epoch` | Conversió en $O(1)$ entre segons Unix epoch i `(year, month, day, hour, min, sec)` |
| `time is leap year / time days in month / time day of week` | Regles d'any de traspàs (`400 / 100 / 4`), dies del mes i dia ISO de la setmana (`1=Dll..7=Diu`) |
| `time format iso8601 / time parse iso8601` | Formata i valida marques `YYYY-MM-DDTHH:MM:SSZ` (`-1` en dates invàlides com 30 de feb) |
| `time format duration ms / time backoff ms` | Durades llegibles i temps d'espera exponencials acotats $base \cdot 2^{attempt}$ |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `time`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import time

fn :: registrar evento temporal (epoch_s : Int) => (String, Int, String)
      registrar evento temporal epoch_s =
        iso = time format iso8601 epoch_s
        sem = time day of week epoch_s
        dur = time format duration ms 3661005
        (iso, sem, dur)
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `time` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import time

fn :: planificar reintentos () => [Int]
      planificar reintentos =
        [time backoff ms 0 100 5000, time backoff ms 1 100 5000, time backoff ms 2 100 5000, time backoff ms 9 100 5000]
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Conversió de calendari en $O(1)$ sense bucles any per any i validació estricta de dies per mes (rebutjant el 29 de febrer en anys no de traspàs).
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_time.rg`.
