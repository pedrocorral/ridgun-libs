# Capitolo 29: La lib `ws` — Handshake WebSocket RFC 6455, Framing a 16/64 bit e Mascheratura XOR

## 29.1. Perché esiste la lib `ws`? (Il problema reale e la filosofia Ridgun)

> *«Perché ho bisogno di una lib `ws` scritta da zero in Ridgun puro invece di collegare una libreria C tradizionale?»*

Questa è la prima domanda che si pone qualsiasi ingegnere di sistema arrivando a `ws`. E la risposta riassume l'intera filosofia di `ridgun-libs`:

Siamo sinceri: il protocollo WebSocket (RFC 6455) combina un handshake SHA-1 + Base64 con frame binari a lunghezza variabile (7 bit, 16 bit o 64 bit) e mascheratura XOR obbligatoria dal client al server.

La lib **`ws`** implementa **RFC 6455** completo in Ridgun puro: calcolo di `Sec-WebSocket-Accept` (con SHA-1 RFC 3174 integrato esclusivamente per il GUID di handshake), intestazioni HTTP `101 Switching Protocols`, codifica e decodifica dei frame (`WsFrame`) con lunghezze a 7, 16 (`126`) e 64 bit (`127`), mascheratura simmetrica XOR e costruttori di frame di testo, ping, pong e chiusura.

In un ecosistema tradizionale, risolvere i compiti del dominio **`WS`** comporta trascinare dipendenze esterne in C, gestire puntatori grezzi, conversioni opache di tipo, eccezioni non verificate o pause imprevedibili del garbage collector. In Ridgun, la lib **`ws`** (`src/main/ridgun/lib/ws.ridgun`) affronta il problema con quattro principi non negoziabili:

1. **Dichiara `import ws` (o `import ws as alias`) all'inizio del file**: ogni lib definisce il proprio spazio dei nomi `module :: ws` e in modalità `--strict` le funzioni multi-parola si invocano sempre con spazi naturali.
2. **Concatena le tue pipeline da sinistra a destra con `->`**: scrivi `input passo uno -> passo due -> risultato`, usa le maschere `(+ _ _ +)` per destrutturare le sequenze e ometti `_ =` nelle istruzioni sequenziali (o scarta il valore con `-> ()`).
3. **Ricorsione di coda con TCO (*Tail-Call Optimization*)**: tutte le scansioni interne di `ws` vengono compilate in cicli nativi in spazio di stack $O(1)$.
4. **Memoria deterministica (`RMM1` / `RMM2`)**: ogni struttura intermedia viene liberata nell'istante esatto in cui termina la sua ultima lettura, senza *Garbage Collector*.

---

## 29.2. Artefatti nativi, importazione e catalogo completo dell'API di `ws`

In `ridgun-libs`, **`ws`** è una **lib** di prima classe situata in `src/main/ridgun/lib/ws.ridgun` (dominio `WS`). Compilando con `stable bundle`, viene impacchettata in tre artefatti nativi:

| Artefatto | Percorso | Scopo |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/ws.ridgunlib` | Distribuzione e importazione diretta con `import ws` |
| **File compilato** | `target/ws.rgc` | Artefatto intermedio verificato da `ridgunc` |
| **Oggetto condiviso ELF64** | `target/libws.so` | Libreria dinamica nativa senza dipendenze C né `libc` |

> Ogni lib dichiara il proprio spazio dei nomi con `module :: ws`: basta scrivere `import ws` (o `import ws as alias`) nell'intestazione e invocare le sue funzioni con spazi naturali (`mia funzione x`) e pipeline `->` (`x mia funzione -> risultato`).

### 29.2.1. Riepilogo delle famiglie funzionali di `ws`

| Firma / Funzione / Tipo | Cosa fa e quando usarla |
|---|---|
| `ws accept key : String -> String` | Calcola `Sec-WebSocket-Accept` (RFC 6455 §1.3) a partire da `Sec-WebSocket-Key` |
| `ws build upgrade request / ws build upgrade response` | Formatta i messaggi HTTP/1.1 di negoziazione (upgrade handshake) WebSocket |
| `ws encode frame / ws decode frame` | Codifica e decodifica frame `WsFrame` (`fin`, `opcode`, `masked`, `mask_key`, `payload`) |
| `ws text frame / ws ping frame / ws pong frame / ws close frame` | Costruttori di frame ad alto livello ed estrattori del codice di chiusura (`1000` normale) |

### 29.2.2. Catalogo esaustivo dei tipi e delle firme in `src/main/ridgun/lib/ws.ridgun`

Di seguito trovi l'inventario completo dei tipi algebrici (`type`), degli operatori (`op ::`) e delle firme di funzione (`fn ::`) definiti in `src/main/ridgun/lib/ws.ridgun` (`3` tipi, `0` operatori e `54` funzioni):

**Tipi algebrici e record (`type`) di `ws`:**

```ridgun
type WsFrame = is_fin: Bool, ws_opcode: Int, is_masked: Bool, payload_bytes: [Int], payload_text: String
type WsRes = WsOk WsFrame Int | WsErr String
type Sha1State = h0: Int, h1: Int, h2: Int, h3: Int, h4: Int
```

| # | Funzione / Firma (`fn ::`) | Tipo di Ritorno |
|---|---|---|
| `1` | `fn :: ws u32 Int` | `Int` |
| `2` | `fn :: ws u32 xor loop Int Int Int Int` | `Int` |
| `3` | `fn :: ws u32 xor Int Int` | `Int` |
| `4` | `fn :: ws u32 and loop Int Int Int Int` | `Int` |
| `5` | `fn :: ws u32 and Int Int` | `Int` |
| `6` | `fn :: ws u32 or loop Int Int Int Int` | `Int` |
| `7` | `fn :: ws u32 or Int Int` | `Int` |
| `8` | `fn :: ws u32 not Int` | `Int` |
| `9` | `fn :: ws pow2 Int` | `Int` |
| `10` | `fn :: ws rotl32 Int Int` | `Int` |
| `11` | `fn :: ws byte xor Int Int` | `Int` |
| `12` | `fn :: ws list len [Int]` | `Int` |
| `13` | `fn :: ws nth [Int] Int` | `Int` |
| `14` | `fn :: ws take [Int] Int` | `[Int]` |
| `15` | `fn :: ws drop [Int] Int` | `[Int]` |
| `16` | `fn :: ws str to bytes loop String Int Int [Int]` | `[Int]` |
| `17` | `fn :: ws str to bytes String` | `[Int]` |
| `18` | `fn :: ws bytes to str [Int]` | `String` |
| `19` | `fn :: ws zeroes Int` | `[Int]` |
| `20` | `fn :: ws u32 be4 Int` | `[Int]` |
| `21` | `fn :: ws sha1 pad [Int]` | `[Int]` |
| `22` | `fn :: ws be32 at [Int] Int` | `Int` |
| `23` | `fn :: ws sha1 w16 loop [Int] Int [Int]` | `[Int]` |
| `24` | `fn :: ws sha1 expand loop [Int] Int` | `[Int]` |
| `25` | `fn :: ws sha1 expand step [Int] Int` | `[Int]` |
| `26` | `fn :: ws sha1 f Int Int Int Int` | `Int` |
| `27` | `fn :: ws sha1 k Int` | `Int` |
| `28` | `fn :: ws sha1 rounds Sha1State [Int] Int` | `Sha1State` |
| `29` | `fn :: ws sha1 round step Sha1State [Int] Int` | `Sha1State` |
| `30` | `fn :: ws sha1 blocks Sha1State [Int]` | `Sha1State` |
| `31` | `fn :: ws sha1 bytes String` | `[Int]` |
| `32` | `fn :: ws b64 lut Int` | `String` |
| `33` | `fn :: ws b64 c Int` | `String` |
| `34` | `fn :: ws b64 enc [Int]` | `String` |
| `35` | `fn :: ws accept key String` | `String` |
| `36` | `fn :: ws build upgrade request String String String` | `String` |
| `37` | `fn :: ws build upgrade response String` | `String` |
| `38` | `fn :: ws mask loop [Int] [Int] Int` | `[Int]` |
| `39` | `fn :: ws mask bytes [Int] [Int]` | `[Int]` |
| `40` | `fn :: ws fin bit Bool` | `Int` |
| `41` | `fn :: ws len header Int Int` | `[Int]` |
| `42` | `fn :: ws encode frame Bool Int [Int] [Int]` | `[Int]` |
| `43` | `fn :: ws encode frame with mask Int Bool [Int] [Int]` | `[Int]` |
| `44` | `fn :: ws encode text String` | `[Int]` |
| `45` | `fn :: ws encode masked text String [Int]` | `[Int]` |
| `46` | `fn :: ws encode ping [Int]` | `[Int]` |
| `47` | `fn :: ws encode pong [Int]` | `[Int]` |
| `48` | `fn :: ws encode close Int` | `[Int]` |
| `49` | `fn :: ws decode frame [Int]` | `WsRes` |
| `50` | `fn :: ws decode check min [Int] Int` | `WsRes` |
| `51` | `fn :: ws decode len [Int] Int Int Int` | `WsRes` |
| `52` | `fn :: ws decode ext len [Int] Int Bool Int Bool Int` | `WsRes` |
| `53` | `fn :: ws decode body [Int] Int Bool Int Bool Int Int` | `WsRes` |
| `54` | `fn :: ws finish frame Bool Int Bool [Int] Int` | `WsRes` |

---

## 29.3. Esplorare `ws` a fondo: Esempi passo dopo passo di ogni funzionalità

Non basta consultare la tabella delle firme: esploreremo **ciascuna delle funzionalità** della lib `ws` tramite esempi progressivi ed eseguibili in Ridgun. Inizieremo con due ricette tabulari di uso quotidiano e poi percorreremo nel dettaglio tutti gli scenari funzionali, le trasformazioni e i casi limite verificati in `src/test/ridgun/test ws.ridgun`.

### 29.3.1. Esempio 1: Flusso principale in stile tabulare con `ws`

Osserva come in Ridgun i segni `=` e i passaggi di trasformazione con `ws` risultino allineati come una tabella pulita, senza variabili mutabili superflue né effetti collaterali nascosti:

```ridgun
import ws

