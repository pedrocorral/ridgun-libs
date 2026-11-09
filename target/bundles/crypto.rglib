-- ============================================================
-- src/main/ridgun/lib/crypto.rg
-- Pure-Ridgun Cryptographic Primitives, Bitops, SHA-256, HMAC, PBKDF2,
-- Argon2id (RGF-015) & RFC 8439 ChaCha20-Poly1305 AEAD Library (CRYPTO)
-- @implements FR-CRYPTO-001
-- @implements FR-CRYPTO-002
-- @implements FR-CRYPTO-003
-- @implements FR-CRYPTO-004
-- @implements FR-CRYPTO-005
-- @implements FR-CRYPTO-006
-- @implements NFR-PERF-001
-- @implements API-CRYPTO-001
-- @implements DM-Argon2
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
-- ============================================================

module :: crypto

import argon2id

type CT16     = ct0: A, ct1: A, ct2: A, ct3: A, ct4: A, ct5: A, ct6: A, ct7: A, ct8: A, ct9: A, ct10: A, ct11: A, ct12: A, ct13: A, ct14: A, ct15: A
type CPbkCtx  = cptbl: CT16, cpipad: String, cpopad: String
type EcPoint  = ecx: Tensor[U64 * 260], ecy: Tensor[U64 * 260], ecz: Tensor[U64 * 260], ec_inf: Bool
type EcCurve  = ecp: Tensor[U64 * 260], ecn: Tensor[U64 * 260], ecb: Tensor[U64 * 260], ecgx: Tensor[U64 * 260], ecgy: Tensor[U64 * 260], eclimbs: Int
type X509Cert = tbs_der: String, issuer_der: String, subject_der: String, issuer_cn: String, subject_cn: String, not_before_at: Int, not_after_at: Int, key_alg: String, pubkey_bytes: String, rsa_exp_bytes: String, sig_alg: String, sig_bytes: String, san_dns: [String], is_ca: Bool, key_usage_bits: Int, has_server_auth: Bool

-- ── RGF-019 Raw Byte Manipulation (`byte_str`, `bytes_from_list`, `bytes_to_list`) ──

fn :: norm byte mod Int => Int
      norm byte mod m   =
        | m < 0     = m + 256
        | otherwise = m

fn :: norm byte Int => Int
      norm byte b   =  norm byte mod (b % 256)

fn :: byte str norm Int => String
      byte str norm ub  =
        t     = Tensor[U8 * 1]
        t_(0) = ub and 255
        tensor to str t

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: byte str Int => String
      byte str n   =
        byte str norm (norm byte n)

fn :: c sb append3 String String => String String String String
      c sb append3 n2     c3     =
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
      c sb finish c0 c1 c2 c3 = ((c3 + c2) + c1) + c0

-- The tensor is bound to a name: with `_` ridgunc 0.9.49 binds a wrong `n`.
fn :: c u8 len Tensor[U8]          => Int
      c u8 len (Tensor[U8 * n] bs) =  n

fn :: c copy loop Tensor[U8] Int Tensor[U8] Int Int Int => Int
      c copy loop dst doff src soff i n =
        | i >= n    = doff + n
        | otherwise =
          dst_(doff + i) = src_(soff + i)
          c copy loop dst doff src soff (i + 1) n

-- Copies `n` bytes of `src` from `soff` into `dst` at `doff`; returns `doff + n`.
fn :: c copy bytes Tensor[U8] Int Tensor[U8] Int Int => Int
      c copy bytes dst doff src soff n =  c copy loop dst doff src soff 0 n

-- Writes `w` as 4 little-endian bytes at `off`; returns `off + 4`.
fn :: c put le32 Tensor[U8] Int Int => Int
      c put le32 t          off w   =
        uw          = w and 0xFFFFFFFF
        t_(off)     = uw and 255
        t_(off + 1) = (uw shr 8) and 255
        t_(off + 2) = (uw shr 16) and 255
        t_(off + 3) = (uw shr 24) and 255
        off + 4

fn :: bytes from list loop Tensor[U8] [Int]    Int => Tensor[U8]
      bytes from list loop t          []       _   =  t
      bytes from list loop t          (b:rest) i   =
        t_(i) = b and 255
        bytes from list loop t rest (i + 1)

-- Values outside 0..255 are taken modulo 256 (`norm byte`).
-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: bytes from list [Int] => String
      bytes from list []    =  ""
      bytes from list bs    =
        n = c list len bs
        t = Tensor[U8 * n]
        tensor to str (bytes from list loop t bs 0)

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: bytes to list String => [Int]
      bytes to list s      =
        tensor to list (tensor from str s)

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

fn :: bytes list to hex Tensor[U8] => String
      bytes list to hex bs         =  bytes to hex bs

fn :: bytes to hex str String => String
      bytes to hex str raw    =
        bytes list to hex (tensor from str raw)

fn :: crypto hex val Int => Int
      crypto hex val c   =
        | c >= 48 and c <= 57  = c - 48
        | c >= 97 and c <= 102 = (c - 97) + 10
        | c >= 65 and c <= 70  = (c - 65) + 10
        | otherwise            = 0

fn :: hex str to bytes loop String Tensor[U8] Int Int => Tensor[U8]
      hex str to bytes loop h      out        i   n   =
        | i >= n    = out
        | otherwise =
          hi      = crypto hex val (str char at h (2 * i))
          lo      = crypto hex val (str char at h ((2 * i) + 1))
          out_(i) = (hi * 16) + lo
          hex str to bytes loop h out (i + 1) n

fn :: hex str to bytes String => Tensor[U8]
      hex str to bytes h      =
        n   = (str len h) / 2
        out = Tensor[U8 * n]
        hex str to bytes loop h out 0 n

fn :: hex to byte str String => String
      hex to byte str h      =
        tensor to str (hex str to bytes h)

fn :: c list len loop [Int] Int => Int
      c list len loop [] acc = acc
      c list len loop (_:rest) acc = c list len loop rest (acc + 1)

fn :: c list len [Int] => Int
      c list len xs    =  c list len loop xs 0

fn :: byte slice String Int   Int     => String
      byte slice s      start end_idx =
        slen = str len s
        st   =
          | start < 0 = 0
          | start > slen = slen
          | otherwise = start
        en   =
          | end_idx < st = st
          | end_idx > slen = slen
          | otherwise = end_idx
        n    = en - st
        out  = Tensor[U8 * n]
        _    = c copy bytes out 0 (tensor from str s) st n
        tensor to str out

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

fn :: bitxor key pad loop Tensor[U8] Tensor[U8] Int Int Int => Tensor[U8]
      bitxor key pad loop kb         out        pad i   n   =
        | i >= n    = out
        | otherwise =
          out_(i) = (kb_(i) xor pad) and 255
          bitxor key pad loop kb out pad (i + 1) n

fn :: bitxor key pad Tensor[U8] Int => Tensor[U8]
      bitxor key pad kb         pad =
        n   = c u8 len kb
        out = Tensor[U8 * n]
        bitxor key pad loop kb out pad 0 n

-- The HMAC key `raw` zero-padded to `blen` bytes (`raw` is at most `blen` bytes).
fn :: c hmac key block String Int  => Tensor[U8]
      c hmac key block raw    blen =
        k   = tensor from str raw
        out = Tensor[U8 * blen]
        _   = c copy bytes out 0 k 0 (c u8 len k)
        out

fn :: normalize hmac key String => Tensor[U8]
      normalize hmac key key    =
        | (str len key) > 64 = c hmac key block (sha256 bytes key) 64
        | otherwise          = c hmac key block key 64

-- @implements FR-CRYPTO-003
-- @implements API-CRYPTO-001
fn :: hmac sha256 String String => String
      hmac sha256 key    msg    =
        k_block = normalize hmac key key
        ipad_s  = tensor to str (bitxor key pad k_block 54)
        opad_s  = tensor to str (bitxor key pad k_block 92)
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

fn :: bitxor byte lists loop Tensor[U8] Tensor[U8] Tensor[U8] Int Int => Tensor[U8]
      bitxor byte lists loop a          b          out        i   n   =
        | i >= n    = out
        | otherwise =
          out_(i) = byte bxor a_(i) b_(i)
          bitxor byte lists loop a b out (i + 1) n

-- Byte-wise XOR over the shorter of the two lengths.
fn :: bitxor byte lists Tensor[U8] Tensor[U8] => Tensor[U8]
      bitxor byte lists a          b          =
        la  = c u8 len a
        lb  = c u8 len b
        n   =
          | la < lb   = la
          | otherwise = lb
        out = Tensor[U8 * n]
        bitxor byte lists loop a b out 0 n

fn :: bitxor byte strings String String => String
      bitxor byte strings a      b      =
        tensor to str (bitxor byte lists (tensor from str a) (tensor from str b))

fn :: be32 bytes Int => String
      be32 bytes n   =
        un    = u32 val n
        t     = Tensor[U8 * 4]
        t_(0) = (un shr 24) and 255
        t_(1) = (un shr 16) and 255
        t_(2) = (un shr 8) and 255
        t_(3) = un and 255
        tensor to str t

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

fn :: c init acc32 String => Tensor[U64 * 32]
      c init acc32 s      =
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
      c bxor1 acc32 acc              s      =
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
      c acc32 quad _ acc off =
        b0 = byte str norm acc_(off)
        b1 = byte str norm acc_(off + 1)
        b2 = byte str norm acc_(off + 2)
        b3 = byte str norm acc_(off + 3)
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
        | (str len acc) == dk_len = acc
        | (str len acc) > dk_len  = byte slice acc 0 dk_len
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
          tbl     = CT16 "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" ""
          k_block = normalize hmac key pwd
          ipad_s  = tensor to str (bitxor key pad k_block 54)
          opad_s  = tensor to str (bitxor key pad k_block 92)
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

fn :: le32 at Tensor[U8] Int => Int
      le32 at bs         off =
        bs_(off) + (bs_(off + 1) * 256) + (bs_(off + 2) * 65536) + (bs_(off + 3) * 16777216)

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

fn :: chacha20 init st Tensor[U8] Tensor[U8] Int => Tensor[Int * 16]
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

fn :: chacha20 emit loop Tensor[Int * 16] Tensor[Int * 16] Tensor[U8] Int => Tensor[U8]
      chacha20 emit loop mixed init out w =
        | w >= 16   = out
        | otherwise =
          _ = c put le32 out (4 * w) ((mixed_(w) + init_(w)) and 0xFFFFFFFF)
          chacha20 emit loop mixed init out (w + 1)

-- The 64-byte keystream block `counter` (RFC 8439 §2.3).
fn :: chacha20 block Tensor[U8] Tensor[U8] Int     => Tensor[U8]
      chacha20 block key_bs     nonce_bs   counter =
        init_st = chacha20 init st key_bs nonce_bs counter
        work_st = chacha20 init st key_bs nonce_bs counter
        mixed   = chacha rounds loop work_st 0
        chacha20 emit loop mixed init_st (Tensor[U8 * 64]) 0

fn :: chacha copy st Tensor[Int * 16] Tensor[Int * 16] Int => Tensor[Int * 16]
      chacha copy st src              dst              i   =
        | i >= 16   = dst
        | otherwise =
          dst_(i) = src_(i)
          chacha copy st src dst (i + 1)

fn :: chacha20 mix block Tensor[Int * 16] Tensor[Int * 16] Tensor[U8] Tensor[U8] Int Int Int => Int
      chacha20 mix block mixed init msg out off n i =
        | i >= 64 or (off + i) >= n = 0
        | otherwise =
          w             = i shr 2
          ks            = ((mixed_(w) + init_(w)) shr (8 * (i and 3))) and 255
          out_(off + i) = msg_(off + i) xor ks
          chacha20 mix block mixed init msg out off n (i + 1)

fn :: chacha20 bitxor loop Tensor[Int * 16] Tensor[U8] Tensor[U8] Int Int Int => Tensor[U8]
      chacha20 bitxor loop init msg out off n ctr =
        | off >= n  = out
        | otherwise =
          init_(12) = ctr and 0xFFFFFFFF
          mixed     = chacha rounds loop (chacha copy st init (Tensor[Int * 16]) 0) 0
          _         = chacha20 mix block mixed init msg out off n 0
          chacha20 bitxor loop init msg out (off + 64) n (ctr + 1)

-- RFC 8439 §2.4 encryption: `msg` XOR the keystream from block `ctr` on.
fn :: chacha20 bitxor Tensor[U8] Tensor[U8] Int Tensor[U8] => Tensor[U8]
      chacha20 bitxor key_bs     nonce_bs   ctr msg        =
        n    = c u8 len msg
        out  = Tensor[U8 * n]
        init = chacha20 init st key_bs nonce_bs ctr
        chacha20 bitxor loop init msg out 0 n ctr

-- ── RFC 8439 Poly1305 One-Time Authenticator (5 x 26-bit limbs) ──

-- r = clamp(otk[0..16)) as 5 x 26-bit limbs (RFC 8439 §2.5.1 clamp as word masks).
fn :: poly1305 r limbs Tensor[U8] => Tensor[Int * 5]
      poly1305 r limbs otk        =
        t0    = (le32 at otk 0) and 0x0FFFFFFF
        t1    = (le32 at otk 4) and 0x0FFFFFFC
        t2    = (le32 at otk 8) and 0x0FFFFFFC
        t3    = (le32 at otk 12) and 0x0FFFFFFC
        r     = Tensor[Int * 5]
        r_(0) = t0 % 67108864
        r_(1) = ((t0 / 67108864) + ((t1 % 1048576) * 64)) % 67108864
        r_(2) = ((t1 / 1048576) + ((t2 % 16384) * 4096)) % 67108864
        r_(3) = ((t2 / 16384) + ((t3 % 256) * 262144)) % 67108864
        r_(4) = t3 / 256
        r

-- h = (h + block) * r mod 2^130 - 5 for the full 16-byte block at `off`; updates `h` in place.
fn :: poly1305 step Tensor[Int * 5] Tensor[Int * 5] Tensor[U8] Int => Tensor[Int * 5]
      poly1305 step h                r                msg        off =
        t0 = le32 at msg off
        t1 = le32 at msg (off + 4)
        t2 = le32 at msg (off + 8)
        t3 = le32 at msg (off + 12)
        h0 = h_(0) + (t0 % 67108864)
        h1 = h_(1) + (((t0 / 67108864) + ((t1 % 1048576) * 64)) % 67108864)
        h2 = h_(2) + (((t1 / 1048576) + ((t2 % 16384) * 4096)) % 67108864)
        h3 = h_(3) + (((t2 / 16384) + ((t3 % 256) * 262144)) % 67108864)
        h4 = h_(4) + ((t3 / 256) + 16777216)
        r0 = r_(0)
        r1 = r_(1)
        r2 = r_(2)
        r3 = r_(3)
        r4 = r_(4)
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
        h_(0) = f0 % 67108864
        h_(1) = n1 + cf
        h_(2) = n2
        h_(3) = n3
        h_(4) = n4
        h

fn :: poly1305 blocks loop Tensor[Int * 5] Tensor[Int * 5] Tensor[U8] Int Int => Tensor[Int * 5]
      poly1305 blocks loop h r msg off n =
        | off >= n  = h
        | otherwise = poly1305 blocks loop (poly1305 step h r msg off) r msg (off + 16) n

