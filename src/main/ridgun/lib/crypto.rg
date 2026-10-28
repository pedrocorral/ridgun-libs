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

module :: crypto

import argon2id

type CT16    = ct0: A, ct1: A, ct2: A, ct3: A, ct4: A, ct5: A, ct6: A, ct7: A, ct8: A, ct9: A, ct10: A, ct11: A, ct12: A, ct13: A, ct14: A, ct15: A
type CPbkCtx = cptbl: CT16, cpipad: String, cpopad: String

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
        | ub == 0 = str slice (sha256 raw "00679") 0 1
        | otherwise =
          idx = (ub - 128) * 5
          lut = "0056400101002080010000179000010024100109003430040100361007870009100353001870030400471000870020200071002360012501171004140236900275001810016001398004440080400017005250027000314001400024700004006350015700183005940027600207007720028400601003400038000839006850084900617003060113500277000320006900483000580019200151008700008500193000100057000070002880002600326006460038800018009190028900103006000043900073011700038900628007210077300074004740006000041001410019900066003680001900383001730005700558000670024500065002030031900000008250001100128001360034900030003750039600228002380008400618005900031800062001770087900076002570009600034002200001600161"
          str slice (sha256 raw (str slice lut idx (idx + 5))) 0 1

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: byte str Int => String
      byte str n   =
        byte str norm (norm byte n)

fn :: c sb append3 String String => String String String String
      c sb append3 n2 c3 =
        | (str len n2) < 65536 = ("", "", n2, c3)
        | otherwise            = ("", "", "", c3 + n2)

fn :: c sb append2 String String String => String String String String
      c sb append2 n1 c2 c3 =
        | (str len n1) < 8192 = ("", n1, c2, c3)
        | otherwise           = c sb append3 (c2 + n1) c3

fn :: c sb append1 String String String String => String String String String
      c sb append1 n0 c1 c2 c3 =
        | (str len n0) < 512 = (n0, c1, c2, c3)
        | otherwise          = c sb append2 (c1 + n0) c2 c3

fn :: c sb append String String String String String => String String String String
      c sb append chunk c0 c1 c2 c3 =
        c sb append1 (c0 + chunk) c1 c2 c3

fn :: c sb finish String String String String => String
      c sb finish c0 c1 c2 c3 =  ((c3 + c2) + c1) + c0

fn :: c lb append2 [Int] [Int] Int => [Int] [Int] [Int] Int
      c lb append2 n1 l2 cnt =
        | (cnt % 1024) == 0 = ([], [], l2 :: n1, cnt)
        | otherwise         = ([], n1, l2, cnt)

fn :: c lb append1 [Int] [Int] [Int] Int => [Int] [Int] [Int] Int
      c lb append1 n0 l1 l2 cnt =
        | (cnt % 32) == 0 = c lb append2 (l1 :: n0) l2 cnt
        | otherwise       = (n0, l1, l2, cnt)

fn :: c lb append Int [Int] [Int] [Int] Int => [Int] [Int] [Int] Int
      c lb append item l0 l1 l2 cnt =
        c lb append1 (l0 :: [item]) l1 l2 (cnt + 1)

fn :: c lb finish [Int] [Int] [Int] => [Int]
      c lb finish l0 l1 l2 =  l2 :: (l1 :: l0)

fn :: bytes from list loop CT16 [Int] String String String String => String
      bytes from list loop _   []       c0 c1 c2 c3 =  c sb finish c0 c1 c2 c3
      bytes from list loop tbl (b:rest) c0 c1 c2 c3 =
        ub = norm byte b
        ch = c get b256 tbl (ub / 16) (ub % 16)
        n0, n1, n2, n3 = c sb append ch c0 c1 c2 c3
        bytes from list loop tbl rest n0 n1 n2 n3

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: bytes from list [Int]    => String
      bytes from list []       =  ""
      bytes from list bs       =  bytes from list loop (c build b256) bs "" "" "" ""

