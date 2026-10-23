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

type CT16    = ct0: A, ct1: A, ct2: A, ct3: A, ct4: A, ct5: A, ct6: A, ct7: A, ct8: A, ct9: A, ct10: A, ct11: A, ct12: A, ct13: A, ct14: A, ct15: A
type CP16    = cp0: Int, cp1: Int, cp2: Int, cp3: Int, cp4: Int, cp5: Int, cp6: Int, cp7: Int, cp8: Int, cp9: Int, cp10: Int, cp11: Int, cp12: Int, cp13: Int, cp14: Int, cp15: Int
type CP32    = cplo: CP16, cphi: CP16
type CPbkCtx = cptbl: CT16, cpipad: String, cpopad: String
type CA2Ctx  = cr_pass: Int, cs_slice: Int, cl_lane: Int, cp_lanes: Int, cq_cols: Int, cseg_len: Int, ct_iters: Int

-- ── RGF-019 Raw Byte Manipulation (`byte_str`, `bytes_from_list`, `bytes_to_list`) ──

fn :: norm byte mod Int => Int
      norm byte mod m   =
        | m < 0     = m + 256
        | otherwise = m

fn :: norm byte Int => Int
      norm byte b   =  norm byte mod (b % 256)

fn :: byte str norm Int => String
      byte str norm ub  =
        | ub >= 1 and ub <= 127 = char from code ub
        | otherwise =
          efd = sys call 290 (256 + ub) 526336 0 0 0 0
          s   = sys read fd efd 8
          _   = sys close efd
          str slice s 0 1

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
        | otherwise   = [norm byte (str char at s idx)] :: (bytes to list loop s (idx + 1) slen)

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: bytes to list String => [Int]
      bytes to list s      =
        bytes to list loop s 0 (str len s)

-- ── RGF-019 32-Bit Unsigned Bitwise Operations (`band`, `bor`, `bxor`, `shl`, `shr`) ──

fn :: u32 mod Int => Int
      u32 mod m   =
        | m < 0     = m + 4294967296
        | otherwise = m

fn :: u32 val Int => Int
      u32 val x   =  x and 0xFFFFFFFF

fn :: byte band Int Int => Int
      byte band a   b   =
        (a and b) and 255

fn :: byte bor Int Int => Int
      byte bor a   b   =
        (a or b) and 255

fn :: byte bxor Int Int => Int
      byte bxor a   b   =
        (a xor b) and 255

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: band Int Int => Int
      band a   b   =
        (a and b) and 0xFFFFFFFF

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: bor Int Int => Int
      bor a   b   =
        (a or b) and 0xFFFFFFFF

fn :: c u32 bxor Int Int => Int
      c u32 bxor ua  ub  =
        (ua xor ub) and 0xFFFFFFFF

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: bxor Int Int => Int
      bxor a   b   =
        (a xor b) and 0xFFFFFFFF

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: shl Int Int => Int
      shl a   n   =
        | n < 0 or n >= 32 = 0
        | otherwise        = ((a and 0xFFFFFFFF) shl n) and 0xFFFFFFFF

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: shr Int Int => Int
      shr a   n   =
        | n < 0 or n >= 32 = 0
        | otherwise        = (a and 0xFFFFFFFF) shr n

fn :: rotl32 Int Int => Int
      rotl32 x   n   =
        ux = x and 0xFFFFFFFF
        (((ux shl n) or (ux shr (32 - n))) and 0xFFFFFFFF)

-- ── Hex & List Utilities ─────────────────────────────────────

fn :: hextable Int => String
      hextable _   =  "0123456789abcdef"

fn :: crypto byte to hex Int => String
      crypto byte to hex b   =
        ub = norm byte b
        hi = (ub / 16) % 16
        lo = ub % 16
        (str slice (hextable 0) hi (hi + 1)) + (str slice (hextable 0) lo (lo + 1))

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
          hi = crypto hex val (str char at h idx)
          lo = crypto hex val (str char at h (idx + 1))
          [(hi * 16) + lo] :: (hex str to bytes loop h (idx + 2) hlen)

fn :: hex to byte str String => String
      hex to byte str h      =
        bytes from list (hex str to bytes loop h 0 (str len h))

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
        sha256 str data

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: sha256 bytes String => String
      sha256 bytes data   =
        hex to byte str (sha256 str data)

fn :: pad zeroes Int => [Int]
      pad zeroes n   =
        | n <= 0    = []
        | otherwise = [0] :: (pad zeroes (n - 1))

fn :: bitxor key pad [Int]    Int => [Int]
      bitxor key pad []       _   =  []
      bitxor key pad (b:rest) pad =  [byte bxor b pad] :: (bitxor key pad rest pad)

fn :: raw hmac key bytes String => [Int]
      raw hmac key bytes key    =
        | (str len key) > 64 = bytes to list (sha256 bytes key)
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
          ca = norm byte (str char at a idx)
          cb = norm byte (str char at b idx)
          ct diff str a b (idx + 1) slen (acc + (byte bxor ca cb))

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
fn :: ct equal String String => Bool
      ct equal a      b      =
        | (str len a) != (str len b) = False
        | otherwise                  = (ct diff str a b 0 (str len a) 0) == 0

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

fn :: c get16 CT16 Int => A
      c get16 row  idx =
        | idx == 0  = ct0 row
        | idx == 1  = ct1 row
        | idx == 2  = ct2 row
        | idx == 3  = ct3 row
        | idx == 4  = ct4 row
        | idx == 5  = ct5 row
        | idx == 6  = ct6 row
        | idx == 7  = ct7 row
        | idx == 8  = ct8 row
        | idx == 9  = ct9 row
        | idx == 10 = ct10 row
        | idx == 11 = ct11 row
        | idx == 12 = ct12 row
        | idx == 13 = ct13 row
        | idx == 14 = ct14 row
        | otherwise = ct15 row

fn :: c set16 CT16 Int A   => CT16
      c set16 m    idx val =
        | idx == 0  = m with ct0 = val
        | idx == 1  = m with ct1 = val
        | idx == 2  = m with ct2 = val
        | idx == 3  = m with ct3 = val
        | idx == 4  = m with ct4 = val
        | idx == 5  = m with ct5 = val
        | idx == 6  = m with ct6 = val
        | idx == 7  = m with ct7 = val
        | idx == 8  = m with ct8 = val
        | idx == 9  = m with ct9 = val
        | idx == 10 = m with ct10 = val
        | idx == 11 = m with ct11 = val
        | idx == 12 = m with ct12 = val
        | idx == 13 = m with ct13 = val
        | idx == 14 = m with ct14 = val
        | otherwise = m with ct15 = val

fn :: c build b16 Int  => CT16
      c build b16 base =
        CT16 (byte str norm base) (byte str norm (base + 1)) (byte str norm (base + 2)) (byte str norm (base + 3)) (byte str norm (base + 4)) (byte str norm (base + 5)) (byte str norm (base + 6)) (byte str norm (base + 7)) (byte str norm (base + 8)) (byte str norm (base + 9)) (byte str norm (base + 10)) (byte str norm (base + 11)) (byte str norm (base + 12)) (byte str norm (base + 13)) (byte str norm (base + 14)) (byte str norm (base + 15))

