# Capítulo 31: A lib `pool` — Pool Acoutado de Traballadores, Round-Robin e Roubo de Traballo

## 1. Por que existe a lib `pool`?

Sexamos sinceros: lanzar un fío ou actor novo por cada petición entrante sen límite superior (`unbounded spawning`) fai que un pico de tráfico esgote a memoria en segundos (*Out Of Memory*).

A lib **`pool`** proporciona un despachador de tarefas con **contrapresión explícita** (`PoolAccept`, `PoolRejectFull`), partición equilibrada de lotes en $K$ carrís (`pool partition`), reequilibrio por **roubo de traballo (*work-stealing*)** (`pool steal rebalance`) e execución paralela sobre actores nativos.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`pool`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/pool.rg` (dominio `AGENT`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/pool.rglib` | Distribución e importación directa con `import pool` |
| **Ficheiro compilado** | `target/pool.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libpool.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import pool` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `pool`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `pool new : Int -> Int -> PoolState` | Crea un pool acoutado con `workers` carrís e capacidade máxima `max_queue` |
| `pool submit : PoolState -> PoolTask -> (PoolState, PoolDecision)` | Enfila unha tarefa en round-robin ou devolve `PoolRejectFull` se está saturado |
| `pool partition / pool steal rebalance` | Reparte lotes entre $K$ traballadores e rouba a metade dunha fila sobrecargada para un traballador libre |
| `pool map sum / pool parallel sum2` | Despacha cargas de traballo en paralelo sobre traballadores `agent` nativos |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `pool`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import pool

fn :: encolar con contrapresion () => (Int, Int)
      encolar con contrapresion =
        p0        = pool new 4 16
        tarea     = PoolTask 1 100 "indexar-bloque"
        (p1, dec) = pool submit p0 tarea
        (pool queued p1, pool accepted p1)
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `pool` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import pool

fn :: sumar en paralelo () => Int
      sumar en paralelo =
        pool parallel sum2 [10, 20, 30] [40, 50, 60]
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Capacidade de fila estritamente acoutada (`queued <= max_queue`) para protexer a memoria baixo sobrecarga e reparto determinista entre traballadores.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_pool.rg`.
