# Kapitel 29: Lib:en `ws` — RFC 6455 WebSocket-handskakning, 16/64-bitars Ramkodek och XOR-maskering

## 29.1. Varför finns lib:en `ws`? (Det verkliga problemet och Ridguns filosofi)

> *”Varför behöver jag en `ws`-lib skriven från grunden i ren Ridgun i stället för att bara länka in ett gammalt C-bibliotek?”*

Det är den första fråga varje systemingenjör ställer sig när man möter `ws`. Och svaret sammanfattar hela filosofin bakom `ridgun-libs`:

Låt oss vara ärliga: WebSocket-protokollet (RFC 6455) kombinerar en SHA-1 + Base64-handskakning med binära ramar av variabel längd (7, 16 eller 64 bitar) och obligatorisk 4-bytes XOR-maskering från klient till server.

Lib:en **`ws`** implementerar hela **RFC 6455** i ren Ridgun: beräkning av `Sec-WebSocket-Accept` (med inbyggd RFC 3174 SHA-1 för handskaknings-GUID), `101 Switching Protocols`-headers, kodning och avkodning av 7/16/64-bitars `WsFrame`-ramar, symmetrisk XOR-maskering samt byggare för text-, ping-, pong- och stängningsramar.

I ett traditionellt ekosystem innebär uppgifter inom domänen **`WS`** ofta att man drar in externa C-beroenden, brottas med råa pekare, ogenomskinliga typkonverteringar, okontrollerade undantag eller oförutsägbara skräpsamlarpauser. I Ridgun löser lib:en **`ws`** (`src/main/ridgun/lib/ws.ridgun`) problemet genom fyra kompromisslösa principer:

1. **Deklarera `import ws` (eller `import ws as alias`) överst i filen**: varje lib definierar sin `module :: ws`-namnrymd och i `--strict`-läge anropas flerordsfunktioner alltid med naturliga mellanslag.
2. **Kedja dina datapipelines från vänster till höger med `->`**: skriv `indata steg ett -> steg två -> resultat`, använd `(+ _ _ +)`-sekvensmasker för att packa upp tupler och utelämna `_ =` vid sekventiella satser (eller kasta med `-> ()`).
3. **Svansrekursion med TCO (*Tail-Call Optimization*)**: alla interna genomlöpningar i `ws` kompileras till inbyggda hårdvaruloopar med $O(1)$ stackutrymme.
4. **Deterministiskt minne (`RMM1` / `RMM2`)**: varje mellanliggande struktur frigörs i exakt det ögonblick dess sista läsning avslutas, helt utan *Garbage Collector*.

---

## 29.2. Inbyggda artefakter, import och komplett API-katalog för `ws`

I `ridgun-libs` är **`ws`** en förstklassig **lib** placerad i `src/main/ridgun/lib/ws.ridgun` (domän `WS`). När du bygger med `stable bundle` paketeras den i ett inbyggt format:

| Artefakt | Sökväg | Syfte |
|---|---|---|
| **Ridgun-bundle** | `target/bundles/ws.ridgunlib` | Portabel distribution och direkt import med `import ws` |

> Varje lib deklarerar sin egen namnrymd med `module :: ws`: skriv bara `import ws` (eller `import ws as alias`) överst och anropa dess funktioner med naturliga mellanslag (`min funktion x`) och `->`-pipelines (`x min funktion -> resultat`).

### 29.2.1. Översikt över funktionella familjer i `ws`

| Signatur / Funktion / Typ | Vad den gör och när den används |
|---|---|
| `ws accept key : String -> String` | Beräknar RFC 6455 §1.3 `Sec-WebSocket-Accept` från `Sec-WebSocket-Key` |
| `ws build upgrade request / ws build upgrade response` | Formaterar HTTP/1.1-meddelanden för WebSocket-uppgraderingshandskakning |
| `ws encode frame / ws decode frame` | Kodar och avkodar `WsFrame`-ramar (`fin`, `opcode`, `masked`, `mask_key`, `payload`) |
| `ws encode text / ws encode ping / ws encode pong / ws encode close` | Högnivåbyggare för ramar och extraherare för stängningskoder (`1000` normal stängning) |

### 29.2.2. Komplett katalog över typer och signaturer i `src/main/ridgun/lib/ws.ridgun`

