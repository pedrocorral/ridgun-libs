-- ============================================================
-- src/main/ridgun/lib/ws.rg
-- Pure-Ridgun RFC 6455 WebSocket Handshake, Framing & Masking Library (WS)
-- @implements FR-WS-001
-- @implements API-WS-001
-- @implements DM-WebSocket
-- @mitigates VUL-INPUT-001
-- ============================================================

type WsFrame = is_fin: Bool, ws_opcode: Int, is_masked: Bool, payload_bytes: [Int], payload_text: String

type WsRes = WsOk WsFrame Int | WsErr String

type Sha1State = h0: Int, h1: Int, h2: Int, h3: Int, h4: Int

-- ── 32-Bit Unsigned Bitwise Helpers for RFC 3174 SHA-1 ───────

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

-- ── List & String Byte Conversion Helpers ────────────────────

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

-- ── Pure-Ridgun SHA-1 & Base64 for RFC 6455 Handshake ────────

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

fn :: ws_sha1_rounds Sha1State [Int] Int => Sha1State
      ws_sha1_rounds st        w     t
        | t >= 80 = st
        | otherwise = ws_sha1_round_step st w t

fn :: ws_sha1_round_step Sha1State [Int] Int => Sha1State
      ws_sha1_round_step st        w     t   =
        a = h0 st
        b = h1 st
        c = h2 st
        d = h3 st
        e = h4 st
        f = ws_sha1_f t b c d
        k = ws_sha1_k t
        wt = ws_nth w t
        temp = ws_u32 ((ws_rotl32 a 5) + f + e + k + wt)
        ws_sha1_rounds (Sha1State temp a (ws_rotl32 b 30) c d) w (t + 1)

fn :: ws_sha1_blocks Sha1State [Int]  => Sha1State
      ws_sha1_blocks st        []     =  st
      ws_sha1_blocks st        padded =
        blk = ws_take padded 64
        rest = ws_drop padded 64
        w80 = ws_sha1_expand_loop (ws_sha1_w16_loop blk 0 []) 16
        r = ws_sha1_rounds st w80 0
        next_st = Sha1State (ws_u32 ((h0 st) + (h0 r))) (ws_u32 ((h1 st) + (h1 r))) (ws_u32 ((h2 st) + (h2 r))) (ws_u32 ((h3 st) + (h3 r))) (ws_u32 ((h4 st) + (h4 r)))
        ws_sha1_blocks next_st rest

fn :: ws_sha1_bytes String => [Int]
      ws_sha1_bytes s      =
        init_st = Sha1State 1732584193 4023233417 2562383102 271733878 3285377520
        fin = ws_sha1_blocks init_st (ws_sha1_pad (ws_str_to_bytes s))
        ((((ws_u32_be4 (h0 fin)) :: (ws_u32_be4 (h1 fin))) :: (ws_u32_be4 (h2 fin))) :: (ws_u32_be4 (h3 fin))) :: (ws_u32_be4 (h4 fin))

fn :: ws_b64_lut Int => String
      ws_b64_lut _   =  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

fn :: ws_b64_c Int => String
      ws_b64_c idx =
        tbl = ws_b64_lut 0
        i = ((idx % 64) + 64) % 64
        str_slice tbl i (i + 1)

