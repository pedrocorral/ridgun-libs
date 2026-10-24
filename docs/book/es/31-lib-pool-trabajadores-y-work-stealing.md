# Capítulo 31: La lib `pool` — Pool Acotado de Trabajadores, Round-Robin y Robo de Trabajo

## 1. ¿Por qué existe la lib `pool`?

Seamos sinceros: lanzar un hilo o actor nuevo por cada petición entrante sin límite superior (`unbounded spawning`) hace que un pico de tráfico agote la memoria en segundos (*Out Of Memory*).

La lib **`pool`** proporciona un despachador de tareas con **contrapresión explícita** (`PoolAccept`, `PoolRejectFull`), partición equilibrada de lotes en $K$ carriles (`pool partition`), reequilibrio por **robo de trabajo (*work-stealing*)** (`pool steal rebalance`) y ejecución paralela sobre actores nativos.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`pool`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/pool.rg` (dominio `AGENT`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/pool.rglib` | Distribución e importación directa con `import pool` |
| **Archivo compilado** | `target/pool.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libpool.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import pool` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `pool`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `pool new : Int -> Int -> PoolState` | Crea un pool acotado con `workers` carriles y capacidad máxima `max_queue` |
| `pool submit : PoolState -> PoolTask -> (PoolState, PoolDecision)` | Encola una tarea en round-robin o devuelve `PoolRejectFull` si está saturado |
| `pool partition / pool steal rebalance` | Reparte lotes entre $K$ trabajadores y roba la mitad de una cola sobrecargada para un trabajador libre |
| `pool map sum / pool parallel sum2` | Despacha cargas de trabajo en paralelo sobre trabajadores `agent` nativos |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `pool`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import pool

fn :: encolar con contrapresion () => (Int, Int)
      encolar con contrapresion =
        p0        = pool new 4 16
        tarea     = PoolTask 1 100 "indexar-bloque"
        (p1, dec) = pool submit p0 tarea
        (pool queued p1, pool accepted p1)
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `pool` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import pool

fn :: sumar en paralelo () => Int
      sumar en paralelo =
        pool parallel sum2 [10, 20, 30] [40, 50, 60]
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Capacidad de cola estrictamente acotada (`queued <= max_queue`) para proteger la memoria bajo sobrecarga y reparto determinista entre trabajadores.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_pool.rg`.
