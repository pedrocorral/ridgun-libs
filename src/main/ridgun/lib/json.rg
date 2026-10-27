-- ============================================================
-- src/main/ridgun/lib/json.rg
-- Pure-Ridgun Recursive RFC 8259 JSON AST Parser, Serializer, Pretty-Printer & Dot-Path Query Library (JSON)
-- @implements FR-JSON-001
-- @implements API-JSON-001
-- @implements DM-Json
-- @mitigates VUL-INPUT-001
-- ============================================================

module :: json

type JsonField = JsonField String JsonVal

type JsonVal = JsonNull | JsonBool Bool | JsonInt Int | JsonStr String | JsonArr [JsonVal] | JsonObj [JsonField]

type JsonRes = JsonOk JsonVal | JsonErr String

type JsonStep = JStepOk JsonVal Int | JStepErr String

type JsonArrStep = JArrOk [JsonVal] Int | JArrErr String

type JsonObjStep = JObjOk [JsonField] Int | JObjErr String

type JsonStrStep = JStrOk String Int | JStrErr String

-- ── Whitespace, Raw Byte & Character Helpers ─────────────────

fn :: j is ws Int => Bool
      j is ws c   =  c == 32 or c == 9 or c == 10 or c == 13

fn :: j is digit Int => Bool
      j is digit c   =  c >= 48 and c <= 57

fn :: j skip ws String Int Int => Int
      j skip ws s      pos len =
        | pos >= len                    = len
        | j is ws (str char at s pos) = j skip ws s (pos + 1) len
        | otherwise                     = pos

fn :: j spaces loop Int String => String
      j spaces loop n acc =
        | n <= 0    = acc
        | otherwise = j spaces loop (n - 1) (acc + " ")

fn :: j spaces Int => String
      j spaces n   =  j spaces loop n ""

fn :: j raw byte ub Int => String
      j raw byte ub ub  =
        | ub >= 1 and ub <= 127 = char from code ub
        | ub == 0 = str slice (sha256 raw "00679") 0 1
        | otherwise =
          idx = (ub - 128) * 5
          lut = "0056400101002080010000179000010024100109003430040100361007870009100353001870030400471000870020200071002360012501171004140236900275001810016001398004440080400017005250027000314001400024700004006350015700183005940027600207007720028400601003400038000839006850084900617003060113500277000320006900483000580019200151008700008500193000100057000070002880002600326006460038800018009190028900103006000043900073011700038900628007210077300074004740006000041001410019900066003680001900383001730005700558000670024500065002030031900000008250001100128001360034900030003750039600228002380008400618005900031800062001770087900076002570009600034002200001600161"
          str slice (sha256 raw (str slice lut idx (idx + 5))) 0 1

fn :: j raw byte Int => String
      j raw byte b   =  j raw byte ub (((b % 256) + 256) % 256)

fn :: j sb append3 String String => String String String String
      j sb append3 n2 c3 =
        | (str len n2) < 65536 = ("", "", n2, c3)
        | otherwise            = ("", "", "", c3 + n2)

fn :: j sb append2 String String String => String String String String
      j sb append2 n1 c2 c3 =
        | (str len n1) < 8192 = ("", n1, c2, c3)
        | otherwise           = j sb append3 (c2 + n1) c3

fn :: j sb append1 String String String String => String String String String
      j sb append1 n0 c1 c2 c3 =
        | (str len n0) < 512 = (n0, c1, c2, c3)
        | otherwise          = j sb append2 (c1 + n0) c2 c3

fn :: j sb append String String String String String => String String String String
      j sb append chunk c0 c1 c2 c3 =
        j sb append1 (c0 + chunk) c1 c2 c3

fn :: j sb finish String String String String => String
      j sb finish c0 c1 c2 c3 =  ((c3 + c2) + c1) + c0

fn :: j vlb append2 [JsonVal] [JsonVal] Int => [JsonVal] [JsonVal] [JsonVal] Int
      j vlb append2 n1 l2 cnt =
        | (cnt % 1024) == 0 = ([], [], l2 :: n1, cnt)
        | otherwise         = ([], n1, l2, cnt)

fn :: j vlb append1 [JsonVal] [JsonVal] [JsonVal] Int => [JsonVal] [JsonVal] [JsonVal] Int
      j vlb append1 n0 l1 l2 cnt =
        | (cnt % 32) == 0 = j vlb append2 (l1 :: n0) l2 cnt
        | otherwise       = (n0, l1, l2, cnt)

fn :: j vlb append JsonVal [JsonVal] [JsonVal] [JsonVal] Int => [JsonVal] [JsonVal] [JsonVal] Int
      j vlb append item l0 l1 l2 cnt =
        j vlb append1 (l0 :: [item]) l1 l2 (cnt + 1)

