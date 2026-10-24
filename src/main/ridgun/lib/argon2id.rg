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

type A2M16   = mb0: Tensor[U64 * 8 * 16], mb1: Tensor[U64 * 8 * 16], mb2: Tensor[U64 * 8 * 16], mb3: Tensor[U64 * 8 * 16], mb4: Tensor[U64 * 8 * 16], mb5: Tensor[U64 * 8 * 16], mb6: Tensor[U64 * 8 * 16], mb7: Tensor[U64 * 8 * 16], mb8: Tensor[U64 * 8 * 16], mb9: Tensor[U64 * 8 * 16], mb10: Tensor[U64 * 8 * 16], mb11: Tensor[U64 * 8 * 16], mb12: Tensor[U64 * 8 * 16], mb13: Tensor[U64 * 8 * 16], mb14: Tensor[U64 * 8 * 16], mb15: Tensor[U64 * 8 * 16]
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

fn :: byte bitxor Int Int => Int
      byte bitxor a   b   =
        (a xor b) and 255

fn :: u32 norm Int => Int
      u32 norm x   =  x and 0xFFFFFFFF

fn :: u32 add Int Int => Int
      u32 add a   b   =  (a + b) and 0xFFFFFFFF

fn :: u32 bitxor Int Int => Int
      u32 bitxor a   b   =
        (a xor b) and 0xFFFFFFFF

fn :: a2 u64 lh Int Int => U64
      a2 u64 lh lo  hi  =  (lo and 0xFFFFFFFF) or (hi shl 32)

fn :: a2 f blamka U64 U64 => U64
      a2 f blamka x   y   =  x + y + 2 * ((x and 0xFFFFFFFF) * (y and 0xFFFFFFFF))

fn :: a2 u32 to le4 Int => [Int]
      a2 u32 to le4 w   =
        uw = u32 norm w
        [uw and 255, (uw shr 8) and 255, (uw shr 16) and 255, (uw shr 24) and 255]

fn :: a2 bytes to u32 le [Int] Int => Int
      a2 bytes to u32 le bs off =
        (a2 nth int bs off) or ((a2 nth int bs (off + 1)) shl 8) or ((a2 nth int bs (off + 2)) shl 16) or ((a2 nth int bs (off + 3)) shl 24)

-- ============================================================
-- Pure-Ridgun RFC 7693 BLAKE2b-512 & Variable-Length H' (`blake2b_long`)
-- ============================================================

fn :: a2 zero w16 => Tensor[U64 * 16]
      a2 zero w16 =  Tensor[U64 * 16]

fn :: a2 zero blk8 => Tensor[U64 * 8 * 16]
      a2 zero blk8 =  Tensor[U64 * 8 * 16]

fn :: a2 b2b iv w16 => Tensor[U64 * 16]
      a2 b2b iv w16 =
        iv = Tensor[U64 * 16]
        iv_(0) = a2 u64 lh 4089235720 1779033703
        iv_(1) = a2 u64 lh 2227873595 3144134277
        iv_(2) = a2 u64 lh 4271175723 1013904242
        iv_(3) = a2 u64 lh 1595750129 2773480762
        iv_(4) = a2 u64 lh 2917565137 1359893119
        iv_(5) = a2 u64 lh 725511199  2600822924
        iv_(6) = a2 u64 lh 4215389547 528734635
        iv_(7) = a2 u64 lh 327033209  1541459225
        iv

fn :: a2 b2b g4 U64 U64 U64 U64 U64 U64 => U64 U64 U64 U64
      a2 b2b g4 a b c d mx my =
        mut a = a + b + mx
        mut d = (d xor a) rotr 32
        mut c = c + d
        mut b = (b xor c) rotr 24
        a = a + b + my
        d = (d xor a) rotr 16
        c = c + d
        b = (b xor c) rotr 63
        (a, b, c, d)

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

