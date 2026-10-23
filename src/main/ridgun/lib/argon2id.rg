-- src/main/ridgun/lib/argon2id.rg
-- Pure-Ridgun RFC 9106 Argon2id Password Hashing, Key Derivation & PHC Verification Library
-- @implements FR-CRYPTO-001
-- @implements FR-CRYPTO-002
-- @implements FR-CRYPTO-004
-- @implements NFR-PERF-001
-- @implements API-CRYPTO-001
-- @implements DM-Argon2
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001

type Argon2Params = m_cost: Int, t_cost: Int, lanes: Int, tag_len: Int, version: Int
type Argon2Phc    = params: Argon2Params, salt_b64: String, tag_b64: String
type Argon2Res    = Argon2Ok String | Argon2Err String
type Argon2KeyRes = Argon2KeyOk [Int] | Argon2KeyErr String
type Argon2PhcRes = Argon2PhcOk Argon2Phc | Argon2PhcErr String

type A2U64   = a2_lo: Int, a2_hi: Int
type A2G4    = a2_ga: A2U64, a2_gb: A2U64, a2_gc: A2U64, a2_gd: A2U64
type A2W16   = w0: A2U64, w1: A2U64, w2: A2U64, w3: A2U64, w4: A2U64, w5: A2U64, w6: A2U64, w7: A2U64, w8: A2U64, w9: A2U64, w10: A2U64, w11: A2U64, w12: A2U64, w13: A2U64, w14: A2U64, w15: A2U64
type A2Blk8  = r0: A2W16, r1: A2W16, r2: A2W16, r3: A2W16, r4: A2W16, r5: A2W16, r6: A2W16, r7: A2W16
type A2M16   = mb0: A2Blk8, mb1: A2Blk8, mb2: A2Blk8, mb3: A2Blk8, mb4: A2Blk8, mb5: A2Blk8, mb6: A2Blk8, mb7: A2Blk8, mb8: A2Blk8, mb9: A2Blk8, mb10: A2Blk8, mb11: A2Blk8, mb12: A2Blk8, mb13: A2Blk8, mb14: A2Blk8, mb15: A2Blk8
type A2M256  = mr0: A2M16, mr1: A2M16, mr2: A2M16, mr3: A2M16, mr4: A2M16, mr5: A2M16, mr6: A2M16, mr7: A2M16, mr8: A2M16, mr9: A2M16, mr10: A2M16, mr11: A2M16, mr12: A2M16, mr13: A2M16, mr14: A2M16, mr15: A2M16
type A2M4096 = mp0: A2M256, mp1: A2M256, mp2: A2M256, mp3: A2M256, mp4: A2M256, mp5: A2M256, mp6: A2M256, mp7: A2M256, mp8: A2M256, mp9: A2M256, mp10: A2M256, mp11: A2M256, mp12: A2M256, mp13: A2M256, mp14: A2M256, mp15: A2M256
type A2Mem   = mt0: A2M4096, mt1: A2M4096, mt2: A2M4096, mt3: A2M4096, mt4: A2M4096, mt5: A2M4096, mt6: A2M4096, mt7: A2M4096, mt8: A2M4096, mt9: A2M4096, mt10: A2M4096, mt11: A2M4096, mt12: A2M4096, mt13: A2M4096, mt14: A2M4096, mt15: A2M4096
type A2Ctx   = r_pass: Int, s_slice: Int, l_lane: Int, p_lanes: Int, q_cols: Int, seg_len: Int, t_iters: Int

-- ============================================================
-- List, String & 32/64-bit Modular Arithmetic Helpers (Internal)
-- ============================================================

fn :: a2 list len [Int]    => Int
      a2 list len []       =  0
      a2 list len (_:rest) =  1 + (a2 list len rest)

fn :: a2 str list len [String] => Int
      a2 str list len []       =  0
      a2 str list len (_:rest) =  1 + (a2 str list len rest)

fn :: a2 nth int [Int]    Int => Int
      a2 nth int []       _   =  0
      a2 nth int (x:rest) idx =
        | idx <= 0  = x
        | otherwise = a2 nth int rest (idx - 1)

fn :: a2 nth str [String] Int => String
      a2 nth str []       _   =  ""
      a2 nth str (x:rest) idx =
        | idx <= 0  = x
        | otherwise = a2 nth str rest (idx - 1)

fn :: a2 take ints [Int]    Int => [Int]
      a2 take ints []       _   =  []
      a2 take ints (x:rest) n   =
        | n <= 0    = []
        | otherwise = [x] :: (a2 take ints rest (n - 1))

fn :: a2 drop ints [Int]    Int => [Int]
      a2 drop ints []       _   =  []
      a2 drop ints (x:rest) n   =
        | n <= 0    = [x] :: rest
        | otherwise = a2 drop ints rest (n - 1)

fn :: a2 pad zeroes Int => [Int]
      a2 pad zeroes n   =
        | n <= 0    = []
        | otherwise = [0] :: (a2 pad zeroes (n - 1))

fn :: a2 raw byte ub Int => String
      a2 raw byte ub ub  =
        | ub >= 1 and ub <= 127 = char from code ub
        | otherwise             =
          efd = sys call 290 (256 + ub) 526336 0 0 0 0
          s   = sys read fd efd 8
          _   = sys close efd
          str slice s 0 1

fn :: a2 raw byte Int => String
      a2 raw byte b   =  a2 raw byte ub (((b % 256) + 256) % 256)

fn :: a2 str to bytes loop String Int Int => [Int]
      a2 str to bytes loop s idx len =
        | idx >= len = []
        | otherwise  = [(((str char at s idx) % 256) + 256) % 256] :: (a2 str to bytes loop s (idx + 1) len)

fn :: a2 str to bytes String => [Int]
      a2 str to bytes s      =  a2 str to bytes loop s 0 (str len s)

fn :: a2 bytes to str [Int]    => String
      a2 bytes to str []       =  ""
      a2 bytes to str (b:rest) =  (a2 raw byte b) + (a2 bytes to str rest)

fn :: hex digits => String
      hex digits =  "0123456789abcdef"

fn :: byte to hex Int => String
      byte to hex b   =
        ub = b % 256
        hi = (ub / 16) % 16
        lo = ub % 16
        (str slice (hex digits) hi (hi + 1)) + (str slice (hex digits) lo (lo + 1))

fn :: bytes to hex [Int]    => String
      bytes to hex []       =  ""
      bytes to hex (b:rest) =  (byte to hex b) + (bytes to hex rest)

fn :: a2 bitxor2 Int Int => Int
      a2 bitxor2 a   b   =
        | a == b    = 0
        | a == 0    = b
        | b == 0    = a
        | otherwise = 6 - a - b

fn :: a2 bitxor4 Int Int => Int
      a2 bitxor4 a   b   =
        | a == b    = 0
        | a == 0    = b
        | b == 0    = a
        | otherwise = (a2 bitxor2 (a % 4) (b % 4)) + ((a2 bitxor2 (a / 4) (b / 4)) * 4)

fn :: byte bitxor Int Int => Int
      byte bitxor a   b   =
        ua = ((a % 256) + 256) % 256
        ub = ((b % 256) + 256) % 256
        (a2 bitxor4 (ua % 16) (ub % 16)) + ((a2 bitxor4 (ua / 16) (ub / 16)) * 16)

fn :: u32 norm mod Int => Int
      u32 norm mod m   =
        | m < 0     = m + 4294967296
        | otherwise = m

fn :: u32 norm Int => Int
      u32 norm x   =  u32 norm mod (x % 4294967296)

fn :: u32 add Int Int => Int
      u32 add a   b   =  u32 norm (a + b)

fn :: u32 bitxor Int Int => Int
      u32 bitxor a   b   =
        | a == b    = 0
        | a == 0    = b
        | b == 0    = a
        | otherwise =
          (a2 bitxor4 (a % 16) (b % 16)) + ((a2 bitxor4 ((a / 16) % 16) ((b / 16) % 16)) * 16) + ((a2 bitxor4 ((a / 256) % 16) ((b / 256) % 16)) * 256) + ((a2 bitxor4 ((a / 4096) % 16) ((b / 4096) % 16)) * 4096) + ((a2 bitxor4 ((a / 65536) % 16) ((b / 65536) % 16)) * 65536) + ((a2 bitxor4 ((a / 1048576) % 16) ((b / 1048576) % 16)) * 1048576) + ((a2 bitxor4 ((a / 16777216) % 16) ((b / 16777216) % 16)) * 16777216) + ((a2 bitxor4 (a / 268435456) (b / 268435456)) * 268435456)

fn :: a2 u64 add A2U64 A2U64 => A2U64
      a2 u64 add a     b     =
        s0 = (a2_lo a) + (a2_lo b)
        nl = s0 % 4294967296
        cy = s0 / 4294967296
        nh = ((a2_hi a) + (a2_hi b) + cy) % 4294967296
        A2U64 nl nh

fn :: a2 u64 bitxor A2U64 A2U64 => A2U64
      a2 u64 bitxor a     b     =
        A2U64 (u32 bitxor (a2_lo a) (a2_lo b)) (u32 bitxor (a2_hi a) (a2_hi b))

fn :: a2 u64 rotr32 A2U64 => A2U64
      a2 u64 rotr32 x     =  A2U64 (a2_hi x) (a2_lo x)

