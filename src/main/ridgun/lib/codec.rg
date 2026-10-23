-- ============================================================
-- src/main/ridgun/lib/codec.rg
-- Pure-Ridgun RFC 4648 Hex/Base64/Base64url, RFC 3986 URL & RFC 8259 JSON Library (CODEC)
-- @implements FR-CODEC-001
-- @implements API-CODEC-001
-- @mitigates VUL-INPUT-001
-- ============================================================

fn :: cd raw byte ub Int => String
      cd raw byte ub ub  =
        | ub >= 1 and ub <= 127 = char from code ub
        | otherwise =
          efd = sys call 290 (256 + ub) 526336 0 0 0 0
          s   = sys read fd efd 8
          _   = sys close efd
          str slice s 0 1

fn :: cd raw byte Int => String
      cd raw byte b   =  cd raw byte ub (((b % 256) + 256) % 256)

fn :: cd hex lut Int => String
      cd hex lut _   =  "0123456789abcdef"

fn :: cd hex up lut Int => String
      cd hex up lut _   =  "0123456789ABCDEF"

fn :: cd b64 lut Int => String
      cd b64 lut _   =  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

fn :: cd b64url lut Int => String
      cd b64url lut _   =  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

fn :: cd index of loop String String Int Int Int => Int
      cd index of loop s sub idx slen sublen =
        | (idx + sublen) > slen                        = 0 - 1
        | (str slice s idx (idx + sublen)) == sub      = idx
        | otherwise                                    = cd index of loop s sub (idx + 1) slen sublen

fn :: cd index of String String => Int
      cd index of s      sub    =
        | (str len sub) == 0 = 0
        | otherwise          = cd index of loop s sub 0 (str len s) (str len sub)

fn :: cd split char loop String Int Int Int Int => [String]
      cd split char loop s ch start idx len =
        | idx >= len                = [(str slice s start len)]
        | (str char at s idx) == ch = [(str slice s start idx)] :: (cd split char loop s ch (idx + 1) (idx + 1) len)
        | otherwise                 = cd split char loop s ch start (idx + 1) len

-- ── RFC 4648 Hexadecimal Encoding & Decoding ─────────────────

fn :: cd hex val Int => Int
      cd hex val c   =
        | c >= 48 and c <= 57  = c - 48
        | c >= 65 and c <= 70  = (c - 65) + 10
        | c >= 97 and c <= 102 = (c - 97) + 10
        | otherwise            = 0 - 1

fn :: cd valid hex loop String Int Int => Bool
      cd valid hex loop s idx len =
        | idx >= len                           = True
        | (cd hex val (str char at s idx)) < 0 = False
        | otherwise                            = cd valid hex loop s (idx + 1) len

fn :: cd is valid hex len String Int => Bool
      cd is valid hex len s n =
        | (n % 2) != 0 = False
        | otherwise    = cd valid hex loop s 0 n

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
-- @mitigates VUL-INPUT-001
fn :: is valid hex String => Bool
      is valid hex s      =  cd is valid hex len s (str len s)

fn :: cd hex enc byte Int => String
      cd hex enc byte b   =
        ub  = ((b % 256) + 256) % 256
        hi  = ub / 16
        lo  = ub % 16
        tbl = cd hex lut 0
        (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1))

fn :: cd hex enc loop String Int Int => String
      cd hex enc loop s idx len =
        | idx >= len = ""
        | otherwise  = (cd hex enc byte (str char at s idx)) + (cd hex enc loop s (idx + 1) len)

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: hex encode String => String
      hex encode s      =  cd hex enc loop s 0 (str len s)

fn :: cd hex dec loop String Int Int => String
      cd hex dec loop s idx len =
        | idx >= len = ""
        | otherwise =
          hi = cd hex val (str char at s idx)
          lo = cd hex val (str char at s (idx + 1))
          (cd raw byte ((hi * 16) + lo)) + (cd hex dec loop s (idx + 2) len)

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
-- @mitigates VUL-INPUT-001
fn :: hex decode String => String
      hex decode s      =
        | not (is valid hex s) = ""
        | otherwise            = cd hex dec loop s 0 (str len s)