fn :: a2 b2b round Tensor[U64 * 16] Tensor[U64 * 16] Int => Tensor[U64 * 16]
      a2 b2b round v m r =
        s = a2 b2b sigma r
        v_(0), v_(4), v_(8),  v_(12) = a2 b2b g4 v_(0) v_(4) v_(8)  v_(12) m_(a2 nth int s 0)  m_(a2 nth int s 1)
        v_(1), v_(5), v_(9),  v_(13) = a2 b2b g4 v_(1) v_(5) v_(9)  v_(13) m_(a2 nth int s 2)  m_(a2 nth int s 3)
        v_(2), v_(6), v_(10), v_(14) = a2 b2b g4 v_(2) v_(6) v_(10) v_(14) m_(a2 nth int s 4)  m_(a2 nth int s 5)
        v_(3), v_(7), v_(11), v_(15) = a2 b2b g4 v_(3) v_(7) v_(11) v_(15) m_(a2 nth int s 6)  m_(a2 nth int s 7)
        v_(0), v_(5), v_(10), v_(15) = a2 b2b g4 v_(0) v_(5) v_(10) v_(15) m_(a2 nth int s 8)  m_(a2 nth int s 9)
        v_(1), v_(6), v_(11), v_(12) = a2 b2b g4 v_(1) v_(6) v_(11) v_(12) m_(a2 nth int s 10) m_(a2 nth int s 11)
        v_(2), v_(7), v_(8),  v_(13) = a2 b2b g4 v_(2) v_(7) v_(8)  v_(13) m_(a2 nth int s 12) m_(a2 nth int s 13)
        v_(3), v_(4), v_(9),  v_(14) = a2 b2b g4 v_(3) v_(4) v_(9)  v_(14) m_(a2 nth int s 14) m_(a2 nth int s 15)
        v

fn :: a2 b2b rounds Tensor[U64 * 16] Tensor[U64 * 16] Int => Tensor[U64 * 16]
      a2 b2b rounds v m r =
        | r >= 12   = v
        | otherwise = a2 b2b rounds (a2 b2b round v m r) m (r + 1)

fn :: a2 b2b compress Tensor[U64 * 16] Tensor[U64 * 16] Int Bool => Tensor[U64 * 16]
      a2 b2b compress h m t is_last =
        iv  = a2 b2b iv w16
        v14 =
          | is_last   = iv_(6) xor (not 0)
          | otherwise = iv_(6)
        v0  = Tensor[U64 * 16]
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
        v0_(12) = iv_(4) xor (t and 0xFFFFFFFF)
        v0_(13) = iv_(5)
        v0_(14) = v14
        v0_(15) = iv_(7)
        vf  = a2 b2b rounds v0 m 0
        out = Tensor[U64 * 16]
        out_(0) = (h_(0) xor vf_(0)) xor vf_(8)
        out_(1) = (h_(1) xor vf_(1)) xor vf_(9)
        out_(2) = (h_(2) xor vf_(2)) xor vf_(10)
        out_(3) = (h_(3) xor vf_(3)) xor vf_(11)
        out_(4) = (h_(4) xor vf_(4)) xor vf_(12)
        out_(5) = (h_(5) xor vf_(5)) xor vf_(13)
        out_(6) = (h_(6) xor vf_(6)) xor vf_(14)
        out_(7) = (h_(7) xor vf_(7)) xor vf_(15)
        out

fn :: a2 bytes to u64 [Int] Int => U64
      a2 bytes to u64 bs off =
        a2 u64 lh (a2 bytes to u32 le bs off) (a2 bytes to u32 le bs (off + 4))

fn :: a2 bytes to w16 [Int] Int => Tensor[U64 * 16]
      a2 bytes to w16 bs off =
        w = Tensor[U64 * 16]
        w_(0)  = a2 bytes to u64 bs off
        w_(1)  = a2 bytes to u64 bs (off + 8)
        w_(2)  = a2 bytes to u64 bs (off + 16)
        w_(3)  = a2 bytes to u64 bs (off + 24)
        w_(4)  = a2 bytes to u64 bs (off + 32)
        w_(5)  = a2 bytes to u64 bs (off + 40)
        w_(6)  = a2 bytes to u64 bs (off + 48)
        w_(7)  = a2 bytes to u64 bs (off + 56)
        w_(8)  = a2 bytes to u64 bs (off + 64)
        w_(9)  = a2 bytes to u64 bs (off + 72)
        w_(10) = a2 bytes to u64 bs (off + 80)
        w_(11) = a2 bytes to u64 bs (off + 88)
        w_(12) = a2 bytes to u64 bs (off + 96)
        w_(13) = a2 bytes to u64 bs (off + 104)
        w_(14) = a2 bytes to u64 bs (off + 112)
        w_(15) = a2 bytes to u64 bs (off + 120)
        w

fn :: a2 u64 to le8 U64 => [Int]
      a2 u64 to le8 x   =
        (a2 u32 to le4 (x and 0xFFFFFFFF)) :: (a2 u32 to le4 ((x shr 32) and 0xFFFFFFFF))

