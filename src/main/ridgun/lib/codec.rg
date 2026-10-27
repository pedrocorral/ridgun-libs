-- ============================================================
-- src/main/ridgun/lib/codec.rg
-- Pure-Ridgun RFC 4648 Hex/Base64/Base64url, RFC 3986 URL & RFC 8259 JSON Library (CODEC)
-- @implements FR-CODEC-001
-- @implements API-CODEC-001
-- @mitigates VUL-INPUT-001
-- ============================================================

module :: codec

-- ── Zero-Syscall Raw Byte Extraction (0..255) ────────────────

fn :: cd raw byte ub Int => String
      cd raw byte ub ub  =
        | ub >= 1 and ub <= 127 = char from code ub
        | ub == 0 = str slice (sha256 raw "00679") 0 1
        | otherwise =
          idx = (ub - 128) * 5
          lut = "0056400101002080010000179000010024100109003430040100361007870009100353001870030400471000870020200071002360012501171004140236900275001810016001398004440080400017005250027000314001400024700004006350015700183005940027600207007720028400601003400038000839006850084900617003060113500277000320006900483000580019200151008700008500193000100057000070002880002600326006460038800018009190028900103006000043900073011700038900628007210077300074004740006000041001410019900066003680001900383001730005700558000670024500065002030031900000008250001100128001360034900030003750039600228002380008400618005900031800062001770087900076002570009600034002200001600161"
          str slice (sha256 raw (str slice lut idx (idx + 5))) 0 1

fn :: cd raw byte Int => String
      cd raw byte b   =  cd raw byte ub (((b % 256) + 256) % 256)

-- ── 4-Level Tail-Recursive String & List Builders ────────────

fn :: cd sb append3 String String => String String String String
      cd sb append3 n2 c3 =
        | (str len n2) < 65536 = ("", "", n2, c3)
        | otherwise            = ("", "", "", c3 + n2)

fn :: cd sb append2 String String String => String String String String
      cd sb append2 n1 c2 c3 =
        | (str len n1) < 8192 = ("", n1, c2, c3)
        | otherwise           = cd sb append3 (c2 + n1) c3

fn :: cd sb append1 String String String String => String String String String
      cd sb append1 n0 c1 c2 c3 =
        | (str len n0) < 512 = (n0, c1, c2, c3)
        | otherwise          = cd sb append2 (c1 + n0) c2 c3

fn :: cd sb append String String String String String => String String String String
      cd sb append chunk c0 c1 c2 c3 =
        cd sb append1 (c0 + chunk) c1 c2 c3

fn :: cd sb finish String String String String => String
      cd sb finish c0 c1 c2 c3 =  ((c3 + c2) + c1) + c0

fn :: cd lb append2 [String] [String] Int => [String] [String] [String] Int
      cd lb append2 n1 l2 cnt =
        | (cnt % 1024) == 0 = ([], [], l2 :: n1, cnt)
        | otherwise         = ([], n1, l2, cnt)

fn :: cd lb append1 [String] [String] [String] Int => [String] [String] [String] Int
      cd lb append1 n0 l1 l2 cnt =
        | (cnt % 32) == 0 = cd lb append2 (l1 :: n0) l2 cnt
        | otherwise       = (n0, l1, l2, cnt)

fn :: cd lb append String [String] [String] [String] Int => [String] [String] [String] Int
      cd lb append item l0 l1 l2 cnt =
        cd lb append1 (l0 :: [item]) l1 l2 (cnt + 1)

fn :: cd lb finish [String] [String] [String] => [String]
      cd lb finish l0 l1 l2 =  l2 :: (l1 :: l0)

fn :: cd hex lut Int => String
      cd hex lut _   =  "0123456789abcdef"

fn :: cd hex up lut Int => String
      cd hex up lut _   =  "0123456789ABCDEF"

fn :: cd b64 lut Int => String
      cd b64 lut _   =  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

fn :: cd b64url lut Int => String
      cd b64url lut _   =  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