fn :: c pick Bool Int Int => Int
      c pick use_a a   b   =
        | use_a     = a
        | otherwise = b

fn :: poly1305 finalize Tensor[Int * 5] Tensor[U8] => Tensor[U8]
      poly1305 finalize h                otk        =
        c1   = h_(1) / 67108864
        h1   = h_(1) % 67108864
        t2   = h_(2) + c1
        c2   = t2 / 67108864
        h2   = t2 % 67108864
        t3   = h_(3) + c2
        c3   = t3 / 67108864
        h3   = t3 % 67108864
        t4   = h_(4) + c3
        c4   = t4 / 67108864
        h4   = t4 % 67108864
        t0   = h_(0) + (c4 * 5)
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

        use_g = g4 >= 0
        f0   = c pick use_g g0 h0
        f1   = c pick use_g g1 h1_f
        f2   = c pick use_g g2 h2
        f3   = c pick use_g g3 h3
        f4   = c pick use_g g4 h4

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
        tag  = Tensor[U8 * 16]
        o1   = c put le32 tag 0 (sum0 % 4294967296)
        o2   = c put le32 tag o1 (sum1 % 4294967296)
        o3   = c put le32 tag o2 (sum2 % 4294967296)
        _    = c put le32 tag o3 (sum3 % 4294967296)
        tag

fn :: pad16 len Int => Int
      pad16 len len =
        | (len % 16) == 0 = 0
        | otherwise       = 16 - (len % 16)

-- Writes `n` as 8 little-endian bytes at `off`; returns `off + 8`.
fn :: c put le64 Tensor[U8] Int Int => Int
      c put le64 t          off n   =
        o1 = c put le32 t off (n % 4294967296)
        c put le32 t o1 (n / 4294967296)

-- RFC 8439 §2.8 MAC input: aad || pad16 || ct || pad16 || le64(len aad) || le64(len ct).
fn :: poly1305 aead mac Tensor[U8] Tensor[U8] Tensor[U8] => Tensor[U8]
      poly1305 aead mac otk        aad_b      ct_b       =
        alen  = c u8 len aad_b
        clen  = c u8 len ct_b
        apad  = pad16 len alen
        cpad  = pad16 len clen
        total = alen + apad + clen + cpad + 16
        msg   = Tensor[U8 * total]
        o1    = c copy bytes msg 0 aad_b 0 alen
        o2    = c copy bytes msg (o1 + apad) ct_b 0 clen
        o3    = c put le64 msg (o2 + cpad) alen
        _     = c put le64 msg o3 clen
        r     = poly1305 r limbs otk
        h_fin = poly1305 blocks loop (Tensor[Int * 5]) r msg 0 total
        poly1305 finalize h_fin otk

-- @implements FR-CRYPTO-004
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: aead seal String String String String => String
      aead seal key nonce aad plaintext =
        | (str len key) != 32 or (str len nonce) != 12 = ""
        | otherwise                                    =
          key_bs   = tensor from str key
          nonce_bs = tensor from str nonce
          otk      = chacha20 block key_bs nonce_bs 0
          ct_bs    = chacha20 bitxor key_bs nonce_bs 1 (tensor from str plaintext)
          tag_bs   = poly1305 aead mac otk (tensor from str aad) ct_bs
          (tensor to str ct_bs) + (tensor to str tag_bs)

fn :: decrypt verified aead Bool Tensor[U8] Tensor[U8] Tensor[U8] => Int String
      decrypt verified aead False _          _          _          =  (0 - 12, "")
      decrypt verified aead True  key_bs     nonce_bs   ct_bs      =
        chacha20 bitxor key_bs nonce_bs 1 ct_bs -> pt_bs
        (0, tensor to str pt_bs)

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
          key_bs    = tensor from str key
          nonce_bs  = tensor from str nonce
          ct_bs     = tensor from str ct_str
          otk       = chacha20 block key_bs nonce_bs 0
          exp_tag   = tensor to str (poly1305 aead mac otk (tensor from str aad) ct_bs)
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
      sha512 big sigma0 ah  al  =
        r1h, r1l = sha512 rrot lt32 ah al 28
        r2h, r2l = sha512 rrot lt32 al ah 2
        r3h, r3l = sha512 rrot lt32 al ah 7
        ((r1h xor r2h) xor r3h, (r1l xor r2l) xor r3l)

fn :: sha512 big sigma1 U64 U64 => U64 U64
      sha512 big sigma1 eh  el  =
        r1h, r1l = sha512 rrot lt32 eh el 14
        r2h, r2l = sha512 rrot lt32 eh el 18
        r3h, r3l = sha512 rrot lt32 el eh 9
        ((r1h xor r2h) xor r3h, (r1l xor r2l) xor r3l)

fn :: sha512 small sigma0 U64 U64 => U64 U64
      sha512 small sigma0 xh  xl  =
        r1h, r1l = sha512 rrot lt32 xh xl 1
        r2h, r2l = sha512 rrot lt32 xh xl 8
        r3h, r3l = sha512 rshift lt32 xh xl 7
        ((r1h xor r2h) xor r3h, (r1l xor r2l) xor r3l)

fn :: sha512 small sigma1 U64 U64 => U64 U64
      sha512 small sigma1 xh  xl  =
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
      sha512 expand w w                 t   =
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
      sha512 bytes msg    =
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
      sha512 hex msg    =
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
      fe carry pass h                =
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
      fe carry h                =
        h1 = fe carry pass h
        h2 = fe carry pass h1
        c0 = h2_(0) shr 26
        h2_(0) = h2_(0) and 67108863
        h2_(1) = h2_(1) + c0
        h2

fn :: fe add Tensor[U64 * 10] Tensor[U64 * 10] => Tensor[U64 * 10]
      fe add f                g                =
        fe lit (f_(0) + g_(0)) (f_(1) + g_(1)) (f_(2) + g_(2)) (f_(3) + g_(3)) (f_(4) + g_(4)) (f_(5) + g_(5)) (f_(6) + g_(6)) (f_(7) + g_(7)) (f_(8) + g_(8)) (f_(9) + g_(9))

fn :: fe sub Tensor[U64 * 10] Tensor[U64 * 10] => Tensor[U64 * 10]
      fe sub f                g                =
        h = fe lit ((f_(0) + 134217690) - g_(0)) ((f_(1) + 67108862) - g_(1)) ((f_(2) + 134217726) - g_(2)) ((f_(3) + 67108862) - g_(3)) ((f_(4) + 134217726) - g_(4)) ((f_(5) + 67108862) - g_(5)) ((f_(6) + 134217726) - g_(6)) ((f_(7) + 67108862) - g_(7)) ((f_(8) + 134217726) - g_(8)) ((f_(9) + 67108862) - g_(9))
        fe carry h

fn :: fe mul Tensor[U64 * 10] Tensor[U64 * 10] => Tensor[U64 * 10]
      fe mul f                g                =
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
      fe sq f                =  fe mul f f

fn :: fe sq n Tensor[U64 * 10] Int => Tensor[U64 * 10]
      fe sq n f                n   =
        | n <= 0    = f
        | otherwise = fe sq n (fe sq f) (n - 1)

fn :: fe freeze Tensor[U64 * 10] => Tensor[U64 * 10]
      fe freeze f                =
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
        h_(9) = (h_(9) + c8) and 33554431
        h

fn :: fe eq Tensor[U64 * 10] Tensor[U64 * 10] => Bool
      fe eq f                g                =
        ff = fe freeze f
        gf = fe freeze g
        d  = (ff_(0) xor gf_(0)) or (ff_(1) xor gf_(1)) or (ff_(2) xor gf_(2)) or (ff_(3) xor gf_(3)) or (ff_(4) xor gf_(4)) or (ff_(5) xor gf_(5)) or (ff_(6) xor gf_(6)) or (ff_(7) xor gf_(7)) or (ff_(8) xor gf_(8)) or (ff_(9) xor gf_(9))
        d == 0

fn :: fe pow22523 Tensor[U64 * 10] => Tensor[U64 * 10]
      fe pow22523 z                =
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
      fe invert z                =
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
      fe to words8 f                =
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
      raw32 to words8 s      =
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
      fe from raw32 s      =
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

fn :: ge coord Tensor[U64 * 40] Int  => Tensor[U64 * 10]
      ge coord p                base =
        fe lit p_(base) p_(base + 1) p_(base + 2) p_(base + 3) p_(base + 4) p_(base + 5) p_(base + 6) p_(base + 7) p_(base + 8) p_(base + 9)

fn :: ge zero => Tensor[U64 * 40]
      ge zero =  ge pack (fe zero) (fe one) (fe one) (fe zero)

fn :: ge base => Tensor[U64 * 40]
      ge base =  ge pack (fe bx) (fe by) (fe one) (fe bt)

fn :: ge add Tensor[U64 * 40] Tensor[U64 * 40] => Tensor[U64 * 40]
      ge add p1               p2               =
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
      ge dbl p                =
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
      ge cselect p0               p1               bit =
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
      ge scalarmult ct p                s_w             =
        z_pt = ge zero
        ge scalarmult loop z_pt z_pt p s_w 254

fn :: ge to bytes Tensor[U64 * 40] => String
      ge to bytes p                =
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
      ge decompress y False _ _ = (False, ge zero)
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
      ge from bytes s      =
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
      sc lt l w               =  sc lt l loop w (sc l words) 7

fn :: sc sub word U64 U64 => U64 U64
      sc sub word wi  wb  =
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
      sc sub l w               =
        out = Tensor[U64 * 8]
        sc sub l loop w (sc l words) out 0 0

fn :: sc norm l Tensor[U64 * 8] => Tensor[U64 * 8]
      sc norm l w               =
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
      sc cond add bit False acc _ = acc
      sc cond add bit True acc add_w = sc add mod l acc add_w

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
      sc reduce le64 s64    =
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
      ed25519 clamp scalar h64    =
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
      ed25519 public key seed   =
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
      ed25519 sign seed   msg    =
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
      ed25519 verify points False _ _ _ _ _ _ = False
      ed25519 verify points True a_pt r_pt s_w r_bytes pubkey msg =
        k_w  = sc reduce le64 (sha512 bytes (r_bytes + pubkey + msg))
        lhs  = ge scalarmult ct (ge base) s_w
        rhs  = ge add r_pt (ge scalarmult ct a_pt k_w)
        x_ok = fe eq (fe mul (ge coord lhs 0) (ge coord rhs 20)) (fe mul (ge coord rhs 0) (ge coord lhs 20))
        y_ok = fe eq (fe mul (ge coord lhs 10) (ge coord rhs 20)) (fe mul (ge coord rhs 10) (ge coord lhs 20))
        x_ok and y_ok

fn :: ed25519 verify scalar Bool String String String Tensor[U64 * 8] => Bool
      ed25519 verify scalar False _ _ _ _ = False
      ed25519 verify scalar True pubkey msg r_bytes s_w =
        ok_a, a_pt = ge from bytes pubkey
        ok_r, r_pt = ge from bytes r_bytes
        ed25519 verify points (ok_a and ok_r) a_pt r_pt s_w r_bytes pubkey msg

-- @implements FR-CRYPTO-005
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: ed25519 verify String String String => Bool
      ed25519 verify pubkey msg    sig    =
        | (str len pubkey) != 32 or (str len sig) != 64 = False
        | otherwise =
          r_bytes = byte slice sig 0 32
          s_bytes = byte slice sig 32 64
          s_w     = raw32 to words8 s_bytes
          ed25519 verify scalar (sc lt l s_w) pubkey msg r_bytes s_w

-- ── Minisign Format Helpers & Public API ─────────────────────

fn :: c is ws Int => Bool
      c is ws ch  =  ch == 32 or ch == 9 or ch == 10 or ch == 13

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
      c trim s      =
        slen = str len s
        st   = c trim start s 0 slen
        en   = c trim end s st slen
        str slice s st en

fn :: c starts with String String => Bool
      c starts with s      pfx    =
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
      c split lines s      =
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
      c b64 encode s      =  c b64 encode loop s 0 (str len s)

fn :: c b64 val Int => Int
      c b64 val ch  =
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
      c b64 decode s      =
        st = c trim s
        c b64 decode trimmed st (str len st)

fn :: c nth str [String] Int => String
      c nth str []       _   =  ""
      c nth str (x:rest) idx =
        | idx <= 0  = x
        | otherwise = c nth str rest (idx - 1)

fn :: c str list len [String] Int => Int
      c str list len [] acc = acc
      c str list len (_:rest) acc = c str list len rest (acc + 1)

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

fn :: minisign unpack pubkey Bool  String => String String
      minisign unpack pubkey False _      =  ("", "")
      minisign unpack pubkey True  raw    =
        | (str len raw) != 42          = ("", "")
        | (byte slice raw 0 2) != "Ed" = ("", "")
        | otherwise                    = (byte slice raw 2 10, byte slice raw 10 42)

-- @implements FR-CRYPTO-005
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: minisign decode pubkey String => String String
      minisign decode pubkey text   =
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
      minisign extract tc line l3     =
        | not (c starts with l3 "trusted comment: ") = ""
        | otherwise = str slice l3 17 (str len l3)

fn :: minisign extract tc lines [String] Int => String
      minisign extract tc lines lines cnt =
        | cnt < 4   = ""
        | otherwise = minisign extract tc line (c nth str lines 2)

-- @implements FR-CRYPTO-005
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: minisign trusted comment String       => String
      minisign trusted comment minisig_text =
        lines = c split lines minisig_text
        minisign extract tc lines lines (c str list len lines 0)

fn :: minisign payload for alg String String => Bool String
      minisign payload for alg alg msg =
        | alg == "Ed" = (True, msg)
        | alg == "ED" = (True, tensor to str (argon2id.a2 blake2b (tensor from str msg) 64))
        | otherwise   = (False, "")

fn :: minisign check sigs Bool String String String String String String => Bool
      minisign check sigs False _ _ _ _ _ _ = False
      minisign check sigs True pk_kid pk_bytes sig_kid payload sig tc_and_gsig =
        | not (ct equal pk_kid sig_kid) = False
        | otherwise =
          gsig = byte slice tc_and_gsig 0 64
          tc   = byte slice tc_and_gsig 64 (str len tc_and_gsig)
          (ed25519 verify pk_bytes payload sig) and (ed25519 verify pk_bytes (sig + tc) gsig)

fn :: minisign verify decoded Bool String String String String String => Bool
      minisign verify decoded False _ _ _ _ _ = False
      minisign verify decoded True pk_kid pk_bytes msg raw2 gsig_and_tc =
        alg             = byte slice raw2 0 2
        sig_kid         = byte slice raw2 2 10
        sig             = byte slice raw2 10 74
        alg_ok, payload = minisign payload for alg alg msg
        minisign check sigs alg_ok pk_kid pk_bytes sig_kid payload sig gsig_and_tc

