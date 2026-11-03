-- ============================================================
-- src/main/ridgun/lib/locale.rg
-- Pure-Ridgun Unicode CLDR Locale Data Library for Cardinal Plurals,
-- UTC Date/Datetime Formatting, Number Formatting & Language Autonyms (LOCALE)
-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
-- @implements DM-Locale
-- ============================================================

module :: locale

type LocaleDatePatterns = LocaleDatePatterns String String String String String

type LocaleSpec = LocaleSpec String String String String String [String] [String] [String] [String] LocaleDatePatterns

-- ── String & List Helpers ───────────────────────────────────

fn :: loc ascii lower char Int => Int
      loc ascii lower char c   =
        | c >= 65 and c <= 90 = c + 32
        | otherwise           = c

fn :: loc tag base char String Int Int String Int => String
      loc tag base char s idx len acc c =
        | c == 45 or c == 95 or c == 46 or c == 64 = acc
        | c == 32 or c == 9 =
          | acc == "" = loc tag base loop s (idx + 1) len acc
          | otherwise = acc |.
        | otherwise = loc tag base loop s (idx + 1) len (acc + (char from code (loc ascii lower char c)))

fn :: loc tag base loop String Int Int String => String
      loc tag base loop s idx len acc =
        | idx >= len = acc
        | otherwise  = loc tag base char s idx len acc (str char at s idx)

fn :: loc extract base tag String => String
      loc extract base tag raw    =
        loc tag base loop raw 0 (str len raw) ""

fn :: loc nth str [String] Int String => String
      loc nth str [] _ fallback = fallback
      loc nth str (x:rest) idx fallback =
        | idx <= 0  = x
        | otherwise = loc nth str rest (idx - 1) fallback

fn :: loc replace all loop String String String Int Int Int String => String
      loc replace all loop s pat repl pos slen plen acc =
        | (pos + plen) > slen = acc + (str slice s pos slen)
        | (str slice s pos (pos + plen)) == pat = loc replace all loop s pat repl (pos + plen) slen plen (acc + repl)
        | otherwise = loc replace all loop s pat repl (pos + 1) slen plen (acc + (str slice s pos (pos + 1)))

fn :: loc replace all String String String => String
      loc replace all s pat repl =
        | pat == "" = s
        | otherwise = loc replace all loop s pat repl 0 (str len s) (str len pat) ""

-- ── Built-in CLDR Locale Specifications (es, ca, eu, gl, pt, sv, en) ──

fn :: loc nbsp => String
      loc nbsp =  (char from code 194) + (char from code 160)

fn :: loc spec es => LocaleSpec
      loc spec es =
        LocaleSpec "es" "Español" "one_many_millions" "." "," ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"] ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"] ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"] ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"] (LocaleDatePatterns "%DD/%MM/%YYYY" "%D %MMM %YYYY" "%D de %MMMM de %YYYY" "%EEEE, %D de %MMMM de %YYYY" ", ")

fn :: loc spec ca => LocaleSpec
      loc spec ca =
        LocaleSpec "ca" "Català" "one_many_millions" "." "," ["gener", "febrer", "març", "abril", "maig", "juny", "juliol", "agost", "setembre", "octubre", "novembre", "desembre"] ["gen.", "febr.", "març", "abr.", "maig", "juny", "jul.", "ag.", "set.", "oct.", "nov.", "des."] ["dilluns", "dimarts", "dimecres", "dijous", "divendres", "dissabte", "diumenge"] ["dl.", "dt.", "dc.", "dj.", "dv.", "ds.", "dg."] (LocaleDatePatterns "%DD/%MM/%YYYY" "%D %de_MMM de %YYYY" "%D %de_MMMM de %YYYY" "%EEEE, %D %de_MMMM de %YYYY" ", ")

fn :: loc spec eu => LocaleSpec
      loc spec eu =
        LocaleSpec "eu" "Euskara" "one_other" "." "," ["urtarrila", "otsaila", "martxoa", "apirila", "maiatza", "ekaina", "uztaila", "abuztua", "iraila", "urria", "azaroa", "abendua"] ["urt.", "ots.", "mar.", "api.", "mai.", "eka.", "uzt.", "abu.", "ira.", "urr.", "aza.", "abe."] ["astelehena", "asteartea", "asteazkena", "osteguna", "ostirala", "larunbata", "igandea"] ["al.", "ar.", "az.", "og.", "or.", "lr.", "ig."] (LocaleDatePatterns "%YYYY/%MM/%DD" "%YYYY(e)ko %MMM %D" "%YYYY(e)ko %MMMM_eu %Da" "%YYYY(e)ko %MMMM_eu %Da, %EEEE" " ")