Nedan följer hela förteckningen över algebraiska datatyper (`type`), mixfix-operatorer (`op ::`) och funktionssignaturer (`fn ::`) som definieras i `src/main/ridgun/lib/ws.ridgun` (`2` typer, `0` operatorer och `40` funktioner):

**Algebraiska datatyper och poster (`type`) i `ws`:**

```ridgun
type WsFrame = is_fin: Bool, ws_opcode: Int, is_masked: Bool, payload_bytes: Tensor[U8], payload_text: String
type WsRes = WsOk WsFrame Int | WsErr String
```

| # | Funktion / Signatur (`fn ::`) | Returtyp |
|---|---|---|
| `1` | `fn :: ws u32 Int` | `Int` |
| `2` | `fn :: ws byte bxor Int Int` | `Int` |
| `3` | `fn :: ws blen Tensor[U8]` | `Int` |
| `4` | `fn :: ws copy range Tensor[U8] Int Tensor[U8] Int Int` | `Tensor[U8]` |
| `5` | `fn :: ws copy range step Tensor[U8] Int Tensor[U8] Int Int` | `Tensor[U8]` |
| `6` | `fn :: ws mask range Tensor[U8] Int Tensor[U8] Int Int Tensor[U8] Int Int` | `Tensor[U8]` |
| `7` | `fn :: ws mask range step Tensor[U8] Int Tensor[U8] Int Int Tensor[U8] Int Int` | `Tensor[U8]` |
| `8` | `fn :: ws put be32 Tensor[U8] Int Int` | `Tensor[U8]` |
| `9` | `fn :: ws be32 at Tensor[U8] Int` | `Int` |
| `10` | `fn :: ws b64 lut Int` | `String` |
| `11` | `fn :: ws b64 code String Int` | `Int` |
| `12` | `fn :: ws b64 enc Tensor[U8]` | `String` |
| `13` | `fn :: ws b64 enc loop Tensor[U8] Int Tensor[U8] String Int Int` | `Tensor[U8]` |
| `14` | `fn :: ws b64 enc group Tensor[U8] Int Tensor[U8] String Int Int` | `Tensor[U8]` |
| `15` | `fn :: ws b64 enc tail1 Tensor[U8] Tensor[U8] String Int Int` | `Tensor[U8]` |
| `16` | `fn :: ws b64 enc tail2 Tensor[U8] Tensor[U8] String Int Int` | `Tensor[U8]` |
| `17` | `fn :: ws accept key String` | `String` |
| `18` | `fn :: ws build upgrade request String String String` | `String` |
| `19` | `fn :: ws build upgrade response String` | `String` |
| `20` | `fn :: ws mask bytes Tensor[U8] Tensor[U8]` | `Tensor[U8]` |
| `21` | `fn :: ws mask bytes into Tensor[U8] Tensor[U8] Tensor[U8] Int` | `Tensor[U8]` |
| `22` | `fn :: ws fin bit Bool` | `Int` |
| `23` | `fn :: ws len ext size Int` | `Int` |
| `24` | `fn :: ws put len Tensor[U8] Int Int Int` | `Tensor[U8]` |
| `25` | `fn :: ws put len7 Tensor[U8] Int` | `Tensor[U8]` |
| `26` | `fn :: ws put len16 Tensor[U8] Int Int` | `Tensor[U8]` |
| `27` | `fn :: ws put len64 Tensor[U8] Int Int` | `Tensor[U8]` |
| `28` | `fn :: ws encode frame Bool Int Tensor[U8] Tensor[U8]` | `Tensor[U8]` |
| `29` | `fn :: ws encode frame with mask Int Bool Tensor[U8] Tensor[U8]` | `Tensor[U8]` |
| `30` | `fn :: ws encode text String` | `Tensor[U8]` |
| `31` | `fn :: ws encode masked text String Tensor[U8]` | `Tensor[U8]` |
| `32` | `fn :: ws encode ping Tensor[U8]` | `Tensor[U8]` |
| `33` | `fn :: ws encode pong Tensor[U8]` | `Tensor[U8]` |
| `34` | `fn :: ws encode close Int` | `Tensor[U8]` |
| `35` | `fn :: ws decode frame Tensor[U8]` | `WsRes` |
| `36` | `fn :: ws decode check min Tensor[U8] Int` | `WsRes` |
| `37` | `fn :: ws decode len Tensor[U8] Int Int Int` | `WsRes` |
| `38` | `fn :: ws decode ext len Tensor[U8] Int Bool Int Bool Int` | `WsRes` |
| `39` | `fn :: ws decode body Tensor[U8] Int Bool Int Bool Int Int` | `WsRes` |
| `40` | `fn :: ws finish frame Bool Int Bool Tensor[U8] Int` | `WsRes` |