fn :: minisign verify body Bool String String String String String String => Bool
      minisign verify body False _ _ _ _ _ _ = False
      minisign verify body True pk_kid pk_bytes msg l2 l3 l4 =
        ok2, raw2 = c b64 decode l2
        ok4, gsig = c b64 decode l4
        tc        = str slice l3 17 (str len l3)
        ok_all    = ok2 and ok4 and ((str len raw2) == 74) and ((str len gsig) == 64)
        minisign verify decoded ok_all pk_kid pk_bytes msg raw2 (gsig + tc)

fn :: minisign verify lines Bool String String String [String] => Bool
      minisign verify lines False _ _ _ _ = False
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
fn :: minisign verify String      String String       => Bool
      minisign verify pubkey_text msg    minisig_text =
        pk_kid, pk_bytes = minisign decode pubkey pubkey_text
        lines            = c split lines minisig_text
        ok_hdr           = ((str len pk_bytes) == 32) and ((c str list len lines 0) >= 4)
        minisign verify lines ok_hdr pk_kid pk_bytes msg lines


-- ============================================================
-- FR-CRYPTO-006: SHA-384, HMAC-SHA-384 & HKDF (RFC 5869 / RFC 8446)
-- ============================================================

fn :: sha384 init h => Tensor[U64 * 16]
      sha384 init h =
        h = Tensor[U64 * 16]
        s = "cbbb9d5dc1059ed8629a292a367cd5079159015a3070dd17152fecd8f70e593967332667ffc00b318eb44a8768581511db0c2e0d64f98fa747b5481dbefa4fa4"
        sha512 init h loop h s 0

fn :: sha384 state to raw CT16 Tensor[U64 * 16] Int => String
      sha384 state to raw tbl h idx =
        | idx >= 12 = ""
        | otherwise = (c word32 to raw4 tbl h_(idx)) + (sha384 state to raw tbl h (idx + 1))

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: sha384 bytes String => String
      sha384 bytes msg    =
        mlen      = str len msg
        total_len = ((mlen + 17 + 127) / 128) * 128
        h0        = sha384 init h
        v0        = Tensor[U64 * 16]
        k         = sha512 init k
        w         = Tensor[U64 * 160]
        hf        = sha512 blocks loop h0 v0 k w msg mlen total_len 0
        sha384 state to raw (c build b256) hf 0

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: sha384 hex String => String
      sha384 hex msg    =
        msg sha384 bytes -> bytes to hex str

fn :: normalize hmac384 key String => Tensor[U8]
      normalize hmac384 key key    =
        | (str len key) > 128 = c hmac key block (sha384 bytes key) 128
        | otherwise           = c hmac key block key 128

fn :: hmac sha384 String String => String
      hmac sha384 key    msg    =
        k_block = normalize hmac384 key key
        ipad_s  = tensor to str (bitxor key pad k_block 54)
        opad_s  = tensor to str (bitxor key pad k_block 92)
        inner   = sha384 bytes (ipad_s + msg)
        sha384 bytes (opad_s + inner)

fn :: c repeat byte Int Int => String
      c repeat byte b   n   =
        | n <= 0    = ""
        | otherwise = (byte str b) + (c repeat byte b (n - 1))

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
fn :: hkdf extract String String => String
      hkdf extract salt   ikm    =
        | (str len salt) == 0 = hmac sha256 (c repeat byte 0 32) ikm
        | otherwise           = hmac sha256 salt ikm

fn :: hkdf expand loop String String Int Int String String => String
      hkdf expand loop prk info out_len idx prev acc =
        | (str len acc) == out_len = acc
        | (str len acc) > out_len  = byte slice acc 0 out_len
        | otherwise                =
          t_cur = hmac sha256 prk (prev + info + (byte str idx))
          hkdf expand loop prk info out_len (idx + 1) t_cur (acc + t_cur)

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: hkdf expand String String Int     => String
      hkdf expand prk    info   out_len =
        | out_len <= 0 or out_len > 8160 = ""
        | otherwise                      = hkdf expand loop prk info out_len 1 "" ""

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
fn :: hkdf extract sha384 String String => String
      hkdf extract sha384 salt   ikm    =
        | (str len salt) == 0 = hmac sha384 (c repeat byte 0 48) ikm
        | otherwise           = hmac sha384 salt ikm

fn :: hkdf expand sha384 loop String String Int Int String String => String
      hkdf expand sha384 loop prk info out_len idx prev acc =
        | (str len acc) == out_len = acc
        | (str len acc) > out_len  = byte slice acc 0 out_len
        | otherwise                =
          t_cur = hmac sha384 prk (prev + info + (byte str idx))
          hkdf expand sha384 loop prk info out_len (idx + 1) t_cur (acc + t_cur)

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: hkdf expand sha384 String String Int     => String
      hkdf expand sha384 prk    info   out_len =
        | out_len <= 0 or out_len > 12240 = ""
        | otherwise                       = hkdf expand sha384 loop prk info out_len 1 "" ""

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
fn :: hkdf expand label String String String  Int     => String
      hkdf expand label secret label  context out_len =
        full_lbl = "tls13 " + label
        len_be2  = (byte str ((out_len / 256) % 256)) + (byte str (out_len % 256))
        lbl_vec  = (byte str (str len full_lbl)) + full_lbl
        ctx_vec  = (byte str (str len context)) + context
        hkdf expand secret (len_be2 + lbl_vec + ctx_vec) out_len

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
fn :: derive secret String String String   => String
      derive secret secret label  messages =
        hkdf expand label secret label (sha256 bytes messages) 32

-- ============================================================
-- FR-CRYPTO-006: RFC 7748 X25519 Constant-Time Diffie-Hellman
-- ============================================================

fn :: fe a24 => Tensor[U64 * 10]
      fe a24 =  fe lit 121665 0 0 0 0 0 0 0 0 0

fn :: fe cswap loop Tensor[U64 * 10] Tensor[U64 * 10] U64 Int => Tensor[U64 * 10] Tensor[U64 * 10]
      fe cswap loop p q mask idx =
        | idx >= 10 = (p, q)
        | otherwise =
          t = (p_(idx) xor q_(idx)) and mask
          p_(idx) = p_(idx) xor t
          q_(idx) = q_(idx) xor t
          fe cswap loop p q mask (idx + 1)

fn :: fe cswap Tensor[U64 * 10] Tensor[U64 * 10] U64 => Tensor[U64 * 10] Tensor[U64 * 10]
      fe cswap p                q                bit =
        mask = (0 - (bit and 1)) and 0xFFFFFFFF
        p_c  = fe lit p_(0) p_(1) p_(2) p_(3) p_(4) p_(5) p_(6) p_(7) p_(8) p_(9)
        q_c  = fe lit q_(0) q_(1) q_(2) q_(3) q_(4) q_(5) q_(6) q_(7) q_(8) q_(9)
        fe cswap loop p_c q_c mask 0

fn :: x25519 clamp scalar String => Tensor[U64 * 8]
      x25519 clamp scalar k32    =
        w = raw32 to words8 k32
        w_(0) = w_(0) and 0xFFFFFFF8
        w_(7) = (w_(7) and 0x7FFFFFFF) or 0x40000000
        w

fn :: x25519 decode u String => Tensor[U64 * 10]
      x25519 decode u u32    =
        _, _, u_fe = fe from raw32 u32
        u_fe

fn :: x25519 ladder loop Tensor[U64 * 8] Tensor[U64 * 10] Tensor[U64 * 10] Tensor[U64 * 10] Tensor[U64 * 10] Tensor[U64 * 10] U64 Int => Tensor[U64 * 10] Tensor[U64 * 10]
      x25519 ladder loop k_w x1 x2 z2 x3 z3 swap_prev t =
        | t < 0 =
          x2_f, _ = fe cswap x2 x3 swap_prev
          z2_f, _ = fe cswap z2 z3 swap_prev
          (x2_f, z2_f)
        | otherwise =
          k_t       = (k_w_(t / 32) shr (t % 32)) and 1
          swap      = swap_prev xor k_t
          x2_s, x3_s = fe cswap x2 x3 swap
          z2_s, z3_s = fe cswap z2 z3 swap
          a         = fe add x2_s z2_s
          aa        = fe sq a
          b         = fe sub x2_s z2_s
          bb        = fe sq b
          e         = fe sub aa bb
          c         = fe add x3_s z3_s
          d         = fe sub x3_s z3_s
          da        = fe mul d a
          cb        = fe mul c b
          x3_n      = fe sq (fe add da cb)
          z3_n      = fe mul x1 (fe sq (fe sub da cb))
          x2_n      = fe mul aa bb
          z2_n      = fe mul e (fe add aa (fe mul (fe a24) e))
          x25519 ladder loop k_w x1 x2_n z2_n x3_n z3_n k_t (t - 1)

fn :: x25519 check non zero String => String
      x25519 check non zero out    =
        | ct equal out (c repeat byte 0 32) = ""
        | otherwise                         = out

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: x25519 String String => String
      x25519 scalar u_coord =
        | (str len scalar) != 32 or (str len u_coord) != 32 = ""
        | otherwise =
          k_w    = x25519 clamp scalar scalar
          x1     = x25519 decode u u_coord
          x2, z2 = x25519 ladder loop k_w x1 (fe one) (fe zero) x1 (fe one) 0 254
          out_fe = fe mul x2 (fe invert z2)
          out_w  = fe to words8 out_fe
          x25519 check non zero (words8 to raw32 loop (c build b256) out_w 0)

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: x25519 public key String => String
      x25519 public key scalar =
        | (str len scalar) != 32 = ""
        | otherwise              = x25519 scalar ((byte str 9) + (c repeat byte 0 31))

-- ============================================================
-- FR-CRYPTO-006: FIPS 197 AES-128 & NIST SP 800-38D AES-128-GCM
-- ============================================================

fn :: aes sbox hex => String
      aes sbox hex =
        "637c777bf26b6fc53001672bfed7ab76ca82c97dfa5947f0add4a2af9ca472c0b7fd9326363ff7cc34a5e5f171d8311504c723c31896059a071280e2eb27b27509832c1a1b6e5aa0523bd6b329e32f8453d100ed20fcb15b6acbbe394a4c58cfd0efaafb434d338545f9027f503c9fa851a3408f929d38f5bcb6da2110fff3d2cd0c13ec5f974417c4a77e3d645d197360814fdc222a908846eeb814de5e0bdbe0323a0a4906245cc2d3ac629195e479e7c8376d8dd54ea96c56f4ea657aae08ba78252e1ca6b4c6e8dd741f4bbd8b8a703eb5664803f60e613557b986c11d9ee1f8981169d98e949b1e87e9ce5528df8ca1890dbfe6426841992d0fb054bb16"

fn :: aes init sbox loop Tensor[U64 * 256] String Int => Tensor[U64 * 256]
      aes init sbox loop sb h idx =
        | idx >= 256 = sb
        | otherwise  =
          hi = c hex nib (str char at h (idx * 2))
          lo = c hex nib (str char at h ((idx * 2) + 1))
          sb_(idx) = (hi shl 4) or lo
          aes init sbox loop sb h (idx + 1)

fn :: aes init sbox => Tensor[U64 * 256]
      aes init sbox =
        sb = Tensor[U64 * 256]
        aes init sbox loop sb (aes sbox hex) 0

fn :: aes rcon Int => U64
      aes rcon r   =
        | r == 1    = 1
        | r == 2    = 2
        | r == 3    = 4
        | r == 4    = 8
        | r == 5    = 16
        | r == 6    = 32
        | r == 7    = 64
        | r == 8    = 128
        | r == 9    = 27
        | otherwise = 54

fn :: aes copy key init Tensor[U64 * 176] String Int => Tensor[U64 * 176]
      aes copy key init rk key idx =
        | idx >= 16 = rk
        | otherwise =
          rk_(idx) = norm byte (str char at key idx)
          aes copy key init rk key (idx + 1)

fn :: aes expand key loop Tensor[U64 * 256] Tensor[U64 * 176] Int => Tensor[U64 * 176]
      aes expand key loop sb rk word_idx =
        | word_idx >= 44 = rk
        | otherwise      =
          off  = word_idx * 4
          prev = off - 4
          src  = off - 16
          t0   = rk_(prev)
          t1   = rk_(prev + 1)
          t2   = rk_(prev + 2)
          t3   = rk_(prev + 3)
          u0   =
            | (word_idx % 4) == 0 = sb_(t1) xor (aes rcon (word_idx / 4))
            | otherwise           = t0
          u1   =
            | (word_idx % 4) == 0 = sb_(t2)
            | otherwise           = t1
          u2   =
            | (word_idx % 4) == 0 = sb_(t3)
            | otherwise           = t2
          u3   =
            | (word_idx % 4) == 0 = sb_(t0)
            | otherwise           = t3
          rk_(off)     = rk_(src) xor u0
          rk_(off + 1) = rk_(src + 1) xor u1
          rk_(off + 2) = rk_(src + 2) xor u2
          rk_(off + 3) = rk_(src + 3) xor u3
          aes expand key loop sb rk (word_idx + 1)

fn :: aes expand key Tensor[U64 * 256] String => Tensor[U64 * 176]
      aes expand key sb key =
        rk0 = Tensor[U64 * 176]
        rk1 = aes copy key init rk0 key 0
        aes expand key loop sb rk1 4

fn :: aes xtime U64 => U64
      aes xtime x   =
        ((x shl 1) xor (((x shr 7) and 1) * 27)) and 255

fn :: aes mix col Tensor[U64 * 16] Int => Tensor[U64 * 16]
      aes mix col st col =
        off = col * 4
        a0  = st_(off)
        a1  = st_(off + 1)
        a2  = st_(off + 2)
        a3  = st_(off + 3)
        t   = a0 xor a1 xor a2 xor a3
        st_(off)     = a0 xor t xor (aes xtime (a0 xor a1))
        st_(off + 1) = a1 xor t xor (aes xtime (a1 xor a2))
        st_(off + 2) = a2 xor t xor (aes xtime (a2 xor a3))
        st_(off + 3) = a3 xor t xor (aes xtime (a3 xor a0))
        st

fn :: aes sub shift Tensor[U64 * 256] Tensor[U64 * 16] => Tensor[U64 * 16]
      aes sub shift sb st =
        s0  = sb_(st_(0))
        s1  = sb_(st_(5))
        s2  = sb_(st_(10))
        s3  = sb_(st_(15))
        s4  = sb_(st_(4))
        s5  = sb_(st_(9))
        s6  = sb_(st_(14))
        s7  = sb_(st_(3))
        s8  = sb_(st_(8))
        s9  = sb_(st_(13))
        s10 = sb_(st_(2))
        s11 = sb_(st_(7))
        s12 = sb_(st_(12))
        s13 = sb_(st_(1))
        s14 = sb_(st_(6))
        s15 = sb_(st_(11))
        st_(0)  = s0
        st_(1)  = s1
        st_(2)  = s2
        st_(3)  = s3
        st_(4)  = s4
        st_(5)  = s5
        st_(6)  = s6
        st_(7)  = s7
        st_(8)  = s8
        st_(9)  = s9
        st_(10) = s10
        st_(11) = s11
        st_(12) = s12
        st_(13) = s13
        st_(14) = s14
        st_(15) = s15
        st

fn :: aes add rk loop Tensor[U64 * 16] Tensor[U64 * 176] Int Int => Tensor[U64 * 16]
      aes add rk loop st rk base idx =
        | idx >= 16 = st
        | otherwise =
          st_(idx) = st_(idx) xor rk_(base + idx)
          aes add rk loop st rk base (idx + 1)