fn :: cd match sub at String String Int Int Int => Bool
      cd match sub at s sub idx k sublen =
        | k >= sublen = True
        | (str char at s (idx + k)) == (str char at sub k) =
          cd match sub at s sub idx (k + 1) sublen
        | otherwise = False

fn :: cd index of loop String String Int Int Int Int => Int
      cd index of loop s sub idx slen sublen s0 =
        | (idx + sublen) > slen = 0 - 1
        | (idx + 4096 + sublen) <= slen and (not (str contains (str slice s idx (idx + 4096 + sublen - 1)) sub)) =
          cd index of loop s sub (idx + 4096) slen sublen s0
        | (str char at s idx) == s0 and (cd match sub at s sub idx 1 sublen) = idx
        | otherwise = cd index of loop s sub (idx + 1) slen sublen s0

fn :: cd index of String String => Int
      cd index of s      sub    =
        | (str len sub) == 0 = 0
        | not (str contains s sub) = 0 - 1
        | otherwise          = cd index of loop s sub 0 (str len s) (str len sub) (str char at sub 0)

fn :: cd scan b end String Int => Int
      cd scan b end s end_idx =
        | end_idx >= (str len s) = 0
        | otherwise              = ((str char at s end_idx) % 256 + 256) % 256

fn :: cd scan b prev String Int => Int
      cd scan b prev s start =
        | start == 0 = 0
        | otherwise  = ((str char at s (start - 1)) % 256 + 256) % 256

fn :: cd scan ascii end String Int Int => Int
      cd scan ascii end s idx end_idx =
        | idx >= end_idx = end_idx
        | (str char at s idx) == 0 or (str char at s idx) >= 128 = idx
        | otherwise = cd scan ascii end s (idx + 1) end_idx

fn :: cd byte slice step String Int Int Int String String String String => String
      cd byte slice step s idx run_end end_idx c0 c1 c2 c3 =
        | run_end >= end_idx = cd sb finish (c0 + (str slice s idx end_idx)) c1 c2 c3
        | otherwise =
          piece = (str slice s idx run_end) + (cd raw byte ub (((str char at s run_end) % 256 + 256) % 256))
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd byte slice loop s (run_end + 1) end_idx n0 n1 n2 n3

fn :: cd byte slice loop String Int Int String String String String => String
      cd byte slice loop s idx end_idx c0 c1 c2 c3 =
        | idx >= end_idx = cd sb finish c0 c1 c2 c3
        | otherwise      = cd byte slice step s idx (cd scan ascii end s idx end_idx) end_idx c0 c1 c2 c3

fn :: cd byte slice check String Int Int Int Int => String
      cd byte slice check s start end_idx b_prev b_end =
        | b_prev < 128 and (b_end < 128 or b_end >= 192) = str slice s start end_idx
        | otherwise = cd byte slice loop s start end_idx "" "" "" ""

fn :: cd byte slice String Int Int => String
      cd byte slice s start end_idx =
        | start >= end_idx = ""
        | start == 0 and end_idx >= (str len s) = s
        | otherwise = cd byte slice check s start end_idx (cd scan b prev s start) (cd scan b end s end_idx)

fn :: cd split char loop String String Int Int Int Int [String] [String] [String] Int => [String]
      cd split char loop s ch_str ch start idx len l0 l1 l2 cnt =
        | idx >= len =
          n0, n1, n2, _ = cd lb append (cd byte slice s start len) l0 l1 l2 cnt
          cd lb finish n0 n1 n2
        | (idx + 4096) <= len and (not (str contains (str slice s idx (idx + 4096)) ch_str)) =
          cd split char loop s ch_str ch start (idx + 4096) len l0 l1 l2 cnt
        | (str char at s idx) == ch =
          n0, n1, n2, ncnt = cd lb append (cd byte slice s start idx) l0 l1 l2 cnt
          cd split char loop s ch_str ch (idx + 1) (idx + 1) len n0 n1 n2 ncnt
        | otherwise =
          cd split char loop s ch_str ch start (idx + 1) len l0 l1 l2 cnt

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
        tbl = "0123456789abcdef"
        (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1))

