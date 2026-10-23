-- ============================================================
-- src/test/ridgun/test ws.rg
-- Automated unit tests for ws.rg (RFC 6455 WebSocket Handshake & Framing)
-- @tests TS-WS-001
-- ============================================================

import test
import ws

fn :: is_ws_ok WsRes      => Bool
      is_ws_ok (WsOk _ _) =  True
      is_ws_ok (WsErr _)  =  False

fn :: unwrap_ws_frame WsRes      => WsFrame
      unwrap_ws_frame (WsOk f _) =  f
      unwrap_ws_frame (WsErr _)  =  WsFrame False 0 False [] ""

fn :: unwrap_ws_len WsRes      => Int
      unwrap_ws_len (WsOk _ n) =  n
      unwrap_ws_len (WsErr _)  =  0

fn :: ws_repeat_str String Int => String
      ws_repeat_str _      0   =  ""
      ws_repeat_str s      n   =  s + (ws_repeat_str s (n - 1))

-- @tests TS-WS-001
fn :: test_ws_rfc6455_handshake => ()
      test_ws_rfc6455_handshake =
        rfc_key = "dGhlIHNhbXBsZSBub25jZQ=="
        accept = ws accept key rfc_key
        _ = assert str eq accept "s3pPLMBiTxaQ9kYGzzhZRbK+xOo=" "AC1: RFC 6455 Sec-WebSocket-Accept test vector"

        req = ws build upgrade request "chat.example.com" "/ws" rfc_key
        _ = assert true (str_contains req "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==") "AC1: upgrade request contains key"

        resp = ws build upgrade response rfc_key
        _ = assert true (str_contains resp "101 Switching Protocols") "AC1: upgrade response status 101"
        _ = assert true (str_contains resp "Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=") "AC1: upgrade response contains accept digest"
        ()

-- @tests TS-WS-001
fn :: test_ws_framing_and_masking => ()
      test_ws_framing_and_masking =
        w_txt = ws encode text "Hello WebSocket!"
        r_txt = ws decode frame w_txt
        _ = assert true (is_ws_ok r_txt) "AC2: decode unmasked text frame"
        f_txt = unwrap_ws_frame r_txt
        _ = assert true (is_fin f_txt) "AC2: text frame FIN=true"
        _ = assert int equals (ws_opcode f_txt) 1 "AC2: text frame opcode=1"
        _ = assert false (is_masked f_txt) "AC2: unmasked text frame is_masked=false"
        _ = assert str eq (payload_text f_txt) "Hello WebSocket!" "AC2: decoded payload_text matches"
        _ = assert int equals (unwrap_ws_len r_txt) 18 "AC2: consumed 2 + 16 = 18 bytes"

        mask4 = [55, 250, 33, 61]
        w_mtxt = ws encode masked text "Masked Ridgun Payload" mask4
        r_mtxt = ws decode frame w_mtxt
        _ = assert true (is_ws_ok r_mtxt) "AC2: decode masked text frame"
        f_mtxt = unwrap_ws_frame r_mtxt
        _ = assert true (is_masked f_mtxt) "AC2: masked frame is_masked=true"
        _ = assert str eq (payload_text f_mtxt) "Masked Ridgun Payload" "AC2: XOR unmasked text matches original"

        long_msg = ws_repeat_str "0123456789" 14
        w_long = ws encode masked text long_msg mask4
        r_long = ws decode frame w_long
        _ = assert true (is_ws_ok r_long) "AC2: decode 140-byte 16-bit extended length masked frame"
        _ = assert str eq (payload_text (unwrap_ws_frame r_long)) long_msg "AC2: 140-byte payload round-trips"
        _ = assert int equals (unwrap_ws_len r_long) 148 "AC2: 4 hdr + 4 mask + 140 payload = 148 bytes"

        w_ping = ws encode ping [1, 2, 3]
        f_ping = unwrap_ws_frame (ws decode frame w_ping)
        _ = assert int equals (ws_opcode f_ping) 9 "AC2: ping opcode=9"

        w_pong = ws encode pong [1, 2, 3]
        f_pong = unwrap_ws_frame (ws decode frame w_pong)
        _ = assert int equals (ws_opcode f_pong) 10 "AC2: pong opcode=10"

        w_close = ws encode close 1000
        f_close = unwrap_ws_frame (ws decode frame w_close)
        _ = assert int equals (ws_opcode f_close) 8 "AC2: close opcode=8"
        ()

-- @tests TS-WS-001
fn :: test_ws_truncated_frames => ()
      test_ws_truncated_frames =
        _ = assert false (is_ws_ok (ws decode frame [129])) "AC3: reject 1-byte truncated header"
        _ = assert false (is_ws_ok (ws decode frame [129, 10, 65, 66])) "AC3: reject truncated payload"
        _ = assert false (is_ws_ok (ws decode frame [129, 126, 0])) "AC3: reject truncated 16-bit extended header"
        ()

-- @tests TS-WS-001
fn :: main => ()
      main =
        _ = test_ws_rfc6455_handshake
        _ = test_ws_framing_and_masking
        _ = test_ws_truncated_frames
        echo "[PASS] test ws: TS-WS-001 passed"