fn :: aes rounds loop Tensor[U64 * 256] Tensor[U64 * 176] Tensor[U64 * 16] Int => Tensor[U64 * 16]
      aes rounds loop sb rk st r =
        | r >= 10   =
          st1 = aes sub shift sb st
          aes add rk loop st1 rk 160 0
        | otherwise =
          st1 = aes sub shift sb st
          st2 = aes mix col st1 0
          st3 = aes mix col st2 1
          st4 = aes mix col st3 2
          st5 = aes mix col st4 3
          st6 = aes add rk loop st5 rk (r * 16) 0
          aes rounds loop sb rk st6 (r + 1)

fn :: aes load st Tensor[U64 * 16] Tensor[U64 * 176] String Int => Tensor[U64 * 16]
      aes load st st rk blk idx =
        | idx >= 16 = st
        | otherwise =
          st_(idx) = (norm byte (str char at blk idx)) xor rk_(idx)
          aes load st st rk blk (idx + 1)

fn :: aes st to str CT16 Tensor[U64 * 16] Int => String
      aes st to str tbl st idx =
        | idx >= 16 = ""
        | otherwise =
          v = st_(idx) and 255
          (c get b256 tbl (v shr 4) (v and 15)) + (aes st to str tbl st (idx + 1))

fn :: aes encrypt with rk CT16 Tensor[U64 * 256] Tensor[U64 * 176] String => String
      aes encrypt with rk tbl sb rk blk16 =
        st0 = Tensor[U64 * 16]
        st1 = aes load st st0 rk blk16 0
        stf = aes rounds loop sb rk st1 1
        aes st to str tbl stf 0

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: aes128 block String String => String
      aes128 block key    blk    =
        | (str len key) != 16 or (str len blk) != 16 = ""
        | otherwise =
          sb = aes init sbox
          rk = aes expand key sb key
          aes encrypt with rk (c build b256) sb rk blk

fn :: ghash bytes to words4 String Int => Tensor[U64 * 4]
      ghash bytes to words4 s off =
        w = Tensor[U64 * 4]
        slen = str len s
        w_(0) = ((ghash byte at s slen off) shl 24) or ((ghash byte at s slen (off + 1)) shl 16) or ((ghash byte at s slen (off + 2)) shl 8) or (ghash byte at s slen (off + 3))
        w_(1) = ((ghash byte at s slen (off + 4)) shl 24) or ((ghash byte at s slen (off + 5)) shl 16) or ((ghash byte at s slen (off + 6)) shl 8) or (ghash byte at s slen (off + 7))
        w_(2) = ((ghash byte at s slen (off + 8)) shl 24) or ((ghash byte at s slen (off + 9)) shl 16) or ((ghash byte at s slen (off + 10)) shl 8) or (ghash byte at s slen (off + 11))
        w_(3) = ((ghash byte at s slen (off + 12)) shl 24) or ((ghash byte at s slen (off + 13)) shl 16) or ((ghash byte at s slen (off + 14)) shl 8) or (ghash byte at s slen (off + 15))
        w

fn :: ghash byte at String Int Int => U64
      ghash byte at s slen pos =
        | pos >= slen = 0
        | otherwise   = norm byte (str char at s pos)

fn :: ghash mul loop Tensor[U64 * 4] Tensor[U64 * 4] Tensor[U64 * 4] Int => Tensor[U64 * 4]
      ghash mul loop x v z bit_idx =
        | bit_idx >= 128 = z
        | otherwise      =
          w_idx = bit_idx / 32
          sh    = 31 - (bit_idx % 32)
          bit   = (x_(w_idx) shr sh) and 1
          mask  = (0 - bit) and 0xFFFFFFFF
          z_(0) = z_(0) xor (v_(0) and mask)
          z_(1) = z_(1) xor (v_(1) and mask)
          z_(2) = z_(2) xor (v_(2) and mask)
          z_(3) = z_(3) xor (v_(3) and mask)
          lsb   = v_(3) and 1
          rmask = (0 - lsb) and 0xE1000000
          v0    = v_(0)
          v1    = v_(1)
          v2    = v_(2)
          v3    = v_(3)
          v_(3) = ((v3 shr 1) or ((v2 and 1) shl 31)) and 0xFFFFFFFF
          v_(2) = ((v2 shr 1) or ((v1 and 1) shl 31)) and 0xFFFFFFFF
          v_(1) = ((v1 shr 1) or ((v0 and 1) shl 31)) and 0xFFFFFFFF
          v_(0) = (v0 shr 1) xor rmask
          ghash mul loop x v z (bit_idx + 1)

fn :: ghash mul Tensor[U64 * 4] Tensor[U64 * 4] => Tensor[U64 * 4]
      ghash mul x               h_w             =
        v = Tensor[U64 * 4]
        v_(0) = h_w_(0)
        v_(1) = h_w_(1)
        v_(2) = h_w_(2)
        v_(3) = h_w_(3)
        z = Tensor[U64 * 4]
        z_(0) = 0
        z_(1) = 0
        z_(2) = 0
        z_(3) = 0
        ghash mul loop x v z 0

fn :: ghash update stream Tensor[U64 * 4] Tensor[U64 * 4] String Int Int => Tensor[U64 * 4]
      ghash update stream y h_w data off dlen =
        | off >= dlen = y
        | otherwise   =
          blk_w = ghash bytes to words4 data off
          y_(0) = y_(0) xor blk_w_(0)
          y_(1) = y_(1) xor blk_w_(1)
          y_(2) = y_(2) xor blk_w_(2)
          y_(3) = y_(3) xor blk_w_(3)
          y_next = ghash mul y h_w
          ghash update stream y_next h_w data (off + 16) dlen

fn :: ghash compute CT16 Tensor[U64 * 4] String String => String
      ghash compute tbl h_w aad ct =
        y0 = Tensor[U64 * 4]
        y0_(0) = 0
        y0_(1) = 0
        y0_(2) = 0
        y0_(3) = 0
        y1   = ghash update stream y0 h_w aad 0 (str len aad)
        y2   = ghash update stream y1 h_w ct 0 (str len ct)
        abits = (str len aad) * 8
        cbits = (str len ct) * 8
        y2_(0) = y2_(0) xor ((abits shr 32) and 0xFFFFFFFF)
        y2_(1) = y2_(1) xor (abits and 0xFFFFFFFF)
        y2_(2) = y2_(2) xor ((cbits shr 32) and 0xFFFFFFFF)
        y2_(3) = y2_(3) xor (cbits and 0xFFFFFFFF)
        yf   = ghash mul y2 h_w
        ((c word32 to raw4 tbl yf_(0)) + (c word32 to raw4 tbl yf_(1))) + ((c word32 to raw4 tbl yf_(2)) + (c word32 to raw4 tbl yf_(3)))

fn :: aes gcm mix chunk CT16 String String Int Int Int String => String
      aes gcm mix chunk tbl data ks off end_off idx acc =
        | (off + idx) >= end_off = acc
        | otherwise              =
          b_d = norm byte (str char at data (off + idx))
          b_k = norm byte (str char at ks idx)
          xv  = b_d xor b_k
          ch  = c get b256 tbl (xv shr 4) (xv and 15)
          aes gcm mix chunk tbl data ks off end_off (idx + 1) (acc + ch)

fn :: aes gcm ctr loop CT16 Tensor[U64 * 256] Tensor[U64 * 176] String String Int Int Int String String String String => String
      aes gcm ctr loop tbl sb rk nonce data off dlen ctr c0 c1 c2 c3 =
        | off >= dlen = c sb finish c0 c1 c2 c3
        | otherwise   =
          cb   = nonce + (be32 bytes ctr)
          ks   = aes encrypt with rk tbl sb rk cb
          end_o =
            | (off + 16) <= dlen = off + 16
            | otherwise          = dlen
          chunk = aes gcm mix chunk tbl data ks off end_o 0 ""
          n0, n1, n2, n3 = c sb append chunk c0 c1 c2 c3
          aes gcm ctr loop tbl sb rk nonce data (off + 16) dlen (ctr + 1) n0 n1 n2 n3

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: aes128 gcm seal String String String String => String
      aes128 gcm seal key    nonce  aad    plaintext =
        | (str len key) != 16 or (str len nonce) != 12 = ""
        | otherwise =
          tbl   = c build b256
          sb    = aes init sbox
          rk    = aes expand key sb key
          h_blk = aes encrypt with rk tbl sb rk (c repeat byte 0 16)
          h_w   = ghash bytes to words4 h_blk 0
          j0    = nonce + (be32 bytes 1)
          ej0   = aes encrypt with rk tbl sb rk j0
          ct    = aes gcm ctr loop tbl sb rk nonce plaintext 0 (str len plaintext) 2 "" "" "" ""
          s_tag = ghash compute tbl h_w aad ct
          tag   = aes gcm mix chunk tbl s_tag ej0 0 16 0 ""
          ct + tag

fn :: aes128 gcm open verified Bool CT16 Tensor[U64 * 256] Tensor[U64 * 176] String String => Int String
      aes128 gcm open verified False _ _ _ _ _ = (0 - 12, "")
      aes128 gcm open verified True tbl sb rk nonce ct =
        pt = aes gcm ctr loop tbl sb rk nonce ct 0 (str len ct) 2 "" "" "" ""
        (0, pt)

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: aes128 gcm open String String String String => Int String
      aes128 gcm open key    nonce  aad    ciphertext_and_tag =
        | (str len key) != 16 or (str len nonce) != 12 or (str len ciphertext_and_tag) < 16 = (0 - 7, "")
        | otherwise =
          tlen    = str len ciphertext_and_tag
          clen    = tlen - 16
          ct      = byte slice ciphertext_and_tag 0 clen
          tag     = byte slice ciphertext_and_tag clen tlen
          tbl     = c build b256
          sb      = aes init sbox
          rk      = aes expand key sb key
          h_blk   = aes encrypt with rk tbl sb rk (c repeat byte 0 16)
          h_w     = ghash bytes to words4 h_blk 0
          j0      = nonce + (be32 bytes 1)
          ej0     = aes encrypt with rk tbl sb rk j0
          s_tag   = ghash compute tbl h_w aad ct
          exp_tag = aes gcm mix chunk tbl s_tag ej0 0 16 0 ""
          aes128 gcm open verified (ct equal tag exp_tag) tbl sb rk nonce ct

-- ============================================================
-- FR-CRYPTO-006: 16-Bit-Limb BigInt Modular Arithmetic Engine
-- (Supports P-256 [16 limbs], P-384 [24 limbs], RSA-2048..4096 [128..256 limbs])
-- ============================================================

fn :: bn zero loop Tensor[U64 * 260] Int Int => Tensor[U64 * 260]
      bn zero loop a idx lim =
        | idx >= lim = a
        | otherwise  =
          a_(idx) = 0
          bn zero loop a (idx + 1) lim

fn :: bn zero Int => Tensor[U64 * 260]
      bn zero lim =
        a = Tensor[U64 * 260]
        bn zero loop a 0 (lim + 4)

fn :: bn zero520 loop Tensor[U64 * 520] Int Int => Tensor[U64 * 520]
      bn zero520 loop a idx lim =
        | idx >= lim = a
        | otherwise  =
          a_(idx) = 0
          bn zero520 loop a (idx + 1) lim

fn :: bn zero520 Int => Tensor[U64 * 520]
      bn zero520 lim =
        a = Tensor[U64 * 520]
        bn zero520 loop a 0 lim

fn :: bn clone loop Tensor[U64 * 260] Tensor[U64 * 260] Int Int => Tensor[U64 * 260]
      bn clone loop dst src idx lim =
        | idx >= lim = dst
        | otherwise  =
          dst_(idx) = src_(idx)
          bn clone loop dst src (idx + 1) lim

fn :: bn clone Tensor[U64 * 260] Int => Tensor[U64 * 260]
      bn clone src               lim =
        dst = bn zero lim
        bn clone loop dst src 0 lim

fn :: bn strip leading zeroes String Int Int => String
      bn strip leading zeroes s idx slen =
        | idx >= slen                         = ""
        | (norm byte (str char at s idx)) == 0 = bn strip leading zeroes s (idx + 1) slen
        | otherwise                           = byte slice s idx slen

fn :: bn from be loop Tensor[U64 * 260] String Int Int Int => Tensor[U64 * 260]
      bn from be loop out s slen idx lim =
        | idx >= lim = out
        | otherwise  =
          p_lo = (slen - 1) - (idx * 2)
          p_hi = p_lo - 1
          b_lo =
            | p_lo >= 0 and p_lo < slen = norm byte (str char at s p_lo)
            | otherwise                 = 0
          b_hi =
            | p_hi >= 0 and p_hi < slen = norm byte (str char at s p_hi)
            | otherwise                 = 0
          out_(idx) = (b_hi shl 8) or b_lo
          bn from be loop out s slen (idx + 1) lim

fn :: bn from be String Int => Tensor[U64 * 260]
      bn from be raw    lim =
        s   = bn strip leading zeroes raw 0 (str len raw)
        out = bn zero lim
        bn from be loop out s (str len s) 0 lim

fn :: bn from hex String Int => Tensor[U64 * 260]
      bn from hex h      lim =
        bn from be (hex to byte str h) lim

fn :: bn to be loop CT16 Tensor[U64 * 260] Int String String String String => String
      bn to be loop tbl a idx c0 c1 c2 c3 =
        | idx < 0   = c sb finish c0 c1 c2 c3
        | otherwise =
          w  = a_(idx)
          hi = (w shr 8) and 255
          lo = w and 255
          pair = (c get b256 tbl (hi shr 4) (hi and 15)) + (c get b256 tbl (lo shr 4) (lo and 15))
          n0, n1, n2, n3 = c sb append pair c0 c1 c2 c3
          bn to be loop tbl a (idx - 1) n0 n1 n2 n3

fn :: bn to be Tensor[U64 * 260] Int => String
      bn to be a                 lim =
        bn to be loop (c build b256) a (lim - 1) "" "" "" ""

fn :: bn is zero loop Tensor[U64 * 260] Int Int => Bool
      bn is zero loop a idx lim =
        | idx >= lim   = True
        | a_(idx) != 0 = False
        | otherwise    = bn is zero loop a (idx + 1) lim

fn :: bn is zero Tensor[U64 * 260] Int => Bool
      bn is zero a                 lim =  bn is zero loop a 0 lim

fn :: bn cmp loop Tensor[U64 * 260] Tensor[U64 * 260] Int => Int
      bn cmp loop a b idx =
        | idx < 0         = 0
        | a_(idx) < b_(idx) = 0 - 1
        | a_(idx) > b_(idx) = 1
        | otherwise       = bn cmp loop a b (idx - 1)

fn :: bn cmp Tensor[U64 * 260] Tensor[U64 * 260] Int => Int
      bn cmp a                 b                 lim =  bn cmp loop a b (lim - 1)

fn :: bn add raw loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int Int U64 => U64
      bn add raw loop a b out idx lim carry =
        | idx >= lim = carry
        | otherwise  =
          s = a_(idx) + b_(idx) + carry
          out_(idx) = s and 0xFFFF
          bn add raw loop a b out (idx + 1) lim (s shr 16)

