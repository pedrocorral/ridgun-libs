-- ============================================================
-- src/main/ridgun/lib/crypto.rg
-- Pure-Ridgun Cryptographic Primitives, Bitops, SHA-256, HMAC, PBKDF2,
-- Argon2id (RGF-015) & RFC 8439 ChaCha20-Poly1305 AEAD Library (CRYPTO)
-- @implements FR-CRYPTO-001
-- @implements FR-CRYPTO-002
-- @implements FR-CRYPTO-003
-- @implements FR-CRYPTO-004
-- @implements FR-CRYPTO-005
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
-- ── FIPS 180-4 SHA-512 (`sha512 bytes`, `sha512 hex`) ────────

fn :: sha512 k hex0 => String
      sha512 k hex0 =
        "428a2f98d728ae227137449123ef65cdb5c0fbcfec4d3b2fe9b5dba58189dbbc3956c25bf348b53859f111f1b605d019923f82a4af194f9bab1c5ed5da6d8118d807aa98a303024212835b0145706fbe243185be4ee4b28c550c7dc3d5ffb4e272be5d74f27b896f80deb1fe3b1696b19bdc06a725c71235c19bf174cf692694e49b69c19ef14ad2efbe4786384f25e30fc19dc68b8cd5b5240ca1cc77ac9c652de92c6f592b02754a7484aa6ea6e4835cb0a9dcbd41fbd476f988da831153b5983e5152ee66dfaba831c66d2db43210b00327c898fb213fbf597fc7beef0ee4c6e00bf33da88fc2d5a79147930aa72506ca6351e003826f142929670a0e6e7027b70a8546d22ffc2e1b21385c26c9264d2c6dfc5ac42aed53380d139d95b3df650a73548baf63de766a0abb3c77b2a881c2c92e47edaee692722c851482353b"

fn :: sha512 k hex1 => String
      sha512 k hex1 =
        "a2bfe8a14cf10364a81a664bbc423001c24b8b70d0f89791c76c51a30654be30d192e819d6ef5218d69906245565a910f40e35855771202a106aa07032bbd1b819a4c116b8d2d0c81e376c085141ab532748774cdf8eeb9934b0bcb5e19b48a8391c0cb3c5c95a634ed8aa4ae3418acb5b9cca4f7763e373682e6ff3d6b2b8a3748f82ee5defb2fc78a5636f43172f6084c87814a1f0ab728cc702081a6439ec90befffa23631e28a4506cebde82bde9bef9a3f7b2c67915c67178f2e372532bca273eceea26619cd186b8c721c0c207eada7dd6cde0eb1ef57d4f7fee6ed17806f067aa72176fba0a637dc5a2c898a6113f9804bef90dae1b710b35131c471b28db77f523047d8432caab7b40c724933c9ebe0a15c9bebc431d67c49c100d4c4cc5d4becb3e42b6597f299cfc657e2a5fcb6fab3ad6faec6c44198c4a475817"

fn :: sha512 fill hex words Tensor[U64 * 160] String Int Int => Tensor[U64 * 160]
      sha512 fill hex words k s base idx =
        | idx >= 80 = k
        | otherwise =
          k_(base + idx) = c hex8 word s (idx * 8)
          sha512 fill hex words k s base (idx + 1)

fn :: sha512 init k => Tensor[U64 * 160]
      sha512 init k =
        k0 = Tensor[U64 * 160]
        k1 = sha512 fill hex words k0 (sha512 k hex0) 0 0
        sha512 fill hex words k1 (sha512 k hex1) 80 0

fn :: sha512 init h loop Tensor[U64 * 16] String Int => Tensor[U64 * 16]
      sha512 init h loop h s idx =
        | idx >= 16 = h
        | otherwise =
          h_(idx) = c hex8 word s (idx * 8)
          sha512 init h loop h s (idx + 1)

fn :: sha512 init h => Tensor[U64 * 16]
      sha512 init h =
        h = Tensor[U64 * 16]
        s = "6a09e667f3bcc908bb67ae8584caa73b3c6ef372fe94f82ba54ff53a5f1d36f1510e527fade682d19b05688c2b3e6c1f1f83d9abfb41bd6b5be0cd19137e2179"
        sha512 init h loop h s 0

fn :: sha512 rrot lt32 U64 U64 Int => U64 U64
      sha512 rrot lt32 xh xl n =
        rh = ((xh shr n) or (xl shl (32 - n))) and 0xFFFFFFFF
        rl = ((xl shr n) or (xh shl (32 - n))) and 0xFFFFFFFF
        (rh, rl)

fn :: sha512 rshift lt32 U64 U64 Int => U64 U64
      sha512 rshift lt32 xh xl n =
        rh = xh shr n
        rl = ((xl shr n) or (xh shl (32 - n))) and 0xFFFFFFFF
        (rh, rl)

fn :: sha512 big sigma0 U64 U64 => U64 U64
      sha512 big sigma0 ah al =
        r1h, r1l = sha512 rrot lt32 ah al 28
        r2h, r2l = sha512 rrot lt32 al ah 2
        r3h, r3l = sha512 rrot lt32 al ah 7
        ((r1h xor r2h) xor r3h, (r1l xor r2l) xor r3l)

fn :: sha512 big sigma1 U64 U64 => U64 U64
      sha512 big sigma1 eh el =
        r1h, r1l = sha512 rrot lt32 eh el 14
        r2h, r2l = sha512 rrot lt32 eh el 18
        r3h, r3l = sha512 rrot lt32 el eh 9
        ((r1h xor r2h) xor r3h, (r1l xor r2l) xor r3l)

fn :: sha512 small sigma0 U64 U64 => U64 U64
      sha512 small sigma0 xh xl =
        r1h, r1l = sha512 rrot lt32 xh xl 1
        r2h, r2l = sha512 rrot lt32 xh xl 8
        r3h, r3l = sha512 rshift lt32 xh xl 7
        ((r1h xor r2h) xor r3h, (r1l xor r2l) xor r3l)

fn :: sha512 small sigma1 U64 U64 => U64 U64
      sha512 small sigma1 xh xl =
        r1h, r1l = sha512 rrot lt32 xh xl 19
        r2h, r2l = sha512 rrot lt32 xl xh 29
        r3h, r3l = sha512 rshift lt32 xh xl 6
        ((r1h xor r2h) xor r3h, (r1l xor r2l) xor r3l)

fn :: sha512 vbyte String Int Int Int => U64
      sha512 vbyte msg mlen total_len pos =
        | pos < mlen  = norm byte (str char at msg pos)
        | pos == mlen = 128
        | pos >= (total_len - 8) =
          bit_len = mlen * 8
          shift   = ((total_len - 1) - pos) * 8
          (bit_len shr shift) and 255
        | otherwise = 0

fn :: sha512 load w fast Tensor[U64 * 160] String Int Int => Tensor[U64 * 160]
      sha512 load w fast w msg off idx =
        | idx >= 32 = w
        | otherwise =
          p  = off + (idx * 4)
          b0 = norm byte (str char at msg p)
          b1 = norm byte (str char at msg (p + 1))
          b2 = norm byte (str char at msg (p + 2))
          b3 = norm byte (str char at msg (p + 3))
          w_(idx) = (b0 shl 24) or (b1 shl 16) or (b2 shl 8) or b3
          sha512 load w fast w msg off (idx + 1)

