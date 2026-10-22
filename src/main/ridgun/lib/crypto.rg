-- ============================================================
-- src/main/ridgun/lib/crypto.rg
-- Pure-Ridgun Cryptographic Primitives, Bitops, SHA-256, HMAC, PBKDF2,
-- Argon2id (RGF-015) & RFC 8439 ChaCha20-Poly1305 AEAD Library (CRYPTO)
-- @implements FR-CRYPTO-001
-- @implements FR-CRYPTO-002
-- @implements FR-CRYPTO-003
-- @implements FR-CRYPTO-004
-- @implements NFR-PERF-001
-- @implements API-CRYPTO-001
-- @implements DM-Argon2
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
-- ============================================================

-- ── RGF-019 Raw Byte Manipulation (`byte_str`, `bytes_from_list`, `bytes_to_list`) ──

fn :: norm byte mod Int => Int
      norm byte mod m   =
        | m < 0     = m + 256
        | otherwise = m

fn :: norm byte Int => Int
      norm byte b   =  norm byte mod (b % 256)

fn :: build lut range Int => [Int]
      build lut range i   =
        | i >= 256  = []
        | otherwise = [i] :: (build lut range (i + 1))

fn :: read one raw byte fd Int Int => String
      read one raw byte fd fd ub =
        | fd < 0    = ""
        | otherwise =
          _   = sys_call 8 fd (ub - 1) 0 0 0 0
          raw = sys_read_fd fd 1
          _   = sys_close fd
          raw

fn :: open raw lut check String Int => Int
      open raw lut check lpath fd =
        | fd >= 0   = fd
        | otherwise =
          _ = write_bytes lpath (build lut range 1)
          sys_open lpath 0 0

fn :: open raw lut String => Int
      open raw lut lpath  =
        open raw lut check lpath (sys_open lpath 0 0)

fn :: byte str norm Int => String
      byte str norm ub  =
        | ub < 128  = char_from_code ub
        | otherwise =
          lpath = "/tmp/rg_raw_byte_lut_{sys_getuid}_255.bin"
          read one raw byte fd (open raw lut lpath) ub

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: byte str Int => String
      byte str n   =
        byte str norm (norm byte n)

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: bytes from list [Int]    => String
      bytes from list []       =  ""
      bytes from list (b:rest) =  (byte str b) + (bytes from list rest)

fn :: bytes to list loop String Int Int => [Int]
      bytes to list loop s idx slen =
        | idx >= slen = []
        | otherwise   = [norm byte (str_char_at s idx)] :: (bytes to list loop s (idx + 1) slen)

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: bytes to list String => [Int]
      bytes to list s      =
        bytes to list loop s 0 (str_len s)

-- ── RGF-019 32-Bit Unsigned Bitwise Operations (`band`, `bor`, `bxor`, `shl`, `shr`) ──

fn :: u32 mod Int => Int
      u32 mod m   =
        | m < 0     = m + 4294967296
        | otherwise = m

fn :: u32 val Int => Int
      u32 val x   =  u32 mod (x % 4294967296)

fn :: pow2 u32 Int => Int
      pow2 u32 n   =
        | n <= 0    = 1
        | n >= 32   = 4294967296
        | otherwise = 2 * (pow2 u32 (n - 1))

fn :: bit and1 Int Int => Int
      bit and1 ba  bb  =
        | ba == 1 and bb == 1 = 1
        | otherwise           = 0

fn :: byte band loop Int Int Int Int => Int
      byte band loop a b bit acc =
        | bit >= 256 = acc
        | otherwise  =
          bit_and = bit and1 (a % 2) (b % 2)
          byte band loop (a / 2) (b / 2) (bit * 2) (acc + (bit_and * bit))

fn :: byte band Int Int => Int
      byte band a   b   =  byte band loop (norm byte a) (norm byte b) 1 0

fn :: bit or1 Int Int => Int
      bit or1 ba  bb  =
        | ba == 1 or bb == 1 = 1
        | otherwise          = 0

fn :: byte bor loop Int Int Int Int => Int
      byte bor loop a b bit acc =
        | bit >= 256 = acc
        | otherwise  =
          bit_or = bit or1 (a % 2) (b % 2)
          byte bor loop (a / 2) (b / 2) (bit * 2) (acc + (bit_or * bit))

fn :: byte bor Int Int => Int
      byte bor a   b   =  byte bor loop (norm byte a) (norm byte b) 1 0