fn :: bn sub raw loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int Int U64 => U64
      bn sub raw loop a b out idx lim borrow =
        | idx >= lim = borrow
        | otherwise  =
          av  = a_(idx)
          bv  = b_(idx) + borrow
          d   =
            | av >= bv  = av - bv
            | otherwise = (av + 65536) - bv
          nb  =
            | av >= bv  = 0
            | otherwise = 1
          out_(idx) = d and 0xFFFF
          bn sub raw loop a b out (idx + 1) lim nb

fn :: bn add mod finish Bool Tensor[U64 * 260] Tensor[U64 * 260] Int => Tensor[U64 * 260]
      bn add mod finish False out _ _ = out
      bn add mod finish True out m lim =
        _ = bn sub raw loop out m out 0 lim 0
        out

fn :: bn add mod Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int => Tensor[U64 * 260]
      bn add mod a b m lim =
        out   = bn zero lim
        carry = bn add raw loop a b out 0 lim 0
        bn add mod finish (carry > 0 or (bn cmp out m lim) >= 0) out m lim

fn :: bn sub mod Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int => Tensor[U64 * 260]
      bn sub mod a b m lim =
        | (bn cmp a b lim) >= 0 =
          out = bn zero lim
          _   = bn sub raw loop a b out 0 lim 0
          out
        | otherwise =
          out = bn zero lim
          _   = bn add raw loop a m out 0 lim 0
          _   = bn sub raw loop out b out 0 lim 0
          out

fn :: bn mul row loop Tensor[U64 * 520] Tensor[U64 * 260] U64 Int Int Int U64 => Tensor[U64 * 520]
      bn mul row loop prod b ai i j lim carry =
        | j >= lim =
          prod_(i + lim) = prod_(i + lim) + carry
          prod
        | otherwise =
          s = prod_(i + j) + (ai * b_(j)) + carry
          prod_(i + j) = s and 0xFFFF
          bn mul row loop prod b ai i (j + 1) lim (s shr 16)

fn :: bn mul full loop Tensor[U64 * 520] Tensor[U64 * 260] Tensor[U64 * 260] Int Int => Tensor[U64 * 520]
      bn mul full loop prod a b i lim =
        | i >= lim  = prod
        | a_(i) == 0 = bn mul full loop prod a b (i + 1) lim
        | otherwise =
          prod1 = bn mul row loop prod b a_(i) i 0 lim 0
          bn mul full loop prod1 a b (i + 1) lim

fn :: bn sub qm loop Tensor[U64 * 520] Tensor[U64 * 260] U64 Int Int Int U64 => Tensor[U64 * 520]
      bn sub qm loop prod m q off j lim borrow =
        | j >= lim =
          cur_top = prod_(off + lim)
          prod_(off + lim) =
            | cur_top >= borrow = cur_top - borrow
            | otherwise         = 0
          prod
        | otherwise =
          sub_v = (q * m_(j)) + borrow
          lo    = sub_v and 0xFFFF
          hi    = sub_v shr 16
          cur   = prod_(off + j)
          d     =
            | cur >= lo = cur - lo
            | otherwise = (cur + 65536) - lo
          nb    =
            | cur >= lo = hi
            | otherwise = hi + 1
          prod_(off + j) = d
          bn sub qm loop prod m q off (j + 1) lim nb

fn :: bn cmp520 offset loop Tensor[U64 * 520] Int Tensor[U64 * 260] Int => Int
      bn cmp520 offset loop prod off m idx =
        | idx < 0                  = 0
        | prod_(off + idx) < m_(idx) = 0 - 1
        | prod_(off + idx) > m_(idx) = 1
        | otherwise                = bn cmp520 offset loop prod off m (idx - 1)

fn :: bn ge520 offset Tensor[U64 * 520] Int Tensor[U64 * 260] Int => Bool
      bn ge520 offset prod off m lim =
        | prod_(off + lim) > 0 = True
        | otherwise            = (bn cmp520 offset loop prod off m (lim - 1)) >= 0

fn :: bn sub m while ge Tensor[U64 * 520] Int Tensor[U64 * 260] Int => Tensor[U64 * 520]
      bn sub m while ge prod off m lim =
        | not (bn ge520 offset prod off m lim) = prod
        | otherwise                            =
          prod1 = bn sub qm loop prod m 1 off 0 lim 0
          bn sub m while ge prod1 off m lim

fn :: bn reduce step q Tensor[U64 * 520] Tensor[U64 * 260] U64 Int Int Int => Tensor[U64 * 520]
      bn reduce step q prod m m_top idx off lim =
        p2    =
          | idx >= 2  = prod_(idx - 2)
          | otherwise = 0
        p_top = (prod_(idx) shl 32) + (prod_(idx - 1) shl 16) + p2
        q     = p_top / m_top
        res   =
          | q <= 0    = prod
          | otherwise = bn sub qm loop prod m q off 0 lim 0
        res

fn :: bn reduce loop Tensor[U64 * 520] Tensor[U64 * 260] U64 Int Int => Tensor[U64 * 520]
      bn reduce loop prod m m_top idx lim =
        | idx < lim = prod
        | otherwise =
          off   = idx - lim
          prod1 = bn reduce step q prod m m_top idx off lim
          prod2 = bn reduce step q prod1 m m_top idx off lim
          prod3 = bn sub m while ge prod2 off m lim
          bn reduce loop prod3 m m_top (idx - 1) lim

fn :: bn copy520 to out Tensor[U64 * 260] Tensor[U64 * 520] Int Int => Tensor[U64 * 260]
      bn copy520 to out out prod idx lim =
        | idx >= lim = out
        | otherwise  =
          out_(idx) = prod_(idx)
          bn copy520 to out out prod (idx + 1) lim

fn :: bn reduce520 Tensor[U64 * 520] Tensor[U64 * 260] Int => Tensor[U64 * 260]
      bn reduce520 prod m lim =
        m_lo  =
          | lim >= 2  = m_(lim - 2)
          | otherwise = 0
        m_top = (m_(lim - 1) shl 16) + m_lo + 1
        prodf = bn reduce loop prod m m_top ((2 * lim) - 1) lim
        out   = bn zero lim
        bn copy520 to out out prodf 0 lim

fn :: bn mul mod Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int => Tensor[U64 * 260]
      bn mul mod a b m lim =
        prod0 = bn zero520 ((2 * lim) + 4)
        prod1 = bn mul full loop prod0 a b 0 lim
        bn reduce520 prod1 m lim

fn :: bn sq mod Tensor[U64 * 260] Tensor[U64 * 260] Int => Tensor[U64 * 260]
      bn sq mod a m lim =  bn mul mod a a m lim

fn :: bn mod from be String Tensor[U64 * 260] Int => Tensor[U64 * 260]
      bn mod from be raw m lim =
        a     = bn from be raw lim
        prod0 = bn zero520 ((2 * lim) + 4)
        one   = bn zero lim
        one_(0) = 1
        prod1 = bn mul full loop prod0 a one 0 lim
        bn reduce520 prod1 m lim

fn :: bn mod exp bits loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int Int Int => Tensor[U64 * 260]
      bn mod exp bits loop acc base m lim e_word bit_idx =
        | bit_idx < 0 = acc
        | otherwise   =
          acc2 = bn sq mod acc m lim
          bit  = (e_word shr bit_idx) and 1
          acc3 =
            | bit == 1  = bn mul mod acc2 base m lim
            | otherwise = acc2
          bn mod exp bits loop acc3 base m lim e_word (bit_idx - 1)

fn :: bn mod exp bytes loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Int String Int Int => Tensor[U64 * 260]
      bn mod exp bytes loop acc base m lim exp_s idx elen =
        | idx >= elen = acc
        | otherwise   =
          b    = norm byte (str char at exp_s idx)
          acc1 = bn mod exp bits loop acc base m lim b 7
          bn mod exp bytes loop acc1 base m lim exp_s (idx + 1) elen

fn :: bn mod exp Tensor[U64 * 260] String Tensor[U64 * 260] Int => Tensor[U64 * 260]
      bn mod exp base exp_be m lim =
        exp_s = bn strip leading zeroes exp_be 0 (str len exp_be)
        acc0  = bn zero lim
        acc0_(0) = 1
        bn mod exp bytes loop acc0 base m lim exp_s 0 (str len exp_s)

fn :: bn mod inv Tensor[U64 * 260] Tensor[U64 * 260] Int => Tensor[U64 * 260]
      bn mod inv a m lim =
        two   = bn zero lim
        two_(0) = 2
        m_m2  = bn sub mod m two m lim
        exp_s = bn to be m_m2 lim
        bn mod exp a exp_s m lim

-- ============================================================
-- FR-CRYPTO-006: NIST P-256 & P-384 Jacobian Curve & ECDSA / ECDHE
-- ============================================================

fn :: p256 curve => EcCurve
      p256 curve =
        p  = bn from hex "ffffffff00000001000000000000000000000000ffffffffffffffffffffffff" 16
        n  = bn from hex "ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551" 16
        b  = bn from hex "5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b" 16
        gx = bn from hex "6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296" 16
        gy = bn from hex "4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5" 16
        EcCurve p n b gx gy 16

fn :: p384 curve => EcCurve
      p384 curve =
        p  = bn from hex "fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000ffffffff" 24
        n  = bn from hex "ffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52973" 24
        b  = bn from hex "b3312fa7e23ee7e4988e056be3f82d19181d9c6efe8141120314088f5013875ac656398d8a2ed19d2a85c8edd3ec2aef" 24
        gx = bn from hex "aa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b9859f741e082542a385502f25dbf55296c3a545e3872760ab7" 24
        gy = bn from hex "3617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147ce9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5f" 24
        EcCurve p n b gx gy 24

fn :: ec inf point Int => EcPoint
      ec inf point lim =
        EcPoint (bn zero lim) (bn zero lim) (bn zero lim) True

fn :: ec affine point Tensor[U64 * 260] Tensor[U64 * 260] Int => EcPoint
      ec affine point x y lim =
        z = bn zero lim
        z_(0) = 1
        EcPoint x y z False

fn :: ec point on curve EcCurve Tensor[U64 * 260] Tensor[U64 * 260] => Bool
      ec point on curve crv x y =
        | (bn cmp x (ecp crv) (eclimbs crv)) >= 0 or (bn cmp y (ecp crv) (eclimbs crv)) >= 0 = False
        | otherwise =
          p   = ecp crv
          b   = ecb crv
          lim = eclimbs crv
          lhs = bn sq mod y p lim
          x2  = bn sq mod x p lim
          x3  = bn mul mod x2 x p lim
          x_3 = bn add mod x (bn add mod x x p lim) p lim
          rhs = bn add mod (bn sub mod x3 x_3 p lim) b p lim
          (bn cmp lhs rhs lim) == 0

fn :: ec dbl EcCurve EcPoint => EcPoint
      ec dbl crv     pt      =
        | (ec_inf pt) or (bn is zero (ecy pt) (eclimbs crv)) = ec inf point (eclimbs crv)
        | otherwise =
          p     = ecp crv
          lim   = eclimbs crv
          x1    = ecx pt
          y1    = ecy pt
          z1    = ecz pt
          delta = bn sq mod z1 p lim
          gamma = bn sq mod y1 p lim
          beta  = bn mul mod x1 gamma p lim
          x_m_d = bn sub mod x1 delta p lim
          x_p_d = bn add mod x1 delta p lim
          prod  = bn mul mod x_m_d x_p_d p lim
          alpha = bn add mod prod (bn add mod prod prod p lim) p lim
          b2    = bn add mod beta beta p lim
          b4    = bn add mod b2 b2 p lim
          b8    = bn add mod b4 b4 p lim
          x3    = bn sub mod (bn sq mod alpha p lim) b8 p lim
          yz    = bn mul mod y1 z1 p lim
          z3    = bn add mod yz yz p lim
          g_sq  = bn sq mod gamma p lim
          g2    = bn add mod g_sq g_sq p lim
          g4    = bn add mod g2 g2 p lim
          g8    = bn add mod g4 g4 p lim
          y3    = bn sub mod (bn mul mod alpha (bn sub mod b4 x3 p lim) p lim) g8 p lim
          EcPoint x3 y3 z3 False

fn :: ec add diff EcCurve EcPoint Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] => EcPoint
      ec add diff crv p1 u1 u2 s1 s2 z1 z2 =
        | (bn cmp u1 u2 (eclimbs crv)) == 0 and (bn cmp s1 s2 (eclimbs crv)) == 0 = ec dbl crv p1
        | (bn cmp u1 u2 (eclimbs crv)) == 0                                       = ec inf point (eclimbs crv)
        | otherwise =
          p   = ecp crv
          lim = eclimbs crv
          h   = bn sub mod u2 u1 p lim
          r   = bn sub mod s2 s1 p lim
          hh  = bn sq mod h p lim
          hhh = bn mul mod h hh p lim
          v   = bn mul mod u1 hh p lim
          v2  = bn add mod v v p lim
          x3  = bn sub mod (bn sub mod (bn sq mod r p lim) hhh p lim) v2 p lim
          y3  = bn sub mod (bn mul mod r (bn sub mod v x3 p lim) p lim) (bn mul mod s1 hhh p lim) p lim
          z3  = bn mul mod (bn mul mod z1 z2 p lim) h p lim
          EcPoint x3 y3 z3 False

fn :: ec add EcCurve EcPoint EcPoint => EcPoint
      ec add crv     p1      p2      =
        | ec_inf p1 = p2
        | ec_inf p2 = p1
        | otherwise =
          p    = ecp crv
          lim  = eclimbs crv
          x1   = ecx p1
          y1   = ecy p1
          z1   = ecz p1
          x2   = ecx p2
          y2   = ecy p2
          z2   = ecz p2
          z1z1 = bn sq mod z1 p lim
          z2z2 = bn sq mod z2 p lim
          u1   = bn mul mod x1 z2z2 p lim
          u2   = bn mul mod x2 z1z1 p lim
          s1   = bn mul mod y1 (bn mul mod z2 z2z2 p lim) p lim
          s2   = bn mul mod y2 (bn mul mod z1 z1z1 p lim) p lim
          ec add diff crv p1 u1 u2 s1 s2 z1 z2

fn :: ec to affine EcCurve EcPoint => Bool Tensor[U64 * 260] Tensor[U64 * 260]
      ec to affine crv     pt      =
        | (ec_inf pt) or (bn is zero (ecz pt) (eclimbs crv)) = (False, bn zero (eclimbs crv), bn zero (eclimbs crv))
        | otherwise =
          p     = ecp crv
          lim   = eclimbs crv
          zinv  = bn mod inv (ecz pt) p lim
          zinv2 = bn sq mod zinv p lim
          zinv3 = bn mul mod zinv2 zinv p lim
          ax    = bn mul mod (ecx pt) zinv2 p lim
          ay    = bn mul mod (ecy pt) zinv3 p lim
          (True, ax, ay)

fn :: ec cselect bn loop Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] U64 Int Int => Tensor[U64 * 260]
      ec cselect bn loop out a b mask idx lim =
        | idx >= lim = out
        | otherwise  =
          v0 = a_(idx)
          v1 = b_(idx)
          out_(idx) = v0 xor ((v0 xor v1) and mask)
          ec cselect bn loop out a b mask (idx + 1) lim

