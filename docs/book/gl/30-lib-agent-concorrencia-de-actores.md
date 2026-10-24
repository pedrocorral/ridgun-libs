# Capítulo 30: A lib `agent` — Modelo Nativo de Actores (`agent`, `send`, `receive`), KV Store e Rate Limiter

## 1. Por que existe a lib `agent`?

Sexamos sinceros: compartir memoria mutable entre fíos con `Mutex`, `RwLock` e variables de condición é unha fábrica inesgotable de *deadlocks* e condicións de carreira.

A lib **`agent`** aproveita o **Modelo Nativo de Axentes** de Ridgun (`agent`, `send ... to`, `receive from`, `try receive from`, `stop`) para ofrecer caixas de correo illadas con paso de mensaxes Copy-on-Write, un almacén chave-valor concorrente (`KvStore`), un limitador de taxa por cubo de tokens (`RateBucket`) e supervisión de estado (`AgentHealth`).

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`agent`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/agent.rg` (dominio `AGENT`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/agent.rglib` | Distribución e importación directa con `import agent` |
| **Ficheiro compilado** | `target/agent.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libagent.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import agent` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `agent`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `agent roundtrip / agent drain count` | Lanza actores nativos (`agent`), intercambia mensaxes (`send ... to` / `receive from`) e executa `stop` |
| `kv store new / kv store apply` | Almacén chave-valor inmutable para actores (`KvPut`, `KvGet`, `KvDelete`, `KvClear`) |
| `rate bucket new / rate bucket allow` | Limitador de taxa por cubo de tokens que devolve o cubo actualizado e `(allowed, remaining)` |
| `sup mark failed / sup should restart` | Políticas de supervisión con control de orzamento de reinicios (`max_restarts`) |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `agent`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import agent

fn :: probar actor nativo () => (Int, Int)
      probar actor nativo =
        eco = agent roundtrip 42
        vac = agent drain count [10, 20, 30]
        (eco, vac)
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `agent` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import agent

fn :: aplicar limite peticion () => (Bool, Int)
      aplicar limite peticion =
        b0         = rate bucket new 10 2 1000
        (b1, res1) = rate bucket allow b0 1 1000
        rateresp allowed res1, rateobs remaining res1
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Cero memoria mutable compartida entre actores: cada mensaxe transfírese por valor / Copy-on-Write e `stop` libera a rexión do axente de forma determinista.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_agent.rg`.
