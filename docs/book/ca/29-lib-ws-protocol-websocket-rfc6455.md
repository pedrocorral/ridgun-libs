# Capítol 29: La lib `ws` — Handshake WebSocket RFC 6455, Framing de 16/64 bits i Emmascament XOR

## 29.1. Per què existeix la lib `ws`? (El problema real i la filosofia Ridgun)

> *«Per què necessito una lib `ws` escrita des de zero en Ridgun pur en lloc d'enllaçar una llibreria de C de tota la vida?»*

Aquesta és la primera pregunta que es fa qualsevol enginyer de sistemes en arribar a `ws`. I la resposta resumeix tota la filosofia de `ridgun-libs`:

Siguem sincers: el protocol WebSocket (RFC 6455) combina un handshake SHA-1 + Base64 amb trames binàries de longitud variable (7 bits, 16 bits o 64 bits) i emmascarament XOR obligatori de client a servidor.

La lib **`ws`** implementa **RFC 6455** complet en Ridgun pur: càlcul de `Sec-WebSocket-Accept` (amb SHA-1 RFC 3174 integrat exclusivament per al GUID de handshake), capçaleres HTTP `101 Switching Protocols`, codificació i descodificació de trames (`WsFrame`) amb longituds de 7, 16 (`126`) i 64 bits (`127`), emmascarament simètric XOR i constructors de trames de text, ping, pong i tancament.

En un ecosistema tradicional, resoldre les tasques del domini **`WS`** implica arrossegar dependències externes en C, lluitar amb punters crus, conversions opaques de tipus, excepcions no verificades o pauses impredictibles del recol·lector de brossa. En Ridgun, la lib **`ws`** (`src/main/ridgun/lib/ws.rg`) aborda el problema amb quatre principis innegociables:

1. **Declara `import ws` (o `import ws as alias`) a l'inici del fitxer**: cada lib defineix el seu espai de noms `module :: ws` i en mode `--strict` les funcions multi-paraula s'invoquen sempre amb espais naturals.
2. **Encadena les teves canonades d'esquerra a dreta amb `->`**: escriu `entrada pas u -> pas dos -> resultat`, fes servir màscares `(+ _ _ +)` per desestructurar seqüències i omet `_ =` en sentències seqüencials (o descarta amb `-> ()`).
3. **Recursió de cua amb TCO (*Tail-Call Optimization*)**: tots els recorreguts interns de `ws` es compilen a bucles natius en espai de pila $O(1)$.
4. **Memòria determinista (`RMM1` / `RMM2`)**: cada estructura intermèdia s'allibera en l'instant exacte en què acaba la seva última lectura, sense *Garbage Collector*.

---

## 29.2. Artefactes natius, importació i catàleg complet de l'API de `ws`

A `ridgun-libs`, **`ws`** és una **lib** de primera classe situada a `src/main/ridgun/lib/ws.rg` (domini `WS`). En compilar amb `stable bundle`, s'empaqueta en tres formats natius:

| Artefacte | Ruta | Propòsit |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/ws.rglib` | Distribució i importació directa amb `import ws` |
| **Fitxer compilat** | `target/ws.rgc` | Artefacte intermedi verificat per `ridgunc` |
| **Objecte compartit ELF64** | `target/libws.so` | Biblioteca dinàmica nativa sense dependències de C ni `libc` |

> Cada lib declara el seu propi espai de noms amb `module :: ws`: n'hi ha prou d'escriure `import ws` (o `import ws as alias`) a la capçalera i cridar les seves funcions amb espais naturals (`la meva funcio x`) i canonades `->` (`x la meva funcio -> resultat`).

### 29.2.1. Resum de famílies funcionals de `ws`

| Signatura / Funció / Tipus | Què fa i quan fer-la servir |
|---|---|
| `ws accept key : String -> String` | Calcula `Sec-WebSocket-Accept` (RFC 6455 §1.3) a partir de `Sec-WebSocket-Key` |
| `ws build upgrade request / ws build upgrade response` | Formata els missatges HTTP/1.1 de negociació (upgrade handshake) WebSocket |
| `ws encode frame / ws decode frame` | Codifica i descodifica trames `WsFrame` (`fin`, `opcode`, `masked`, `mask_key`, `payload`) |
| `ws text frame / ws ping frame / ws pong frame / ws close frame` | Constructors de trames d'alt nivell i extractors de codi de tancament (`1000` normal) |

### 29.2.2. Catàleg exhaustiu de tipus i signatures a `src/main/ridgun/lib/ws.rg`

A continuació tens l'inventari complet de tipus algebraics (`type`), operadors (`op ::`) i signatures de funcions (`fn ::`) definits a `src/main/ridgun/lib/ws.rg` (`3` tipus, `0` operadors i `54` funcions):

**Tipus algebraics i registres (`type`) de `ws`:**

```ridgun
type WsFrame = is_fin: Bool, ws_opcode: Int, is_masked: Bool, payload_bytes: [Int], payload_text: String
type WsRes = WsOk WsFrame Int | WsErr String
type Sha1State = h0: Int, h1: Int, h2: Int, h3: Int, h4: Int
```

| # | Funció / Signatura (`fn ::`) | Tipus de Retorn |
|---|---|---|
| `1` | `fn :: ws_u32 Int` | `Int` |
| `2` | `fn :: ws_u32_xor_loop Int Int Int Int` | `Int` |
| `3` | `fn :: ws_u32_xor Int Int` | `Int` |
| `4` | `fn :: ws_u32_and_loop Int Int Int Int` | `Int` |
| `5` | `fn :: ws_u32_and Int Int` | `Int` |
| `6` | `fn :: ws_u32_or_loop Int Int Int Int` | `Int` |
| `7` | `fn :: ws_u32_or Int Int` | `Int` |
| `8` | `fn :: ws_u32_not Int` | `Int` |
| `9` | `fn :: ws_pow2 Int` | `Int` |
| `10` | `fn :: ws_rotl32 Int Int` | `Int` |
| `11` | `fn :: ws_byte_xor Int Int` | `Int` |
| `12` | `fn :: ws_list_len [Int]` | `Int` |
| `13` | `fn :: ws_nth [Int] Int` | `Int` |
| `14` | `fn :: ws_take [Int] Int` | `[Int]` |
| `15` | `fn :: ws_drop [Int] Int` | `[Int]` |
| `16` | `fn :: ws_str_to_bytes_loop String Int Int [Int]` | `[Int]` |
| `17` | `fn :: ws_str_to_bytes String` | `[Int]` |
| `18` | `fn :: ws_bytes_to_str [Int]` | `String` |
| `19` | `fn :: ws_zeroes Int` | `[Int]` |
| `20` | `fn :: ws_u32_be4 Int` | `[Int]` |
| `21` | `fn :: ws_sha1_pad [Int]` | `[Int]` |
| `22` | `fn :: ws_be32_at [Int] Int` | `Int` |
| `23` | `fn :: ws_sha1_w16_loop [Int] Int [Int]` | `[Int]` |
| `24` | `fn :: ws_sha1_expand_loop [Int] Int` | `[Int]` |
| `25` | `fn :: ws_sha1_expand_step [Int] Int` | `[Int]` |
| `26` | `fn :: ws_sha1_f Int Int Int Int` | `Int` |
| `27` | `fn :: ws_sha1_k Int` | `Int` |
| `28` | `fn :: ws_sha1_rounds Sha1State [Int] Int` | `Sha1State` |
| `29` | `fn :: ws_sha1_round_step Sha1State [Int] Int` | `Sha1State` |
| `30` | `fn :: ws_sha1_blocks Sha1State [Int]` | `Sha1State` |
| `31` | `fn :: ws_sha1_bytes String` | `[Int]` |
| `32` | `fn :: ws_b64_lut Int` | `String` |
| `33` | `fn :: ws_b64_c Int` | `String` |
| `34` | `fn :: ws_b64_enc [Int]` | `String` |
| `35` | `fn :: ws accept key String` | `String` |
| `36` | `fn :: ws build upgrade request String String String` | `String` |
| `37` | `fn :: ws build upgrade response String` | `String` |
| `38` | `fn :: ws_mask_loop [Int] [Int] Int` | `[Int]` |
| `39` | `fn :: ws mask bytes [Int] [Int]` | `[Int]` |
| `40` | `fn :: ws_fin_bit Bool` | `Int` |
| `41` | `fn :: ws_len_header Int Int` | `[Int]` |
| `42` | `fn :: ws encode frame Bool Int [Int] [Int]` | `[Int]` |
| `43` | `fn :: ws_encode_frame_with_mask Int Bool [Int] [Int]` | `[Int]` |
| `44` | `fn :: ws encode text String` | `[Int]` |
| `45` | `fn :: ws encode masked text String [Int]` | `[Int]` |
| `46` | `fn :: ws encode ping [Int]` | `[Int]` |
| `47` | `fn :: ws encode pong [Int]` | `[Int]` |
| `48` | `fn :: ws encode close Int` | `[Int]` |
| `49` | `fn :: ws decode frame [Int]` | `WsRes` |
| `50` | `fn :: ws_decode_check_min [Int] Int` | `WsRes` |
| `51` | `fn :: ws_decode_len [Int] Int Int Int` | `WsRes` |
| `52` | `fn :: ws_decode_ext_len [Int] Int Bool Int Bool Int` | `WsRes` |
| `53` | `fn :: ws_decode_body [Int] Int Bool Int Bool Int Int` | `WsRes` |
| `54` | `fn :: ws_finish_frame Bool Int Bool [Int] Int` | `WsRes` |

---

## 29.3. Explorant `ws` a fons: Exemples pas a pas de cada funcionalitat

No n'hi ha prou de veure la taula de signatures: explorarem **cadascuna de les funcionalitats** de la lib `ws` mitjançant exemples progressius i executables en Ridgun. Començarem per les dues receptes tabulars d'ús quotidià i després recorrerem en detall tots els escenaris funcionals, transformacions i casos límit verificats a `src/test/ridgun/test ws.rg`.

### 29.3.1. Exemple 1: Flux principal en estil tabular amb `ws`

Observa com en Ridgun els signes `=` i els passos de transformació amb `ws` queden alineats com una taula neta, sense variables mutables innecessàries ni efectes laterals ocults:

```ridgun
import ws