---

## 29.3. Djupdykning i `ws`: Steg-för-steg-exempel för varje funktion

Det räcker inte med en signaturtabell: låt oss utforska **varje funktionalitet** i lib:en `ws` genom progressiva, körbara Ridgun-exempel. Vi börjar med två tabellbaserade vardagsrecept och går därefter igenom alla funktionella scenarier, transformationer och gränsfall som verifieras i `src/test/ridgun/test ws.ridgun`.

### 29.3.1. Exempel 1: Huvudflöde i tabellform med `ws`

Lägg märke till hur `=`-tecknen och transformationsstegen med `ws` linjeras som en ren tabell utan onödiga muterbara variabler eller dolda sidoeffekter:

```ridgun
import ws

fn :: negociar y enviar String => String Tensor[U8]
      negociar y enviar client_key =
        ws build upgrade response client_key -> resp
        ws encode text "hola-tiempo-real" -> trama
        (resp, trama)
```

### 29.3.2. Exempel 2: Säker komposition och hantering av gränsfall

Varje funktion i lib:en `ws` är utformad för att kombineras sömlöst med booleska vakter `|` och med övriga 38 libs i `ridgun-libs`:

```ridgun
import ws

fn :: texto de WsRes      => String
      texto de (WsOk f _) =  payload_text f
      texto de (WsErr e)  =  "error: " + e

fn :: decodificar trama cliente Tensor[U8] String => String
      decodificar trama cliente mask4 msg =
        ws encode masked text msg mask4 -> wire
        texto de (ws decode frame wire)
```

### 29.3.3. Exempel 3: RFC 6455 WebSocket-handskakning (`Sec-WebSocket-Accept` via SHA-1 + Base64) och `101 Switching Protocols`-rubriker

I detta praktiska exempel undersöker vi grundligt hur `ws` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test ws rfc6455 handshake => ()
      test ws rfc6455 handshake =
        rfc_key = "dGhlIHNhbXBsZSBub25jZQ=="
        accept = ws accept key rfc_key
        accept -> assert str eq "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=" "AC1: RFC 6455 Sec-WebSocket-Accept test vector"

        req = ws build upgrade request "chat.example.com" "/ws" rfc_key
        str contains req "GET /ws HTTP/1.1" -> assert true "AC1: upgrade request line"
        str contains req "Host: chat.example.com" -> assert true "AC1: upgrade request Host header"
        str contains req "Upgrade: websocket" -> assert true "AC1: upgrade request Upgrade header"
        str contains req "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" -> assert true "AC1: upgrade request contains key"

        resp = ws build upgrade response rfc_key
        str contains resp "101 Switching Protocols" -> assert true "AC1: upgrade response status 101"
        str contains resp "Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=" -> assert true "AC1: upgrade response contains accept digest"
        ()
