# 29. kapitulua: `ws` lib-a — RFC 6455 WebSocket Handshakea, 16/64 biteko Framinga eta XOR Maskaratzea

## 1. Zergatik existitzen da `ws` lib-a?

Izan gaitezen zintzoak: WebSocket protokoloak (RFC 6455) SHA-1 + Base64 handshake bat luzera aldakorreko trama bitarrekin (7 bit, 16 bit edo 64 bit) eta bezerotik zerbitzarirako nahitaezko XOR maskaratzearekin uztartzen du.

**`ws`** lib-ak **RFC 6455** osoa inplementatzen du Ridgun hutsean: `Sec-WebSocket-Accept` kalkulua (handshake GUIDerako soilik integratutako RFC 3174 SHA-1-ekin), `101 Switching Protocols` HTTP goiburuak, 7, 16 (`126`) eta 64 biteko (`127`) luzeradun tramen (`WsFrame`) kodetzea/deskodetzea, XOR maskaratze simetrikoa eta testu, ping, pong zein itxiera tramen eraikitzaileak.

---

## 2. Artefaktuak, inportazioa eta `libc` gabeko arkitektura

`ridgun-libs`-en, **`ws`** lehen mailako **lib** bat da, `src/main/ridgun/lib/ws.rg` bidean kokatua (`WS` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/ws.rglib` | Banaketa eta inportazio zuzena `import ws` bidez |
| **Fitxategi konpilatua** | `target/ws.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libws.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import ws` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

---

## 3. `ws` APIaren erreferentzia azkarra

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `ws accept key : String -> String` | `Sec-WebSocket-Key`-tik abiatuta RFC 6455 §1.3 `Sec-WebSocket-Accept` kalkulatzen du |
| `ws build upgrade request / ws build upgrade response` | WebSocket HTTP/1.1 upgrade handshake mezuak formateatzen ditu |
| `ws encode frame / ws decode frame` | `WsFrame` tramak (`fin`, `opcode`, `masked`, `mask_key`, `payload`) kodetu eta deskodetzen ditu |
| `ws text frame / ws ping frame / ws pong frame / ws close frame` | Goi-mailako tramen eraikitzaileak eta itxiera-kodeen erauzleak (`1000` itxiera normala) |

---

## 4. Errezeta praktikoak estilo taularatuan

### 1. errezeta: Fluxu nagusia `ws` erabiliz

Ikusi nola `=` ikurrak eta eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren:

```ridgun
import ws

fn :: negociar y enviar (client_key : String) => (String, String)
      negociar y enviar client_key =
        resp  = ws build upgrade response client_key
        trama = ws encode frame (ws text frame "hola-tiempo-real" False "")
        (resp, trama)
```

### 2. errezeta: Konposizio segurua eta albo-ondoriorik gabea

`ws` lib-eko funtzio oro `ridgun-libs`-eko gainerako 32 lib-ekin konposa daiteke:

```ridgun
import ws

fn :: decodificar trama cliente (clave4 : String) (msg : String) => String
      decodificar trama cliente clave4 msg =
        wire = ws encode frame (ws text frame msg True clave4)
        res  = ws decode frame wire
        ws frame payload res
```

---

## 5. Kaputaren azpian: errendimendua, RMM memoria eta bermeak

- **Berme algoritmikoa eta segurtasunekoa**: Bat-etortze zehatza RFC 6455 bektore ofizialarekin (`"dGhlIHNhbXBsZSBub25jZQ=="` $\rightarrow$ `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="`) eta maskara-kentze automatikoa `ws decode frame`-n.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test_ws.rg` suite automatizatuaren bidez.