fn :: sha512 load w pad Tensor[U64 * 160] String Int Int Int Int => Tensor[U64 * 160]
      sha512 load w pad w msg mlen total_len off idx =
        | idx >= 32 = w
        | otherwise =
          p  = off + (idx * 4)
          b0 = sha512 vbyte msg mlen total_len p
          b1 = sha512 vbyte msg mlen total_len (p + 1)
          b2 = sha512 vbyte msg mlen total_len (p + 2)
          b3 = sha512 vbyte msg mlen total_len (p + 3)
          w_(idx) = (b0 shl 24) or (b1 shl 16) or (b2 shl 8) or b3
          sha512 load w pad w msg mlen total_len off (idx + 1)

fn :: sha512 expand w Tensor[U64 * 160] Int => Tensor[U64 * 160]
      sha512 expand w w t =
        | t >= 80   = w
        | otherwise =
          i2  = (t - 2) * 2
          i7  = (t - 7) * 2
          i15 = (t - 15) * 2
          i16 = (t - 16) * 2
          s1h, s1l = sha512 small sigma1 w_(i2) w_(i2 + 1)
          s0h, s0l = sha512 small sigma0 w_(i15) w_(i15 + 1)
          sum_l    = s1l + w_(i7 + 1) + s0l + w_(i16 + 1)
          sum_h    = s1h + w_(i7) + s0h + w_(i16) + (sum_l shr 32)
          it       = t * 2
          w_(it)     = sum_h and 0xFFFFFFFF
          w_(it + 1) = sum_l and 0xFFFFFFFF
          sha512 expand w w (t + 1)

fn :: sha512 copy state Tensor[U64 * 16] Tensor[U64 * 16] Int => Tensor[U64 * 16]
      sha512 copy state dst src idx =
        | idx >= 16 = dst
        | otherwise =
          dst_(idx) = src_(idx)
          sha512 copy state dst src (idx + 1)

fn :: sha512 add state Tensor[U64 * 16] Tensor[U64 * 16] Int => Tensor[U64 * 16]
      sha512 add state h v idx =
        | idx >= 8  = h
        | otherwise =
          hi = idx * 2
          lo = hi + 1
          sl = h_(lo) + v_(lo)
          sh = h_(hi) + v_(hi) + (sl shr 32)
          h_(hi) = sh and 0xFFFFFFFF
          h_(lo) = sl and 0xFFFFFFFF
          sha512 add state h v (idx + 1)

fn :: sha512 rounds loop Tensor[U64 * 16] Tensor[U64 * 160] Tensor[U64 * 160] Int => Tensor[U64 * 16]
      sha512 rounds loop v k w t =
        | t >= 80   = v
        | otherwise =
          ah = v_(0)
          al = v_(1)
          bh = v_(2)
          bl = v_(3)
          ch = v_(4)
          cl = v_(5)
          dh = v_(6)
          dl = v_(7)
          eh = v_(8)
          el = v_(9)
          fh = v_(10)
          fl = v_(11)
          gh = v_(12)
          gl = v_(13)
          hh = v_(14)
          hl = v_(15)
          s1h, s1l = sha512 big sigma1 eh el
          ch_h = (eh and fh) xor ((eh xor 0xFFFFFFFF) and gh)
          ch_l = (el and fl) xor ((el xor 0xFFFFFFFF) and gl)
          it   = t * 2
          t1_l = hl + s1l + ch_l + k_(it + 1) + w_(it + 1)
          t1_h = (hh + s1h + ch_h + k_(it) + w_(it) + (t1_l shr 32)) and 0xFFFFFFFF
          t1_l_m = t1_l and 0xFFFFFFFF
          s0h, s0l = sha512 big sigma0 ah al
          maj_h = (ah and bh) xor (ah and ch) xor (bh and ch)
          maj_l = (al and bl) xor (al and cl) xor (bl and cl)
          t2_l = s0l + maj_l
          t2_h = (s0h + maj_h + (t2_l shr 32)) and 0xFFFFFFFF
          t2_l_m = t2_l and 0xFFFFFFFF
          ne_l = dl + t1_l_m
          ne_h = (dh + t1_h + (ne_l shr 32)) and 0xFFFFFFFF
          na_l = t1_l_m + t2_l_m
          na_h = (t1_h + t2_h + (na_l shr 32)) and 0xFFFFFFFF
          v_(0)  = na_h
          v_(1)  = na_l and 0xFFFFFFFF
          v_(2)  = ah
          v_(3)  = al
          v_(4)  = bh
          v_(5)  = bl
          v_(6)  = ch
          v_(7)  = cl
          v_(8)  = ne_h
          v_(9)  = ne_l and 0xFFFFFFFF
          v_(10) = eh
          v_(11) = el
          v_(12) = fh
          v_(13) = fl
          v_(14) = gh
          v_(15) = gl
          sha512 rounds loop v k w (t + 1)

fn :: sha512 blocks loop Tensor[U64 * 16] Tensor[U64 * 16] Tensor[U64 * 160] Tensor[U64 * 160] String Int Int Int => Tensor[U64 * 16]
      sha512 blocks loop h v k w msg mlen total_len off =
        | off >= total_len = h
        | (off + 128) <= mlen =
          w1 = sha512 load w fast w msg off 0
          w2 = sha512 expand w w1 16
          v1 = sha512 copy state v h 0
          v2 = sha512 rounds loop v1 k w2 0
          h1 = sha512 add state h v2 0
          sha512 blocks loop h1 v2 k w2 msg mlen total_len (off + 128)
        | otherwise =
          w1 = sha512 load w pad w msg mlen total_len off 0
          w2 = sha512 expand w w1 16
          v1 = sha512 copy state v h 0
          v2 = sha512 rounds loop v1 k w2 0
          h1 = sha512 add state h v2 0
          sha512 blocks loop h1 v2 k w2 msg mlen total_len (off + 128)

fn :: sha512 state to raw CT16 Tensor[U64 * 16] Int => String
      sha512 state to raw tbl h idx =
        | idx >= 16 = ""
        | otherwise = (c word32 to raw4 tbl h_(idx)) + (sha512 state to raw tbl h (idx + 1))

-- @implements FR-CRYPTO-005
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: sha512 bytes String => String
      sha512 bytes msg =
        mlen      = str len msg
        total_len = ((mlen + 17 + 127) / 128) * 128
        h0        = sha512 init h
        v0        = Tensor[U64 * 16]
        k         = sha512 init k
        w         = Tensor[U64 * 160]
        hf        = sha512 blocks loop h0 v0 k w msg mlen total_len 0
        sha512 state to raw (c build b256) hf 0

-- @implements FR-CRYPTO-005
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: sha512 hex String => String
      sha512 hex msg =
        msg sha512 bytes -> bytes to hex str

-- ── Ed25519 Field Arithmetic mod p = 2^255 - 19 (10 radix-2^25.5 limbs) ──

fn :: fe lit U64 U64 U64 U64 U64 U64 U64 U64 U64 U64 => Tensor[U64 * 10]
      fe lit l0 l1 l2 l3 l4 l5 l6 l7 l8 l9 =
        f = Tensor[U64 * 10]
        f_(0) = l0
        f_(1) = l1
        f_(2) = l2
        f_(3) = l3
        f_(4) = l4
        f_(5) = l5
        f_(6) = l6
        f_(7) = l7
        f_(8) = l8
        f_(9) = l9
        f

fn :: fe zero => Tensor[U64 * 10]
      fe zero =  fe lit 0 0 0 0 0 0 0 0 0 0

fn :: fe one => Tensor[U64 * 10]
      fe one =  fe lit 1 0 0 0 0 0 0 0 0 0

fn :: fe d => Tensor[U64 * 10]
      fe d =  fe lit 56195235 13857412 51736253 6949390 114729 24766616 60832955 30306712 48412415 21499315

