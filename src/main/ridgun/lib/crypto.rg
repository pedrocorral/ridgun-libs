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

import argon2id

type CB16  = cs0: String, cs1: String, cs2: String, cs3: String, cs4: String, cs5: String, cs6: String, cs7: String, cs8: String, cs9: String, cs10: String, cs11: String, cs12: String, cs13: String, cs14: String, cs15: String
type CB256 = cr0: CB16, cr1: CB16, cr2: CB16, cr3: CB16, cr4: CB16, cr5: CB16, cr6: CB16, cr7: CB16, cr8: CB16, cr9: CB16, cr10: CB16, cr11: CB16, cr12: CB16, cr13: CB16, cr14: CB16, cr15: CB16

-- ── RGF-019 Raw Byte Manipulation (`byte_str`, `bytes_from_list`, `bytes_to_list`) ──

fn :: norm byte mod Int => Int
      norm byte mod m   =
        | m < 0     = m + 256
        | otherwise = m

fn :: norm byte Int => Int
      norm byte b   =  norm byte mod (b % 256)

fn :: byte str norm Int => String
      byte str norm ub  =
        | ub >= 1 and ub <= 127 = char_from_code ub
        | otherwise =
          efd = sys_call 290 (256 + ub) 526336 0 0 0 0
          s   = sys_read_fd efd 8
          _   = sys_close efd
          str_slice s 0 1

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

fn :: c build b16 Int  => CB16
      c build b16 base =
        CB16 (byte str norm base) (byte str norm (base + 1)) (byte str norm (base + 2)) (byte str norm (base + 3)) (byte str norm (base + 4)) (byte str norm (base + 5)) (byte str norm (base + 6)) (byte str norm (base + 7)) (byte str norm (base + 8)) (byte str norm (base + 9)) (byte str norm (base + 10)) (byte str norm (base + 11)) (byte str norm (base + 12)) (byte str norm (base + 13)) (byte str norm (base + 14)) (byte str norm (base + 15))

fn :: c build b256 => CB256
      c build b256 =
        CB256 (c build b16 0) (c build b16 16) (c build b16 32) (c build b16 48) (c build b16 64) (c build b16 80) (c build b16 96) (c build b16 112) (c build b16 128) (c build b16 144) (c build b16 160) (c build b16 176) (c build b16 192) (c build b16 208) (c build b16 224) (c build b16 240)

fn :: c get b16 CB16 Int => String
      c get b16 row  lo  =
        | lo < 8 =
          | lo < 4 =
            | lo == 0   = cs0 row
            | lo == 1   = cs1 row
            | lo == 2   = cs2 row
            | otherwise = cs3 row |.
          | otherwise =
            | lo == 4   = cs4 row
            | lo == 5   = cs5 row
            | lo == 6   = cs6 row
            | otherwise = cs7 row |.
        | otherwise =
          | lo < 12 =
            | lo == 8   = cs8 row
            | lo == 9   = cs9 row
            | lo == 10  = cs10 row
            | otherwise = cs11 row |.
          | otherwise =
            | lo == 12  = cs12 row
            | lo == 13  = cs13 row
            | lo == 14  = cs14 row
            | otherwise = cs15 row

fn :: c get b256 CB256 Int Int => String
      c get b256 tbl hi lo =
        | hi < 8 =
          | hi < 4 =
            | hi == 0   = c get b16 (cr0 tbl) lo
            | hi == 1   = c get b16 (cr1 tbl) lo
            | hi == 2   = c get b16 (cr2 tbl) lo
            | otherwise = c get b16 (cr3 tbl) lo |.
          | otherwise =
            | hi == 4   = c get b16 (cr4 tbl) lo
            | hi == 5   = c get b16 (cr5 tbl) lo
            | hi == 6   = c get b16 (cr6 tbl) lo
            | otherwise = c get b16 (cr7 tbl) lo |.
        | otherwise =
          | hi < 12 =
            | hi == 8   = c get b16 (cr8 tbl) lo
            | hi == 9   = c get b16 (cr9 tbl) lo
            | hi == 10  = c get b16 (cr10 tbl) lo
            | otherwise = c get b16 (cr11 tbl) lo |.
          | otherwise =
            | hi == 12  = c get b16 (cr12 tbl) lo
            | hi == 13  = c get b16 (cr13 tbl) lo
            | hi == 14  = c get b16 (cr14 tbl) lo
            | otherwise = c get b16 (cr15 tbl) lo

fn :: c hex val fast Int => Int
      c hex val fast c   =
        | c <= 57   = c - 48
        | c >= 97   = c - 87
        | otherwise = c - 55

fn :: c hex pair CB256 String Int => String
      c hex pair tbl h off =
        c get b256 tbl (c hex val fast (str_char_at h off)) (c hex val fast (str_char_at h (off + 1)))