fn :: ec cselect point EcPoint EcPoint U64 Int => EcPoint
      ec cselect point p0      p1      bit lim =
        mask = (0 - (bit and 1)) and 0xFFFF
        ox   = ec cselect bn loop (bn zero lim) (ecx p0) (ecx p1) mask 0 lim
        oy   = ec cselect bn loop (bn zero lim) (ecy p0) (ecy p1) mask 0 lim
        oz   = ec cselect bn loop (bn zero lim) (ecz p0) (ecz p1) mask 0 lim
        oinf =
          | (bit and 1) == 1 = ec_inf p1
          | otherwise        = ec_inf p0
        EcPoint ox oy oz oinf

fn :: ec scalar mul loop EcCurve EcPoint EcPoint Tensor[U64 * 260] Int => EcPoint
      ec scalar mul loop crv acc base k bit_idx =
        | bit_idx < 0 = acc
        | otherwise   =
          lim  = eclimbs crv
          acc2 = ec dbl crv acc
          w    = k_(bit_idx / 16)
          bit  = (w shr (bit_idx % 16)) and 1
          sum  = ec add crv acc2 base
          acc3 = ec cselect point acc2 sum bit lim
          ec scalar mul loop crv acc3 base k (bit_idx - 1)

fn :: ec scalar mul EcCurve EcPoint Tensor[U64 * 260] => EcPoint
      ec scalar mul crv     base    k                 =
        lim = eclimbs crv
        ec scalar mul loop crv (ec inf point lim) base k ((lim * 16) - 1)

fn :: ec shamir loop EcCurve EcPoint EcPoint EcPoint EcPoint Tensor[U64 * 260] Tensor[U64 * 260] Int => EcPoint
      ec shamir loop crv acc g_pt q_pt gq_pt u1 u2 bit_idx =
        | bit_idx < 0 = acc
        | otherwise   =
          acc2 = ec dbl crv acc
          b1   = (u1_(bit_idx / 16) shr (bit_idx % 16)) and 1
          b2   = (u2_(bit_idx / 16) shr (bit_idx % 16)) and 1
          acc3 =
            | b1 == 1 and b2 == 1 = ec add crv acc2 gq_pt
            | b1 == 1             = ec add crv acc2 g_pt
            | b2 == 1             = ec add crv acc2 q_pt
            | otherwise           = acc2
          ec shamir loop crv acc3 g_pt q_pt gq_pt u1 u2 (bit_idx - 1)

fn :: p256 public key inner EcCurve Tensor[U64 * 260] => String
      p256 public key inner crv k =
        | (bn is zero k 16) or (bn cmp k (ecn crv) 16) >= 0 = ""
        | otherwise =
          g_pt       = ec affine point (ecgx crv) (ecgy crv) 16
          pub_pt     = ec scalar mul crv g_pt k
          ok, ax, ay = ec to affine crv pub_pt
          out_s      =
            | not ok    = ""
            | otherwise = (byte str 4) + (bn to be ax 16) + (bn to be ay 16)
          out_s

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: p256 public key String => String
      p256 public key priv32 =
        | (str len priv32) != 32 = ""
        | otherwise              = p256 public key inner (p256 curve) (bn from be priv32 16)

fn :: p256 ecdh inner EcCurve Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] => String
      p256 ecdh inner crv k px py =
        | (bn is zero k 16) or (bn cmp k (ecn crv) 16) >= 0 = ""
        | not (ec point on curve crv px py)                  = ""
        | otherwise =
          peer_pt   = ec affine point px py 16
          sh_pt     = ec scalar mul crv peer_pt k
          ok, sx, _ = ec to affine crv sh_pt
          out_s     =
            | not ok    = ""
            | otherwise = bn to be sx 16
          out_s

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: p256 ecdh String String  => String
      p256 ecdh priv32 peer_pub =
        | (str len priv32) != 32 or (str len peer_pub) != 65 = ""
        | (norm byte (str char at peer_pub 0)) != 4          = ""
        | otherwise =
          crv = p256 curve
          k   = bn from be priv32 16
          px  = bn from be (byte slice peer_pub 1 33) 16
          py  = bn from be (byte slice peer_pub 33 65) 16
          p256 ecdh inner crv k px py

fn :: ecdsa unpack der rs Bool Int Int Int Int Bool Int Int Int String Int => Bool String String
      ecdsa unpack der rs ok_r tag_r r_vs r_vlen next_r ok_s tag_s s_vs s_vlen sig coord_bytes =
        | (not ok_r) or (not ok_s) or (tag_r != 2) or (tag_s != 2) = (False, "", "")
        | otherwise =
          r_raw = bn strip leading zeroes (byte slice sig r_vs (r_vs + r_vlen)) 0 r_vlen
          s_raw = bn strip leading zeroes (byte slice sig s_vs (s_vs + s_vlen)) 0 s_vlen
          ok_l  = ((str len r_raw) <= coord_bytes) and ((str len s_raw) <= coord_bytes)
          r_out =
            | ok_l      = r_raw
            | otherwise = ""
          s_out =
            | ok_l      = s_raw
            | otherwise = ""
          (ok_l, r_out, s_out)

fn :: ecdsa unpack der seq Bool Int Int String Int => Bool String String
      ecdsa unpack der seq False _ _ _ _ = (False, "", "")
      ecdsa unpack der seq True seq_vs seq_vlen sig coord_bytes =
        ok_r, tag_r, r_vs, r_vlen, next_r = asn1 parse tlv sig seq_vs
        ok_s, tag_s, s_vs, s_vlen, _      = asn1 parse tlv sig next_r
        ecdsa unpack der rs (ok_r and (next_r <= (seq_vs + seq_vlen))) tag_r r_vs r_vlen next_r ok_s tag_s s_vs s_vlen sig coord_bytes

fn :: ecdsa unpack sig String Int => Bool String String
      ecdsa unpack sig sig coord_bytes =
        | (str len sig) == (coord_bytes * 2) =
          (True, byte slice sig 0 coord_bytes, byte slice sig coord_bytes (str len sig))
        | (str len sig) >= 6 and (norm byte (str char at sig 0)) == 48 =
          ok_seq, _, seq_vs, seq_vlen, _ = asn1 parse tlv sig 0
          ecdsa unpack der seq ok_seq seq_vs seq_vlen sig coord_bytes
        | otherwise = (False, "", "")

fn :: ecdsa verify shamir EcCurve Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] Tensor[U64 * 260] String Int => Bool
      ecdsa verify shamir crv qx qy r s msg_hash coord_bytes =
        | (bn is zero r (eclimbs crv)) or (bn cmp r (ecn crv) (eclimbs crv)) >= 0 = False
        | (bn is zero s (eclimbs crv)) or (bn cmp s (ecn crv) (eclimbs crv)) >= 0 = False
        | otherwise =
          lim   = eclimbs crv
          n     = ecn crv
          e_bn  = bn mod from be (byte slice msg_hash 0 coord_bytes) n lim
          w     = bn mod inv s n lim
          u1    = bn mul mod e_bn w n lim
          u2    = bn mul mod r w n lim
          g_pt  = ec affine point (ecgx crv) (ecgy crv) lim
          q_pt  = ec affine point qx qy lim
          gq_pt = ec add crv g_pt q_pt
          r_pt  = ec shamir loop crv (ec inf point lim) g_pt q_pt gq_pt u1 u2 ((lim * 16) - 1)
          ok_a, rx, _ = ec to affine crv r_pt
          v     = bn mod from be (bn to be rx lim) n lim
          ok_a and ((bn cmp v r lim) == 0)

fn :: ecdsa verify curve EcCurve String String String => Bool
      ecdsa verify curve crv pubkey msg_hash sig =
        | (str len pubkey) != (1 + ((eclimbs crv) * 4)) = False
        | (norm byte (str char at pubkey 0)) != 4       = False
        | (str len msg_hash) < ((eclimbs crv) * 2)      = False
        | otherwise =
          lim         = eclimbs crv
          coord_bytes = lim * 2
          qx          = bn from be (byte slice pubkey 1 (1 + coord_bytes)) lim
          qy          = bn from be (byte slice pubkey (1 + coord_bytes) (1 + (coord_bytes * 2))) lim
          ok_sig, r_raw, s_raw = ecdsa unpack sig sig coord_bytes
          r           = bn from be r_raw lim
          s           = bn from be s_raw lim
          (ec point on curve crv qx qy) and ok_sig and (ecdsa verify shamir crv qx qy r s msg_hash coord_bytes)

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: ecdsa p256 verify String String   String => Bool
      ecdsa p256 verify pubkey msg_hash sig    =
        ecdsa verify curve (p256 curve) pubkey msg_hash sig

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
fn :: ecdsa p256 verify sha256 String String String => Bool
      ecdsa p256 verify sha256 pubkey msg    sig    =
        ecdsa p256 verify pubkey (sha256 bytes msg) sig

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: ecdsa p384 verify String String   String => Bool
      ecdsa p384 verify pubkey msg_hash sig    =
        ecdsa verify curve (p384 curve) pubkey msg_hash sig

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
fn :: ecdsa p384 verify sha384 String String String => Bool
      ecdsa p384 verify sha384 pubkey msg    sig    =
        ecdsa p384 verify pubkey (sha384 bytes msg) sig

-- ============================================================
-- FR-CRYPTO-006: RSA PKCS#1 v1.5 & RSA-PSS Verification (>= 2048 bits)
-- ============================================================

fn :: rsa mod exp inner String String String Int => String
      rsa mod exp inner base_be exp_be mod_s mlen =
        | mlen < 4 or mlen > 512 or (mlen % 2) != 0 = ""
        | otherwise =
          lim  = mlen / 2
          m_bn = bn from be mod_s lim
          b_bn = bn from be base_be lim
          r_bn = bn mod exp b_bn exp_be m_bn lim
          out  =
            | (bn cmp b_bn m_bn lim) >= 0 = ""
            | otherwise                   = bn to be r_bn lim
          out

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: rsa mod exp String  String String => String
      rsa mod exp base_be exp_be mod_be =
        mod_s = bn strip leading zeroes mod_be 0 (str len mod_be)
        rsa mod exp inner base_be exp_be mod_s (str len mod_s)

fn :: rsa hash msg String   String => String
      rsa hash msg hash_alg msg    =
        | hash_alg == "sha256" = sha256 bytes msg
        | hash_alg == "sha384" = sha384 bytes msg
        | hash_alg == "sha512" = sha512 bytes msg
        | otherwise            = ""

fn :: rsa digest info prefix String   => String
      rsa digest info prefix hash_alg =
        | hash_alg == "sha256" = hex to byte str "3031300d060960864801650304020105000420"
        | hash_alg == "sha384" = hex to byte str "3041300d060960864801650304020205000430"
        | hash_alg == "sha512" = hex to byte str "3051300d060960864801650304020305000440"
        | otherwise            = ""

fn :: rsa verify pkcs1 inner String String String String String Int => Bool
      rsa verify pkcs1 inner mod_s e_be hash_alg msg sig k =
        | k < 256 or k > 512 or (str len sig) != k             = False
        | ((norm byte (str char at mod_s (k - 1))) and 1) == 0 = False
        | otherwise =
          em     = rsa mod exp sig e_be mod_s
          mhash  = rsa hash msg hash_alg msg
          di_pfx = rsa digest info prefix hash_alg
          t_info = di_pfx + mhash
          t_len  = str len t_info
          ps_len = (k - t_len) - 3
          exp_em =
            | ps_len >= 8 = (byte str 0) + (byte str 1) + (c repeat byte 255 ps_len) + (byte str 0) + t_info
            | otherwise   = ""
          ((str len em) == k) and ((str len mhash) > 0) and (ps_len >= 8) and (ct equal em exp_em)

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: rsa verify pkcs1 String String String   String String => Bool
      rsa verify pkcs1 n_be   e_be   hash_alg msg    sig    =
        mod_s = bn strip leading zeroes n_be 0 (str len n_be)
        rsa verify pkcs1 inner mod_s e_be hash_alg msg sig (str len mod_s)

fn :: rsa mgf1 loop String String Int Int String => String
      rsa mgf1 loop hash_alg seed mask_len ctr acc =
        | (str len acc) == mask_len = acc
        | (str len acc) > mask_len  = byte slice acc 0 mask_len
        | otherwise                 =
          blk = rsa hash msg hash_alg (seed + (be32 bytes ctr))
          rsa mgf1 loop hash_alg seed mask_len (ctr + 1) (acc + blk)

fn :: rsa pss check db zeroes String Int Int => Bool
      rsa pss check db zeroes db idx zero_len =
        | idx >= zero_len                      = (norm byte (str char at db zero_len)) == 1
        | (norm byte (str char at db idx)) != 0 = False
        | otherwise                            = rsa pss check db zeroes db (idx + 1) zero_len

fn :: rsa pss unmask db CT16 String String Int Int String => String
      rsa pss unmask db tbl masked_db db_mask idx dlen acc =
        | idx >= dlen = acc
        | otherwise   =
          b0  = norm byte (str char at masked_db idx)
          b1  = norm byte (str char at db_mask idx)
          xv  =
            | idx == 0  = (b0 xor b1) and 127
            | otherwise = b0 xor b1
          ch  = c get b256 tbl (xv shr 4) (xv and 15)
          rsa pss unmask db tbl masked_db db_mask (idx + 1) dlen (acc + ch)

fn :: rsa verify pss em String String String Int Int => Bool
      rsa verify pss em hash_alg mhash em k hlen =
        | (str len em) != k or hlen == 0 or k < ((2 * hlen) + 2) = False
        | (norm byte (str char at em (k - 1))) != 188            = False
        | ((norm byte (str char at em 0)) and 128) != 0          = False
        | otherwise =
          db_len    = (k - hlen) - 1
          masked_db = byte slice em 0 db_len
          h_ext     = byte slice em db_len (db_len + hlen)
          db_mask   = rsa mgf1 loop hash_alg h_ext db_len 0 ""
          db        = rsa pss unmask db (c build b256) masked_db db_mask 0 db_len ""
          zero_len  = (db_len - hlen) - 1
          salt      = byte slice db (zero_len + 1) db_len
          m_prm     = (c repeat byte 0 8) + mhash + salt
          h_exp     = rsa hash msg hash_alg m_prm
          (rsa pss check db zeroes db 0 zero_len) and (ct equal h_ext h_exp)

fn :: rsa verify pss inner String String String String String Int => Bool
      rsa verify pss inner mod_s e_be hash_alg msg sig k =
        | k < 256 or k > 512 or (str len sig) != k             = False
        | ((norm byte (str char at mod_s (k - 1))) and 1) == 0 = False
        | otherwise =
          em    = rsa mod exp sig e_be mod_s
          mhash = rsa hash msg hash_alg msg
          rsa verify pss em hash_alg mhash em k (str len mhash)

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: rsa verify pss String String String   String String => Bool
      rsa verify pss n_be   e_be   hash_alg msg    sig    =
        mod_s = bn strip leading zeroes n_be 0 (str len n_be)
        rsa verify pss inner mod_s e_be hash_alg msg sig (str len mod_s)