fn :: fe d2 => Tensor[U64 * 10]
      fe d2 =  fe lit 45281625 27714825 36363642 13898781 229458 15978800 54557047 27058993 29715967 9444199

fn :: fe sqrt m1 => Tensor[U64 * 10]
      fe sqrt m1 =  fe lit 34513072 25610706 9377949 3500415 12389472 33281959 41962654 31548777 326685 11406482

fn :: fe bx => Tensor[U64 * 10]
      fe bx =  fe lit 52811034 25909283 16144682 17082669 27570973 30858332 40966398 8378388 20764389 8758491

fn :: fe by => Tensor[U64 * 10]
      fe by =  fe lit 40265304 26843545 13421772 20132659 26843545 6710886 53687091 13421772 40265318 26843545

fn :: fe bt => Tensor[U64 * 10]
      fe bt =  fe lit 28827043 27438313 39759291 244362 8635006 11264893 19351346 13413597 16611511 27139452

fn :: fe carry pass Tensor[U64 * 10] => Tensor[U64 * 10]
      fe carry pass h =
        c0 = h_(0) shr 26
        h_(0) = h_(0) and 67108863
        h_(1) = h_(1) + c0
        c1 = h_(1) shr 25
        h_(1) = h_(1) and 33554431
        h_(2) = h_(2) + c1
        c2 = h_(2) shr 26
        h_(2) = h_(2) and 67108863
        h_(3) = h_(3) + c2
        c3 = h_(3) shr 25
        h_(3) = h_(3) and 33554431
        h_(4) = h_(4) + c3
        c4 = h_(4) shr 26
        h_(4) = h_(4) and 67108863
        h_(5) = h_(5) + c4
        c5 = h_(5) shr 25
        h_(5) = h_(5) and 33554431
        h_(6) = h_(6) + c5
        c6 = h_(6) shr 26
        h_(6) = h_(6) and 67108863
        h_(7) = h_(7) + c6
        c7 = h_(7) shr 25
        h_(7) = h_(7) and 33554431
        h_(8) = h_(8) + c7
        c8 = h_(8) shr 26
        h_(8) = h_(8) and 67108863
        h_(9) = h_(9) + c8
        c9 = h_(9) shr 25
        h_(9) = h_(9) and 33554431
        h_(0) = h_(0) + (c9 * 19)
        h

fn :: fe carry Tensor[U64 * 10] => Tensor[U64 * 10]
      fe carry h =
        h1 = fe carry pass h
        h2 = fe carry pass h1
        c0 = h2_(0) shr 26
        h2_(0) = h2_(0) and 67108863
        h2_(1) = h2_(1) + c0
        h2

fn :: fe add Tensor[U64 * 10] Tensor[U64 * 10] => Tensor[U64 * 10]
      fe add f g =
        fe lit (f_(0) + g_(0)) (f_(1) + g_(1)) (f_(2) + g_(2)) (f_(3) + g_(3)) (f_(4) + g_(4)) (f_(5) + g_(5)) (f_(6) + g_(6)) (f_(7) + g_(7)) (f_(8) + g_(8)) (f_(9) + g_(9))

fn :: fe sub Tensor[U64 * 10] Tensor[U64 * 10] => Tensor[U64 * 10]
      fe sub f g =
        h = fe lit ((f_(0) + 134217690) - g_(0)) ((f_(1) + 67108862) - g_(1)) ((f_(2) + 134217726) - g_(2)) ((f_(3) + 67108862) - g_(3)) ((f_(4) + 134217726) - g_(4)) ((f_(5) + 67108862) - g_(5)) ((f_(6) + 134217726) - g_(6)) ((f_(7) + 67108862) - g_(7)) ((f_(8) + 134217726) - g_(8)) ((f_(9) + 67108862) - g_(9))
        fe carry h

fn :: fe mul Tensor[U64 * 10] Tensor[U64 * 10] => Tensor[U64 * 10]
      fe mul f g =
        f0 = f_(0)
        f1 = f_(1)
        f2 = f_(2)
        f3 = f_(3)
        f4 = f_(4)
        f5 = f_(5)
        f6 = f_(6)
        f7 = f_(7)
        f8 = f_(8)
        f9 = f_(9)
        g0 = g_(0)
        g1 = g_(1)
        g2 = g_(2)
        g3 = g_(3)
        g4 = g_(4)
        g5 = g_(5)
        g6 = g_(6)
        g7 = g_(7)
        g8 = g_(8)
        g9 = g_(9)
        g1_19 = 19 * g1
        g2_19 = 19 * g2
        g3_19 = 19 * g3
        g4_19 = 19 * g4
        g5_19 = 19 * g5
        g6_19 = 19 * g6
        g7_19 = 19 * g7
        g8_19 = 19 * g8
        g9_19 = 19 * g9
        f1_2  = 2 * f1
        f3_2  = 2 * f3
        f5_2  = 2 * f5
        f7_2  = 2 * f7
        f9_2  = 2 * f9
        h0 = (f0 * g0) + (f1_2 * g9_19) + (f2 * g8_19) + (f3_2 * g7_19) + (f4 * g6_19) + (f5_2 * g5_19) + (f6 * g4_19) + (f7_2 * g3_19) + (f8 * g2_19) + (f9_2 * g1_19)
        h1 = (f0 * g1) + (f1 * g0) + (f2 * g9_19) + (f3 * g8_19) + (f4 * g7_19) + (f5 * g6_19) + (f6 * g5_19) + (f7 * g4_19) + (f8 * g3_19) + (f9 * g2_19)
        h2 = (f0 * g2) + (f1_2 * g1) + (f2 * g0) + (f3_2 * g9_19) + (f4 * g8_19) + (f5_2 * g7_19) + (f6 * g6_19) + (f7_2 * g5_19) + (f8 * g4_19) + (f9_2 * g3_19)
        h3 = (f0 * g3) + (f1 * g2) + (f2 * g1) + (f3 * g0) + (f4 * g9_19) + (f5 * g8_19) + (f6 * g7_19) + (f7 * g6_19) + (f8 * g5_19) + (f9 * g4_19)
        h4 = (f0 * g4) + (f1_2 * g3) + (f2 * g2) + (f3_2 * g1) + (f4 * g0) + (f5_2 * g9_19) + (f6 * g8_19) + (f7_2 * g7_19) + (f8 * g6_19) + (f9_2 * g5_19)
        h5 = (f0 * g5) + (f1 * g4) + (f2 * g3) + (f3 * g2) + (f4 * g1) + (f5 * g0) + (f6 * g9_19) + (f7 * g8_19) + (f8 * g7_19) + (f9 * g6_19)
        h6 = (f0 * g6) + (f1_2 * g5) + (f2 * g4) + (f3_2 * g3) + (f4 * g2) + (f5_2 * g1) + (f6 * g0) + (f7_2 * g9_19) + (f8 * g8_19) + (f9_2 * g7_19)
        h7 = (f0 * g7) + (f1 * g6) + (f2 * g5) + (f3 * g4) + (f4 * g3) + (f5 * g2) + (f6 * g1) + (f7 * g0) + (f8 * g9_19) + (f9 * g8_19)
        h8 = (f0 * g8) + (f1_2 * g7) + (f2 * g6) + (f3_2 * g5) + (f4 * g4) + (f5_2 * g3) + (f6 * g2) + (f7_2 * g1) + (f8 * g0) + (f9_2 * g9_19)
        h9 = (f0 * g9) + (f1 * g8) + (f2 * g7) + (f3 * g6) + (f4 * g5) + (f5 * g4) + (f6 * g3) + (f7 * g2) + (f8 * g1) + (f9 * g0)
        fe carry (fe lit h0 h1 h2 h3 h4 h5 h6 h7 h8 h9)