fn :: cd hex enc loop String Int Int String String String String => String
      cd hex enc loop s idx len c0 c1 c2 c3 =
        | idx >= len = cd sb finish c0 c1 c2 c3
        | otherwise  =
          n0, n1, n2, n3 = cd sb append (cd hex enc byte (str char at s idx)) c0 c1 c2 c3
          cd hex enc loop s (idx + 1) len n0 n1 n2 n3

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: hex encode String => String
      hex encode s      =  cd hex enc loop s 0 (str len s) "" "" "" ""

fn :: cd hex dec loop String Int Int String String String String => String
      cd hex dec loop s idx len c0 c1 c2 c3 =
        | idx >= len = cd sb finish c0 c1 c2 c3
        | otherwise =
          hi = cd hex val (str char at s idx)
          lo = cd hex val (str char at s (idx + 1))
          b  = cd raw byte ub ((hi * 16) + lo)
          n0, n1, n2, n3 = cd sb append b c0 c1 c2 c3
          cd hex dec loop s (idx + 2) len n0 n1 n2 n3

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
-- @mitigates VUL-INPUT-001
fn :: hex decode String => String
      hex decode s      =
        | not (is valid hex s) = ""
        | otherwise            = cd hex dec loop s 0 (str len s) "" "" "" ""

-- ── RFC 4648 Standard Base64 & URL-Safe Base64url ────────────

fn :: cd b64 char String Int => String
      cd b64 char tbl    idx =
        i = idx % 64
        str slice tbl i (i + 1)

fn :: cd b64 pad suffix String Bool => String
      cd b64 pad suffix suffix True = suffix
      cd b64 pad suffix _ False = ""

fn :: cd b64 enc step String Int String Bool Int String String String String => String
      cd b64 enc step s idx tbl pad rem c0 c1 c2 c3 =
        | rem <= 0 = cd sb finish c0 c1 c2 c3
        | rem == 1 =
          b0   = str char at s idx
          out2 = (cd b64 char tbl (b0 / 4)) + (cd b64 char tbl ((b0 % 4) * 16)) + (cd b64 pad suffix "==" pad)
          cd sb finish (c0 + out2) c1 c2 c3
        | rem == 2 =
          b0   = str char at s idx
          b1   = str char at s (idx + 1)
          n    = (b0 * 256) + b1
          out3 = (cd b64 char tbl (n / 1024)) + (cd b64 char tbl ((n / 16) % 64)) + (cd b64 char tbl ((n % 16) * 4)) + (cd b64 pad suffix "=" pad)
          cd sb finish (c0 + out3) c1 c2 c3
        | otherwise =
          b0   = str char at s idx
          b1   = str char at s (idx + 1)
          b2   = str char at s (idx + 2)
          n    = (b0 * 65536) + (b1 * 256) + b2
          out4 = (cd b64 char tbl (n / 262144)) + (cd b64 char tbl ((n / 4096) % 64)) + (cd b64 char tbl ((n / 64) % 64)) + (cd b64 char tbl (n % 64))
          n0, n1, n2, n3 = cd sb append out4 c0 c1 c2 c3
          cd b64 enc step s (idx + 3) tbl pad (rem - 3) n0 n1 n2 n3

fn :: cd b64 enc rem String Int String Bool => String
      cd b64 enc rem s idx tbl pad = cd b64 enc step s idx tbl pad ((str len s) - idx) "" "" "" ""

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

fn :: cd strip one b64 pad String Int => String
      cd strip one b64 pad s n =
        | n <= 0                        = ""
        | (str char at s (n - 1)) == 61 = str slice s 0 (n - 1)
        | otherwise                     = s

fn :: cd strip b64 pad String Int => String
      cd strip b64 pad s n =
        | (n % 4) != 0 = s
        | otherwise =
          s1 = cd strip one b64 pad s n
          cd strip one b64 pad s1 (str len s1)

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

