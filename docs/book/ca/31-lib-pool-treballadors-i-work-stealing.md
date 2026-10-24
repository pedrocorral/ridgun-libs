# Capítol 31: La lib `pool` — Pool Acotat de Treballadors, Round-Robin i Robatori de Treball

## 1. Per què existeix la lib `pool`?

Siguem sincers: llançar un fil o actor nou per cada petició entrant sense límit superior (`unbounded spawning`) fa que un pic de trànsit esgoti la memòria en segons (*Out Of Memory*).

La lib **`pool`** proporciona un despatxador de tasques amb **contrapressió explícita** (`PoolAccept`, `PoolRejectFull`), partició equilibrada de lots en $K$ carrils (`pool partition`), reequilibri per **robatori de treball (*work-stealing*)** (`pool steal rebalance`) i execució paral·lela sobre actors natius.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`pool`** és una **lib** de primera classe situada a `src/main/ridgun/lib/pool.rg` (domini `AGENT`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/pool.rglib` | Distribució i importació directa amb `import pool` |
| **Fitxer compilat** | `target/pool.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libpool.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import pool` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `pool`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `pool new : Int -> Int -> PoolState` | Crea un pool acotat amb `workers` carrils i capacitat màxima `max_queue` |
| `pool submit : PoolState -> PoolTask -> (PoolState, PoolDecision)` | Encola una tasca en round-robin o retorna `PoolRejectFull` si està saturat |
| `pool partition / pool steal rebalance` | Reparteix lots entre $K$ treballadors i roba la meitat d'una cua sobrecarregada per a un treballador lliure |
| `pool map sum / pool parallel sum2` | Despatxa càrregues de treball en paral·lel sobre treballadors `agent` natius |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `pool`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import pool

fn :: encolar con contrapresion () => (Int, Int)
      encolar con contrapresion =
        p0        = pool new 4 16
        tarea     = PoolTask 1 100 "indexar-bloque"
        (p1, dec) = pool submit p0 tarea
        (pool queued p1, pool accepted p1)
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `pool` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import pool

fn :: sumar en paralelo () => Int
      sumar en paralelo =
        pool parallel sum2 [10, 20, 30] [40, 50, 60]
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Capacitat de cua estrictament acotada (`queued <= max_queue`) per protegir la memòria sota sobrecàrrega i repartiment determinista entre treballadors.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_pool.rg`.