fn :: fe sq Tensor[U64 * 10] => Tensor[U64 * 10]
      fe sq f =  fe mul f f

fn :: fe sq n Tensor[U64 * 10] Int => Tensor[U64 * 10]
      fe sq n f n =
        | n <= 0    = f
        | otherwise = fe sq n (fe sq f) (n - 1)

fn :: fe freeze Tensor[U64 * 10] => Tensor[U64 * 10]
      fe freeze f =
        h  = fe carry (fe lit f_(0) f_(1) f_(2) f_(3) f_(4) f_(5) f_(6) f_(7) f_(8) f_(9))
        q0 = (h_(0) + 19) shr 26
        q1 = (h_(1) + q0) shr 25
        q2 = (h_(2) + q1) shr 26
        q3 = (h_(3) + q2) shr 25
        q4 = (h_(4) + q3) shr 26
        q5 = (h_(5) + q4) shr 25
        q6 = (h_(6) + q5) shr 26
        q7 = (h_(7) + q6) shr 25
        q8 = (h_(8) + q7) shr 26
        q9 = (h_(9) + q8) shr 25
        h_(0) = h_(0) + (19 * q9)
        h1 = fe carry pass h
        h1_(9) = h1_(9) and 33554431
        h1

fn :: fe eq Tensor[U64 * 10] Tensor[U64 * 10] => Bool
      fe eq f g =
        ff = fe freeze f
        gf = fe freeze g
        d  = (ff_(0) xor gf_(0)) or (ff_(1) xor gf_(1)) or (ff_(2) xor gf_(2)) or (ff_(3) xor gf_(3)) or (ff_(4) xor gf_(4)) or (ff_(5) xor gf_(5)) or (ff_(6) xor gf_(6)) or (ff_(7) xor gf_(7)) or (ff_(8) xor gf_(8)) or (ff_(9) xor gf_(9))
        d == 0

fn :: fe pow22523 Tensor[U64 * 10] => Tensor[U64 * 10]
      fe pow22523 z =
        z2  = fe sq z
        z9  = fe mul (fe sq n z2 2) z
        z11 = fe mul z9 z2
        t0  = fe mul (fe sq z11) z9
        t1  = fe mul (fe sq n t0 5) t0
        t2  = fe mul (fe sq n t1 10) t1
        t3  = fe mul (fe sq n t2 20) t2
        t4  = fe mul (fe sq n t3 10) t1
        t5  = fe mul (fe sq n t4 50) t4
        t6  = fe mul (fe sq n t5 100) t5
        t7  = fe mul (fe sq n t6 50) t4
        t8  = fe sq n t7 2
        fe mul t8 z

fn :: fe invert Tensor[U64 * 10] => Tensor[U64 * 10]
      fe invert z =
        z2  = fe sq z
        z9  = fe mul (fe sq n z2 2) z
        z11 = fe mul z9 z2
        t0  = fe mul (fe sq z11) z9
        t1  = fe mul (fe sq n t0 5) t0
        t2  = fe mul (fe sq n t1 10) t1
        t3  = fe mul (fe sq n t2 20) t2
        t4  = fe mul (fe sq n t3 10) t1
        t5  = fe mul (fe sq n t4 50) t4
        t6  = fe mul (fe sq n t5 100) t5
        t7  = fe mul (fe sq n t6 50) t4
        fe mul (fe sq n t7 5) z11

fn :: fe to words8 Tensor[U64 * 10] => Tensor[U64 * 8]
      fe to words8 f =
        h  = fe freeze f
        w  = Tensor[U64 * 8]
        w_(0) = (h_(0) or (h_(1) shl 26)) and 0xFFFFFFFF
        w_(1) = ((h_(1) shr 6) or (h_(2) shl 19)) and 0xFFFFFFFF
        w_(2) = ((h_(2) shr 13) or (h_(3) shl 13)) and 0xFFFFFFFF
        w_(3) = ((h_(3) shr 19) or (h_(4) shl 6)) and 0xFFFFFFFF
        w_(4) = (h_(5) or (h_(6) shl 25)) and 0xFFFFFFFF
        w_(5) = ((h_(6) shr 7) or (h_(7) shl 19)) and 0xFFFFFFFF
        w_(6) = ((h_(7) shr 13) or (h_(8) shl 12)) and 0xFFFFFFFF
        w_(7) = ((h_(8) shr 20) or (h_(9) shl 6)) and 0xFFFFFFFF
        w

fn :: words8 to raw32 loop CT16 Tensor[U64 * 8] Int => String
      words8 to raw32 loop tbl w idx =
        | idx >= 8  = ""
        | otherwise =
          v  = w_(idx)
          b0 = c get b256 tbl ((v shr 4) and 15) (v and 15)
          b1 = c get b256 tbl ((v shr 12) and 15) ((v shr 8) and 15)
          b2 = c get b256 tbl ((v shr 20) and 15) ((v shr 16) and 15)
          b3 = c get b256 tbl ((v shr 28) and 15) ((v shr 24) and 15)
          ((b0 + b1) + (b2 + b3)) + (words8 to raw32 loop tbl w (idx + 1))

fn :: raw32 to words8 String => Tensor[U64 * 8]
      raw32 to words8 s =
        w = Tensor[U64 * 8]
        w_(0) = (norm byte (str char at s 0)) or ((norm byte (str char at s 1)) shl 8) or ((norm byte (str char at s 2)) shl 16) or ((norm byte (str char at s 3)) shl 24)
        w_(1) = (norm byte (str char at s 4)) or ((norm byte (str char at s 5)) shl 8) or ((norm byte (str char at s 6)) shl 16) or ((norm byte (str char at s 7)) shl 24)
        w_(2) = (norm byte (str char at s 8)) or ((norm byte (str char at s 9)) shl 8) or ((norm byte (str char at s 10)) shl 16) or ((norm byte (str char at s 11)) shl 24)
        w_(3) = (norm byte (str char at s 12)) or ((norm byte (str char at s 13)) shl 8) or ((norm byte (str char at s 14)) shl 16) or ((norm byte (str char at s 15)) shl 24)
        w_(4) = (norm byte (str char at s 16)) or ((norm byte (str char at s 17)) shl 8) or ((norm byte (str char at s 18)) shl 16) or ((norm byte (str char at s 19)) shl 24)
        w_(5) = (norm byte (str char at s 20)) or ((norm byte (str char at s 21)) shl 8) or ((norm byte (str char at s 22)) shl 16) or ((norm byte (str char at s 23)) shl 24)
        w_(6) = (norm byte (str char at s 24)) or ((norm byte (str char at s 25)) shl 8) or ((norm byte (str char at s 26)) shl 16) or ((norm byte (str char at s 27)) shl 24)
        w_(7) = (norm byte (str char at s 28)) or ((norm byte (str char at s 29)) shl 8) or ((norm byte (str char at s 30)) shl 16) or ((norm byte (str char at s 31)) shl 24)
        w