fn :: cd b64 dec step String Int Int Int String String String String => String
      cd b64 dec step s idx len rem c0 c1 c2 c3 =
        | rem <= 1 = cd sb finish c0 c1 c2 c3
        | rem == 2 =
          v0 = cd b64 val (str char at s idx)
          v1 = cd b64 val (str char at s (idx + 1))
          b0 = cd raw byte ub (((v0 * 4) + (v1 / 16)) % 256)
          cd sb finish (c0 + b0) c1 c2 c3
        | rem == 3 =
          v0 = cd b64 val (str char at s idx)
          v1 = cd b64 val (str char at s (idx + 1))
          v2 = cd b64 val (str char at s (idx + 2))
          n  = (v0 * 1024) + (v1 * 16) + (v2 / 4)
          b01 = (cd raw byte ub ((n / 256) % 256)) + (cd raw byte ub (n % 256))
          cd sb finish (c0 + b01) c1 c2 c3
        | otherwise =
          v0 = cd b64 val (str char at s idx)
          v1 = cd b64 val (str char at s (idx + 1))
          v2 = cd b64 val (str char at s (idx + 2))
          v3 = cd b64 val (str char at s (idx + 3))
          n  = (v0 * 262144) + (v1 * 4096) + (v2 * 64) + v3
          b0 = (n / 65536) % 256
          b1 = (n / 256) % 256
          b2 = n % 256
          chunk = (cd raw byte ub b0) + (cd raw byte ub b1) + (cd raw byte ub b2)
          n0, n1, n2, n3 = cd sb append chunk c0 c1 c2 c3
          cd b64 dec step s (idx + 4) len (rem - 4) n0 n1 n2 n3

fn :: cd b64 dec loop String Int Int => String
      cd b64 dec loop s idx len = cd b64 dec step s idx len (len - idx) "" "" "" ""

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

fn :: cd scan unres String String Int Int => Int
      cd scan unres s umap idx len =
        | idx >= len = len
        | (str char at umap ((str char at s idx) % 256)) == 49 =
          cd scan unres s umap (idx + 1) len
        | otherwise = idx

fn :: cd pct byte lut String Int => String
      cd pct byte lut lut b =
        ub = ((b % 256) + 256) % 256
        hi = ub / 16
        lo = ub % 16
        "%" + (str slice lut hi (hi + 1)) + (str slice lut lo (lo + 1))

fn :: cd url enc step String String String Int Int Int String String String String => String
      cd url enc step s umap lut run_start next_idx len c0 c1 c2 c3 =
        | next_idx >= len =
          | run_start == 0 = s
          | otherwise      = cd sb finish (c0 + (str slice s run_start len)) c1 c2 c3 |.
        | otherwise =
          piece = (str slice s run_start next_idx) + (cd pct byte lut lut (str char at s next_idx))
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd url enc loop s umap lut (next_idx + 1) len n0 n1 n2 n3

fn :: cd url enc loop String String String Int Int String String String String => String
      cd url enc loop s umap lut run_start len c0 c1 c2 c3 =
        | run_start >= len = cd sb finish c0 c1 c2 c3
        | otherwise        = cd url enc step s umap lut run_start (cd scan unres s umap run_start len) len c0 c1 c2 c3

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: url encode String => String
      url encode s      =
        umap = "0000000000000000000000000000000000000000000001101111111111000000011111111111111111111111111000010111111111111111111111111110001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
        cd url enc loop s umap "0123456789ABCDEF" 0 (str len s) "" "" "" ""

fn :: cd scan url plain String Int Int => Int
      cd scan url plain s idx len =
        | idx >= len = len
        | (str char at s idx) == 37 or (str char at s idx) == 43 = idx
        | otherwise = cd scan url plain s (idx + 1) len

fn :: cd url dec pct String Int Int Int Int String String String String String => String
      cd url dec pct s next_idx len hi lo prefix c0 c1 c2 c3 =
        | hi >= 0 and lo >= 0 =
          piece = prefix + (cd raw byte ub ((hi * 16) + lo))
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd url dec loop s (next_idx + 3) len n0 n1 n2 n3
        | otherwise =
          piece = prefix + "%"
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd url dec loop s (next_idx + 1) len n0 n1 n2 n3