-- ── RFC 4648 Standard Base64 & URL-Safe Base64url ────────────

fn :: cd b64 char String Int => String
      cd b64 char tbl    idx =
        i = idx % 64
        str slice tbl i (i + 1)

fn :: cd b64 pad suffix String Bool => String
      cd b64 pad suffix suffix True = suffix
      cd b64 pad suffix _ False = ""

fn :: cd b64 enc step String Int String Bool Int => String
      cd b64 enc step s idx tbl pad rem =
        | rem <= 0 = ""
        | rem == 1 =
          b0   = str char at s idx
          out2 = (cd b64 char tbl (b0 / 4)) + (cd b64 char tbl ((b0 % 4) * 16))
          out2 + (cd b64 pad suffix "==" pad)
        | rem == 2 =
          b0   = str char at s idx
          b1   = str char at s (idx + 1)
          n    = (b0 * 256) + b1
          out3 = (cd b64 char tbl (n / 1024)) + (cd b64 char tbl ((n / 16) % 64)) + (cd b64 char tbl ((n % 16) * 4))
          out3 + (cd b64 pad suffix "=" pad)
        | otherwise =
          b0   = str char at s idx
          b1   = str char at s (idx + 1)
          b2   = str char at s (idx + 2)
          n    = (b0 * 65536) + (b1 * 256) + b2
          out4 = (cd b64 char tbl (n / 262144)) + (cd b64 char tbl ((n / 4096) % 64)) + (cd b64 char tbl ((n / 64) % 64)) + (cd b64 char tbl (n % 64))
          out4 + (cd b64 enc rem s (idx + 3) tbl pad)

fn :: cd b64 enc rem String Int String Bool => String
      cd b64 enc rem s idx tbl pad = cd b64 enc step s idx tbl pad ((str len s) - idx)

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: base64 encode String => String
      base64 encode s      =  cd b64 enc rem s 0 (cd b64 lut 0) True

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: base64url encode String => String
      base64url encode s      =  cd b64 enc rem s 0 (cd b64url lut 0) False

fn :: cd b64 val Int => Int
      cd b64 val c   =
        | c >= 65 and c <= 90  = c - 65
        | c >= 97 and c <= 122 = (c - 97) + 26
        | c >= 48 and c <= 57  = (c - 48) + 52
        | c == 43 or c == 45   = 62
        | c == 47 or c == 95   = 63
        | otherwise            = 0 - 1

fn :: cd strip b64 pad String Int => String
      cd strip b64 pad s n =
        | n <= 0                        = ""
        | (str char at s (n - 1)) == 61 = cd strip b64 pad (str slice s 0 (n - 1)) (n - 1)
        | otherwise                     = s

fn :: cd valid b64 body String Int Int => Bool
      cd valid b64 body s idx len =
        | idx >= len                           = True
        | (cd b64 val (str char at s idx)) < 0 = False
        | otherwise                            = cd valid b64 body s (idx + 1) len

fn :: cd valid b64 raw String Int => Bool
      cd valid b64 raw raw n =
        | (n % 4) == 1 = False
        | otherwise    = cd valid b64 body raw 0 n

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
-- @mitigates VUL-INPUT-001
fn :: is valid base64 String => Bool
      is valid base64 s      =
        raw = cd strip b64 pad s (str len s)
        cd valid b64 raw raw (str len raw)

fn :: cd b64 dec step String Int Int Int => String
      cd b64 dec step s idx len rem =
        | rem <= 1 = ""
        | rem == 2 =
          v0 = cd b64 val (str char at s idx)
          v1 = cd b64 val (str char at s (idx + 1))
          cd raw byte (((v0 * 4) + (v1 / 16)) % 256)
        | rem == 3 =
          v0 = cd b64 val (str char at s idx)
          v1 = cd b64 val (str char at s (idx + 1))
          v2 = cd b64 val (str char at s (idx + 2))
          n  = (v0 * 1024) + (v1 * 16) + (v2 / 4)
          (cd raw byte ((n / 256) % 256)) + (cd raw byte (n % 256))
        | otherwise =
          v0 = cd b64 val (str char at s idx)
          v1 = cd b64 val (str char at s (idx + 1))
          v2 = cd b64 val (str char at s (idx + 2))
          v3 = cd b64 val (str char at s (idx + 3))
          n  = (v0 * 262144) + (v1 * 4096) + (v2 * 64) + v3
          b0 = (n / 65536) % 256
          b1 = (n / 256) % 256
          b2 = n % 256
          (cd raw byte b0) + (cd raw byte b1) + (cd raw byte b2) + (cd b64 dec loop s (idx + 4) len)