fn :: a2 u64 rotr24 A2U64 => A2U64
      a2 u64 rotr24 x     =
        xl = a2_lo x
        xh = a2_hi x
        A2U64 ((xl / 16777216) + ((xh % 16777216) * 256)) ((xh / 16777216) + ((xl % 16777216) * 256))

fn :: a2 u64 rotr16 A2U64 => A2U64
      a2 u64 rotr16 x     =
        xl = a2_lo x
        xh = a2_hi x
        A2U64 ((xl / 65536) + ((xh % 65536) * 65536)) ((xh / 65536) + ((xl % 65536) * 65536))

fn :: a2 u64 rotr63 A2U64 => A2U64
      a2 u64 rotr63 x     =
        xl = a2_lo x
        xh = a2_hi x
        A2U64 (((xl % 2147483648) * 2) + (xh / 2147483648)) (((xh % 2147483648) * 2) + (xl / 2147483648))

fn :: a2 mul32 u64 Int Int => A2U64
      a2 mul32 u64 x   y   =
        x0 = x % 65536
        x1 = x / 65536
        y0 = y % 65536
        y1 = y / 65536
        p0 = x0 * y0
        p1 = (x0 * y1) + (x1 * y0)
        p2 = x1 * y1
        s0 = p0 + ((p1 % 65536) * 65536)
        nl = s0 % 4294967296
        cy = s0 / 4294967296
        nh = (p2 + (p1 / 65536) + cy) % 4294967296
        A2U64 nl nh

fn :: a2 f blamka A2U64 A2U64 => A2U64
      a2 f blamka x     y     =
        pr  = a2 mul32 u64 (a2_lo x) (a2_lo y)
        two = a2 u64 add pr pr
        a2 u64 add (a2 u64 add x y) two

fn :: a2 u32 to le4 Int => [Int]
      a2 u32 to le4 w   =
        uw = u32 norm w
        [uw % 256, (uw / 256) % 256, (uw / 65536) % 256, (uw / 16777216) % 256]

fn :: a2 bytes to u32 le [Int] Int => Int
      a2 bytes to u32 le bs off =
        (a2 nth int bs off) + ((a2 nth int bs (off + 1)) * 256) + ((a2 nth int bs (off + 2)) * 65536) + ((a2 nth int bs (off + 3)) * 16777216)

-- ============================================================
-- Pure-Ridgun RFC 7693 BLAKE2b-512 & Variable-Length H' (`blake2b_long`)
-- ============================================================

fn :: a2 zero w16 => A2W16
      a2 zero w16 =
        z = A2U64 0 0
        A2W16 z z z z z z z z z z z z z z z z

fn :: a2 zero blk8 => A2Blk8
      a2 zero blk8 =
        zw = a2 zero w16
        A2Blk8 zw zw zw zw zw zw zw zw

fn :: a2 get w16 A2W16 Int => A2U64
      a2 get w16 row   lo  =
        | lo < 8 =
          | lo < 4 =
            | lo == 0   = w0 row
            | lo == 1   = w1 row
            | lo == 2   = w2 row
            | otherwise = w3 row |.
          | otherwise =
            | lo == 4   = w4 row
            | lo == 5   = w5 row
            | lo == 6   = w6 row
            | otherwise = w7 row |.
        | otherwise =
          | lo < 12 =
            | lo == 8   = w8 row
            | lo == 9   = w9 row
            | lo == 10  = w10 row
            | otherwise = w11 row |.
          | otherwise =
            | lo == 12  = w12 row
            | lo == 13  = w13 row
            | lo == 14  = w14 row
            | otherwise = w15 row

fn :: a2 b2b iv w16 => A2W16
      a2 b2b iv w16 =
        z = A2U64 0 0
        A2W16 (A2U64 4089235720 1779033703) (A2U64 2227873595 3144134277) (A2U64 4271175723 1013904242) (A2U64 1595750129 2773480762) (A2U64 2917565137 1359893119) (A2U64 725511199 2600822924) (A2U64 4215389547 528734635) (A2U64 327033209 1541459225) z z z z z z z z

fn :: a2 b2b g4 A2U64 A2U64 A2U64 A2U64 A2U64 A2U64 => A2G4
      a2 b2b g4 a0 b0 c0 d0 mx my =
        va1 = a2 u64 add (a2 u64 add a0 b0) mx
        vd1 = a2 u64 rotr32 (a2 u64 bitxor d0 va1)
        vc1 = a2 u64 add c0 vd1
        vb1 = a2 u64 rotr24 (a2 u64 bitxor b0 vc1)
        va2 = a2 u64 add (a2 u64 add va1 vb1) my
        vd2 = a2 u64 rotr16 (a2 u64 bitxor vd1 va2)
        vc2 = a2 u64 add vc1 vd2
        vb2 = a2 u64 rotr63 (a2 u64 bitxor vb1 vc2)
        A2G4 va2 vb2 vc2 vd2

fn :: a2 b2b sigma Int => [Int]
      a2 b2b sigma r   =
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

fn :: a2 b2b round A2W16 A2W16 Int => A2W16
      a2 b2b round v m r =
        s  = a2 b2b sigma r
        c0 = a2 b2b g4 (w0 v) (w4 v) (w8 v)  (w12 v) (a2 get w16 m (a2 nth int s 0))  (a2 get w16 m (a2 nth int s 1))
        c1 = a2 b2b g4 (w1 v) (w5 v) (w9 v)  (w13 v) (a2 get w16 m (a2 nth int s 2))  (a2 get w16 m (a2 nth int s 3))
        c2 = a2 b2b g4 (w2 v) (w6 v) (w10 v) (w14 v) (a2 get w16 m (a2 nth int s 4))  (a2 get w16 m (a2 nth int s 5))
        c3 = a2 b2b g4 (w3 v) (w7 v) (w11 v) (w15 v) (a2 get w16 m (a2 nth int s 6))  (a2 get w16 m (a2 nth int s 7))
        d0 = a2 b2b g4 (a2_ga c0) (a2_gb c1) (a2_gc c2) (a2_gd c3) (a2 get w16 m (a2 nth int s 8))  (a2 get w16 m (a2 nth int s 9))
        d1 = a2 b2b g4 (a2_ga c1) (a2_gb c2) (a2_gc c3) (a2_gd c0) (a2 get w16 m (a2 nth int s 10)) (a2 get w16 m (a2 nth int s 11))
        d2 = a2 b2b g4 (a2_ga c2) (a2_gb c3) (a2_gc c0) (a2_gd c1) (a2 get w16 m (a2 nth int s 12)) (a2 get w16 m (a2 nth int s 13))
        d3 = a2 b2b g4 (a2_ga c3) (a2_gb c0) (a2_gc c1) (a2_gd c2) (a2 get w16 m (a2 nth int s 14)) (a2 get w16 m (a2 nth int s 15))
        A2W16 (a2_ga d0) (a2_ga d1) (a2_ga d2) (a2_ga d3) (a2_gb d3) (a2_gb d0) (a2_gb d1) (a2_gb d2) (a2_gc d2) (a2_gc d3) (a2_gc d0) (a2_gc d1) (a2_gd d1) (a2_gd d2) (a2_gd d3) (a2_gd d0)

fn :: a2 b2b rounds A2W16 A2W16 Int => A2W16
      a2 b2b rounds v m r =
        | r >= 12   = v
        | otherwise = a2 b2b rounds (a2 b2b round v m r) m (r + 1)

fn :: a2 b2b compress A2W16 A2W16 Int Bool => A2W16
      a2 b2b compress h m t is_last =
        iv  = a2 b2b iv w16
        v12 = a2 u64 bitxor (w4 iv) (A2U64 t 0)
        v14 =
          | is_last   = a2 u64 bitxor (w6 iv) (A2U64 4294967295 4294967295)
          | otherwise = w6 iv
        v0  = A2W16 (w0 h) (w1 h) (w2 h) (w3 h) (w4 h) (w5 h) (w6 h) (w7 h) (w0 iv) (w1 iv) (w2 iv) (w3 iv) v12 (w5 iv) v14 (w7 iv)
        vf  = a2 b2b rounds v0 m 0
        z   = A2U64 0 0
        A2W16 (a2 u64 bitxor (w0 h) (a2 u64 bitxor (w0 vf) (w8 vf))) (a2 u64 bitxor (w1 h) (a2 u64 bitxor (w1 vf) (w9 vf))) (a2 u64 bitxor (w2 h) (a2 u64 bitxor (w2 vf) (w10 vf))) (a2 u64 bitxor (w3 h) (a2 u64 bitxor (w3 vf) (w11 vf))) (a2 u64 bitxor (w4 h) (a2 u64 bitxor (w4 vf) (w12 vf))) (a2 u64 bitxor (w5 h) (a2 u64 bitxor (w5 vf) (w13 vf))) (a2 u64 bitxor (w6 h) (a2 u64 bitxor (w6 vf) (w14 vf))) (a2 u64 bitxor (w7 h) (a2 u64 bitxor (w7 vf) (w15 vf))) z z z z z z z z

fn :: a2 bytes to u64 [Int] Int => A2U64
      a2 bytes to u64 bs off =
        A2U64 (a2 bytes to u32 le bs off) (a2 bytes to u32 le bs (off + 4))