fn :: loc spec gl => LocaleSpec
      loc spec gl =
        LocaleSpec "gl" "Galego" "one_other" "." "," ["xaneiro", "febreiro", "marzo", "abril", "maio", "xuño", "xullo", "agosto", "setembro", "outubro", "novembro", "decembro"] ["xan.", "feb.", "mar.", "abr.", "mai.", "xuñ.", "xul.", "ago.", "set.", "out.", "nov.", "dec."] ["luns", "martes", "mércores", "xoves", "venres", "sábado", "domingo"] ["luns", "mar.", "mér.", "xov.", "ven.", "sáb.", "dom."] (LocaleDatePatterns "%DD/%MM/%YYYY" "%D de %MMM de %YYYY" "%D de %MMMM de %YYYY" "%EEEE, %D de %MMMM de %YYYY" ", ")

fn :: loc spec pt => LocaleSpec
      loc spec pt =
        LocaleSpec "pt" "Português" "one_many_millions" "." "," ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"] ["jan.", "fev.", "mar.", "abr.", "mai.", "jun.", "jul.", "ago.", "set.", "out.", "nov.", "dez."] ["segunda-feira", "terça-feira", "quarta-feira", "quinta-feira", "sexta-feira", "sábado", "domingo"] ["seg.", "ter.", "qua.", "qui.", "sex.", "sáb.", "dom."] (LocaleDatePatterns "%DD/%MM/%YYYY" "%D de %MMM de %YYYY" "%D de %MMMM de %YYYY" "%EEEE, %D de %MMMM de %YYYY" ", ")

fn :: loc spec sv => LocaleSpec
      loc spec sv =
        LocaleSpec "sv" "Svenska" "one_other" (loc nbsp) "," ["januari", "februari", "mars", "april", "maj", "juni", "juli", "augusti", "september", "oktober", "november", "december"] ["jan.", "feb.", "mars", "apr.", "maj", "juni", "juli", "aug.", "sep.", "okt.", "nov.", "dec."] ["måndag", "tisdag", "onsdag", "torsdag", "fredag", "lördag", "söndag"] ["mån", "tis", "ons", "tors", "fre", "lör", "sön"] (LocaleDatePatterns "%YYYY-%MM-%DD" "%D %MMM %YYYY" "%D %MMMM %YYYY" "%EEEE %D %MMMM %YYYY" " ")

fn :: loc spec en => LocaleSpec
      loc spec en =
        LocaleSpec "en" "English" "one_other" "," "." ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"] ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"] ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"] ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] (LocaleDatePatterns "%MM/%DD/%YYYY" "%MMM %D, %YYYY" "%MMMM %D, %YYYY" "%EEEE, %MMMM %D, %YYYY" ", ")

fn :: loc spec it => LocaleSpec
      loc spec it =
        LocaleSpec "it" "Italiano" "one_many_millions" "." "," ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio", "agosto", "settembre", "ottobre", "novembre", "dicembre"] ["gen", "feb", "mar", "apr", "mag", "giu", "lug", "ago", "set", "ott", "nov", "dic"] ["lunedì", "martedì", "mercoledì", "giovedì", "venerdì", "sabato", "domenica"] ["lun", "mar", "mer", "gio", "ven", "sab", "dom"] (LocaleDatePatterns "%DD/%MM/%YYYY" "%D %MMM %YYYY" "%D %MMMM %YYYY" "%EEEE %D %MMMM %YYYY" ", ")

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: supported locales => [String]
      supported locales =
        ["es", "ca", "eu", "gl", "pt", "sv", "en", "it"]

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
-- @implements DM-Locale
fn :: default locales => [LocaleSpec]
      default locales =
        [loc spec es, loc spec ca, loc spec eu, loc spec gl, loc spec pt, loc spec sv, loc spec en, loc spec it]

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
-- @implements DM-Locale
fn :: register locale LocaleSpec [LocaleSpec] => [LocaleSpec]
      register locale spec       registry     =
        [spec] :: registry

