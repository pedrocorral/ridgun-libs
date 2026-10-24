# Capítulo 32: A lib `net_agent` — Supervisor de Conexións de Rede e Ponte de Eventos Non Bloqueante

## 1. Por que existe a lib `net_agent`?

Sexamos sinceros: nun servidor real coma **Solstice**, aceptar conexións TCP é a parte fácil; o difícil é limitar o máximo de clientes simultáneos, desconectar clientes zombis inactivos (*idle timeout*) e conectar o bucle `ppoll` cos teus actores sen fugas de descritores.

A lib **`net_agent`** pecha o círculo de `ridgun-libs` unindo **`posix`**, **`socket`** e **`agent`**: xestiona táboas de conexións supervisadas (`NetSupervisor`), aplica límites de concorrencia (`max_conns`), purga conexións inactivas (`net evict idle`) e converte eventos de descritores do kernel en eventos tipados (`NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout`, `NetEvError`) ademais de ofrecer un paso de eco TCP completo de extremo a extremo (`net tcp echo step`).

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`net_agent`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/net_agent.rg` (dominio `AGENT`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/net_agent.rglib` | Distribución e importación directa con `import net_agent` |
| **Ficheiro compilado** | `target/net_agent.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libnet_agent.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import net_agent` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `net_agent`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `net supervisor new : Int -> Int -> NetSupervisor` | Crea un supervisor de conexións con límite `max_conns` e inactividade `idle_timeout_ms` |
| `net register conn / net record rx / net record tx / net close conn` | Rexistra sockets aceptados, actualiza contadores de bytes/actividade e pecha pares |
| `net evict idle : NetSupervisor -> Int -> (NetSupervisor, [Int])` | Pecha e expulsa conexións inactivas máis aló de `idle_timeout_ms`, devolvendo os seus FDs |
| `net poll fd : Int -> Bool -> Int -> NetEvent` | Ponte `wait fd` non bloqueante que emite `NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout` ou `NetEvError` |
| `net tcp echo step : String -> Int -> (Int, String)` | Paso completo de extremo a extremo TCP loopback (`listen/connect/accept/supervise/echo`) |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `net_agent`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import net_agent

fn :: supervisar clientes () => (Int, [Int])
      supervisar clientes =
        s0        = net supervisor new 100 5000
        (s1, _)   = net register conn s0 10 "10.0.0.1" 51000 1000
        (s2, _)   = net register conn s1 11 "10.0.0.2" 51001 6500
        (s3, exp) = net evict idle s2 7000
        (net active count s3, exp)
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `net_agent` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import net_agent

fn :: probar puente tcp supervisado () => (Int, String)
      probar puente tcp supervisado =
        net tcp echo step "ping-supervisado" 1000
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Protección automática fronte a esgotamento de descritores (`max_conns`), expulsión determinista de conexións inactivas e peche garantido de sockets en `net tcp echo step`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_net_agent.rg`.