```

### 29.3.4. Exempel 4: Kodning och avkodning av 7-, 16- och 64-bitarsramar (`Text`, `Binary`, `Ping`, `Pong`, `Close`) och 4-bytes XOR-maskering

I detta praktiska exempel undersöker vi grundligt hur `ws` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test ws framing and masking => ()
      test ws framing and masking =
        -- RFC 6455 Section 5.7 Example 1: single-frame unmasked text "Hello" -> [0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f]
        w_hello = ws encode text "Hello"
        ws bytes eq w_hello [129, 5, 72, 101, 108, 108, 111] -> assert true "AC2: RFC 6455 5.7 unmasked 'Hello' wire bytes"
        r_hello = ws decode frame w_hello
        is ws ok r_hello -> assert true "AC2: decode RFC 6455 unmasked 'Hello'"
        payload_text (unwrap ws frame r_hello) -> assert str eq "Hello" "AC2: decoded 'Hello' text"
        unwrap ws len r_hello -> assert int equals 7 "AC2: consumed 7 bytes"

        -- RFC 6455 Section 5.7 Example 2: single-frame masked text "Hello" with mask [0x37, 0xfa, 0x21, 0x3d]
        mask_rfc = ws bytes of [55, 250, 33, 61]
        w_mhello = ws encode masked text "Hello" mask_rfc
        ws bytes eq w_mhello [129, 133, 55, 250, 33, 61, 127, 159, 77, 81, 88] -> assert true "AC2: RFC 6455 5.7 masked 'Hello' wire bytes"
        r_mhello = ws decode frame w_mhello
        is ws ok r_mhello -> assert true "AC2: decode RFC 6455 masked 'Hello'"
        f_mhello = unwrap ws frame r_mhello
        is_masked f_mhello -> assert true "AC2: masked frame is_masked=true"
        payload_text f_mhello -> assert str eq "Hello" "AC2: XOR unmasked text matches 'Hello'"
        unwrap ws len r_mhello -> assert int equals 11 "AC2: consumed 11 bytes"

        -- Empty payload frame (0 bytes)
        w_empty = ws encode text ""
        r_empty = ws decode frame w_empty
        is ws ok r_empty -> assert true "AC2: decode empty text frame"
        payload_text (unwrap ws frame r_empty) -> assert str eq "" "AC2: empty payload_text"
        unwrap ws len r_empty -> assert int equals 2 "AC2: 2-byte header for empty unmasked frame"

        -- Boundary length 125 (max 7-bit length) vs 126 (min 16-bit extended length)
        msg_125 = ws repeat str "A" 125
        w_125 = ws encode text msg_125
        r_125 = ws decode frame w_125
        unwrap ws len r_125 -> assert int equals 127 "AC2: 125B payload uses 2B header (127 total)"
        payload_text (unwrap ws frame r_125) -> assert str eq msg_125 "AC2: 125B payload round-trips"

        msg_126 = ws repeat str "B" 126
        w_126 = ws encode masked text msg_126 mask_rfc
        r_126 = ws decode frame w_126
        unwrap ws len r_126 -> assert int equals 134 "AC2: 126B masked payload uses 4B hdr + 4B mask + 126B (134 total)"
        payload_text (unwrap ws frame r_126) -> assert str eq msg_126 "AC2: 126B payload round-trips"

        -- Control frames: Ping (9), Pong (10), Close (8)
        w_ping = ws encode ping (ws bytes of [1, 2, 3])
        f_ping = unwrap ws frame (ws decode frame w_ping)
        ws_opcode f_ping -> assert int equals 9 "AC2: ping opcode=9"
        ws bytes eq (payload_bytes f_ping) [1, 2, 3] -> assert true "AC2: ping payload bytes"

        w_pong = ws encode pong (ws bytes of [4, 5])
        f_pong = unwrap ws frame (ws decode frame w_pong)
        ws_opcode f_pong -> assert int equals 10 "AC2: pong opcode=10"

        w_close = ws encode close 1000
        f_close = unwrap ws frame (ws decode frame w_close)
        ws_opcode f_close -> assert int equals 8 "AC2: close opcode=8"
        ws bytes eq (payload_bytes f_close) [3, 232] -> assert true "AC2: close code 1000 big-endian [0x03, 0xE8]"
        ()
```

### 29.3.5. Exempel 5: Säker detektering av trunkerade eller ofullständiga WebSocket-ramar (`WsErr`)

I detta praktiska exempel undersöker vi grundligt hur `ws` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test ws truncated frames => ()
      test ws truncated frames =
        is ws ok (ws decode frame (ws bytes of [])) -> assert false "AC3: reject 0-byte empty buffer"
        is ws ok (ws decode frame (ws bytes of [129])) -> assert false "AC3: reject 1-byte truncated header"
        is ws ok (ws decode frame (ws bytes of [129, 10, 65, 66])) -> assert false "AC3: reject truncated unmasked payload"
        is ws ok (ws decode frame (ws bytes of [129, 126, 0])) -> assert false "AC3: reject truncated 16-bit extended header"
        is ws ok (ws decode frame (ws bytes of [129, 130, 1, 2])) -> assert false "AC3: reject truncated 4-byte masking key"
        is ws ok (ws decode frame (ws bytes of [129, 133, 55, 250, 33, 61, 127, 159])) -> assert false "AC3: reject truncated masked payload"
        is ws ok (ws decode frame (ws bytes of [130, 127, 0, 0, 0, 0, 0])) -> assert false "AC3: reject truncated 64-bit extended header"
        is ws ok (ws decode frame (ws bytes of [130, 127, 128, 0, 0, 0, 0, 0, 0, 1, 65])) -> assert false "AC3: reject 64-bit length with the most significant bit set"
        is ws ok (ws decode frame (ws bytes of [130, 127, 0, 0, 0, 0, 0, 1, 17, 112, 65])) -> assert false "AC3: reject truncated 64-bit length payload"
        ()