fn :: c build b256 => CT16
      c build b256 =
        CT16 (c build b16 0) (c build b16 16) (c build b16 32) (c build b16 48) (c build b16 64) (c build b16 80) (c build b16 96) (c build b16 112) (c build b16 128) (c build b16 144) (c build b16 160) (c build b16 176) (c build b16 192) (c build b16 208) (c build b16 224) (c build b16 240)

fn :: c get b256 CT16 Int Int => String
      c get b256 tbl hi lo =
        c get16 (c get16 tbl hi) lo

fn :: c hex nib Int => Int
      c hex nib c   =
        | c < 58    = c - 48
        | otherwise = c - 87

fn :: c hex pair CT16 String Int => String
      c hex pair tbl h off =
        c get b256 tbl (c hex nib (str char at h off)) (c hex nib (str char at h (off + 1)))

fn :: c hex2raw4 CT16 String Int => String
      c hex2raw4 tbl  h      off =
        b0 = c hex pair tbl h off
        b1 = c hex pair tbl h (off + 2)
        b2 = c hex pair tbl h (off + 4)
        b3 = c hex pair tbl h (off + 6)
        s0 = b0 + b1
        s1 = b2 + b3
        s0 + s1

fn :: c hex2raw32 CT16 String => String
      c hex2raw32 tbl  h      =
        q0 = c hex2raw4 tbl h 0
        q1 = c hex2raw4 tbl h 8
        q2 = c hex2raw4 tbl h 16
        q3 = c hex2raw4 tbl h 24
        q4 = c hex2raw4 tbl h 32
        q5 = c hex2raw4 tbl h 40
        q6 = c hex2raw4 tbl h 48
        q7 = c hex2raw4 tbl h 56
        h0 = q0 + q1
        h1 = q2 + q3
        h2 = q4 + q5
        h3 = q6 + q7
        w0 = h0 + h1
        w1 = h2 + h3
        w0 + w1

fn :: c hex sp256 Int => Int
      c hex sp256 c   =
        | c <= 48   = 0
        | c == 49   = 1
        | c == 50   = 256
        | c == 51   = 257
        | c == 52   = 65536
        | c == 53   = 65537
        | c == 54   = 65792
        | c == 55   = 65793
        | c == 56   = 16777216
        | c == 57   = 16777217
        | c == 97   = 16777472
        | c == 98   = 16777473
        | c == 99   = 16842752
        | c == 100  = 16842753
        | c == 101  = 16843008
        | otherwise = 16843009

fn :: c hb String Int => Int
      c hb h      off =
        ((c hex sp256 (str char at h off)) * 4294967296) + (c hex sp256 (str char at h (off + 1)))

fn :: c add cp16 CP16 String Int => CP16
      c add cp16 p h base =
        CP16 ((cp0 p) + (c hb h base)) ((cp1 p) + (c hb h (base + 2))) ((cp2 p) + (c hb h (base + 4))) ((cp3 p) + (c hb h (base + 6))) ((cp4 p) + (c hb h (base + 8))) ((cp5 p) + (c hb h (base + 10))) ((cp6 p) + (c hb h (base + 12))) ((cp7 p) + (c hb h (base + 14))) ((cp8 p) + (c hb h (base + 16))) ((cp9 p) + (c hb h (base + 18))) ((cp10 p) + (c hb h (base + 20))) ((cp11 p) + (c hb h (base + 22))) ((cp12 p) + (c hb h (base + 24))) ((cp13 p) + (c hb h (base + 26))) ((cp14 p) + (c hb h (base + 28))) ((cp15 p) + (c hb h (base + 30)))

fn :: c add cp32 CP32 String => CP32
      c add cp32 acc  h      =
        CP32 (c add cp16 (cplo acc) h 0) (c add cp16 (cphi acc) h 32)

fn :: c norm sp256 Int => Int
      c norm sp256 x   =
        b0 = x % 2
        b1 = (x / 256) % 2
        b2 = (x / 65536) % 2
        b3 = (x / 16777216) % 2
        b4 = (x / 4294967296) % 2
        b5 = (x / 1099511627776) % 2
        b6 = (x / 281474976710656) % 2
        b7 = (x / 72057594037927936) % 2
        b0 + (b1 * 256) + (b2 * 65536) + (b3 * 16777216) + (b4 * 4294967296) + (b5 * 1099511627776) + (b6 * 281474976710656) + (b7 * 72057594037927936)

fn :: c norm cp16 CP16 => CP16
      c norm cp16 p    =
        CP16 (c norm sp256 (cp0 p)) (c norm sp256 (cp1 p)) (c norm sp256 (cp2 p)) (c norm sp256 (cp3 p)) (c norm sp256 (cp4 p)) (c norm sp256 (cp5 p)) (c norm sp256 (cp6 p)) (c norm sp256 (cp7 p)) (c norm sp256 (cp8 p)) (c norm sp256 (cp9 p)) (c norm sp256 (cp10 p)) (c norm sp256 (cp11 p)) (c norm sp256 (cp12 p)) (c norm sp256 (cp13 p)) (c norm sp256 (cp14 p)) (c norm sp256 (cp15 p))

fn :: c norm cp32 CP32 => CP32
      c norm cp32 acc  =
        CP32 (c norm cp16 (cplo acc)) (c norm cp16 (cphi acc))

fn :: c step cp32 CP32 String Int => CP32
      c step cp32 acc h rem =
        | (rem % 64) == 0 = c norm cp32 (c add cp32 acc h)
        | otherwise       = c add cp32 acc h

fn :: c sp256 nib Int => Int
      c sp256 nib w   =
        (w % 2) + (((w / 256) % 2) * 2) + (((w / 65536) % 2) * 4) + (((w / 16777216) % 2) * 8)

fn :: c sp256 to raw CT16 Int => String
      c sp256 to raw tbl x =
        c get b256 tbl (c sp256 nib (x / 4294967296)) (c sp256 nib (x % 4294967296))

fn :: c cp16 to raw CT16 CP16 => String
      c cp16 to raw tbl p =
        b0  = c sp256 to raw tbl (cp0 p)
        b1  = c sp256 to raw tbl (cp1 p)
        b2  = c sp256 to raw tbl (cp2 p)
        b3  = c sp256 to raw tbl (cp3 p)
        b4  = c sp256 to raw tbl (cp4 p)
        b5  = c sp256 to raw tbl (cp5 p)
        b6  = c sp256 to raw tbl (cp6 p)
        b7  = c sp256 to raw tbl (cp7 p)
        b8  = c sp256 to raw tbl (cp8 p)
        b9  = c sp256 to raw tbl (cp9 p)
        b10 = c sp256 to raw tbl (cp10 p)
        b11 = c sp256 to raw tbl (cp11 p)
        b12 = c sp256 to raw tbl (cp12 p)
        b13 = c sp256 to raw tbl (cp13 p)
        b14 = c sp256 to raw tbl (cp14 p)
        b15 = c sp256 to raw tbl (cp15 p)
        s0  = b0 + b1
        s1  = b2 + b3
        s2  = b4 + b5
        s3  = b6 + b7
        s4  = b8 + b9
        s5  = b10 + b11
        s6  = b12 + b13
        s7  = b14 + b15
        q0  = s0 + s1
        q1  = s2 + s3
        q2  = s4 + s5
        q3  = s6 + s7
        h0  = q0 + q1
        h1  = q2 + q3
        h0 + h1