fn :: j vlb finish [JsonVal] [JsonVal] [JsonVal] => [JsonVal]
      j vlb finish l0 l1 l2 =  l2 :: (l1 :: l0)

fn :: j flb append2 [JsonField] [JsonField] Int => [JsonField] [JsonField] [JsonField] Int
      j flb append2 n1 l2 cnt =
        | (cnt % 1024) == 0 = ([], [], l2 :: n1, cnt)
        | otherwise         = ([], n1, l2, cnt)

fn :: j flb append1 [JsonField] [JsonField] [JsonField] Int => [JsonField] [JsonField] [JsonField] Int
      j flb append1 n0 l1 l2 cnt =
        | (cnt % 32) == 0 = j flb append2 (l1 :: n0) l2 cnt
        | otherwise       = (n0, l1, l2, cnt)

fn :: j flb append JsonField [JsonField] [JsonField] [JsonField] Int => [JsonField] [JsonField] [JsonField] Int
      j flb append item l0 l1 l2 cnt =
        j flb append1 (l0 :: [item]) l1 l2 (cnt + 1)

fn :: j flb finish [JsonField] [JsonField] [JsonField] => [JsonField]
      j flb finish l0 l1 l2 =  l2 :: (l1 :: l0)

-- ── RFC 8259 §7 Unicode Escape (\uXXXX + UTF-16 Surrogates) & String Escaping ──

fn :: j hex digit Int => Int
      j hex digit c   =
        | c >= 48 and c <= 57  = c - 48
        | c >= 97 and c <= 102 = (c - 97) + 10
        | c >= 65 and c <= 70  = (c - 65) + 10
        | otherwise            = 0 - 1

fn :: j combine hex4 Int Int Int Int => Int
      j combine hex4 d0 d1 d2 d3 =
        | d0 < 0 or d1 < 0 or d2 < 0 or d3 < 0 = 0 - 1
        | otherwise                            = (((d0 * 16) + d1) * 256) + (d2 * 16) + d3

fn :: j parse hex4 String Int Int => Int
      j parse hex4 s      pos len =
        | (pos + 4) > len = 0 - 1
        | otherwise       =
          j combine hex4 (j hex digit (str char at s pos)) (j hex digit (str char at s (pos + 1))) (j hex digit (str char at s (pos + 2))) (j hex digit (str char at s (pos + 3)))

fn :: j utf8 from cp Int => String
      j utf8 from cp cp  =
        | cp <= 127 = j raw byte cp
        | cp <= 2047 =
          b0 = 192 + (cp / 64)
          b1 = 128 + (cp % 64)
          (j raw byte b0) + (j raw byte b1)
        | cp <= 65535 =
          b0 = 224 + (cp / 4096)
          b1 = 128 + ((cp / 64) % 64)
          b2 = 128 + (cp % 64)
          (j raw byte b0) + (j raw byte b1) + (j raw byte b2)
        | otherwise =
          b0 = 240 + (cp / 262144)
          b1 = 128 + ((cp / 4096) % 64)
          b2 = 128 + ((cp / 64) % 64)
          b3 = 128 + (cp % 64)
          (j raw byte b0) + (j raw byte b1) + (j raw byte b2) + (j raw byte b3)

fn :: j hex2 lower Int => String
      j hex2 lower b   =
        tbl = "0123456789abcdef"
        hi  = (b / 16) % 16
        lo  = b % 16
        (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1))

fn :: j esc special Int => String
      j esc special c   =
        | c == 34   = (char from code 92) + (char from code 34)
        | c == 92   = (char from code 92) + (char from code 92)
        | c == 8    = (char from code 92) + "b"
        | c == 12   = (char from code 92) + "f"
        | c == 10   = (char from code 92) + "n"
        | c == 13   = (char from code 92) + "r"
        | c == 9    = (char from code 92) + "t"
        | c < 32    = (char from code 92) + "u00" + (j hex2 lower c)
        | otherwise = j raw byte ub c

fn :: j scan esc plain2 String Int Int Int => Int
      j scan esc plain2 s pos len c =
        | c >= 32 and c <= 127 and c != 34 and c != 92 = j scan esc plain s (pos + 1) len
        | otherwise                                    = pos

fn :: j scan esc plain String Int Int => Int
      j scan esc plain s pos len =
        | pos >= len = len
        | otherwise  = j scan esc plain2 s pos len (((str char at s pos) % 256 + 256) % 256)

fn :: j escape run String Int Int Int String String String String => String
      j escape run s pos run_end len c0 c1 c2 c3 =
        | run_end > pos =
          n0, n1, n2, n3 = j sb append (str slice s pos run_end) c0 c1 c2 c3
          j escape loop s run_end len n0 n1 n2 n3
        | otherwise =
          c = ((str char at s pos) % 256 + 256) % 256
          n0, n1, n2, n3 = j sb append (j esc special c) c0 c1 c2 c3
          j escape loop s (pos + 1) len n0 n1 n2 n3