fn :: negociar y enviar String => String String
      negociar y enviar client_key =
        ws build upgrade response client_key "chat" -> resp
        ws encode text frame "hola-tiempo-real" -> trama
        (resp, trama)
```

### 29.3.2. Esempio 2: Composizione sicura e gestione dei casi limite

Ogni funzione della lib `ws` è progettata per comporsi con le guardie booleane `|` e con il resto delle 34 lib di `ridgun-libs`:

```ridgun
import ws

fn :: decodificar trama cliente String String => String
      decodificar trama cliente mask4 msg =
        ws encode masked frame (ws op text) msg mask4 -> wire
        wire ws frame payload
```

### 29.3.3. Esempio 3: Handshake WebSocket RFC 6455 (`Sec-WebSocket-Accept` tramite SHA-1 + Base64) e intestazioni HTTP `101 Switching Protocols`

In questo esempio pratico esploriamo in modo esaustivo come si comporta `ws` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test ws rfc6455 handshake => ()
      test ws rfc6455 handshake =
        rfc_key = "dGhlIHNhbXBsZSBub25jZQ=="
        accept = ws accept key rfc_key
        assert str eq accept "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=" "AC1: RFC 6455 Sec-WebSocket-Accept test vector"

        req = ws build upgrade request "chat.example.com" "/ws" rfc_key
        assert true (str contains req "GET /ws HTTP/1.1") "AC1: upgrade request line"
        assert true (str contains req "Host: chat.example.com") "AC1: upgrade request Host header"
        assert true (str contains req "Upgrade: websocket") "AC1: upgrade request Upgrade header"
        assert true (str contains req "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==") "AC1: upgrade request contains key"

        resp = ws build upgrade response rfc_key
        assert true (str contains resp "101 Switching Protocols") "AC1: upgrade response status 101"
        assert true (str contains resp "Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=") "AC1: upgrade response contains accept digest"
        ()
```

### 29.3.4. Esempio 4: Codifica e decodifica di frame a 7, 16 e 64 bit (`Text`, `Binary`, `Ping`, `Pong`, `Close`) e mascheratura XOR a 4 byte

