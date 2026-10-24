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

-- ── List & String Byte Conversion Helpers ────────────────────

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
        | otherwise = ws str to bytes loop s (pos + 1) len (acc :: [((str_char_at s pos) % 256 + 256) % 256])

fn :: ws str to bytes String => [Int]
      ws str to bytes s = ws str to bytes loop s 0 (str_len s) []

fn :: ws bytes to str [Int] => String
      ws bytes to str [] = ""
      ws bytes to str (b:rest) = (char_from_code b) + (ws bytes to str rest)

-- ── Pure-Ridgun SHA-1 & Base64 for RFC 6455 Handshake ────────

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
        tbl = ws b64 lut 0
        i = ((idx % 64) + 64) % 64
        str_slice tbl i (i + 1)

fn :: ws b64 enc [Int] => String
      ws b64 enc [] = ""
      ws b64 enc (b0:[]) = (ws b64 c (b0 / 4)) + (ws b64 c ((b0 % 4) * 16)) + "=="
      ws b64 enc (b0:b1:[]) =
        n = (b0 * 256) + b1
        (ws b64 c (n / 1024)) + (ws b64 c ((n / 16) % 64)) + (ws b64 c ((n % 16) * 4)) + "="
      ws b64 enc (b0:b1:b2:rs) =
        n = (b0 * 65536) + (b1 * 256) + b2
        (ws b64 c (n / 262144)) + (ws b64 c ((n / 4096) % 64)) + (ws b64 c ((n / 64) % 64)) + (ws b64 c (n % 64)) + (ws b64 enc rs)

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws accept key String => String
      ws accept key client_key = ws b64 enc (ws sha1 bytes (client_key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws build upgrade request String String String => String
      ws build upgrade request host path client_key =
        crlf = (char_from_code 13) + (char_from_code 10)
        "GET " + path + " HTTP/1.1" + crlf + "Host: " + host + crlf + "Upgrade: websocket" + crlf + "Connection: Upgrade" + crlf + "Sec-WebSocket-Key: " + client_key + crlf + "Sec-WebSocket-Version: 13" + crlf + crlf

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws build upgrade response String => String
      ws build upgrade response client_key =
        crlf = (char_from_code 13) + (char_from_code 10)
        accept = ws accept key client_key
        "HTTP/1.1 101 Switching Protocols" + crlf + "Upgrade: websocket" + crlf + "Connection: Upgrade" + crlf + "Sec-WebSocket-Accept: " + accept + crlf + crlf

-- ── RFC 6455 XOR Masking & Frame Encoding / Decoding ─────────

fn :: ws mask loop [Int] [Int] Int => [Int]
      ws mask loop [] _ _ = []
      ws mask loop (b:rest) mask_key idx = [ws byte bxor b (ws nth mask_key (idx % 4))] :: (ws mask loop rest mask_key (idx + 1))

-- @implements FR-WS-001
-- @implements API-WS-001
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

-- @implements FR-WS-001
-- @implements API-WS-001
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

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws encode text String => [Int]
      ws encode text text = ws encode frame True 1 [] (ws str to bytes text)

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws encode masked text String [Int] => [Int]
      ws encode masked text text mask_key = ws encode frame True 1 mask_key (ws str to bytes text)

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws encode ping [Int] => [Int]
      ws encode ping payload = ws encode frame True 9 [] payload

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws encode pong [Int] => [Int]
      ws encode pong payload = ws encode frame True 10 [] payload

-- @implements FR-WS-001
-- @implements API-WS-001
fn :: ws encode close Int => [Int]
      ws encode close code = ws encode frame True 8 [] [(code / 256) % 256, code % 256]

-- @implements FR-WS-001
-- @implements API-WS-001
-- @mitigates VUL-INPUT-001
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