fn :: j escape loop String Int Int String String String String => String
      j escape loop s pos len c0 c1 c2 c3 =
        | pos >= len = j sb finish c0 c1 c2 c3
        | otherwise  = j escape run s pos (j scan esc plain s pos len) len c0 c1 c2 c3

fn :: j escape str String => String
      j escape str s      =
        q = char from code 34
        q + (j escape loop s 0 (str len s) "" "" "" "") + q

fn :: j unescape simple Int => String
      j unescape simple 34  =  char from code 34
      j unescape simple 92  =  char from code 92
      j unescape simple 47  =  "/"
      j unescape simple 98  =  char from code 8
      j unescape simple 102 =  char from code 12
      j unescape simple 110 =  char from code 10
      j unescape simple 114 =  char from code 13
      j unescape simple 116 =  char from code 9
      j unescape simple _   =  ""

fn :: j finish surrogate String Int Int Int Int String String String String => JsonStrStep
      j finish surrogate s pos len hi_u lo_u c0 c1 c2 c3 =
        | lo_u < 56320 or lo_u > 57343 = JStrErr "invalid low UTF-16 surrogate in JSON string"
        | otherwise =
          cp = 65536 + ((hi_u - 55296) * 1024) + (lo_u - 56320)
          n0, n1, n2, n3 = j sb append (j utf8 from cp cp) c0 c1 c2 c3
          j parse str loop s (pos + 6) len n0 n1 n2 n3

fn :: j parse u surrogate String Int Int Int String String String String => JsonStrStep
      j parse u surrogate s pos len hi_u c0 c1 c2 c3 =
        | (pos + 6) > len = JStrErr "unpaired high UTF-16 surrogate in JSON string"
        | (str char at s pos) != 92 or (str char at s (pos + 1)) != 117 = JStrErr "unpaired high UTF-16 surrogate in JSON string"
        | otherwise = j finish surrogate s pos len hi_u (j parse hex4 s (pos + 2) len) c0 c1 c2 c3

fn :: j dispatch u escape String Int Int Int String String String String => JsonStrStep
      j dispatch u escape s pos len u c0 c1 c2 c3 =
        | u < 0 = JStrErr "invalid \\uXXXX hex escape in JSON string"
        | u >= 56320 and u <= 57343 = JStrErr "unpaired low UTF-16 surrogate in JSON string"
        | u >= 55296 and u <= 56319 = j parse u surrogate s (pos + 4) len u c0 c1 c2 c3
        | otherwise =
          n0, n1, n2, n3 = j sb append (j utf8 from cp u) c0 c1 c2 c3
          j parse str loop s (pos + 4) len n0 n1 n2 n3

fn :: j parse u escape String Int Int String String String String => JsonStrStep
      j parse u escape s pos len c0 c1 c2 c3 =
        j dispatch u escape s pos len (j parse hex4 s pos len) c0 c1 c2 c3

fn :: j finish simple escape String Int Int String String String String String => JsonStrStep
      j finish simple escape s pos len rep c0 c1 c2 c3 =
        | rep == "" = JStrErr "invalid escape sequence in JSON string"
        | otherwise =
          n0, n1, n2, n3 = j sb append rep c0 c1 c2 c3
          j parse str loop s (pos + 1) len n0 n1 n2 n3

fn :: j parse escape char String Int Int Int String String String String => JsonStrStep
      j parse escape char s pos len esc_c c0 c1 c2 c3 =
        | esc_c == 117 = j parse u escape s (pos + 1) len c0 c1 c2 c3
        | otherwise    = j finish simple escape s pos len (j unescape simple esc_c) c0 c1 c2 c3

fn :: j parse escape String Int Int String String String String => JsonStrStep
      j parse escape s pos len c0 c1 c2 c3 =
        j parse escape char s pos len (str char at s pos) c0 c1 c2 c3

fn :: j scan str plain2 String Int Int Int => Int
      j scan str plain2 s pos len c =
        | c >= 32 and c <= 127 and c != 34 and c != 92 = j scan str plain s (pos + 1) len
        | otherwise                                    = pos

fn :: j scan str plain String Int Int => Int
      j scan str plain s pos len =
        | pos >= len = len
        | otherwise  = j scan str plain2 s pos len (((str char at s pos) % 256 + 256) % 256)