fn :: c cp32 to raw CT16 CP32 => String
      c cp32 to raw tbl acc =
        (c cp16 to raw tbl (cplo acc)) + (c cp16 to raw tbl (cphi acc))

fn :: c list to raw CT16 [Int] => String
      c list to raw _ [] = ""
      c list to raw tbl (b:rest) =
        ub = norm byte b
        (c get b256 tbl (ub / 16) (ub % 16)) + (c list to raw tbl rest)

fn :: pbkdf2 iter loop CPbkCtx String CP32 Int => CP32
      pbkdf2 iter loop ctx u_raw acc rem =
        | rem <= 0  = c norm cp32 acc
        | otherwise =
          tbl   = cptbl ctx
          in_h  = sha256 str ((cpipad ctx) + u_raw)
          out_h = sha256 str ((cpopad ctx) + (c hex2raw32 tbl in_h))
          pbkdf2 iter loop ctx (c hex2raw32 tbl out_h) (c step cp32 acc out_h rem) (rem - 1)

fn :: pbkdf2 block CPbkCtx String Int Int => String
      pbkdf2 block ctx salt iterations block_idx =
        tbl   = cptbl ctx
        in_h  = sha256 str ((cpipad ctx) + salt + (be32 bytes block_idx))
        u1_h  = sha256 str ((cpopad ctx) + (c hex2raw32 tbl in_h))
        u1_r  = c hex2raw32 tbl u1_h
        z16   = CP16 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
        acc0  = c add cp32 (CP32 z16 z16) u1_h
        accf  = pbkdf2 iter loop ctx u1_r acc0 (iterations - 1)
        c cp32 to raw tbl accf

fn :: pbkdf2 blocks loop CPbkCtx String Int Int Int String => String
      pbkdf2 blocks loop ctx salt iterations block_idx dk_len acc =
        | (str len acc) >= dk_len = byte slice acc 0 dk_len
        | otherwise               =
          blk = pbkdf2 block ctx salt iterations block_idx
          pbkdf2 blocks loop ctx salt iterations (block_idx + 1) dk_len (acc + blk)

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
          ctx     = CPbkCtx tbl ipad_s opad_s
          pbkdf2 blocks loop ctx salt iterations 1 dk_len ""

-- ── Ridgun v0.9.15 BlaMka Tensor Block Compression (`f blamka`, `blamka g`, `blamka p16`, `compress block`) ──

-- @implements FR-CRYPTO-004
-- @implements API-CRYPTO-001
-- @implements DM-Tensor
fn :: f blamka U64 U64 => U64
      f blamka x   y   =  x + y + 2 * ((x and 0xFFFFFFFF) * (y and 0xFFFFFFFF))

-- @implements FR-CRYPTO-004
-- @implements API-CRYPTO-001
-- @implements DM-Tensor
fn :: blamka g U64 U64 U64 U64 => U64 U64 U64 U64
      blamka g a b c d =
        mut a = f blamka a b
        mut d = (d xor a) rotr 32
        mut c = f blamka c d
        mut b = (b xor c) rotr 24
        a = f blamka a b
        d = (d xor a) rotr 16
        c = f blamka c d
        b = (b xor c) rotr 63
        (a, b, c, d)

-- @implements FR-CRYPTO-004
-- @implements API-CRYPTO-001
-- @implements DM-Tensor
fn :: blamka p16 Tensor[U64 * 16] => ()
      blamka p16 v                =
        v_(0), v_(4), v_(8),  v_(12) = blamka g v_(0) v_(4) v_(8)  v_(12)
        v_(1), v_(5), v_(9),  v_(13) = blamka g v_(1) v_(5) v_(9)  v_(13)
        v_(2), v_(6), v_(10), v_(14) = blamka g v_(2) v_(6) v_(10) v_(14)
        v_(3), v_(7), v_(11), v_(15) = blamka g v_(3) v_(7) v_(11) v_(15)
        v_(0), v_(5), v_(10), v_(15) = blamka g v_(0) v_(5) v_(10) v_(15)
        v_(1), v_(6), v_(11), v_(12) = blamka g v_(1) v_(6) v_(11) v_(12)
        v_(2), v_(7), v_(8),  v_(13) = blamka g v_(2) v_(7) v_(8)  v_(13)
        v_(3), v_(4), v_(9),  v_(14) = blamka g v_(3) v_(4) v_(9)  v_(14)

fn :: ca2 blamka col pair Tensor[U64 * 8 * 16] Int => Tensor[U64 * 8 * 16]
      ca2 blamka col pair z j =
        c  = 2 * j
        c1 = c + 1
        z_(0, c),  z_(2, c),  z_(4, c),  z_(6, c)  = blamka g z_(0, c)  z_(2, c)  z_(4, c)  z_(6, c)
        z_(0, c1), z_(2, c1), z_(4, c1), z_(6, c1) = blamka g z_(0, c1) z_(2, c1) z_(4, c1) z_(6, c1)
        z_(1, c),  z_(3, c),  z_(5, c),  z_(7, c)  = blamka g z_(1, c)  z_(3, c)  z_(5, c)  z_(7, c)
        z_(1, c1), z_(3, c1), z_(5, c1), z_(7, c1) = blamka g z_(1, c1) z_(3, c1) z_(5, c1) z_(7, c1)
        z_(0, c),  z_(2, c1), z_(5, c),  z_(7, c1) = blamka g z_(0, c)  z_(2, c1) z_(5, c)  z_(7, c1)
        z_(0, c1), z_(3, c),  z_(5, c1), z_(6, c)  = blamka g z_(0, c1) z_(3, c)  z_(5, c1) z_(6, c)
        z_(1, c),  z_(3, c1), z_(4, c),  z_(6, c1) = blamka g z_(1, c)  z_(3, c1) z_(4, c)  z_(6, c1)
        z_(1, c1), z_(2, c),  z_(4, c1), z_(7, c)  = blamka g z_(1, c1) z_(2, c)  z_(4, c1) z_(7, c)
        z

fn :: ca2 blamka cols loop Tensor[U64 * 8 * 16] Int => Tensor[U64 * 8 * 16]
      ca2 blamka cols loop z j =
        | j >= 8    = z
        | otherwise = ca2 blamka cols loop (ca2 blamka col pair z j) (j + 1)

-- @implements FR-CRYPTO-004
-- @implements API-CRYPTO-001
-- @implements DM-Tensor
fn :: compress block Tensor[U64 * 8 * 16] Tensor[U64 * 8 * 16] => Tensor[U64 * 8 * 16]
      compress block x y =
        r_ij = x_ij xor y_ij
        z_ij = r_ij
        ||map blamka p16 in z_(i,)
        z2   = ca2 blamka cols loop z 0
        z2_ij xor r_ij

-- ── RGF-015 Pure-Ridgun RFC 9106 Argon2id (`argon2id_hash`, `argon2id_verify`) ──

fn :: ca2 take ints [Int]    Int => [Int]
      ca2 take ints []       _   =  []
      ca2 take ints (x:rest) n   =
        | n <= 0    = []
        | otherwise = [x] :: (ca2 take ints rest (n - 1))

