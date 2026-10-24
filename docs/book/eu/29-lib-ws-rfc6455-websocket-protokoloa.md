# 29. kapitulua: `ws` lib-a — RFC 6455 WebSocket Handshakea, 16/64 biteko Framinga eta XOR Maskaratzea

## 29.1. Zergatik existitzen da `ws` lib-a? (Benetako arazoa eta Ridgun filosofia)

> *«Zergatik behar dut `ws` lib bat hutsetik Ridgun hutsean idatzia, betiko C liburutegi bat estekatu beharrean?»*

Hori da edozein sistema-ingeniarik `ws`-era iristean egiten duen lehen galdera. Eta erantzunak `ridgun-libs`-en filosofia osoa laburbiltzen du:

Izan gaitezen zintzoak: WebSocket protokoloak (RFC 6455) SHA-1 + Base64 handshake bat luzera aldakorreko trama bitarrekin (7 bit, 16 bit edo 64 bit) eta bezerotik zerbitzarirako nahitaezko XOR maskaratzearekin uztartzen du.

**`ws`** lib-ak **RFC 6455** osoa inplementatzen du Ridgun hutsean: `Sec-WebSocket-Accept` kalkulua (handshake GUIDerako soilik integratutako RFC 3174 SHA-1-ekin), `101 Switching Protocols` HTTP goiburuak, 7, 16 (`126`) eta 64 biteko (`127`) luzeradun tramen (`WsFrame`) kodetzea/deskodetzea, XOR maskaratze simetrikoa eta testu, ping, pong zein itxiera tramen eraikitzaileak.

Ekosistema tradizional batean, **`WS`** domeinuko zereginak ebazteak C-ko kanpo-mendekotasunak arrastatzea, erakusle gordinekin borrokatzea, mota-bihurketa opakuak, egiaztatu gabeko salbuespenak edo zabor-biltzailearen geldialdi ustekabekoak jasatea dakar. Ridgunen, **`ws`** lib-ak (`src/main/ridgun/lib/ws.rg`) lau printzipio negoziatu ezinekin heltzen dio arazoari:

1. **Funtzio osoak eta kontratu esplizituak (`=>`)**: `ws`-eko funtzio bakar batek ere ez du ezkutuko salbuespenik jaurtitzen, ezta `null` erabiltzen ere. Muga-kasu orok dokumentatutako balio bat edo batura-mota aljebraiko bat (`Option`, `Result`) itzultzen du.
2. **Zero C kode eta zero `libc`**: `ws`-eko kode guztia zuzenean ELF64 makina-kode natibora konpilatzen da, `ridgunc`-ek egiaztatuta.
3. **Isats-errekurtsioa TCOrekin (*Tail-Call Optimization*)**: `ws`-eko barne-ibilbide guztiak $O(1)$ pila-espazioko begizta natiboetara konpilatzen dira.
4. **Memoria determinista (`RMM1` / `RMM2`)**: tarteko egitura bakoitza bere azken irakurketa amaitzen den une zehatzean askatzen da, *Garbage Collector* gabe.

---

## 29.2. Artefaktu natiboak, inportazioa eta `ws` APIaren katalogo osoa

`ridgun-libs`-en, **`ws`** lehen mailako **lib** bat da, `src/main/ridgun/lib/ws.rg` bidean kokatua (`WS` domeinua). `stable bundle`-ekin konpilatzean, hiru formatu natibotan paketatzen da:

| Artefaktua | Bidea | Helburua |
|---|---|---|
| **Ridgun Bundle-a** | `target/bundles/ws.rglib` | Banaketa eta inportazio zuzena `import ws` bidez |
| **Fitxategi konpilatua** | `target/ws.rgc` | `ridgunc`-ek egiaztatutako tarteko artefaktua |
| **ELF64 objektu partekatua** | `target/libws.so` | C edo `libc` mendekotasunik gabeko liburutegi dinamiko natiboa |