fn :: j parse str char String Int Int Int String String String String => JsonStrStep
      j parse str char s pos len c c0 c1 c2 c3 =
        | c == 34 = JStrOk (j sb finish c0 c1 c2 c3) (pos + 1)
        | c < 32  = JStrErr "unescaped control character in JSON string"
        | c == 92 =
          | (pos + 1) >= len = JStrErr "unterminated escape in JSON string"
          | otherwise        = j parse escape s (pos + 1) len c0 c1 c2 c3 |.
        | otherwise =
          n0, n1, n2, n3 = j sb append (j raw byte ub c) c0 c1 c2 c3
          j parse str loop s (pos + 1) len n0 n1 n2 n3

fn :: j parse str run String Int Int Int String String String String => JsonStrStep
      j parse str run s pos run_end len c0 c1 c2 c3 =
        | run_end > pos =
          n0, n1, n2, n3 = j sb append (str slice s pos run_end) c0 c1 c2 c3
          j parse str loop s run_end len n0 n1 n2 n3
        | otherwise =
          j parse str char s pos len (((str char at s pos) % 256 + 256) % 256) c0 c1 c2 c3

fn :: j parse str loop String Int Int String String String String => JsonStrStep
      j parse str loop s pos len c0 c1 c2 c3 =
        | pos >= len = JStrErr "unterminated JSON string"
        | otherwise  = j parse str run s pos (j scan str plain s pos len) len c0 c1 c2 c3

fn :: j parse string String Int Int => JsonStrStep
      j parse string s pos len =
        | pos >= len or (str char at s pos) != 34 = JStrErr "expected JSON string"
        | otherwise                               = j parse str loop s (pos + 1) len "" "" "" ""

-- ── RFC 8259 §6 Number Parsing (No Leading Zeroes, 64-Bit Overflow Check, Fraction & Exponent) ──

fn :: j scan digits String Int Int => Int
      j scan digits s pos len =
        | pos >= len                      = len
        | j is digit (str char at s pos) = j scan digits s (pos + 1) len
        | otherwise                       = pos

fn :: j str cmp2 Int Int String String Int Int => Int
      j str cmp2 ca cb a b idx len =
        | ca < cb   = 0 - 1
        | ca > cb   = 1
        | otherwise = j str cmp loop a b (idx + 1) len

fn :: j str cmp loop String String Int Int => Int
      j str cmp loop a b idx len =
        | idx >= len = 0
        | otherwise  = j str cmp2 (str char at a idx) (str char at b idx) a b idx len

fn :: j digits fit i64 len String Bool Int => Bool
      j digits fit i64 len digs is_neg dlen =
        | dlen < 19 = True
        | dlen > 19 = False
        | is_neg    = (j str cmp loop digs "9223372036854775808" 0 19) <= 0
        | otherwise = (j str cmp loop digs "9223372036854775807" 0 19) <= 0

fn :: j digits fit i64 String Bool => Bool
      j digits fit i64 digs is_neg =
        j digits fit i64 len digs is_neg (str len digs)

fn :: j parse pos digits loop String Int Int Int => Int
      j parse pos digits loop digs idx dlen acc =
        | idx >= dlen = acc
        | otherwise   = j parse pos digits loop digs (idx + 1) dlen ((acc * 10) + ((str char at digs idx) - 48))

fn :: j parse neg digits loop String Int Int Int => Int
      j parse neg digits loop digs idx dlen acc =
        | idx >= dlen = acc
        | otherwise   = j parse neg digits loop digs (idx + 1) dlen ((acc * 10) - ((str char at digs idx) - 48))

fn :: j parse i64 exact String Bool => Int
      j parse i64 exact digs is_neg =
        | is_neg    = j parse neg digits loop digs 0 (str len digs) 0
        | otherwise = j parse pos digits loop digs 0 (str len digs) 0

fn :: j scan exp after sign2 Int Int => Int
      j scan exp after sign2 pos end_e =
        | end_e <= pos = 0 - 1
        | otherwise    = end_e

fn :: j scan exp after sign String Int Int => Int
      j scan exp after sign s pos len =
        | pos >= len = 0 - 1
        | otherwise  = j scan exp after sign2 pos (j scan digits s pos len)

fn :: j scan opt exp sign String Int Int Int => Int
      j scan opt exp sign s pos len sc =
        | sc == 43 or sc == 45 = j scan exp after sign s (pos + 2) len
        | otherwise            = j scan exp after sign s (pos + 1) len

fn :: j scan opt exp char String Int Int Int => Int
      j scan opt exp char s pos len c =
        | c != 101 and c != 69 = pos
        | (pos + 1) >= len     = 0 - 1
        | otherwise            = j scan opt exp sign s pos len (str char at s (pos + 1))

fn :: j scan opt exp String Int Int => Int
      j scan opt exp s pos len =
        | pos >= len = pos
        | otherwise  = j scan opt exp char s pos len (str char at s pos)