fn :: a2 h8 to bytes Tensor[U64 * 16] => [Int]
      a2 h8 to bytes h                =
        (a2 u64 to le8 h_(0)) :: (a2 u64 to le8 h_(1)) :: (a2 u64 to le8 h_(2)) :: (a2 u64 to le8 h_(3)) :: (a2 u64 to le8 h_(4)) :: (a2 u64 to le8 h_(5)) :: (a2 u64 to le8 h_(6)) :: (a2 u64 to le8 h_(7))

fn :: a2 b2b loop Tensor[U64 * 16] [Int] Int => Tensor[U64 * 16]
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
        h_in     = a2 b2b iv w16
        h_in_(0) = h_in_(0) xor ((16842752 + outlen) and 0xFFFFFFFF)
        h_fi     = a2 b2b loop h_in msg 0
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

fn :: a2 blamka g U64 U64 U64 U64 => U64 U64 U64 U64
      a2 blamka g a b c d =
        mut a = a + b + 2 * ((a and 0xFFFFFFFF) * (b and 0xFFFFFFFF))
        mut d = (d xor a) rotr 32
        mut c = c + d + 2 * ((c and 0xFFFFFFFF) * (d and 0xFFFFFFFF))
        mut b = (b xor c) rotr 24
        a = a + b + 2 * ((a and 0xFFFFFFFF) * (b and 0xFFFFFFFF))
        d = (d xor a) rotr 16
        c = c + d + 2 * ((c and 0xFFFFFFFF) * (d and 0xFFFFFFFF))
        b = (b xor c) rotr 63
        (a, b, c, d)

fn :: a2 blamka p16 Tensor[U64 * 16] => ()
      a2 blamka p16 v                =
        v0, v4, v8,  v12 = a2 blamka g v_(0) v_(4) v_(8)  v_(12)
        v1, v5, v9,  v13 = a2 blamka g v_(1) v_(5) v_(9)  v_(13)
        v2, v6, v10, v14 = a2 blamka g v_(2) v_(6) v_(10) v_(14)
        v3, v7, v11, v15 = a2 blamka g v_(3) v_(7) v_(11) v_(15)
        v_(0), v_(5), v_(10), v_(15) = a2 blamka g v0 v5 v10 v15
        v_(1), v_(6), v_(11), v_(12) = a2 blamka g v1 v6 v11 v12
        v_(2), v_(7), v_(8),  v_(13) = a2 blamka g v2 v7 v8  v13
        v_(3), v_(4), v_(9),  v_(14) = a2 blamka g v3 v4 v9  v14

fn :: a2 blamka col pair Tensor[U64 * 8 * 16] Int => Tensor[U64 * 8 * 16]
      a2 blamka col pair z j =
        c  = 2 * j
        c1 = c + 1
        z0c,  z2c,  z4c,  z6c  = a2 blamka g z_(0, c)  z_(2, c)  z_(4, c)  z_(6, c)
        z0c1, z2c1, z4c1, z6c1 = a2 blamka g z_(0, c1) z_(2, c1) z_(4, c1) z_(6, c1)
        z1c,  z3c,  z5c,  z7c  = a2 blamka g z_(1, c)  z_(3, c)  z_(5, c)  z_(7, c)
        z1c1, z3c1, z5c1, z7c1 = a2 blamka g z_(1, c1) z_(3, c1) z_(5, c1) z_(7, c1)
        z_(0, c),  z_(2, c1), z_(5, c),  z_(7, c1) = a2 blamka g z0c  z2c1 z5c  z7c1
        z_(0, c1), z_(3, c),  z_(5, c1), z_(6, c)  = a2 blamka g z0c1 z3c  z5c1 z6c
        z_(1, c),  z_(3, c1), z_(4, c),  z_(6, c1) = a2 blamka g z1c  z3c1 z4c  z6c1
        z_(1, c1), z_(2, c),  z_(4, c1), z_(7, c)  = a2 blamka g z1c1 z2c  z4c1 z7c
        z

fn :: a2 blamka cols loop Tensor[U64 * 8 * 16] Int => Tensor[U64 * 8 * 16]
      a2 blamka cols loop z j =
        | j >= 8    = z
        | otherwise = a2 blamka cols loop (a2 blamka col pair z j) (j + 1)