fn :: loc spec code LocaleSpec => String
      loc spec code (LocaleSpec c _ _ _ _ _ _ _ _ _) = c

fn :: loc spec autonym LocaleSpec => String
      loc spec autonym (LocaleSpec _ name _ _ _ _ _ _ _ _) = name

fn :: loc spec plural rule LocaleSpec => String
      loc spec plural rule (LocaleSpec _ _ rule _ _ _ _ _ _ _) = rule

fn :: loc spec group sep LocaleSpec => String
      loc spec group sep (LocaleSpec _ _ _ gsep _ _ _ _ _ _) = gsep

fn :: loc spec dec sep LocaleSpec => String
      loc spec dec sep (LocaleSpec _ _ _ _ dsep _ _ _ _ _) = dsep

fn :: loc spec months wide LocaleSpec => [String]
      loc spec months wide (LocaleSpec _ _ _ _ _ mw _ _ _ _) = mw

fn :: loc spec months short LocaleSpec => [String]
      loc spec months short (LocaleSpec _ _ _ _ _ _ ms _ _ _) = ms

fn :: loc spec weekdays wide LocaleSpec => [String]
      loc spec weekdays wide (LocaleSpec _ _ _ _ _ _ _ ww _ _) = ww

fn :: loc spec weekdays short LocaleSpec => [String]
      loc spec weekdays short (LocaleSpec _ _ _ _ _ _ _ _ ws _) = ws

fn :: loc spec date patterns LocaleSpec => LocaleDatePatterns
      loc spec date patterns (LocaleSpec _ _ _ _ _ _ _ _ _ pats) = pats

fn :: loc find in registry [LocaleSpec] String => LocaleSpec
      loc find in registry [] _ = loc spec en
      loc find in registry (s:rest) base =
        | (loc spec code s) == base = s
        | otherwise                 = loc find in registry rest base

fn :: loc lookup base with [LocaleSpec] String => LocaleSpec
      loc lookup base with registry base =
        | base == "" or base == "root" = loc spec en
        | otherwise                    = loc find in registry registry base

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
-- @implements DM-Locale
fn :: lookup locale with [LocaleSpec] String => LocaleSpec
      lookup locale with registry     tag    =
        loc lookup base with registry (loc extract base tag tag)

fn :: loc lookup base String => LocaleSpec
      loc lookup base base   =
        | base == "es" = loc spec es
        | base == "ca" = loc spec ca
        | base == "eu" = loc spec eu
        | base == "gl" = loc spec gl
        | base == "pt" = loc spec pt
        | base == "sv" = loc spec sv
        | base == "it" = loc spec it
        | otherwise    = loc spec en

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
-- @implements DM-Locale
fn :: lookup locale String => LocaleSpec
      lookup locale tag    =
        loc lookup base (loc extract base tag tag)

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: normalize locale String => String
      normalize locale tag    =
        loc spec code (lookup locale tag)

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: language name String => String
      language name tag    =
        loc spec autonym (lookup locale tag)

-- ── Cardinal Plural Rules (.po 2-Form Default & Strict CLDR 46) ──

fn :: loc abs int Int => Int
      loc abs int n   =
        | n < 0     = 0 - n
        | otherwise = n

fn :: loc eval plural an String Int Bool => String
      loc eval plural an rule an strict_cldr =
        | rule == "other_only" = "other"
        | rule == "one_zero_one" =
          | an == 0 or an == 1 = "one"
          | otherwise          = "other" |.
        | rule == "one_many_millions" =
          | an == 1 = "one"
          | strict_cldr and an != 0 and (an % 1000000) == 0 = "many"
          | otherwise = "other" |.
        | otherwise =
          | an == 1   = "one"
          | otherwise = "other"

fn :: loc eval plural rule String Int Bool => String
      loc eval plural rule rule n strict_cldr =
        loc eval plural an rule (loc abs int n) strict_cldr