fn :: j scan opt frac2 String Int Int Int => Int
      j scan opt frac2 s pos len end_f =
        | end_f <= (pos + 1) = 0 - 1
        | otherwise          = j scan opt exp s end_f len

fn :: j scan opt frac String Int Int => Int
      j scan opt frac s pos len =
        | pos >= len                = pos
        | (str char at s pos) != 46 = j scan opt exp s pos len
        | (pos + 1) >= len          = 0 - 1
        | otherwise                 = j scan opt frac2 s pos len (j scan digits s (pos + 1) len)

fn :: j finish int digs String Bool Int => JsonStep
      j finish int digs digs is_neg int_end =
        | not (j digits fit i64 digs is_neg) = JStepErr "JSON integer overflows 64-bit signed range"
        | otherwise                          = JStepOk (JsonInt (j parse i64 exact digs is_neg)) int_end

fn :: j finish num after frac String Int Bool Int Int => JsonStep
      j finish num after frac s int_start is_neg int_end end_pos =
        | end_pos < 0       = JStepErr "invalid fraction or exponent in JSON number"
        | end_pos > int_end = JStepOk (JsonInt 0) end_pos
        | otherwise         = j finish int digs (str slice s int_start int_end) is_neg int_end

fn :: j finish num after int String Int Int Bool Int Int => JsonStep
      j finish num after int s _ int_start is_neg int_end len =
        j finish num after frac s int_start is_neg int_end (j scan opt frac s int_end len)

fn :: j parse num int part2 String Int Int Bool Int Int Int => JsonStep
      j parse num int part2 s start_pos int_start is_neg len c0 int_end =
        | int_end <= int_start                   = JStepErr "expected digits in JSON number"
        | c0 == 48 and int_end > (int_start + 1) = JStepErr "leading zero not permitted in JSON number"
        | otherwise                              = j finish num after int s start_pos int_start is_neg int_end len

fn :: j parse num int part String Int Int Bool Int => JsonStep
      j parse num int part s start_pos int_start is_neg len =
        | int_start >= len = JStepErr "expected digits in JSON number"
        | otherwise        = j parse num int part2 s start_pos int_start is_neg len (str char at s int_start) (j scan digits s int_start len)

fn :: j parse number String Int Int => JsonStep
      j parse number s pos len =
        | (str char at s pos) == 45 = j parse num int part s pos (pos + 1) True len
        | otherwise                 = j parse num int part s pos pos False len

-- ── Recursive Value, Array & Object Parser (Bounded Depth & Unique Keys) ──

fn :: j has field [JsonField] String => Bool
      j has field []                   _   =  False
      j has field ((JsonField k _):fs) key =
        | k == key  = True
        | otherwise = j has field fs key

fn :: j has field3 [JsonField] [JsonField] [JsonField] String => Bool
      j has field3 l0 l1 l2 key =
        (j has field l0 key) or (j has field l1 key) or (j has field l2 key)

fn :: j parse val String Int Int Int => JsonStep
      j parse val s pos len rem_depth =
        p = j skip ws s pos len
        j parse val at s p len rem_depth

fn :: j parse val at String Int Int Int => JsonStep
      j parse val at s p len rem_depth =
        | p >= len = JStepErr "unexpected end of JSON input"
        | (str char at s p) == 34 = j wrap str step (j parse string s p len)
        | (str char at s p) == 91 =
          | rem_depth <= 0 = JStepErr "maximum JSON nesting depth exceeded"
          | otherwise      = j parse arr open s (p + 1) len (rem_depth - 1)
        | (str char at s p) == 123 =
          | rem_depth <= 0 = JStepErr "maximum JSON nesting depth exceeded"
          | otherwise      = j parse obj open s (p + 1) len (rem_depth - 1)
        | (p + 4) <= len and (str slice s p (p + 4)) == "true"  = JStepOk (JsonBool True) (p + 4)
        | (p + 5) <= len and (str slice s p (p + 5)) == "false" = JStepOk (JsonBool False) (p + 5)
        | (p + 4) <= len and (str slice s p (p + 4)) == "null"  = JStepOk JsonNull (p + 4)
        | (str char at s p) == 45 or (j is digit (str char at s p)) = j parse number s p len
        | otherwise = JStepErr "unexpected token in JSON value"

fn :: j wrap str step JsonStrStep          => JsonStep
      j wrap str step (JStrOk val next_p)  =  JStepOk (JsonStr val) next_p
      j wrap str step (JStrErr err)        =  JStepErr err

fn :: j parse arr open String Int Int Int => JsonStep
      j parse arr open s pos len rem_depth =
        p = j skip ws s pos len
        j parse arr first s p len rem_depth