-- ============================================================
-- FR-CRYPTO-006: ASN.1 DER, PEM & X.509 Certificate Parsing / Verification
-- ============================================================

fn :: pem strip ws step Bool CT16 Int String Int Int String String String String => String
      pem strip ws step True tbl _ s idx slen c0 c1 c2 c3 =
        pem strip ws loop tbl s (idx + 1) slen c0 c1 c2 c3
      pem strip ws step False tbl ch s idx slen c0 c1 c2 c3 =
        bs = c get b256 tbl (ch shr 4) (ch and 15)
        n0, n1, n2, n3 = c sb append bs c0 c1 c2 c3
        pem strip ws loop tbl s (idx + 1) slen n0 n1 n2 n3

fn :: pem strip ws loop CT16 String Int Int String String String String => String
      pem strip ws loop tbl s idx slen c0 c1 c2 c3 =
        | idx >= slen = c sb finish c0 c1 c2 c3
        | otherwise   =
          ch = norm byte (str char at s idx)
          pem strip ws step (c is ws ch) tbl ch s idx slen c0 c1 c2 c3

fn :: pem decode b64 block CT16 String => Bool String
      pem decode b64 block tbl raw_b64 =
        clean = pem strip ws loop tbl raw_b64 0 (str len raw_b64) "" "" "" ""
        clen  = str len clean
        c b64 decode trimmed clean clen

fn :: pem find sub from String String Int Int Int => Int
      pem find sub from s sub idx slen sublen =
        | (idx + sublen) > slen = 0 - 1
        | (idx + 4096 + sublen) <= slen and (not (str contains (str slice s idx (idx + 4096 + sublen - 1)) sub)) =
          pem find sub from s sub (idx + 4096) slen sublen
        | (str slice s idx (idx + sublen)) == sub = idx
        | otherwise                               = pem find sub from s sub (idx + 1) slen sublen

fn :: pem decode blocks step CT16 String String String Int Int Int [String] => [String]
      pem decode blocks step tbl pem_text begin_m end_m b_idx e_idx plen acc =
        | b_idx < 0 or e_idx < 0 = acc
        | otherwise =
          body_st   = b_idx + (str len begin_m)
          b64_chunk = str slice pem_text body_st e_idx
          ok, der   = pem decode b64 block tbl b64_chunk
          next_pos  = e_idx + (str len end_m)
          next_acc  =
            | ok        = acc :: [der]
            | otherwise = acc
          pem decode blocks loop tbl pem_text begin_m end_m next_pos plen next_acc

fn :: pem decode blocks loop CT16 String String String Int Int [String] => [String]
      pem decode blocks loop tbl pem_text begin_m end_m pos plen acc =
        b_idx = pem find sub from pem_text begin_m pos plen (str len begin_m)
        e_idx =
          | b_idx < 0 = 0 - 1
          | otherwise = pem find sub from pem_text end_m (b_idx + (str len begin_m)) plen (str len end_m)
        pem decode blocks step tbl pem_text begin_m end_m b_idx e_idx plen acc

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: pem decode blocks String   String => [String]
      pem decode blocks pem_text label  =
        begin_m = "-----BEGIN " + label + "-----"
        end_m   = "-----END " + label + "-----"
        pem decode blocks loop (c build b256) pem_text begin_m end_m 0 (str len pem_text) []

fn :: asn1 read len bytes String Int Int Int => Int
      asn1 read len bytes der idx rem acc =
        | rem <= 0  = acc
        | otherwise =
          b = norm byte (str char at der idx)
          asn1 read len bytes der (idx + 1) (rem - 1) ((acc * 256) + b)

fn :: asn1 finish tlv Bool Int Int Int Int Int => Bool Int Int Int Int
      asn1 finish tlv False _ _ _ _ dlen = (False, 0, 0, 0, dlen)
      asn1 finish tlv True tag vs vlen next _ = (True, tag, vs, vlen, next)

fn :: asn1 parse long len String Int Int Int Int => Bool Int Int Int Int
      asn1 parse long len der off dlen tag nbytes =
        | nbytes > 4 or (off + 2 + nbytes) > dlen = (False, 0, 0, 0, dlen)
        | otherwise =
          vlen = asn1 read len bytes der (off + 2) nbytes 0
          vs   = off + 2 + nbytes
          next = vs + vlen
          asn1 finish tlv (vlen >= 0 and next <= dlen) tag vs vlen next dlen

fn :: asn1 parse len dispatch String Int Int Int Int => Bool Int Int Int Int
      asn1 parse len dispatch der off dlen tag lb =
        | lb < 128 =
          vs   = off + 2
          next = vs + lb
          asn1 finish tlv (next <= dlen) tag vs lb next dlen
        | lb == 128 = (False, 0, 0, 0, dlen)
        | otherwise = asn1 parse long len der off dlen tag (lb - 128)

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: asn1 parse tlv String Int => Bool Int Int Int Int
      asn1 parse tlv der    off =
        | off < 0 or (off + 2) > (str len der) = (False, 0, 0, 0, str len der)
        | otherwise =
          dlen = str len der
          tag  = norm byte (str char at der off)
          lb   = norm byte (str char at der (off + 1))
          asn1 parse len dispatch der off dlen tag lb

fn :: x509 parse dec2 String Int => Int
      x509 parse dec2 s off =
        d0 = (norm byte (str char at s off)) - 48
        d1 = (norm byte (str char at s (off + 1))) - 48
        res =
          | d0 < 0 or d0 > 9 or d1 < 0 or d1 > 9 = 0 - 1
          | otherwise                             = (d0 * 10) + d1
        res

fn :: x509 days from civil Int Int Int => Int
      x509 days from civil y m d =
        y_adj =
          | m <= 2    = y - 1
          | otherwise = y
        era   =
          | y_adj >= 0 = y_adj / 400
          | otherwise  = (y_adj - 399) / 400
        yoe   = y_adj - (era * 400)
        mp    =
          | m > 2     = m - 3
          | otherwise = m + 9
        doy   = (((153 * mp) + 2) / 5) + d - 1
        doe   = (yoe * 365) + (yoe / 4) - (yoe / 100) + doy
        ((era * 146097) + doe) - 719468

fn :: x509 parse time tag Int String => Int
      x509 parse time tag tag s =
        | tag == 23 and (str len s) >= 12 =
          yy = x509 parse dec2 s 0
          mm = x509 parse dec2 s 2
          dd = x509 parse dec2 s 4
          hh = x509 parse dec2 s 6
          mi = x509 parse dec2 s 8
          ss = x509 parse dec2 s 10
          yr =
            | yy >= 50  = 1900 + yy
            | otherwise = 2000 + yy
          t_u =
            | yy < 0 or mm < 1 or mm > 12 or dd < 1 or dd > 31 or hh < 0 or hh > 23 or mi < 0 or mi > 59 or ss < 0 or ss > 59 = 0 - 1
            | otherwise = ((x509 days from civil yr mm dd) * 86400) + (hh * 3600) + (mi * 60) + ss
          t_u
        | tag == 24 and (str len s) >= 14 =
          y_hi = x509 parse dec2 s 0
          y_lo = x509 parse dec2 s 2
          mm   = x509 parse dec2 s 4
          dd   = x509 parse dec2 s 6
          hh   = x509 parse dec2 s 8
          mi   = x509 parse dec2 s 10
          ss   = x509 parse dec2 s 12
          yr   = (y_hi * 100) + y_lo
          t_g  =
            | y_hi < 0 or y_lo < 0 or mm < 1 or mm > 12 or dd < 1 or dd > 31 or hh < 0 or hh > 23 or mi < 0 or mi > 59 or ss < 0 or ss > 59 = 0 - 1
            | otherwise = ((x509 days from civil yr mm dd) * 86400) + (hh * 3600) + (mi * 60) + ss
          t_g
        | otherwise = 0 - 1

fn :: x509 parse validity inner Bool Int Int Int Int Int Int String => Int Int
      x509 parse validity inner False _ _ _ _ _ _ _ = (0 - 1, 0 - 1)
      x509 parse validity inner True t1 vs1 vl1 t2 vs2 vl2 der =
        nb = x509 parse time tag t1 (byte slice der vs1 (vs1 + vl1))
        na = x509 parse time tag t2 (byte slice der vs2 (vs2 + vl2))
        (nb, na)

fn :: x509 parse validity String Int Int => Int Int
      x509 parse validity der vs vlen =
        ok1, t1, vs1, vl1, next1 = asn1 parse tlv der vs
        ok2, t2, vs2, vl2, _     = asn1 parse tlv der next1
        x509 parse validity inner (ok1 and ok2 and (next1 <= (vs + vlen))) t1 vs1 vl1 t2 vs2 vl2 der

fn :: x509 check cn attr Bool String Int Int Int => String
      x509 check cn attr False _ _ _ _ = ""
      x509 check cn attr True der a_vs a_vlen end_pos =
        ok_o, tag_o, o_vs, o_vlen, o_next = asn1 parse tlv der a_vs
        ok_v, _, v_vs, v_vlen, _          = asn1 parse tlv der o_next
        oid_hex = bytes to hex str (byte slice der o_vs (o_vs + o_vlen))
        out     =
          | ok_o and ok_v and (tag_o == 6) and (oid_hex == "550403") and (o_next < (a_vs + a_vlen)) and (end_pos >= 0) =
            str slice der v_vs (v_vs + v_vlen)
          | otherwise = ""
        out

fn :: x509 find cn in rdn String Int Int => String
      x509 find cn in rdn der pos end_pos =
        | pos >= end_pos = ""
        | otherwise      =
          ok_s, _, s_vs, _, s_next = asn1 parse tlv der pos
          ok_a, _, a_vs, a_vlen, _ = asn1 parse tlv der s_vs
          cn_cur = x509 check cn attr (ok_s and ok_a) der a_vs a_vlen end_pos
          out    =
            | not ok_s            = ""
            | (str len cn_cur) > 0 = cn_cur
            | otherwise           = x509 find cn in rdn der s_next end_pos
          out

fn :: x509 parse sig alg oid String String => String
      x509 parse sig alg oid oid_hex params_hex =
        | oid_hex == "2a864886f70d01010b" = "rsa_pkcs1_sha256"
        | oid_hex == "2a864886f70d01010c" = "rsa_pkcs1_sha384"
        | oid_hex == "2a864886f70d01010d" = "rsa_pkcs1_sha512"
        | oid_hex == "2a8648ce3d040302"   = "ecdsa_sha256"
        | oid_hex == "2a8648ce3d040303"   = "ecdsa_sha384"
        | oid_hex == "2a8648ce3d040304"   = "ecdsa_sha512"
        | oid_hex == "2b6570"             = "ed25519"
        | oid_hex == "2a864886f70d01010a" =
          | str contains params_hex "608648016503040202" = "rsa_pss_sha384"
          | str contains params_hex "608648016503040203" = "rsa_pss_sha512"
          | otherwise                                    = "rsa_pss_sha256" |.
        | otherwise = "unknown"

fn :: x509 parse sig alg String Int Int => String
      x509 parse sig alg der vs vlen =
        ok_o, tag_o, o_vs, o_vlen, o_next = asn1 parse tlv der vs
        oid_hex    = bytes to hex str (byte slice der o_vs (o_vs + o_vlen))
        params_hex = bytes to hex str (byte slice der o_next (vs + vlen))
        out        =
          | (not ok_o) or (tag_o != 6) = "unknown"
          | otherwise                  = x509 parse sig alg oid oid_hex params_hex
        out

fn :: x509 parse rsa spki String => String String String
      x509 parse rsa spki pk_raw =
        ok_rs, _, rs_vs, _, _           = asn1 parse tlv pk_raw 0
        ok_n, tag_n, n_vs, n_vlen, n_nx = asn1 parse tlv pk_raw rs_vs
        ok_e, tag_e, e_vs, e_vlen, _    = asn1 parse tlv pk_raw n_nx
        ok_all  = ok_rs and ok_n and ok_e and (tag_n == 2) and (tag_e == 2)
        n_clean = bn strip leading zeroes (byte slice pk_raw n_vs (n_vs + n_vlen)) 0 n_vlen
        e_clean = bn strip leading zeroes (byte slice pk_raw e_vs (e_vs + e_vlen)) 0 e_vlen
        alg_s   =
          | ok_all    = "rsa"
          | otherwise = "unknown"
        n_out   =
          | ok_all    = n_clean
          | otherwise = ""
        e_out   =
          | ok_all    = e_clean
          | otherwise = ""
        (alg_s, n_out, e_out)

fn :: x509 parse ec spki String Int String => String String String
      x509 parse ec spki der o_next pk_raw =
        ok_c, tag_c, c_vs, c_vlen, _ = asn1 parse tlv der o_next
        crv_hex =
          | ok_c and (tag_c == 6) = bytes to hex str (byte slice der c_vs (c_vs + c_vlen))
          | otherwise             = ""
        alg_s   =
          | crv_hex == "2a8648ce3d030107" = "ec_p256"
          | crv_hex == "2b81040022"       = "ec_p384"
          | otherwise                     = "ec_unknown"
        (alg_s, pk_raw, "")

fn :: x509 dispatch spki oid String String Int String => String String String
      x509 dispatch spki oid oid_hex der o_next pk_raw =
        | oid_hex == "2a864886f70d010101" or oid_hex == "2a864886f70d01010a" = x509 parse rsa spki pk_raw
        | oid_hex == "2a8648ce3d0201" = x509 parse ec spki der o_next pk_raw
        | oid_hex == "2b6570"         = ("ed25519", pk_raw, "")
        | otherwise                   = ("unknown", "", "")

fn :: x509 parse spki inner Bool String Int Int Int => String String String
      x509 parse spki inner False _ _ _ _ = ("unknown", "", "")
      x509 parse spki inner True der a_vs b_vs b_vlen =
        ok_o, tag_o, o_vs, o_vlen, o_next = asn1 parse tlv der a_vs
        oid_hex =
          | ok_o and (tag_o == 6) = bytes to hex str (byte slice der o_vs (o_vs + o_vlen))
          | otherwise             = "unknown"
        pk_raw  = byte slice der (b_vs + 1) (b_vs + b_vlen)
        x509 dispatch spki oid oid_hex der o_next pk_raw

fn :: x509 parse spki String Int Int => String String String
      x509 parse spki der vs vlen =
        ok_a, _, a_vs, _, a_next     = asn1 parse tlv der vs
        ok_b, tag_b, b_vs, b_vlen, _ = asn1 parse tlv der a_next
        ok_all = ok_a and ok_b and (tag_b == 3) and (b_vlen >= 2) and (a_next <= (vs + vlen))
        x509 parse spki inner ok_all der a_vs b_vs b_vlen

fn :: x509 parse san entry Bool Int Int Int Int String Int [String] => [String]
      x509 parse san entry False _ _ _ _ _ _ acc = acc
      x509 parse san entry True tag_g g_vs g_vlen g_next der end_pos acc =
        | tag_g == 130 =
          dns = str slice der g_vs (g_vs + g_vlen)
          x509 parse san loop der g_next end_pos (acc :: [dns])
        | tag_g == 135 and g_vlen == 4 =
          ip = (int to str (norm byte (str char at der g_vs))) + "." + (int to str (norm byte (str char at der (g_vs + 1)))) + "." + (int to str (norm byte (str char at der (g_vs + 2)))) + "." + (int to str (norm byte (str char at der (g_vs + 3))))
          x509 parse san loop der g_next end_pos (acc :: [ip])
        | otherwise =
          x509 parse san loop der g_next end_pos acc

