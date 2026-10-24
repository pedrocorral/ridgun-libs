# Capítulo 30: La lib `agent` — Modelo Nativo de Actores (`agent`, `send`, `receive`), KV Store y Rate Limiter

## 1. ¿Por qué existe la lib `agent`?

Seamos sinceros: compartir memoria mutable entre hilos con `Mutex`, `RwLock` y variables de condición es una fábrica inagotable de *deadlocks* y condiciones de carrera.

La lib **`agent`** aprovecha el **Modelo Nativo de Agentes** de Ridgun (`agent`, `send ... to`, `receive from`, `try receive from`, `stop`) para ofrecer buzones aislados con paso de mensajes Copy-on-Write, un almacén clave-valor concurrente (`KvStore`), un limitador de tasa por cubo de tokens (`RateBucket`) y supervisión de estado (`AgentHealth`).

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`agent`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/agent.rg` (dominio `AGENT`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/agent.rglib` | Distribución e importación directa con `import agent` |
| **Archivo compilado** | `target/agent.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libagent.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import agent` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `agent`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `agent roundtrip / agent drain count` | Lanza actores nativos (`agent`), intercambia mensajes (`send ... to` / `receive from`) y ejecuta `stop` |
| `kv store new / kv store apply` | Almacén clave-valor inmutable para actores (`KvPut`, `KvGet`, `KvDelete`, `KvClear`) |
| `rate bucket new / rate bucket allow` | Limitador de tasa por cubo de tokens que devuelve el cubo actualizado y `(allowed, remaining)` |
| `sup mark failed / sup should restart` | Políticas de supervisión con control de presupuesto de reinicios (`max_restarts`) |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `agent`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import agent

fn :: probar actor nativo () => (Int, Int)
      probar actor nativo =
        eco = agent roundtrip 42
        vac = agent drain count [10, 20, 30]
        (eco, vac)
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `agent` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import agent

fn :: aplicar limite peticion () => (Bool, Int)
      aplicar limite peticion =
        b0         = rate bucket new 10 2 1000
        (b1, res1) = rate bucket allow b0 1 1000
        rateresp allowed res1, rateobs remaining res1
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Cero memoria mutable compartida entre actores: cada mensaje se transfiere por valor / Copy-on-Write y `stop` libera la región del agente de forma determinista.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_agent.rg`.