fn :: cd b64 dec loop String Int Int => String
      cd b64 dec loop s idx len = cd b64 dec step s idx len (len - idx)

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
-- @mitigates VUL-INPUT-001
fn :: base64 decode String => String
      base64 decode s      =
        | not (is valid base64 s) = ""
        | otherwise =
          raw = cd strip b64 pad s (str len s)
          cd b64 dec loop raw 0 (str len raw)

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
-- @mitigates VUL-INPUT-001
fn :: base64url decode String => String
      base64url decode s      =  base64 decode s

-- ── RFC 3986 URL Percent-Encoding & Query Strings ────────────

fn :: cd is unreserved Int => Bool
      cd is unreserved c   =
        | c >= 65 and c <= 90                        = True
        | c >= 97 and c <= 122                       = True
        | c >= 48 and c <= 57                        = True
        | c == 45 or c == 95 or c == 46 or c == 126  = True
        | otherwise                                  = False

fn :: cd pct byte Int => String
      cd pct byte b   =
        ub  = ((b % 256) + 256) % 256
        hi  = ub / 16
        lo  = ub % 16
        tbl = cd hex up lut 0
        "%" + (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1))

fn :: cd url enc char String Int Int => String
      cd url enc char s idx c =
        | cd is unreserved c = str slice s idx (idx + 1)
        | otherwise          = cd pct byte c

fn :: cd url enc loop String Int Int => String
      cd url enc loop s idx len =
        | idx >= len = ""
        | otherwise  = (cd url enc char s idx (str char at s idx)) + (cd url enc loop s (idx + 1) len)

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: url encode String => String
      url encode s      =  cd url enc loop s 0 (str len s)

fn :: cd url dec pct String Int Int Int Int => String
      cd url dec pct s idx len hi lo =
        | hi >= 0 and lo >= 0 = (cd raw byte ((hi * 16) + lo)) + (cd url dec loop s (idx + 3) len)
        | otherwise           = "%" + (cd url dec loop s (idx + 1) len)

fn :: cd url dec at String Int Int Int => String
      cd url dec at s idx len c =
        | c == 43                     = " " + (cd url dec loop s (idx + 1) len)
        | c == 37 and (idx + 2) < len = cd url dec pct s idx len (cd hex val (str char at s (idx + 1))) (cd hex val (str char at s (idx + 2)))
        | otherwise                   = (str slice s idx (idx + 1)) + (cd url dec loop s (idx + 1) len)

fn :: cd url dec loop String Int Int => String
      cd url dec loop s idx len =
        | idx >= len = ""
        | otherwise  = cd url dec at s idx len (str char at s idx)

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: url decode String => String
      url decode s      =  cd url dec loop s 0 (str len s)

fn :: cd pair key (String String) => String
      cd pair key (k, _)          =  k

fn :: cd pair val (String String) => String
      cd pair val (_, v)          =  v

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: query string encode [String String] => String
      query string encode []              =  ""
      query string encode (pair:[])       =  (url encode (cd pair key pair)) + "=" + (url encode (cd pair val pair))
      query string encode (pair:rest)     =
        (url encode (cd pair key pair)) + "=" + (url encode (cd pair val pair)) + "&" + (query string encode rest)

fn :: cd parse kv at String Int => String String
      cd parse kv at item eq_idx =
        | eq_idx < 0 = (url decode item, "")
        | otherwise  = (url decode (str slice item 0 eq_idx), url decode (str slice item (eq_idx + 1) (str len item)))