fn :: a2 bitxor blk8 Tensor[U64 * 8 * 16] Tensor[U64 * 8 * 16] => Tensor[U64 * 8 * 16]
      a2 bitxor blk8 a b = a_ij xor b_ij

fn :: a2 compress blk8 Tensor[U64 * 8 * 16] Tensor[U64 * 8 * 16] => Tensor[U64 * 8 * 16]
      a2 compress blk8 x y =
        r_ij = x_ij xor y_ij
        z_ij = r_ij
        map a2 blamka p16 in z_(i,)
        z2   = a2 blamka cols loop z 0
        z2_ij xor r_ij

fn :: a2 get blk8 Tensor[U64 * 8 * 16] Int => U64
      a2 get blk8 blk                  idx =
        blk_((idx / 16) % 8, idx % 16)

fn :: a2 bytes to blk8 row Tensor[U64 * 8 * 16] Int [Int] Int => Tensor[U64 * 8 * 16]
      a2 bytes to blk8 row blk r bs c =
        | c >= 16   = blk
        | otherwise =
          blk_(r, c) = a2 bytes to u64 bs (c * 8)
          a2 bytes to blk8 row blk r bs (c + 1)

fn :: a2 bytes to blk8 loop Tensor[U64 * 8 * 16] Int [Int] => Tensor[U64 * 8 * 16]
      a2 bytes to blk8 loop blk r bs =
        | r >= 8    = blk
        | otherwise =
          row_bs = a2 take ints bs 128
          rest   = a2 drop ints bs 128
          blk2   = a2 bytes to blk8 row blk r row_bs 0
          a2 bytes to blk8 loop blk2 (r + 1) rest

fn :: a2 bytes to blk8 [Int] => Tensor[U64 * 8 * 16]
      a2 bytes to blk8 bs    =
        a2 bytes to blk8 loop (Tensor[U64 * 8 * 16]) 0 bs

fn :: a2 blk8 row to bytes Tensor[U64 * 8 * 16] Int Int => [Int]
      a2 blk8 row to bytes b r c =
        | c >= 16   = []
        | otherwise = (a2 u64 to le8 b_(r, c)) :: (a2 blk8 row to bytes b r (c + 1))

fn :: a2 blk8 to bytes loop Tensor[U64 * 8 * 16] Int => [Int]
      a2 blk8 to bytes loop b r =
        | r >= 8    = []
        | otherwise = (a2 blk8 row to bytes b r 0) :: (a2 blk8 to bytes loop b (r + 1))

fn :: a2 blk8 to bytes Tensor[U64 * 8 * 16] => [Int]
      a2 blk8 to bytes b                    =
        a2 blk8 to bytes loop b 0

fn :: a2 zero mem => A2Mem
      a2 zero mem =
        zb = a2 zero blk8
        m1 = A2M16 zb zb zb zb zb zb zb zb zb zb zb zb zb zb zb zb
        m2 = A2M256 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1 m1
        m3 = A2M4096 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2 m2
        A2Mem m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3 m3

fn :: a2 get m16 A2M16 Int => Tensor[U64 * 8 * 16]
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

fn :: a2 get m256 A2M256 Int Int => Tensor[U64 * 8 * 16]
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

fn :: a2 get m4096 A2M4096 Int Int Int => Tensor[U64 * 8 * 16]
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

fn :: a2 get mem A2Mem Int Int Int Int => Tensor[U64 * 8 * 16]
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

fn :: a2 nth blk A2Mem Int => Tensor[U64 * 8 * 16]
      a2 nth blk m     idx =
        a2 get mem m ((idx / 4096) % 16) ((idx / 256) % 16) ((idx / 16) % 16) (idx % 16)

fn :: a2 set m16 A2M16 Int Tensor[U64 * 8 * 16] => A2M16
      a2 set m16 m i val =
        | i < 8 =
          | i < 4 =
            | i == 0    = m with mb0 = val
            | i == 1    = m with mb1 = val
            | i == 2    = m with mb2 = val
            | otherwise = m with mb3 = val |.
          | otherwise =
            | i == 4    = m with mb4 = val
            | i == 5    = m with mb5 = val
            | i == 6    = m with mb6 = val
            | otherwise = m with mb7 = val |.
        | otherwise =
          | i < 12 =
            | i == 8    = m with mb8 = val
            | i == 9    = m with mb9 = val
            | i == 10   = m with mb10 = val
            | otherwise = m with mb11 = val |.
          | otherwise =
            | i == 12   = m with mb12 = val
            | i == 13   = m with mb13 = val
            | i == 14   = m with mb14 = val
            | otherwise = m with mb15 = val