fn :: ws_b64_enc [Int]         => String
      ws_b64_enc []            =  ""
      ws_b64_enc (b0:[])       =  (ws_b64_c (b0 / 4)) + (ws_b64_c ((b0 % 4) * 16)) + "=="
      ws_b64_enc (b0:b1:[])    =
        n = (b0 * 256) + b1
        (ws_b64_c (n / 1024)) + (ws_b64_c ((n / 16) % 64)) + (ws_b64_c ((n % 16) * 4)) + "="
      ws_b64_enc (b0:b1:b2:rs) =
        n = (b0 * 65536) + (b1 * 256) + b2
        (ws_b64_c (n / 262144)) + (ws_b64_c ((n / 4096) % 64)) + (ws_b64_c ((n / 64) % 64)) + (ws_b64_c (n % 64)) + (ws_b64_enc rs)

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws accept key String     => String
      ws accept key client_key =  ws_b64_enc (ws_sha1_bytes (client_key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws build upgrade request String String String => String
      ws build upgrade request host path client_key =
        crlf = (char_from_code 13) + (char_from_code 10)
        "GET " + path + " HTTP/1.1" + crlf + "Host: " + host + crlf + "Upgrade: websocket" + crlf + "Connection: Upgrade" + crlf + "Sec-WebSocket-Key: " + client_key + crlf + "Sec-WebSocket-Version: 13" + crlf + crlf

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws build upgrade response String     => String
      ws build upgrade response client_key =
        crlf = (char_from_code 13) + (char_from_code 10)
        accept = ws_accept_key client_key
        "HTTP/1.1 101 Switching Protocols" + crlf + "Upgrade: websocket" + crlf + "Connection: Upgrade" + crlf + "Sec-WebSocket-Accept: " + accept + crlf + crlf

-- ── RFC 6455 XOR Masking & Frame Encoding / Decoding ─────────

fn :: ws_mask_loop [Int]    [Int]    Int => [Int]
      ws_mask_loop []       _        _   =  []
      ws_mask_loop (b:rest) mask_key idx =  [ws_byte_xor b (ws_nth mask_key (idx % 4))] :: (ws_mask_loop rest mask_key (idx + 1))

-- @implements FR-WS-001
-- @implements API-WS-001
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

-- @implements FR-WS-001
-- @implements API-WS-001
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

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws encode text String => [Int]
      ws encode text text   =  ws_encode_frame True 1 [] (ws_str_to_bytes text)

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws encode masked text String [Int] => [Int]
      ws encode masked text text mask_key = ws_encode_frame True 1 mask_key (ws_str_to_bytes text)

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws encode ping [Int]   => [Int]
      ws encode ping payload =  ws_encode_frame True 9 [] payload

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws encode pong [Int]   => [Int]
      ws encode pong payload =  ws_encode_frame True 10 [] payload

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws encode close Int  => [Int]
      ws encode close code =  ws_encode_frame True 8 [] [(code / 256) % 256, code % 256]

-- @implements FR-WS-001
-- @implements API-WS-001
-- @mitigates VUL-INPUT-001
fn :: ws decode frame [Int] => WsRes
      ws decode frame wire  =
        total = ws_list_len wire
        ws_decode_check_min wire total

fn :: ws_decode_check_min [Int] Int   => WsRes
      ws_decode_check_min wire  total
        | total < 2 = WsErr "truncated WebSocket frame header (< 2 bytes)"
        | otherwise = ws_decode_len wire total (ws_nth wire 0) (ws_nth wire 1)

fn :: ws_decode_len [Int] Int   Int Int => WsRes
      ws_decode_len wire  total b0  b1  =
        fin = (b0 / 128) == 1
        opcode = b0 % 16
        masked = (b1 / 128) == 1
        len7 = b1 % 128
        ws_decode_ext_len wire total fin opcode masked len7

fn :: ws_decode_ext_len [Int] Int Bool Int Bool Int => WsRes
      ws_decode_ext_len wire total fin opcode masked len7
        | len7 < 126 = ws_decode_body wire total fin opcode masked len7 2
        | len7 == 126 AND total < 4 = WsErr "truncated 16-bit extended payload length"
        | len7 == 126 = ws_decode_body wire total fin opcode masked (((ws_nth wire 2) * 256) + (ws_nth wire 3)) 4
        | otherwise = WsErr "unsupported 64-bit extended length"

fn :: ws_decode_body [Int] Int Bool Int Bool Int Int => WsRes
      ws_decode_body wire total fin opcode True plen hdr_off
        | total < (hdr_off + 4 + plen) = WsErr "truncated masked WebSocket frame payload"
        | otherwise = ws_finish_frame fin opcode True (ws_mask_bytes (ws_take (ws_drop wire (hdr_off + 4)) plen) (ws_take (ws_drop wire hdr_off) 4)) (hdr_off + 4 + plen)
      ws_decode_body wire total fin opcode False plen hdr_off
        | total < (hdr_off + plen) = WsErr "truncated unmasked WebSocket frame payload"
        | otherwise = ws_finish_frame fin opcode False (ws_take (ws_drop wire hdr_off) plen) (hdr_off + plen)

fn :: ws_finish_frame Bool Int Bool [Int] Int => WsRes
      ws_finish_frame fin opcode masked unmasked consumed
        | opcode == 1 = WsOk (WsFrame fin opcode masked unmasked (ws_bytes_to_str unmasked)) consumed
        | otherwise = WsOk (WsFrame fin opcode masked unmasked "") consumed