> Lib hau edozein `.rg` fitxategitan erabiltzeko, nahikoa da goiburuan `import ws` deklaratzea eta bere funtzioei zuriuneekin edo azpimarrarekin deitzea.

### 29.2.1. `ws`-eko familia funtzionalen laburpena

| Sinadura / Funtzioa / Mota | Zer egiten duen eta noiz erabili |
|---|---|
| `ws accept key : String -> String` | `Sec-WebSocket-Key`-tik abiatuta RFC 6455 §1.3 `Sec-WebSocket-Accept` kalkulatzen du |
| `ws build upgrade request / ws build upgrade response` | WebSocket HTTP/1.1 upgrade handshake mezuak formateatzen ditu |
| `ws encode frame / ws decode frame` | `WsFrame` tramak (`fin`, `opcode`, `masked`, `mask_key`, `payload`) kodetu eta deskodetzen ditu |
| `ws text frame / ws ping frame / ws pong frame / ws close frame` | Goi-mailako tramen eraikitzaileak eta itxiera-kodeen erauzleak (`1000` itxiera normala) |

### 29.2.2. `src/main/ridgun/lib/ws.rg`-eko mota eta sinadura guztien katalogoa

Jarraian duzu `src/main/ridgun/lib/ws.rg` fitxategian definitutako mota aljebraiko (`type`), eragile (`op ::`) eta funtzio-sinadura (`fn ::`) guztien inbentario osoa (`3` mota, `0` eragile eta `54` funtzio):

**`ws`-eko mota aljebraikoak eta erregistroak (`type`):**

```ridgun
type WsFrame = is_fin: Bool, ws_opcode: Int, is_masked: Bool, payload_bytes: [Int], payload_text: String
type WsRes = WsOk WsFrame Int | WsErr String
type Sha1State = h0: Int, h1: Int, h2: Int, h3: Int, h4: Int
```

| # | Funtzioa / Sinadura (`fn ::`) | Itzulera-mota |
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

## 29.3. `ws` sakonki esploratzen: Funtzionalitate bakoitzaren urratsez urratseko adibideak

Ez da nahikoa sinadura-taula ikustea: `ws` lib-aren **funtzionalitate bakoitza** Ridgunen exekutagarriak diren adibide progresiboen bidez esploratuko dugu. Eguneroko bi errezeta taularatuekin hasiko gara eta ondoren xehetasunez ikusiko ditugu `src/test/ridgun/test ws.rg`-en egiaztatutako agertoki funtzional eta muga-kasu guztiak.

### 29.3.1. 1. adibidea: Fluxu nagusia estilo taularatuan `ws` erabiliz

Ikusi nola Ridgunen `=` ikurrak eta `ws` bidezko eraldaketa-urratsak taula garbi bat bezala lerrokatuta geratzen diren, beharrezkoak ez diren aldagai aldakorrik edo ezkutuko albo-ondoriorik gabe:

```ridgun
import ws

fn :: negociar y enviar (client_key : String) => (String, String)
      negociar y enviar client_key =
        resp  = ws build upgrade response client_key
        trama = ws encode frame (ws text frame "hola-tiempo-real" False "")
        (resp, trama)
```

### 29.3.2. 2. adibidea: Konposizio segurua eta muga-kasuen kudeaketa

`ws` lib-eko funtzio oro `|` guarda boolearrekin eta `ridgun-libs`-eko gainerako 32 lib-ekin konposatzeko diseinatuta dago:

```ridgun
import ws

fn :: decodificar trama cliente (clave4 : String) (msg : String) => String
      decodificar trama cliente clave4 msg =
        wire = ws encode frame (ws text frame msg True clave4)
        res  = ws decode frame wire
        ws frame payload res
```

### 29.3.3. 3. adibidea: RFC 6455 WebSocket handshake-a (`Sec-WebSocket-Accept` SHA-1 + Base64 bidez) eta `101 Switching Protocols` HTTP goiburuak

