-- ============================================================
-- src/main/ridgun/lib/uuid.rg
-- Pure-Ridgun RFC 9562 UUIDv4/UUIDv7, FNV-1a/Adler-32/CRC-32 Checksums & Seeded PRNG Library (UUID)
-- @implements FR-UUID-001
-- @implements API-UUID-001
-- @mitigates VUL-INPUT-001
-- ============================================================

fn :: uu hex lut Int => String
      uu hex lut _   =  "0123456789abcdef"

fn :: uu u32 Int => Int
      uu u32 x   =  ((x % 4294967296) + 4294967296) % 4294967296

fn :: uu bxor loop Int Int Int Int => Int
      uu bxor loop a b bit acc =
        | a == 0 and b == 0 = acc
        | otherwise =
          ba = a % 2
          bb = b % 2
          d  = (ba + bb) % 2
          uu bxor loop (a / 2) (b / 2) (bit * 2) (acc + (d * bit))

fn :: uu bxor32 Int Int => Int
      uu bxor32 a   b   =  uu bxor loop (uu u32 a) (uu u32 b) 1 0

-- ── Non-Cryptographic Checksums (`fnv1a_32`, `adler32`, `crc32`) ─

fn :: uu fnv loop String Int Int Int => Int
      uu fnv loop s idx len h =
        | idx >= len = h
        | otherwise =
          x = uu bxor32 h (str_char_at s idx)
          uu fnv loop s (idx + 1) len (uu u32 (x * 16777619))

-- @implements FR-UUID-001
-- @implements API-UUID-001
fn :: fnv1a 32 String => Int
      fnv1a 32 s      =  uu fnv loop s 0 (str_len s) 2166136261

fn :: uu adler loop String Int Int Int Int => Int
      uu adler loop s idx len a b =
        | idx >= len = (b * 65536) + a
        | otherwise =
          na = (a + (str_char_at s idx)) % 65521
          nb = (b + na) % 65521
          uu adler loop s (idx + 1) len na nb

-- @implements FR-UUID-001
-- @implements API-UUID-001
fn :: adler32 String => Int
      adler32 s      =  uu adler loop s 0 (str_len s) 1 0

fn :: uu crc bit loop Int Int => Int
      uu crc bit loop crc rem =
        | rem <= 0       = crc
        | (crc % 2) == 1 = uu crc bit loop (uu bxor32 (crc / 2) 3988292384) (rem - 1)
        | otherwise      = uu crc bit loop (crc / 2) (rem - 1)

fn :: uu crc byte loop String Int Int Int => Int
      uu crc byte loop s idx len crc =
        | idx >= len = uu bxor32 crc 4294967295
        | otherwise =
          c1 = uu bxor32 crc (str_char_at s idx)
          uu crc byte loop s (idx + 1) len (uu crc bit loop c1 8)

-- @implements FR-UUID-001
-- @implements API-UUID-001
fn :: crc32 String => Int
      crc32 s      =  uu crc byte loop s 0 (str_len s) 4294967295

-- ── Deterministic Seeded 31-Bit PRNG (`prng_next`, `prng_range`) ─

fn :: uu abs Int => Int
      uu abs x   =
        | x < 0     = 0 - x
        | otherwise = x

-- @implements FR-UUID-001
-- @implements API-UUID-001
fn :: prng next Int  => Int
      prng next seed =
        s0 = (uu abs seed) % 2147483647
        (((s0 * 1103515245) + 12345) % 2147483647)

fn :: uu prng range step Int Int Int => (Int, Int)
      uu prng range step ns lo hi =
        | hi <= lo  = (ns, lo)
        | otherwise = (ns, lo + (ns % ((hi - lo) + 1)))

-- @implements FR-UUID-001
-- @implements API-UUID-001
-- @mitigates VUL-INPUT-001
fn :: prng range Int  Int Int => (Int, Int)
      prng range seed lo  hi  =  uu prng range step (prng next seed) lo hi

-- ── RFC 9562 UUIDv4 & UUIDv7 Generation & Validation ─────────