fn :: fe from raw32 String => Bool U64 Tensor[U64 * 10]
      fe from raw32 s =
        w      = raw32 to words8 s
        x_sign = (w_(7) shr 31) and 1
        w7_m   = w_(7) and 0x7FFFFFFF
        l0 = w_(0) and 67108863
        l1 = ((w_(0) shr 26) or (w_(1) shl 6)) and 33554431
        l2 = ((w_(1) shr 19) or (w_(2) shl 13)) and 67108863
        l3 = ((w_(2) shr 13) or (w_(3) shl 19)) and 33554431
        l4 = (w_(3) shr 6) and 67108863
        l5 = w_(4) and 33554431
        l6 = ((w_(4) shr 25) or (w_(5) shl 7)) and 67108863
        l7 = ((w_(5) shr 19) or (w_(6) shl 13)) and 33554431
        l8 = ((w_(6) shr 12) or (w7_m shl 20)) and 67108863
        l9 = (w7_m shr 6) and 33554431
        raw_fe = fe lit l0 l1 l2 l3 l4 l5 l6 l7 l8 l9
        frz_fe = fe freeze raw_fe
        diff   = (raw_fe_(0) xor frz_fe_(0)) or (raw_fe_(1) xor frz_fe_(1)) or (raw_fe_(2) xor frz_fe_(2)) or (raw_fe_(3) xor frz_fe_(3)) or (raw_fe_(4) xor frz_fe_(4)) or (raw_fe_(5) xor frz_fe_(5)) or (raw_fe_(6) xor frz_fe_(6)) or (raw_fe_(7) xor frz_fe_(7)) or (raw_fe_(8) xor frz_fe_(8)) or (raw_fe_(9) xor frz_fe_(9))
        (diff == 0, x_sign, raw_fe)

-- ── Ed25519 Extended Twisted Edwards Point Arithmetic (Tensor[U64 * 40]) ──

fn :: ge pack Tensor[U64 * 10] Tensor[U64 * 10] Tensor[U64 * 10] Tensor[U64 * 10] => Tensor[U64 * 40]
      ge pack x y z t =
        p = Tensor[U64 * 40]
        p_(0)  = x_(0)
        p_(1)  = x_(1)
        p_(2)  = x_(2)
        p_(3)  = x_(3)
        p_(4)  = x_(4)
        p_(5)  = x_(5)
        p_(6)  = x_(6)
        p_(7)  = x_(7)
        p_(8)  = x_(8)
        p_(9)  = x_(9)
        p_(10) = y_(0)
        p_(11) = y_(1)
        p_(12) = y_(2)
        p_(13) = y_(3)
        p_(14) = y_(4)
        p_(15) = y_(5)
        p_(16) = y_(6)
        p_(17) = y_(7)
        p_(18) = y_(8)
        p_(19) = y_(9)
        p_(20) = z_(0)
        p_(21) = z_(1)
        p_(22) = z_(2)
        p_(23) = z_(3)
        p_(24) = z_(4)
        p_(25) = z_(5)
        p_(26) = z_(6)
        p_(27) = z_(7)
        p_(28) = z_(8)
        p_(29) = z_(9)
        p_(30) = t_(0)
        p_(31) = t_(1)
        p_(32) = t_(2)
        p_(33) = t_(3)
        p_(34) = t_(4)
        p_(35) = t_(5)
        p_(36) = t_(6)
        p_(37) = t_(7)
        p_(38) = t_(8)
        p_(39) = t_(9)
        p

fn :: ge coord Tensor[U64 * 40] Int => Tensor[U64 * 10]
      ge coord p base =
        fe lit p_(base) p_(base + 1) p_(base + 2) p_(base + 3) p_(base + 4) p_(base + 5) p_(base + 6) p_(base + 7) p_(base + 8) p_(base + 9)

fn :: ge zero => Tensor[U64 * 40]
      ge zero =  ge pack (fe zero) (fe one) (fe one) (fe zero)

fn :: ge base => Tensor[U64 * 40]
      ge base =  ge pack (fe bx) (fe by) (fe one) (fe bt)

fn :: ge add Tensor[U64 * 40] Tensor[U64 * 40] => Tensor[U64 * 40]
      ge add p1 p2 =
        x1 = ge coord p1 0
        y1 = ge coord p1 10
        z1 = ge coord p1 20
        t1 = ge coord p1 30
        x2 = ge coord p2 0
        y2 = ge coord p2 10
        z2 = ge coord p2 20
        t2 = ge coord p2 30
        a  = fe mul (fe sub y1 x1) (fe sub y2 x2)
        b  = fe mul (fe add y1 x1) (fe add y2 x2)
        c  = fe mul (fe mul t1 t2) (fe d2)
        d  = fe mul z1 (fe add z2 z2)
        e  = fe sub b a
        f  = fe sub d c
        g  = fe add d c
        h  = fe add b a
        ge pack (fe mul e f) (fe mul g h) (fe mul f g) (fe mul e h)

fn :: ge dbl Tensor[U64 * 40] => Tensor[U64 * 40]
      ge dbl p =
        x1 = ge coord p 0
        y1 = ge coord p 10
        z1 = ge coord p 20
        a  = fe sq x1
        b  = fe sq y1
        z2 = fe sq z1
        c  = fe add z2 z2
        h  = fe add a b
        xy = fe add x1 y1
        e  = fe sub h (fe sq xy)
        g  = fe sub a b
        f  = fe add c g
        ge pack (fe mul e f) (fe mul g h) (fe mul f g) (fe mul e h)

fn :: ge cselect loop Tensor[U64 * 40] Tensor[U64 * 40] Tensor[U64 * 40] U64 Int => Tensor[U64 * 40]
      ge cselect loop out p0 p1 mask idx =
        | idx >= 40 = out
        | otherwise =
          v0 = p0_(idx)
          v1 = p1_(idx)
          out_(idx) = v0 xor ((v0 xor v1) and mask)
          ge cselect loop out p0 p1 mask (idx + 1)

fn :: ge cselect Tensor[U64 * 40] Tensor[U64 * 40] U64 => Tensor[U64 * 40]
      ge cselect p0 p1 bit =
        mask = (0 - (bit and 1)) and 0xFFFFFFFF
        out  = Tensor[U64 * 40]
        ge cselect loop out p0 p1 mask 0

fn :: ge scalarmult loop Tensor[U64 * 40] Tensor[U64 * 40] Tensor[U64 * 40] Tensor[U64 * 8] Int => Tensor[U64 * 40]
      ge scalarmult loop acc zero_pt p s_w bit_idx =
        | bit_idx < 0 = acc
        | otherwise   =
          acc_d = ge dbl acc
          bit   = (s_w_(bit_idx / 32) shr (bit_idx % 32)) and 1
          q     = ge cselect zero_pt p bit
          acc_n = ge add acc_d q
          ge scalarmult loop acc_n zero_pt p s_w (bit_idx - 1)

fn :: ge scalarmult ct Tensor[U64 * 40] Tensor[U64 * 8] => Tensor[U64 * 40]
      ge scalarmult ct p s_w =
        z_pt = ge zero
        ge scalarmult loop z_pt z_pt p s_w 254

fn :: ge to bytes Tensor[U64 * 40] => String
      ge to bytes p =
        recip = fe invert (ge coord p 20)
        x     = fe mul (ge coord p 0) recip
        y     = fe mul (ge coord p 10) recip
        yw    = fe to words8 y
        xw    = fe to words8 x
        yw_(7) = yw_(7) or ((xw_(0) and 1) shl 31)
        words8 to raw32 loop (c build b256) yw 0

fn :: ge finish sign Bool Bool Tensor[U64 * 10] Tensor[U64 * 10] => Bool Tensor[U64 * 40]
      ge finish sign is_zero_neg flip_sign x y =
        | is_zero_neg = (False, ge zero)
        | flip_sign =
          xn = fe sub (fe zero) x
          (True, ge pack xn y (fe one) (fe mul xn y))
        | otherwise =
          (True, ge pack x y (fe one) (fe mul x y))

