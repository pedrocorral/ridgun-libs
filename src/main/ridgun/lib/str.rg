-- ============================================================
-- src/main/ridgun/lib/str.rg
-- Pure-Ridgun String Manipulation Library (STR)
-- @implements FR-STR-001
-- @implements API-STR-001
-- @mitigates VUL-INPUT-001
-- ============================================================

-- ── ASCII Classification & Zero-Syscall Raw Byte Helpers ─────

fn :: is ascii space Int  => Bool
      is ascii space code =
        code == 32 or code == 9 or code == 10 or code == 13

fn :: is ascii lower Int  => Bool
      is ascii lower code =  code >= 97 and code <= 122

fn :: is ascii upper Int  => Bool
      is ascii upper code =  code >= 65 and code <= 90

fn :: to upper code Int  => Int
      to upper code code =
        | is ascii lower code = code - 32
        | otherwise           = code

fn :: to lower code Int  => Int
      to lower code code =
        | is ascii upper code = code + 32
        | otherwise           = code

fn :: s raw byte ub Int => String
      s raw byte ub ub  =
        | ub >= 1 and ub <= 127 = char from code ub
        | ub == 0 = str slice (sha256 raw "00679") 0 1
        | otherwise =
          idx = (ub - 128) * 5
          lut = "0056400101002080010000179000010024100109003430040100361007870009100353001870030400471000870020200071002360012501171004140236900275001810016001398004440080400017005250027000314001400024700004006350015700183005940027600207007720028400601003400038000839006850084900617003060113500277000320006900483000580019200151008700008500193000100057000070002880002600326006460038800018009190028900103006000043900073011700038900628007210077300074004740006000041001410019900066003680001900383001730005700558000670024500065002030031900000008250001100128001360034900030003750039600228002380008400618005900031800062001770087900076002570009600034002200001600161"
          str slice (sha256 raw (str slice lut idx (idx + 5))) 0 1

-- ── 4-Level Tail-Recursive String & List Builders ────────────

fn :: s sb append3 String String => String String String String
      s sb append3 n2 c3 =
        | (str len n2) < 65536 = ("", "", n2, c3)
        | otherwise            = ("", "", "", c3 + n2)

fn :: s sb append2 String String String => String String String String
      s sb append2 n1 c2 c3 =
        | (str len n1) < 8192 = ("", n1, c2, c3)
        | otherwise           = s sb append3 (c2 + n1) c3

fn :: s sb append1 String String String String => String String String String
      s sb append1 n0 c1 c2 c3 =
        | (str len n0) < 512 = (n0, c1, c2, c3)
        | otherwise          = s sb append2 (c1 + n0) c2 c3

fn :: s sb append String String String String String => String String String String
      s sb append chunk c0 c1 c2 c3 =
        s sb append1 (c0 + chunk) c1 c2 c3

fn :: s sb finish String String String String => String
      s sb finish c0 c1 c2 c3 =  ((c3 + c2) + c1) + c0

fn :: s lb append2 [String] [String] Int => [String] [String] [String] Int
      s lb append2 n1 l2 cnt =
        | (cnt % 1024) == 0 = ([], [], l2 :: n1, cnt)
        | otherwise         = ([], n1, l2, cnt)

fn :: s lb append1 [String] [String] [String] Int => [String] [String] [String] Int
      s lb append1 n0 l1 l2 cnt =
        | (cnt % 32) == 0 = s lb append2 (l1 :: n0) l2 cnt
        | otherwise       = (n0, l1, l2, cnt)

fn :: s lb append String [String] [String] [String] Int => [String] [String] [String] Int
      s lb append item l0 l1 l2 cnt =
        s lb append1 (l0 :: [item]) l1 l2 (cnt + 1)

fn :: s lb finish [String] [String] [String] => [String]
      s lb finish l0 l1 l2 =  l2 :: (l1 :: l0)

-- ── Binary-Safe Substring Slicing ────────────────────────────

fn :: s scan ascii end String Int Int => Int
      s scan ascii end s idx end_idx =
        | idx >= end_idx = end_idx
        | (str char at s idx) == 0 or (str char at s idx) >= 128 = idx
        | otherwise = s scan ascii end s (idx + 1) end_idx

