-- ============================================================
-- src/test/ridgun/test ws.rg
-- Comprehensive test suite for ws.rg inspired by tungstenite & RFC 6455 Section 4.2.2 & 5.7
-- @tests TS-WS-001
-- ============================================================

import test
import ws

fn :: is ws ok WsRes      => Bool
      is ws ok (WsOk _ _) =  True
      is ws ok (WsErr _)  =  False

fn :: unwrap ws frame WsRes      => WsFrame
      unwrap ws frame (WsOk f _) =  f
      unwrap ws frame (WsErr _)  =  WsFrame False 0 False (Tensor[U8 * 0]) ""

fn :: unwrap ws len WsRes      => Int
      unwrap ws len (WsOk _ n) =  n
      unwrap ws len (WsErr _)  =  0

fn :: ws repeat str String Int => String
      ws repeat str _      0   =  ""
      ws repeat str s      n   =  s + (ws repeat str s (n - 1))

fn :: ws int list len [Int] Int => Int
      ws int list len []     acc = acc
      ws int list len (_:xs) acc = ws int list len xs (acc + 1)

-- Builds a Tensor[U8] from a list literal of bytes (ADR-0010).
fn :: ws bytes of [Int] => Tensor[U8]
      ws bytes of xs =
        t = Tensor[U8 * (ws int list len xs 0)]
        ws bytes fill t 0 xs

fn :: ws bytes fill Tensor[U8] Int [Int] => Tensor[U8]
      ws bytes fill t _ []      = t
      ws bytes fill t i (x:xs)  = ws bytes fill step t i x xs

fn :: ws bytes fill step Tensor[U8] Int Int [Int] => Tensor[U8]
      ws bytes fill step t i x xs =
        t_(i) = x
        ws bytes fill t (i + 1) xs

-- Byte i of the large payload is i % 256, so it holds 0, 128 and 255.
fn :: ws big payload Int => Tensor[U8]
      ws big payload n =
        t = Tensor[U8 * n]
        ws big fill t 0 n

fn :: ws big fill Tensor[U8] Int Int => Tensor[U8]
      ws big fill t i n =
        | i >= n = t
        | otherwise = ws big fill step t i n

fn :: ws big fill step Tensor[U8] Int Int => Tensor[U8]
      ws big fill step t i n =
        t_(i) = i % 256
        ws big fill t (i + 1) n

fn :: ws bytes eq Tensor[U8] [Int] => Bool
      ws bytes eq t xs = ws int list eq (tensor to list t) xs

fn :: ws int list eq [Int] [Int] => Bool
      ws int list eq [] [] = True
      ws int list eq (a:as) (b:bs)
        | a == b = ws int list eq as bs
        | otherwise = False
      ws int list eq _ _ = False

-- 1. RFC 6455 Section 4.2.2 Handshake Test Vector
-- @tests TS-WS-001
fn :: test ws rfc6455 handshake => ()
      test ws rfc6455 handshake =
        rfc_key = "dGhlIHNhbXBsZSBub25jZQ=="
        accept = ws accept key rfc_key
        _ = assert str eq accept "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=" "AC1: RFC 6455 Sec-WebSocket-Accept test vector"

        req = ws build upgrade request "chat.example.com" "/ws" rfc_key
        _ = assert true (str contains req "GET /ws HTTP/1.1") "AC1: upgrade request line"
        _ = assert true (str contains req "Host: chat.example.com") "AC1: upgrade request Host header"
        _ = assert true (str contains req "Upgrade: websocket") "AC1: upgrade request Upgrade header"
        _ = assert true (str contains req "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==") "AC1: upgrade request contains key"

        resp = ws build upgrade response rfc_key
        _ = assert true (str contains resp "101 Switching Protocols") "AC1: upgrade response status 101"
        _ = assert true (str contains resp "Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=") "AC1: upgrade response contains accept digest"
        ()

