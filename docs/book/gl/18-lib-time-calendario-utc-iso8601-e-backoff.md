# Capítulo 18: A lib `time` — Calendario Civil UTC (Hinnant), ISO-8601, Duracións e Backoff

## 1. Por que existe a lib `time`?

Sexamos sinceros: as funcións de data de `libc` (`localtime`, `gmtime`, `mktime`) dependen de estado global mutable (`TZ`), non son seguras entre fíos e fallan con regras de anos bisestos seculares coma 1900 vs 2000.

A lib **`time`** implementa o algoritmo de calendario civil gregoriano proléptico en **$O(1)$ de Howard Hinnant**, formatado e análise estrita **ISO-8601 / RFC 3339** (`YYYY-MM-DDTHH:MM:SSZ`), duracións lexibles (`1h 1m 1s 5ms`) e cálculo de *exponential backoff* acoutado para reintentos de rede.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`time`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/time.rg` (dominio `TIME`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/time.rglib` | Distribución e importación directa con `import time` |
| **Ficheiro compilado** | `target/time.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libtime.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import time` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `time`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `time epoch to utc / time utc to epoch` | Conversión en $O(1)$ entre segundos Unix epoch e `(year, month, day, hour, min, sec)` |
| `time is leap year / time days in month / time day of week` | Regras de ano bisesto (`400 / 100 / 4`), días do mes e día ISO da semana (`1=Lun..7=Dom`) |
| `time format iso8601 / time parse iso8601` | Formatea e valida marcas `YYYY-MM-DDTHH:MM:SSZ` (`-1` en datas inválidas coma 30 de feb) |
| `time format duration ms / time backoff ms` | Duracións lexibles e tempos de espera exponenciais acoutados $base \cdot 2^{attempt}$ |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `time`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import time

fn :: registrar evento temporal (epoch_s : Int) => (String, Int, String)
      registrar evento temporal epoch_s =
        iso = time format iso8601 epoch_s
        sem = time day of week epoch_s
        dur = time format duration ms 3661005
        (iso, sem, dur)
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `time` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import time

fn :: planificar reintentos () => [Int]
      planificar reintentos =
        [time backoff ms 0 100 5000, time backoff ms 1 100 5000, time backoff ms 2 100 5000, time backoff ms 9 100 5000]
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Conversión de calendario en $O(1)$ sen bucles ano por ano e validación estrita de días por mes (rexeitando o 29 de febreiro en anos non bisestos).
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_time.rg`.