fn :: s byte slice step String Int Int Int String String String String => String
      s byte slice step s idx run_end end_idx c0 c1 c2 c3 =
        | run_end >= end_idx = s sb finish (c0 + (str slice s idx end_idx)) c1 c2 c3
        | otherwise =
          piece = (str slice s idx run_end) + (s raw byte ub (((str char at s run_end) % 256 + 256) % 256))
          n0, n1, n2, n3 = s sb append piece c0 c1 c2 c3
          s byte slice loop s (run_end + 1) end_idx n0 n1 n2 n3

fn :: s byte slice loop String Int Int String String String String => String
      s byte slice loop s idx end_idx c0 c1 c2 c3 =
        | idx >= end_idx = s sb finish c0 c1 c2 c3
        | otherwise      = s byte slice step s idx (s scan ascii end s idx end_idx) end_idx c0 c1 c2 c3

fn :: s byte prev String Int => Int
      s byte prev s start =
        | start == 0 = 0
        | otherwise  = ((str char at s (start - 1)) % 256 + 256) % 256

fn :: s byte at end String Int => Int
      s byte at end s end_idx =
        | end_idx >= (str len s) = 0
        | otherwise              = ((str char at s end_idx) % 256 + 256) % 256

fn :: s byte slice check String Int Int Int Int => String
      s byte slice check s start end_idx b_prev b_end =
        | b_prev < 128 and (b_end < 128 or b_end >= 192) = str slice s start end_idx
        | otherwise = s byte slice loop s start end_idx "" "" "" ""

fn :: s byte slice String Int Int => String
      s byte slice s start end_idx =
        | start >= end_idx = ""
        | start == 0 and end_idx >= (str len s) = s
        | otherwise = s byte slice check s start end_idx (s byte prev s start) (s byte at end s end_idx)

-- ── Substring Search & Suffix / Prefix Predicates ────────────

fn :: s match needle at String String Int Int Int => Bool
      s match needle at haystack needle pos k nlen =
        | k >= nlen = True
        | (str char at haystack (pos + k)) == (str char at needle k) =
          s match needle at haystack needle pos (k + 1) nlen
        | otherwise = False

fn :: str index of from String String Int Int Int Int => Int
      str index of from haystack needle pos hlen nlen n0 =
        | pos + nlen > hlen = 0 - 1
        | (pos + 4096 + nlen) <= hlen and (not (str contains (str slice haystack pos (pos + 4096 + nlen - 1)) needle)) =
          str index of from haystack needle (pos + 4096) hlen nlen n0
        | (str char at haystack pos) == n0 and (s match needle at haystack needle pos 1 nlen) = pos
        | otherwise = str index of from haystack needle (pos + 1) hlen nlen n0

fn :: str index of step String String Int Int => Int
      str index of step haystack needle hlen nlen =
        | nlen == 0 = 0
        | nlen > hlen = 0 - 1
        | not (str contains haystack needle) = 0 - 1
        | otherwise = str index of from haystack needle 0 hlen nlen (str char at needle 0)

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str index of String   String => Int
      str index of haystack needle =
        str index of step haystack needle (str len haystack) (str len needle)

fn :: str ends with step String String Int Int => Bool
      str ends with step s suffix slen suflen =
        | suflen == 0   = True
        | suflen > slen = False
        | otherwise     = s match needle at s suffix (slen - suflen) 0 suflen

fn :: str ends with String String => Bool
      str ends with s      suffix =
        str ends with step s suffix (str len s) (str len suffix)

fn :: str is empty String => Bool
      str is empty s      =  (str len s) == 0

-- ── Whitespace Trimming ──────────────────────────────────────

fn :: first non space idx String Int Int => Int
      first non space idx s idx len =
        | idx >= len                         = len
        | is ascii space (str char at s idx) = first non space idx s (idx + 1) len
        | otherwise                          = idx

fn :: last non space end String Int => Int
      last non space end s end =
        | end <= 0                                 = 0
        | is ascii space (str char at s (end - 1)) = last non space end s (end - 1)
        | otherwise                                = end

