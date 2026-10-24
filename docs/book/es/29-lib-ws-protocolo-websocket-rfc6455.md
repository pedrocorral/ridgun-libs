# Capítulo 29: La lib `ws` — Handshake WebSocket RFC 6455, Framing de 16/64 bits y Enmascarado XOR

## 1. ¿Por qué existe la lib `ws`?

Seamos sinceros: el protocolo WebSocket (RFC 6455) combina un handshake SHA-1 + Base64 con tramas binarias de longitud variable (7 bits, 16 bits o 64 bits) y enmascarado XOR obligatorio de cliente a servidor.

La lib **`ws`** implementa **RFC 6455** completo en Ridgun puro: cálculo de `Sec-WebSocket-Accept` (con SHA-1 RFC 3174 integrado exclusivamente para el GUID de handshake), cabeceras HTTP `101 Switching Protocols`, codificación y decodificación de tramas (`WsFrame`) con longitudes de 7, 16 (`126`) y 64 bits (`127`), enmascarado simétrico XOR y constructores de tramas de texto, ping, pong y cierre.

---

## 2. Artefactos, importación y arquitectura sin `libc`

En `ridgun-libs`, **`ws`** es una **lib** de primera clase ubicada en `src/main/ridgun/lib/ws.rg` (dominio `WS`). Al compilar con `stable bundle`, se empaqueta en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/ws.rglib` | Distribución e importación directa con `import ws` |
| **Archivo compilado** | `target/ws.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Objeto compartido ELF64** | `target/libws.so` | Biblioteca dinámica nativa sin dependencias de C ni `libc` |

> Para usar esta lib en cualquier archivo `.rg`, basta con declarar `import ws` en el encabezado y llamar a sus funciones con espacios o guiones bajos indistintamente.

---

## 3. Referencia rápida de la API de `ws`

| Firma / Función / Tipo | Qué hace y cuándo usarla |
|---|---|
| `ws accept key : String -> String` | Calcula `Sec-WebSocket-Accept` (RFC 6455 §1.3) a partir de `Sec-WebSocket-Key` |
| `ws build upgrade request / ws build upgrade response` | Formatea los mensajes HTTP/1.1 de negociación (upgrade handshake) WebSocket |
| `ws encode frame / ws decode frame` | Codifica y decodifica tramas `WsFrame` (`fin`, `opcode`, `masked`, `mask_key`, `payload`) |
| `ws text frame / ws ping frame / ws pong frame / ws close frame` | Constructores de tramas de alto nivel y extractores de código de cierre (`1000` normal) |

---

## 4. Recetas prácticas en estilo tabular

### Receta 1: Flujo principal con `ws`

Observa cómo los signos `=` y los pasos de transformación quedan alineados como una tabla limpia:

```ridgun
import ws

fn :: negociar y enviar (client_key : String) => (String, String)
      negociar y enviar client_key =
        resp  = ws build upgrade response client_key
        trama = ws encode frame (ws text frame "hola-tiempo-real" False "")
        (resp, trama)
```

### Receta 2: Composición segura y sin efectos laterales

Toda función de la lib `ws` es componible con el resto de las 32 libs de `ridgun-libs`:

```ridgun
import ws

fn :: decodificar trama cliente (clave4 : String) (msg : String) => String
      decodificar trama cliente clave4 msg =
        wire = ws encode frame (ws text frame msg True clave4)
        res  = ws decode frame wire
        ws frame payload res
```

---

## 5. Bajo el capó: rendimiento, memoria RMM y garantías

- **Garantía algorítmica y de seguridad**: Coincidencia exacta con el vector oficial RFC 6455 (`"dGhlIHNhbXBsZSBub25jZQ=="` $\rightarrow$ `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="`) y desenmascarado automático en `ws decode frame`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de recolector de basura; todas las estructuras intermedias se liberan de forma determinista al salir del ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` y la suite automatizada `src/test/ridgun/test_ws.rg`.