fn :: ca2 drop ints [Int]    Int => [Int]
      ca2 drop ints []       _   =  []
      ca2 drop ints (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = ca2 drop ints rest (n - 1)

fn :: ca2 pad zeroes Int => [Int]
      ca2 pad zeroes n   =
        | n <= 0    = []
        | otherwise = [0] :: (ca2 pad zeroes (n - 1))

fn :: ca2 u64 lh Int Int => U64
      ca2 u64 lh lo  hi  =
        ((hi and 0xFFFFFFFF) shl 32) or (lo and 0xFFFFFFFF)

fn :: ca2 u32 to le4 Int => [Int]
      ca2 u32 to le4 w   =
        uw = u32 val w
        [uw % 256, (uw / 256) % 256, (uw / 65536) % 256, (uw / 16777216) % 256]

fn :: ca2 bytes to u32 le [Int] Int => Int
      ca2 bytes to u32 le bs off =
        (c nth int bs off) + ((c nth int bs (off + 1)) * 256) + ((c nth int bs (off + 2)) * 65536) + ((c nth int bs (off + 3)) * 16777216)

fn :: ca2 zero w16 => Tensor[U64 * 16]
      ca2 zero w16 =
        Tensor[U64 * 16]

fn :: ca2 zero blk8 => Tensor[U64 * 8 * 16]
      ca2 zero blk8 =
        Tensor[U64 * 8 * 16]

fn :: ca2 b2b iv w16 => Tensor[U64 * 16]
      ca2 b2b iv w16 =
        iv = Tensor[U64 * 16]
        iv_(0) = ca2 u64 lh 4089235720 1779033703
        iv_(1) = ca2 u64 lh 2227873595 3144134277
        iv_(2) = ca2 u64 lh 4271175723 1013904242
        iv_(3) = ca2 u64 lh 1595750129 2773480762
        iv_(4) = ca2 u64 lh 2917565137 1359893119
        iv_(5) = ca2 u64 lh 725511199  2600822924
        iv_(6) = ca2 u64 lh 4215389547 528734635
        iv_(7) = ca2 u64 lh 327033209  1541459225
        iv

fn :: ca2 b2b g4 U64 U64 U64 U64 U64 U64 => U64 U64 U64 U64
      ca2 b2b g4 a0 b0 c0 d0 mx my =
        mut a = a0 + b0 + mx
        mut d = (d0 xor a) rotr 32
        mut c = c0 + d
        mut b = (b0 xor c) rotr 24
        a = a + b + my
        d = (d xor a) rotr 16
        c = c + d
        b = (b xor c) rotr 63
        (a, b, c, d)

fn :: ca2 b2b sigma Int => [Int]
      ca2 b2b sigma r   =
        | (r % 10) == 0 = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
        | (r % 10) == 1 = [14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3]
        | (r % 10) == 2 = [11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4]
        | (r % 10) == 3 = [7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8]
        | (r % 10) == 4 = [9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13]
        | (r % 10) == 5 = [2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9]
        | (r % 10) == 6 = [12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11]
        | (r % 10) == 7 = [13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10]
        | (r % 10) == 8 = [6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5]
        | otherwise     = [10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0]

fn :: ca2 b2b round Tensor[U64 * 16] Tensor[U64 * 16] Int => Tensor[U64 * 16]
      ca2 b2b round v m r =
        s = ca2 b2b sigma r
        v_(0), v_(4), v_(8),  v_(12) = ca2 b2b g4 v_(0) v_(4) v_(8)  v_(12) m_(c nth int s 0)  m_(c nth int s 1)
        v_(1), v_(5), v_(9),  v_(13) = ca2 b2b g4 v_(1) v_(5) v_(9)  v_(13) m_(c nth int s 2)  m_(c nth int s 3)
        v_(2), v_(6), v_(10), v_(14) = ca2 b2b g4 v_(2) v_(6) v_(10) v_(14) m_(c nth int s 4)  m_(c nth int s 5)
        v_(3), v_(7), v_(11), v_(15) = ca2 b2b g4 v_(3) v_(7) v_(11) v_(15) m_(c nth int s 6)  m_(c nth int s 7)
        v_(0), v_(5), v_(10), v_(15) = ca2 b2b g4 v_(0) v_(5) v_(10) v_(15) m_(c nth int s 8)  m_(c nth int s 9)
        v_(1), v_(6), v_(11), v_(12) = ca2 b2b g4 v_(1) v_(6) v_(11) v_(12) m_(c nth int s 10) m_(c nth int s 11)
        v_(2), v_(7), v_(8),  v_(13) = ca2 b2b g4 v_(2) v_(7) v_(8)  v_(13) m_(c nth int s 12) m_(c nth int s 13)
        v_(3), v_(4), v_(9),  v_(14) = ca2 b2b g4 v_(3) v_(4) v_(9)  v_(14) m_(c nth int s 14) m_(c nth int s 15)
        v

fn :: ca2 b2b rounds Tensor[U64 * 16] Tensor[U64 * 16] Int => Tensor[U64 * 16]
      ca2 b2b rounds v m r =
        | r >= 12   = v
        | otherwise = ca2 b2b rounds (ca2 b2b round v m r) m (r + 1)

fn :: ca2 b2b compress Tensor[U64 * 16] Tensor[U64 * 16] Int Bool => Tensor[U64 * 16]
      ca2 b2b compress h m t is_last =
        iv  = ca2 b2b iv w16
        v12 = iv_(4) xor (ca2 u64 lh t 0)
        v14 =
          | is_last   = iv_(6) xor (ca2 u64 lh 4294967295 4294967295)
          | otherwise = iv_(6)
        v0      = Tensor[U64 * 16]
        v0_(0)  = h_(0)
        v0_(1)  = h_(1)
        v0_(2)  = h_(2)
        v0_(3)  = h_(3)
        v0_(4)  = h_(4)
        v0_(5)  = h_(5)
        v0_(6)  = h_(6)
        v0_(7)  = h_(7)
        v0_(8)  = iv_(0)
        v0_(9)  = iv_(1)
        v0_(10) = iv_(2)
        v0_(11) = iv_(3)
        v0_(12) = v12
        v0_(13) = iv_(5)
        v0_(14) = v14
        v0_(15) = iv_(7)
        vf = ca2 b2b rounds v0 m 0
        out = Tensor[U64 * 16]
        out_(0) = h_(0) xor (vf_(0) xor vf_(8))
        out_(1) = h_(1) xor (vf_(1) xor vf_(9))
        out_(2) = h_(2) xor (vf_(2) xor vf_(10))
        out_(3) = h_(3) xor (vf_(3) xor vf_(11))
        out_(4) = h_(4) xor (vf_(4) xor vf_(12))
        out_(5) = h_(5) xor (vf_(5) xor vf_(13))
        out_(6) = h_(6) xor (vf_(6) xor vf_(14))
        out_(7) = h_(7) xor (vf_(7) xor vf_(15))
        out

fn :: ca2 bytes to u64 [Int] Int => U64
      ca2 bytes to u64 bs off =
        ca2 u64 lh (ca2 bytes to u32 le bs off) (ca2 bytes to u32 le bs (off + 4))

fn :: ca2 bytes to w16 [Int] Int => Tensor[U64 * 16]
      ca2 bytes to w16 bs off =
        w      = Tensor[U64 * 16]
        w_(0)  = ca2 bytes to u64 bs off
        w_(1)  = ca2 bytes to u64 bs (off + 8)
        w_(2)  = ca2 bytes to u64 bs (off + 16)
        w_(3)  = ca2 bytes to u64 bs (off + 24)
        w_(4)  = ca2 bytes to u64 bs (off + 32)
        w_(5)  = ca2 bytes to u64 bs (off + 40)
        w_(6)  = ca2 bytes to u64 bs (off + 48)
        w_(7)  = ca2 bytes to u64 bs (off + 56)
        w_(8)  = ca2 bytes to u64 bs (off + 64)
        w_(9)  = ca2 bytes to u64 bs (off + 72)
        w_(10) = ca2 bytes to u64 bs (off + 80)
        w_(11) = ca2 bytes to u64 bs (off + 88)
        w_(12) = ca2 bytes to u64 bs (off + 96)
        w_(13) = ca2 bytes to u64 bs (off + 104)
        w_(14) = ca2 bytes to u64 bs (off + 112)
        w_(15) = ca2 bytes to u64 bs (off + 120)
        w

fn :: ca2 u64 to le8 U64 => [Int]
      ca2 u64 to le8 x   =
        (ca2 u32 to le4 (x and 0xFFFFFFFF)) :: (ca2 u32 to le4 ((x shr 32) and 0xFFFFFFFF))

fn :: ca2 h8 to bytes Tensor[U64 * 16] => [Int]
      ca2 h8 to bytes h =
        (ca2 u64 to le8 h_(0)) :: (ca2 u64 to le8 h_(1)) :: (ca2 u64 to le8 h_(2)) :: (ca2 u64 to le8 h_(3)) :: (ca2 u64 to le8 h_(4)) :: (ca2 u64 to le8 h_(5)) :: (ca2 u64 to le8 h_(6)) :: (ca2 u64 to le8 h_(7))

fn :: ca2 b2b loop Tensor[U64 * 16] [Int] Int => Tensor[U64 * 16]
      ca2 b2b loop h rem t =
        | (c list len rem) <= 128 =
          rlen   = c list len rem
          padded = rem :: (ca2 pad zeroes (128 - rlen))
          ca2 b2b compress h (ca2 bytes to w16 padded 0) (t + rlen) True
        | otherwise =
          blk  = ca2 take ints rem 128
          rest = ca2 drop ints rem 128
          h1   = ca2 b2b compress h (ca2 bytes to w16 blk 0) (t + 128) False
          ca2 b2b loop h1 rest (t + 128)

fn :: ca2 blake2b [Int] Int    => [Int]
      ca2 blake2b msg   outlen =
        h_in    = ca2 b2b iv w16
        h_in_(0) = h_in_(0) xor (ca2 u64 lh (16842752 + outlen) 0)
        h_fi    = ca2 b2b loop h_in msg 0
        ca2 take ints (ca2 h8 to bytes h_fi) outlen

fn :: ca2 b2b long loop [Int] Int Int Int => [Int]
      ca2 b2b long loop v idx r outlen =
        | idx > r =
          rem = outlen - (32 * r)
          ca2 blake2b v rem
        | otherwise =
          v_next = ca2 blake2b v 64
          (ca2 take ints v_next 32) :: (ca2 b2b long loop v_next (idx + 1) r outlen)

fn :: ca2 blake2b long [Int] Int    => [Int]
      ca2 blake2b long data  outlen =
        | outlen <= 64 = ca2 blake2b ((ca2 u32 to le4 outlen) :: data) outlen
        | otherwise =
          r  = ((outlen + 31) / 32) - 2
          v1 = ca2 blake2b ((ca2 u32 to le4 outlen) :: data) 64
          (ca2 take ints v1 32) :: (ca2 b2b long loop v1 2 r outlen)

fn :: ca2 bitxor blk8 Tensor[U64 * 8 * 16] Tensor[U64 * 8 * 16] => Tensor[U64 * 8 * 16]
      ca2 bitxor blk8 a b =
        a_ij xor b_ij

fn :: ca2 get blk8 Tensor[U64 * 8 * 16] Int => U64
      ca2 get blk8 blk idx =
        blk_((idx / 16) % 8, idx % 16)

fn :: ca2 bytes to blk8 row Tensor[U64 * 8 * 16] [Int] Int Int => Tensor[U64 * 8 * 16]
      ca2 bytes to blk8 row blk bs r c =
        | c >= 16   = blk
        | otherwise =
          blk_(r, c) = ca2 bytes to u64 bs (c * 8)
          ca2 bytes to blk8 row blk bs r (c + 1)

fn :: ca2 bytes to blk8 loop Tensor[U64 * 8 * 16] [Int] Int => Tensor[U64 * 8 * 16]
      ca2 bytes to blk8 loop blk rem r =
        | r >= 8    = blk
        | otherwise =
          row_bs = ca2 take ints rem 128
          rest   = ca2 drop ints rem 128
          ca2 bytes to blk8 loop (ca2 bytes to blk8 row blk row_bs r 0) rest (r + 1)

fn :: ca2 bytes to blk8 [Int] => Tensor[U64 * 8 * 16]
      ca2 bytes to blk8 bs    =
        ca2 bytes to blk8 loop (ca2 zero blk8) bs 0

fn :: ca2 blk8 row to bytes Tensor[U64 * 8 * 16] Int Int => [Int]
      ca2 blk8 row to bytes b r c =
        | c >= 16   = []
        | otherwise = (ca2 u64 to le8 b_(r, c)) :: (ca2 blk8 row to bytes b r (c + 1))

fn :: ca2 blk8 to bytes loop Tensor[U64 * 8 * 16] Int => [Int]
      ca2 blk8 to bytes loop b r =
        | r >= 8    = []
        | otherwise = (ca2 blk8 row to bytes b r 0) :: (ca2 blk8 to bytes loop b (r + 1))

fn :: ca2 blk8 to bytes Tensor[U64 * 8 * 16] => [Int]
      ca2 blk8 to bytes b =
        ca2 blk8 to bytes loop b 0

fn :: ca2 zero mem => CT16
      ca2 zero mem =
        zb = ca2 zero blk8
        m1 = CT16 zb zb zb zb zb zb zb zb zb zb zb zb zb zb zb zb
        m2 = CT16 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1
        m3 = CT16 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2
        CT16 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3

fn :: ca2 nth blk CT16 Int => Tensor[U64 * 8 * 16]
      ca2 nth blk m    idx =
        m3 = c get16 m  ((idx / 4096) % 16)
        m2 = c get16 m3 ((idx / 256) % 16)
        m1 = c get16 m2 ((idx / 16) % 16)
        c get16 m1 (idx % 16)

fn :: ca2 set blk CT16 Int Tensor[U64 * 8 * 16] => CT16
      ca2 set blk m idx val =
        i3 = (idx / 4096) % 16
        i2 = (idx / 256) % 16
        i1 = (idx / 16) % 16
        i0 = idx % 16
        m3 = c get16 m  i3
        m2 = c get16 m3 i2
        m1 = c get16 m2 i1
        n1 = c set16 m1 i0 val
        n2 = c set16 m2 i1 n1
        n3 = c set16 m3 i2 n2
        c set16 m i3 n3

fn :: ca2 init all lanes loop CT16 [Int] Int Int Int => CT16
      ca2 init all lanes loop mem h0 l lanes q =
        | l >= lanes = mem
        | otherwise  =
          b0   = ca2 bytes to blk8 (ca2 blake2b long (h0 :: (ca2 u32 to le4 0) :: (ca2 u32 to le4 l)) 1024)
          b1   = ca2 bytes to blk8 (ca2 blake2b long (h0 :: (ca2 u32 to le4 1) :: (ca2 u32 to le4 l)) 1024)
          mem1 = ca2 set blk mem (l * q) b0
          mem2 = ca2 set blk mem1 ((l * q) + 1) b1
          ca2 init all lanes loop mem2 h0 (l + 1) lanes q

fn :: ca2 init all lanes [Int] Int Int Int => CT16
      ca2 init all lanes h0 l lanes q =
        ca2 init all lanes loop (ca2 zero mem) h0 l lanes q

fn :: ca2 make addr blk CA2Ctx Int => Tensor[U64 * 8 * 16]
      ca2 make addr blk ctx ctr =
        zb          = ca2 zero blk8
        in_blk      = ca2 zero blk8
        m_prime     = (cp_lanes ctx) * (cq_cols ctx)
        in_blk_(0, 0) = ca2 u64 lh (cr_pass ctx) 0
        in_blk_(0, 1) = ca2 u64 lh (cl_lane ctx) 0
        in_blk_(0, 2) = ca2 u64 lh (cs_slice ctx) 0
        in_blk_(0, 3) = ca2 u64 lh m_prime 0
        in_blk_(0, 4) = ca2 u64 lh (ct_iters ctx) 0
        in_blk_(0, 5) = ca2 u64 lh 2 0
        in_blk_(0, 6) = ca2 u64 lh ctr 0
        mid         = compress block zb in_blk
        compress block zb mid

fn :: ca2 calc w size p0 CA2Ctx Int Bool => Int
      ca2 calc w size p0 ctx idx same_lane =
        | (cs_slice ctx) == 0 or same_lane = ((cs_slice ctx) * (cseg_len ctx)) + idx - 1
        | idx == 0                         = ((cs_slice ctx) * (cseg_len ctx)) - 1
        | otherwise                        = (cs_slice ctx) * (cseg_len ctx)

fn :: ca2 calc w size pn CA2Ctx Int Bool => Int
      ca2 calc w size pn ctx idx same_lane =
        | same_lane = ((cq_cols ctx) - (cseg_len ctx)) + idx - 1
        | idx == 0  = ((cq_cols ctx) - (cseg_len ctx)) - 1
        | otherwise = (cq_cols ctx) - (cseg_len ctx)

fn :: ca2 calc w size CA2Ctx Int Bool => Int
      ca2 calc w size ctx idx same_lane =
        | (cr_pass ctx) == 0 = ca2 calc w size p0 ctx idx same_lane
        | otherwise          = ca2 calc w size pn ctx idx same_lane

fn :: ca2 step addr Bool CA2Ctx Int Tensor[U64 * 8 * 16] => Tensor[U64 * 8 * 16]
      ca2 step addr need_adr ctx idx addr_blk =
        | need_adr  = ca2 make addr blk ctx ((idx / 128) + 1)
        | otherwise = addr_blk

fn :: ca2 step jpair Bool Tensor[U64 * 8 * 16] Int CT16 Int => U64
      ca2 step jpair data_ind addr2 idx mem prev_idx =
        | data_ind  = ca2 get blk8 addr2 (idx % 128)
        | otherwise =
          pblk = ca2 nth blk mem prev_idx
          pblk_(0, 0)

fn :: ca2 ref lane Int Int Int Int Int => Int
      ca2 ref lane r s l j2 p =
        | r == 0 and s == 0 = l
        | otherwise         = j2 % p

fn :: ca2 st pos Int Int Int => Int
      ca2 st pos r s sl =
        | r == 0    = 0
        | otherwise = ((s + 1) % 4) * sl

fn :: ca2 fin blk Int Tensor[U64 * 8 * 16] CT16 Int => Tensor[U64 * 8 * 16]
      ca2 fin blk r new_blk mem curr_idx =
        | r == 0    = new_blk
        | otherwise = ca2 bitxor blk8 new_blk (ca2 nth blk mem curr_idx)

fn :: ca2 fill segment CT16 CA2Ctx Int Tensor[U64 * 8 * 16] => CT16
      ca2 fill segment mem ctx idx addr_blk =
        | idx >= (cseg_len ctx) = mem
        | otherwise =
          r        = cr_pass ctx
          s        = cs_slice ctx
          l        = cl_lane ctx
          p        = cp_lanes ctx
          q        = cq_cols ctx
          sl       = cseg_len ctx
          curr_col = (s * sl) + idx
          prev_col = ((curr_col - 1) + q) % q
          data_ind = r == 0 and s < 2
          need_adr = data_ind and ((idx % 128) == 0 or (idx == 2 and r == 0 and s == 0))
          addr2    = ca2 step addr need_adr ctx idx addr_blk
          j_pair   = ca2 step jpair data_ind addr2 idx mem ((l * q) + prev_col)
          j1       = j_pair and 0xFFFFFFFF
          j2       = (j_pair shr 32) and 0xFFFFFFFF
          ref_lane = ca2 ref lane r s l j2 p
          w_size   = ca2 calc w size ctx idx (ref_lane == l)
          x_val    = ((j1 * j1) shr 32) and 0xFFFFFFFF
          y_val    = (((w_size and 0xFFFFFFFF) * x_val) shr 32) and 0xFFFFFFFF
          zz       = w_size - 1 - y_val
          st_pos   = ca2 st pos r s sl
          ref_col  = (st_pos + zz) % q
          prev_blk = ca2 nth blk mem ((l * q) + prev_col)
          ref_blk  = ca2 nth blk mem ((ref_lane * q) + ref_col)
          new_blk  = compress block prev_blk ref_blk
          fin_blk  = ca2 fin blk r new_blk mem ((l * q) + curr_col)
          mem2     = ca2 set blk mem ((l * q) + curr_col) fin_blk
          ca2 fill segment mem2 ctx (idx + 1) addr2

fn :: ca2 start j CA2Ctx => Int
      ca2 start j ctx    =
        | (cr_pass ctx) == 0 and (cs_slice ctx) == 0 = 2
        | otherwise                                  = 0

fn :: ca2 run lanes CT16 CA2Ctx Int => CT16
      ca2 run lanes mem ctx l =
        | l >= (cp_lanes ctx) = mem
        | otherwise =
          ctx_l   = ctx with cl_lane = l
          start_j = ca2 start j ctx
          mem2    = ca2 fill segment mem ctx_l start_j (ca2 zero blk8)
          ca2 run lanes mem2 ctx (l + 1)

fn :: ca2 run slices CT16 CA2Ctx Int => CT16
      ca2 run slices mem ctx s =
        | s >= 4 = mem
        | otherwise =
          ctx_s = ctx with cs_slice = s
          mem2  = ca2 run lanes mem ctx_s 0
          ca2 run slices mem2 ctx (s + 1)

fn :: ca2 run passes CT16 CA2Ctx Int => CT16
      ca2 run passes mem ctx r =
        | r >= (ct_iters ctx) = mem
        | otherwise =
          ctx_r = ctx with cr_pass = r
          mem2  = ca2 run slices mem ctx_r 0
          ca2 run passes mem2 ctx (r + 1)

fn :: ca2 bitxor final lanes CT16 Int Int Int Tensor[U64 * 8 * 16] => Tensor[U64 * 8 * 16]
      ca2 bitxor final lanes mem l lanes q acc =
        | l >= lanes = acc
        | otherwise  =
          blk = ca2 nth blk mem ((l * q) + (q - 1))
          ca2 bitxor final lanes mem (l + 1) lanes q (ca2 bitxor blk8 acc blk)

fn :: ca2 derive raw tag [Int] [Int] Int Int Int Int => [Int]
      ca2 derive raw tag pwd_raw salt_bytes m t p tlen =
        h0_in = (ca2 u32 to le4 p) :: (ca2 u32 to le4 tlen) :: (ca2 u32 to le4 m) :: (ca2 u32 to le4 t) :: (ca2 u32 to le4 19) :: (ca2 u32 to le4 2) :: (ca2 u32 to le4 (c list len pwd_raw)) :: pwd_raw :: (ca2 u32 to le4 (c list len salt_bytes)) :: salt_bytes :: (ca2 u32 to le4 0) :: (ca2 u32 to le4 0)
        h0    = ca2 blake2b h0_in 64
        sl    = m / (4 * p)
        q     = sl * 4
        mem0  = ca2 init all lanes h0 0 p q
        ctx   = CA2Ctx 0 0 0 p q sl t
        memf  = ca2 run passes mem0 ctx 0
        c0    = ca2 nth blk memf (q - 1)
        c_fin = ca2 bitxor final lanes memf 1 p q c0
        ca2 blake2b long (ca2 blk8 to bytes c_fin) tlen

fn :: ca2 b64 alphabet => String
      ca2 b64 alphabet =  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

fn :: ca2 b64 char Int => String
      ca2 b64 char idx =  str slice (ca2 b64 alphabet) (idx % 64) ((idx % 64) + 1)

fn :: ca2 b64 encode [Int]           => String
      ca2 b64 encode []              =  ""
      ca2 b64 encode (b0:[])         =
        c0 = b0 / 4
        c1 = (b0 % 4) * 16
        (ca2 b64 char c0) + (ca2 b64 char c1)
      ca2 b64 encode (b0:b1:[])      =
        c0 = b0 / 4
        c1 = ((b0 % 4) * 16) + (b1 / 16)
        c2 = (b1 % 16) * 4
        s0 = (ca2 b64 char c0) + (ca2 b64 char c1)
        s0 + (ca2 b64 char c2)
      ca2 b64 encode (b0:b1:b2:rest) =
        c0 = b0 / 4
        c1 = ((b0 % 4) * 16) + (b1 / 16)
        c2 = ((b1 % 16) * 4) + (b2 / 64)
        c3 = b2 % 64
        s0 = (ca2 b64 char c0) + (ca2 b64 char c1)
        s1 = (ca2 b64 char c2) + (ca2 b64 char c3)
        s2 = s0 + s1
        s2 + (ca2 b64 encode rest)

fn :: ca2 b64 char val Int => Int
      ca2 b64 char val c   =
        | c >= 65 and c <= 90  = c - 65
        | c >= 97 and c <= 122 = (c - 97) + 26
        | c >= 48 and c <= 57  = (c - 48) + 52
        | c == 43              = 62
        | c == 47              = 63
        | otherwise            = 0 - 1

fn :: ca2 valid b64 chars String Int Int => Bool
      ca2 valid b64 chars s idx len =
        | idx >= len                                 = True
        | (ca2 b64 char val (str char at s idx)) < 0 = False
        | otherwise                                  = ca2 valid b64 chars s (idx + 1) len

fn :: ca2 is valid b64 String => Bool
      ca2 is valid b64 s      =
        | (str len s) == 0 or ((str len s) % 4) == 1 = False
        | str contains s "="                         = False
        | otherwise                                  = ca2 valid b64 chars s 0 (str len s)

fn :: ca2 b64 decode rem String Int Int Int => [Int]
      ca2 b64 decode rem s idx len rem =
        | rem <= 0 = []
        | rem == 2 =
          v0 = ca2 b64 char val (str char at s idx)
          v1 = ca2 b64 char val (str char at s (idx + 1))
          [((v0 * 4) + (v1 / 16)) % 256]
        | rem == 3 =
          v0 = ca2 b64 char val (str char at s idx)
          v1 = ca2 b64 char val (str char at s (idx + 1))
          v2 = ca2 b64 char val (str char at s (idx + 2))
          [((v0 * 4) + (v1 / 16)) % 256, (((v1 % 16) * 16) + (v2 / 4)) % 256]
        | otherwise =
          v0 = ca2 b64 char val (str char at s idx)
          v1 = ca2 b64 char val (str char at s (idx + 1))
          v2 = ca2 b64 char val (str char at s (idx + 2))
          v3 = ca2 b64 char val (str char at s (idx + 3))
          b0 = ((v0 * 4) + (v1 / 16)) % 256
          b1 = (((v1 % 16) * 16) + (v2 / 4)) % 256
          b2 = (((v2 % 4) * 64) + v3) % 256
          [b0, b1, b2] :: (ca2 b64 decode loop s (idx + 4) len)

fn :: ca2 b64 decode loop String Int Int => [Int]
      ca2 b64 decode loop s idx len = ca2 b64 decode rem s idx len (len - idx)

fn :: ca2 b64 decode String => [Int]
      ca2 b64 decode s      =  ca2 b64 decode loop s 0 (str len s)

fn :: ca2 split str String Int Int Int Int => [String]
      ca2 split str s ch start idx len =
        | idx >= len                = [str slice s start len]
        | (str char at s idx) == ch = [str slice s start idx] :: (ca2 split str s ch (idx + 1) (idx + 1) len)
        | otherwise                 = ca2 split str s ch start (idx + 1) len

fn :: ca2 nth str [String] Int => String
      ca2 nth str []       _   =  ""
      ca2 nth str (x:rest) idx =
        | idx <= 0  = x
        | otherwise = ca2 nth str rest (idx - 1)

fn :: ca2 str list len [String] => Int
      ca2 str list len []       =  0
      ca2 str list len (_:rest) =  1 + (ca2 str list len rest)

fn :: ca2 is digits String Int Int => Bool
      ca2 is digits s idx len =
        | idx >= len                                           = True
        | (str char at s idx) < 48 or (str char at s idx) > 57 = False
        | otherwise                                            = ca2 is digits s (idx + 1) len

fn :: ca2 parse kv String String => Int
      ca2 parse kv item   prefix =
        | (str len item) <= (str len prefix)                        = 0 - 1
        | not (str starts with item prefix)                         = 0 - 1
        | not (ca2 is digits item (str len prefix) (str len item))  = 0 - 1
        | otherwise                                                 = str to int (str slice item (str len prefix) (str len item))

fn :: ca2 verify decoded String [Int] [Int] Int Int Int Int => Bool
      ca2 verify decoded pwd salt_bs tag_bs m t p tlen =
        | (c list len salt_bs) < 8 or tlen < 4 or tlen > 64 or t < 1 or p < 1 or p > 255 or m < (8 * p) = False
        | otherwise =
          comp_bs  = ca2 derive raw tag (bytes to list pwd) salt_bs m t p tlen
          comp_b64 = ca2 b64 encode comp_bs
          exp_b64  = ca2 b64 encode tag_bs
          ct equal comp_b64 exp_b64

fn :: ca2 verify kvs String [String] String String => Bool
      ca2 verify kvs pwd kvs s_b64 t_b64 =
        | (ca2 str list len kvs) != 3 or not (ca2 is valid b64 s_b64) or not (ca2 is valid b64 t_b64) = False
        | otherwise =
          m      = ca2 parse kv (ca2 nth str kvs 0) "m="
          t      = ca2 parse kv (ca2 nth str kvs 1) "t="
          p      = ca2 parse kv (ca2 nth str kvs 2) "p="
          tag_bs = ca2 b64 decode t_b64
          ca2 verify decoded pwd (ca2 b64 decode s_b64) tag_bs m t p (c list len tag_bs)

fn :: ca2 verify parts String [String] => Bool
      ca2 verify parts pwd    parts    =
        | (ca2 str list len parts) != 6       = False
        | (ca2 nth str parts 0) != ""         = False
        | (ca2 nth str parts 1) != "argon2id" = False
        | (ca2 nth str parts 2) != "v=19"     = False
        | otherwise =
          p_str = ca2 nth str parts 3
          kvs   = ca2 split str p_str 44 0 0 (str len p_str)
          s_b64 = ca2 nth str parts 4
          t_b64 = ca2 nth str parts 5
          ca2 verify kvs pwd kvs s_b64 t_b64

fn :: ca2 hash checked String [Int] Int Int Int => String
      ca2 hash checked pwd salt_bs m_kib t_iters p_lanes =
        | (c list len salt_bs) < 8 or t_iters < 1 or p_lanes < 1 or p_lanes > 255 or m_kib < (8 * p_lanes) = ""
        | otherwise =
          tag_bs   = ca2 derive raw tag (bytes to list pwd) salt_bs m_kib t_iters p_lanes 32
          salt_b64 = ca2 b64 encode salt_bs
          tag_b64  = ca2 b64 encode tag_bs
          "$argon2id$v=19$m={m_kib},t={t_iters},p={p_lanes}${salt_b64}${tag_b64}"

-- @implements FR-CRYPTO-001
-- @implements FR-CRYPTO-004
-- @implements NFR-PERF-001
-- @implements API-CRYPTO-001
-- @implements DM-Argon2
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: argon2id hash String String Int Int Int => String
      argon2id hash pwd salt m_kib t_iters p_lanes =
        ca2 hash checked pwd (bytes to list salt) m_kib t_iters p_lanes

-- @implements FR-CRYPTO-004
-- @implements API-CRYPTO-001
fn :: argon2id hash phc String String Int Int Int => String
      argon2id hash phc pwd salt m_kib t_iters p_lanes =
        argon2id hash pwd salt m_kib t_iters p_lanes

-- @implements FR-CRYPTO-001
-- @implements FR-CRYPTO-004
-- @implements NFR-PERF-001
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
fn :: argon2id verify String String => Bool
      argon2id verify pwd    phc    =
        | not (str starts with phc "$argon2id$") = False
        | otherwise                              = ca2 verify parts pwd (ca2 split str phc 36 0 0 (str len phc))

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

fn :: chacha qr Int Int Int Int => Int Int Int Int
      chacha qr a0 b0 c0 d0 =
        a1 = u32 val (a0 + b0)
        d1 = rotl32 (bxor d0 a1) 16
        c1 = u32 val (c0 + d1)
        b1 = rotl32 (bxor b0 c1) 12
        a2 = u32 val (a1 + b1)
        d2 = rotl32 (bxor d1 a2) 8
        c2 = u32 val (c1 + d2)
        b2 = rotl32 (bxor b1 c2) 7
        (a2, b2, c2, d2)

fn :: chacha double round Tensor[Int * 16] => Tensor[Int * 16]
      chacha double round st =
        st_(0), st_(4), st_(8),  st_(12) = chacha qr st_(0) st_(4) st_(8)  st_(12)
        st_(1), st_(5), st_(9),  st_(13) = chacha qr st_(1) st_(5) st_(9)  st_(13)
        st_(2), st_(6), st_(10), st_(14) = chacha qr st_(2) st_(6) st_(10) st_(14)
        st_(3), st_(7), st_(11), st_(15) = chacha qr st_(3) st_(7) st_(11) st_(15)
        st_(0), st_(5), st_(10), st_(15) = chacha qr st_(0) st_(5) st_(10) st_(15)
        st_(1), st_(6), st_(11), st_(12) = chacha qr st_(1) st_(6) st_(11) st_(12)
        st_(2), st_(7), st_(8),  st_(13) = chacha qr st_(2) st_(7) st_(8)  st_(13)
        st_(3), st_(4), st_(9),  st_(14) = chacha qr st_(3) st_(4) st_(9)  st_(14)
        st

fn :: chacha rounds loop Tensor[Int * 16] Int => Tensor[Int * 16]
      chacha rounds loop st idx =
        | idx >= 10 = st
        | otherwise = chacha rounds loop (chacha double round st) (idx + 1)

fn :: words16 tensor to bytes Tensor[Int * 16] Tensor[Int * 16] Int => [Int]
      words16 tensor to bytes mixed init_st idx =
        | idx >= 16 = []
        | otherwise = (u32 to le4 ((mixed_(idx) + init_st_(idx)) and 0xFFFFFFFF)) :: (words16 tensor to bytes mixed init_st (idx + 1))

fn :: chacha20 init st [Int] [Int] Int => Tensor[Int * 16]
      chacha20 init st key_bs nonce_bs counter =
        st      = Tensor[Int * 16]
        st_(0)  = 1634760805
        st_(1)  = 857760878
        st_(2)  = 2036477234
        st_(3)  = 1797285236
        st_(4)  = le32 at key_bs 0
        st_(5)  = le32 at key_bs 4
        st_(6)  = le32 at key_bs 8
        st_(7)  = le32 at key_bs 12
        st_(8)  = le32 at key_bs 16
        st_(9)  = le32 at key_bs 20
        st_(10) = le32 at key_bs 24
        st_(11) = le32 at key_bs 28
        st_(12) = u32 val counter
        st_(13) = le32 at nonce_bs 0
        st_(14) = le32 at nonce_bs 4
        st_(15) = le32 at nonce_bs 8
        st

fn :: chacha20 block [Int]  [Int]    Int     => [Int]
      chacha20 block key_bs nonce_bs counter =
        init_st = chacha20 init st key_bs nonce_bs counter
        work_st = chacha20 init st key_bs nonce_bs counter
        mixed   = chacha rounds loop work_st 0
        words16 tensor to bytes mixed init_st 0

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
        | (str len key) != 32 or (str len nonce) != 12 = ""
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
        | (str len key) != 32 or (str len nonce) != 12 or (str len ciphertext_and_tag) < 16 = (0 - 7, "")
        | otherwise =
          total_len = str len ciphertext_and_tag
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
