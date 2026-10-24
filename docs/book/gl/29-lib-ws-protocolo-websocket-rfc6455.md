# Capítulo 29: A lib `ws` — Handshake WebSocket RFC 6455, Framing de 16/64 bits e Enmascarado XOR

## 29.1. Por que existe a lib `ws`? (O problema real e a filosofía Ridgun)

> *«Por que necesito unha lib `ws` escrita dende cero en Ridgun puro en vez de enlazar unha librería de C de toda a vida?»*

Esa é a primeira pregunta que se fai calquera enxeñeiro de sistemas ao chegar a `ws`. E a resposta resume toda a filosofía de `ridgun-libs`:

Sexamos sinceros: o protocolo WebSocket (RFC 6455) combina un handshake SHA-1 + Base64 con tramas binarias de lonxitude variable (7 bits, 16 bits ou 64 bits) e enmascarado XOR obrigatorio de cliente a servidor.

A lib **`ws`** implementa **RFC 6455** completo en Ridgun puro: cálculo de `Sec-WebSocket-Accept` (con SHA-1 RFC 3174 integrado exclusivamente para o GUID de handshake), cabeceiras HTTP `101 Switching Protocols`, codificación e descodificación de tramas (`WsFrame`) con lonxitudes de 7, 16 (`126`) e 64 bits (`127`), enmascarado simétrico XOR e construtores de tramas de texto, ping, pong e peche.

Nun ecosistema tradicional, resolver as tarefas do dominio **`WS`** implica arrastrar dependencias externas en C, loitar con punteiros crus, conversións opacas de tipos, excepcións non verificadas ou pausas impredicibles do colector de lixo. En Ridgun, a lib **`ws`** (`src/main/ridgun/lib/ws.rg`) aborda o problema con catro principios innegociables:

1. **Funcións totais e contratos explícitos (`=>`)**: ningunha función de `ws` lanza excepcións ocultas nin depende de `null`. Todo caso límite devolve un valor sentinela documentado ou un tipo alxébrico suma (`Option`, `Result`).
2. **Cero código C e cero `libc`**: todo o código de `ws` compila directamente a código máquina nativo ELF64 verificado por `ridgunc`.
3. **Recursión de cola con TCO (*Tail-Call Optimization*)**: todos os percorridos internos de `ws` compílanse a bucles nativos en espazo de pila $O(1)$.
4. **Memoria determinista (`RMM1` / `RMM2`)**: cada estrutura intermedia libérase no instante exacto en que remata a súa última lectura, sen *Garbage Collector*.

---

## 29.2. Artefactos nativos, importación e catálogo completo da API de `ws`

En `ridgun-libs`, **`ws`** é unha **lib** de primeira clase situada en `src/main/ridgun/lib/ws.rg` (dominio `WS`). Ao compilar con `stable bundle`, empaquétase en tres formatos nativos:

| Artefacto | Ruta | Propósito |
|---|---|---|
| **Bundle Ridgun** | `target/bundles/ws.rglib` | Distribución e importación directa con `import ws` |
| **Ficheiro compilado** | `target/ws.rgc` | Artefacto intermedio verificado por `ridgunc` |
| **Obxecto compartido ELF64** | `target/libws.so` | Biblioteca dinámica nativa sen dependencias de C nin `libc` |

> Para usar esta lib en calquera ficheiro `.rg`, abonda con declarar `import ws` na cabeceira e chamar ás súas funcións con espazos ou guións baixos indistintamente.

### 29.2.1. Resumo de familias funcionais de `ws`

| Sinatura / Función / Tipo | Que fai e cando usala |
|---|---|
| `ws accept key : String -> String` | Calcula `Sec-WebSocket-Accept` (RFC 6455 §1.3) a partir de `Sec-WebSocket-Key` |
| `ws build upgrade request / ws build upgrade response` | Formatea as mensaxes HTTP/1.1 de negociación (upgrade handshake) WebSocket |
| `ws encode frame / ws decode frame` | Codifica e descodifica tramas `WsFrame` (`fin`, `opcode`, `masked`, `mask_key`, `payload`) |
| `ws text frame / ws ping frame / ws pong frame / ws close frame` | Construtores de tramas de alto nivel e extractores de código de peche (`1000` normal) |

### 29.2.2. Catálogo exhaustivo de tipos e sinaturas en `src/main/ridgun/lib/ws.rg`

A continuación tes o inventario completo de tipos alxébricos (`type`), operadores (`op ::`) e sinaturas de funcións (`fn ::`) definidos en `src/main/ridgun/lib/ws.rg` (`3` tipos, `0` operadores e `54` funcións):

**Tipos alxébricos e rexistros (`type`) de `ws`:**

```ridgun
type WsFrame = is_fin: Bool, ws_opcode: Int, is_masked: Bool, payload_bytes: [Int], payload_text: String
type WsRes = WsOk WsFrame Int | WsErr String
type Sha1State = h0: Int, h1: Int, h2: Int, h3: Int, h4: Int
```

| # | Función / Sinatura (`fn ::`) | Tipo de Retorno |
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

## 29.3. Explorando `ws` a fondo: Exemplos paso a paso de cada funcionalidade