fn :: a2 bytes to w16 [Int] Int => A2W16
      a2 bytes to w16 bs off =
        A2W16 (a2 bytes to u64 bs off) (a2 bytes to u64 bs (off + 8)) (a2 bytes to u64 bs (off + 16)) (a2 bytes to u64 bs (off + 24)) (a2 bytes to u64 bs (off + 32)) (a2 bytes to u64 bs (off + 40)) (a2 bytes to u64 bs (off + 48)) (a2 bytes to u64 bs (off + 56)) (a2 bytes to u64 bs (off + 64)) (a2 bytes to u64 bs (off + 72)) (a2 bytes to u64 bs (off + 80)) (a2 bytes to u64 bs (off + 88)) (a2 bytes to u64 bs (off + 96)) (a2 bytes to u64 bs (off + 104)) (a2 bytes to u64 bs (off + 112)) (a2 bytes to u64 bs (off + 120))

fn :: a2 u64 to le8 A2U64 => [Int]
      a2 u64 to le8 x     =
        (a2 u32 to le4 (a2_lo x)) :: (a2 u32 to le4 (a2_hi x))

fn :: a2 h8 to bytes A2W16 => [Int]
      a2 h8 to bytes h     =
        (a2 u64 to le8 (w0 h)) :: (a2 u64 to le8 (w1 h)) :: (a2 u64 to le8 (w2 h)) :: (a2 u64 to le8 (w3 h)) :: (a2 u64 to le8 (w4 h)) :: (a2 u64 to le8 (w5 h)) :: (a2 u64 to le8 (w6 h)) :: (a2 u64 to le8 (w7 h))

fn :: a2 b2b loop A2W16 [Int] Int => A2W16
      a2 b2b loop h rem t =
        | (a2 list len rem) <= 128 =
          rlen   = a2 list len rem
          padded = rem :: (a2 pad zeroes (128 - rlen))
          a2 b2b compress h (a2 bytes to w16 padded 0) (t + rlen) True
        | otherwise =
          blk  = a2 take ints rem 128
          rest = a2 drop ints rem 128
          h1   = a2 b2b compress h (a2 bytes to w16 blk 0) (t + 128) False
          a2 b2b loop h1 rest (t + 128)

fn :: a2 blake2b [Int] Int    => [Int]
      a2 blake2b msg   outlen =
        iv   = a2 b2b iv w16
        h0_0 = a2 u64 bitxor (w0 iv) (A2U64 (16842752 + outlen) 0)
        h_in = iv with w0: h0_0
        h_fi = a2 b2b loop h_in msg 0
        a2 take ints (a2 h8 to bytes h_fi) outlen

fn :: a2 b2b long loop [Int] Int Int Int => [Int]
      a2 b2b long loop v idx r outlen =
        | idx > r =
          rem = outlen - (32 * r)
          a2 blake2b v rem
        | otherwise =
          v_next = a2 blake2b v 64
          (a2 take ints v_next 32) :: (a2 b2b long loop v_next (idx + 1) r outlen)

fn :: a2 blake2b long [Int] Int    => [Int]
      a2 blake2b long data  outlen =
        | outlen <= 64 = a2 blake2b ((a2 u32 to le4 outlen) :: data) outlen
        | otherwise =
          r  = ((outlen + 31) / 32) - 2
          v1 = a2 blake2b ((a2 u32 to le4 outlen) :: data) 64
          (a2 take ints v1 32) :: (a2 b2b long loop v1 2 r outlen)

-- ============================================================
-- Pure-Ridgun RFC 9106 v0x13 Argon2id Block Compression & Memory Engine
-- ============================================================

fn :: a2 g4 A2U64 A2U64 A2U64 A2U64 => A2G4
      a2 g4 a0 b0 c0 d0 =
        al0 = a2_lo a0
        ah0 = a2_hi a0
        bl0 = a2_lo b0
        bh0 = a2_hi b0
        cl0 = a2_lo c0
        ch0 = a2_hi c0
        dl0 = a2_lo d0
        dh0 = a2_hi d0
        p1m = ((al0 % 65536) * (bl0 / 65536)) + ((al0 / 65536) * (bl0 % 65536))
        pr1 = ((al0 % 65536) * (bl0 % 65536)) + ((p1m % 65536) * 65536)
        ph1 = ((al0 / 65536) * (bl0 / 65536)) + (p1m / 65536) + (pr1 / 4294967296)
        s1  = al0 + bl0 + ((pr1 % 4294967296) * 2)
        al1 = s1 % 4294967296
        ah1 = (ah0 + bh0 + (ph1 * 2) + (s1 / 4294967296)) % 4294967296
        dl1 = u32 bitxor dh0 ah1
        dh1 = u32 bitxor dl0 al1
        p2m = ((cl0 % 65536) * (dl1 / 65536)) + ((cl0 / 65536) * (dl1 % 65536))
        pr2 = ((cl0 % 65536) * (dl1 % 65536)) + ((p2m % 65536) * 65536)
        ph2 = ((cl0 / 65536) * (dl1 / 65536)) + (p2m / 65536) + (pr2 / 4294967296)
        s2  = cl0 + dl1 + ((pr2 % 4294967296) * 2)
        cl1 = s2 % 4294967296
        ch1 = (ch0 + dh1 + (ph2 * 2) + (s2 / 4294967296)) % 4294967296
        bx1 = u32 bitxor bl0 cl1
        by1 = u32 bitxor bh0 ch1
        bl1 = (bx1 / 16777216) + ((by1 % 16777216) * 256)
        bh1 = (by1 / 16777216) + ((bx1 % 16777216) * 256)
        p3m = ((al1 % 65536) * (bl1 / 65536)) + ((al1 / 65536) * (bl1 % 65536))
        pr3 = ((al1 % 65536) * (bl1 % 65536)) + ((p3m % 65536) * 65536)
        ph3 = ((al1 / 65536) * (bl1 / 65536)) + (p3m / 65536) + (pr3 / 4294967296)
        s3  = al1 + bl1 + ((pr3 % 4294967296) * 2)
        al2 = s3 % 4294967296
        ah2 = (ah1 + bh1 + (ph3 * 2) + (s3 / 4294967296)) % 4294967296
        dx2 = u32 bitxor dl1 al2
        dy2 = u32 bitxor dh1 ah2
        dl2 = (dx2 / 65536) + ((dy2 % 65536) * 65536)
        dh2 = (dy2 / 65536) + ((dx2 % 65536) * 65536)
        p4m = ((cl1 % 65536) * (dl2 / 65536)) + ((cl1 / 65536) * (dl2 % 65536))
        pr4 = ((cl1 % 65536) * (dl2 % 65536)) + ((p4m % 65536) * 65536)
        ph4 = ((cl1 / 65536) * (dl2 / 65536)) + (p4m / 65536) + (pr4 / 4294967296)
        s4  = cl1 + dl2 + ((pr4 % 4294967296) * 2)
        cl2 = s4 % 4294967296
        ch2 = (ch1 + dh2 + (ph4 * 2) + (s4 / 4294967296)) % 4294967296
        bx2 = u32 bitxor bl1 cl2
        by2 = u32 bitxor bh1 ch2
        bl2 = ((bx2 % 2147483648) * 2) + (by2 / 2147483648)
        bh2 = ((by2 % 2147483648) * 2) + (bx2 / 2147483648)
        A2G4 (A2U64 al2 ah2) (A2U64 bl2 bh2) (A2U64 cl2 ch2) (A2U64 dl2 dh2)

fn :: a2 p16 w A2W16 => A2W16
      a2 p16 w v     =
        c0 = a2 g4 (w0 v) (w4 v) (w8 v)  (w12 v)
        c1 = a2 g4 (w1 v) (w5 v) (w9 v)  (w13 v)
        c2 = a2 g4 (w2 v) (w6 v) (w10 v) (w14 v)
        c3 = a2 g4 (w3 v) (w7 v) (w11 v) (w15 v)
        d0 = a2 g4 (a2_ga c0) (a2_gb c1) (a2_gc c2) (a2_gd c3)
        d1 = a2 g4 (a2_ga c1) (a2_gb c2) (a2_gc c3) (a2_gd c0)
        d2 = a2 g4 (a2_ga c2) (a2_gb c3) (a2_gc c0) (a2_gd c1)
        d3 = a2 g4 (a2_ga c3) (a2_gb c0) (a2_gc c1) (a2_gd c2)
        A2W16 (a2_ga d0) (a2_ga d1) (a2_ga d2) (a2_ga d3) (a2_gb d3) (a2_gb d0) (a2_gb d1) (a2_gb d2) (a2_gc d2) (a2_gc d3) (a2_gc d0) (a2_gc d1) (a2_gd d1) (a2_gd d2) (a2_gd d3) (a2_gd d0)

fn :: a2 bitxor w16 A2W16 A2W16 => A2W16
      a2 bitxor w16 a     b     =
        A2W16 (a2 u64 bitxor (w0 a) (w0 b)) (a2 u64 bitxor (w1 a) (w1 b)) (a2 u64 bitxor (w2 a) (w2 b)) (a2 u64 bitxor (w3 a) (w3 b)) (a2 u64 bitxor (w4 a) (w4 b)) (a2 u64 bitxor (w5 a) (w5 b)) (a2 u64 bitxor (w6 a) (w6 b)) (a2 u64 bitxor (w7 a) (w7 b)) (a2 u64 bitxor (w8 a) (w8 b)) (a2 u64 bitxor (w9 a) (w9 b)) (a2 u64 bitxor (w10 a) (w10 b)) (a2 u64 bitxor (w11 a) (w11 b)) (a2 u64 bitxor (w12 a) (w12 b)) (a2 u64 bitxor (w13 a) (w13 b)) (a2 u64 bitxor (w14 a) (w14 b)) (a2 u64 bitxor (w15 a) (w15 b))