-- 2. RFC 6455 Section 5.7 Exact Wire Byte Vectors ("Hello" unmasked & masked, empty frame, 125B vs 126B boundary)
-- @tests TS-WS-001
fn :: test ws framing and masking => ()
      test ws framing and masking =
        -- RFC 6455 Section 5.7 Example 1: single-frame unmasked text "Hello" -> [0x81, 0x05, 0x48, 0x65, 0x6c, 0x6c, 0x6f]
        w_hello = ws encode text "Hello"
        _ = assert true (ws bytes eq w_hello [129, 5, 72, 101, 108, 108, 111]) "AC2: RFC 6455 5.7 unmasked 'Hello' wire bytes"
        r_hello = ws decode frame w_hello
        _ = assert true (is ws ok r_hello) "AC2: decode RFC 6455 unmasked 'Hello'"
        _ = assert str eq (payload_text (unwrap ws frame r_hello)) "Hello" "AC2: decoded 'Hello' text"
        _ = assert int equals (unwrap ws len r_hello) 7 "AC2: consumed 7 bytes"

        -- RFC 6455 Section 5.7 Example 2: single-frame masked text "Hello" with mask [0x37, 0xfa, 0x21, 0x3d]
        mask_rfc = ws bytes of [55, 250, 33, 61]
        w_mhello = ws encode masked text "Hello" mask_rfc
        _ = assert true (ws bytes eq w_mhello [129, 133, 55, 250, 33, 61, 127, 159, 77, 81, 88]) "AC2: RFC 6455 5.7 masked 'Hello' wire bytes"
        r_mhello = ws decode frame w_mhello
        _ = assert true (is ws ok r_mhello) "AC2: decode RFC 6455 masked 'Hello'"
        f_mhello = unwrap ws frame r_mhello
        _ = assert true (is_masked f_mhello) "AC2: masked frame is_masked=true"
        _ = assert str eq (payload_text f_mhello) "Hello" "AC2: XOR unmasked text matches 'Hello'"
        _ = assert int equals (unwrap ws len r_mhello) 11 "AC2: consumed 11 bytes"

        -- Empty payload frame (0 bytes)
        w_empty = ws encode text ""
        r_empty = ws decode frame w_empty
        _ = assert true (is ws ok r_empty) "AC2: decode empty text frame"
        _ = assert str eq (payload_text (unwrap ws frame r_empty)) "" "AC2: empty payload_text"
        _ = assert int equals (unwrap ws len r_empty) 2 "AC2: 2-byte header for empty unmasked frame"

        -- Boundary length 125 (max 7-bit length) vs 126 (min 16-bit extended length)
        msg_125 = ws repeat str "A" 125
        w_125 = ws encode text msg_125
        r_125 = ws decode frame w_125
        _ = assert int equals (unwrap ws len r_125) 127 "AC2: 125B payload uses 2B header (127 total)"
        _ = assert str eq (payload_text (unwrap ws frame r_125)) msg_125 "AC2: 125B payload round-trips"

        msg_126 = ws repeat str "B" 126
        w_126 = ws encode masked text msg_126 mask_rfc
        r_126 = ws decode frame w_126
        _ = assert int equals (unwrap ws len r_126) 134 "AC2: 126B masked payload uses 4B hdr + 4B mask + 126B (134 total)"
        _ = assert str eq (payload_text (unwrap ws frame r_126)) msg_126 "AC2: 126B payload round-trips"

        -- Control frames: Ping (9), Pong (10), Close (8)
        w_ping = ws encode ping (ws bytes of [1, 2, 3])
        f_ping = unwrap ws frame (ws decode frame w_ping)
        _ = assert int equals (ws_opcode f_ping) 9 "AC2: ping opcode=9"
        _ = assert true (ws bytes eq (payload_bytes f_ping) [1, 2, 3]) "AC2: ping payload bytes"

        w_pong = ws encode pong (ws bytes of [4, 5])
        f_pong = unwrap ws frame (ws decode frame w_pong)
        _ = assert int equals (ws_opcode f_pong) 10 "AC2: pong opcode=10"

        w_close = ws encode close 1000
        f_close = unwrap ws frame (ws decode frame w_close)
        _ = assert int equals (ws_opcode f_close) 8 "AC2: close opcode=8"
        _ = assert true (ws bytes eq (payload_bytes f_close) [3, 232]) "AC2: close code 1000 big-endian [0x03, 0xE8]"
        ()