fn :: cd parse kv item String => String String
      cd parse kv item item   =  cd parse kv at item (cd index of item "=")

fn :: cd parse qs list [String] => [String String]
      cd parse qs list []       =  []
      cd parse qs list (x:rest) =
        | (str len x) == 0 = cd parse qs list rest
        | otherwise        = [(cd parse kv item x)] :: (cd parse qs list rest)

fn :: cd strip leading q String => String
      cd strip leading q qs     =
        | str starts with qs "?" = str slice qs 1 (str len qs)
        | otherwise              = qs

fn :: cd decode clean qs String => [String String]
      cd decode clean qs clean  =
        | (str len clean) == 0 = []
        | otherwise            = cd parse qs list (cd split char loop clean 38 0 0 (str len clean))

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: query string decode String => [String String]
      query string decode qs     =  cd decode clean qs (cd strip leading q qs)

-- ── RFC 8259 Lightweight JSON Formatting & Field Extraction ──

fn :: cd json esc code String Int Int => String
      cd json esc code s idx c =
        | c == 34   = "\\\""
        | c == 92   = "\\\\"
        | c == 10   = "\\n"
        | c == 13   = "\\r"
        | c == 9    = "\\t"
        | otherwise = str slice s idx (idx + 1)

fn :: cd json esc loop String Int Int => String
      cd json esc loop s idx len =
        | idx >= len = ""
        | otherwise  = (cd json esc code s idx (str char at s idx)) + (cd json esc loop s (idx + 1) len)

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
-- @mitigates VUL-INPUT-001
fn :: json escape String => String
      json escape s      =  cd json esc loop s 0 (str len s)

fn :: cd json unesc next String Int Int Int => String
      cd json unesc next s idx len nc =
        | nc == 34  = "\"" + (cd json unesc loop s (idx + 2) len)
        | nc == 92  = "\\" + (cd json unesc loop s (idx + 2) len)
        | nc == 110 = "\n" + (cd json unesc loop s (idx + 2) len)
        | nc == 114 = "\r" + (cd json unesc loop s (idx + 2) len)
        | nc == 116 = "\t" + (cd json unesc loop s (idx + 2) len)
        | otherwise = (str slice s (idx + 1) (idx + 2)) + (cd json unesc loop s (idx + 2) len)

fn :: cd json unesc loop String Int Int => String
      cd json unesc loop s idx len =
        | idx >= len                                    = ""
        | (str char at s idx) == 92 and (idx + 1) < len = cd json unesc next s idx len (str char at s (idx + 1))
        | otherwise                                     = (str slice s idx (idx + 1)) + (cd json unesc loop s (idx + 1) len)

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: json unescape String => String
      json unescape s      =  cd json unesc loop s 0 (str len s)

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: json quote String => String
      json quote s      =  "\"" + (json escape s) + "\""

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: json int Int => String
      json int n   =  int to str n

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: json bool Bool  => String
      json bool True  =  "true"
      json bool False =  "false"

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: json null => String
      json null =  "null"

fn :: cd join json items [String] => String
      cd join json items []       =  ""
      cd join json items (x:[])   =  x
      cd join json items (x:rest) =  x + "," + (cd join json items rest)

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: json array [String] => String
      json array items    =  "[" + (cd join json items items) + "]"

fn :: cd join json pairs [String String] => String
      cd join json pairs []              =  ""
      cd join json pairs (pair:[])       =  (json quote (cd pair key pair)) + ":" + (cd pair val pair)
      cd join json pairs (pair:rest)     =
        (json quote (cd pair key pair)) + ":" + (cd pair val pair) + "," + (cd join json pairs rest)

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: json object [String String] => String
      json object pairs           =  "{" + (cd join json pairs pairs) + "}"

fn :: cd quote pair vals [String String] => [String String]
      cd quote pair vals []              =  []
      cd quote pair vals (pair:rest)     =
        [(cd pair key pair, json quote (cd pair val pair))] :: (cd quote pair vals rest)

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: json str object [String String] => String
      json str object pairs           =  json object (cd quote pair vals pairs)