fn :: bytes to list loop String Int Int [Int] [Int] [Int] Int => [Int]
      bytes to list loop s idx slen l0 l1 l2 cnt =
        | idx >= slen = c lb finish l0 l1 l2
        | otherwise   =
          n0, n1, n2, ncnt = c lb append (norm byte (str char at s idx)) l0 l1 l2 cnt
          bytes to list loop s (idx + 1) slen n0 n1 n2 ncnt

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: bytes to list String => [Int]
      bytes to list s      =
        bytes to list loop s 0 (str len s) [] [] [] 0

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

fn :: bytes list to hex loop [Int] String String String String => String
      bytes list to hex loop []       c0 c1 c2 c3 = c sb finish c0 c1 c2 c3
      bytes list to hex loop (b:rest) c0 c1 c2 c3 =
        n0, n1, n2, n3 = c sb append (crypto byte to hex b) c0 c1 c2 c3
        bytes list to hex loop rest n0 n1 n2 n3

fn :: bytes list to hex [Int] => String
      bytes list to hex bs    =  bytes list to hex loop bs "" "" "" ""

fn :: bytes to hex str String => String
      bytes to hex str raw    =
        bytes list to hex (bytes to list raw)

fn :: crypto hex val Int => Int
      crypto hex val c   =
        | c >= 48 and c <= 57  = c - 48
        | c >= 97 and c <= 102 = (c - 97) + 10
        | c >= 65 and c <= 70  = (c - 65) + 10
        | otherwise            = 0

fn :: hex str to bytes loop String Int Int [Int] [Int] [Int] Int => [Int]
      hex str to bytes loop h idx hlen l0 l1 l2 cnt =
        | (idx + 1) >= hlen = c lb finish l0 l1 l2
        | otherwise         =
          hi = crypto hex val (str char at h idx)
          lo = crypto hex val (str char at h (idx + 1))
          n0, n1, n2, ncnt = c lb append ((hi * 16) + lo) l0 l1 l2 cnt
          hex str to bytes loop h (idx + 2) hlen n0 n1 n2 ncnt

fn :: hex to byte str String => String
      hex to byte str h      =
        bytes from list (hex str to bytes loop h 0 (str len h) [] [] [] 0)

fn :: c list len loop [Int] Int => Int
      c list len loop []       acc = acc
      c list len loop (_:rest) acc = c list len loop rest (acc + 1)

fn :: c list len [Int] => Int
      c list len xs    =  c list len loop xs 0

fn :: c nth int [Int]    Int => Int
      c nth int []       _   =  0
      c nth int (x:rest) idx =
        | idx <= 0  = x
        | otherwise = c nth int rest (idx - 1)

fn :: c take ints loop [Int] Int [Int] => [Int]
      c take ints loop []       _ acc = acc
      c take ints loop (x:rest) n acc =
        | n <= 0    = acc
        | otherwise = c take ints loop rest (n - 1) (acc :: [x])

fn :: c take ints [Int] Int => [Int]
      c take ints xs    n   =  c take ints loop xs n []