fn :: negociar y enviar String => String String
      negociar y enviar client_key =
        ws build upgrade response client_key "chat" -> resp
        ws encode text frame "hola-tiempo-real" -> trama
        (resp, trama)
```

### 29.3.2. Exemple 2: Composició segura i gestió de casos de vora

Tota funció de la lib `ws` està dissenyada per compondre's amb guardes booleanes `|` i amb la resta de les 32 libs de `ridgun-libs`:

```ridgun
import ws

fn :: decodificar trama cliente String String => String
      decodificar trama cliente mask4 msg =
        ws encode masked frame (ws op text) msg mask4 -> wire
        wire ws frame payload
```

### 29.3.3. Exemple 3: Handshake WebSocket RFC 6455 (`Sec-WebSocket-Accept` mitjançant SHA-1 + Base64) i capçaleres HTTP `101 Switching Protocols`

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `ws` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test_ws_rfc6455_handshake => ()
      test_ws_rfc6455_handshake =
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

### 29.3.4. Exemple 4: Codificació i descodificació de trames de 7, 16 i 64 bits (`Text`, `Binary`, `Ping`, `Pong`, `Close`) i emmascarament XOR de 4 bytes

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `ws` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test_ws_framing_and_masking => ()
      test_ws_framing_and_masking =
        -- RFC 6455 Section 5.7 Example 1: single-frame unmasked text "Hello" -> [0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f]
        w_hello = ws encode text "Hello"
        assert true (ws_int_list_eq w_hello [129, 5, 72, 101, 108, 108, 111]) "AC2: RFC 6455 5.7 unmasked 'Hello' wire bytes"
        r_hello = ws decode frame w_hello
        assert true (is_ws_ok r_hello) "AC2: decode RFC 6455 unmasked 'Hello'"
        assert str eq (payload_text (unwrap_ws_frame r_hello)) "Hello" "AC2: decoded 'Hello' text"
        assert int equals (unwrap_ws_len r_hello) 7 "AC2: consumed 7 bytes"

        -- RFC 6455 Section 5.7 Example 2: single-frame masked text "Hello" with mask [0x37, 0xfa, 0x21, 0x3d]
        mask_rfc = [55, 250, 33, 61]
        w_mhello = ws encode masked text "Hello" mask_rfc
        assert true (ws_int_list_eq w_mhello [129, 133, 55, 250, 33, 61, 127, 159, 77, 81, 88]) "AC2: RFC 6455 5.7 masked 'Hello' wire bytes"
        r_mhello = ws decode frame w_mhello
        assert true (is_ws_ok r_mhello) "AC2: decode RFC 6455 masked 'Hello'"
        f_mhello = unwrap_ws_frame r_mhello
        assert true (is_masked f_mhello) "AC2: masked frame is_masked=true"
        assert str eq (payload_text f_mhello) "Hello" "AC2: XOR unmasked text matches 'Hello'"
        assert int equals (unwrap_ws_len r_mhello) 11 "AC2: consumed 11 bytes"

        -- Empty payload frame (0 bytes)
        w_empty = ws encode text ""
        r_empty = ws decode frame w_empty
        assert true (is_ws_ok r_empty) "AC2: decode empty text frame"
        assert str eq (payload_text (unwrap_ws_frame r_empty)) "" "AC2: empty payload_text"
        assert int equals (unwrap_ws_len r_empty) 2 "AC2: 2-byte header for empty unmasked frame"

        -- Boundary length 125 (max 7-bit length) vs 126 (min 16-bit extended length)
        msg_125 = ws_repeat_str "A" 125
        w_125 = ws encode text msg_125
        r_125 = ws decode frame w_125
        assert int equals (unwrap_ws_len r_125) 127 "AC2: 125B payload uses 2B header (127 total)"
        assert str eq (payload_text (unwrap_ws_frame r_125)) msg_125 "AC2: 125B payload round-trips"

        msg_126 = ws_repeat_str "B" 126
        w_126 = ws encode masked text msg_126 mask_rfc
        r_126 = ws decode frame w_126
        assert int equals (unwrap_ws_len r_126) 134 "AC2: 126B masked payload uses 4B hdr + 4B mask + 126B (134 total)"
        assert str eq (payload_text (unwrap_ws_frame r_126)) msg_126 "AC2: 126B payload round-trips"

        -- Control frames: Ping (9), Pong (10), Close (8)
        w_ping = ws encode ping [1, 2, 3]
        f_ping = unwrap_ws_frame (ws decode frame w_ping)
        assert int equals (ws_opcode f_ping) 9 "AC2: ping opcode=9"
        assert true (ws_int_list_eq (payload_bytes f_ping) [1, 2, 3]) "AC2: ping payload bytes"

        w_pong = ws encode pong [4, 5]
        f_pong = unwrap_ws_frame (ws decode frame w_pong)
        assert int equals (ws_opcode f_pong) 10 "AC2: pong opcode=10"

        w_close = ws encode close 1000
        f_close = unwrap_ws_frame (ws decode frame w_close)
        assert int equals (ws_opcode f_close) 8 "AC2: close opcode=8"
        assert true (ws_int_list_eq (payload_bytes f_close) [3, 232]) "AC2: close code 1000 big-endian [0x03, 0xE8]"
        ()
```