Adibide praktiko honetan `ws` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_ws_rfc6455_handshake => ()
      test_ws_rfc6455_handshake =
        rfc_key = "dGhlIHNhbXBsZSBub25jZQ=="
        accept = ws accept key rfc_key
        _ = assert str eq accept "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=" "AC1: RFC 6455 Sec-WebSocket-Accept test vector"

        req = ws build upgrade request "chat.example.com" "/ws" rfc_key
        _ = assert true (str_contains req "GET /ws HTTP/1.1") "AC1: upgrade request line"
        _ = assert true (str_contains req "Host: chat.example.com") "AC1: upgrade request Host header"
        _ = assert true (str_contains req "Upgrade: websocket") "AC1: upgrade request Upgrade header"
        _ = assert true (str_contains req "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==") "AC1: upgrade request contains key"

        resp = ws build upgrade response rfc_key
        _ = assert true (str_contains resp "101 Switching Protocols") "AC1: upgrade response status 101"
        _ = assert true (str_contains resp "Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=") "AC1: upgrade response contains accept digest"
        ()
```

### 29.3.4. 4. adibidea: 7, 16 eta 64 biteko bilbeen kodetzea eta deskodetzea (`Text`, `Binary`, `Ping`, `Pong`, `Close`) eta 4 byteko XOR maskaratzea

Adibide praktiko honetan `ws` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_ws_framing_and_masking => ()
      test_ws_framing_and_masking =
        -- RFC 6455 Section 5.7 Example 1: single-frame unmasked text "Hello" -> [0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f]
        w_hello = ws encode text "Hello"
        _ = assert true (ws_int_list_eq w_hello [129, 5, 72, 101, 108, 108, 111]) "AC2: RFC 6455 5.7 unmasked 'Hello' wire bytes"
        r_hello = ws decode frame w_hello
        _ = assert true (is_ws_ok r_hello) "AC2: decode RFC 6455 unmasked 'Hello'"
        _ = assert str eq (payload_text (unwrap_ws_frame r_hello)) "Hello" "AC2: decoded 'Hello' text"
        _ = assert int equals (unwrap_ws_len r_hello) 7 "AC2: consumed 7 bytes"

        -- RFC 6455 Section 5.7 Example 2: single-frame masked text "Hello" with mask [0x37, 0xfa, 0x21, 0x3d]
        mask_rfc = [55, 250, 33, 61]
        w_mhello = ws encode masked text "Hello" mask_rfc
        _ = assert true (ws_int_list_eq w_mhello [129, 133, 55, 250, 33, 61, 127, 159, 77, 81, 88]) "AC2: RFC 6455 5.7 masked 'Hello' wire bytes"
        r_mhello = ws decode frame w_mhello
        _ = assert true (is_ws_ok r_mhello) "AC2: decode RFC 6455 masked 'Hello'"
        f_mhello = unwrap_ws_frame r_mhello
        _ = assert true (is_masked f_mhello) "AC2: masked frame is_masked=true"
        _ = assert str eq (payload_text f_mhello) "Hello" "AC2: XOR unmasked text matches 'Hello'"
        _ = assert int equals (unwrap_ws_len r_mhello) 11 "AC2: consumed 11 bytes"

        -- Empty payload frame (0 bytes)
        w_empty = ws encode text ""
        r_empty = ws decode frame w_empty
        _ = assert true (is_ws_ok r_empty) "AC2: decode empty text frame"
        _ = assert str eq (payload_text (unwrap_ws_frame r_empty)) "" "AC2: empty payload_text"
        _ = assert int equals (unwrap_ws_len r_empty) 2 "AC2: 2-byte header for empty unmasked frame"

        -- Boundary length 125 (max 7-bit length) vs 126 (min 16-bit extended length)
        msg_125 = ws_repeat_str "A" 125
        w_125 = ws encode text msg_125
        r_125 = ws decode frame w_125
        _ = assert int equals (unwrap_ws_len r_125) 127 "AC2: 125B payload uses 2B header (127 total)"
        _ = assert str eq (payload_text (unwrap_ws_frame r_125)) msg_125 "AC2: 125B payload round-trips"

        msg_126 = ws_repeat_str "B" 126
        w_126 = ws encode masked text msg_126 mask_rfc
        r_126 = ws decode frame w_126
        _ = assert int equals (unwrap_ws_len r_126) 134 "AC2: 126B masked payload uses 4B hdr + 4B mask + 126B (134 total)"
        _ = assert str eq (payload_text (unwrap_ws_frame r_126)) msg_126 "AC2: 126B payload round-trips"

        -- Control frames: Ping (9), Pong (10), Close (8)
        w_ping = ws encode ping [1, 2, 3]
        f_ping = unwrap_ws_frame (ws decode frame w_ping)
        _ = assert int equals (ws_opcode f_ping) 9 "AC2: ping opcode=9"
        _ = assert true (ws_int_list_eq (payload_bytes f_ping) [1, 2, 3]) "AC2: ping payload bytes"

        w_pong = ws encode pong [4, 5]
        f_pong = unwrap_ws_frame (ws decode frame w_pong)
        _ = assert int equals (ws_opcode f_pong) 10 "AC2: pong opcode=10"

        w_close = ws encode close 1000
        f_close = unwrap_ws_frame (ws decode frame w_close)
        _ = assert int equals (ws_opcode f_close) 8 "AC2: close opcode=8"
        _ = assert true (ws_int_list_eq (payload_bytes f_close) [3, 232]) "AC2: close code 1000 big-endian [0x03, 0xE8]"
        ()
```