fn :: loc categories for rule String Bool => [String]
      loc categories for rule rule strict_cldr =
        | rule == "other_only"                        = ["other"]
        | rule == "one_many_millions" and strict_cldr = ["one", "many", "other"]
        | otherwise                                   = ["one", "other"]

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: plural category String Int => String
      plural category tag    n   =
        spec = lookup locale tag
        loc eval plural rule (loc spec plural rule spec) n False

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: plural categories String => [String]
      plural categories tag    =
        spec = lookup locale tag
        loc categories for rule (loc spec plural rule spec) False

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: plural category cldr String Int => String
      plural category cldr tag    n   =
        spec = lookup locale tag
        loc eval plural rule (loc spec plural rule spec) n True

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: plural categories cldr String => [String]
      plural categories cldr tag    =
        spec = lookup locale tag
        loc categories for rule (loc spec plural rule spec) True

fn :: loc index in cats [String] String Int => Int
      loc index in cats []       _      _   =  0
      loc index in cats (c:rest) target idx =
        | c == target = idx
        | otherwise   = loc index in cats rest target (idx + 1)

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: plural index String Int => Int
      plural index tag    n   =
        loc index in cats (plural categories tag) (plural category tag n) 0

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: plural index cldr String Int => Int
      plural index cldr tag    n   =
        loc index in cats (plural categories cldr tag) (plural category cldr tag n) 0

-- ── Civil UTC Calendar & Date/Datetime Formatting ───────────

fn :: loc floor div qr Int Int => Int
      loc floor div qr q r =
        | r < 0     = q - 1
        | otherwise = q

fn :: loc floor div Int Int => Int
      loc floor div a   b   =
        loc floor div qr (a / b) (a % b)

fn :: loc floor mod r Int Int => Int
      loc floor mod r r b =
        | r < 0     = r + b
        | otherwise = r

fn :: loc floor mod Int Int => Int
      loc floor mod a   b   =
        loc floor mod r (a % b) b

fn :: loc ymd month Int => Int
      loc ymd month mp  =
        | mp < 10   = mp + 3
        | otherwise = mp - 9

fn :: loc ymd year Int Int => Int
      loc ymd year y   m   =
        | m <= 2    = y + 1
        | otherwise = y

fn :: loc days to ymd Int   => Int Int Int
      loc days to ymd z_raw =
        z   = z_raw + 719468
        era = loc floor div z 146097
        doe = z - (era * 146097)
        yoe = (doe - (doe / 1460) + (doe / 36524) - (doe / 146096)) / 365
        y   = yoe + (era * 400)
        doy = doe - ((365 * yoe) + (yoe / 4) - (yoe / 100))
        mp  = ((5 * doy) + 2) / 153
        d   = doy - (((153 * mp) + 2) / 5) + 1
        m   = loc ymd month mp
        yr  = loc ymd year y m
        (yr, m, d)

fn :: loc iso weekday norm Int => Int
      loc iso weekday norm w0  =
        | w0 == 0   = 7
        | otherwise = w0

fn :: loc iso weekday from days Int => Int
      loc iso weekday from days days =
        loc iso weekday norm (loc floor mod (days + 4) 7)

fn :: loc pad2 Int => String
      loc pad2 n   =
        | n >= 0 and n < 10 = "0" + (int to str n)
        | otherwise         = int to str n

fn :: loc pad4 Int => String
      loc pad4 n   =
        | n < 0     = int to str n
        | n < 10    = "000" + (int to str n)
        | n < 100   = "00" + (int to str n)
        | n < 1000  = "0" + (int to str n)
        | otherwise = int to str n

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: month name String Int => String
      month name tag    m   =
        | m < 1 or m > 12 = ""
        | otherwise       = loc nth str (loc spec months wide (lookup locale tag)) (m - 1) ""

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: month short name String Int => String
      month short name tag    m   =
        | m < 1 or m > 12 = ""
        | otherwise       = loc nth str (loc spec months short (lookup locale tag)) (m - 1) ""

fn :: loc norm weekday idx Int => Int
      loc norm weekday idx w   =
        | w == 0    = 7
        | otherwise = w

fn :: loc weekday wide by nw String Int => String
      loc weekday wide by nw tag nw =
        | nw < 1 or nw > 7 = ""
        | otherwise        = loc nth str (loc spec weekdays wide (lookup locale tag)) (nw - 1) ""

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: weekday name String Int => String
      weekday name tag    w   =
        loc weekday wide by nw tag (loc norm weekday idx w)

fn :: loc weekday short by nw String Int => String
      loc weekday short by nw tag nw =
        | nw < 1 or nw > 7 = ""
        | otherwise        = loc nth str (loc spec weekdays short (lookup locale tag)) (nw - 1) ""

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: weekday short name String Int => String
      weekday short name tag    w   =
        loc weekday short by nw tag (loc norm weekday idx w)