fn :: str trim left String => String
      str trim left s      =
        len   = str len s
        start = first non space idx s 0 len
        s byte slice s start len

fn :: str trim right String => String
      str trim right s      =
        len = str len s
        end = last non space end s len
        s byte slice s 0 end

fn :: str trim slice String Int Int => String
      str trim slice s start end =
        | start >= end = ""
        | otherwise    = s byte slice s start end

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str trim String => String
      str trim s      =
        len   = str len s
        start = first non space idx s 0 len
        end   = last non space end s len
        str trim slice s start end

fn :: str is blank String => Bool
      str is blank s      =  (str len (str trim s)) == 0

-- ── Substring Replacement ────────────────────────────────────

fn :: str replace loop String String String Int Int Int Int Int String String String String => String
      str replace loop s old new_s pos seg_start slen olen o0 c0 c1 c2 c3 =
        | pos + olen > slen =
          s sb finish (c0 + (s byte slice s seg_start slen)) c1 c2 c3
        | (pos + 4096 + olen) <= slen and (not (str contains (str slice s pos (pos + 4096 + olen - 1)) old)) =
          str replace loop s old new_s (pos + 4096) seg_start slen olen o0 c0 c1 c2 c3
        | (str char at s pos) == o0 and (s match needle at s old pos 1 olen) =
          piece = (s byte slice s seg_start pos) + new_s
          n0, n1, n2, n3 = s sb append piece c0 c1 c2 c3
          next_p = pos + olen
          str replace loop s old new_s next_p next_p slen olen o0 n0 n1 n2 n3
        | otherwise =
          str replace loop s old new_s (pos + 1) seg_start slen olen o0 c0 c1 c2 c3

fn :: str replace step String String String Int => String
      str replace step s old new_s olen =
        | olen == 0 = s
        | not (str contains s old) = s
        | otherwise = str replace loop s old new_s 0 0 (str len s) olen (str char at old 0) "" "" "" ""

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str replace String String String => String
      str replace s      old    new_s  =
        str replace step s old new_s (str len old)

-- ── String Splitting & Joining ───────────────────────────────

fn :: str split chars String Int Int [String] [String] [String] Int => [String]
      str split chars s idx slen l0 l1 l2 cnt =
        | idx >= slen = s lb finish l0 l1 l2
        | otherwise   =
          n0, n1, n2, ncnt = s lb append (s byte slice s idx (idx + 1)) l0 l1 l2 cnt
          str split chars s (idx + 1) slen n0 n1 n2 ncnt

fn :: str split loop String String Int Int Int Int Int [String] [String] [String] Int => [String]
      str split loop s delim pos slen dlen d0 seg_start l0 l1 l2 cnt =
        | pos + dlen > slen =
          n0, n1, n2, _ = s lb append (s byte slice s seg_start slen) l0 l1 l2 cnt
          s lb finish n0 n1 n2
        | (pos + 4096 + dlen) <= slen and (not (str contains (str slice s pos (pos + 4096 + dlen - 1)) delim)) =
          str split loop s delim (pos + 4096) slen dlen d0 seg_start l0 l1 l2 cnt
        | (str char at s pos) == d0 and (s match needle at s delim pos 1 dlen) =
          seg = s byte slice s seg_start pos
          n0, n1, n2, ncnt = s lb append seg l0 l1 l2 cnt
          next_p = pos + dlen
          str split loop s delim next_p slen dlen d0 next_p n0 n1 n2 ncnt
        | otherwise =
          str split loop s delim (pos + 1) slen dlen d0 seg_start l0 l1 l2 cnt

fn :: str split step String String Int Int => [String]
      str split step s delim slen dlen =
        | dlen == 0 = str split chars s 0 slen [] [] [] 0
        | not (str contains s delim) = [s]
        | otherwise = str split loop s delim 0 slen dlen (str char at delim 0) 0 [] [] [] 0

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str split String String => [String]
      str split s      delim  =
        str split step s delim (str len s) (str len delim)

fn :: str join loop [String] String String String String String => String
      str join loop []     _   c0 c1 c2 c3 =  s sb finish c0 c1 c2 c3
      str join loop (x:xs) sep c0 c1 c2 c3 =
        n0, n1, n2, n3 = s sb append (sep + x) c0 c1 c2 c3
        str join loop xs sep n0 n1 n2 n3

