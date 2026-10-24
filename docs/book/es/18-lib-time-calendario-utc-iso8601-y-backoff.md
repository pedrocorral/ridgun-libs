# Capítulo 18: La lib `time` — Calendario Civil UTC (Hinnant), ISO-8601, Duraciones y Backoff

## 1. ¿Por qué existe la lib `time`?

Seamos sinceros: las funciones de fecha de `libc` (`localtime`, `gmtime`, `mktime`) dependen de estado global mutable (`TZ`), no son seguras entre hilos y fallan con reglas de años bisiestos seculares como 1900 vs 2000.

La lib **`time`** implementa el algoritmo de calendario civil gregoriano proléptico en **$O(1)$ de Howard Hinnant**, formateo y análisis estricto **ISO-8601 / RFC 3339** (`YYYY-MM-DDTHH:MM:SSZ`), duraciones legibles (`1h 1m 1s 5ms`) y cálculo de *exponential backoff* acotado para reintentos de red.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`time`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/time.rg` (dominio `TIME`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/time.rglib` | Distribución e importación directa con `import time` |
| **Archivo compilado** | `target/time.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libtime.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import time` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `time`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `time epoch to utc / time utc to epoch` | Conversión en $O(1)$ entre segundos Unix epoch y `(year, month, day, hour, min, sec)` |
| `time is leap year / time days in month / time day of week` | Reglas de año bisiesto (`400 / 100 / 4`), días del mes y día ISO de la semana (`1=Lun..7=Dom`) |
| `time format iso8601 / time parse iso8601` | Formatea y valida marcas `YYYY-MM-DDTHH:MM:SSZ` (`-1` en fechas inválidas como 30 de feb) |
| `time format duration ms / time backoff ms` | Duraciones legibles y tiempos de espera exponenciales acotados $base \cdot 2^{attempt}$ |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `time`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import time

fn :: registrar evento temporal (epoch_s : Int) => (String, Int, String)
      registrar evento temporal epoch_s =
        iso = time format iso8601 epoch_s
        sem = time day of week epoch_s
        dur = time format duration ms 3661005
        (iso, sem, dur)
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `time` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import time

fn :: planificar reintentos () => [Int]
      planificar reintentos =
        [time backoff ms 0 100 5000, time backoff ms 1 100 5000, time backoff ms 2 100 5000, time backoff ms 9 100 5000]
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Conversión de calendario en $O(1)$ sin bucles año por año y validación estricta de días por mes (rechazando el 29 de febrero en años no bisiestos).
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_time.rg`.