fn :: loc ca prep char String Int => String
      loc ca prep char m_str c =
        | c == 97 or c == 101 or c == 105 or c == 111 or c == 117 = "d'" + m_str
        | otherwise = "de " + m_str

fn :: loc ca prep month String => String
      loc ca prep month m_str  =
        | m_str == "" = ""
        | otherwise   = loc ca prep char m_str (loc ascii lower char (str char at m_str 0))

fn :: loc eu genitive len String Int => String
      loc eu genitive len m_str mlen =
        | mlen > 0 and (str char at m_str (mlen - 1)) == 97 = (str slice m_str 0 (mlen - 1)) + "aren"
        | otherwise = m_str + "ren"

fn :: loc eu genitive month String => String
      loc eu genitive month m_str  =
        loc eu genitive len m_str (str len m_str)

fn :: loc select date pattern LocaleDatePatterns String => String
      loc select date pattern (LocaleDatePatterns p_short p_med p_long p_full _) style =
        | style == "short"  = p_short
        | style == "medium" = p_med
        | style == "full"   = p_full
        | otherwise         = p_long

fn :: loc select dt join LocaleDatePatterns => String
      loc select dt join (LocaleDatePatterns _ _ _ _ dt_join) = dt_join

fn :: loc render date pattern LocaleSpec String Int Int Int Int => String
      loc render date pattern spec pat y m d wd =
        m_wide  = loc nth str (loc spec months wide spec) (m - 1) ""
        m_short = loc nth str (loc spec months short spec) (m - 1) ""
        w_wide  = loc nth str (loc spec weekdays wide spec) (wd - 1) ""
        w_short = loc nth str (loc spec weekdays short spec) (wd - 1) ""
        s0  = loc replace all pat "%YYYY" (loc pad4 y)
        s1  = loc replace all s0 "%YY" (loc pad2 (loc floor mod y 100))
        s2  = loc replace all s1 "%MMMM_eu" (loc eu genitive month m_wide)
        s3  = loc replace all s2 "%de_MMMM" (loc ca prep month m_wide)
        s4  = loc replace all s3 "%de_MMM" (loc ca prep month m_short)
        s5  = loc replace all s4 "%MMMM" m_wide
        s6  = loc replace all s5 "%MMM" m_short
        s7  = loc replace all s6 "%MM" (loc pad2 m)
        s8  = loc replace all s7 "%M" (int to str m)
        s9  = loc replace all s8 "%DD" (loc pad2 d)
        s10 = loc replace all s9 "%D" (int to str d)
        s11 = loc replace all s10 "%EEEE" w_wide
        loc replace all s11 "%EEE" w_short

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: format date String String Int      => String
      format date tag    style  unix_sec =
        spec    = lookup locale tag
        days    = loc floor div unix_sec 86400
        y, m, d = loc days to ymd days
        wd      = loc iso weekday from days days
        pat     = loc select date pattern (loc spec date patterns spec) style
        loc render date pattern spec pat y m d wd

fn :: loc format time style String Int Int Int => String
      loc format time style style hh mm ss =
        | style == "short" = (loc pad2 hh) + ":" + (loc pad2 mm)
        | otherwise        = (loc pad2 hh) + ":" + (loc pad2 mm) + ":" + (loc pad2 ss)

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: format datetime String String Int      => String
      format datetime tag    style  unix_sec =
        spec     = lookup locale tag
        days     = loc floor div unix_sec 86400
        rem_sec  = loc floor mod unix_sec 86400
        hh       = rem_sec / 3600
        mm       = (rem_sec % 3600) / 60
        ss       = rem_sec % 60
        y, m, d  = loc days to ymd days
        wd       = loc iso weekday from days days
        pats     = loc spec date patterns spec
        pat      = loc select date pattern pats style
        date_str = loc render date pattern spec pat y m d wd
        time_str = loc format time style style hh mm ss
        date_str + (loc select dt join pats) + time_str

-- ── Localized Integer & Decimal Number Formatting ───────────

fn :: loc join grouped String String String => String
      loc join grouped chunk gsep acc =
        | acc == "" = chunk
        | otherwise = chunk + gsep + acc