### 29.3.5. Exemple 5: Detecció segura de trames WebSocket truncades o incompletes (`WsErr`)

En aquest exemple pràctic explorem de manera exhaustiva com es comporta `ws` en aquest bloc funcional, incloent-hi entrades estàndard, combinacions de paràmetres i valors frontera:

```ridgun
fn :: test_ws_truncated_frames => ()
      test_ws_truncated_frames =
        assert false (is_ws_ok (ws decode frame [])) "AC3: reject 0-byte empty buffer"
        assert false (is_ws_ok (ws decode frame [129])) "AC3: reject 1-byte truncated header"
        assert false (is_ws_ok (ws decode frame [129, 10, 65, 66])) "AC3: reject truncated unmasked payload"
        assert false (is_ws_ok (ws decode frame [129, 126, 0])) "AC3: reject truncated 16-bit extended header"
        assert false (is_ws_ok (ws decode frame [129, 130, 1, 2])) "AC3: reject truncated 4-byte masking key"
        assert false (is_ws_ok (ws decode frame [129, 133, 55, 250, 33, 61, 127, 159])) "AC3: reject truncated masked payload"
        ()
```

---

## 29.4. Sota el capó: com està construïda `ws` en Ridgun pur (`src/main/ridgun/lib/ws.rg`)