fn :: c drop ints [Int]    Int => [Int]
      c drop ints []       _   =  []
      c drop ints (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = c drop ints rest (n - 1)

fn :: c byte slice loop CT16 String Int Int String String String String => String
      c byte slice loop tbl s idx end_idx c0 c1 c2 c3 =
        | idx >= end_idx = c sb finish c0 c1 c2 c3
        | otherwise      =
          ub = norm byte (str char at s idx)
          n0, n1, n2, n3 = c sb append (c get b256 tbl (ub / 16) (ub % 16)) c0 c1 c2 c3
          c byte slice loop tbl s (idx + 1) end_idx n0 n1 n2 n3

fn :: byte slice String Int Int => String
      byte slice s start end_idx =
        slen = str len s
        st   =
          | start < 0 = 0
          | start > slen = slen
          | otherwise = start
        en   =
          | end_idx < st = st
          | end_idx > slen = slen
          | otherwise = end_idx
        c byte slice loop (c build b256) s st en "" "" "" ""

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
        sha256 raw data

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
        inner   = sha256 raw (ipad_s + msg)
        sha256 raw (opad_s + inner)

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
        | idx < 8 =
          | idx < 4 =
            | idx < 2 =
              | idx == 0  = ct0 row
              | otherwise = ct1 row |.
            | otherwise =
              | idx == 2  = ct2 row
              | otherwise = ct3 row |. |.
          | otherwise =
            | idx < 6 =
              | idx == 4  = ct4 row
              | otherwise = ct5 row |.
            | otherwise =
              | idx == 6  = ct6 row
              | otherwise = ct7 row |. |.
        | otherwise =
          | idx < 12 =
            | idx < 10 =
              | idx == 8  = ct8 row
              | otherwise = ct9 row |.
            | otherwise =
              | idx == 10 = ct10 row
              | otherwise = ct11 row |. |.
          | otherwise =
            | idx < 14 =
              | idx == 12 = ct12 row
              | otherwise = ct13 row |.
            | otherwise =
              | idx == 14 = ct14 row
              | otherwise = ct15 row

fn :: c set16 CT16 Int A   => CT16
      c set16 m    idx val =
        | idx < 8 =
          | idx < 4 =
            | idx < 2 =
              | idx == 0  = m with ct0 = val
              | otherwise = m with ct1 = val |.
            | otherwise =
              | idx == 2  = m with ct2 = val
              | otherwise = m with ct3 = val |. |.
          | otherwise =
            | idx < 6 =
              | idx == 4  = m with ct4 = val
              | otherwise = m with ct5 = val |.
            | otherwise =
              | idx == 6  = m with ct6 = val
              | otherwise = m with ct7 = val |. |.
        | otherwise =
          | idx < 12 =
            | idx < 10 =
              | idx == 8  = m with ct8 = val
              | otherwise = m with ct9 = val |.
            | otherwise =
              | idx == 10 = m with ct10 = val
              | otherwise = m with ct11 = val |. |.
          | otherwise =
            | idx < 14 =
              | idx == 12 = m with ct12 = val
              | otherwise = m with ct13 = val |.
            | otherwise =
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
        (c and 15) + ((c shr 6) * 9)

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

fn :: c hex8 word String Int => U64
      c hex8 word h      off =
        n0 = c hex nib (str char at h off)
        n1 = c hex nib (str char at h (off + 1))
        n2 = c hex nib (str char at h (off + 2))
        n3 = c hex nib (str char at h (off + 3))
        n4 = c hex nib (str char at h (off + 4))
        n5 = c hex nib (str char at h (off + 5))
        n6 = c hex nib (str char at h (off + 6))
        n7 = c hex nib (str char at h (off + 7))
        (n0 shl 28) or (n1 shl 24) or (n2 shl 20) or (n3 shl 16) or (n4 shl 12) or (n5 shl 8) or (n6 shl 4) or n7

fn :: c bxor acc8 Tensor[U64 * 8] String => Tensor[U64 * 8]
      c bxor acc8 acc             h      =
        acc_(0) = acc_(0) xor (c hex8 word h 0)
        acc_(1) = acc_(1) xor (c hex8 word h 8)
        acc_(2) = acc_(2) xor (c hex8 word h 16)
        acc_(3) = acc_(3) xor (c hex8 word h 24)
        acc_(4) = acc_(4) xor (c hex8 word h 32)
        acc_(5) = acc_(5) xor (c hex8 word h 40)
        acc_(6) = acc_(6) xor (c hex8 word h 48)
        acc_(7) = acc_(7) xor (c hex8 word h 56)
        acc

fn :: c word32 to raw4 CT16 U64 => String
      c word32 to raw4 tbl w =
        b0 = c get b256 tbl ((w shr 28) and 15) ((w shr 24) and 15)
        b1 = c get b256 tbl ((w shr 20) and 15) ((w shr 16) and 15)
        b2 = c get b256 tbl ((w shr 12) and 15) ((w shr 8) and 15)
        b3 = c get b256 tbl ((w shr 4) and 15)  (w and 15)
        (b0 + b1) + (b2 + b3)

fn :: c acc8 to raw CT16 Tensor[U64 * 8] => String
      c acc8 to raw tbl acc =
        q0 = c word32 to raw4 tbl acc_(0)
        q1 = c word32 to raw4 tbl acc_(1)
        q2 = c word32 to raw4 tbl acc_(2)
        q3 = c word32 to raw4 tbl acc_(3)
        q4 = c word32 to raw4 tbl acc_(4)
        q5 = c word32 to raw4 tbl acc_(5)
        q6 = c word32 to raw4 tbl acc_(6)
        q7 = c word32 to raw4 tbl acc_(7)
        ((q0 + q1) + (q2 + q3)) + ((q4 + q5) + (q6 + q7))

fn :: c list to raw CT16 [Int] => String
      c list to raw _ [] = ""
      c list to raw tbl (b:rest) =
        ub = norm byte b
        (c get b256 tbl (ub / 16) (ub % 16)) + (c list to raw tbl rest)

fn :: c init acc32 String => Tensor[U64 * 32]
      c init acc32 s =
        acc = Tensor[U64 * 32]
        acc_(0)  = str char at s 0
        acc_(1)  = str char at s 1
        acc_(2)  = str char at s 2
        acc_(3)  = str char at s 3
        acc_(4)  = str char at s 4
        acc_(5)  = str char at s 5
        acc_(6)  = str char at s 6
        acc_(7)  = str char at s 7
        acc_(8)  = str char at s 8
        acc_(9)  = str char at s 9
        acc_(10) = str char at s 10
        acc_(11) = str char at s 11
        acc_(12) = str char at s 12
        acc_(13) = str char at s 13
        acc_(14) = str char at s 14
        acc_(15) = str char at s 15
        acc_(16) = str char at s 16
        acc_(17) = str char at s 17
        acc_(18) = str char at s 18
        acc_(19) = str char at s 19
        acc_(20) = str char at s 20
        acc_(21) = str char at s 21
        acc_(22) = str char at s 22
        acc_(23) = str char at s 23
        acc_(24) = str char at s 24
        acc_(25) = str char at s 25
        acc_(26) = str char at s 26
        acc_(27) = str char at s 27
        acc_(28) = str char at s 28
        acc_(29) = str char at s 29
        acc_(30) = str char at s 30
        acc_(31) = str char at s 31
        acc

fn :: c bxor1 acc32 Tensor[U64 * 32] String => Tensor[U64 * 32]
      c bxor1 acc32 acc s =
        acc_(0)  = acc_(0) xor (str char at s 0)
        acc_(1)  = acc_(1) xor (str char at s 1)
        acc_(2)  = acc_(2) xor (str char at s 2)
        acc_(3)  = acc_(3) xor (str char at s 3)
        acc_(4)  = acc_(4) xor (str char at s 4)
        acc_(5)  = acc_(5) xor (str char at s 5)
        acc_(6)  = acc_(6) xor (str char at s 6)
        acc_(7)  = acc_(7) xor (str char at s 7)
        acc_(8)  = acc_(8) xor (str char at s 8)
        acc_(9)  = acc_(9) xor (str char at s 9)
        acc_(10) = acc_(10) xor (str char at s 10)
        acc_(11) = acc_(11) xor (str char at s 11)
        acc_(12) = acc_(12) xor (str char at s 12)
        acc_(13) = acc_(13) xor (str char at s 13)
        acc_(14) = acc_(14) xor (str char at s 14)
        acc_(15) = acc_(15) xor (str char at s 15)
        acc_(16) = acc_(16) xor (str char at s 16)
        acc_(17) = acc_(17) xor (str char at s 17)
        acc_(18) = acc_(18) xor (str char at s 18)
        acc_(19) = acc_(19) xor (str char at s 19)
        acc_(20) = acc_(20) xor (str char at s 20)
        acc_(21) = acc_(21) xor (str char at s 21)
        acc_(22) = acc_(22) xor (str char at s 22)
        acc_(23) = acc_(23) xor (str char at s 23)
        acc_(24) = acc_(24) xor (str char at s 24)
        acc_(25) = acc_(25) xor (str char at s 25)
        acc_(26) = acc_(26) xor (str char at s 26)
        acc_(27) = acc_(27) xor (str char at s 27)
        acc_(28) = acc_(28) xor (str char at s 28)
        acc_(29) = acc_(29) xor (str char at s 29)
        acc_(30) = acc_(30) xor (str char at s 30)
        acc_(31) = acc_(31) xor (str char at s 31)
        acc

fn :: c bxor8 lo Tensor[U64 * 32] String String String String String String String String => Tensor[U64 * 32]
      c bxor8 lo acc s1 s2 s3 s4 s5 s6 s7 s8 =
        acc_(0)  = acc_(0) xor (str char at s1 0) xor (str char at s2 0) xor (str char at s3 0) xor (str char at s4 0) xor (str char at s5 0) xor (str char at s6 0) xor (str char at s7 0) xor (str char at s8 0)
        acc_(1)  = acc_(1) xor (str char at s1 1) xor (str char at s2 1) xor (str char at s3 1) xor (str char at s4 1) xor (str char at s5 1) xor (str char at s6 1) xor (str char at s7 1) xor (str char at s8 1)
        acc_(2)  = acc_(2) xor (str char at s1 2) xor (str char at s2 2) xor (str char at s3 2) xor (str char at s4 2) xor (str char at s5 2) xor (str char at s6 2) xor (str char at s7 2) xor (str char at s8 2)
        acc_(3)  = acc_(3) xor (str char at s1 3) xor (str char at s2 3) xor (str char at s3 3) xor (str char at s4 3) xor (str char at s5 3) xor (str char at s6 3) xor (str char at s7 3) xor (str char at s8 3)
        acc_(4)  = acc_(4) xor (str char at s1 4) xor (str char at s2 4) xor (str char at s3 4) xor (str char at s4 4) xor (str char at s5 4) xor (str char at s6 4) xor (str char at s7 4) xor (str char at s8 4)
        acc_(5)  = acc_(5) xor (str char at s1 5) xor (str char at s2 5) xor (str char at s3 5) xor (str char at s4 5) xor (str char at s5 5) xor (str char at s6 5) xor (str char at s7 5) xor (str char at s8 5)
        acc_(6)  = acc_(6) xor (str char at s1 6) xor (str char at s2 6) xor (str char at s3 6) xor (str char at s4 6) xor (str char at s5 6) xor (str char at s6 6) xor (str char at s7 6) xor (str char at s8 6)
        acc_(7)  = acc_(7) xor (str char at s1 7) xor (str char at s2 7) xor (str char at s3 7) xor (str char at s4 7) xor (str char at s5 7) xor (str char at s6 7) xor (str char at s7 7) xor (str char at s8 7)
        acc_(8)  = acc_(8) xor (str char at s1 8) xor (str char at s2 8) xor (str char at s3 8) xor (str char at s4 8) xor (str char at s5 8) xor (str char at s6 8) xor (str char at s7 8) xor (str char at s8 8)
        acc_(9)  = acc_(9) xor (str char at s1 9) xor (str char at s2 9) xor (str char at s3 9) xor (str char at s4 9) xor (str char at s5 9) xor (str char at s6 9) xor (str char at s7 9) xor (str char at s8 9)
        acc_(10) = acc_(10) xor (str char at s1 10) xor (str char at s2 10) xor (str char at s3 10) xor (str char at s4 10) xor (str char at s5 10) xor (str char at s6 10) xor (str char at s7 10) xor (str char at s8 10)
        acc_(11) = acc_(11) xor (str char at s1 11) xor (str char at s2 11) xor (str char at s3 11) xor (str char at s4 11) xor (str char at s5 11) xor (str char at s6 11) xor (str char at s7 11) xor (str char at s8 11)
        acc_(12) = acc_(12) xor (str char at s1 12) xor (str char at s2 12) xor (str char at s3 12) xor (str char at s4 12) xor (str char at s5 12) xor (str char at s6 12) xor (str char at s7 12) xor (str char at s8 12)
        acc_(13) = acc_(13) xor (str char at s1 13) xor (str char at s2 13) xor (str char at s3 13) xor (str char at s4 13) xor (str char at s5 13) xor (str char at s6 13) xor (str char at s7 13) xor (str char at s8 13)
        acc_(14) = acc_(14) xor (str char at s1 14) xor (str char at s2 14) xor (str char at s3 14) xor (str char at s4 14) xor (str char at s5 14) xor (str char at s6 14) xor (str char at s7 14) xor (str char at s8 14)
        acc_(15) = acc_(15) xor (str char at s1 15) xor (str char at s2 15) xor (str char at s3 15) xor (str char at s4 15) xor (str char at s5 15) xor (str char at s6 15) xor (str char at s7 15) xor (str char at s8 15)
        acc

fn :: c bxor8 hi Tensor[U64 * 32] String String String String String String String String => Tensor[U64 * 32]
      c bxor8 hi acc s1 s2 s3 s4 s5 s6 s7 s8 =
        acc_(16) = acc_(16) xor (str char at s1 16) xor (str char at s2 16) xor (str char at s3 16) xor (str char at s4 16) xor (str char at s5 16) xor (str char at s6 16) xor (str char at s7 16) xor (str char at s8 16)
        acc_(17) = acc_(17) xor (str char at s1 17) xor (str char at s2 17) xor (str char at s3 17) xor (str char at s4 17) xor (str char at s5 17) xor (str char at s6 17) xor (str char at s7 17) xor (str char at s8 17)
        acc_(18) = acc_(18) xor (str char at s1 18) xor (str char at s2 18) xor (str char at s3 18) xor (str char at s4 18) xor (str char at s5 18) xor (str char at s6 18) xor (str char at s7 18) xor (str char at s8 18)
        acc_(19) = acc_(19) xor (str char at s1 19) xor (str char at s2 19) xor (str char at s3 19) xor (str char at s4 19) xor (str char at s5 19) xor (str char at s6 19) xor (str char at s7 19) xor (str char at s8 19)
        acc_(20) = acc_(20) xor (str char at s1 20) xor (str char at s2 20) xor (str char at s3 20) xor (str char at s4 20) xor (str char at s5 20) xor (str char at s6 20) xor (str char at s7 20) xor (str char at s8 20)
        acc_(21) = acc_(21) xor (str char at s1 21) xor (str char at s2 21) xor (str char at s3 21) xor (str char at s4 21) xor (str char at s5 21) xor (str char at s6 21) xor (str char at s7 21) xor (str char at s8 21)
        acc_(22) = acc_(22) xor (str char at s1 22) xor (str char at s2 22) xor (str char at s3 22) xor (str char at s4 22) xor (str char at s5 22) xor (str char at s6 22) xor (str char at s7 22) xor (str char at s8 22)
        acc_(23) = acc_(23) xor (str char at s1 23) xor (str char at s2 23) xor (str char at s3 23) xor (str char at s4 23) xor (str char at s5 23) xor (str char at s6 23) xor (str char at s7 23) xor (str char at s8 23)
        acc_(24) = acc_(24) xor (str char at s1 24) xor (str char at s2 24) xor (str char at s3 24) xor (str char at s4 24) xor (str char at s5 24) xor (str char at s6 24) xor (str char at s7 24) xor (str char at s8 24)
        acc_(25) = acc_(25) xor (str char at s1 25) xor (str char at s2 25) xor (str char at s3 25) xor (str char at s4 25) xor (str char at s5 25) xor (str char at s6 25) xor (str char at s7 25) xor (str char at s8 25)
        acc_(26) = acc_(26) xor (str char at s1 26) xor (str char at s2 26) xor (str char at s3 26) xor (str char at s4 26) xor (str char at s5 26) xor (str char at s6 26) xor (str char at s7 26) xor (str char at s8 26)
        acc_(27) = acc_(27) xor (str char at s1 27) xor (str char at s2 27) xor (str char at s3 27) xor (str char at s4 27) xor (str char at s5 27) xor (str char at s6 27) xor (str char at s7 27) xor (str char at s8 27)
        acc_(28) = acc_(28) xor (str char at s1 28) xor (str char at s2 28) xor (str char at s3 28) xor (str char at s4 28) xor (str char at s5 28) xor (str char at s6 28) xor (str char at s7 28) xor (str char at s8 28)
        acc_(29) = acc_(29) xor (str char at s1 29) xor (str char at s2 29) xor (str char at s3 29) xor (str char at s4 29) xor (str char at s5 29) xor (str char at s6 29) xor (str char at s7 29) xor (str char at s8 29)
        acc_(30) = acc_(30) xor (str char at s1 30) xor (str char at s2 30) xor (str char at s3 30) xor (str char at s4 30) xor (str char at s5 30) xor (str char at s6 30) xor (str char at s7 30) xor (str char at s8 30)
        acc_(31) = acc_(31) xor (str char at s1 31) xor (str char at s2 31) xor (str char at s3 31) xor (str char at s4 31) xor (str char at s5 31) xor (str char at s6 31) xor (str char at s7 31) xor (str char at s8 31)
        acc

fn :: c acc32 quad CT16 Tensor[U64 * 32] Int => String
      c acc32 quad tbl acc off =
        v0 = acc_(off)
        v1 = acc_(off + 1)
        v2 = acc_(off + 2)
        v3 = acc_(off + 3)
        b0 = c get b256 tbl ((v0 shr 4) and 15) (v0 and 15)
        b1 = c get b256 tbl ((v1 shr 4) and 15) (v1 and 15)
        b2 = c get b256 tbl ((v2 shr 4) and 15) (v2 and 15)
        b3 = c get b256 tbl ((v3 shr 4) and 15) (v3 and 15)
        (b0 + b1) + (b2 + b3)

fn :: c acc32 to raw CT16 Tensor[U64 * 32] => String
      c acc32 to raw tbl acc =
        q0 = c acc32 quad tbl acc 0
        q1 = c acc32 quad tbl acc 4
        q2 = c acc32 quad tbl acc 8
        q3 = c acc32 quad tbl acc 12
        q4 = c acc32 quad tbl acc 16
        q5 = c acc32 quad tbl acc 20
        q6 = c acc32 quad tbl acc 24
        q7 = c acc32 quad tbl acc 28
        ((q0 + q1) + (q2 + q3)) + ((q4 + q5) + (q6 + q7))

fn :: pbkdf2 iter loop Int String String String Tensor[U64 * 32] => Tensor[U64 * 32]
      pbkdf2 iter loop rem ipad opad u acc =
        | rem <= 0 = acc
        | rem >= 8 =
          u1   = sha256 raw (opad + (sha256 raw (ipad + u)))
          u2   = sha256 raw (opad + (sha256 raw (ipad + u1)))
          u3   = sha256 raw (opad + (sha256 raw (ipad + u2)))
          u4   = sha256 raw (opad + (sha256 raw (ipad + u3)))
          u5   = sha256 raw (opad + (sha256 raw (ipad + u4)))
          u6   = sha256 raw (opad + (sha256 raw (ipad + u5)))
          u7   = sha256 raw (opad + (sha256 raw (ipad + u6)))
          u8   = sha256 raw (opad + (sha256 raw (ipad + u7)))
          acc1 = c bxor8 lo acc u1 u2 u3 u4 u5 u6 u7 u8
          acc2 = c bxor8 hi acc1 u1 u2 u3 u4 u5 u6 u7 u8
          pbkdf2 iter loop (rem - 8) ipad opad u8 acc2
        | otherwise =
          u1   = sha256 raw (opad + (sha256 raw (ipad + u)))
          acc1 = c bxor1 acc32 acc u1
          pbkdf2 iter loop (rem - 1) ipad opad u1 acc1

fn :: pbkdf2 block CPbkCtx String Int Int => String
      pbkdf2 block ctx salt iterations block_idx =
        tbl  = cptbl ctx
        ipad = cpipad ctx
        opad = cpopad ctx
        u1   = sha256 raw (opad + (sha256 raw (ipad + salt + (be32 bytes block_idx))))
        acc0 = c init acc32 u1
        accf = pbkdf2 iter loop (iterations - 1) ipad opad u1 acc0
        c acc32 to raw tbl accf

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
        mut a = a + b + 2 * ((a and 0xFFFFFFFF) * (b and 0xFFFFFFFF))
        mut d = (d xor a) rotr 32
        mut c = c + d + 2 * ((c and 0xFFFFFFFF) * (d and 0xFFFFFFFF))
        mut b = (b xor c) rotr 24
        a = a + b + 2 * ((a and 0xFFFFFFFF) * (b and 0xFFFFFFFF))
        d = (d xor a) rotr 16
        c = c + d + 2 * ((c and 0xFFFFFFFF) * (d and 0xFFFFFFFF))
        b = (b xor c) rotr 63
        (a, b, c, d)

-- @implements FR-CRYPTO-004
-- @implements API-CRYPTO-001
-- @implements DM-Tensor
fn :: blamka p16 Tensor[U64 * 16] => ()
      blamka p16 v                =
        v0, v4, v8,  v12 = blamka g v_(0) v_(4) v_(8)  v_(12)
        v1, v5, v9,  v13 = blamka g v_(1) v_(5) v_(9)  v_(13)
        v2, v6, v10, v14 = blamka g v_(2) v_(6) v_(10) v_(14)
        v3, v7, v11, v15 = blamka g v_(3) v_(7) v_(11) v_(15)
        v_(0), v_(5), v_(10), v_(15) = blamka g v0 v5 v10 v15
        v_(1), v_(6), v_(11), v_(12) = blamka g v1 v6 v11 v12
        v_(2), v_(7), v_(8),  v_(13) = blamka g v2 v7 v8  v13
        v_(3), v_(4), v_(9),  v_(14) = blamka g v3 v4 v9  v14

fn :: ca2 blamka col pair Tensor[U64 * 8 * 16] Int => Tensor[U64 * 8 * 16]
      ca2 blamka col pair z j =
        c  = 2 * j
        c1 = c + 1
        z0c,  z2c,  z4c,  z6c  = blamka g z_(0, c)  z_(2, c)  z_(4, c)  z_(6, c)
        z0c1, z2c1, z4c1, z6c1 = blamka g z_(0, c1) z_(2, c1) z_(4, c1) z_(6, c1)
        z1c,  z3c,  z5c,  z7c  = blamka g z_(1, c)  z_(3, c)  z_(5, c)  z_(7, c)
        z1c1, z3c1, z5c1, z7c1 = blamka g z_(1, c1) z_(3, c1) z_(5, c1) z_(7, c1)
        z_(0, c),  z_(2, c1), z_(5, c),  z_(7, c1) = blamka g z0c  z2c1 z5c  z7c1
        z_(0, c1), z_(3, c),  z_(5, c1), z_(6, c)  = blamka g z0c1 z3c  z5c1 z6c
        z_(1, c),  z_(3, c1), z_(4, c),  z_(6, c1) = blamka g z1c  z3c1 z4c  z6c1
        z_(1, c1), z_(2, c),  z_(4, c1), z_(7, c)  = blamka g z1c1 z2c  z4c1 z7c
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
        map blamka p16 in z_(i,)
        z2   = ca2 blamka cols loop z 0
        z2_ij xor r_ij

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
      chacha double round st               =
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
      chacha rounds loop st               idx =
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

fn :: chacha20 bitxor loop [Int] [Int] Int [Int] [Int] [Int] [Int] Int => [Int]
      chacha20 bitxor loop _ _ _ [] l0 l1 l2 _ = c lb finish l0 l1 l2
      chacha20 bitxor loop key_bs nonce_bs ctr msg l0 l1 l2 cnt =
        ks    = chacha20 block key_bs nonce_bs ctr
        chunk = c take ints msg 64
        rest  = c drop ints msg 64
        xored = bitxor byte lists chunk ks
        n0, n1, n2, ncnt = c lb append1 (l0 :: xored) l1 l2 (cnt + 1)
        chacha20 bitxor loop key_bs nonce_bs (ctr + 1) rest n0 n1 n2 ncnt

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
        aad_b c list len -> alen
        ct_b c list len -> clen
        aad_b :: (pad16 zeroes alen) :: ct_b :: (pad16 zeroes clen) :: (u64 le8 alen) :: (u64 le8 clen) -> msg
        otk poly1305 clamp r -> poly1305 r limbs -> r
        poly1305 blocks loop [0, 0, 0, 0, 0] r msg -> h_fin
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
          ct_bs    = chacha20 bitxor loop key_bs nonce_bs 1 pt_bs [] [] [] 0
          tag_bs   = poly1305 aead mac otk aad_bs ct_bs
          bytes from list (ct_bs :: tag_bs)

fn :: decrypt verified aead Bool [Int] [Int] [Int] => Int String
      decrypt verified aead False _ _ _ = (0 - 12, "")
      decrypt verified aead True key_bs nonce_bs ct_bs =
        chacha20 bitxor loop key_bs nonce_bs 1 ct_bs [] [] [] 0 -> pt_bs
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
