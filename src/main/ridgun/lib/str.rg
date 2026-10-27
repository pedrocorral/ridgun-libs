-- ============================================================
-- src/main/ridgun/lib/str.rg
-- Pure-Ridgun String Manipulation Library (STR)
-- @implements FR-STR-001
-- @implements API-STR-001
-- @mitigates VUL-INPUT-001
-- ============================================================

module :: str

-- ── ASCII Classification Helpers ─────────────────────────────

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

-- ── Substring Search & Suffix / Prefix Predicates ────────────

fn :: str index of from String String Int Int Int => Int
      str index of from haystack needle pos hlen nlen =
        | nlen == 0           = 0
        | pos + nlen > hlen   = 0 - 1
        | (str slice haystack pos (pos + nlen)) == needle = pos
        | otherwise           = str index of from haystack needle (pos + 1) hlen nlen

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str index of String   String => Int
      str index of haystack needle =
        str index of from haystack needle 0 (str len haystack) (str len needle)

fn :: str ends with step String String Int Int => Bool
      str ends with step s suffix slen suflen =
        | suflen == 0   = True
        | suflen > slen = False
        | otherwise     = (str slice s (slen - suflen) slen) == suffix

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
        str slice s start len

fn :: str trim right String => String
      str trim right s      =
        len = str len s
        end = last non space end s len
        str slice s 0 end

fn :: str trim slice String Int Int => String
      str trim slice s start end =
        | start >= end = ""
        | otherwise    = str slice s start end

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

fn :: str replace step String String String Int => String
      str replace step s old new_s olen =
        | olen == 0 = s
        | otherwise = str join (str split s old) new_s

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str replace String String String => String
      str replace s      old    new_s  =
        str replace step s old new_s (str len old)

-- ── String Splitting & Joining ───────────────────────────────

fn :: str split chars String Int Int [String] => [String]
      str split chars s idx slen acc =
        | idx >= slen = acc
        | otherwise   = str split chars s (idx + 1) slen (acc :: [str slice s idx (idx + 1)])

fn :: str split onech loop String Int Int Int Int [String] => [String]
      str split onech loop s d0 pos slen seg_start acc =
        | pos >= slen = acc :: [str slice s seg_start slen]
        | (str char at s pos) == d0 =
          seg = str slice s seg_start pos
          str split onech loop s d0 (pos + 1) slen (pos + 1) (acc :: [seg])
        | otherwise =
          str split onech loop s d0 (pos + 1) slen seg_start acc

fn :: str split loop String String Int Int Int Int Int [String] => [String]
      str split loop s delim d0 pos slen dlen seg_start acc =
        | pos + dlen > slen = acc :: [str slice s seg_start slen]
        | (str char at s pos) == d0 and (str slice s pos (pos + dlen)) == delim =
          seg = str slice s seg_start pos
          str split loop s delim d0 (pos + dlen) slen dlen (pos + dlen) (acc :: [seg])
        | otherwise =
          str split loop s delim d0 (pos + 1) slen dlen seg_start acc

fn :: str split step String String Int Int => [String]
      str split step s delim slen dlen =
        | dlen == 0 = str split chars s 0 slen []
        | dlen == 1 = str split onech loop s (str char at delim 0) 0 slen 0 []
        | otherwise = str split loop s delim (str char at delim 0) 0 slen dlen 0 []

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str split String String => [String]
      str split s      delim  =
        str split step s delim (str len s) (str len delim)

fn :: str join pair step [String] String [String] => [String]
      str join pair step []         _   acc =  acc
      str join pair step (a:[])     _   acc =  acc :: [a]
      str join pair step (a:b:rest) sep acc =
        str join pair step rest sep (acc :: [a + sep + b])

fn :: str join pairs [String] String => String
      str join pairs []       _   =  ""
      str join pairs (x:[])   _   =  x
      str join pairs (x:y:[]) sep =  x + sep + y
      str join pairs xs       sep =
        str join pairs (str join pair step xs sep []) sep

fn :: str join [String] String => String
      str join xs       sep    =  str join pairs xs sep

-- ── ASCII Case Conversion ────────────────────────────────────

fn :: upper char code String Int Int => String
      upper char code s idx c =
        | is ascii lower c = char from code (c - 32)
        | otherwise        = str slice s idx (idx + 1)

fn :: upper char slice String Int => String
      upper char slice s      idx =
        upper char code s idx (str char at s idx)

fn :: str to upper range String Int Int => String
      str to upper range s start end =
        | start >= end     = ""
        | end - start == 1 = upper char slice s start
        | end - start == 2 = (upper char slice s start) + (upper char slice s (start + 1))
        | otherwise        =
          mid = (start + end) shr 1
          (str to upper range s start mid) + (str to upper range s mid end)

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str to upper String => String
      str to upper s      =  str to upper range s 0 (str len s)

fn :: lower char code String Int Int => String
      lower char code s idx c =
        | is ascii upper c = char from code (c + 32)
        | otherwise        = str slice s idx (idx + 1)

fn :: lower char slice String Int => String
      lower char slice s      idx =
        lower char code s idx (str char at s idx)

fn :: str to lower range String Int Int => String
      str to lower range s start end =
        | start >= end     = ""
        | end - start == 1 = lower char slice s start
        | end - start == 2 = (lower char slice s start) + (lower char slice s (start + 1))
        | otherwise        =
          mid = (start + end) shr 1
          (str to lower range s start mid) + (str to lower range s mid end)

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str to lower String => String
      str to lower s      =  str to lower range s 0 (str len s)

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
        | otherwise             = str slice pad_ch 0 1

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