fn :: a2 set m256 A2M256 Int Int Tensor[U64 * 8 * 16] => A2M256
      a2 set m256 m i1 i0 val =
        | i1 < 8 =
          | i1 < 4 =
            | i1 == 0   = m with mr0 = (a2 set m16 (mr0 m) i0 val)
            | i1 == 1   = m with mr1 = (a2 set m16 (mr1 m) i0 val)
            | i1 == 2   = m with mr2 = (a2 set m16 (mr2 m) i0 val)
            | otherwise = m with mr3 = (a2 set m16 (mr3 m) i0 val) |.
          | otherwise =
            | i1 == 4   = m with mr4 = (a2 set m16 (mr4 m) i0 val)
            | i1 == 5   = m with mr5 = (a2 set m16 (mr5 m) i0 val)
            | i1 == 6   = m with mr6 = (a2 set m16 (mr6 m) i0 val)
            | otherwise = m with mr7 = (a2 set m16 (mr7 m) i0 val) |.
        | otherwise =
          | i1 < 12 =
            | i1 == 8   = m with mr8 = (a2 set m16 (mr8 m) i0 val)
            | i1 == 9   = m with mr9 = (a2 set m16 (mr9 m) i0 val)
            | i1 == 10  = m with mr10 = (a2 set m16 (mr10 m) i0 val)
            | otherwise = m with mr11 = (a2 set m16 (mr11 m) i0 val) |.
          | otherwise =
            | i1 == 12  = m with mr12 = (a2 set m16 (mr12 m) i0 val)
            | i1 == 13  = m with mr13 = (a2 set m16 (mr13 m) i0 val)
            | i1 == 14  = m with mr14 = (a2 set m16 (mr14 m) i0 val)
            | otherwise = m with mr15 = (a2 set m16 (mr15 m) i0 val)

fn :: a2 set m4096 A2M4096 Int Int Int Tensor[U64 * 8 * 16] => A2M4096
      a2 set m4096 m i2 i1 i0 val =
        | i2 < 8 =
          | i2 < 4 =
            | i2 == 0   = m with mp0 = (a2 set m256 (mp0 m) i1 i0 val)
            | i2 == 1   = m with mp1 = (a2 set m256 (mp1 m) i1 i0 val)
            | i2 == 2   = m with mp2 = (a2 set m256 (mp2 m) i1 i0 val)
            | otherwise = m with mp3 = (a2 set m256 (mp3 m) i1 i0 val) |.
          | otherwise =
            | i2 == 4   = m with mp4 = (a2 set m256 (mp4 m) i1 i0 val)
            | i2 == 5   = m with mp5 = (a2 set m256 (mp5 m) i1 i0 val)
            | i2 == 6   = m with mp6 = (a2 set m256 (mp6 m) i1 i0 val)
            | otherwise = m with mp7 = (a2 set m256 (mp7 m) i1 i0 val) |.
        | otherwise =
          | i2 < 12 =
            | i2 == 8   = m with mp8 = (a2 set m256 (mp8 m) i1 i0 val)
            | i2 == 9   = m with mp9 = (a2 set m256 (mp9 m) i1 i0 val)
            | i2 == 10  = m with mp10 = (a2 set m256 (mp10 m) i1 i0 val)
            | otherwise = m with mp11 = (a2 set m256 (mp11 m) i1 i0 val) |.
          | otherwise =
            | i2 == 12  = m with mp12 = (a2 set m256 (mp12 m) i1 i0 val)
            | i2 == 13  = m with mp13 = (a2 set m256 (mp13 m) i1 i0 val)
            | i2 == 14  = m with mp14 = (a2 set m256 (mp14 m) i1 i0 val)
            | otherwise = m with mp15 = (a2 set m256 (mp15 m) i1 i0 val)