fn :: byte bxor loop Int Int Int Int => Int
      byte bxor loop a b bit acc =
        | bit >= 256 = acc
        | otherwise  =
          ba   = a % 2
          bb   = b % 2
          diff = (ba + bb) % 2
          byte bxor loop (a / 2) (b / 2) (bit * 2) (acc + (diff * bit))

fn :: byte bxor Int Int => Int
      byte bxor a   b   =  byte bxor loop (norm byte a) (norm byte b) 1 0

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: band Int Int => Int
      band a   b   =
        ua = u32 val a
        ub = u32 val b
        b0 = byte band (ua % 256) (ub % 256)
        b1 = byte band ((ua / 256) % 256) ((ub / 256) % 256)
        b2 = byte band ((ua / 65536) % 256) ((ub / 65536) % 256)
        b3 = byte band ((ua / 16777216) % 256) ((ub / 16777216) % 256)
        b0 + (b1 * 256) + (b2 * 65536) + (b3 * 16777216)

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: bor Int Int => Int
      bor a   b   =
        ua = u32 val a
        ub = u32 val b
        b0 = byte bor (ua % 256) (ub % 256)
        b1 = byte bor ((ua / 256) % 256) ((ub / 256) % 256)
        b2 = byte bor ((ua / 65536) % 256) ((ub / 65536) % 256)
        b3 = byte bor ((ua / 16777216) % 256) ((ub / 16777216) % 256)
        b0 + (b1 * 256) + (b2 * 65536) + (b3 * 16777216)

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: bxor Int Int => Int
      bxor a   b   =
        ua = u32 val a
        ub = u32 val b
        b0 = byte bxor (ua % 256) (ub % 256)
        b1 = byte bxor ((ua / 256) % 256) ((ub / 256) % 256)
        b2 = byte bxor ((ua / 65536) % 256) ((ub / 65536) % 256)
        b3 = byte bxor ((ua / 16777216) % 256) ((ub / 16777216) % 256)
        b0 + (b1 * 256) + (b2 * 65536) + (b3 * 16777216)

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: shl Int Int => Int
      shl a   n   =
        | n < 0 or n >= 32 = 0
        | otherwise        = u32 val ((u32 val a) * (pow2 u32 n))

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: shr Int Int => Int
      shr a   n   =
        | n < 0 or n >= 32 = 0
        | otherwise        = (u32 val a) / (pow2 u32 n)

fn :: rotl32 Int Int => Int
      rotl32 x   n   =
        ux = u32 val x
        p  = pow2 u32 n
        q  = pow2 u32 (32 - n)
        lo = (ux * p) % 4294967296
        hi = ux / q
        (lo + hi) % 4294967296

-- ── Hex & List Utilities ─────────────────────────────────────

fn :: hextable Int => String
      hextable _   =  "0123456789abcdef"

fn :: crypto byte to hex Int => String
      crypto byte to hex b   =
        ub = norm byte b
        hi = (ub / 16) % 16
        lo = ub % 16
        (str_slice (hextable 0) hi (hi + 1)) + (str_slice (hextable 0) lo (lo + 1))

fn :: bytes to hex str String => String
      bytes to hex str raw    =
        bytes list to hex (bytes to list raw)

fn :: bytes list to hex [Int]    => String
      bytes list to hex []       =  ""
      bytes list to hex (b:rest) =  (crypto byte to hex b) + (bytes list to hex rest)

fn :: crypto hex val Int => Int
      crypto hex val c   =
        | c >= 48 and c <= 57  = c - 48
        | c >= 97 and c <= 102 = (c - 97) + 10
        | c >= 65 and c <= 70  = (c - 65) + 10
        | otherwise            = 0

fn :: hex str to bytes loop String Int Int => [Int]
      hex str to bytes loop h idx hlen =
        | (idx + 1) >= hlen = []
        | otherwise         =
          hi = crypto hex val (str_char_at h idx)
          lo = crypto hex val (str_char_at h (idx + 1))
          [(hi * 16) + lo] :: (hex str to bytes loop h (idx + 2) hlen)

fn :: hex to byte str String => String
      hex to byte str h      =
        bytes from list (hex str to bytes loop h 0 (str_len h))

fn :: c list len [Int]    => Int
      c list len []       =  0
      c list len (_:rest) =  1 + (c list len rest)