fn :: a2 bitxor blk8 A2Blk8 A2Blk8 => A2Blk8
      a2 bitxor blk8 a      b      =
        A2Blk8 (a2 bitxor w16 (r0 a) (r0 b)) (a2 bitxor w16 (r1 a) (r1 b)) (a2 bitxor w16 (r2 a) (r2 b)) (a2 bitxor w16 (r3 a) (r3 b)) (a2 bitxor w16 (r4 a) (r4 b)) (a2 bitxor w16 (r5 a) (r5 b)) (a2 bitxor w16 (r6 a) (r6 b)) (a2 bitxor w16 (r7 a) (r7 b))

fn :: a2 compress blk8 A2Blk8 A2Blk8 => A2Blk8
      a2 compress blk8 x      y      =
        r   = a2 bitxor blk8 x y
        pr0 = a2 p16 w (r0 r)
        pr1 = a2 p16 w (r1 r)
        pr2 = a2 p16 w (r2 r)
        pr3 = a2 p16 w (r3 r)
        pr4 = a2 p16 w (r4 r)
        pr5 = a2 p16 w (r5 r)
        pr6 = a2 p16 w (r6 r)
        pr7 = a2 p16 w (r7 r)
        c0  = a2 p16 w (A2W16 (w0 pr0)  (w1 pr0)  (w0 pr1)  (w1 pr1)  (w0 pr2)  (w1 pr2)  (w0 pr3)  (w1 pr3)  (w0 pr4)  (w1 pr4)  (w0 pr5)  (w1 pr5)  (w0 pr6)  (w1 pr6)  (w0 pr7)  (w1 pr7))
        c1  = a2 p16 w (A2W16 (w2 pr0)  (w3 pr0)  (w2 pr1)  (w3 pr1)  (w2 pr2)  (w3 pr2)  (w2 pr3)  (w3 pr3)  (w2 pr4)  (w3 pr4)  (w2 pr5)  (w3 pr5)  (w2 pr6)  (w3 pr6)  (w2 pr7)  (w3 pr7))
        c2  = a2 p16 w (A2W16 (w4 pr0)  (w5 pr0)  (w4 pr1)  (w5 pr1)  (w4 pr2)  (w5 pr2)  (w4 pr3)  (w5 pr3)  (w4 pr4)  (w5 pr4)  (w4 pr5)  (w5 pr5)  (w4 pr6)  (w5 pr6)  (w4 pr7)  (w5 pr7))
        c3  = a2 p16 w (A2W16 (w6 pr0)  (w7 pr0)  (w6 pr1)  (w7 pr1)  (w6 pr2)  (w7 pr2)  (w6 pr3)  (w7 pr3)  (w6 pr4)  (w7 pr4)  (w6 pr5)  (w7 pr5)  (w6 pr6)  (w7 pr6)  (w6 pr7)  (w7 pr7))
        c4  = a2 p16 w (A2W16 (w8 pr0)  (w9 pr0)  (w8 pr1)  (w9 pr1)  (w8 pr2)  (w9 pr2)  (w8 pr3)  (w9 pr3)  (w8 pr4)  (w9 pr4)  (w8 pr5)  (w9 pr5)  (w8 pr6)  (w9 pr6)  (w8 pr7)  (w9 pr7))
        c5  = a2 p16 w (A2W16 (w10 pr0) (w11 pr0) (w10 pr1) (w11 pr1) (w10 pr2) (w11 pr2) (w10 pr3) (w11 pr3) (w10 pr4) (w11 pr4) (w10 pr5) (w11 pr5) (w10 pr6) (w11 pr6) (w10 pr7) (w11 pr7))
        c6  = a2 p16 w (A2W16 (w12 pr0) (w13 pr0) (w12 pr1) (w13 pr1) (w12 pr2) (w13 pr2) (w12 pr3) (w13 pr3) (w12 pr4) (w13 pr4) (w12 pr5) (w13 pr5) (w12 pr6) (w13 pr6) (w12 pr7) (w13 pr7))
        c7  = a2 p16 w (A2W16 (w14 pr0) (w15 pr0) (w14 pr1) (w15 pr1) (w14 pr2) (w15 pr2) (w14 pr3) (w15 pr3) (w14 pr4) (w15 pr4) (w14 pr5) (w15 pr5) (w14 pr6) (w15 pr6) (w14 pr7) (w15 pr7))
        z0  = A2W16 (w0 c0)  (w1 c0)  (w0 c1)  (w1 c1)  (w0 c2)  (w1 c2)  (w0 c3)  (w1 c3)  (w0 c4)  (w1 c4)  (w0 c5)  (w1 c5)  (w0 c6)  (w1 c6)  (w0 c7)  (w1 c7)
        z1  = A2W16 (w2 c0)  (w3 c0)  (w2 c1)  (w3 c1)  (w2 c2)  (w3 c2)  (w2 c3)  (w3 c3)  (w2 c4)  (w3 c4)  (w2 c5)  (w3 c5)  (w2 c6)  (w3 c6)  (w2 c7)  (w3 c7)
        z2  = A2W16 (w4 c0)  (w5 c0)  (w4 c1)  (w5 c1)  (w4 c2)  (w5 c2)  (w4 c3)  (w5 c3)  (w4 c4)  (w5 c4)  (w4 c5)  (w5 c5)  (w4 c6)  (w5 c6)  (w4 c7)  (w5 c7)
        z3  = A2W16 (w6 c0)  (w7 c0)  (w6 c1)  (w7 c1)  (w6 c2)  (w7 c2)  (w6 c3)  (w7 c3)  (w6 c4)  (w7 c4)  (w6 c5)  (w7 c5)  (w6 c6)  (w7 c6)  (w6 c7)  (w7 c7)
        z4  = A2W16 (w8 c0)  (w9 c0)  (w8 c1)  (w9 c1)  (w8 c2)  (w9 c2)  (w8 c3)  (w9 c3)  (w8 c4)  (w9 c4)  (w8 c5)  (w9 c5)  (w8 c6)  (w9 c6)  (w8 c7)  (w9 c7)
        z5  = A2W16 (w10 c0) (w11 c0) (w10 c1) (w11 c1) (w10 c2) (w11 c2) (w10 c3) (w11 c3) (w10 c4) (w11 c4) (w10 c5) (w11 c5) (w10 c6) (w11 c6) (w10 c7) (w11 c7)
        z6  = A2W16 (w12 c0) (w13 c0) (w12 c1) (w13 c1) (w12 c2) (w13 c2) (w12 c3) (w13 c3) (w12 c4) (w13 c4) (w12 c5) (w13 c5) (w12 c6) (w13 c6) (w12 c7) (w13 c7)
        z7  = A2W16 (w14 c0) (w15 c0) (w14 c1) (w15 c1) (w14 c2) (w15 c2) (w14 c3) (w15 c3) (w14 c4) (w15 c4) (w14 c5) (w15 c5) (w14 c6) (w15 c6) (w14 c7) (w15 c7)
        a2 bitxor blk8 (A2Blk8 z0 z1 z2 z3 z4 z5 z6 z7) r

fn :: a2 get blk8 row A2Blk8 Int Int => A2U64
      a2 get blk8 row blk hi lo =
        | hi < 4 =
          | hi == 0   = a2 get w16 (r0 blk) lo
          | hi == 1   = a2 get w16 (r1 blk) lo
          | hi == 2   = a2 get w16 (r2 blk) lo
          | otherwise = a2 get w16 (r3 blk) lo |.
        | otherwise =
          | hi == 4   = a2 get w16 (r4 blk) lo
          | hi == 5   = a2 get w16 (r5 blk) lo
          | hi == 6   = a2 get w16 (r6 blk) lo
          | otherwise = a2 get w16 (r7 blk) lo

fn :: a2 get blk8 A2Blk8 Int => A2U64
      a2 get blk8 blk    idx =
        a2 get blk8 row blk ((idx / 16) % 8) (idx % 16)

fn :: a2 bytes to blk8 [Int] => A2Blk8
      a2 bytes to blk8 bs    =
        b0 = a2 take ints bs 128
        r1 = a2 drop ints bs 128
        b1 = a2 take ints r1 128
        r2 = a2 drop ints r1 128
        b2 = a2 take ints r2 128
        r3 = a2 drop ints r2 128
        b3 = a2 take ints r3 128
        r4 = a2 drop ints r3 128
        b4 = a2 take ints r4 128
        r5 = a2 drop ints r4 128
        b5 = a2 take ints r5 128
        r6 = a2 drop ints r5 128
        b6 = a2 take ints r6 128
        b7 = a2 drop ints r6 128
        A2Blk8 (a2 bytes to w16 b0 0) (a2 bytes to w16 b1 0) (a2 bytes to w16 b2 0) (a2 bytes to w16 b3 0) (a2 bytes to w16 b4 0) (a2 bytes to w16 b5 0) (a2 bytes to w16 b6 0) (a2 bytes to w16 b7 0)

