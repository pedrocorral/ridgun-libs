# Capítol 30: La lib `agent` — Model Natiu d'Actors (`agent`, `send`, `receive`), KV Store i Rate Limiter

## 1. Per què existeix la lib `agent`?

Siguem sincers: compartir memòria mutable entre fils amb `Mutex`, `RwLock` i variables de condició és una fàbrica inesgotable de *deadlocks* i condicions de carrera.

La lib **`agent`** aprofita el **Model Natiu d'Agents** de Ridgun (`agent`, `send ... to`, `receive from`, `try receive from`, `stop`) per oferir bústies aïllades amb pas de missatges Copy-on-Write, un magatzem clau-valor concurrent (`KvStore`), un limitador de taxa per cubell de tokens (`RateBucket`) i supervisió d'estat (`AgentHealth`).

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`agent`** és una **lib** de primera classe situada a `src/main/ridgun/lib/agent.rg` (domini `AGENT`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/agent.rglib` | Distribució i importació directa amb `import agent` |
| **Fitxer compilat** | `target/agent.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libagent.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import agent` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `agent`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `agent roundtrip / agent drain count` | Llança actors natius (`agent`), intercanvia missatges (`send ... to` / `receive from`) i executa `stop` |
| `kv store new / kv store apply` | Magatzem clau-valor immutable per a actors (`KvPut`, `KvGet`, `KvDelete`, `KvClear`) |
| `rate bucket new / rate bucket allow` | Limitador de taxa per cubell de tokens que retorna el cubell actualitzat i `(allowed, remaining)` |
| `sup mark failed / sup should restart` | Polítiques de supervisió amb control de pressupost de reinicis (`max_restarts`) |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `agent`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import agent

fn :: probar actor nativo () => (Int, Int)
      probar actor nativo =
        eco = agent roundtrip 42
        vac = agent drain count [10, 20, 30]
        (eco, vac)
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `agent` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import agent

fn :: aplicar limite peticion () => (Bool, Int)
      aplicar limite peticion =
        b0         = rate bucket new 10 2 1000
        (b1, res1) = rate bucket allow b0 1 1000
        rateresp allowed res1, rateobs remaining res1
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Zero memòria mutable compartida entre actors: cada missatge es transfereix per valor / Copy-on-Write i `stop` allibera la regió de l'agent de forma determinista.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_agent.rg`.