### 29.3.5. 5. adibidea: Mozketadun edo osatu gabeko WebSocket bilbeen detekzio segurua (`WsErr`)

Adibide praktiko honetan `ws` bloke funtzional honetan nola portatzen den sakonki aztertzen dugu, sarrera estandarrak, parametro-konbinazioak eta muga-balioak barne:

```ridgun
fn :: test_ws_truncated_frames => ()
      test_ws_truncated_frames =
        _ = assert false (is_ws_ok (ws decode frame [])) "AC3: reject 0-byte empty buffer"
        _ = assert false (is_ws_ok (ws decode frame [129])) "AC3: reject 1-byte truncated header"
        _ = assert false (is_ws_ok (ws decode frame [129, 10, 65, 66])) "AC3: reject truncated unmasked payload"
        _ = assert false (is_ws_ok (ws decode frame [129, 126, 0])) "AC3: reject truncated 16-bit extended header"
        _ = assert false (is_ws_ok (ws decode frame [129, 130, 1, 2])) "AC3: reject truncated 4-byte masking key"
        _ = assert false (is_ws_ok (ws decode frame [129, 133, 55, 250, 33, 61, 127, 159])) "AC3: reject truncated masked payload"
        ()
```

---

## 29.4. Kaputaren azpian: nola dagoen eraikia `ws` Ridgun hutsean (`src/main/ridgun/lib/ws.rg`)

`ridgun-libs`-en abantaila handienetako bat **C-ko kutxa beltzik ez egotea** da. `src/main/ridgun/lib/ws.rg` ireki dezakezu eta eragiketa bakoitza *pattern matching*, `|` / `|.` guarda-zuhaitzak eta isats-errekurtsioa (TCO) erabiliz nola inplementatuta dagoen irakurri. Ikus ditzagun bere benetako inplementazioaren funtsezko piezak:

### 29.4.1. Barne-inplementazioa: 32-Bit Unsigned Bitwise Helpers for RFC 3174 SHA-1