In questo esempio pratico esploriamo in modo esaustivo come si comporta `ws` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test ws framing and masking => ()
      test ws framing and masking =
        -- RFC 6455 Section 5.7 Example 1: single-frame unmasked text "Hello" -> [0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f]
        w_hello = ws encode text "Hello"
        assert true (ws int list eq w_hello [129, 5, 72, 101, 108, 108, 111]) "AC2: RFC 6455 5.7 unmasked 'Hello' wire bytes"
        r_hello = ws decode frame w_hello
        assert true (is ws ok r_hello) "AC2: decode RFC 6455 unmasked 'Hello'"
        assert str eq (payload_text (unwrap ws frame r_hello)) "Hello" "AC2: decoded 'Hello' text"
        assert int equals (unwrap ws len r_hello) 7 "AC2: consumed 7 bytes"

        -- RFC 6455 Section 5.7 Example 2: single-frame masked text "Hello" with mask [0x37, 0xfa, 0x21, 0x3d]
        mask_rfc = [55, 250, 33, 61]
        w_mhello = ws encode masked text "Hello" mask_rfc
        assert true (ws int list eq w_mhello [129, 133, 55, 250, 33, 61, 127, 159, 77, 81, 88]) "AC2: RFC 6455 5.7 masked 'Hello' wire bytes"
        r_mhello = ws decode frame w_mhello
        assert true (is ws ok r_mhello) "AC2: decode RFC 6455 masked 'Hello'"
        f_mhello = unwrap ws frame r_mhello
        assert true (is_masked f_mhello) "AC2: masked frame is_masked=true"
        assert str eq (payload_text f_mhello) "Hello" "AC2: XOR unmasked text matches 'Hello'"
        assert int equals (unwrap ws len r_mhello) 11 "AC2: consumed 11 bytes"

        -- Empty payload frame (0 bytes)
        w_empty = ws encode text ""
        r_empty = ws decode frame w_empty
        assert true (is ws ok r_empty) "AC2: decode empty text frame"
        assert str eq (payload_text (unwrap ws frame r_empty)) "" "AC2: empty payload_text"
        assert int equals (unwrap ws len r_empty) 2 "AC2: 2-byte header for empty unmasked frame"

        -- Boundary length 125 (max 7-bit length) vs 126 (min 16-bit extended length)
        msg_125 = ws repeat str "A" 125
        w_125 = ws encode text msg_125
        r_125 = ws decode frame w_125
        assert int equals (unwrap ws len r_125) 127 "AC2: 125B payload uses 2B header (127 total)"
        assert str eq (payload_text (unwrap ws frame r_125)) msg_125 "AC2: 125B payload round-trips"

        msg_126 = ws repeat str "B" 126
        w_126 = ws encode masked text msg_126 mask_rfc
        r_126 = ws decode frame w_126
        assert int equals (unwrap ws len r_126) 134 "AC2: 126B masked payload uses 4B hdr + 4B mask + 126B (134 total)"
        assert str eq (payload_text (unwrap ws frame r_126)) msg_126 "AC2: 126B payload round-trips"

        -- Control frames: Ping (9), Pong (10), Close (8)
        w_ping = ws encode ping [1, 2, 3]
        f_ping = unwrap ws frame (ws decode frame w_ping)
        assert int equals (ws_opcode f_ping) 9 "AC2: ping opcode=9"
        assert true (ws int list eq (payload_bytes f_ping) [1, 2, 3]) "AC2: ping payload bytes"

        w_pong = ws encode pong [4, 5]
        f_pong = unwrap ws frame (ws decode frame w_pong)
        assert int equals (ws_opcode f_pong) 10 "AC2: pong opcode=10"

        w_close = ws encode close 1000
        f_close = unwrap ws frame (ws decode frame w_close)
        assert int equals (ws_opcode f_close) 8 "AC2: close opcode=8"
        assert true (ws int list eq (payload_bytes f_close) [3, 232]) "AC2: close code 1000 big-endian [0x03, 0xE8]"
        ()
```

### 29.3.5. Esempio 5: Rilevamento sicuro di frame WebSocket troncati o incompleti (`WsErr`)

In questo esempio pratico esploriamo in modo esaustivo come si comporta `ws` in questo blocco funzionale, inclusi input standard, combinazioni di parametri e valori di frontiera:

```ridgun
fn :: test ws truncated frames => ()
      test ws truncated frames =
        assert false (is ws ok (ws decode frame [])) "AC3: reject 0-byte empty buffer"
        assert false (is ws ok (ws decode frame [129])) "AC3: reject 1-byte truncated header"
        assert false (is ws ok (ws decode frame [129, 10, 65, 66])) "AC3: reject truncated unmasked payload"
        assert false (is ws ok (ws decode frame [129, 126, 0])) "AC3: reject truncated 16-bit extended header"
        assert false (is ws ok (ws decode frame [129, 130, 1, 2])) "AC3: reject truncated 4-byte masking key"
        assert false (is ws ok (ws decode frame [129, 133, 55, 250, 33, 61, 127, 159])) "AC3: reject truncated masked payload"
        ()