fn :: j parse arr first String Int Int Int => JsonStep
      j parse arr first s p len rem_depth =
        | p >= len                 = JStepErr "unterminated JSON array"
        | (str char at s p) == 93  = JStepOk (JsonArr []) (p + 1)
        | otherwise                = j finish arr step (j parse arr items s p len rem_depth [] [] [] 0)

fn :: j finish arr step JsonArrStep            => JsonStep
      j finish arr step (JArrOk items next_p)  =  JStepOk (JsonArr items) next_p
      j finish arr step (JArrErr err)          =  JStepErr err

fn :: j parse arr items String Int Int Int [JsonVal] [JsonVal] [JsonVal] Int => JsonArrStep
      j parse arr items s pos len rem_depth l0 l1 l2 cnt =
        j parse arr after item s len rem_depth l0 l1 l2 cnt (j parse val s pos len rem_depth)

fn :: j parse arr after item String Int Int [JsonVal] [JsonVal] [JsonVal] Int JsonStep => JsonArrStep
      j parse arr after item _ _ _ _ _ _ _ (JStepErr err) = JArrErr err
      j parse arr after item s len rem_depth l0 l1 l2 cnt (JStepOk v next_p) =
        p = j skip ws s next_p len
        n0, n1, n2, ncnt = j vlb append v l0 l1 l2 cnt
        j parse arr delim s p len rem_depth n0 n1 n2 ncnt

fn :: j parse arr delim String Int Int Int [JsonVal] [JsonVal] [JsonVal] Int => JsonArrStep
      j parse arr delim s p len rem_depth l0 l1 l2 cnt =
        | p >= len                 = JArrErr "unterminated JSON array"
        | (str char at s p) == 93  = JArrOk (j vlb finish l0 l1 l2) (p + 1)
        | (str char at s p) == 44  = j parse arr items s (p + 1) len rem_depth l0 l1 l2 cnt
        | otherwise                = JArrErr "expected ',' or ']' in JSON array"

fn :: j parse obj open String Int Int Int => JsonStep
      j parse obj open s pos len rem_depth =
        p = j skip ws s pos len
        j parse obj first s p len rem_depth

fn :: j parse obj first String Int Int Int => JsonStep
      j parse obj first s p len rem_depth =
        | p >= len                  = JStepErr "unterminated JSON object"
        | (str char at s p) == 125  = JStepOk (JsonObj []) (p + 1)
        | otherwise                 = j finish obj step (j parse obj fields s p len rem_depth [] [] [] 0)

fn :: j finish obj step JsonObjStep             => JsonStep
      j finish obj step (JObjOk fields next_p)  =  JStepOk (JsonObj fields) next_p
      j finish obj step (JObjErr err)           =  JStepErr err

fn :: j parse obj fields String Int Int Int [JsonField] [JsonField] [JsonField] Int => JsonObjStep
      j parse obj fields s pos len rem_depth l0 l1 l2 cnt =
        p = j skip ws s pos len
        j parse obj after key s len rem_depth l0 l1 l2 cnt (j parse string s p len)

fn :: j parse obj after key String Int Int [JsonField] [JsonField] [JsonField] Int JsonStrStep => JsonObjStep
      j parse obj after key _ _ _ _ _ _ _ (JStrErr err) = JObjErr err
      j parse obj after key s len rem_depth l0 l1 l2 cnt (JStrOk key next_p) =
        | j has field3 l0 l1 l2 key = JObjErr ("duplicate JSON object key: " + key)
        | otherwise =
          p = j skip ws s next_p len
          j parse obj colon s p len rem_depth key l0 l1 l2 cnt

fn :: j parse obj colon String Int Int Int String [JsonField] [JsonField] [JsonField] Int => JsonObjStep
      j parse obj colon s p len rem_depth key l0 l1 l2 cnt =
        | p >= len or (str char at s p) != 58 = JObjErr "expected ':' after JSON object key"
        | otherwise                           = j parse obj after val s len rem_depth key l0 l1 l2 cnt (j parse val s (p + 1) len rem_depth)

fn :: j parse obj after val String Int Int String [JsonField] [JsonField] [JsonField] Int JsonStep => JsonObjStep
      j parse obj after val _ _ _ _ _ _ _ _ (JStepErr err) = JObjErr err
      j parse obj after val s len rem_depth key l0 l1 l2 cnt (JStepOk v next_p) =
        p = j skip ws s next_p len
        n0, n1, n2, ncnt = j flb append (JsonField key v) l0 l1 l2 cnt
        j parse obj delim s p len rem_depth n0 n1 n2 ncnt

fn :: j parse obj delim String Int Int Int [JsonField] [JsonField] [JsonField] Int => JsonObjStep
      j parse obj delim s p len rem_depth l0 l1 l2 cnt =
        | p >= len                  = JObjErr "unterminated JSON object"
        | (str char at s p) == 125  = JObjOk (j flb finish l0 l1 l2) (p + 1)
        | (str char at s p) == 44   = j parse obj fields s (p + 1) len rem_depth l0 l1 l2 cnt
        | otherwise                 = JObjErr "expected ',' or '}' in JSON object"