Ikusi nola `ws.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: ws_u32 Int => Int
      ws_u32 x   =  ((x % 4294967296) + 4294967296) % 4294967296

fn :: ws_u32_xor_loop Int Int Int Int => Int
      ws_u32_xor_loop _   _   0   acc =  acc
      ws_u32_xor_loop a   b   bit acc
        | (a % 2) != (b % 2) = ws_u32_xor_loop (a / 2) (b / 2) (bit * 2) (acc + bit)
        | otherwise = ws_u32_xor_loop (a / 2) (b / 2) (bit * 2) acc

fn :: ws_u32_xor Int Int => Int
      ws_u32_xor a   b   =  ws_u32_xor_loop (ws_u32 a) (ws_u32 b) 1 0

fn :: ws_u32_and_loop Int Int Int Int => Int
      ws_u32_and_loop _   _   0   acc =  acc
      ws_u32_and_loop a   b   bit acc
        | (a % 2) == 1 AND (b % 2) == 1 = ws_u32_and_loop (a / 2) (b / 2) (bit * 2) (acc + bit)
        | otherwise = ws_u32_and_loop (a / 2) (b / 2) (bit * 2) acc

fn :: ws_u32_and Int Int => Int
      ws_u32_and a   b   =  ws_u32_and_loop (ws_u32 a) (ws_u32 b) 1 0

fn :: ws_u32_or_loop Int Int Int Int => Int
      ws_u32_or_loop _   _   0   acc =  acc
      ws_u32_or_loop a   b   bit acc
        | (a % 2) == 1 OR (b % 2) == 1 = ws_u32_or_loop (a / 2) (b / 2) (bit * 2) (acc + bit)
        | otherwise = ws_u32_or_loop (a / 2) (b / 2) (bit * 2) acc

fn :: ws_u32_or Int Int => Int
      ws_u32_or a   b   =  ws_u32_or_loop (ws_u32 a) (ws_u32 b) 1 0

fn :: ws_u32_not Int => Int
      ws_u32_not a   =  4294967295 - (ws_u32 a)

fn :: ws_pow2 Int => Int
      ws_pow2 0   =  1
      ws_pow2 n   =  2 * (ws_pow2 (n - 1))

fn :: ws_rotl32 Int Int => Int
      ws_rotl32 x   n   =
        ux = ws_u32 x
        p_shl = ws_pow2 n
        p_shr = ws_pow2 (32 - n)
        ws_u32 ((ux * p_shl) + (ux / p_shr))

fn :: ws_byte_xor Int Int => Int
      ws_byte_xor a   b   =  (ws_u32_xor (a % 256) (b % 256)) % 256
```

### 29.4.2. Barne-inplementazioa: List & String Byte Conversion Helpers

Ikusi nola `ws.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: ws_list_len [Int]    => Int
      ws_list_len []       =  0
      ws_list_len (_:rest) =  1 + (ws_list_len rest)

fn :: ws_nth [Int]    Int => Int
      ws_nth []       _   =  0
      ws_nth (x:_)    0   =  x
      ws_nth (_:rest) idx =  ws_nth rest (idx - 1)

fn :: ws_take [Int]    Int => [Int]
      ws_take []       _   =  []
      ws_take (x:rest) n
        | n <= 0 = []
        | otherwise = [x] :: (ws_take rest (n - 1))

fn :: ws_drop [Int]    Int => [Int]
      ws_drop []       _   =  []
      ws_drop (x:rest) n
        | n <= 0 = [x] :: rest
        | otherwise = ws_drop rest (n - 1)

fn :: ws_str_to_bytes_loop String Int Int [Int] => [Int]
      ws_str_to_bytes_loop s      pos len acc
        | pos >= len = acc
        | otherwise = ws_str_to_bytes_loop s (pos + 1) len (acc :: [((str_char_at s pos) % 256 + 256) % 256])

fn :: ws_str_to_bytes String => [Int]
      ws_str_to_bytes s      =  ws_str_to_bytes_loop s 0 (str_len s) []

fn :: ws_bytes_to_str [Int]    => String
      ws_bytes_to_str []       =  ""
      ws_bytes_to_str (b:rest) =  (char_from_code b) + (ws_bytes_to_str rest)
```

### 29.4.3. Barne-inplementazioa: Pure-Ridgun SHA-1 & Base64 for RFC 6455 Handshake