```

### 29.3.6. Exempel 6: Ramar på 70 000 byte: den 64-bitars längdkoden 127, maskerade och omaskerade rundresor

I detta praktiska exempel undersöker vi grundligt hur `ws` beter sig inom detta funktionsområde, inklusive standardindata, parameterkombinationer och gränsvärden:

```ridgun
fn :: test ws large frame round trip => ()
      test ws large frame round trip =
        big = ws big payload 70000
        big_(128) -> assert int equals 128 "AC2: large payload holds byte 128"
        big_(255) -> assert int equals 255 "AC2: large payload holds byte 255"
        w_big = ws encode frame True 2 (Tensor[U8 * 0]) big
        w_big_(1) -> assert int equals 127 "AC2: 70000B unmasked payload uses the 64-bit length code 127"
        ws int list eq [w_big_(2), w_big_(3), w_big_(4), w_big_(5), w_big_(6), w_big_(7), w_big_(8), w_big_(9)] [0, 0, 0, 0, 0, 1, 17, 112] -> assert true "AC2: 64-bit big-endian length 70000"
        r_big = ws decode frame w_big
        is ws ok r_big -> assert true "AC2: decode 70000B unmasked frame"
        unwrap ws len r_big -> assert int equals 70010 "AC2: consumed 10B header + 70000B"
        (payload_bytes (unwrap ws frame r_big)) == big -> assert true "AC2: 70000B unmasked payload round-trips byte for byte"

        mask_k = ws bytes of [0, 128, 255, 61]
        w_mbig = ws encode frame False 2 mask_k big
        w_mbig_(1) -> assert int equals 255 "AC2: 70000B masked payload sets MASK and length code 127"
        r_mbig = ws decode frame w_mbig
        is ws ok r_mbig -> assert true "AC2: decode 70000B masked frame"
        f_mbig = unwrap ws frame r_mbig
        is_fin f_mbig -> assert false "AC2: large masked frame keeps FIN=0"
        is_masked f_mbig -> assert true "AC2: large masked frame is_masked=true"
        unwrap ws len r_mbig -> assert int equals 70014 "AC2: consumed 10B header + 4B mask + 70000B"
        (payload_bytes f_mbig) == big -> assert true "AC2: 70000B masked payload round-trips byte for byte"
        ()
```

---

## 29.4. Under huven: hur `ws` är byggd i ren Ridgun (`src/main/ridgun/lib/ws.ridgun`)

En av de största fördelarna med `ridgun-libs` är att **det inte finns några svarta lådor i C**. Du kan öppna `src/main/ridgun/lib/ws.ridgun` och läsa exakt hur varje operation är implementerad med mönstermatchning, `|` / `|.`-vaktträd och svansrekursion (TCO). Låt oss titta på nyckeldelarna i den faktiska implementationen:

### 29.4.1. Intern implementation: Byte Helpers

Se hur `ws.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
module :: ws

fn :: ws u32 Int => Int
      ws u32 x = ((x % 4294967296) + 4294967296) % 4294967296

fn :: ws byte bxor Int Int => Int
      ws byte bxor a b = (a xor b) and 255
```

### 29.4.2. Intern implementation: Tensor[U8] Byte Helpers

Se hur `ws.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: ws blen Tensor[U8] => Int
      ws blen (Tensor[U8 * n] t) = n

-- Copies n bytes of src (from index from) into dst (from index at); returns dst.
fn :: ws copy range Tensor[U8] Int Tensor[U8] Int Int => Tensor[U8]
      ws copy range src from dst at n =
        | n <= 0 = dst
        | otherwise = ws copy range step src from dst at n

fn :: ws copy range step Tensor[U8] Int Tensor[U8] Int Int => Tensor[U8]
      ws copy range step src from dst at n =
        dst_(at) = src_(from)
        ws copy range src (from + 1) dst (at + 1) (n - 1)

-- Writes n bytes of src (from index from) xor mask_t[moff + (i % 4)] into dst (from index at); returns dst.
fn :: ws mask range Tensor[U8] Int Tensor[U8] Int Int Tensor[U8] Int Int => Tensor[U8]
      ws mask range src from dst at n mask_t moff i =
        | i >= n = dst
        | otherwise = ws mask range step src from dst at n mask_t moff i