fn :: c hex2raw32 CB256 String => String
      c hex2raw32 tbl   h      =
        (c hex pair tbl h 0) + (c hex pair tbl h 2) + (c hex pair tbl h 4) + (c hex pair tbl h 6) + (c hex pair tbl h 8) + (c hex pair tbl h 10) + (c hex pair tbl h 12) + (c hex pair tbl h 14) + (c hex pair tbl h 16) + (c hex pair tbl h 18) + (c hex pair tbl h 20) + (c hex pair tbl h 22) + (c hex pair tbl h 24) + (c hex pair tbl h 26) + (c hex pair tbl h 28) + (c hex pair tbl h 30) + (c hex pair tbl h 32) + (c hex pair tbl h 34) + (c hex pair tbl h 36) + (c hex pair tbl h 38) + (c hex pair tbl h 40) + (c hex pair tbl h 42) + (c hex pair tbl h 44) + (c hex pair tbl h 46) + (c hex pair tbl h 48) + (c hex pair tbl h 50) + (c hex pair tbl h 52) + (c hex pair tbl h 54) + (c hex pair tbl h 56) + (c hex pair tbl h 58) + (c hex pair tbl h 60) + (c hex pair tbl h 62)

fn :: c bitxor4 Int Int => Int
      c bitxor4 a   b   =
        x0 = ((a % 2) + (b % 2)) % 2
        a1 = a / 2
        b1 = b / 2
        x1 = ((a1 % 2) + (b1 % 2)) % 2
        a2 = a1 / 2
        b2 = b1 / 2
        x2 = ((a2 % 2) + (b2 % 2)) % 2
        a3 = a2 / 2
        b3 = b2 / 2
        x3 = ((a3 % 2) + (b3 % 2)) % 2
        x0 + (x1 * 2) + (x2 * 4) + (x3 * 8)

fn :: c bitxor nibs hex64 [Int] String Int => [Int]
      c bitxor nibs hex64 [] _ _ = []
      c bitxor nibs hex64 (n:rest) h idx =
        [c bitxor4 n (c hex val fast (str_char_at h idx))] :: (c bitxor nibs hex64 rest h (idx + 1))

fn :: c hex to nibs String Int => [Int]
      c hex to nibs h idx =
        | idx >= 64 = []
        | otherwise = [c hex val fast (str_char_at h idx)] :: (c hex to nibs h (idx + 1))

fn :: c nibs to raw CB256 [Int] => String
      c nibs to raw _ [] = ""
      c nibs to raw _ (_:[]) = ""
      c nibs to raw tbl (hi:lo:rest) =
        (c get b256 tbl hi lo) + (c nibs to raw tbl rest)

fn :: c list to raw CB256 [Int] => String
      c list to raw _ [] = ""
      c list to raw tbl (b:rest) =
        ub = norm byte b
        (c get b256 tbl (ub / 16) (ub % 16)) + (c list to raw tbl rest)

fn :: pbkdf2 iter loop CB256 String String String [Int] Int Int => [Int]
      pbkdf2 iter loop tbl ipad opad u_raw acc_nibs idx total_iters =
        | idx >= total_iters = acc_nibs
        | otherwise          =
          in_h  = sha256_str (ipad + u_raw)
          out_h = sha256_str (opad + (c hex2raw32 tbl in_h))
          u_nxt = c hex2raw32 tbl out_h
          acc2  = c bitxor nibs hex64 acc_nibs out_h 0
          pbkdf2 iter loop tbl ipad opad u_nxt acc2 (idx + 1) total_iters

fn :: pbkdf2 block CB256 String String String Int Int => String
      pbkdf2 block tbl ipad opad salt iterations block_idx =
        in_h  = sha256_str (ipad + salt + (be32 bytes block_idx))
        u1_h  = sha256_str (opad + (c hex2raw32 tbl in_h))
        u1_r  = c hex2raw32 tbl u1_h
        nibs  = pbkdf2 iter loop tbl ipad opad u1_r (c hex to nibs u1_h 0) 1 iterations
        c nibs to raw tbl nibs

fn :: pbkdf2 blocks loop CB256 String String String Int Int Int String => String
      pbkdf2 blocks loop tbl ipad opad salt iterations block_idx dk_len acc =
        | (str_len acc) >= dk_len = byte slice acc 0 dk_len
        | otherwise               =
          blk = pbkdf2 block tbl ipad opad salt iterations block_idx
          pbkdf2 blocks loop tbl ipad opad salt iterations (block_idx + 1) dk_len (acc + blk)

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: pbkdf2 hmac sha256 String String Int Int => String
      pbkdf2 hmac sha256 pwd salt iterations dk_len =
        | iterations < 1 or dk_len < 1 = ""
        | otherwise                    =
          tbl     = c build b256
          k_block = normalize hmac key pwd
          ipad_s  = c list to raw tbl (bitxor key pad k_block 54)
          opad_s  = c list to raw tbl (bitxor key pad k_block 92)
          pbkdf2 blocks loop tbl ipad_s opad_s salt iterations 1 dk_len ""

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

fn :: decrypt verified aead Bool [Int] [Int] [Int] => Int String
      decrypt verified aead False _ _ _ = (0 - 12, "")
      decrypt verified aead True key_bs nonce_bs ct_bs =
        pt_bs = chacha20 bitxor loop key_bs nonce_bs 1 ct_bs
        (0, bytes from list pt_bs)

-- @implements FR-CRYPTO-004
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: aead open String String String String => Int String
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