fn :: cd url dec step String Int Int Int String String String String => String
      cd url dec step s run_start next_idx len c0 c1 c2 c3 =
        | next_idx >= len =
          | run_start == 0 = s
          | otherwise      = cd sb finish (c0 + (cd byte slice s run_start len)) c1 c2 c3 |.
        | (str char at s next_idx) == 43 =
          piece = (cd byte slice s run_start next_idx) + " "
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd url dec loop s (next_idx + 1) len n0 n1 n2 n3
        | (next_idx + 2) < len =
          prefix = cd byte slice s run_start next_idx
          hi = cd hex val (str char at s (next_idx + 1))
          lo = cd hex val (str char at s (next_idx + 2))
          cd url dec pct s next_idx len hi lo prefix c0 c1 c2 c3
        | otherwise =
          piece = (cd byte slice s run_start next_idx) + "%"
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd url dec loop s (next_idx + 1) len n0 n1 n2 n3

fn :: cd url dec loop String Int Int String String String String => String
      cd url dec loop s run_start len c0 c1 c2 c3 =
        | run_start >= len = cd sb finish c0 c1 c2 c3
        | otherwise        = cd url dec step s run_start (cd scan url plain s run_start len) len c0 c1 c2 c3

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: url decode String => String
      url decode s      =  cd url dec loop s 0 (str len s) "" "" "" ""

fn :: cd pair key (String String) => String
      cd pair key (k, _)          =  k

fn :: cd pair val (String String) => String
      cd pair val (_, v)          =  v

fn :: cd qs enc loop [String String] String String String String => String
      cd qs enc loop []          c0 c1 c2 c3 =  cd sb finish c0 c1 c2 c3
      cd qs enc loop (pair:rest) c0 c1 c2 c3 =
        piece = "&" + (url encode (cd pair key pair)) + "=" + (url encode (cd pair val pair))
        n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
        cd qs enc loop rest n0 n1 n2 n3

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: query string encode [String String] => String
      query string encode []              =  ""
      query string encode (pair:rest)     =
        first = (url encode (cd pair key pair)) + "=" + (url encode (cd pair val pair))
        cd qs enc loop rest first "" "" ""

fn :: cd parse kv at String Int => String String
      cd parse kv at item eq_idx =
        | eq_idx < 0 = (url decode item, "")
        | otherwise  = (url decode (cd byte slice item 0 eq_idx), url decode (cd byte slice item (eq_idx + 1) (str len item)))

fn :: cd parse kv item String => String String
      cd parse kv item item   =  cd parse kv at item (cd index of item "=")

fn :: cd kv lb append2 [String String] [String String] Int => [String String] [String String] [String String] Int
      cd kv lb append2 n1 l2 cnt =
        | (cnt % 1024) == 0 = ([], [], l2 :: n1, cnt)
        | otherwise         = ([], n1, l2, cnt)

fn :: cd kv lb append1 [String String] [String String] [String String] Int => [String String] [String String] [String String] Int
      cd kv lb append1 n0 l1 l2 cnt =
        | (cnt % 32) == 0 = cd kv lb append2 (l1 :: n0) l2 cnt
        | otherwise       = (n0, l1, l2, cnt)

fn :: cd kv lb append (String String) [String String] [String String] [String String] Int => [String String] [String String] [String String] Int
      cd kv lb append item l0 l1 l2 cnt =
        cd kv lb append1 (l0 :: [item]) l1 l2 (cnt + 1)

fn :: cd parse qs list [String] [String String] [String String] [String String] Int => [String String]
      cd parse qs list []       l0 l1 l2 _   =  l2 :: (l1 :: l0)
      cd parse qs list (x:rest) l0 l1 l2 cnt =
        | (str len x) == 0 = cd parse qs list rest l0 l1 l2 cnt
        | otherwise        =
          n0, n1, n2, ncnt = cd kv lb append (cd parse kv item x) l0 l1 l2 cnt
          cd parse qs list rest n0 n1 n2 ncnt

fn :: cd strip leading q String => String
      cd strip leading q qs     =
        | str starts with qs "?" = str slice qs 1 (str len qs)
        | otherwise              = qs