fn :: j check eof String Int JsonStep         => JsonRes
      j check eof _      _   (JStepErr err)   =  JsonErr err
      j check eof s      len (JStepOk val end_p) =
        p = j skip ws s end_p len
        j check eof pos p len val

fn :: j check eof pos Int Int JsonVal => JsonRes
      j check eof pos p   len val     =
        | p == len  = JsonOk val
        | otherwise = JsonErr "unexpected trailing characters after JSON value"

-- @implements FR-JSON-001
-- @implements API-JSON-001
-- @mitigates VUL-INPUT-001
fn :: json parse with limits String Int Int => JsonRes
      json parse with limits s max_depth max_bytes =
        | max_depth < 1           = JsonErr "invalid JSON max_depth limit"
        | max_bytes < 1           = JsonErr "invalid JSON max_bytes limit"
        | (str len s) > max_bytes = JsonErr "JSON input exceeds maximum allowed byte length"
        | otherwise               = j check eof s (str len s) (j parse val s 0 (str len s) max_depth)

-- @implements FR-JSON-001
-- @implements API-JSON-001
-- @mitigates VUL-INPUT-001
fn :: json parse String => JsonRes
      json parse s      =  json parse with limits s 64 1048576

-- ── Serialization & Pretty-Printing ──────────────────────────

fn :: j join arr loop [JsonVal] String String String String => String
      j join arr loop []     c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j join arr loop (v:vs) c0 c1 c2 c3 =
        n0, n1, n2, n3 = j sb append ("," + (json stringify v)) c0 c1 c2 c3
        j join arr loop vs n0 n1 n2 n3

fn :: j join arr [JsonVal] => String
      j join arr []        =  ""
      j join arr (v:vs)    =  j join arr loop vs (json stringify v) "" "" ""

fn :: j join obj loop [JsonField] String String String String => String
      j join obj loop []                     c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j join obj loop ((JsonField k v):rest) c0 c1 c2 c3 =
        item = "," + (j escape str k) + ":" + (json stringify v)
        n0, n1, n2, n3 = j sb append item c0 c1 c2 c3
        j join obj loop rest n0 n1 n2 n3

fn :: j join obj [JsonField] => String
      j join obj []                     =  ""
      j join obj ((JsonField k v):rest) =
        first = (j escape str k) + ":" + (json stringify v)
        j join obj loop rest first "" "" ""

fn :: j pos int to str Int String => String
      j pos int to str n acc =
        | n <= 0    = acc
        | otherwise = j pos int to str (n / 10) ((char from code (48 + (n % 10))) + acc)

fn :: j int to str Int => String
      j int to str n =
        | n == 0         = "0"
        | n > 0          = j pos int to str n ""
        | n > (0 - 10)   = "-" + (char from code (48 + (0 - n)))
        | otherwise      = "-" + (j pos int to str (0 - (n / 10)) (char from code (48 + (0 - (n % 10)))))

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json stringify JsonVal          => String
      json stringify JsonNull         =  "null"
      json stringify (JsonBool True)  =  "true"
      json stringify (JsonBool False) =  "false"
      json stringify (JsonInt n)      =  j int to str n
      json stringify (JsonStr s)      =  j escape str s
      json stringify (JsonArr items)  =  "[" + (j join arr items) + "]"
      json stringify (JsonObj fields) =  (char from code 123) + (j join obj fields) + (char from code 125)

fn :: j pretty arr loop [JsonVal] Int Int String String String String => String
      j pretty arr loop []     _   _   c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j pretty arr loop (v:vs) ind cur c0 c1 c2 c3 =
        item = "," + (char from code 10) + (j spaces (cur + ind)) + (j pretty val v ind (cur + ind))
        n0, n1, n2, n3 = j sb append item c0 c1 c2 c3
        j pretty arr loop vs ind cur n0 n1 n2 n3

fn :: j pretty arr [JsonVal] Int Int => String
      j pretty arr []     _   _   =  ""
      j pretty arr (v:vs) ind cur =
        first = (j spaces (cur + ind)) + (j pretty val v ind (cur + ind))
        j pretty arr loop vs ind cur first "" "" ""

fn :: j pretty obj loop [JsonField] Int Int String String String String => String
      j pretty obj loop []                     _   _   c0 c1 c2 c3 = j sb finish c0 c1 c2 c3
      j pretty obj loop ((JsonField k v):rest) ind cur c0 c1 c2 c3 =
        item = "," + (char from code 10) + (j spaces (cur + ind)) + (j escape str k) + ": " + (j pretty val v ind (cur + ind))
        n0, n1, n2, n3 = j sb append item c0 c1 c2 c3
        j pretty obj loop rest ind cur n0 n1 n2 n3