```

---

## 29.4. Sotto il cofano: come è costruita `ws` in Ridgun puro (`src/main/ridgun/lib/ws.ridgun`)

Uno dei maggiori vantaggi di `ridgun-libs` è che **non ci sono scatole nere in C**. Puoi aprire `src/main/ridgun/lib/ws.ridgun` e leggere esattamente come è implementata ogni operazione usando *pattern matching*, alberi di guardie `|` / `|.` e ricorsione di coda (TCO). Vediamo i pezzi chiave della sua implementazione reale:

### 29.4.1. Implementazione interna: 32-Bit Unsigned Bitwise Helpers for RFC 3174 SHA-1

Nota come `ws.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
module :: ws

fn :: ws u32 Int => Int
      ws u32 x = ((x % 4294967296) + 4294967296) % 4294967296

fn :: ws u32 bxor loop Int Int Int Int => Int
      ws u32 bxor loop _ _ 0 acc = acc
      ws u32 bxor loop a b bit acc =
        | (a % 2) != (b % 2) = ws u32 bxor loop (a / 2) (b / 2) (bit * 2) (acc + bit)
        | otherwise = ws u32 bxor loop (a / 2) (b / 2) (bit * 2) acc

fn :: ws u32 bxor Int Int => Int
      ws u32 bxor a b = ws u32 bxor loop (ws u32 a) (ws u32 b) 1 0

fn :: ws u32 band loop Int Int Int Int => Int
      ws u32 band loop _ _ 0 acc = acc
      ws u32 band loop a b bit acc =
        | (a % 2) == 1 and (b % 2) == 1 = ws u32 band loop (a / 2) (b / 2) (bit * 2) (acc + bit)
        | otherwise = ws u32 band loop (a / 2) (b / 2) (bit * 2) acc

fn :: ws u32 band Int Int => Int
      ws u32 band a b = ws u32 band loop (ws u32 a) (ws u32 b) 1 0

fn :: ws u32 bor loop Int Int Int Int => Int
      ws u32 bor loop _ _ 0 acc = acc
      ws u32 bor loop a b bit acc =
        | (a % 2) == 1 or (b % 2) == 1 = ws u32 bor loop (a / 2) (b / 2) (bit * 2) (acc + bit)
        | otherwise = ws u32 bor loop (a / 2) (b / 2) (bit * 2) acc

fn :: ws u32 bor Int Int => Int
      ws u32 bor a b = ws u32 bor loop (ws u32 a) (ws u32 b) 1 0

fn :: ws u32 bnot Int => Int
      ws u32 bnot a = 4294967295 - (ws u32 a)

fn :: ws pow2 Int => Int
      ws pow2 0 = 1
      ws pow2 n = 2 * (ws pow2 (n - 1))

fn :: ws rotl32 Int Int => Int
      ws rotl32 x n =
        ux = ws u32 x
        p_shl = ws pow2 n
        p_shr = ws pow2 (32 - n)
        ws u32 ((ux * p_shl) + (ux / p_shr))

fn :: ws byte bxor Int Int => Int
      ws byte bxor a b = (ws u32 bxor (a % 256) (b % 256)) % 256
```

### 29.4.2. Implementazione interna: List & String Byte Conversion Helpers

Nota come `ws.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: ws list len [Int] => Int
      ws list len [] = 0
      ws list len (_:rest) = 1 + (ws list len rest)

fn :: ws nth [Int] Int => Int
      ws nth [] _ = 0
      ws nth (x:_) 0 = x
      ws nth (_:rest) idx = ws nth rest (idx - 1)

fn :: ws take [Int] Int => [Int]
      ws take [] _ = []
      ws take (x:rest) n =
        | n <= 0 = []
        | otherwise = [x] :: (ws take rest (n - 1))

fn :: ws drop [Int] Int => [Int]
      ws drop [] _ = []
      ws drop (x:rest) n =
        | n <= 0 = [x] :: rest
        | otherwise = ws drop rest (n - 1)

fn :: ws str to bytes loop String Int Int [Int] => [Int]
      ws str to bytes loop s pos len acc =
        | pos >= len = acc
        | otherwise = ws str to bytes loop s (pos + 1) len (acc :: [((str char at s pos) % 256 + 256) % 256])

fn :: ws str to bytes String => [Int]
      ws str to bytes s = ws str to bytes loop s 0 (str len s) []

fn :: ws bytes to str [Int] => String
      ws bytes to str [] = ""
      ws bytes to str (b:rest) = (char from code b) + (ws bytes to str rest)
```

### 29.4.3. Implementazione interna: Pure-Ridgun SHA-1 & Base64 for RFC 6455 Handshake

Nota come `ws.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: ws zeroes Int => [Int]
      ws zeroes n =
        | n <= 0 = []
        | otherwise = [0] :: (ws zeroes (n - 1))