fn :: ge decompress step2 Tensor[U64 * 10] Tensor[U64 * 10] U64 => Bool Tensor[U64 * 40]
      ge decompress step2 x y x_sign =
        xw   = fe to words8 x
        is_z = (xw_(0) or xw_(1) or xw_(2) or xw_(3) or xw_(4) or xw_(5) or xw_(6) or xw_(7)) == 0
        ge finish sign (is_z and (x_sign == 1)) ((xw_(0) and 1) != x_sign) x y

fn :: ge check root Bool Bool Tensor[U64 * 10] Tensor[U64 * 10] U64 => Bool Tensor[U64 * 40]
      ge check root eq_pos eq_neg x0 y x_sign =
        | eq_pos    = ge decompress step2 x0 y x_sign
        | eq_neg    = ge decompress step2 (fe mul x0 (fe sqrt m1)) y x_sign
        | otherwise = (False, ge zero)

fn :: ge decompress y Bool U64 Tensor[U64 * 10] => Bool Tensor[U64 * 40]
      ge decompress y False _ _ =  (False, ge zero)
      ge decompress y True x_sign y =
        y2    = fe sq y
        u     = fe sub y2 (fe one)
        v     = fe add (fe mul (fe d) y2) (fe one)
        v2    = fe sq v
        v3    = fe mul v2 v
        v4    = fe sq v2
        uv3   = fe mul u v3
        uv7   = fe mul uv3 v4
        x0    = fe mul uv3 (fe pow22523 uv7)
        vx2   = fe mul v (fe sq x0)
        neg_u = fe sub (fe zero) u
        ge check root (fe eq vx2 u) (fe eq vx2 neg_u) x0 y x_sign

fn :: ge from bytes String => Bool Tensor[U64 * 40]
      ge from bytes s =
        | (str len s) != 32 = (False, ge zero)
        | otherwise =
          is_canon, x_sign, y = fe from raw32 s
          ge decompress y is_canon x_sign y

-- ── Ed25519 Scalar Arithmetic mod L (8 x 32-bit little-endian words) ──

fn :: sc l words => Tensor[U64 * 8]
      sc l words =
        lw = Tensor[U64 * 8]
        lw_(0) = 0x5cf5d3ed
        lw_(1) = 0x5812631a
        lw_(2) = 0xa2f79cd6
        lw_(3) = 0x14def9de
        lw_(4) = 0
        lw_(5) = 0
        lw_(6) = 0
        lw_(7) = 0x10000000
        lw

fn :: sc lt l loop Tensor[U64 * 8] Tensor[U64 * 8] Int => Bool
      sc lt l loop w lw idx =
        | idx < 0            = False
        | w_(idx) < lw_(idx) = True
        | w_(idx) > lw_(idx) = False
        | otherwise          = sc lt l loop w lw (idx - 1)

fn :: sc lt l Tensor[U64 * 8] => Bool
      sc lt l w =  sc lt l loop w (sc l words) 7

fn :: sc sub word U64 U64 => U64 U64
      sc sub word wi wb =
        | wi >= wb  = ((wi - wb) and 0xFFFFFFFF, 0)
        | otherwise = (((wi + 0x100000000) - wb) and 0xFFFFFFFF, 1)

fn :: sc sub l loop Tensor[U64 * 8] Tensor[U64 * 8] Tensor[U64 * 8] Int U64 => Tensor[U64 * 8]
      sc sub l loop w lw out idx borrow =
        | idx >= 8  = out
        | otherwise =
          diff, nb  = sc sub word w_(idx) (lw_(idx) + borrow)
          out_(idx) = diff
          sc sub l loop w lw out (idx + 1) nb

fn :: sc sub l Tensor[U64 * 8] => Tensor[U64 * 8]
      sc sub l w =
        out = Tensor[U64 * 8]
        sc sub l loop w (sc l words) out 0 0

fn :: sc norm l Tensor[U64 * 8] => Tensor[U64 * 8]
      sc norm l w =
        | sc lt l w = w
        | otherwise = sc norm l (sc sub l w)

fn :: sc add raw loop Tensor[U64 * 8] Tensor[U64 * 8] Tensor[U64 * 8] Int U64 => Tensor[U64 * 8]
      sc add raw loop a b out idx carry =
        | idx >= 8  = out
        | otherwise =
          s = a_(idx) + b_(idx) + carry
          out_(idx) = s and 0xFFFFFFFF
          sc add raw loop a b out (idx + 1) (s shr 32)

fn :: sc add mod l Tensor[U64 * 8] Tensor[U64 * 8] => Tensor[U64 * 8]
      sc add mod l a b =
        out = Tensor[U64 * 8]
        sum = sc add raw loop a b out 0 0
        sc norm l sum

fn :: sc zero => Tensor[U64 * 8]
      sc zero =
        z = Tensor[U64 * 8]
        z_(0) = 0
        z_(1) = 0
        z_(2) = 0
        z_(3) = 0
        z_(4) = 0
        z_(5) = 0
        z_(6) = 0
        z_(7) = 0
        z

fn :: sc one => Tensor[U64 * 8]
      sc one =
        o = sc zero
        o_(0) = 1
        o

fn :: sc cond add bit Bool Tensor[U64 * 8] Tensor[U64 * 8] => Tensor[U64 * 8]
      sc cond add bit False acc _     =  acc
      sc cond add bit True  acc add_w =  sc add mod l acc add_w

fn :: sc reduce byte bits Tensor[U64 * 8] Tensor[U64 * 8] U64 Int => Tensor[U64 * 8]
      sc reduce byte bits acc one_w b bit_idx =
        | bit_idx < 0 = acc
        | otherwise   =
          acc2 = sc add mod l acc acc
          acc3 = sc cond add bit (((b shr bit_idx) and 1) == 1) acc2 one_w
          sc reduce byte bits acc3 one_w b (bit_idx - 1)

fn :: sc reduce le64 loop Tensor[U64 * 8] Tensor[U64 * 8] String Int => Tensor[U64 * 8]
      sc reduce le64 loop acc one_w s64 byte_idx =
        | byte_idx < 0 = acc
        | otherwise    =
          b    = norm byte (str char at s64 byte_idx)
          acc1 = sc reduce byte bits acc one_w b 7
          sc reduce le64 loop acc1 one_w s64 (byte_idx - 1)

fn :: sc reduce le64 String => Tensor[U64 * 8]
      sc reduce le64 s64 =
        sc reduce le64 loop (sc zero) (sc one) s64 63

fn :: sc mul word bits Tensor[U64 * 8] Tensor[U64 * 8] U64 Int => Tensor[U64 * 8]
      sc mul word bits acc s_w kw bit_idx =
        | bit_idx < 0 = acc
        | otherwise   =
          acc2 = sc add mod l acc acc
          acc3 = sc cond add bit (((kw shr bit_idx) and 1) == 1) acc2 s_w
          sc mul word bits acc3 s_w kw (bit_idx - 1)

fn :: sc mul mod l loop Tensor[U64 * 8] Tensor[U64 * 8] Tensor[U64 * 8] Int => Tensor[U64 * 8]
      sc mul mod l loop acc k_w s_w word_idx =
        | word_idx < 0 = acc
        | otherwise    =
          acc1 = sc mul word bits acc s_w k_w_(word_idx) 31
          sc mul mod l loop acc1 k_w s_w (word_idx - 1)

