# Capítulo 32: La lib `net_agent` — Supervisor de Conexiones de Red y Puente de Eventos No Bloqueante

## 1. ¿Por qué existe la lib `net_agent`?

Seamos sinceros: en un servidor real como **Solstice**, aceptar conexiones TCP es la parte fácil; lo difícil es limitar el máximo de clientes simultáneos, desconectar clientes zombis inactivos (*idle timeout*) y conectar el bucle `ppoll` con tus actores sin fugas de descriptores.

La lib **`net_agent`** cierra el círculo de `ridgun-libs` uniendo **`posix`**, **`socket`** y **`agent`**: gestiona tablas de conexiones supervisadas (`NetSupervisor`), aplica límites de concurrencia (`max_conns`), purga conexiones inactivas (`net evict idle`) y convierte eventos de descriptores del kernel en eventos tipados (`NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout`, `NetEvError`) además de ofrecer un paso de eco TCP completo de extremo a extremo (`net tcp echo step`).

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`net_agent`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/net_agent.rg` (dominio `AGENT`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/net_agent.rglib` | Distribución e importación directa con `import net_agent` |
| **Archivo compilado** | `target/net_agent.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libnet_agent.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import net_agent` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `net_agent`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `net supervisor new : Int -> Int -> NetSupervisor` | Crea un supervisor de conexiones con límite `max_conns` e inactividad `idle_timeout_ms` |
| `net register conn / net record rx / net record tx / net close conn` | Registra sockets aceptados, actualiza contadores de bytes/actividad y cierra pares |
| `net evict idle : NetSupervisor -> Int -> (NetSupervisor, [Int])` | Cierra y expulsa conexiones inactivas más allá de `idle_timeout_ms`, devolviendo sus FDs |
| `net poll fd : Int -> Bool -> Int -> NetEvent` | Puente `wait fd` no bloqueante que emite `NetEvReadyRead`, `NetEvReadyWrite`, `NetEvTimeout` o `NetEvError` |
| `net tcp echo step : String -> Int -> (Int, String)` | Paso completo de extremo a extremo TCP loopback (`listen/connect/accept/supervise/echo`) |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `net_agent`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

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

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `net_agent` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import net_agent

fn :: probar puente tcp supervisado () => (Int, String)
      probar puente tcp supervisado =
        net tcp echo step "ping-supervisado" 1000
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Protección automática frente a agotamiento de descriptores (`max_conns`), expulsión determinista de conexiones inactivas y cierre garantizado de sockets en `net tcp echo step`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_net_agent.rg`.