fn :: a2 set mem A2Mem Int Int Int Int Tensor[U64 * 8 * 16] => A2Mem
      a2 set mem m i3 i2 i1 i0 val =
        | i3 < 8 =
          | i3 < 4 =
            | i3 == 0   = m with mt0 = (a2 set m4096 (mt0 m) i2 i1 i0 val)
            | i3 == 1   = m with mt1 = (a2 set m4096 (mt1 m) i2 i1 i0 val)
            | i3 == 2   = m with mt2 = (a2 set m4096 (mt2 m) i2 i1 i0 val)
            | otherwise = m with mt3 = (a2 set m4096 (mt3 m) i2 i1 i0 val) |.
          | otherwise =
            | i3 == 4   = m with mt4 = (a2 set m4096 (mt4 m) i2 i1 i0 val)
            | i3 == 5   = m with mt5 = (a2 set m4096 (mt5 m) i2 i1 i0 val)
            | i3 == 6   = m with mt6 = (a2 set m4096 (mt6 m) i2 i1 i0 val)
            | otherwise = m with mt7 = (a2 set m4096 (mt7 m) i2 i1 i0 val) |.
        | otherwise =
          | i3 < 12 =
            | i3 == 8   = m with mt8 = (a2 set m4096 (mt8 m) i2 i1 i0 val)
            | i3 == 9   = m with mt9 = (a2 set m4096 (mt9 m) i2 i1 i0 val)
            | i3 == 10  = m with mt10 = (a2 set m4096 (mt10 m) i2 i1 i0 val)
            | otherwise = m with mt11 = (a2 set m4096 (mt11 m) i2 i1 i0 val) |.
          | otherwise =
            | i3 == 12  = m with mt12 = (a2 set m4096 (mt12 m) i2 i1 i0 val)
            | i3 == 13  = m with mt13 = (a2 set m4096 (mt13 m) i2 i1 i0 val)
            | i3 == 14  = m with mt14 = (a2 set m4096 (mt14 m) i2 i1 i0 val)
            | otherwise = m with mt15 = (a2 set m4096 (mt15 m) i2 i1 i0 val)

fn :: a2 set blk A2Mem Int Tensor[U64 * 8 * 16] => A2Mem
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

fn :: a2 make addr blk A2Ctx Int => Tensor[U64 * 8 * 16]
      a2 make addr blk ctx ctr =
        zb            = Tensor[U64 * 8 * 16]
        in_blk        = Tensor[U64 * 8 * 16]
        in_blk_(0, 0) = r_pass ctx
        in_blk_(0, 1) = l_lane ctx
        in_blk_(0, 2) = s_slice ctx
        in_blk_(0, 3) = (p_lanes ctx) * (q_cols ctx)
        in_blk_(0, 4) = t_iters ctx
        in_blk_(0, 5) = 2
        in_blk_(0, 6) = ctr
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

fn :: a2 fill segment A2Mem A2Ctx Int Tensor[U64 * 8 * 16] => A2Mem
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
          prev_blk = a2 nth blk mem ((l * q) + prev_col)
          j_pair   =
            | data_ind  = a2 get blk8 addr2 (idx % 128)
            | otherwise = prev_blk_(0, 0)
          j1       = j_pair and 0xFFFFFFFF
          j2       = (j_pair shr 32) and 0xFFFFFFFF
          ref_lane =
            | r == 0 and s == 0 = l
            | otherwise         = j2 % p
          w_size   = a2 calc w size ctx idx (ref_lane == l)
          x_val    = (j1 * j1) shr 32
          y_val    = ((w_size and 0xFFFFFFFF) * x_val) shr 32
          zz       = w_size - 1 - y_val
          st_pos   =
            | r == 0    = 0
            | otherwise = ((s + 1) % 4) * sl
          ref_col  = (st_pos + zz) % q
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
          ctx_l   = ctx with l_lane = l
          start_j =
            | (r_pass ctx) == 0 and (s_slice ctx) == 0 = 2
            | otherwise                                = 0
          mem2    = a2 fill segment mem ctx_l start_j (a2 zero blk8)
          a2 run lanes mem2 ctx (l + 1)

fn :: a2 run slices A2Mem A2Ctx Int => A2Mem
      a2 run slices mem ctx s =
        | s >= 4 = mem
        | otherwise =
          ctx_s = ctx with s_slice = s
          mem2  = a2 run lanes mem ctx_s 0
          a2 run slices mem2 ctx (s + 1)

fn :: a2 run passes A2Mem A2Ctx Int => A2Mem
      a2 run passes mem ctx r =
        | r >= (t_iters ctx) = mem
        | otherwise =
          ctx_r = ctx with r_pass = r
          mem2  = a2 run slices mem ctx_r 0
          a2 run passes mem2 ctx (r + 1)

fn :: a2 bitxor final lanes A2Mem Int Int Int Tensor[U64 * 8 * 16] => Tensor[U64 * 8 * 16]
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