fn :: cd is json ws Int => Bool
      cd is json ws c   =  c == 32 or c == 9 or c == 10 or c == 13 or c == 58

fn :: cd skip key sep String Int Int => Int
      cd skip key sep s idx len =
        | idx >= len                        = idx
        | cd is json ws (str char at s idx) = cd skip key sep s (idx + 1) len
        | otherwise                         = idx

fn :: cd scan json str end String Int Int => Int
      cd scan json str end s idx len =
        | idx >= len                = 0 - 1
        | (str char at s idx) == 92 = cd scan json str end s (idx + 2) len
        | (str char at s idx) == 34 = idx
        | otherwise                 = cd scan json str end s (idx + 1) len

fn :: cd is tok delim Int => Bool
      cd is tok delim c   =  c == 44 or c == 125 or c == 93 or c == 32 or c == 9 or c == 10 or c == 13

fn :: cd scan json tok end String Int Int => Int
      cd scan json tok end s idx len =
        | idx >= len                           = len
        | cd is tok delim (str char at s idx)  = idx
        | otherwise                            = cd scan json tok end s (idx + 1) len

fn :: cd extract json str vend String Int Int => String
      cd extract json str vend doc vstart vend =
        | vend < 0  = ""
        | otherwise = json unescape (str slice doc (vstart + 1) vend)

fn :: cd extract json str vstart String Int => String
      cd extract json str vstart doc vstart =
        | vstart >= (str len doc)        = ""
        | (str char at doc vstart) != 34 = ""
        | otherwise                      = cd extract json str vend doc vstart (cd scan json str end doc (vstart + 1) (str len doc))

fn :: cd extract json str kpos String String Int => String
      cd extract json str kpos doc pat kpos =
        | kpos < 0  = ""
        | otherwise = cd extract json str vstart doc (cd skip key sep doc (kpos + (str len pat)) (str len doc))

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: json get str String String => String
      json get str doc    key    =
        pat = "\"" + (json escape key) + "\""
        cd extract json str kpos doc pat (cd index of doc pat)

fn :: cd is signed int loop String Int Int => Bool
      cd is signed int loop s idx len =
        | idx >= len                                           = True
        | (str char at s idx) < 48 or (str char at s idx) > 57 = False
        | otherwise                                            = cd is signed int loop s (idx + 1) len

fn :: cd is valid int len String Int => Bool
      cd is valid int len s n =
        | n == 0                  = False
        | (str char at s 0) == 45 =
          | n <= 1    = False
          | otherwise = cd is signed int loop s 1 n |.
        | otherwise               = cd is signed int loop s 0 n

fn :: cd is valid int str String => Bool
      cd is valid int str s = cd is valid int len s (str len s)

fn :: cd raw tok vstart String Int => String
      cd raw tok vstart doc vstart =
        | vstart >= (str len doc) = ""
        | otherwise =
          vend = cd scan json tok end doc vstart (str len doc)
          str slice doc vstart vend

fn :: cd raw tok kpos String String Int => String
      cd raw tok kpos doc pat kpos =
        | kpos < 0  = ""
        | otherwise = cd raw tok vstart doc (cd skip key sep doc (kpos + (str len pat)) (str len doc))

fn :: cd raw json token String String => String
      cd raw json token doc key =
        pat = "\"" + (json escape key) + "\""
        cd raw tok kpos doc pat (cd index of doc pat)

fn :: cd parse tok int String Int => Int
      cd parse tok int tok fallback =
        | not (cd is valid int str tok) = fallback
        | otherwise                     = str to int tok

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
-- @mitigates VUL-INPUT-001
fn :: json get int String String Int => Int
      json get int doc key fallback = cd parse tok int (cd raw json token doc key) fallback

fn :: cd parse tok bool String Bool => Bool
      cd parse tok bool tok fallback =
        | tok == "true"  = True
        | tok == "false" = False
        | otherwise      = fallback

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: json get bool String String Bool => Bool
      json get bool doc key fallback = cd parse tok bool (cd raw json token doc key) fallback
