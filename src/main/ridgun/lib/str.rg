-- ============================================================
-- src/main/ridgun/lib/str.rg
-- Pure-Ridgun String Manipulation Library (STR)
-- @implements FR-STR-001
-- @implements API-STR-001
-- @mitigates VUL-INPUT-001
-- ============================================================

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
        | (str_slice haystack pos (pos + nlen)) == needle = pos
        | otherwise           = str index of from haystack needle (pos + 1) hlen nlen

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str index of String   String => Int
      str index of haystack needle =
        str index of from haystack needle 0 (str_len haystack) (str_len needle)

fn :: str ends with step String String Int Int => Bool
      str ends with step s suffix slen suflen =
        | suflen == 0   = True
        | suflen > slen = False
        | otherwise     = (str_slice s (slen - suflen) slen) == suffix

fn :: str ends with String String => Bool
      str ends with s      suffix =
        str ends with step s suffix (str_len s) (str_len suffix)

fn :: str is empty String => Bool
      str is empty s      =  (str_len s) == 0

-- ── Whitespace Trimming ──────────────────────────────────────

fn :: first non space idx String Int Int => Int
      first non space idx s idx len =
        | idx >= len                         = len
        | is ascii space (str_char_at s idx) = first non space idx s (idx + 1) len
        | otherwise                          = idx

fn :: last non space end String Int => Int
      last non space end s end =
        | end <= 0                                 = 0
        | is ascii space (str_char_at s (end - 1)) = last non space end s (end - 1)
        | otherwise                                = end

fn :: str trim left String => String
      str trim left s      =
        len   = str_len s
        start = first non space idx s 0 len
        str_slice s start len

fn :: str trim right String => String
      str trim right s      =
        len = str_len s
        end = last non space end s len
        str_slice s 0 end

fn :: str trim slice String Int Int => String
      str trim slice s start end =
        | start >= end = ""
        | otherwise    = str_slice s start end

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str trim String => String
      str trim s      =
        len   = str_len s
        start = first non space idx s 0 len
        end   = last non space end s len
        str trim slice s start end

fn :: str is blank String => Bool
      str is blank s      =  (str_len (str trim s)) == 0

-- ── Substring Replacement ────────────────────────────────────

fn :: str replace loop String String String Int Int Int String => String
      str replace loop s old new_s pos slen olen acc =
        | pos >= slen = acc
        | pos + olen <= slen and (str_slice s pos (pos + olen)) == old =
      str replace loop s old new_s (pos + olen) slen olen (acc + new_s)
        | otherwise =
          ch = str_slice s pos (pos + 1)
          str replace loop s old new_s (pos + 1) slen olen (acc + ch)

fn :: str replace step String String String Int => String
      str replace step s old new_s olen =
        | olen == 0 = s
        | otherwise = str replace loop s old new_s 0 (str_len s) olen ""

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str replace String String String => String
      str replace s      old    new_s  =
        str replace step s old new_s (str_len old)

-- ── String Splitting & Joining ───────────────────────────────

fn :: str split chars String Int Int => [String]
      str split chars s idx slen =
        | idx >= slen = []
        | otherwise   = [str_slice s idx (idx + 1)] :: (str split chars s (idx + 1) slen)

fn :: str split loop String String Int Int Int Int => [String]
      str split loop s delim pos slen dlen seg_start =
        | pos + dlen > slen = [str_slice s seg_start slen]
        | (str_slice s pos (pos + dlen)) == delim =
          seg = str_slice s seg_start pos
          [seg] :: (str split loop s delim (pos + dlen) slen dlen (pos + dlen))
        | otherwise =
          str split loop s delim (pos + 1) slen dlen seg_start

fn :: str split step String String Int Int => [String]
      str split step s delim slen dlen =
        | dlen == 0 = str split chars s 0 slen
        | otherwise = str split loop s delim 0 slen dlen 0

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str split String String => [String]
      str split s      delim  =
        str split step s delim (str_len s) (str_len delim)

fn :: str join tail [String] String => String
      str join tail []       _      =  ""
      str join tail (x:xs)   sep    =  sep + x + (str join tail xs sep)

fn :: str join [String] String => String
      str join []       _      =  ""
      str join (x:xs)   sep    =  x + (str join tail xs sep)

-- ── ASCII Case Conversion ────────────────────────────────────

fn :: upper char slice String Int => String
      upper char slice s      idx =
        | is ascii lower (str_char_at s idx) = char_from_code ((str_char_at s idx) - 32)
        | otherwise                          = str_slice s idx (idx + 1)

fn :: str to upper loop String Int Int String => String
      str to upper loop s idx slen acc =
        | idx >= slen = acc
        | otherwise   =
          up_s = upper char slice s idx
          str to upper loop s (idx + 1) slen (acc + up_s)

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str to upper String => String
      str to upper s      =  str to upper loop s 0 (str_len s) ""

fn :: lower char slice String Int => String
      lower char slice s      idx =
        | is ascii upper (str_char_at s idx) = char_from_code ((str_char_at s idx) + 32)
        | otherwise                          = str_slice s idx (idx + 1)

fn :: str to lower loop String Int Int String => String
      str to lower loop s idx slen acc =
        | idx >= slen = acc
        | otherwise   =
          lo_s = lower char slice s idx
          str to lower loop s (idx + 1) slen (acc + lo_s)

-- @implements FR-STR-001
-- @implements API-STR-001
fn :: str to lower String => String
      str to lower s      =  str to lower loop s 0 (str_len s) ""

-- ── Repetition & Padding ─────────────────────────────────────

-- @mitigates VUL-INPUT-001
fn :: str repeat loop String Int String => String
      str repeat loop s n acc =
        | n <= 0    = acc
        | otherwise = str repeat loop s (n - 1) (acc + s)

fn :: str repeat String Int => String
      str repeat s      n   =
        | n <= 0      = ""
        | n > 1048576 = str repeat loop s 1048576 ""
        | otherwise   = str repeat loop s n ""

fn :: pad fill unit String => String
      pad fill unit pad_ch =
        | (str_len pad_ch) == 0 = " "
        | otherwise             = str_slice pad_ch 0 1

fn :: str pad left step String Int String Int => String
      str pad left step s width pad_ch slen =
        | slen >= width = s
        | otherwise     = (str repeat (pad fill unit pad_ch) (width - slen)) + s

fn :: str pad left String Int String => String
      str pad left s width pad_ch =
        str pad left step s width pad_ch (str_len s)

fn :: str pad right step String Int String Int => String
      str pad right step s width pad_ch slen =
        | slen >= width = s
        | otherwise     = s + (str repeat (pad fill unit pad_ch) (width - slen))

fn :: str pad right String Int String => String
      str pad right s width pad_ch =
        str pad right step s width pad_ch (str_len s)