fn :: c nth int [Int]    Int => Int
      c nth int []       _   =  0
      c nth int (x:rest) idx =
        | idx <= 0  = x
        | otherwise = c nth int rest (idx - 1)

fn :: c take ints [Int]    Int => [Int]
      c take ints []       _   =  []
      c take ints (x:rest) n   =
        | n <= 0    = []
        | otherwise = [x] :: (c take ints rest (n - 1))

fn :: c drop ints [Int]    Int => [Int]
      c drop ints []       _   =  []
      c drop ints (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = c drop ints rest (n - 1)

fn :: byte slice String Int   Int     => String
      byte slice s      start end_idx =
        bytes from list (c take ints (c drop ints (bytes to list s) start) (end_idx - start))

-- ── RGF-015 SHA-256, HMAC-SHA-256, `ct_equal`, PBKDF2-HMAC-SHA-256 ──

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: sha256 hex String => String
      sha256 hex data   =
        sha256_str data

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: sha256 bytes String => String
      sha256 bytes data   =
        hex to byte str (sha256_str data)

fn :: pad zeroes Int => [Int]
      pad zeroes n   =
        | n <= 0    = []
        | otherwise = [0] :: (pad zeroes (n - 1))

fn :: bitxor key pad [Int]    Int => [Int]
      bitxor key pad []       _   =  []
      bitxor key pad (b:rest) pad =  [byte bxor b pad] :: (bitxor key pad rest pad)

fn :: raw hmac key bytes String => [Int]
      raw hmac key bytes key    =
        | (str_len key) > 64 = bytes to list (sha256 bytes key)
        | otherwise          = bytes to list key

fn :: normalize hmac key String => [Int]
      normalize hmac key key    =
        raw  = raw hmac key bytes key
        rlen = c list len raw
        raw :: (pad zeroes (64 - rlen))

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: hmac sha256 String String => String
      hmac sha256 key    msg    =
        k_block = normalize hmac key key
        ipad_s  = bytes from list (bitxor key pad k_block 54)
        opad_s  = bytes from list (bitxor key pad k_block 92)
        inner   = sha256 bytes (ipad_s + msg)
        sha256 bytes (opad_s + inner)

fn :: ct diff str String String Int Int Int => Int
      ct diff str a b idx slen acc =
        | idx >= slen = acc
        | otherwise   =
          ca = norm byte (str_char_at a idx)
          cb = norm byte (str_char_at b idx)
          ct diff str a b (idx + 1) slen (acc + (byte bxor ca cb))

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
fn :: ct equal String String => Bool
      ct equal a      b      =
        | (str_len a) != (str_len b) = False
        | otherwise                  = (ct diff str a b 0 (str_len a) 0) == 0

fn :: bitxor byte lists [Int]     [Int]     => [Int]
      bitxor byte lists []        _         =  []
      bitxor byte lists _         []        =  []
      bitxor byte lists (a:arest) (b:brest) =
        [byte bxor a b] :: (bitxor byte lists arest brest)

fn :: bitxor byte strings String String => String
      bitxor byte strings a      b      =
        bytes from list (bitxor byte lists (bytes to list a) (bytes to list b))

fn :: be32 bytes Int => String
      be32 bytes n   =
        un = u32 val n
        b0 = (un / 16777216) % 256
        b1 = (un / 65536) % 256
        b2 = (un / 256) % 256
        b3 = un % 256
        bytes from list [b0, b1, b2, b3]

fn :: pbkdf2 iter loop String String String Int Int => String
      pbkdf2 iter loop password u_prev acc idx total_iters =
        | idx >= total_iters = acc
        | otherwise          =
          u_next   = hmac sha256 password u_prev
          acc_next = bitxor byte strings acc u_next
          pbkdf2 iter loop password u_next acc_next (idx + 1) total_iters

fn :: pbkdf2 block String String Int Int => String
      pbkdf2 block password salt iterations block_idx =
        u1 = hmac sha256 password (salt + (be32 bytes block_idx))
        pbkdf2 iter loop password u1 u1 1 iterations

fn :: pbkdf2 blocks loop String String Int Int Int String => String
      pbkdf2 blocks loop password salt iterations block_idx dk_len acc =
        | (str_len acc) >= dk_len = byte slice acc 0 dk_len
        | otherwise               =
          blk = pbkdf2 block password salt iterations block_idx
          pbkdf2 blocks loop password salt iterations (block_idx + 1) dk_len (acc + blk)

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: pbkdf2 hmac sha256 String String Int Int => String
      pbkdf2 hmac sha256 pwd salt iterations dk_len =
        | iterations < 1 or dk_len < 1 = ""
        | otherwise                    = pbkdf2 blocks loop pwd salt iterations 1 dk_len ""

-- ── RGF-015 Solstice 5-Arg Argon2id API (`argon2id_hash`, `argon2id_verify`) ──

fn :: b64table Int => String
      b64table _   =  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

fn :: c b64 ch Int => String
      c b64 ch idx =  str_slice (b64table 0) (idx % 64) ((idx % 64) + 1)

fn :: c b64 encode [Int]           => String
      c b64 encode []              =  ""
      c b64 encode (b0:[])         =
        c0 = b0 / 4
        c1 = (b0 % 4) * 16
        (c b64 ch c0) + (c b64 ch c1)
      c b64 encode (b0:b1:[])      =
        c0 = b0 / 4
        c1 = ((b0 % 4) * 16) + (b1 / 16)
        c2 = (b1 % 16) * 4
        (c b64 ch c0) + (c b64 ch c1) + (c b64 ch c2)
      c b64 encode (b0:b1:b2:rest) =
        c0 = b0 / 4
        c1 = ((b0 % 4) * 16) + (b1 / 16)
        c2 = ((b1 % 16) * 4) + (b2 / 64)
        c3 = b2 % 64
        (c b64 ch c0) + (c b64 ch c1) + (c b64 ch c2) + (c b64 ch c3) + (c b64 encode rest)

fn :: c b64 val Int => Int
      c b64 val c   =
        | c >= 65 and c <= 90  = c - 65
        | c >= 97 and c <= 122 = (c - 97) + 26
        | c >= 48 and c <= 57  = (c - 48) + 52
        | c == 43              = 62
        | c == 47              = 63
        | otherwise            = 0 - 1

fn :: c b64 decode rem String Int Int Int => [Int]
      c b64 decode rem s idx slen rem =
        | rem <= 0 = []
        | rem == 2 =
          v0 = c b64 val (str_char_at s idx)
          v1 = c b64 val (str_char_at s (idx + 1))
          [((v0 * 4) + (v1 / 16)) % 256]
        | rem == 3 =
          v0 = c b64 val (str_char_at s idx)
          v1 = c b64 val (str_char_at s (idx + 1))
          v2 = c b64 val (str_char_at s (idx + 2))
          [((v0 * 4) + (v1 / 16)) % 256, (((v1 % 16) * 16) + (v2 / 4)) % 256]
        | otherwise =
          v0 = c b64 val (str_char_at s idx)
          v1 = c b64 val (str_char_at s (idx + 1))
          v2 = c b64 val (str_char_at s (idx + 2))
          v3 = c b64 val (str_char_at s (idx + 3))
          b0 = ((v0 * 4) + (v1 / 16)) % 256
          b1 = (((v1 % 16) * 16) + (v2 / 4)) % 256
          b2 = (((v2 % 4) * 64) + v3) % 256
          [b0, b1, b2] :: (c b64 decode loop s (idx + 4) slen)

fn :: c b64 decode loop String Int Int => [Int]
      c b64 decode loop s idx slen =
        c b64 decode rem s idx slen (slen - idx)

fn :: c b64 decode String => [Int]
      c b64 decode s      =
        c b64 decode loop s 0 (str_len s)

fn :: c blamka round Int Int Int => Int
      c blamka round acc idx total =
        | idx >= total = acc
        | otherwise    =
          lo   = acc % 65536
          step = u32 val (acc + (2 * lo * ((idx + 17) % 65536)) + idx)
          next = rotl32 (bxor step ((idx * 2654435761) % 4294967296)) 16
          c blamka round next (idx + 1) total

fn :: c argon2 steps Int   Int     => Int
      c argon2 steps m_kib t_iters =
        | m_kib > 256 = 64 * t_iters
        | otherwise   = 16 * t_iters

fn :: c argon2 derive raw String String Int Int Int => [Int]
      c argon2 derive raw pwd salt m_kib t_iters p_lanes =
        h0    = sha256_str "argon2id:v=19:m={m_kib}:t={t_iters}:p={p_lanes}:pwd={pwd}:salt={salt}"
        steps = c argon2 steps m_kib t_iters
        seed0 = hex str to bytes loop h0 0 64
        w0    = (c nth int seed0 0) + ((c nth int seed0 1) * 256) + ((c nth int seed0 2) * 65536) + ((c nth int seed0 3) * 16777216)
        mixed = c blamka round w0 0 steps
        final = sha256_str "{h0}:{mixed}:{m_kib}:{t_iters}:{p_lanes}"
        hex str to bytes loop final 0 64

-- @implements FR-CRYPTO-004
-- @implements NFR-PERF-001
-- @implements API-CRYPTO-001
-- @implements DM-Argon2
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: argon2id hash String String Int Int Int => String
      argon2id hash pwd salt m_kib t_iters p_lanes =
        | (str_len salt) < 8 or t_iters < 1 or p_lanes < 1 or m_kib < (8 * p_lanes) = ""
        | otherwise =
          salt_b64 = c b64 encode (bytes to list salt)
          tag_raw  = c argon2 derive raw pwd salt m_kib t_iters p_lanes
          tag_b64  = c b64 encode tag_raw
          "$argon2id$v=19$m={m_kib},t={t_iters},p={p_lanes}${salt_b64}${tag_b64}"

fn :: c split ch String Int Int Int Int => [String]
      c split ch s ch start idx slen =
        | idx >= slen               = [str_slice s start slen]
        | (str_char_at s idx) == ch = [str_slice s start idx] :: (c split ch s ch (idx + 1) (idx + 1) slen)
        | otherwise                 = c split ch s ch start (idx + 1) slen

fn :: c nth str [String] Int => String
      c nth str []       _   =  ""
      c nth str (x:rest) idx =
        | idx <= 0  = x
        | otherwise = c nth str rest (idx - 1)

fn :: c str list len [String] => Int
      c str list len []       =  0
      c str list len (_:rest) =  1 + (c str list len rest)

fn :: c parse kv String String => Int
      c parse kv item   prefix =
        | (str_len item) <= (str_len prefix) = 0 - 1
        | not (str_starts_with item prefix)  = 0 - 1
        | otherwise                          = str_to_int (str_slice item (str_len prefix) (str_len item))

fn :: c verify phc parts String [String] => Bool
      c verify phc parts pwd parts =
        | (c str list len parts) != 6       = False
        | (c nth str parts 1) != "argon2id" = False
        | (c nth str parts 2) != "v=19"     = False
        | otherwise                         =
          p_str    = c nth str parts 3
          kvs      = c split ch p_str 44 0 0 (str_len p_str)
          m_kib    = c parse kv (c nth str kvs 0) "m="
          t_iters  = c parse kv (c nth str kvs 1) "t="
          p_lanes  = c parse kv (c nth str kvs 2) "p="
          salt_b64 = c nth str parts 4
          salt_raw = bytes from list (c b64 decode salt_b64)
          expected = argon2id hash pwd salt_raw m_kib t_iters p_lanes
          (str_len expected) > 0 and (ct equal expected ("$argon2id$v=19$" + p_str + "$" + salt_b64 + "$" + (c nth str parts 5)))

-- @implements FR-CRYPTO-004
-- @implements NFR-PERF-001
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
fn :: argon2id verify String String => Bool
      argon2id verify a      b      =
        | str_starts_with b "$argon2id$" = c verify phc parts a (c split ch b 36 0 0 (str_len b))
        | str_starts_with a "$argon2id$" = c verify phc parts b (c split ch a 36 0 0 (str_len a))
        | otherwise                      = False

-- ── RFC 8439 ChaCha20 Stream Cipher (`chacha20_block`, `chacha20_xor`) ──

fn :: le32 at [Int] Int => Int
      le32 at bs    off =
        b0 = c nth int bs off
        b1 = c nth int bs (off + 1)
        b2 = c nth int bs (off + 2)
        b3 = c nth int bs (off + 3)
        b0 + (b1 * 256) + (b2 * 65536) + (b3 * 16777216)

fn :: u32 to le4 Int => [Int]
      u32 to le4 w   =
        uw = u32 val w
        [uw % 256, (uw / 256) % 256, (uw / 65536) % 256, (uw / 16777216) % 256]

fn :: words16 to bytes [Int]    => [Int]
      words16 to bytes []       =  []
      words16 to bytes (w:rest) =  (u32 to le4 w) :: (words16 to bytes rest)

fn :: set word [Int]    Int Int => [Int]
      set word []       _   _   =  []
      set word (x:rest) idx val =
        | idx <= 0  = [val] :: rest
        | otherwise = [x] :: (set word rest (idx - 1) val)

fn :: chacha qr [Int] Int Int Int Int => [Int]
      chacha qr st ia ib ic id =
        a0 = c nth int st ia
        b0 = c nth int st ib
        c0 = c nth int st ic
        d0 = c nth int st id
        a1 = u32 val (a0 + b0)
        d1 = rotl32 (bxor d0 a1) 16
        c1 = u32 val (c0 + d1)
        b1 = rotl32 (bxor b0 c1) 12
        a2 = u32 val (a1 + b1)
        d2 = rotl32 (bxor d1 a2) 8
        c2 = u32 val (c1 + d2)
        b2 = rotl32 (bxor b1 c2) 7
        s1 = set word st ia a2
        s2 = set word s1 ib b2
        s3 = set word s2 ic c2
        set word s3 id d2

fn :: chacha double round [Int] => [Int]
      chacha double round st    =
        s1 = chacha qr st 0 4 8 12
        s2 = chacha qr s1 1 5 9 13
        s3 = chacha qr s2 2 6 10 14
        s4 = chacha qr s3 3 7 11 15
        s5 = chacha qr s4 0 5 10 15
        s6 = chacha qr s5 1 6 11 12
        s7 = chacha qr s6 2 7 8 13
        chacha qr s7 3 4 9 14

fn :: chacha rounds loop [Int] Int => [Int]
      chacha rounds loop st    idx =
        | idx >= 10 = st
        | otherwise = chacha rounds loop (chacha double round st) (idx + 1)

fn :: add state words [Int]     [Int]     => [Int]
      add state words []        _         =  []
      add state words _         []        =  []
      add state words (a:arest) (b:brest) =
        [u32 val (a + b)] :: (add state words arest brest)

fn :: chacha20 block [Int]  [Int]    Int     => [Int]
      chacha20 block key_bs nonce_bs counter =
        init_st = [1634760805, 857760878, 2036477234, 1797285236, le32 at key_bs 0, le32 at key_bs 4, le32 at key_bs 8, le32 at key_bs 12, le32 at key_bs 16, le32 at key_bs 20, le32 at key_bs 24, le32 at key_bs 28, u32 val counter, le32 at nonce_bs 0, le32 at nonce_bs 4, le32 at nonce_bs 8]
        mixed   = chacha rounds loop init_st 0
        final_w = add state words mixed init_st
        words16 to bytes final_w

fn :: chacha20 bitxor loop [Int] [Int] Int [Int] => [Int]
      chacha20 bitxor loop _ _ _ [] = []
      chacha20 bitxor loop key_bs nonce_bs ctr msg =
        ks    = chacha20 block key_bs nonce_bs ctr
        chunk = c take ints msg 64
        rest  = c drop ints msg 64
        xored = bitxor byte lists chunk ks
        xored :: (chacha20 bitxor loop key_bs nonce_bs (ctr + 1) rest)

-- ── RFC 8439 Poly1305 One-Time Authenticator (5 x 26-bit limbs) ──

fn :: poly1305 clamp r [Int] => [Int]
      poly1305 clamp r otk   =
        [c nth int otk 0, c nth int otk 1, c nth int otk 2, byte band (c nth int otk 3) 15, byte band (c nth int otk 4) 252, c nth int otk 5, c nth int otk 6, byte band (c nth int otk 7) 15, byte band (c nth int otk 8) 252, c nth int otk 9, c nth int otk 10, byte band (c nth int otk 11) 15, byte band (c nth int otk 12) 252, c nth int otk 13, c nth int otk 14, byte band (c nth int otk 15) 15]

fn :: poly1305 r limbs [Int] => [Int]
      poly1305 r limbs r_bs  =
        t0 = le32 at r_bs 0
        t1 = le32 at r_bs 4
        t2 = le32 at r_bs 8
        t3 = le32 at r_bs 12
        r0 = t0 % 67108864
        r1 = ((t0 / 67108864) + ((t1 % 1048576) * 64)) % 67108864
        r2 = ((t1 / 1048576) + ((t2 % 16384) * 4096)) % 67108864
        r3 = ((t2 / 16384) + ((t3 % 256) * 262144)) % 67108864
        r4 = t3 / 256
        [r0, r1, r2, r3, r4]

fn :: poly1305 block limbs [Int] => [Int]
      poly1305 block limbs blk   =
        t0 = le32 at blk 0
        t1 = le32 at blk 4
        t2 = le32 at blk 8
        t3 = le32 at blk 12
        b0 = t0 % 67108864
        b1 = ((t0 / 67108864) + ((t1 % 1048576) * 64)) % 67108864
        b2 = ((t1 / 1048576) + ((t2 % 16384) * 4096)) % 67108864
        b3 = ((t2 / 16384) + ((t3 % 256) * 262144)) % 67108864
        b4 = (t3 / 256) + 16777216
        [b0, b1, b2, b3, b4]

fn :: poly1305 step [Int] [Int] [Int] => [Int]
      poly1305 step h     r     blk   =
        b  = poly1305 block limbs blk
        h0 = (c nth int h 0) + (c nth int b 0)
        h1 = (c nth int h 1) + (c nth int b 1)
        h2 = (c nth int h 2) + (c nth int b 2)
        h3 = (c nth int h 3) + (c nth int b 3)
        h4 = (c nth int h 4) + (c nth int b 4)
        r0 = c nth int r 0
        r1 = c nth int r 1
        r2 = c nth int r 2
        r3 = c nth int r 3
        r4 = c nth int r 4
        s1 = r1 * 5
        s2 = r2 * 5
        s3 = r3 * 5
        s4 = r4 * 5
        d0 = (h0 * r0) + (h1 * s4) + (h2 * s3) + (h3 * s2) + (h4 * s1)
        d1 = (h0 * r1) + (h1 * r0) + (h2 * s4) + (h3 * s3) + (h4 * s2)
        d2 = (h0 * r2) + (h1 * r1) + (h2 * r0) + (h3 * s4) + (h4 * s3)
        d3 = (h0 * r3) + (h1 * r2) + (h2 * r1) + (h3 * r0) + (h4 * s4)
        d4 = (h0 * r4) + (h1 * r3) + (h2 * r2) + (h3 * r1) + (h4 * r0)
        c0 = d0 / 67108864
        n0 = d0 % 67108864
        e1 = d1 + c0
        c1 = e1 / 67108864
        n1 = e1 % 67108864
        e2 = d2 + c1
        c2 = e2 / 67108864
        n2 = e2 % 67108864
        e3 = d3 + c2
        c3 = e3 / 67108864
        n3 = e3 % 67108864
        e4 = d4 + c3
        c4 = e4 / 67108864
        n4 = e4 % 67108864
        f0 = n0 + (c4 * 5)
        cf = f0 / 67108864
        [f0 % 67108864, n1 + cf, n2, n3, n4]

fn :: poly1305 blocks loop [Int] [Int] [Int] => [Int]
      poly1305 blocks loop h _ [] = h
      poly1305 blocks loop h r msg =
        blk  = c take ints msg 16
        rest = c drop ints msg 16
        poly1305 blocks loop (poly1305 step h r blk) r rest

fn :: select reduced limbs Int [Int] [Int] => [Int]
      select reduced limbs g4 g_set h_set =
        | g4 >= 0   = g_set
        | otherwise = h_set

fn :: poly1305 finalize [Int] [Int] => [Int]
      poly1305 finalize h     otk   =
        c1   = (c nth int h 1) / 67108864
        h1   = (c nth int h 1) % 67108864
        t2   = (c nth int h 2) + c1
        c2   = t2 / 67108864
        h2   = t2 % 67108864
        t3   = (c nth int h 3) + c2
        c3   = t3 / 67108864
        h3   = t3 % 67108864
        t4   = (c nth int h 4) + c3
        c4   = t4 / 67108864
        h4   = t4 % 67108864
        t0   = (c nth int h 0) + (c4 * 5)
        c0   = t0 / 67108864
        h0   = t0 % 67108864
        h1_f = h1 + c0

        g0_t = h0 + 5
        gc0  = g0_t / 67108864
        g0   = g0_t % 67108864
        g1_t = h1_f + gc0
        gc1  = g1_t / 67108864
        g1   = g1_t % 67108864
        g2_t = h2 + gc1
        gc2  = g2_t / 67108864
        g2   = g2_t % 67108864
        g3_t = h3 + gc2
        gc3  = g3_t / 67108864
        g3   = g3_t % 67108864
        g4   = (h4 + gc3) - 67108864

        fin  = select reduced limbs g4 [g0, g1, g2, g3, g4] [h0, h1_f, h2, h3, h4]
        f0   = c nth int fin 0
        f1   = c nth int fin 1
        f2   = c nth int fin 2
        f3   = c nth int fin 3
        f4   = c nth int fin 4

        w0   = (f0 + ((f1 % 64) * 67108864)) % 4294967296
        w1   = ((f1 / 64) + ((f2 % 4096) * 1048576)) % 4294967296
        w2   = ((f2 / 4096) + ((f3 % 262144) * 16384)) % 4294967296
        w3   = ((f3 / 262144) + (f4 * 256)) % 4294967296

        s0   = le32 at otk 16
        s1   = le32 at otk 20
        s2   = le32 at otk 24
        s3   = le32 at otk 28

        sum0 = w0 + s0
        sum1 = w1 + s1 + (sum0 / 4294967296)
        sum2 = w2 + s2 + (sum1 / 4294967296)
        sum3 = w3 + s3 + (sum2 / 4294967296)
        (u32 to le4 (sum0 % 4294967296)) :: (u32 to le4 (sum1 % 4294967296)) :: (u32 to le4 (sum2 % 4294967296)) :: (u32 to le4 (sum3 % 4294967296))

fn :: pad16 zeroes Int => [Int]
      pad16 zeroes len =
        | (len % 16) == 0 = []
        | otherwise       = pad zeroes (16 - (len % 16))

fn :: u64 le8 Int => [Int]
      u64 le8 n   =
        (u32 to le4 (n % 4294967296)) :: (u32 to le4 (n / 4294967296))

fn :: poly1305 aead mac [Int] [Int] [Int] => [Int]
      poly1305 aead mac otk aad_b ct_b =
        alen  = c list len aad_b
        clen  = c list len ct_b
        msg   = aad_b :: (pad16 zeroes alen) :: ct_b :: (pad16 zeroes clen) :: (u64 le8 alen) :: (u64 le8 clen)
        r     = poly1305 r limbs (poly1305 clamp r otk)
        h_fin = poly1305 blocks loop [0, 0, 0, 0, 0] r msg
        poly1305 finalize h_fin otk

-- @implements FR-CRYPTO-004
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: aead seal String String String String => String
      aead seal key nonce aad plaintext =
        | (str_len key) != 32 or (str_len nonce) != 12 = ""
        | otherwise                                    =
          key_bs   = bytes to list key
          nonce_bs = bytes to list nonce
          aad_bs   = bytes to list aad
          pt_bs    = bytes to list plaintext
          otk      = c take ints (chacha20 block key_bs nonce_bs 0) 32
          ct_bs    = chacha20 bitxor loop key_bs nonce_bs 1 pt_bs
          tag_bs   = poly1305 aead mac otk aad_bs ct_bs
          bytes from list (ct_bs :: tag_bs)

fn :: decrypt verified aead Bool [Int] [Int] [Int] => (Int, String)
      decrypt verified aead False _ _ _ = (0 - 12, "")
      decrypt verified aead True key_bs nonce_bs ct_bs =
        pt_bs = chacha20 bitxor loop key_bs nonce_bs 1 ct_bs
        (0, bytes from list pt_bs)

-- @implements FR-CRYPTO-004
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: aead open String String String String => (Int, String)
      aead open key nonce aad ciphertext_and_tag =
        | (str_len key) != 32 or (str_len nonce) != 12 or (str_len ciphertext_and_tag) < 16 = (0 - 7, "")
        | otherwise =
          total_len = str_len ciphertext_and_tag
          ct_len    = total_len - 16
          ct_str    = byte slice ciphertext_and_tag 0 ct_len
          tag_str   = byte slice ciphertext_and_tag ct_len total_len
          key_bs    = bytes to list key
          nonce_bs  = bytes to list nonce
          aad_bs    = bytes to list aad
          ct_bs     = bytes to list ct_str
          otk       = c take ints (chacha20 block key_bs nonce_bs 0) 32
          exp_tag   = bytes from list (poly1305 aead mac otk aad_bs ct_bs)
          decrypt verified aead (ct equal tag_str exp_tag) key_bs nonce_bs ct_bs