fn :: uu lstat exists (Bool, String, Int, Int, Int, String, String, Int, String) => Bool
      uu lstat exists (exists, _, _, _, _, _, _, _, _) = exists

fn :: uu next seq Int => Int
      uu next seq pid =
        p = "/tmp/rg_uuid_seq_{pid}.cnt"
        n =
          | uu lstat exists (file_lstat p) = (str_to_int (read_file p)) + 1
          | otherwise                      = 1 |.
        _ = write_file p "{n}"
        n

fn :: uu hex val Int => Int
      uu hex val c   =
        | c >= 48 and c <= 57  = c - 48
        | c >= 65 and c <= 70  = (c - 65) + 10
        | c >= 97 and c <= 102 = (c - 97) + 10
        | otherwise            = 0 - 1

fn :: uu variant char String => String
      uu variant char hex1   =
        v   = uu hex val (str_char_at hex1 0)
        idx = 8 + (v % 4)
        tbl = uu hex lut 0
        str_slice tbl idx (idx + 1)

-- @implements FR-UUID-001
-- @implements API-UUID-001
fn :: uuid v4 => String
      uuid v4 =
        pid = sys_getpid
        ms  = sys_time_ms
        seq = uu next seq pid
        h   = sha256_str "uuid_v4:{pid}:{ms}:{seq}"
        p1  = str_slice h 0 8
        p2  = str_slice h 8 12
        p3  = "4" + (str_slice h 13 16)
        p4  = (uu variant char (str_slice h 16 17)) + (str_slice h 17 20)
        p5  = str_slice h 20 32
        "{p1}-{p2}-{p3}-{p4}-{p5}"

fn :: uu hex48 loop Int Int => String
      uu hex48 loop val rem =
        | rem <= 0 = ""
        | otherwise =
          nib = ((val % 16) + 16) % 16
          tbl = uu hex lut 0
          (uu hex48 loop (val / 16) (rem - 1)) + (str_slice tbl nib (nib + 1))

-- @implements FR-UUID-001
-- @implements API-UUID-001
fn :: uuid v7 at Int   => String
      uuid v7 at ts_ms =
        eff_ts = uu abs ts_ms
        ts_hex = uu hex48 loop eff_ts 12
        pid    = sys_getpid
        seq    = uu next seq pid
        h      = sha256_str "uuid_v7:{pid}:{eff_ts}:{seq}"
        p1     = str_slice ts_hex 0 8
        p2     = str_slice ts_hex 8 12
        p3     = "7" + (str_slice h 0 3)
        p4     = (uu variant char (str_slice h 3 4)) + (str_slice h 4 7)
        p5     = str_slice h 7 19
        "{p1}-{p2}-{p3}-{p4}-{p5}"

-- @implements FR-UUID-001
-- @implements API-UUID-001
fn :: uuid v7 => String
      uuid v7 =  uuid v7 at (sys_time_ms)

fn :: uu is hex range String Int Int => Bool
      uu is hex range s idx end_idx =
        | idx >= end_idx                       = True
        | (uu hex val (str_char_at s idx)) < 0 = False
        | otherwise                            = uu is hex range s (idx + 1) end_idx

-- @implements FR-UUID-001
-- @implements API-UUID-001
-- @mitigates VUL-INPUT-001
fn :: uuid is valid String => Bool
      uuid is valid u      =
        | (str_len u) != 36               = False
        | (str_char_at u 8) != 45         = False
        | (str_char_at u 13) != 45        = False
        | (str_char_at u 18) != 45        = False
        | (str_char_at u 23) != 45        = False
        | not (uu is hex range u 0 8)     = False
        | not (uu is hex range u 9 13)    = False
        | not (uu is hex range u 14 18)   = False
        | not (uu is hex range u 19 23)   = False
        | not (uu is hex range u 24 36)   = False
        | otherwise =
          var_nib = uu hex val (str_char_at u 19)
          (var_nib >= 8) and (var_nib <= 11)

-- @implements FR-UUID-001
-- @implements API-UUID-001
fn :: uuid version String => Int
      uuid version u      =
        | not (uuid is valid u) = 0 - 1
        | otherwise             = uu hex val (str_char_at u 14)