fn :: x509 parse san loop String Int Int [String] => [String]
      x509 parse san loop der pos end_pos acc =
        | pos >= end_pos = acc
        | otherwise      =
          ok_g, tag_g, g_vs, g_vlen, g_next = asn1 parse tlv der pos
          x509 parse san entry ok_g tag_g g_vs g_vlen g_next der end_pos acc

fn :: x509 ext octet span String Bool Int Int Int Int => Int Int
      x509 ext octet span der ok_nx tag_nx nx_vs nx_vlen nx_next =
        | ok_nx and (tag_nx == 1) =
          _, _, v_vs, v_vlen, _ = asn1 parse tlv der nx_next
          (v_vs, v_vlen)
        | otherwise = (nx_vs, nx_vlen)

fn :: x509 dispatch ext oid String String Int Int [String] Bool Int Bool => [String] Bool Int Bool
      x509 dispatch ext oid oid_hex der oct_vs oct_vlen san_acc is_ca_acc ku_acc sa_acc =
        | oid_hex == "551d11" =
          ok_sq, _, sq_vs, sq_vlen, _ = asn1 parse tlv der oct_vs
          san_next =
            | not ok_sq = san_acc
            | otherwise = x509 parse san loop der sq_vs (sq_vs + sq_vlen) san_acc
          (san_next, is_ca_acc, ku_acc, sa_acc)
        | oid_hex == "551d13" =
          ok_bc, _, bc_vs, bc_vlen, _  = asn1 parse tlv der oct_vs
          ok_b, tag_b, b_vs, b_vlen, _ = asn1 parse tlv der bc_vs
          ca_flag = ok_bc and (bc_vlen > 0) and ok_b and (tag_b == 1) and (b_vlen >= 1) and ((norm byte (str char at der b_vs)) != 0)
          (san_acc, is_ca_acc or ca_flag, ku_acc, sa_acc)
        | oid_hex == "551d0f" =
          ok_ku, tag_ku, ku_vs, ku_vlen, _ = asn1 parse tlv der oct_vs
          ku_next =
            | (not ok_ku) or (tag_ku != 3) or (ku_vlen < 2) = ku_acc
            | otherwise = norm byte (str char at der (ku_vs + 1))
          (san_acc, is_ca_acc, ku_next, sa_acc)
        | oid_hex == "551d25" =
          eku_hex = bytes to hex str (byte slice der oct_vs (oct_vs + oct_vlen))
          has_sa  = (str contains eku_hex "2b06010505070301") or (str contains eku_hex "551d2500")
          (san_acc, is_ca_acc, ku_acc, has_sa)
        | otherwise = (san_acc, is_ca_acc, ku_acc, sa_acc)

fn :: x509 parse single ext inner Bool String Int Int Int [String] Bool Int Bool => [String] Bool Int Bool
      x509 parse single ext inner False _ _ _ _ san_acc is_ca_acc ku_acc sa_acc = (san_acc, is_ca_acc, ku_acc, sa_acc)
      x509 parse single ext inner True der o_vs o_vlen o_next san_acc is_ca_acc ku_acc sa_acc =
        oid_hex = bytes to hex str (byte slice der o_vs (o_vs + o_vlen))
        ok_nx, tag_nx, nx_vs, nx_vlen, nx_next = asn1 parse tlv der o_next
        oct_vs, oct_vlen = x509 ext octet span der ok_nx tag_nx nx_vs nx_vlen nx_next
        x509 dispatch ext oid oid_hex der oct_vs oct_vlen san_acc is_ca_acc ku_acc sa_acc

fn :: x509 parse single ext String Int Int [String] Bool Int Bool => [String] Bool Int Bool
      x509 parse single ext der vs vlen san_acc is_ca_acc ku_acc sa_acc =
        end_e = vs + vlen
        ok_o, tag_o, o_vs, o_vlen, o_next = asn1 parse tlv der vs
        x509 parse single ext inner (ok_o and (tag_o == 6) and (o_next < end_e)) der o_vs o_vlen o_next san_acc is_ca_acc ku_acc sa_acc

fn :: x509 parse exts step Bool String Int Int Int Int [String] Bool Int Bool => [String] Bool Int Bool
      x509 parse exts step False _ _ _ _ _ san_acc is_ca_acc ku_acc sa_acc = (san_acc, is_ca_acc, ku_acc, sa_acc)
      x509 parse exts step True der e_vs e_vlen e_next end_pos san_acc is_ca_acc ku_acc sa_acc =
        n_san, n_ca, n_ku, n_sa = x509 parse single ext der e_vs e_vlen san_acc is_ca_acc ku_acc sa_acc
        x509 parse exts loop der e_next end_pos n_san n_ca n_ku n_sa

fn :: x509 parse exts loop String Int Int [String] Bool Int Bool => [String] Bool Int Bool
      x509 parse exts loop der pos end_pos san_acc is_ca_acc ku_acc sa_acc =
        | pos >= end_pos = (san_acc, is_ca_acc, ku_acc, sa_acc)
        | otherwise      =
          ok_e, _, e_vs, e_vlen, e_next = asn1 parse tlv der pos
          x509 parse exts step ok_e der e_vs e_vlen e_next end_pos san_acc is_ca_acc ku_acc sa_acc

fn :: x509 find exts step Bool Int Int Int String Int => [String] Bool Int Bool
      x509 find exts step False _ _ _ _ _ = ([], False, 0, True)
      x509 find exts step True tag_t t_vs t_next der end_pos =
        | tag_t == 163 =
          ok_sq, _, sq_vs, sq_vlen, _ = asn1 parse tlv der t_vs
          x509 parse exts step ok_sq der 0 0 sq_vs (sq_vs + sq_vlen) [] False 0 True
        | otherwise = x509 find exts in tbs der t_next end_pos

fn :: x509 find exts in tbs String Int Int => [String] Bool Int Bool
      x509 find exts in tbs der pos end_pos =
        | pos >= end_pos = ([], False, 0, True)
        | otherwise      =
          ok_t, tag_t, t_vs, _, t_next = asn1 parse tlv der pos
          x509 find exts step ok_t tag_t t_vs t_next der end_pos

fn :: x509 empty cert => X509Cert
      x509 empty cert =
        X509Cert "" "" "" "" "" 0 0 "unknown" "" "" "unknown" "" [] False 0 False

fn :: x509 parse cert tbs Bool String Int Int Int Int Int Int Int => Bool X509Cert
      x509 parse cert tbs False _ _ _ _ _ _ _ _ = (False, x509 empty cert)
      x509 parse cert tbs True cert_der c_vs tbs_vs tbs_vlen tbs_next alg_vs alg_vlen sig_vs =
        _, _, _, sig_vlen, _ = asn1 parse tlv cert_der (alg_vs + alg_vlen)
        tbs_raw = byte slice cert_der c_vs tbs_next
        sig_alg = x509 parse sig alg cert_der alg_vs alg_vlen
        sig_raw = byte slice cert_der (sig_vs + 1) (sig_vs + sig_vlen)
        ok_f0, tag_f0, _, _, f0_next = asn1 parse tlv cert_der tbs_vs
        ser_pos =
          | ok_f0 and (tag_f0 == 160) = f0_next
          | otherwise                 = tbs_vs
        ok_ser, _, _, _, ser_next               = asn1 parse tlv cert_der ser_pos
        ok_ta, _, _, _, ta_next                 = asn1 parse tlv cert_der ser_next
        ok_iss, _, iss_vs, iss_vlen, iss_next   = asn1 parse tlv cert_der ta_next
        ok_val, _, val_vs, val_vlen, val_next   = asn1 parse tlv cert_der iss_next
        ok_sub, _, sub_vs, sub_vlen, sub_next   = asn1 parse tlv cert_der val_next
        ok_spk, _, spk_vs, spk_vlen, spk_next   = asn1 parse tlv cert_der sub_next
        ok_all = ok_ser and ok_ta and ok_iss and ok_val and ok_sub and ok_spk
        iss_der            = byte slice cert_der ta_next iss_next
        sub_der            = byte slice cert_der val_next sub_next
        iss_cn             = x509 find cn in rdn cert_der iss_vs (iss_vs + iss_vlen)
        sub_cn             = x509 find cn in rdn cert_der sub_vs (sub_vs + sub_vlen)
        nb, na             = x509 parse validity cert_der val_vs val_vlen
        k_alg, pk_b, exp_b = x509 parse spki cert_der spk_vs spk_vlen
        sans, is_ca, ku, sa = x509 find exts in tbs cert_der spk_next (tbs_vs + tbs_vlen)
        sans_final         =
          | (c str list len sans 0) > 0 = sans
          | (str len sub_cn) > 0        = [sub_cn]
          | otherwise                   = []
        cert_obj = X509Cert tbs_raw iss_der sub_der iss_cn sub_cn nb na k_alg pk_b exp_b sig_alg sig_raw sans_final is_ca ku sa
        res_ok   =
          | ok_all    = True
          | otherwise = False
        res_cert =
          | ok_all    = cert_obj
          | otherwise = x509 empty cert
        (res_ok, res_cert)

fn :: x509 parse cert outer Bool String Int => Bool X509Cert
      x509 parse cert outer False _ _ = (False, x509 empty cert)
      x509 parse cert outer True cert_der c_vs =
        ok_tbs, tag_tbs, tbs_vs, tbs_vlen, tbs_next = asn1 parse tlv cert_der c_vs
        ok_alg, tag_alg, alg_vs, alg_vlen, alg_next = asn1 parse tlv cert_der tbs_next
        ok_sig, tag_sig, sig_vs, sig_vlen, _        = asn1 parse tlv cert_der alg_next
        ok_top = ok_tbs and ok_alg and ok_sig and (tag_tbs == 48) and (tag_alg == 48) and (tag_sig == 3) and (sig_vlen >= 2)
        x509 parse cert tbs ok_top cert_der c_vs tbs_vs tbs_vlen tbs_next alg_vs alg_vlen sig_vs

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-INPUT-001
fn :: x509 parse cert String   => Bool X509Cert
      x509 parse cert cert_der =
        ok_c, tag_c, c_vs, _, _ = asn1 parse tlv cert_der 0
        x509 parse cert outer (ok_c and (tag_c == 48)) cert_der c_vs

fn :: x509 ascii lower char Int => String
      x509 ascii lower char c   =
        | c >= 65 and c <= 90 = char from code (c + 32)
        | otherwise           = byte str c

fn :: x509 to lower loop String Int Int String => String
      x509 to lower loop s idx slen acc =
        | idx >= slen = acc
        | otherwise   =
          ch = norm byte (str char at s idx)
          x509 to lower loop s (idx + 1) slen (acc + (x509 ascii lower char ch))

fn :: x509 to lower String => String
      x509 to lower s      =  x509 to lower loop s 0 (str len s) ""

fn :: x509 count dots loop String Int Int Int => Int
      x509 count dots loop s idx slen cnt =
        | idx >= slen                         = cnt
        | (norm byte (str char at s idx)) == 46 = x509 count dots loop s (idx + 1) slen (cnt + 1)
        | otherwise                           = x509 count dots loop s (idx + 1) slen cnt

fn :: x509 first dot String Int Int => Int
      x509 first dot s idx slen =
        | idx >= slen                         = 0 - 1
        | (norm byte (str char at s idx)) == 46 = idx
        | otherwise                           = x509 first dot s (idx + 1) slen

fn :: x509 match single san inner String String => Bool
      x509 match single san inner lpat lhost =
        | lpat == lhost = True
        | not (c starts with lpat "*.") = False
        | otherwise =
          suffix  = str slice lpat 1 (str len lpat)
          dot_idx = x509 first dot lhost 0 (str len lhost)
          ok_w    =
            | (x509 count dots loop suffix 0 (str len suffix) 0) < 2 = False
            | (str contains (str slice lpat 2 (str len lpat)) "*")   = False
            | dot_idx <= 0                                           = False
            | otherwise = (str slice lhost dot_idx (str len lhost)) == suffix
          ok_w

fn :: x509 match single san String String => Bool
      x509 match single san pat    host   =
        x509 match single san inner (x509 to lower pat) (x509 to lower host)

fn :: x509 match san list [String] String => Bool
      x509 match san list [] _ = False
      x509 match san list (p:rest) host =
        | x509 match single san p host = True
        | otherwise                    = x509 match san list rest host

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: x509 match hostname X509Cert String => Bool
      x509 match hostname cert     host   =
        | (str len host) == 0 = False
        | otherwise           = x509 match san list (san_dns cert) host

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: x509 verify signature String String String String String String => Bool
      x509 verify signature k_alg pk_b exp_b s_alg msg sig =
        | k_alg == "rsa" =
          | s_alg == "rsa_pkcs1_sha256" = rsa verify pkcs1 pk_b exp_b "sha256" msg sig
          | s_alg == "rsa_pkcs1_sha384" = rsa verify pkcs1 pk_b exp_b "sha384" msg sig
          | s_alg == "rsa_pkcs1_sha512" = rsa verify pkcs1 pk_b exp_b "sha512" msg sig
          | s_alg == "rsa_pss_sha256"   = rsa verify pss pk_b exp_b "sha256" msg sig
          | s_alg == "rsa_pss_sha384"   = rsa verify pss pk_b exp_b "sha384" msg sig
          | s_alg == "rsa_pss_sha512"   = rsa verify pss pk_b exp_b "sha512" msg sig
          | otherwise                   = False |.
        | k_alg == "ec_p256" =
          | s_alg == "ecdsa_sha256" = ecdsa p256 verify pk_b (sha256 bytes msg) sig
          | s_alg == "ecdsa_sha384" = ecdsa p256 verify pk_b (sha384 bytes msg) sig
          | s_alg == "ecdsa_sha512" = ecdsa p256 verify pk_b (sha512 bytes msg) sig
          | otherwise               = False |.
        | k_alg == "ec_p384" =
          | s_alg == "ecdsa_sha384" = ecdsa p384 verify pk_b (sha384 bytes msg) sig
          | s_alg == "ecdsa_sha256" = ecdsa p384 verify pk_b ((c repeat byte 0 16) + (sha256 bytes msg)) sig
          | s_alg == "ecdsa_sha512" = ecdsa p384 verify pk_b (sha512 bytes msg) sig
          | otherwise               = False |.
        | k_alg == "ed25519" and s_alg == "ed25519" =
          ed25519 verify pk_b msg sig
        | otherwise = False

-- @implements FR-CRYPTO-006
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: x509 verify cert sig X509Cert X509Cert => Bool
      x509 verify cert sig child    issuer   =
        | (issuer_der child) != (subject_der issuer) = False
        | otherwise =
          x509 verify signature (key_alg issuer) (pubkey_bytes issuer) (rsa_exp_bytes issuer) (sig_alg child) (tbs_der child) (sig_bytes child)