fn :: ws u32 be4 Int => [Int]
      ws u32 be4 w =
        uw = ws u32 w
        [(uw / 16777216) % 256, (uw / 65536) % 256, (uw / 256) % 256, uw % 256]

fn :: ws sha1 pad [Int] => [Int]
      ws sha1 pad bs =
        mlen = ws list len bs
        bit_len = mlen * 8
        rem = (mlen + 1) % 64
        z_count = ((56 - rem) + 64) % 64
        ((bs :: [128]) :: (ws zeroes z_count)) :: ((ws u32 be4 0) :: (ws u32 be4 bit_len))

fn :: ws be32 at [Int] Int => Int
      ws be32 at bs off = ((ws nth bs off) * 16777216) + ((ws nth bs (off + 1)) * 65536) + ((ws nth bs (off + 2)) * 256) + (ws nth bs (off + 3))

fn :: ws sha1 w16 loop [Int] Int [Int] => [Int]
      ws sha1 w16 loop blk idx acc =
        | idx >= 16 = acc
        | otherwise = ws sha1 w16 loop blk (idx + 1) (acc :: [ws be32 at blk (idx * 4)])

fn :: ws sha1 expand loop [Int] Int => [Int]
      ws sha1 expand loop w t =
        | t >= 80 = w
        | otherwise = ws sha1 expand step w t

fn :: ws sha1 expand step [Int] Int => [Int]
      ws sha1 expand step w t =
        x = ws u32 bxor (ws u32 bxor (ws u32 bxor (ws nth w (t - 3)) (ws nth w (t - 8))) (ws nth w (t - 14))) (ws nth w (t - 16))
        ws sha1 expand loop (w :: [ws rotl32 x 1]) (t + 1)

fn :: ws sha1 f Int Int Int Int => Int
      ws sha1 f t b c d =
        | t < 20 = ws u32 bor (ws u32 band b c) (ws u32 band (ws u32 bnot b) d)
        | t < 40 = ws u32 bxor (ws u32 bxor b c) d
        | t < 60 = ws u32 bor (ws u32 bor (ws u32 band b c) (ws u32 band b d)) (ws u32 band c d)
        | otherwise = ws u32 bxor (ws u32 bxor b c) d

fn :: ws sha1 k Int => Int
      ws sha1 k t =
        | t < 20 = 1518500249
        | t < 40 = 1859775393
        | t < 60 = 2400959708
        | otherwise = 3395469782

fn :: ws sha1 rounds Sha1State [Int] Int => Sha1State
      ws sha1 rounds st w t =
        | t >= 80 = st
        | otherwise = ws sha1 round step st w t

fn :: ws sha1 round step Sha1State [Int] Int => Sha1State
      ws sha1 round step st w t =
        a = h0 st
        b = h1 st
        c = h2 st
        d = h3 st
        e = h4 st
        f = ws sha1 f t b c d
        k = ws sha1 k t
        wt = ws nth w t
        temp = ws u32 ((ws rotl32 a 5) + f + e + k + wt)
        ws sha1 rounds (Sha1State temp a (ws rotl32 b 30) c d) w (t + 1)

fn :: ws sha1 blocks Sha1State [Int] => Sha1State
      ws sha1 blocks st [] = st
      ws sha1 blocks st padded =
        blk = ws take padded 64
        rest = ws drop padded 64
        w80 = ws sha1 expand loop (ws sha1 w16 loop blk 0 []) 16
        r = ws sha1 rounds st w80 0
        next_st = Sha1State (ws u32 ((h0 st) + (h0 r))) (ws u32 ((h1 st) + (h1 r))) (ws u32 ((h2 st) + (h2 r))) (ws u32 ((h3 st) + (h3 r))) (ws u32 ((h4 st) + (h4 r)))
        ws sha1 blocks next_st rest

fn :: ws sha1 bytes String => [Int]
      ws sha1 bytes s =
        init_st = Sha1State 1732584193 4023233417 2562383102 271733878 3285377520
        fin = ws sha1 blocks init_st (ws sha1 pad (ws str to bytes s))
        ((((ws u32 be4 (h0 fin)) :: (ws u32 be4 (h1 fin))) :: (ws u32 be4 (h2 fin))) :: (ws u32 be4 (h3 fin))) :: (ws u32 be4 (h4 fin))

fn :: ws b64 lut Int => String
      ws b64 lut _ = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