fn :: a2 w16 to bytes A2W16 => [Int]
      a2 w16 to bytes w     =
        (a2 u64 to le8 (w0 w)) :: (a2 u64 to le8 (w1 w)) :: (a2 u64 to le8 (w2 w)) :: (a2 u64 to le8 (w3 w)) :: (a2 u64 to le8 (w4 w)) :: (a2 u64 to le8 (w5 w)) :: (a2 u64 to le8 (w6 w)) :: (a2 u64 to le8 (w7 w)) :: (a2 u64 to le8 (w8 w)) :: (a2 u64 to le8 (w9 w)) :: (a2 u64 to le8 (w10 w)) :: (a2 u64 to le8 (w11 w)) :: (a2 u64 to le8 (w12 w)) :: (a2 u64 to le8 (w13 w)) :: (a2 u64 to le8 (w14 w)) :: (a2 u64 to le8 (w15 w))

fn :: a2 blk8 to bytes A2Blk8 => [Int]
      a2 blk8 to bytes b      =
        (a2 w16 to bytes (r0 b)) :: (a2 w16 to bytes (r1 b)) :: (a2 w16 to bytes (r2 b)) :: (a2 w16 to bytes (r3 b)) :: (a2 w16 to bytes (r4 b)) :: (a2 w16 to bytes (r5 b)) :: (a2 w16 to bytes (r6 b)) :: (a2 w16 to bytes (r7 b))

fn :: a2 zero mem => A2Mem
      a2 zero mem =
        zb = a2 zero blk8
        m1 = A2M16 zb zb zb zb zb zb zb zb zb zb zb zb zb zb zb zb
        m2 = A2M256 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1
        m3 = A2M4096 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2
        A2Mem m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3

fn :: a2 get m16 A2M16 Int => A2Blk8
      a2 get m16 m     i   =
        | i < 8 =
          | i < 4 =
            | i == 0    = mb0 m
            | i == 1    = mb1 m
            | i == 2    = mb2 m
            | otherwise = mb3 m |.
          | otherwise =
            | i == 4    = mb4 m
            | i == 5    = mb5 m
            | i == 6    = mb6 m
            | otherwise = mb7 m |.
        | otherwise =
          | i < 12 =
            | i == 8    = mb8 m
            | i == 9    = mb9 m
            | i == 10   = mb10 m
            | otherwise = mb11 m |.
          | otherwise =
            | i == 12   = mb12 m
            | i == 13   = mb13 m
            | i == 14   = mb14 m
            | otherwise = mb15 m

fn :: a2 get m256 A2M256 Int Int => A2Blk8
      a2 get m256 m i1 i0 =
        | i1 < 8 =
          | i1 < 4 =
            | i1 == 0   = a2 get m16 (mr0 m) i0
            | i1 == 1   = a2 get m16 (mr1 m) i0
            | i1 == 2   = a2 get m16 (mr2 m) i0
            | otherwise = a2 get m16 (mr3 m) i0 |.
          | otherwise =
            | i1 == 4   = a2 get m16 (mr4 m) i0
            | i1 == 5   = a2 get m16 (mr5 m) i0
            | i1 == 6   = a2 get m16 (mr6 m) i0
            | otherwise = a2 get m16 (mr7 m) i0 |.
        | otherwise =
          | i1 < 12 =
            | i1 == 8   = a2 get m16 (mr8 m) i0
            | i1 == 9   = a2 get m16 (mr9 m) i0
            | i1 == 10  = a2 get m16 (mr10 m) i0
            | otherwise = a2 get m16 (mr11 m) i0 |.
          | otherwise =
            | i1 == 12  = a2 get m16 (mr12 m) i0
            | i1 == 13  = a2 get m16 (mr13 m) i0
            | i1 == 14  = a2 get m16 (mr14 m) i0
            | otherwise = a2 get m16 (mr15 m) i0

fn :: a2 get m4096 A2M4096 Int Int Int => A2Blk8
      a2 get m4096 m i2 i1 i0 =
        | i2 < 8 =
          | i2 < 4 =
            | i2 == 0   = a2 get m256 (mp0 m) i1 i0
            | i2 == 1   = a2 get m256 (mp1 m) i1 i0
            | i2 == 2   = a2 get m256 (mp2 m) i1 i0
            | otherwise = a2 get m256 (mp3 m) i1 i0 |.
          | otherwise =
            | i2 == 4   = a2 get m256 (mp4 m) i1 i0
            | i2 == 5   = a2 get m256 (mp5 m) i1 i0
            | i2 == 6   = a2 get m256 (mp6 m) i1 i0
            | otherwise = a2 get m256 (mp7 m) i1 i0 |.
        | otherwise =
          | i2 < 12 =
            | i2 == 8   = a2 get m256 (mp8 m) i1 i0
            | i2 == 9   = a2 get m256 (mp9 m) i1 i0
            | i2 == 10  = a2 get m256 (mp10 m) i1 i0
            | otherwise = a2 get m256 (mp11 m) i1 i0 |.
          | otherwise =
            | i2 == 12  = a2 get m256 (mp12 m) i1 i0
            | i2 == 13  = a2 get m256 (mp13 m) i1 i0
            | i2 == 14  = a2 get m256 (mp14 m) i1 i0
            | otherwise = a2 get m256 (mp15 m) i1 i0

fn :: a2 get mem A2Mem Int Int Int Int => A2Blk8
      a2 get mem m i3 i2 i1 i0 =
        | i3 < 8 =
          | i3 < 4 =
            | i3 == 0   = a2 get m4096 (mt0 m) i2 i1 i0
            | i3 == 1   = a2 get m4096 (mt1 m) i2 i1 i0
            | i3 == 2   = a2 get m4096 (mt2 m) i2 i1 i0
            | otherwise = a2 get m4096 (mt3 m) i2 i1 i0 |.
          | otherwise =
            | i3 == 4   = a2 get m4096 (mt4 m) i2 i1 i0
            | i3 == 5   = a2 get m4096 (mt5 m) i2 i1 i0
            | i3 == 6   = a2 get m4096 (mt6 m) i2 i1 i0
            | otherwise = a2 get m4096 (mt7 m) i2 i1 i0 |.
        | otherwise =
          | i3 < 12 =
            | i3 == 8   = a2 get m4096 (mt8 m) i2 i1 i0
            | i3 == 9   = a2 get m4096 (mt9 m) i2 i1 i0
            | i3 == 10  = a2 get m4096 (mt10 m) i2 i1 i0
            | otherwise = a2 get m4096 (mt11 m) i2 i1 i0 |.
          | otherwise =
            | i3 == 12  = a2 get m4096 (mt12 m) i2 i1 i0
            | i3 == 13  = a2 get m4096 (mt13 m) i2 i1 i0
            | i3 == 14  = a2 get m4096 (mt14 m) i2 i1 i0
            | otherwise = a2 get m4096 (mt15 m) i2 i1 i0

fn :: a2 nth blk A2Mem Int => A2Blk8
      a2 nth blk m     idx =
        a2 get mem m ((idx / 4096) % 16) ((idx / 256) % 16) ((idx / 16) % 16) (idx % 16)

fn :: a2 set m16 A2M16 Int A2Blk8 => A2M16
      a2 set m16 m i val =
        | i < 8 =
          | i < 4 =
            | i == 0    = m with mb0: val
            | i == 1    = m with mb1: val
            | i == 2    = m with mb2: val
            | otherwise = m with mb3: val |.
          | otherwise =
            | i == 4    = m with mb4: val
            | i == 5    = m with mb5: val
            | i == 6    = m with mb6: val
            | otherwise = m with mb7: val |.
        | otherwise =
          | i < 12 =
            | i == 8    = m with mb8: val
            | i == 9    = m with mb9: val
            | i == 10   = m with mb10: val
            | otherwise = m with mb11: val |.
          | otherwise =
            | i == 12   = m with mb12: val
            | i == 13   = m with mb13: val
            | i == 14   = m with mb14: val
            | otherwise = m with mb15: val

fn :: a2 set m256 A2M256 Int Int A2Blk8 => A2M256
      a2 set m256 m i1 i0 val =
        | i1 < 8 =
          | i1 < 4 =
            | i1 == 0   = m with mr0: (a2 set m16 (mr0 m) i0 val)
            | i1 == 1   = m with mr1: (a2 set m16 (mr1 m) i0 val)
            | i1 == 2   = m with mr2: (a2 set m16 (mr2 m) i0 val)
            | otherwise = m with mr3: (a2 set m16 (mr3 m) i0 val) |.
          | otherwise =
            | i1 == 4   = m with mr4: (a2 set m16 (mr4 m) i0 val)
            | i1 == 5   = m with mr5: (a2 set m16 (mr5 m) i0 val)
            | i1 == 6   = m with mr6: (a2 set m16 (mr6 m) i0 val)
            | otherwise = m with mr7: (a2 set m16 (mr7 m) i0 val) |.
        | otherwise =
          | i1 < 12 =
            | i1 == 8   = m with mr8: (a2 set m16 (mr8 m) i0 val)
            | i1 == 9   = m with mr9: (a2 set m16 (mr9 m) i0 val)
            | i1 == 10  = m with mr10: (a2 set m16 (mr10 m) i0 val)
            | otherwise = m with mr11: (a2 set m16 (mr11 m) i0 val) |.
          | otherwise =
            | i1 == 12  = m with mr12: (a2 set m16 (mr12 m) i0 val)
            | i1 == 13  = m with mr13: (a2 set m16 (mr13 m) i0 val)
            | i1 == 14  = m with mr14: (a2 set m16 (mr14 m) i0 val)
            | otherwise = m with mr15: (a2 set m16 (mr15 m) i0 val)