fn :: ws mask range step Tensor[U8] Int Tensor[U8] Int Int Tensor[U8] Int Int => Tensor[U8]
      ws mask range step src from dst at n mask_t moff i =
        dst_(at + i) = ws byte bxor src_(from + i) mask_t_(moff + (i % 4))
        ws mask range src from dst at n mask_t moff (i + 1)

fn :: ws put be32 Tensor[U8] Int Int => Tensor[U8]
      ws put be32 t off w =
        uw = ws u32 w
        t_(off) = (uw / 16777216) % 256
        t_(off + 1) = (uw / 65536) % 256
        t_(off + 2) = (uw / 256) % 256
        t_(off + 3) = uw % 256
        t

fn :: ws be32 at Tensor[U8] Int => Int
      ws be32 at t off = (t_(off) * 16777216) + (t_(off + 1) * 65536) + (t_(off + 2) * 256) + t_(off + 3)
```

### 29.4.3. Intern implementation: Base64 for the RFC 6455 Handshake (SHA-1 is crypto's `sha1 bytes`)

Se hur `ws.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: ws b64 lut Int => String
      ws b64 lut _ = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

fn :: ws b64 code String Int => Int
      ws b64 code tbl idx = str char at tbl (((idx % 64) + 64) % 64)

-- Standard Base64 (RFC 4648 §4) with '=' padding.
fn :: ws b64 enc Tensor[U8] => String
      ws b64 enc bs =
        n = ws blen bs
        out = Tensor[U8 * (((n + 2) / 3) * 4)]
        ws b64 enc loop bs n out (ws b64 lut 0) 0 0 -> tensor to str

fn :: ws b64 enc loop Tensor[U8] Int Tensor[U8] String Int Int => Tensor[U8]
      ws b64 enc loop bs n out tbl i o =
        | i >= n = out
        | (n - i) == 1 = ws b64 enc tail1 bs out tbl i o
        | (n - i) == 2 = ws b64 enc tail2 bs out tbl i o
        | otherwise = ws b64 enc group bs n out tbl i o

fn :: ws b64 enc group Tensor[U8] Int Tensor[U8] String Int Int => Tensor[U8]
      ws b64 enc group bs n out tbl i o =
        v = (bs_(i) * 65536) + (bs_(i + 1) * 256) + bs_(i + 2)
        out_(o) = ws b64 code tbl (v / 262144)
        out_(o + 1) = ws b64 code tbl ((v / 4096) % 64)
        out_(o + 2) = ws b64 code tbl ((v / 64) % 64)
        out_(o + 3) = ws b64 code tbl (v % 64)
        ws b64 enc loop bs n out tbl (i + 3) (o + 4)

fn :: ws b64 enc tail1 Tensor[U8] Tensor[U8] String Int Int => Tensor[U8]
      ws b64 enc tail1 bs out tbl i o =
        b0 = bs_(i)
        out_(o) = ws b64 code tbl (b0 / 4)
        out_(o + 1) = ws b64 code tbl ((b0 % 4) * 16)
        out_(o + 2) = 61
        out_(o + 3) = 61
        out

fn :: ws b64 enc tail2 Tensor[U8] Tensor[U8] String Int Int => Tensor[U8]
      ws b64 enc tail2 bs out tbl i o =
        v = (bs_(i) * 256) + bs_(i + 1)
        out_(o) = ws b64 code tbl (v / 1024)
        out_(o + 1) = ws b64 code tbl ((v / 16) % 64)
        out_(o + 2) = ws b64 code tbl ((v % 16) * 4)
        out_(o + 3) = 61
        out