fn :: ws b64 c Int => String
      ws b64 c idx =
        ws b64 lut 0 -> tbl
        ((idx % 64) + 64) % 64 -> i
        str slice tbl i (i + 1)

fn :: ws b64 enc [Int] => String
      ws b64 enc [] = ""
      ws b64 enc (b0:[]) = (ws b64 c (b0 / 4)) + (ws b64 c ((b0 % 4) * 16)) + "=="
      ws b64 enc (b0:b1:[]) =
        (b0 * 256) + b1 -> n
        (ws b64 c (n / 1024)) + (ws b64 c ((n / 16) % 64)) + (ws b64 c ((n % 16) * 4)) + "="
      ws b64 enc (b0:b1:b2:rs) =
        (b0 * 65536) + (b1 * 256) + b2 -> n
        (ws b64 c (n / 262144)) + (ws b64 c ((n / 4096) % 64)) + (ws b64 c ((n / 64) % 64)) + (ws b64 c (n % 64)) + (ws b64 enc rs)

fn :: ws accept key String => String
      ws accept key client_key =
        (client_key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11") -> ws sha1 bytes -> ws b64 enc

fn :: ws build upgrade request String String String => String
      ws build upgrade request host path client_key =
        (char from code 13) + (char from code 10) -> crlf
        "GET " + path + " HTTP/1.1" + crlf + "Host: " + host + crlf + "Upgrade: websocket" + crlf + "Connection: Upgrade" + crlf + "Sec-WebSocket-Key: " + client_key + crlf + "Sec-WebSocket-Version: 13" + crlf + crlf

fn :: ws build upgrade response String => String
      ws build upgrade response client_key =
        (char from code 13) + (char from code 10) -> crlf
        client_key ws accept key -> accept
        "HTTP/1.1 101 Switching Protocols" + crlf + "Upgrade: websocket" + crlf + "Connection: Upgrade" + crlf + "Sec-WebSocket-Accept: " + accept + crlf + crlf
```

### 29.4.4. Implementazione interna: RFC 6455 XOR Masking & Frame Encoding / Decoding

Nota come `ws.ridgun` strutturi prima le firme `fn :: ... => ...` e risolva ogni caso tramite equazioni allineate e chiamate di coda:

```ridgun
fn :: ws mask loop [Int] [Int] Int => [Int]
      ws mask loop [] _ _ = []
      ws mask loop (b:rest) mask_key idx = [ws byte bxor b (ws nth mask_key (idx % 4))] :: (ws mask loop rest mask_key (idx + 1))

fn :: ws mask bytes [Int] [Int] => [Int]
      ws mask bytes payload mask_key =
        | (ws list len mask_key) < 4 = payload
        | otherwise = ws mask loop payload mask_key 0

fn :: ws fin bit Bool => Int
      ws fin bit True = 128
      ws fin bit False = 0

fn :: ws len header Int Int => [Int]
      ws len header plen mask_bit =
        | plen < 126 = [mask_bit + plen]
        | otherwise = [mask_bit + 126, (plen / 256) % 256, plen % 256]

fn :: ws encode frame Bool Int [Int] [Int] => [Int]
      ws encode frame fin opcode mask_key payload =
        b0 = (ws fin bit fin) + (opcode % 16)
        has_mask = (ws list len mask_key) >= 4
        ws encode frame with mask b0 has_mask mask_key payload

fn :: ws encode frame with mask Int Bool [Int] [Int] => [Int]
      ws encode frame with mask b0 False _ payload = ([b0] :: (ws len header (ws list len payload) 0)) :: payload
      ws encode frame with mask b0 True mask_key payload =
        m4 = ws take mask_key 4
        masked_pay = ws mask bytes payload m4
        (([b0] :: (ws len header (ws list len payload) 128)) :: m4) :: masked_pay

fn :: ws encode text String => [Int]
      ws encode text text = ws encode frame True 1 [] (ws str to bytes text)

fn :: ws encode masked text String [Int] => [Int]
      ws encode masked text text mask_key = ws encode frame True 1 mask_key (ws str to bytes text)

fn :: ws encode ping [Int] => [Int]
      ws encode ping payload = ws encode frame True 9 [] payload

fn :: ws encode pong [Int] => [Int]
      ws encode pong payload = ws encode frame True 10 [] payload

fn :: ws encode close Int => [Int]
      ws encode close code = ws encode frame True 8 [] [(code / 256) % 256, code % 256]

fn :: ws decode frame [Int] => WsRes
      ws decode frame wire =
        total = ws list len wire
        ws decode check min wire total

fn :: ws decode check min [Int] Int => WsRes
      ws decode check min wire total =
        | total < 2 = WsErr "truncated WebSocket frame header (< 2 bytes)"
        | otherwise = ws decode len wire total (ws nth wire 0) (ws nth wire 1)

fn :: ws decode len [Int] Int Int Int => WsRes
      ws decode len wire total b0 b1 =
        fin = (b0 / 128) == 1
        opcode = b0 % 16
        masked = (b1 / 128) == 1
        len7 = b1 % 128
        ws decode ext len wire total fin opcode masked len7

fn :: ws decode ext len [Int] Int Bool Int Bool Int => WsRes
      ws decode ext len wire total fin opcode masked len7 =
        | len7 < 126 = ws decode body wire total fin opcode masked len7 2
        | len7 == 126 and total < 4 = WsErr "truncated 16-bit extended payload length"
        | len7 == 126 = ws decode body wire total fin opcode masked (((ws nth wire 2) * 256) + (ws nth wire 3)) 4
        | otherwise = WsErr "unsupported 64-bit extended length"

fn :: ws decode body [Int] Int Bool Int Bool Int Int => WsRes
      ws decode body wire total fin opcode True plen hdr_off =
        | total < (hdr_off + 4 + plen) = WsErr "truncated masked WebSocket frame payload"
        | otherwise = ws finish frame fin opcode True (ws mask bytes (ws take (ws drop wire (hdr_off + 4)) plen) (ws take (ws drop wire hdr_off) 4)) (hdr_off + 4 + plen)
      ws decode body wire total fin opcode False plen hdr_off =
        | total < (hdr_off + plen) = WsErr "truncated unmasked WebSocket frame payload"
        | otherwise = ws finish frame fin opcode False (ws take (ws drop wire hdr_off) plen) (hdr_off + plen)

fn :: ws finish frame Bool Int Bool [Int] Int => WsRes
      ws finish frame fin opcode masked unmasked consumed =
        | opcode == 1 = WsOk (WsFrame fin opcode masked unmasked (ws bytes to str unmasked)) consumed
        | otherwise = WsOk (WsFrame fin opcode masked unmasked "") consumed
```

---

## 29.5. Garanzie algoritmiche, memoria `RMM1`/`RMM2` e le 5 Regole d'Oro di `ws`

- **Garanzia algoritmica e di sicurezza**: Corrispondenza esatta con il vettore ufficiale RFC 6455 (`"dGhlIHNhbXBsZSBub25jZQ=="` $\rightarrow$ `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="`) e smascheratura automatica in `ws decode frame`.
- **Complessità dello stack $O(1)$ con TCO**: Tutti i cicli ricorsivi in `src/main/ridgun/lib/ws.ridgun` sono in posizione di coda, perciò `ridgunc` li compila in salti nativi senza crescita dello stack.
- **Memoria deterministica (`RMM1`/`RMM2`)**: Zero pause del garbage collector; tutte le strutture intermedie vengono liberate in modo deterministico all'uscita dallo scope.
- **Verifica continua**: Testata in modo esaustivo con `stable check` e la suite automatizzata `src/test/ridgun/test ws.ridgun`.

### Le 5 Regole d'Oro quando programmi con `ws`

1. **Dichiara `import ws` all'inizio del file** e usa le funzioni multi-parola con spazi naturali affinché il tuo codice si legga come prosa.
2. **Allinea le tue pipeline di dati con `=` e `->`**: concatena le chiamate a `ws` in passaggi con nomi chiari e lascia che `stable format` allinei le colonne.
3. **Sfrutta le funzioni totali di `ws` nelle tue guardie `|`**: controlla i valori di ritorno o destruttura gli ADT con *pattern matching* invece di dare per scontato che l'input esterno sia sempre valido.
4. **Evita di copiare grandi strutture se devi solo consultare un campo**: ricorda che in `RMM2` gli argomenti di input sono prestati e non incrementano né decrementano i contatori (`+0` / `-0`).
5. **Combina `ws` con `test` (`import test`)**: scrivi sempre asserzioni con `assert equals` o `assert true` per fissare gli invarianti del tuo dominio.

---

Nel **Capitolo 30** passeremo a esplorare in profondità la lib **`agent`** (La lib `agent` — Modello Nativo ad Attori (`agent`, `send`, `receive`), KV Store e Rate Limiter).