fn :: j pretty obj [JsonField] Int Int => String
      j pretty obj []                     _   _   =  ""
      j pretty obj ((JsonField k v):rest) ind cur =
        first = (j spaces (cur + ind)) + (j escape str k) + ": " + (j pretty val v ind (cur + ind))
        j pretty obj loop rest ind cur first "" "" ""

fn :: j pretty val JsonVal          Int Int => String
      j pretty val (JsonArr [])     _   _   =  "[]"
      j pretty val (JsonArr items)  ind cur =
        nl = char from code 10
        "[" + nl + (j pretty arr items ind cur) + nl + (j spaces cur) + "]"
      j pretty val (JsonObj [])     _   _   =  (char from code 123) + (char from code 125)
      j pretty val (JsonObj fields) ind cur =
        nl = char from code 10
        (char from code 123) + nl + (j pretty obj fields ind cur) + nl + (j spaces cur) + (char from code 125)
      j pretty val v                _   _   =  json stringify v

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json pretty JsonVal Int => String
      json pretty val     ind =  j pretty val val ind 0

-- ── Dot-Path Queries & Field Updates ─────────────────────────

fn :: j find field [JsonField] String => JsonVal
      j find field []                   _   =  JsonNull
      j find field ((JsonField k v):fs) key =
        | k == key  = v
        | otherwise = j find field fs key

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json get field JsonVal          String => JsonVal
      json get field (JsonObj fields) key    =  j find field fields key
      json get field _                _      =  JsonNull

fn :: j nth val [JsonVal] Int => JsonVal
      j nth val []     _   =  JsonNull
      j nth val (v:vs) idx =
        | idx < 0   = JsonNull
        | idx == 0  = v
        | otherwise = j nth val vs (idx - 1)

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json get index JsonVal         Int => JsonVal
      json get index (JsonArr items) idx =  j nth val items idx
      json get index _               _   =  JsonNull

fn :: j split dots loop String Int Int Int [String] => [String]
      j split dots loop s pos len start acc =
        | pos >= len                = acc :: [str slice s start len]
        | (str char at s pos) == 46 = j split dots loop s (pos + 1) len (pos + 1) (acc :: [str slice s start pos])
        | otherwise                 = j split dots loop s (pos + 1) len start acc

fn :: j step path JsonVal          String => JsonVal
      j step path (JsonObj fields) seg    =  j find field fields seg
      j step path (JsonArr items)  seg    =
        | seg != "" and (j scan digits seg 0 (str len seg)) == (str len seg) and (j digits fit i64 seg False) = j nth val items (str to int seg)
        | otherwise = JsonNull
      j step path _                _      =  JsonNull

fn :: j walk path JsonVal [String]   => JsonVal
      j walk path val     []         =  val
      j walk path val     ("":rest)  =  j walk path val rest
      j walk path val     (seg:rest) =  j walk path (j step path val seg) rest

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json get path JsonVal String   => JsonVal
      json get path val     ""       =  val
      json get path val     dot_path =  j walk path val (j split dots loop dot_path 0 (str len dot_path) 0 [])

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json get str JsonVal String String => String
      json get str val dot_path fallback = j unwrap str (json get path val dot_path) fallback

fn :: j unwrap str JsonVal     String   => String
      j unwrap str (JsonStr s) _        =  s
      j unwrap str _           fallback =  fallback

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json get int JsonVal String Int => Int
      json get int val dot_path fallback = j unwrap int (json get path val dot_path) fallback

fn :: j unwrap int JsonVal     Int      => Int
      j unwrap int (JsonInt n) _        =  n
      j unwrap int _           fallback =  fallback

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json get bool JsonVal String Bool => Bool
      json get bool val dot_path fallback = j unwrap bool (json get path val dot_path) fallback

fn :: j unwrap bool JsonVal      Bool     => Bool
      j unwrap bool (JsonBool b) _        =  b
      j unwrap bool _            fallback =  fallback

fn :: j put field [JsonField] String JsonVal => [JsonField]
      j put field []                   key new_val = [JsonField key new_val]
      j put field ((JsonField k v):fs) key new_val =
        | k == key  = [JsonField key new_val] :: fs
        | otherwise = [JsonField k v] :: (j put field fs key new_val)

-- @implements FR-JSON-001
-- @implements API-JSON-001
fn :: json set field JsonVal String JsonVal => JsonVal
      json set field (JsonObj fields) key new_val = JsonObj (j put field fields key new_val)
      json set field _ key new_val = JsonObj [JsonField key new_val]