fn :: str join [String] String => String
      str join []       _      =  ""
      str join (x:xs)   sep    =  str join loop xs sep x "" "" ""

-- ── ASCII Case Conversion ────────────────────────────────────

fn :: s scan no lower String Int Int => Int
      s scan no lower s idx slen =
        | idx >= slen = idx
        | is ascii lower (str char at s idx) = idx
        | otherwise = s scan no lower s (idx + 1) slen

fn :: str to upper step String Int Int Int String String String String => String
      str to upper step s idx end_run slen c0 c1 c2 c3 =
        | end_run >= slen =
          | idx == 0  = s
          | otherwise = s sb finish (c0 + (s byte slice s idx slen)) c1 c2 c3 |.
        | otherwise =
          up_ch = char from code ((str char at s end_run) - 32)
          piece = (s byte slice s idx end_run) + up_ch
          n0, n1, n2, n3 = s sb append piece c0 c1 c2 c3
          str to upper loop s (end_run + 1) slen n0 n1 n2 n3

fn :: str to upper loop String Int Int String String String String => String
      str to upper loop s idx slen c0 c1 c2 c3 =
        | idx >= slen = s sb finish c0 c1 c2 c3
        | otherwise   = str to upper step s idx (s scan no lower s idx slen) slen c0 c1 c2 c3

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str to upper String => String
      str to upper s      =  str to upper loop s 0 (str len s) "" "" "" ""

fn :: s scan no upper String Int Int => Int
      s scan no upper s idx slen =
        | idx >= slen = idx
        | is ascii upper (str char at s idx) = idx
        | otherwise = s scan no upper s (idx + 1) slen

fn :: str to lower step String Int Int Int String String String String => String
      str to lower step s idx end_run slen c0 c1 c2 c3 =
        | end_run >= slen =
          | idx == 0  = s
          | otherwise = s sb finish (c0 + (s byte slice s idx slen)) c1 c2 c3 |.
        | otherwise =
          lo_ch = char from code ((str char at s end_run) + 32)
          piece = (s byte slice s idx end_run) + lo_ch
          n0, n1, n2, n3 = s sb append piece c0 c1 c2 c3
          str to lower loop s (end_run + 1) slen n0 n1 n2 n3

fn :: str to lower loop String Int Int String String String String => String
      str to lower loop s idx slen c0 c1 c2 c3 =
        | idx >= slen = s sb finish c0 c1 c2 c3
        | otherwise   = str to lower step s idx (s scan no upper s idx slen) slen c0 c1 c2 c3

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str to lower String => String
      str to lower s      =  str to lower loop s 0 (str len s) "" "" "" ""

-- ── Repetition & Padding ─────────────────────────────────────

-- @mitigates VUL-INPUT-001
fn :: str repeat loop String Int String => String
      str repeat loop cur n acc =
        | n <= 0       = acc
        | (n % 2) == 1 = str repeat loop (cur + cur) (n / 2) (acc + cur)
        | otherwise    = str repeat loop (cur + cur) (n / 2) acc

fn :: str repeat String Int => String
      str repeat s      n   =
        | n <= 0 or (str len s) == 0 = ""
        | otherwise                  = str repeat loop s n ""

fn :: pad fill unit String => String
      pad fill unit pad_ch =
        | (str len pad_ch) == 0 = " "
        | otherwise             = s byte slice pad_ch 0 1

fn :: str pad left step String Int String Int => String
      str pad left step s width pad_ch slen =
        | slen >= width = s
        | otherwise     = (str repeat (pad fill unit pad_ch) (width - slen)) + s

fn :: str pad left String Int String => String
      str pad left s width pad_ch =
        str pad left step s width pad_ch (str len s)

fn :: str pad right step String Int String Int => String
      str pad right step s width pad_ch slen =
        | slen >= width = s
        | otherwise     = s + (str repeat (pad fill unit pad_ch) (width - slen))

fn :: str pad right String Int String => String
      str pad right s width pad_ch =
        str pad right step s width pad_ch (str len s)