-- 3. Truncated / adversarial frame headers and payloads rejection
-- @tests TS-WS-001
fn :: test ws truncated frames => ()
      test ws truncated frames =
        _ = assert false (is ws ok (ws decode frame (ws bytes of []))) "AC3: reject 0-byte empty buffer"
        _ = assert false (is ws ok (ws decode frame (ws bytes of [129]))) "AC3: reject 1-byte truncated header"
        _ = assert false (is ws ok (ws decode frame (ws bytes of [129, 10, 65, 66]))) "AC3: reject truncated unmasked payload"
        _ = assert false (is ws ok (ws decode frame (ws bytes of [129, 126, 0]))) "AC3: reject truncated 16-bit extended header"
        _ = assert false (is ws ok (ws decode frame (ws bytes of [129, 130, 1, 2]))) "AC3: reject truncated 4-byte masking key"
        _ = assert false (is ws ok (ws decode frame (ws bytes of [129, 133, 55, 250, 33, 61, 127, 159]))) "AC3: reject truncated masked payload"
        _ = assert false (is ws ok (ws decode frame (ws bytes of [130, 127, 0, 0, 0, 0, 0]))) "AC3: reject truncated 64-bit extended header"
        _ = assert false (is ws ok (ws decode frame (ws bytes of [130, 127, 128, 0, 0, 0, 0, 0, 0, 1, 65]))) "AC3: reject 64-bit length with the most significant bit set"
        _ = assert false (is ws ok (ws decode frame (ws bytes of [130, 127, 0, 0, 0, 0, 0, 1, 17, 112, 65]))) "AC3: reject truncated 64-bit length payload"
        ()

-- 4. 64-bit extended length: 70,000-byte binary payload holding bytes 0, 128 and 255, unmasked and masked
-- @tests TS-WS-001
fn :: test ws large frame round trip => ()
      test ws large frame round trip =
        big = ws big payload 70000
        _ = assert int equals big_(128) 128 "AC2: large payload holds byte 128"
        _ = assert int equals big_(255) 255 "AC2: large payload holds byte 255"
        w_big = ws encode frame True 2 (Tensor[U8 * 0]) big
        _ = assert int equals w_big_(1) 127 "AC2: 70000B unmasked payload uses the 64-bit length code 127"
        _ = assert true (ws int list eq [w_big_(2), w_big_(3), w_big_(4), w_big_(5), w_big_(6), w_big_(7), w_big_(8), w_big_(9)] [0, 0, 0, 0, 0, 1, 17, 112]) "AC2: 64-bit big-endian length 70000"
        r_big = ws decode frame w_big
        _ = assert true (is ws ok r_big) "AC2: decode 70000B unmasked frame"
        _ = assert int equals (unwrap ws len r_big) 70010 "AC2: consumed 10B header + 70000B"
        _ = assert true ((payload_bytes (unwrap ws frame r_big)) == big) "AC2: 70000B unmasked payload round-trips byte for byte"

        mask_k = ws bytes of [0, 128, 255, 61]
        w_mbig = ws encode frame False 2 mask_k big
        _ = assert int equals w_mbig_(1) 255 "AC2: 70000B masked payload sets MASK and length code 127"
        r_mbig = ws decode frame w_mbig
        _ = assert true (is ws ok r_mbig) "AC2: decode 70000B masked frame"
        f_mbig = unwrap ws frame r_mbig
        _ = assert false (is_fin f_mbig) "AC2: large masked frame keeps FIN=0"
        _ = assert true (is_masked f_mbig) "AC2: large masked frame is_masked=true"
        _ = assert int equals (unwrap ws len r_mbig) 70014 "AC2: consumed 10B header + 4B mask + 70000B"
        _ = assert true ((payload_bytes f_mbig) == big) "AC2: 70000B masked payload round-trips byte for byte"
        ()

-- @tests TS-WS-001
fn :: main => ()
      main =
        _ = test ws rfc6455 handshake
        _ = test ws framing and masking
        _ = test ws truncated frames
        _ = test ws large frame round trip
        echo "[PASS] test ws: TS-WS-001 passed"
