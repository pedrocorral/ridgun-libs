# Kapitel 29: Lib:en `ws` — RFC 6455 WebSocket-handskakning, 16/64-bitars Ramkodek och XOR-maskering

## 1. Varför finns lib:en `ws`?

Låt oss vara ärliga: WebSocket-protokollet (RFC 6455) kombinerar en SHA-1 + Base64-handskakning med binära ramar av variabel längd (7, 16 eller 64 bitar) och obligatorisk 4-bytes XOR-maskering från klient till server.

Lib:en **`ws`** implementerar hela **RFC 6455** i ren Ridgun: beräkning av `Sec-WebSocket-Accept` (med inbyggd RFC 3174 SHA-1 för handskaknings-GUID), `101 Switching Protocols`-headers, kodning och avkodning av 7/16/64-bitars `WsFrame`-ramar, symmetrisk XOR-maskering samt byggare för text-, ping-, pong- och stängningsramar.

---

## 2. Paket, import och arkitektur helt utan `libc`

I `ridgun-libs` är **`ws`** en förstklassig **lib** placerad i `src/main/ridgun/lib/ws.rg` (domän `WS`). När du bygger med `stable bundle` paketeras den i tre inbyggda format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/ws.rglib` | Portabel distribution och direkt import med `import ws` |
| **Kompilerat arkiv** | `target/ws.rgc` | Typkontrollerad mellanartefakt verifierad av `ridgunc` |
| **Delat ELF64-objekt** | `target/libws.so` | Inbyggt dynamiskt bibliotek helt utan C- eller `libc`-beroenden |

> För att använda denna lib i valfri `.rg`-fil deklarerar du bara `import ws` överst och anropar funktionerna med mellanslag eller understreck.

---

## 3. Snabbreferens för `ws`-API:et

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `ws accept key : String -> String` | Beräknar RFC 6455 §1.3 `Sec-WebSocket-Accept` från `Sec-WebSocket-Key` |
| `ws build upgrade request / ws build upgrade response` | Formaterar HTTP/1.1-meddelanden för WebSocket-uppgraderingshandskakning |
| `ws encode frame / ws decode frame` | Kodar och avkodar `WsFrame`-ramar (`fin`, `opcode`, `masked`, `mask_key`, `payload`) |
| `ws text frame / ws ping frame / ws pong frame / ws close frame` | Högnivåbyggare för ramar och extraherare för stängningskoder (`1000` normal stängning) |

---

## 4. Praktiska recept i tabellform

### Recept 1: Huvudflöde med `ws`

Lägg märke till hur `=`-tecknen och transformationsstegen linjeras som en ren tabell:

```ridgun
import ws

fn :: negociar y enviar (client_key : String) => (String, String)
      negociar y enviar client_key =
        resp  = ws build upgrade response client_key
        trama = ws encode frame (ws text frame "hola-tiempo-real" False "")
        (resp, trama)
```

### Recept 2: Säker komposition utan sidoeffekter

Varje funktion i lib:en `ws` kan kombineras fritt med övriga 32 libs i `ridgun-libs`:

```ridgun
import ws

fn :: decodificar trama cliente (clave4 : String) (msg : String) => String
      decodificar trama cliente clave4 msg =
        wire = ws encode frame (ws text frame msg True clave4)
        res  = ws decode frame wire
        ws frame payload res
```

---

## 5. Under huven: prestanda, RMM-minne och garantier

- **Algoritmisk garanti och säkerhet**: Exakt matchning med den officiella testvektorn i RFC 6455 (`"dGhlIHNhbXBsZSBub25jZQ=="` $\rightarrow$ `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="`) och automatisk XOR-avmaskering i `ws decode frame`.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test_ws.rg`.