fn :: ws accept key String => String
      ws accept key client_key =
        (client_key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11") -> sha1 bytes -> tensor from str -> ws b64 enc

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

### 29.4.4. Intern implementation: RFC 6455 XOR Masking & Frame Encoding / Decoding

Se hur `ws.ridgun` deklarerar explicita `fn :: ... => ...`-kontrakt först och löser varje fall genom linjerade ekvationer och svansanrop:

```ridgun
fn :: ws mask bytes Tensor[U8] Tensor[U8] => Tensor[U8]
      ws mask bytes payload mask_key =
        n = ws blen payload
        out = Tensor[U8 * n]
        ws mask bytes into payload mask_key out n

fn :: ws mask bytes into Tensor[U8] Tensor[U8] Tensor[U8] Int => Tensor[U8]
      ws mask bytes into payload mask_key out n =
        | (ws blen mask_key) < 4 = ws copy range payload 0 out 0 n
        | otherwise = ws mask range payload 0 out 0 n mask_key 0 0

fn :: ws fin bit Bool => Int
      ws fin bit True = 128
      ws fin bit False = 0

-- Bytes of the extended payload length field: 0 (7-bit), 2 (16-bit) or 8 (64-bit).
fn :: ws len ext size Int => Int
      ws len ext size plen =
        | plen < 126 = 0
        | plen < 65536 = 2
        | otherwise = 8

-- Writes byte 1 (mask bit + length code) and the extended length field.
fn :: ws put len Tensor[U8] Int Int Int => Tensor[U8]
      ws put len out plen mask_bit ext =
        | ext == 0 = ws put len7 out (mask_bit + plen)
        | ext == 2 = ws put len16 out plen mask_bit
        | otherwise = ws put len64 out plen mask_bit

fn :: ws put len7 Tensor[U8] Int => Tensor[U8]
      ws put len7 out b1 =
        out_(1) = b1
        out

fn :: ws put len16 Tensor[U8] Int Int => Tensor[U8]
      ws put len16 out plen mask_bit =
        out_(1) = mask_bit + 126
        out_(2) = (plen / 256) % 256
        out_(3) = plen % 256
        out

fn :: ws put len64 Tensor[U8] Int Int => Tensor[U8]
      ws put len64 out plen mask_bit =
        out_(1) = mask_bit + 127
        out -> ws put be32 2 (plen / 4294967296) -> ws put be32 6 (plen % 4294967296)

fn :: ws encode frame Bool Int Tensor[U8] Tensor[U8] => Tensor[U8]
      ws encode frame fin opcode mask_key payload =
        b0 = (ws fin bit fin) + (((opcode % 16) + 16) % 16)
        has_mask = (ws blen mask_key) >= 4
        ws encode frame with mask b0 has_mask mask_key payload

fn :: ws encode frame with mask Int Bool Tensor[U8] Tensor[U8] => Tensor[U8]
      ws encode frame with mask b0 False _ payload =
        plen = ws blen payload
        ext = ws len ext size plen
        out = Tensor[U8 * (2 + ext + plen)]
        out_(0) = b0
        with_len = ws put len out plen 0 ext
        ws copy range payload 0 with_len (2 + ext) plen
      ws encode frame with mask b0 True mask_key payload =
        plen = ws blen payload
        ext = ws len ext size plen
        hdr = 2 + ext
        out = Tensor[U8 * (hdr + 4 + plen)]
        out_(0) = b0
        with_len = ws put len out plen 128 ext
        with_mask = ws copy range mask_key 0 with_len hdr 4
        ws mask range payload 0 with_mask (hdr + 4) plen mask_key 0 0

fn :: ws encode text String => Tensor[U8]
      ws encode text text = ws encode frame True 1 (Tensor[U8 * 0]) (tensor from str text)

fn :: ws encode masked text String Tensor[U8] => Tensor[U8]
      ws encode masked text text mask_key = ws encode frame True 1 mask_key (tensor from str text)

fn :: ws encode ping Tensor[U8] => Tensor[U8]
      ws encode ping payload = ws encode frame True 9 (Tensor[U8 * 0]) payload

fn :: ws encode pong Tensor[U8] => Tensor[U8]
      ws encode pong payload = ws encode frame True 10 (Tensor[U8 * 0]) payload

fn :: ws encode close Int => Tensor[U8]
      ws encode close code =
        payload = Tensor[U8 * 2]
        payload_(0) = (((code / 256) % 256) + 256) % 256
        payload_(1) = ((code % 256) + 256) % 256
        ws encode frame True 8 (Tensor[U8 * 0]) payload

fn :: ws decode frame Tensor[U8] => WsRes
      ws decode frame wire =
        total = ws blen wire
        ws decode check min wire total

fn :: ws decode check min Tensor[U8] Int => WsRes
      ws decode check min wire total =
        | total < 2 = WsErr "truncated WebSocket frame header (< 2 bytes)"
        | otherwise = ws decode len wire total wire_(0) wire_(1)

fn :: ws decode len Tensor[U8] Int Int Int => WsRes
      ws decode len wire total b0 b1 =
        fin = (b0 / 128) == 1
        opcode = b0 % 16
        masked = (b1 / 128) == 1
        len7 = b1 % 128
        ws decode ext len wire total fin opcode masked len7

fn :: ws decode ext len Tensor[U8] Int Bool Int Bool Int => WsRes
      ws decode ext len wire total fin opcode masked len7 =
        | len7 < 126 = ws decode body wire total fin opcode masked len7 2
        | len7 == 126 and total < 4 = WsErr "truncated 16-bit extended payload length"
        | len7 == 126 = ws decode body wire total fin opcode masked ((wire_(2) * 256) + wire_(3)) 4
        | total < 10 = WsErr "truncated 64-bit extended payload length"
        | wire_(2) >= 128 = WsErr "invalid 64-bit extended payload length (most significant bit set)"
        | otherwise = ws decode body wire total fin opcode masked (((ws be32 at wire 2) * 4294967296) + (ws be32 at wire 6)) 10

fn :: ws decode body Tensor[U8] Int Bool Int Bool Int Int => WsRes
      ws decode body wire total fin opcode True plen hdr_off =
        | (total - hdr_off - 4) < plen = WsErr "truncated masked WebSocket frame payload"
        | otherwise = ws finish frame fin opcode True (ws mask range wire (hdr_off + 4) (Tensor[U8 * plen]) 0 plen wire hdr_off 0) (hdr_off + 4 + plen)
      ws decode body wire total fin opcode False plen hdr_off =
        | (total - hdr_off) < plen = WsErr "truncated unmasked WebSocket frame payload"
        | otherwise = ws finish frame fin opcode False (ws copy range wire hdr_off (Tensor[U8 * plen]) 0 plen) (hdr_off + plen)

fn :: ws finish frame Bool Int Bool Tensor[U8] Int => WsRes
      ws finish frame fin opcode masked unmasked consumed =
        | opcode == 1 = WsOk (WsFrame fin opcode masked unmasked (tensor to str unmasked)) consumed
        | otherwise = WsOk (WsFrame fin opcode masked unmasked "") consumed
```

---

## 29.5. Algoritmiska garantier, `RMM1`/`RMM2`-minne och de 5 Gyllene Reglerna för `ws`

- **Algoritmisk garanti och säkerhet**: Exakt matchning med den officiella testvektorn i RFC 6455 (`"dGhlIHNhbXBsZSBub25jZQ=="` $\rightarrow$ `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="`) och automatisk XOR-avmaskering i `ws decode frame`.
- **$O(1)$ stackkomplexitet med TCO**: Alla rekursiva loopar i `src/main/ridgun/lib/ws.ridgun` ligger i svansposition, så `ridgunc` kompilerar dem till inbyggda hopp utan stacktillväxt.
- **Deterministiskt minne (`RMM1`/`RMM2`)**: Noll skräpsamlarpauser; alla temporära strukturer frigörs deterministiskt när räckvidden lämnas.
- **Kontinuerlig verifiering**: Statiskt kontrollerad med `stable check` och verifierad av den automatiserade testsviten `src/test/ridgun/test ws.ridgun`.

### De 5 Gyllene Reglerna när du programmerar med `ws`

1. **Deklarera `import ws` överst i filen** och anropa dess funktioner med mellanslag, precis som de är deklarerade, så att koden läses som naturlig prosa.
2. **Linjera dina datapipelines med `=`**: kedja samman `ws`-anrop i namngivna mellansteg och låt `stable format` linjera kolumnerna.
3. **Utnyttja `ws`:s totala funktioner i dina `|`-vakter**: kontrollera returvärden eller packa upp ADT:er med mönstermatchning i stället för att anta att extern indata alltid är giltig.
4. **Undvik att kopiera stora strukturer när du bara läser ett fält**: kom ihåg att i `RMM2` medför inargument noll referensräkningskostnad (`+0` / `-0`).
5. **Kombinera `ws` med `test` (`import test`)**: lås alltid fast dina domäninvarianter med `assert equals` eller `assert true`.

---

I **Kapitel 30** går vi vidare och utforskar lib:en **`agent`** på djupet (Lib:en `agent` — Inbyggd Aktörskonkurrens (`agent`, `send`, `receive`), Fråga-svar-kombinatorer samt Räknar-, Logg- och Nyckel-värde-agenter).