fn :: sc muladd mod l Tensor[U64 * 8] Tensor[U64 * 8] Tensor[U64 * 8] => Tensor[U64 * 8]
      sc muladd mod l r_w k_w s_w =
        ks = sc mul mod l loop (sc zero) k_w (sc norm l s_w) 7
        sc add mod l ks r_w

fn :: ed25519 clamp scalar String => Tensor[U64 * 8]
      ed25519 clamp scalar h64 =
        w = raw32 to words8 (byte slice h64 0 32)
        w_(0) = w_(0) and 0xFFFFFFF8
        w_(7) = (w_(7) and 0x7FFFFFFF) or 0x40000000
        w

-- ── RFC 8032 §5.1 Pure Ed25519 Public API ────────────────────

-- @implements FR-CRYPTO-005
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: ed25519 public key String => String
      ed25519 public key seed =
        | (str len seed) != 32 = ""
        | otherwise            =
          h64 = sha512 bytes seed
          s_w = ed25519 clamp scalar h64
          ge to bytes (ge scalarmult ct (ge base) s_w)

-- @implements FR-CRYPTO-005
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: ed25519 sign String String => String
      ed25519 sign seed msg =
        | (str len seed) != 32 = ""
        | otherwise            =
          h64     = sha512 bytes seed
          s_w     = ed25519 clamp scalar h64
          prefix  = byte slice h64 32 64
          a_bytes = ge to bytes (ge scalarmult ct (ge base) s_w)
          r_w     = sc reduce le64 (sha512 bytes (prefix + msg))
          r_bytes = ge to bytes (ge scalarmult ct (ge base) r_w)
          k_w     = sc reduce le64 (sha512 bytes (r_bytes + a_bytes + msg))
          cap_s_w = sc muladd mod l r_w k_w s_w
          s_bytes = words8 to raw32 loop (c build b256) cap_s_w 0
          r_bytes + s_bytes

fn :: ed25519 verify points Bool Tensor[U64 * 40] Tensor[U64 * 40] Tensor[U64 * 8] String String String => Bool
      ed25519 verify points False _ _ _ _ _ _ =  False
      ed25519 verify points True a_pt r_pt s_w r_bytes pubkey msg =
        k_w  = sc reduce le64 (sha512 bytes (r_bytes + pubkey + msg))
        lhs  = ge scalarmult ct (ge base) s_w
        rhs  = ge add r_pt (ge scalarmult ct a_pt k_w)
        x_ok = fe eq (fe mul (ge coord lhs 0) (ge coord rhs 20)) (fe mul (ge coord rhs 0) (ge coord lhs 20))
        y_ok = fe eq (fe mul (ge coord lhs 10) (ge coord rhs 20)) (fe mul (ge coord rhs 10) (ge coord lhs 20))
        x_ok and y_ok

fn :: ed25519 verify scalar Bool String String String Tensor[U64 * 8] => Bool
      ed25519 verify scalar False _ _ _ _ =  False
      ed25519 verify scalar True pubkey msg r_bytes s_w =
        ok_a, a_pt = ge from bytes pubkey
        ok_r, r_pt = ge from bytes r_bytes
        ed25519 verify points (ok_a and ok_r) a_pt r_pt s_w r_bytes pubkey msg

-- @implements FR-CRYPTO-005
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: ed25519 verify String String String => Bool
      ed25519 verify pubkey msg sig =
        | (str len pubkey) != 32 or (str len sig) != 64 = False
        | otherwise =
          r_bytes = byte slice sig 0 32
          s_bytes = byte slice sig 32 64
          s_w     = raw32 to words8 s_bytes
          ed25519 verify scalar (sc lt l s_w) pubkey msg r_bytes s_w

-- ── Minisign Format Helpers & Public API ─────────────────────

fn :: c is ws Int => Bool
      c is ws ch =  ch == 32 or ch == 9 or ch == 10 or ch == 13

fn :: c trim start String Int Int => Int
      c trim start s idx slen =
        | idx >= slen                         = slen
        | c is ws (norm byte (str char at s idx)) = c trim start s (idx + 1) slen
        | otherwise                           = idx

fn :: c trim end String Int Int => Int
      c trim end s st idx =
        | idx <= st                                   = st
        | c is ws (norm byte (str char at s (idx - 1))) = c trim end s st (idx - 1)
        | otherwise                                   = idx

fn :: c trim String => String
      c trim s =
        slen = str len s
        st   = c trim start s 0 slen
        en   = c trim end s st slen
        str slice s st en

fn :: c starts with String String => Bool
      c starts with s pfx =
        | (str len s) < (str len pfx) = False
        | otherwise                   = (str slice s 0 (str len pfx)) == pfx

fn :: c split lines loop String Int Int Int [String] => [String]
      c split lines loop s st idx slen acc =
        | idx >= slen = acc :: [c trim (str slice s st slen)]
        | (norm byte (str char at s idx)) == 10 =
          c split lines loop s (idx + 1) (idx + 1) slen (acc :: [c trim (str slice s st idx)])
        | otherwise =
          c split lines loop s st (idx + 1) slen acc

fn :: c split lines trimmed String Int => [String]
      c split lines trimmed st slen =
        | slen == 0 = []
        | otherwise = c split lines loop st 0 0 slen []

fn :: c split lines String => [String]
      c split lines s =
        st = c trim s
        c split lines trimmed st (str len st)

fn :: c b64 table => String
      c b64 table =  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

fn :: c b64 ch Int => String
      c b64 ch idx =
        t = c b64 table
        str slice t (idx and 63) ((idx and 63) + 1)

fn :: c b64 encode loop String Int Int => String
      c b64 encode loop s idx slen =
        | idx >= slen = ""
        | (idx + 3) <= slen =
          b0 = norm byte (str char at s idx)
          b1 = norm byte (str char at s (idx + 1))
          b2 = norm byte (str char at s (idx + 2))
          v  = (b0 shl 16) or (b1 shl 8) or b2
          q  = (c b64 ch (v shr 18)) + (c b64 ch (v shr 12)) + (c b64 ch (v shr 6)) + (c b64 ch v)
          q + (c b64 encode loop s (idx + 3) slen)
        | (idx + 2) == slen =
          b0 = norm byte (str char at s idx)
          b1 = norm byte (str char at s (idx + 1))
          v  = (b0 shl 16) or (b1 shl 8)
          (c b64 ch (v shr 18)) + (c b64 ch (v shr 12)) + (c b64 ch (v shr 6)) + "="
        | otherwise =
          b0 = norm byte (str char at s idx)
          v  = b0 shl 16
          (c b64 ch (v shr 18)) + (c b64 ch (v shr 12)) + "=="

fn :: c b64 encode String => String
      c b64 encode s =  c b64 encode loop s 0 (str len s)

fn :: c b64 val Int => Int
      c b64 val ch =
        | ch >= 65 and ch <= 90  = ch - 65
        | ch >= 97 and ch <= 122 = (ch - 97) + 26
        | ch >= 48 and ch <= 57  = (ch - 48) + 52
        | ch == 43               = 62
        | ch == 47               = 63
        | ch == 61               = 0 - 2
        | otherwise              = 0 - 1