fn :: a2 set m4096 A2M4096 Int Int Int A2Blk8 => A2M4096
      a2 set m4096 m i2 i1 i0 val =
        | i2 < 8 =
          | i2 < 4 =
            | i2 == 0   = m with mp0: (a2 set m256 (mp0 m) i1 i0 val)
            | i2 == 1   = m with mp1: (a2 set m256 (mp1 m) i1 i0 val)
            | i2 == 2   = m with mp2: (a2 set m256 (mp2 m) i1 i0 val)
            | otherwise = m with mp3: (a2 set m256 (mp3 m) i1 i0 val) |.
          | otherwise =
            | i2 == 4   = m with mp4: (a2 set m256 (mp4 m) i1 i0 val)
            | i2 == 5   = m with mp5: (a2 set m256 (mp5 m) i1 i0 val)
            | i2 == 6   = m with mp6: (a2 set m256 (mp6 m) i1 i0 val)
            | otherwise = m with mp7: (a2 set m256 (mp7 m) i1 i0 val) |.
        | otherwise =
          | i2 < 12 =
            | i2 == 8   = m with mp8: (a2 set m256 (mp8 m) i1 i0 val)
            | i2 == 9   = m with mp9: (a2 set m256 (mp9 m) i1 i0 val)
            | i2 == 10  = m with mp10: (a2 set m256 (mp10 m) i1 i0 val)
            | otherwise = m with mp11: (a2 set m256 (mp11 m) i1 i0 val) |.
          | otherwise =
            | i2 == 12  = m with mp12: (a2 set m256 (mp12 m) i1 i0 val)
            | i2 == 13  = m with mp13: (a2 set m256 (mp13 m) i1 i0 val)
            | i2 == 14  = m with mp14: (a2 set m256 (mp14 m) i1 i0 val)
            | otherwise = m with mp15: (a2 set m256 (mp15 m) i1 i0 val)

fn :: a2 set mem A2Mem Int Int Int Int A2Blk8 => A2Mem
      a2 set mem m i3 i2 i1 i0 val =
        | i3 < 8 =
          | i3 < 4 =
            | i3 == 0   = m with mt0: (a2 set m4096 (mt0 m) i2 i1 i0 val)
            | i3 == 1   = m with mt1: (a2 set m4096 (mt1 m) i2 i1 i0 val)
            | i3 == 2   = m with mt2: (a2 set m4096 (mt2 m) i2 i1 i0 val)
            | otherwise = m with mt3: (a2 set m4096 (mt3 m) i2 i1 i0 val) |.
          | otherwise =
            | i3 == 4   = m with mt4: (a2 set m4096 (mt4 m) i2 i1 i0 val)
            | i3 == 5   = m with mt5: (a2 set m4096 (mt5 m) i2 i1 i0 val)
            | i3 == 6   = m with mt6: (a2 set m4096 (mt6 m) i2 i1 i0 val)
            | otherwise = m with mt7: (a2 set m4096 (mt7 m) i2 i1 i0 val) |.
        | otherwise =
          | i3 < 12 =
            | i3 == 8   = m with mt8: (a2 set m4096 (mt8 m) i2 i1 i0 val)
            | i3 == 9   = m with mt9: (a2 set m4096 (mt9 m) i2 i1 i0 val)
            | i3 == 10  = m with mt10: (a2 set m4096 (mt10 m) i2 i1 i0 val)
            | otherwise = m with mt11: (a2 set m4096 (mt11 m) i2 i1 i0 val) |.
          | otherwise =
            | i3 == 12  = m with mt12: (a2 set m4096 (mt12 m) i2 i1 i0 val)
            | i3 == 13  = m with mt13: (a2 set m4096 (mt13 m) i2 i1 i0 val)
            | i3 == 14  = m with mt14: (a2 set m4096 (mt14 m) i2 i1 i0 val)
            | otherwise = m with mt15: (a2 set m4096 (mt15 m) i2 i1 i0 val)

fn :: a2 set blk A2Mem Int A2Blk8 => A2Mem
      a2 set blk m idx val =
        a2 set mem m ((idx / 4096) % 16) ((idx / 256) % 16) ((idx / 16) % 16) (idx % 16) val

fn :: a2 init all lanes loop A2Mem [Int] Int Int Int => A2Mem
      a2 init all lanes loop mem h0 l lanes q =
        | l >= lanes = mem
        | otherwise  =
          b0   = a2 bytes to blk8 (a2 blake2b long (h0 :: (a2 u32 to le4 0) :: (a2 u32 to le4 l)) 1024)
          b1   = a2 bytes to blk8 (a2 blake2b long (h0 :: (a2 u32 to le4 1) :: (a2 u32 to le4 l)) 1024)
          mem1 = a2 set blk mem (l * q) b0
          mem2 = a2 set blk mem1 ((l * q) + 1) b1
          a2 init all lanes loop mem2 h0 (l + 1) lanes q

fn :: a2 init all lanes [Int] Int Int Int => A2Mem
      a2 init all lanes h0 l lanes q =
        a2 init all lanes loop (a2 zero mem) h0 l lanes q

fn :: a2 make addr blk A2Ctx Int => A2Blk8
      a2 make addr blk ctx ctr =
        zb      = a2 zero blk8
        zw      = a2 zero w16
        z0      = A2U64 0 0
        m_prime = (p_lanes ctx) * (q_cols ctx)
        in_w0   = A2W16 (A2U64 (r_pass ctx) 0) (A2U64 (l_lane ctx) 0) (A2U64 (s_slice ctx) 0) (A2U64 m_prime 0) (A2U64 (t_iters ctx) 0) (A2U64 2 0) (A2U64 ctr 0) z0 z0 z0 z0 z0 z0 z0 z0 z0
        in_blk  = A2Blk8 in_w0 zw zw zw zw zw zw zw
        a2 compress blk8 zb (a2 compress blk8 zb in_blk)

fn :: a2 calc w size A2Ctx Int Bool => Int
      a2 calc w size ctx idx same_lane =
        | (r_pass ctx) == 0 =
          | (s_slice ctx) == 0 or same_lane = ((s_slice ctx) * (seg_len ctx)) + idx - 1
          | idx == 0                        = ((s_slice ctx) * (seg_len ctx)) - 1
          | otherwise                       = (s_slice ctx) * (seg_len ctx) |.
        | otherwise =
          | same_lane = ((q_cols ctx) - (seg_len ctx)) + idx - 1
          | idx == 0  = ((q_cols ctx) - (seg_len ctx)) - 1
          | otherwise = (q_cols ctx) - (seg_len ctx)

fn :: a2 fill segment A2Mem A2Ctx Int A2Blk8 => A2Mem
      a2 fill segment mem ctx idx addr_blk =
        | idx >= (seg_len ctx) = mem
        | otherwise =
          r        = r_pass ctx
          s        = s_slice ctx
          l        = l_lane ctx
          p        = p_lanes ctx
          q        = q_cols ctx
          sl       = seg_len ctx
          curr_col = (s * sl) + idx
          prev_col = ((curr_col - 1) + q) % q
          data_ind = r == 0 and s < 2
          need_adr = data_ind and ((idx % 128) == 0 or (idx == 2 and r == 0 and s == 0))
          addr2    =
            | need_adr  = a2 make addr blk ctx ((idx / 128) + 1)
            | otherwise = addr_blk
          j_pair   =
            | data_ind  = a2 get blk8 addr2 (idx % 128)
            | otherwise = w0 (r0 (a2 nth blk mem ((l * q) + prev_col)))
          j1       = a2_lo j_pair
          j2       = a2_hi j_pair
          ref_lane =
            | r == 0 and s == 0 = l
            | otherwise         = j2 % p
          w_size   = a2 calc w size ctx idx (ref_lane == l)
          x_val    = a2_hi (a2 mul32 u64 j1 j1)
          y_val    = a2_hi (a2 mul32 u64 w_size x_val)
          zz       = w_size - 1 - y_val
          st_pos   =
            | r == 0    = 0
            | otherwise = ((s + 1) % 4) * sl
          ref_col  = (st_pos + zz) % q
          prev_blk = a2 nth blk mem ((l * q) + prev_col)
          ref_blk  = a2 nth blk mem ((ref_lane * q) + ref_col)
          new_blk  = a2 compress blk8 prev_blk ref_blk
          fin_blk  =
            | r == 0    = new_blk
            | otherwise = a2 bitxor blk8 new_blk (a2 nth blk mem ((l * q) + curr_col))
          mem2     = a2 set blk mem ((l * q) + curr_col) fin_blk
          a2 fill segment mem2 ctx (idx + 1) addr2

fn :: a2 run lanes A2Mem A2Ctx Int => A2Mem
      a2 run lanes mem ctx l =
        | l >= (p_lanes ctx) = mem
        | otherwise =
          ctx_l   = ctx with l_lane: l
          start_j =
            | (r_pass ctx) == 0 and (s_slice ctx) == 0 = 2
            | otherwise                                = 0
          mem2    = a2 fill segment mem ctx_l start_j (a2 zero blk8)
          a2 run lanes mem2 ctx (l + 1)

fn :: a2 run slices A2Mem A2Ctx Int => A2Mem
      a2 run slices mem ctx s =
        | s >= 4 = mem
        | otherwise =
          ctx_s = ctx with s_slice: s
          mem2  = a2 run lanes mem ctx_s 0
          a2 run slices mem2 ctx (s + 1)