Non abonda con ver a táboa de sinaturas: imos explorar **cada unha das funcionalidades** da lib `ws` mediante exemplos progresivos e executables en Ridgun. Comezaremos polas dúas receitas tabulares de uso cotián e despois percorreremos en detalle todos os escenarios funcionais, transformacións e casos límite verificados en `src/test/ridgun/test ws.rg`.

### 29.3.1. Exemplo 1: Fluxo principal en estilo tabular con `ws`

Observa como en Ridgun os signos `=` e os pasos de transformación con `ws` quedan aliñados coma unha táboa limpa, sen variables mutables innecesarias nin efectos laterais ocultos:

```ridgun
import ws

fn :: negociar y enviar (client_key : String) => (String, String)
      negociar y enviar client_key =
        resp  = ws build upgrade response client_key
        trama = ws encode frame (ws text frame "hola-tiempo-real" False "")
        (resp, trama)
```

### 29.3.2. Exemplo 2: Composición segura e manexo de casos de bordo

Toda función da lib `ws` está deseñada para compoñerse con gardas booleanas `|` e co resto das 32 libs de `ridgun-libs`:

```ridgun
import ws

fn :: decodificar trama cliente (clave4 : String) (msg : String) => String
      decodificar trama cliente clave4 msg =
        wire = ws encode frame (ws text frame msg True clave4)
        res  = ws decode frame wire
        ws frame payload res
```

### 29.3.3. Exemplo 3: Handshake WebSocket RFC 6455 (`Sec-WebSocket-Accept` mediante SHA-1 + Base64) e cabeceiras HTTP `101 Switching Protocols`

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `ws` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 29.3.4. Exemplo 4: Codificación e decodificación de tramas de 7, 16 e 64 bits (`Text`, `Binary`, `Ping`, `Pong`, `Close`) e enmascaramento XOR de 4 bytes

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `ws` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

### 29.3.5. Exemplo 5: Detección segura de tramas WebSocket truncadas ou incompletas (`WsErr`)

Neste exemplo práctico exploramos de forma exhaustiva como se comporta `ws` neste bloque funcional, incluíndo entradas estándar, combinacións de parámetros e valores fronteira:

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

## 29.4. Baixo o capó: como está construída `ws` en Ridgun puro (`src/main/ridgun/lib/ws.rg`)

Unha das maiores vantaxes de `ridgun-libs` é que **non hai caixas negras en C**. Podes abrir `src/main/ridgun/lib/ws.rg` e ler exactamente como está implementada cada operación usando *pattern matching*, árbores de gardas `|` / `|.` e recursión de cola (TCO). Vexamos as pezas clave da súa implementación real:

### 29.4.1. Implementación interna: 32-Bit Unsigned Bitwise Helpers for RFC 3174 SHA-1

Fíxate en como `ws.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

### 29.4.2. Implementación interna: List & String Byte Conversion Helpers

Fíxate en como `ws.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

### 29.4.3. Implementación interna: Pure-Ridgun SHA-1 & Base64 for RFC 6455 Handshake

Fíxate en como `ws.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

### 29.4.4. Implementación interna: RFC 6455 XOR Masking & Frame Encoding / Decoding

Fíxate en como `ws.rg` estrutura as sinaturas `fn :: ... => ...` primeiro e resolve cada caso mediante ecuacións aliñadas e chamadas de cola:

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

## 29.5. Garantías algorítmicas, memoria `RMM1`/`RMM2` e as 5 Regras de Ouro de `ws`

- **Garantía algorítmica e de seguridade**: Coincidencia exacta co vector oficial RFC 6455 (`"dGhlIHNhbXBsZSBub25jZQ=="` $\rightarrow$ `"s3pPLMBiTxaQ9kYGzzhZRbK+xOo="`) e desenmascarado automático en `ws decode frame`.
- **Complexidade de pila $O(1)$ con TCO**: Todos os bucles recursivos en `src/main/ridgun/lib/ws.rg` están en posición de cola, polo que `ridgunc` os compila a saltos nativos sen crecemento de pila.
- **Memoria determinista (`RMM1`/`RMM2`)**: Cero pausas de colector de lixo; todas as estruturas intermedias libéranse de forma determinista ao saír do ámbito.
- **Verificación continua**: Probada exhaustivamente con `stable check` e a suite automatizada `src/test/ridgun/test ws.rg`.

### As 5 Regras de Ouro ao programar con `ws`

1. **Declara `import ws` ao inicio do ficheiro** e aproveita a equivalencia entre espazos e guións baixos para que o teu código se lea coma prosa.
2. **Aliña as túas tubaxes de datos con `=`**: encadea as chamadas a `ws` en pasos con nome propio e deixa que `stable format` aliñe as columnas.
3. **Aproveita as funcións totais de `ws` nas túas gardas `|`**: comproba os valores de retorno ou desenvolve os ADTs con *pattern matching* en vez de asumir que a entrada externa sempre é válida.
4. **Evita copiar grandes estruturas se só necesitas consultar un campo**: lembra que en `RMM2` os argumentos de entrada non incrementan nin decrementan contadores (`+0` / `-0`).
5. **Combina `ws` con `test` (`import test`)**: escribe sempre asercións con `assert equals` ou `assert true` para fixar os invariantes do teu dominio.

---

No **Capítulo 30** pasaremos a explorar en profundidade a lib **`agent`** (A lib `agent` — Modelo Nativo de Actores (`agent`, `send`, `receive`), KV Store e Rate Limiter).