fn :: c b64 quad CT16 String Int Int String Int Int Int Int => Bool String
      c b64 quad tbl s idx slen acc v0 v1 v2 v3 =
        | v0 < 0 or v1 < 0 or v2 == (0 - 1) or v3 == (0 - 1) = (False, "")
        | v2 == (0 - 2) =
          | v3 != (0 - 2) or (idx + 4) != slen = (False, "")
          | otherwise =
            b0 = (v0 shl 2) or (v1 shr 4)
            (True, acc + (c get b256 tbl ((b0 shr 4) and 15) (b0 and 15))) |.
        | v3 == (0 - 2) =
          | (idx + 4) != slen = (False, "")
          | otherwise =
            b0 = (v0 shl 2) or (v1 shr 4)
            b1 = ((v1 and 15) shl 4) or (v2 shr 2)
            s0 = c get b256 tbl ((b0 shr 4) and 15) (b0 and 15)
            s1 = c get b256 tbl ((b1 shr 4) and 15) (b1 and 15)
            (True, acc + s0 + s1) |.
        | otherwise =
          b0 = (v0 shl 2) or (v1 shr 4)
          b1 = ((v1 and 15) shl 4) or (v2 shr 2)
          b2 = ((v2 and 3) shl 6) or v3
          s0 = c get b256 tbl ((b0 shr 4) and 15) (b0 and 15)
          s1 = c get b256 tbl ((b1 shr 4) and 15) (b1 and 15)
          s2 = c get b256 tbl ((b2 shr 4) and 15) (b2 and 15)
          c b64 decode loop tbl s (idx + 4) slen (acc + s0 + s1 + s2)

fn :: c b64 decode loop CT16 String Int Int String => Bool String
      c b64 decode loop tbl s idx slen acc =
        | idx >= slen = (True, acc)
        | otherwise   =
          v0 = c b64 val (str char at s idx)
          v1 = c b64 val (str char at s (idx + 1))
          v2 = c b64 val (str char at s (idx + 2))
          v3 = c b64 val (str char at s (idx + 3))
          c b64 quad tbl s idx slen acc v0 v1 v2 v3

fn :: c b64 decode trimmed String Int => Bool String
      c b64 decode trimmed st slen =
        | slen == 0 or (slen % 4) != 0 = (False, "")
        | otherwise                    = c b64 decode loop (c build b256) st 0 slen ""

fn :: c b64 decode String => Bool String
      c b64 decode s =
        st = c trim s
        c b64 decode trimmed st (str len st)

fn :: c nth str [String] Int => String
      c nth str []       _   =  ""
      c nth str (x:rest) idx =
        | idx <= 0  = x
        | otherwise = c nth str rest (idx - 1)

fn :: c str list len [String] Int => Int
      c str list len []       acc =  acc
      c str list len (_:rest) acc =  c str list len rest (acc + 1)

-- @implements FR-CRYPTO-005
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: minisign encode pubkey String String => String
      minisign encode pubkey key_id pubkey =
        | (str len key_id) != 8 or (str len pubkey) != 32 = ""
        | otherwise = c b64 encode ("Ed" + key_id + pubkey)

fn :: minisign select pubkey line [String] Int => String
      minisign select pubkey line lines cnt =
        | cnt <= 0  = ""
        | cnt == 1  = c nth str lines 0
        | otherwise = c nth str lines 1

fn :: minisign unpack pubkey Bool String => String String
      minisign unpack pubkey False _   =  ("", "")
      minisign unpack pubkey True  raw =
        | (str len raw) != 42          = ("", "")
        | (byte slice raw 0 2) != "Ed" = ("", "")
        | otherwise                    = (byte slice raw 2 10, byte slice raw 10 42)

-- @implements FR-CRYPTO-005
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: minisign decode pubkey String => String String
      minisign decode pubkey text =
        lines   = c split lines text
        b64_str = minisign select pubkey line lines (c str list len lines 0)
        ok, raw = c b64 decode b64_str
        minisign unpack pubkey ok raw

-- @implements FR-CRYPTO-005
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: minisign sign String String String String String => String
      minisign sign seed key_id msg untrusted_comment trusted_comment =
        | (str len seed) != 32 or (str len key_id) != 8 = ""
        | otherwise =
          sig        = ed25519 sign seed msg
          global_sig = ed25519 sign seed (sig + trusted_comment)
          l1         = "untrusted comment: " + untrusted_comment
          l2         = c b64 encode ("Ed" + key_id + sig)
          l3         = "trusted comment: " + trusted_comment
          l4         = c b64 encode global_sig
          l1 + "\n" + l2 + "\n" + l3 + "\n" + l4 + "\n"

fn :: minisign extract tc line String => String
      minisign extract tc line l3 =
        | not (c starts with l3 "trusted comment: ") = ""
        | otherwise = str slice l3 17 (str len l3)

fn :: minisign extract tc lines [String] Int => String
      minisign extract tc lines lines cnt =
        | cnt < 4   = ""
        | otherwise = minisign extract tc line (c nth str lines 2)

-- @implements FR-CRYPTO-005
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: minisign trusted comment String => String
      minisign trusted comment minisig_text =
        lines = c split lines minisig_text
        minisign extract tc lines lines (c str list len lines 0)

fn :: minisign payload for alg String String => Bool String
      minisign payload for alg alg msg =
        | alg == "Ed" = (True, msg)
        | alg == "ED" = (True, bytes from list (argon2id.a2 blake2b (bytes to list msg) 64))
        | otherwise   = (False, "")

fn :: minisign check sigs Bool String String String String String String => Bool
      minisign check sigs False _ _ _ _ _ _ =  False
      minisign check sigs True pk_kid pk_bytes sig_kid payload sig tc_and_gsig =
        | not (ct equal pk_kid sig_kid) = False
        | otherwise =
          gsig = byte slice tc_and_gsig 0 64
          tc   = byte slice tc_and_gsig 64 (str len tc_and_gsig)
          (ed25519 verify pk_bytes payload sig) and (ed25519 verify pk_bytes (sig + tc) gsig)

fn :: minisign verify decoded Bool String String String String String => Bool
      minisign verify decoded False _ _ _ _ _ =  False
      minisign verify decoded True pk_kid pk_bytes msg raw2 gsig_and_tc =
        alg             = byte slice raw2 0 2
        sig_kid         = byte slice raw2 2 10
        sig             = byte slice raw2 10 74
        alg_ok, payload = minisign payload for alg alg msg
        minisign check sigs alg_ok pk_kid pk_bytes sig_kid payload sig gsig_and_tc

fn :: minisign verify body Bool String String String String String String => Bool
      minisign verify body False _ _ _ _ _ _ =  False
      minisign verify body True pk_kid pk_bytes msg l2 l3 l4 =
        ok2, raw2 = c b64 decode l2
        ok4, gsig = c b64 decode l4
        tc        = str slice l3 17 (str len l3)
        ok_all    = ok2 and ok4 and ((str len raw2) == 74) and ((str len gsig) == 64)
        minisign verify decoded ok_all pk_kid pk_bytes msg raw2 (gsig + tc)

fn :: minisign verify lines Bool String String String [String] => Bool
      minisign verify lines False _ _ _ _ =  False
      minisign verify lines True pk_kid pk_bytes msg lines =
        l1     = c nth str lines 0
        l2     = c nth str lines 1
        l3     = c nth str lines 2
        l4     = c nth str lines 3
        hdr_ok = (c starts with l1 "untrusted comment: ") and (c starts with l3 "trusted comment: ")
        minisign verify body hdr_ok pk_kid pk_bytes msg l2 l3 l4

-- @implements FR-CRYPTO-005
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: minisign verify String String String => Bool
      minisign verify pubkey_text msg minisig_text =
        pk_kid, pk_bytes = minisign decode pubkey pubkey_text
        lines            = c split lines minisig_text
        ok_hdr           = ((str len pk_bytes) == 32) and ((c str list len lines 0) >= 4)
        minisign verify lines ok_hdr pk_kid pk_bytes msg lines