fn :: cd decode clean qs String => [String String]
      cd decode clean qs clean  =
        | (str len clean) == 0 = []
        | otherwise            = cd parse qs list (cd split char loop clean "&" 38 0 0 (str len clean) [] [] [] 0) [] [] [] 0

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: query string decode String => [String String]
      query string decode qs     =  cd decode clean qs (cd strip leading q qs)

-- ── RFC 8259 Lightweight JSON Formatting & Field Extraction ──

fn :: cd is json esc Int => Bool
      cd is json esc c =
        ub = ((c % 256) + 256) % 256
        ub < 32 or ub == 34 or ub == 92

fn :: cd scan json plain String Int Int => Int
      cd scan json plain s idx len =
        | idx >= len = len
        | cd is json esc (str char at s idx) = idx
        | otherwise = cd scan json plain s (idx + 1) len

fn :: cd json esc hex2 Int => String
      cd json esc hex2 ub =
        hi  = (ub / 16) % 16
        lo  = ub % 16
        tbl = "0123456789abcdef"
        "\\u00" + (str slice tbl hi (hi + 1)) + (str slice tbl lo (lo + 1))

fn :: cd json esc code ub Int => String
      cd json esc code ub ub =
        | ub == 34  = "\\\""
        | ub == 92  = "\\\\"
        | ub == 8   = "\\b"
        | ub == 12  = "\\f"
        | ub == 10  = "\\n"
        | ub == 13  = "\\r"
        | ub == 9   = "\\t"
        | otherwise = cd json esc hex2 ub

fn :: cd json esc code Int => String
      cd json esc code c =
        cd json esc code ub (((c % 256) + 256) % 256)

fn :: cd json esc step String Int Int Int String String String String => String
      cd json esc step s idx next_idx len c0 c1 c2 c3 =
        | next_idx >= len =
          | idx == 0  = s
          | otherwise = cd sb finish (c0 + (cd byte slice s idx len)) c1 c2 c3 |.
        | otherwise =
          piece = (cd byte slice s idx next_idx) + (cd json esc code (str char at s next_idx))
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd json esc loop s (next_idx + 1) len n0 n1 n2 n3

fn :: cd json esc loop String Int Int String String String String => String
      cd json esc loop s idx len c0 c1 c2 c3 =
        | idx >= len = cd sb finish c0 c1 c2 c3
        | otherwise  = cd json esc step s idx (cd scan json plain s idx len) len c0 c1 c2 c3

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
-- @mitigates VUL-INPUT-001
fn :: json escape String => String
      json escape s      =  cd json esc loop s 0 (str len s) "" "" "" ""

fn :: cd json unesc char String Int Int => String
      cd json unesc char s idx nc =
        | nc == 34  = "\""
        | nc == 92  = "\\"
        | nc == 47  = "/"
        | nc == 98  = char from code 8
        | nc == 102 = char from code 12
        | nc == 110 = "\n"
        | nc == 114 = "\r"
        | nc == 116 = "\t"
        | otherwise = str slice s (idx + 1) (idx + 2)

fn :: cd scan no backslash String Int Int => Int
      cd scan no backslash s idx len =
        | idx >= len = len
        | (str char at s idx) == 92 = idx
        | otherwise = cd scan no backslash s (idx + 1) len

fn :: cd json unesc cp Int Int => String Int
      cd json unesc cp next_idx cp =
        | cp <= 255 = (cd raw byte ub cp, next_idx + 6)
        | otherwise = (char from code cp, next_idx + 6)

fn :: cd json unesc u4 Int Int Int Int Int => String Int
      cd json unesc u4 next_idx d0 d1 d2 d3 =
        | d0 < 0 or d1 < 0 or d2 < 0 or d3 < 0 = ("\\u", next_idx + 2)
        | otherwise = cd json unesc cp next_idx ((((d0 * 16) + d1) * 256) + (d2 * 16) + d3)

