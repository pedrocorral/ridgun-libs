# Capítol 29: La lib `ws` — Handshake WebSocket RFC 6455, Framing de 16/64 bits i Emmascament XOR

## 1. Per què existeix la lib `ws`?

Siguem sincers: el protocol WebSocket (RFC 6455) combina un handshake SHA-1 + Base64 amb trames binàries de longitud variable (7 bits, 16 bits o 64 bits) i emmascarament XOR obligatori de client a servidor.

La lib **`ws`** implementa **RFC 6455** complet en Ridgun pur: càlcul de `Sec-WebSocket-Accept` (amb SHA-1 RFC 3174 integrat exclusivament per al GUID de handshake), capçaleres HTTP `101 Switching Protocols`, codificació i descodificació de trames (`WsFrame`) amb longituds de 7, 16 (`126`) i 64 bits (`127`), emmascarament simètric XOR i constructors de trames de text, ping, pong i tancament.

---

## 2. Artefactes, importació i arquitectura sense `libc`

A `ridgun-libs`, **`ws`** és una **lib** de primera classe situada a `src/main/ridgun/lib/ws.rg` (domini `WS`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/ws.rglib` | Distribució i importació directa amb `import ws` |
| **Fitxer compilat** | `target/ws.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libws.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Per fer servir aquesta lib en qualsevol fitxer `.rg`, n'hi ha prou de declarar `import ws` a la capçalera i cridar les seves funcions amb espais o guions baixos indistintament.

---

## 3. Referència ràpida de l'API de `ws`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `ws accept key : String -> String` | Calcula `Sec-WebSocket-Accept` (RFC 6455 §1.3) a partir de `Sec-WebSocket-Key` |
| `ws build upgrade request / ws build upgrade response` | Formata els missatges HTTP/1.1 de negociació (upgrade handshake) WebSocket |
| `ws encode frame / ws decode frame` | Codifica i descodifica trames `WsFrame` (`fin`, `opcode`, `masked`, `mask_key`, `payload`) |
| `ws text frame / ws ping frame / ws pong frame / ws close frame` | Constructors de trames d'alt nivell i extractors de codi de tancament (`1000` normal) |

---

## 4. Receptes pràctiques en estil tabular

### Recepta 1: Flux principal amb `ws`

Observa com els signes `=` i els passos de transformació queden alineats com una taula neta:

```ridgun
import ws

fn :: negociar y enviar (client_key : String) => (String, String)
      negociar y enviar client_key =
        resp  = ws build upgrade response client_key
        trama = ws encode frame (ws text frame "hola-tiempo-real" False "")
        (resp, trama)
```

### Recepta 2: Composició segura i sense efectes laterals

Tota funció de la lib `ws` és componible amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import ws

fn :: decodificar trama cliente (clave4 : String) (msg : String) => String
      decodificar trama cliente clave4 msg =
        wire = ws encode frame (ws text frame msg True clave4)
        res  = ws decode frame wire
        ws frame payload res
```

---

## 5. Sota el capó: rendiment, memòria RMM i garanties

- **Garantia algorísmica i de seguretat**: Coincidència exacta amb el vector oficial RFC 6455 (`"dGhlIHNhbXBsZSBub25jZQ=="` $\rightarrow$ `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="`) i desemmascarament automàtic a `ws decode frame`.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test_ws.rg`.