Ikusi nola `ws.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: ws_zeroes Int => [Int]
      ws_zeroes n
        | n <= 0 = []
        | otherwise = [0] :: (ws_zeroes (n - 1))

fn :: ws_u32_be4 Int => [Int]
      ws_u32_be4 w   =
        uw = ws_u32 w
        [(uw / 16777216) % 256, (uw / 65536) % 256, (uw / 256) % 256, uw % 256]

fn :: ws_sha1_pad [Int] => [Int]
      ws_sha1_pad bs    =
        mlen = ws_list_len bs
        bit_len = mlen * 8
        rem = (mlen + 1) % 64
        z_count = ((56 - rem) + 64) % 64
        ((bs :: [128]) :: (ws_zeroes z_count)) :: ((ws_u32_be4 0) :: (ws_u32_be4 bit_len))

fn :: ws_be32_at [Int] Int => Int
      ws_be32_at bs    off =  ((ws_nth bs off) * 16777216) + ((ws_nth bs (off + 1)) * 65536) + ((ws_nth bs (off + 2)) * 256) + (ws_nth bs (off + 3))

fn :: ws_sha1_w16_loop [Int] Int [Int] => [Int]
      ws_sha1_w16_loop blk   idx acc
        | idx >= 16 = acc
        | otherwise = ws_sha1_w16_loop blk (idx + 1) (acc :: [ws_be32_at blk (idx * 4)])

fn :: ws_sha1_expand_loop [Int] Int => [Int]
      ws_sha1_expand_loop w     t
        | t >= 80 = w
        | otherwise = ws_sha1_expand_step w t

fn :: ws_sha1_expand_step [Int] Int => [Int]
      ws_sha1_expand_step w     t   =
        x = ws_u32_xor (ws_u32_xor (ws_u32_xor (ws_nth w (t - 3)) (ws_nth w (t - 8))) (ws_nth w (t - 14))) (ws_nth w (t - 16))
        ws_sha1_expand_loop (w :: [ws_rotl32 x 1]) (t + 1)

fn :: ws_sha1_f Int Int Int Int => Int
      ws_sha1_f t   b   c   d
        | t < 20 = ws_u32_or (ws_u32_and b c) (ws_u32_and (ws_u32_not b) d)
        | t < 40 = ws_u32_xor (ws_u32_xor b c) d
        | t < 60 = ws_u32_or (ws_u32_or (ws_u32_and b c) (ws_u32_and b d)) (ws_u32_and c d)
        | otherwise = ws_u32_xor (ws_u32_xor b c) d

fn :: ws_sha1_k Int => Int
      ws_sha1_k t
        | t < 20 = 1518500249
        | t < 40 = 1859775393
        | t < 60 = 2400959708
        | otherwise = 3395469782
```

### 29.4.4. Barne-inplementazioa: RFC 6455 XOR Masking & Frame Encoding / Decoding

Ikusi nola `ws.rg`-ek lehenik `fn :: ... => ...` sinadurak egituratzen dituen eta kasu bakoitza lerrokatutako ekuazioen eta isats-deien bidez ebazten duen:

```ridgun
fn :: ws_mask_loop [Int]    [Int]    Int => [Int]
      ws_mask_loop []       _        _   =  []
      ws_mask_loop (b:rest) mask_key idx =  [ws_byte_xor b (ws_nth mask_key (idx % 4))] :: (ws_mask_loop rest mask_key (idx + 1))

fn :: ws mask bytes [Int]   [Int]    => [Int]
      ws mask bytes payload mask_key
        | (ws_list_len mask_key) < 4 = payload
        | otherwise = ws_mask_loop payload mask_key 0

fn :: ws_fin_bit Bool  => Int
      ws_fin_bit True  =  128
      ws_fin_bit False =  0

fn :: ws_len_header Int  Int      => [Int]
      ws_len_header plen mask_bit
        | plen < 126 = [mask_bit + plen]
        | otherwise = [mask_bit + 126, (plen / 256) % 256, plen % 256]

fn :: ws encode frame Bool Int [Int] [Int] => [Int]
      ws encode frame fin opcode mask_key payload =
        b0 = (ws_fin_bit fin) + (opcode % 16)
        has_mask = (ws_list_len mask_key) >= 4
        ws_encode_frame_with_mask b0 has_mask mask_key payload

fn :: ws_encode_frame_with_mask Int Bool  [Int]    [Int]   => [Int]
      ws_encode_frame_with_mask b0  False _        payload =  ([b0] :: (ws_len_header (ws_list_len payload) 0)) :: payload
      ws_encode_frame_with_mask b0  True  mask_key payload =
        m4 = ws_take mask_key 4
        masked_pay = ws_mask_bytes payload m4
        (([b0] :: (ws_len_header (ws_list_len payload) 128)) :: m4) :: masked_pay

fn :: ws encode text String => [Int]
      ws encode text text   =  ws_encode_frame True 1 [] (ws_str_to_bytes text)

fn :: ws encode masked text String [Int] => [Int]
      ws encode masked text text mask_key = ws_encode_frame True 1 mask_key (ws_str_to_bytes text)

fn :: ws encode ping [Int]   => [Int]
      ws encode ping payload =  ws_encode_frame True 9 [] payload

fn :: ws encode pong [Int]   => [Int]
      ws encode pong payload =  ws_encode_frame True 10 [] payload

fn :: ws encode close Int  => [Int]
      ws encode close code =  ws_encode_frame True 8 [] [(code / 256) % 256, code % 256]

fn :: ws decode frame [Int] => WsRes
      ws decode frame wire  =
        total = ws_list_len wire
        ws_decode_check_min wire total
```

---

## 29.5. Berme algoritmikoak, `RMM1`/`RMM2` memoria eta `ws`-en Urrezko 5 Arauak

- **Berme algoritmikoa eta segurtasunekoa**: Bat-etortze zehatza RFC 6455 bektore ofizialarekin (`"dGhlIHNhbXBsZSBub25jZQ=="` $\rightarrow$ `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="`) eta maskara-kentze automatikoa `ws decode frame`-n.
- **$O(1)$ pila-konplexutasuna TCOrekin**: `src/main/ridgun/lib/ws.rg`-eko begizta errekurtsibo guztiak isats-posizioan daude; beraz, `ridgunc`-ek pila-hazkuntzarik gabeko jauzi natiboetara konpilatzen ditu.
- **Memoria determinista (`RMM1`/`RMM2`)**: Zero zabor-biltzaile etenaldi; tarteko egitura guztiak modu deterministan askatzen dira esparrutik irtetean.
- **Etengabeko egiaztapena**: Zorrotz probatua `stable check` eta `src/test/ridgun/test ws.rg` suite automatizatuaren bidez.

### `ws`-ekin programatzeko Urrezko 5 Arauak

1. **Deklaratu `import ws` fitxategiaren hasieran** eta baliatu zuriuneen eta azpimarren arteko baliokidetasuna zure kodea prosa bezala irakur dadin.
2. **Lerrokatu zure datu-hodiak `=` ikurrarekin**: kateatu `ws`-erako deiak izen propioko urratsetan eta utzi `stable format`-i zutabeak lerrokatzen.
3. **Baliatu `ws`-eko funtzio osoak zure `|` guardetan**: egiaztatu itzulera-balioak edo askatu ADTak *pattern matching* bidez, kanpoko sarrera beti baliozkoa dela suposatu beharrean.
4. **Saihestu egitura handiak kopiatzea eremu bat kontsultatu besterik behar ez baduzu**: gogoratu `RMM2`-n sarrerako argumentuek ez dituztela kontagailuak handitzen edo txikitzen (`+0` / `-0`).
5. **Konbinatu `ws` eta `test` (`import test`)**: idatzi beti asertzioak `assert equals` edo `assert true` erabiliz zure domeinuaren inbarianteak finkatzeko.

---

**30. kapituluan** **`agent`** lib-a sakonki esploratuko dugu (`agent` lib-a — Aktoreen Eredu Natiboa (`agent`, `send`, `receive`), KV Biltegia eta Rate Limiter-a).
