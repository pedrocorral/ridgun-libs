# Capítulo 29: A lib `ws` — Handshake WebSocket RFC 6455, Framing de 16/64 bits e Enmascarado XOR

## 1. Por que existe a lib `ws`?

Sexamos sinceros: o protocolo WebSocket (RFC 6455) combina un handshake SHA-1 + Base64 con tramas binarias de lonxitude variable (7 bits, 16 bits ou 64 bits) e enmascarado XOR obrigatorio de cliente a servidor.

A lib **`ws`** implementa **RFC 6455** completo en Ridgun puro: cálculo de `Sec-WebSocket-Accept` (con SHA-1 RFC 3174 integrado exclusivamente para o GUID de handshake), cabeceiras HTTP `101 Switching Protocols`, codificación e descodificación de tramas (`WsFrame`) con lonxitudes de 7, 16 (`126`) e 64 bits (`127`), enmascarado simétrico XOR e construtores de tramas de texto, ping, pong e peche.

---

## 2. Artefactos, importación e arquitectura sen `libc`

En `ridgun-libs`, **`ws`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/ws.rg` (dominio `WS`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/ws.rglib` | Distribución e importación directa con `import ws` |
| **Ficheiro compilado** | `target/ws.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libws.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import ws` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

---

## 3. Referencia rápida da API de `ws`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `ws accept key : String -> String` | Calcula `Sec-WebSocket-Accept` (RFC 6455 §1.3) a partir de `Sec-WebSocket-Key` |
| `ws build upgrade request / ws build upgrade response` | Formatea as mensaxes HTTP/1.1 de negociación (upgrade handshake) WebSocket |
| `ws encode frame / ws decode frame` | Codifica e descodifica tramas `WsFrame` (`fin`, `opcode`, `masked`, `mask_key`, `payload`) |
| `ws text frame / ws ping frame / ws pong frame / ws close frame` | Construtores de tramas de alto nivel e extractores de código de peche (`1000` normal) |

---

## 4. Receitas prácticas en estilo tabular

### Receita 1: Fluxo principal con `ws`

Observa como os signos `=` e os pasos de transformación quedan aliñados coma unha táboa limpa:

```ridgun
import ws

fn :: negociar y enviar (client_key : String) => (String, String)
      negociar y enviar client_key =
        resp  = ws build upgrade response client_key
        trama = ws encode frame (ws text frame "hola-tiempo-real" False "")
        (resp, trama)
```

### Receita 2: Composición segura e sen efectos laterais

Toda función da lib `ws` é compoñible co resto das 32 libs de `ridgun-libs`:

```ridgun
import ws

fn :: decodificar trama cliente (clave4 : String) (msg : String) => String
      decodificar trama cliente clave4 msg =
        wire = ws encode frame (ws text frame msg True clave4)
        res  = ws decode frame wire
        ws frame payload res
```

---

## 5. Baixo o capó: rendemento, memoria RMM e garantías

- **Garantía algorítmica e de seguridade**: Coincidencia exacta co vector oficial RFC 6455 (`"dGhlIHNhbXBsZSBub25jZQ=="` $\rightarrow$ `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="`) e desenmascarado automático en `ws decode frame`.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test_ws.rg`.