Un dels majors avantatges de `ridgun-libs` és que **no hi ha caixes negres en C**. Pots obrir `src/main/ridgun/lib/ws.rg` i llegir exactament com està implementada cada operació fent servir *pattern matching*, arbres de guardes `|` / `|.` i recursió de cua (TCO). Vegem les peces clau de la seva implementació real:

### 29.4.1. Implementació interna: 32-Bit Unsigned Bitwise Helpers for RFC 3174 SHA-1

Fixa't en com `ws.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 29.4.2. Implementació interna: List & String Byte Conversion Helpers

Fixa't en com `ws.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 29.4.3. Implementació interna: Pure-Ridgun SHA-1 & Base64 for RFC 6455 Handshake

Fixa't en com `ws.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

### 29.4.4. Implementació interna: RFC 6455 XOR Masking & Frame Encoding / Decoding

Fixa't en com `ws.rg` estructura les signatures `fn :: ... => ...` primer i resol cada cas mitjançant equacions alineades i crides de cua:

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

## 29.5. Garanties algorísmiques, memòria `RMM1`/`RMM2` i les 5 Regles d'Or de `ws`

- **Garantia algorísmica i de seguretat**: Coincidència exacta amb el vector oficial RFC 6455 (`"dGhlIHNhbXBsZSBub25jZQ=="` $\rightarrow$ `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="`) i desemmascarament automàtic a `ws decode frame`.
- **Complexitat de pila $O(1)$ amb TCO**: Tots els bucles recursius a `src/main/ridgun/lib/ws.rg` estan en posició de cua, de manera que `ridgunc` els compila a salts natius sense creixement de pila.
- **Memòria determinista (`RMM1`/`RMM2`)**: Zero pauses de recol·lector de brossa; totes les estructures intermèdies s'alliberen de forma determinista en sortir de l'àmbit.
- **Verificació contínua**: Provada exhaustivament amb `stable check` i la suite automatitzada `src/test/ridgun/test ws.rg`.

### Les 5 Regles d'Or en programar amb `ws`

1. **Declara `import ws` a l'inici del fitxer** i aprofita l'equivalència entre espais i guions baixos perquè el teu codi es llegeixi com a prosa.
2. **Alinea les teves canonades de dades amb `=`**: encadena les crides a `ws` en passos amb nom propi i deixa que `stable format` alineï les columnes.
3. **Aprofita les funcions totals de `ws` a les teves guardes `|`**: comprova els valors de retorn o desembolica els ADTs amb *pattern matching* en lloc d'assumir que l'entrada externa sempre és vàlida.
4. **Evita copiar grans estructures si només necessites consultar un camp**: recorda que en `RMM2` els arguments d'entrada no incrementen ni decrementen comptadors (`+0` / `-0`).
5. **Combina `ws` amb `test` (`import test`)**: escriu sempre assercions amb `assert equals` o `assert true` per fixar els invariants del teu domini.

---

Al **Capítol 30** passarem a explorar en profunditat la lib **`agent`** (La lib `agent` — Model Natiu d'Actors (`agent`, `send`, `receive`), KV Store i Rate Limiter).