fn :: loc group digits loop String Int String String => String
      loc group digits loop digits end_pos gsep acc =
        | end_pos <= 3 = loc join grouped (str slice digits 0 end_pos) gsep acc
        | otherwise    = loc group digits loop digits (end_pos - 3) gsep (loc join grouped (str slice digits (end_pos - 3) end_pos) gsep acc)

fn :: loc format uint digits String String => String
      loc format uint digits digits gsep =
        | gsep == "" or (str len digits) <= 3 = digits
        | otherwise                           = loc group digits loop digits (str len digits) gsep ""

fn :: loc pos int digits Int String => String
      loc pos int digits n acc =
        | n <= 0    = acc
        | otherwise = loc pos int digits (n / 10) ((char from code (48 + (n % 10))) + acc)

fn :: loc uint to digits Int => String
      loc uint to digits n   =
        | n == 0         = "0"
        | n > 0          = loc pos int digits n ""
        | n > (0 - 10)   = char from code (48 + (0 - n))
        | otherwise      = loc pos int digits (0 - (n / 10)) (char from code (48 + (0 - (n % 10))))

fn :: loc prepend neg Int String  => String
      loc prepend neg n   grouped =
        | n < 0     = "-" + grouped
        | otherwise = grouped

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: format int String Int => String
      format int tag    n   =
        spec = lookup locale tag
        gsep = loc spec group sep spec
        loc prepend neg n (loc format uint digits (loc uint to digits n) gsep)

fn :: loc pow10 Int Int => Int
      loc pow10 k   acc =
        | k <= 0    = acc
        | otherwise = loc pow10 (k - 1) (acc * 10)

fn :: loc pow10 real Int Real => Real
      loc pow10 real k   acc  =
        | k <= 0    = acc
        | otherwise = loc pow10 real (k - 1) (acc * 10.0)

fn :: loc real to int loop Real Int Real Int => Int
      loc real to int loop rem bit_int bit_val acc =
        | bit_int <= 0   = acc
        | rem >= bit_val = loc real to int loop (rem - bit_val) (bit_int / 2) (bit_val / 2.0) (acc + bit_int)
        | otherwise      = loc real to int loop rem (bit_int / 2) (bit_val / 2.0) acc

fn :: loc real to uint Real => Int
      loc real to uint val  =
        | val <= 0.0 = 0
        | otherwise  = loc real to int loop val 4503599627370496 4503599627370496.0 0

fn :: loc pad left zeros String Int => String
      loc pad left zeros s target_len =
        | (str len s) >= target_len = s
        | otherwise                 = loc pad left zeros ("0" + s) target_len

fn :: loc abs float Real => Real
      loc abs float val  =
        | val < 0.0 = 0.0 - val
        | otherwise = val

fn :: loc sign str float Real => String
      loc sign str float val  =
        | val < 0.0 = "-"
        | otherwise = ""

fn :: loc clamp frac digits Int => Int
      loc clamp frac digits d   =
        | d > 9     = 9
        | otherwise = d

fn :: loc format decimal scaled String String String Real Int => String
      loc format decimal scaled sign_s gsep dsep abs_v clamped_d =
        scale      = loc pow10 clamped_d 1
        scale_r    = loc pow10 real clamped_d 1.0
        scaled_int = loc real to uint ((abs_v * scale_r) + 0.5)
        int_part   = scaled_int / scale
        frac_part  = scaled_int % scale
        int_str    = loc format uint digits (loc uint to digits int_part) gsep
        frac_str   = loc pad left zeros (loc uint to digits frac_part) clamped_d
        sign_s + int_str + dsep + frac_str

fn :: loc format decimal impl String String String Real Int => String
      loc format decimal impl sign_s gsep dsep abs_v frac_digits =
        | frac_digits <= 0 = sign_s + (loc format uint digits (loc uint to digits (loc real to uint (abs_v + 0.5))) gsep)
        | otherwise        = loc format decimal scaled sign_s gsep dsep abs_v (loc clamp frac digits frac_digits)

-- @implements FR-LOCALE-001
-- @implements API-LOCALE-001
fn :: format decimal String Real Int         => String
      format decimal tag    val  frac_digits =
        spec = lookup locale tag
        loc format decimal impl (loc sign str float val) (loc spec group sep spec) (loc spec dec sep spec) (loc abs float val) frac_digits