fn :: a2 run passes A2Mem A2Ctx Int => A2Mem
      a2 run passes mem ctx r =
        | r >= (t_iters ctx) = mem
        | otherwise =
          ctx_r = ctx with r_pass: r
          mem2  = a2 run slices mem ctx_r 0
          a2 run passes mem2 ctx (r + 1)

fn :: a2 bitxor final lanes A2Mem Int Int Int A2Blk8 => A2Blk8
      a2 bitxor final lanes mem l lanes q acc =
        | l >= lanes = acc
        | otherwise  =
          blk = a2 nth blk mem ((l * q) + (q - 1))
          a2 bitxor final lanes mem (l + 1) lanes q (a2 bitxor blk8 acc blk)

-- @implements FR-CRYPTO-001
-- @implements FR-CRYPTO-004
-- @implements NFR-PERF-001
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
fn :: derive raw tag ctx [Int] [Int] String String Argon2Params => [Int]
      derive raw tag ctx pwd_raw salt_bytes secret ad params =
        sec_b = a2 str to bytes secret
        ad_b  = a2 str to bytes ad
        m     = m_cost params
        t     = t_cost params
        p     = lanes params
        tlen  = tag_len params
        h0_in = (a2 u32 to le4 p) :: (a2 u32 to le4 tlen) :: (a2 u32 to le4 m) :: (a2 u32 to le4 t) :: (a2 u32 to le4 19) :: (a2 u32 to le4 2) :: (a2 u32 to le4 (a2 list len pwd_raw)) :: pwd_raw :: (a2 u32 to le4 (a2 list len salt_bytes)) :: salt_bytes :: (a2 u32 to le4 (a2 list len sec_b)) :: sec_b :: (a2 u32 to le4 (a2 list len ad_b)) :: ad_b
        h0    = a2 blake2b h0_in 64
        sl    = m / (4 * p)
        q     = sl * 4
        mem0  = a2 init all lanes h0 0 p q
        ctx   = A2Ctx 0 0 0 p q sl t
        memf  = a2 run passes mem0 ctx 0
        c0    = a2 nth blk memf (q - 1)
        c_fin = a2 bitxor final lanes memf 1 p q c0
        a2 blake2b long (a2 blk8 to bytes c_fin) tlen

fn :: derive raw tag [Int] [Int] Argon2Params => [Int]
      derive raw tag pwd_raw salt_bytes params = derive raw tag ctx pwd_raw salt_bytes "" "" params

-- ============================================================
-- Unpadded Base64 Encoding & Decoding (PHC Specification)
-- ============================================================

fn :: b64 alphabet => String
      b64 alphabet =  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

fn :: b64 char Int => String
      b64 char idx =  str slice (b64 alphabet) (idx % 64) ((idx % 64) + 1)

fn :: b64 encode nopad [Int]           => String
      b64 encode nopad []              =  ""
      b64 encode nopad (b0:[])         =
        c0 = b0 / 4
        c1 = (b0 % 4) * 16
        (b64 char c0) + (b64 char c1)
      b64 encode nopad (b0:b1:[])      =
        c0 = b0 / 4
        c1 = ((b0 % 4) * 16) + (b1 / 16)
        c2 = (b1 % 16) * 4
        (b64 char c0) + (b64 char c1) + (b64 char c2)
      b64 encode nopad (b0:b1:b2:rest) =
        c0 = b0 / 4
        c1 = ((b0 % 4) * 16) + (b1 / 16)
        c2 = ((b1 % 16) * 4) + (b2 / 64)
        c3 = b2 % 64
        (b64 char c0) + (b64 char c1) + (b64 char c2) + (b64 char c3) + (b64 encode nopad rest)

fn :: b64 char val Int => Int
      b64 char val c   =
        | c >= 65 and c <= 90  = c - 65
        | c >= 97 and c <= 122 = (c - 97) + 26
        | c >= 48 and c <= 57  = (c - 48) + 52
        | c == 43              = 62
        | c == 47              = 63
        | otherwise            = 0 - 1

fn :: valid b64 chars String Int Int => Bool
      valid b64 chars s idx len =
        | idx >= len                             = True
        | (b64 char val (str char at s idx)) < 0 = False
        | otherwise                              = valid b64 chars s (idx + 1) len

fn :: is valid b64 nopad String => Bool
      is valid b64 nopad s      =
        | (str len s) == 0 or ((str len s) % 4) == 1 = False
        | str contains s "="                         = False
        | otherwise                                  = valid b64 chars s 0 (str len s)

fn :: b64 decode rem String Int Int Int => [Int]
      b64 decode rem s idx len rem =
        | rem <= 0 = []
        | rem == 2 =
          v0 = b64 char val (str char at s idx)
          v1 = b64 char val (str char at s (idx + 1))
          [((v0 * 4) + (v1 / 16)) % 256]
        | rem == 3 =
          v0 = b64 char val (str char at s idx)
          v1 = b64 char val (str char at s (idx + 1))
          v2 = b64 char val (str char at s (idx + 2))
          [((v0 * 4) + (v1 / 16)) % 256, (((v1 % 16) * 16) + (v2 / 4)) % 256]
        | otherwise =
          v0 = b64 char val (str char at s idx)
          v1 = b64 char val (str char at s (idx + 1))
          v2 = b64 char val (str char at s (idx + 2))
          v3 = b64 char val (str char at s (idx + 3))
          b0 = ((v0 * 4) + (v1 / 16)) % 256
          b1 = (((v1 % 16) * 16) + (v2 / 4)) % 256
          b2 = (((v2 % 4) * 64) + v3) % 256
          [b0, b1, b2] :: (b64 decode loop s (idx + 4) len)

fn :: b64 decode loop String Int Int => [Int]
      b64 decode loop s idx len = b64 decode rem s idx len (len - idx)

fn :: b64 decode nopad String => [Int]
      b64 decode nopad s      =  b64 decode loop s 0 (str len s)

-- ============================================================
-- Presets, Salt Generation, Key Derivation, PHC & Rehash API
-- @implements FR-CRYPTO-001
-- @implements FR-CRYPTO-002
-- @mitigates VUL-AUTHN-001
-- @mitigates VUL-INPUT-001
-- ============================================================

-- Preset profiles (`m_cost` is in KiB: 19456 KiB = 19 MiB OWASP minimum;
-- 47104 KiB = 46 MiB OWASP moderate; 65536 KiB = 64 MiB RFC 9106 §4 second option)
fn :: default argon2 params => Argon2Params
      default argon2 params =  Argon2Params 19456 2 1 32 19

fn :: argon2 interactive params => Argon2Params
      argon2 interactive params =  Argon2Params 19456 2 1 32 19

fn :: argon2 moderate params => Argon2Params
      argon2 moderate params =  Argon2Params 47104 3 1 32 19

fn :: argon2 sensitive params => Argon2Params
      argon2 sensitive params =  Argon2Params 65536 3 4 32 19

fn :: argon2 params Int Int Int Int => Argon2Params
      argon2 params m_cost t_cost lanes tag_len = Argon2Params m_cost t_cost lanes tag_len 19

fn :: clamp salt len Int => Int
      clamp salt len n   =
        | n < 16    = 16
        | n > 64    = 64
        | otherwise = n

fn :: a2 getrandom call Int Int Int => Int
      a2 getrandom call ptr rem rc =
        | rc == (0 - 4) = a2 getrandom loop ptr rem
        | otherwise     = rc

fn :: a2 getrandom step Int Int Int => Int
      a2 getrandom step ptr rem rc =
        | rc <= 0   = rc
        | rc >= rem = 0
        | otherwise = a2 getrandom loop (ptr + rc) (rem - rc)

fn :: a2 getrandom loop Int Int => Int
      a2 getrandom loop ptr rem =
        | rem <= 0  = 0
        | otherwise = a2 getrandom step ptr rem (a2 getrandom call ptr rem (sys call 318 ptr rem 0 0 0 0))

fn :: argon2id generate salt Int => String
      argon2id generate salt n   =
        eff_n = clamp salt len n
        neg1  = 0 - 1
        ptr   = sys call 9 0 4096 3 34 neg1 0
        mfd   = sys call 319 4194311 1 0 0 0 0
        _     = a2 getrandom loop ptr eff_n
        _     = sys call 18 mfd ptr eff_n 0 0 0
        _     = sys call 8 mfd 0 0 0 0 0
        raw   = sys read fd mfd eff_n
        _     = sys close mfd
        _     = sys call 11 ptr 4096 0 0 0 0
        raw

fn :: validate argon2 params Argon2Params [Int]      => String
      validate argon2 params params       salt_bytes =
        | (version params) != 19                        = "unsupported Argon2 version (expected 19)"
        | (t_cost params) < 1                           = "t_cost must be >= 1"
        | (lanes params) < 1 or (lanes params) > 255    = "lanes must be in 1..255"
        | (m_cost params) < (8 * (lanes params))        = "m_cost must be >= 8 * lanes"
        | (tag_len params) < 4 or (tag_len params) > 64 = "tag_len must be in 4..64"
        | (a2 list len salt_bytes) < 8                  = "salt must be at least 8 bytes"
        | otherwise                                     = ""

fn :: finish derive key checked [Int] Int => Argon2KeyRes
      finish derive key checked tag_raw exp_len =
        | (a2 list len tag_raw) != exp_len = Argon2KeyErr "tag derivation failed"
        | otherwise                        = Argon2KeyOk tag_raw