fn :: cd json unesc step String Int Int Int String String String String => String
      cd json unesc step s idx next_idx len c0 c1 c2 c3 =
        | next_idx >= len =
          | idx == 0  = s
          | otherwise = cd sb finish (c0 + (cd byte slice s idx len)) c1 c2 c3 |.
        | (next_idx + 5) < len and (str char at s (next_idx + 1)) == 117 =
          d0 = cd hex val (str char at s (next_idx + 2))
          d1 = cd hex val (str char at s (next_idx + 3))
          d2 = cd hex val (str char at s (next_idx + 4))
          d3 = cd hex val (str char at s (next_idx + 5))
          rep, adv = cd json unesc u4 next_idx d0 d1 d2 d3
          piece = (cd byte slice s idx next_idx) + rep
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd json unesc loop s adv len n0 n1 n2 n3
        | (next_idx + 1) < len =
          piece = (cd byte slice s idx next_idx) + (cd json unesc char s next_idx (str char at s (next_idx + 1)))
          n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
          cd json unesc loop s (next_idx + 2) len n0 n1 n2 n3
        | otherwise =
          cd sb finish (c0 + (cd byte slice s idx len)) c1 c2 c3

fn :: cd json unesc loop String Int Int String String String String => String
      cd json unesc loop s idx len c0 c1 c2 c3 =
        | idx >= len = cd sb finish c0 c1 c2 c3
        | otherwise  = cd json unesc step s idx (cd scan no backslash s idx len) len c0 c1 c2 c3

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: json unescape String => String
      json unescape s      =
        | not (str contains s "\\") = s
        | otherwise                 = cd json unesc loop s 0 (str len s) "" "" "" ""

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

fn :: cd join json loop [String] String String String String => String
      cd join json loop []       c0 c1 c2 c3 =  cd sb finish c0 c1 c2 c3
      cd join json loop (x:rest) c0 c1 c2 c3 =
        n0, n1, n2, n3 = cd sb append ("," + x) c0 c1 c2 c3
        cd join json loop rest n0 n1 n2 n3

fn :: cd join json items [String] => String
      cd join json items []       =  ""
      cd join json items (x:rest) =  cd join json loop rest x "" "" ""

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: json array [String] => String
      json array items    =  "[" + (cd join json items items) + "]"

fn :: cd join json pairs loop [String String] String String String String => String
      cd join json pairs loop []          c0 c1 c2 c3 =  cd sb finish c0 c1 c2 c3
      cd join json pairs loop (pair:rest) c0 c1 c2 c3 =
        piece = "," + (json quote (cd pair key pair)) + ":" + (cd pair val pair)
        n0, n1, n2, n3 = cd sb append piece c0 c1 c2 c3
        cd join json pairs loop rest n0 n1 n2 n3

fn :: cd join json pairs [String String] => String
      cd join json pairs []              =  ""
      cd join json pairs (pair:rest)     =
        first = (json quote (cd pair key pair)) + ":" + (cd pair val pair)
        cd join json pairs loop rest first "" "" ""

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: json object [String String] => String
      json object pairs           =  "{" + (cd join json pairs pairs) + "}"

fn :: cd quote pair vals [String String] [String String] [String String] [String String] Int => [String String]
      cd quote pair vals []          l0 l1 l2 _   =  l2 :: (l1 :: l0)
      cd quote pair vals (pair:rest) l0 l1 l2 cnt =
        n0, n1, n2, ncnt = cd kv lb append (cd pair key pair, json quote (cd pair val pair)) l0 l1 l2 cnt
        cd quote pair vals rest n0 n1 n2 ncnt

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: json str object [String String] => String
      json str object pairs           =  json object (cd quote pair vals pairs [] [] [] 0)

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
fn :: codec json get str String String => String
      codec json get str doc    key    =
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
fn :: codec json get int String String Int => Int
      codec json get int doc key fallback = cd parse tok int (cd raw json token doc key) fallback

fn :: cd parse tok bool String Bool => Bool
      cd parse tok bool tok fallback =
        | tok == "true"  = True
        | tok == "false" = False
        | otherwise      = fallback

-- @implements FR-CODEC-001
-- @implements API-CODEC-001
fn :: codec json get bool String String Bool => Bool
      codec json get bool doc key fallback = cd parse tok bool (cd raw json token doc key) fallback