fn :: finish derive key String [Int] Argon2Params String => Argon2KeyRes
      finish derive key pwd salt_bytes params err =
        | (str len err) > 0 = Argon2KeyErr err
        | otherwise         =
          tag_raw = derive raw tag (a2 str to bytes pwd) salt_bytes params
          finish derive key checked tag_raw (tag_len params)

fn :: argon2id derive key String String Argon2Params => Argon2KeyRes
      argon2id derive key pwd salt params =
        salt_bytes = a2 str to bytes salt
        finish derive key pwd salt_bytes params (validate argon2 params params salt_bytes)

fn :: key res to hex Argon2KeyRes       => Argon2Res
      key res to hex (Argon2KeyErr err) =  Argon2Err err
      key res to hex (Argon2KeyOk bytes) = Argon2Ok (bytes to hex bytes)

fn :: argon2id derive key hex String String Argon2Params => Argon2Res
      argon2id derive key hex pwd salt params = key res to hex (argon2id derive key pwd salt params)

fn :: build phc from tag [Int] [Int] Argon2Params => Argon2Res
      build phc from tag salt_bytes tag_raw params =
        | (a2 list len tag_raw) != (tag_len params) = Argon2Err "tag derivation failed"
        | otherwise =
          salt_b64 = b64 encode nopad salt_bytes
          tag_b64  = b64 encode nopad tag_raw
          m        = m_cost params
          t        = t_cost params
          p        = lanes params
          Argon2Ok "$argon2id$v=19$m={m},t={t},p={p}${salt_b64}${tag_b64}"

fn :: finish argon2id hash ctx String [Int] String String Argon2Params String => Argon2Res
      finish argon2id hash ctx pwd salt_bytes secret ad params err =
        | (str len err) > 0 = Argon2Err err
        | otherwise =
          pwd_raw = a2 str to bytes pwd
          tag_raw = derive raw tag ctx pwd_raw salt_bytes secret ad params
          build phc from tag salt_bytes tag_raw params

fn :: argon2id hash ctx String String String String Argon2Params => Argon2Res
      argon2id hash ctx pwd salt secret ad params =
        salt_bytes = a2 str to bytes salt
        finish argon2id hash ctx pwd salt_bytes secret ad params (validate argon2 params params salt_bytes)

fn :: argon2id hash bytes String [Int] Argon2Params => Argon2Res
      argon2id hash bytes pwd salt_bytes params =
        finish argon2id hash ctx pwd salt_bytes "" "" params (validate argon2 params params salt_bytes)

fn :: argon2id hash params String String Argon2Params => Argon2Res
      argon2id hash params pwd salt params = argon2id hash bytes pwd (a2 str to bytes salt) params

fn :: argon2id hash password String Argon2Params => Argon2Res
      argon2id hash password pwd    params       =  argon2id hash params pwd (argon2id generate salt 16) params

fn :: ct diff loop [Int] [Int] Int => Int
      ct diff loop [] [] acc = acc
      ct diff loop (a:ar) (b:br) acc =
        d = byte bitxor a b
        ct diff loop ar br (acc + d)
      ct diff loop _ _ acc = acc + 1

fn :: constant time bytes eq [Int] [Int] => Bool
      constant time bytes eq a b =
        la   = a2 list len a
        lb   = a2 list len b
        diff = ct diff loop a b 0
        (la == lb) and (diff == 0)

fn :: constant time eq String String => Bool
      constant time eq a      b      =  constant time bytes eq (a2 str to bytes a) (a2 str to bytes b)

fn :: split str loop String Int Int Int Int => [String]
      split str loop s ch start idx len =
        | idx >= len                = [(str slice s start len)]
        | (str char at s idx) == ch = [(str slice s start idx)] :: (split str loop s ch (idx + 1) (idx + 1) len)
        | otherwise                 = split str loop s ch start (idx + 1) len

fn :: a2 is digits loop String Int Int => Bool
      a2 is digits loop s idx len =
        | idx >= len                                           = True
        | (str char at s idx) < 48 or (str char at s idx) > 57 = False
        | otherwise                                            = a2 is digits loop s (idx + 1) len

fn :: parse kv int String String => Int
      parse kv int item   prefix =
        | (str len item) <= (str len prefix)                           = 0 - 1
        | not (str starts with item prefix)                            = 0 - 1
        | not (a2 is digits loop item (str len prefix) (str len item)) = 0 - 1
        | otherwise                                                    = str to int (str slice item (str len prefix) (str len item))

fn :: build parsed phc String String Argon2Params String => Argon2PhcRes
      build parsed phc s_b64 t_b64 params err =
        | (str len err) > 0 = Argon2PhcErr err
        | otherwise         = Argon2PhcOk (Argon2Phc params s_b64 t_b64)

fn :: decode phc fields String String Int Int Int => Argon2PhcRes
      decode phc fields s_b64 t_b64 m t p =
        | not (is valid b64 nopad s_b64) = Argon2PhcErr "invalid Base64 salt in PHC string"
        | not (is valid b64 nopad t_b64) = Argon2PhcErr "invalid Base64 tag in PHC string"
        | otherwise =
          salt_bytes = b64 decode nopad s_b64
          tag_bytes  = b64 decode nopad t_b64
          params     = Argon2Params m t p (a2 list len tag_bytes) 19
          build parsed phc s_b64 t_b64 params (validate argon2 params params salt_bytes)

fn :: parse phc mtp Int Int Int [String] => Argon2PhcRes
      parse phc mtp m t p parts =
        | m < 8 or t < 1 or p < 1 = Argon2PhcErr "invalid m, t, or p in PHC string"
        | otherwise               = decode phc fields (a2 nth str parts 4) (a2 nth str parts 5) m t p

fn :: parse phc kvs [String] [String] => Argon2PhcRes
      parse phc kvs parts    kvs      =
        | (a2 str list len kvs) != 3 = Argon2PhcErr "expected m,t,p parameters in PHC string"
        | otherwise =
          m = parse kv int (a2 nth str kvs 0) "m="
          t = parse kv int (a2 nth str kvs 1) "t="
          p = parse kv int (a2 nth str kvs 2) "p="
          parse phc mtp m t p parts

fn :: parse phc parts [String] => Argon2PhcRes
      parse phc parts parts    =
        | (a2 str list len parts) != 6       = Argon2PhcErr "invalid PHC segment count"
        | (a2 nth str parts 0) != ""         = Argon2PhcErr "PHC string must start with $"
        | (a2 nth str parts 1) != "argon2id" = Argon2PhcErr "unsupported algorithm (expected argon2id)"
        | (a2 nth str parts 2) != "v=19"     = Argon2PhcErr "unsupported version (expected v=19)"
        | otherwise =
          p_str = a2 nth str parts 3
          parse phc kvs parts (split str loop p_str 44 0 0 (str len p_str))

fn :: argon2id parse phc String => Argon2PhcRes
      argon2id parse phc phc    =  parse phc parts (split str loop phc 36 0 0 (str len phc))

fn :: check rehash parsed Argon2PhcRes     Argon2Params => Bool
      check rehash parsed (Argon2PhcErr _) _            =  True
      check rehash parsed (Argon2PhcOk parsed) target   =
        cur = params parsed
        ((m_cost cur) != (m_cost target)) or ((t_cost cur) != (t_cost target)) or ((lanes cur) != (lanes target)) or ((tag_len cur) != (tag_len target))

fn :: argon2id needs rehash String Argon2Params => Bool
      argon2id needs rehash phc    target       =  check rehash parsed (argon2id parse phc phc) target

fn :: verify parsed ctx Argon2PhcRes String String String => Bool
      verify parsed ctx (Argon2PhcErr _) _ _ _ = False
      verify parsed ctx (Argon2PhcOk parsed) pwd secret ad =
        salt_bytes = b64 decode nopad (salt_b64 parsed)
        tag_bytes  = b64 decode nopad (tag_b64 parsed)
        computed   = derive raw tag ctx (a2 str to bytes pwd) salt_bytes secret ad (params parsed)
        constant time bytes eq computed tag_bytes

fn :: argon2id verify ctx String String String String => Bool
      argon2id verify ctx pwd phc secret ad = verify parsed ctx (argon2id parse phc phc) pwd secret ad

-- @implements FR-CRYPTO-001
-- @implements FR-CRYPTO-004
-- @implements API-CRYPTO-001
-- @mitigates VUL-AUTHN-001
fn :: argon2id verify String String => Bool
      argon2id verify pwd    phc    =
        | not (str starts with phc "$argon2id$") = False
        | otherwise                              = argon2id verify ctx pwd phc "" ""

fn :: unwrap phc res Argon2Res      => String
      unwrap phc res (Argon2Ok phc) =  phc
      unwrap phc res (Argon2Err _)  =  ""

-- @implements FR-CRYPTO-001
-- @implements FR-CRYPTO-004
-- @implements API-CRYPTO-001
fn :: argon2id hash String String Int Int Int => String
      argon2id hash pwd salt m_kib t_iters p_lanes =
        unwrap phc res (argon2id hash params pwd salt (Argon2Params m_kib t_iters p_lanes 32 19))

-- @implements FR-CRYPTO-004
-- @implements API-CRYPTO-001
fn :: argon2id hash phc String String Int Int Int => String
      argon2id hash phc pwd salt m_kib t_iters p_lanes =
        argon2id hash pwd salt m_kib t_iters p_lanes
