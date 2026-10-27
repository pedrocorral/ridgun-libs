-- ============================================================
-- src/main/ridgun/lib/ini.rg
-- Pure-Ridgun INI Sectioned Configuration & Dotenv Parser, Interpolator & Serializer Library (INI)
-- @implements FR-INI-001
-- @implements API-INI-001
-- @implements DM-Ini
-- @mitigates VUL-INPUT-001
-- ============================================================

module :: ini

type IniEntry = IniEntry String String

type IniSection = section_name: String, entries: [IniEntry]

type IniDoc = sections: [IniSection]

-- ── Whitespace, Comment & Line Helpers ───────────────────────

fn :: ini is hspace Int => Bool
      ini is hspace c = c == 32 or c == 9 or c == 13

fn :: ini trim left loop String Int Int => String
      ini trim left loop s pos len =
        | pos >= len = ""
        | ini is hspace (str_char_at s pos) = ini trim left loop s (pos + 1) len
        | otherwise = str_slice s pos len

fn :: ini trim right loop String Int => String
      ini trim right loop s end_pos =
        | end_pos <= 0 = ""
        | ini is hspace (str_char_at s (end_pos - 1)) = ini trim right loop s (end_pos - 1)
        | otherwise = str_slice s 0 end_pos

fn :: ini trim String => String
      ini trim s = ini trim left loop (ini trim right loop s (str_len s)) 0 (str_len (ini trim right loop s (str_len s)))

fn :: ini split lines loop String Int Int Int [String] => [String]
      ini split lines loop s pos len start acc =
        | pos >= len and start == len = acc
        | pos >= len = acc :: [str_slice s start len]
        | (str_char_at s pos) == 10 = ini split lines loop s (pos + 1) len (pos + 1) (acc :: [str_slice s start pos])
        | otherwise = ini split lines loop s (pos + 1) len start acc

fn :: ini skip quoted String Int Int Int => Int
      ini skip quoted s pos len q =
        | pos >= len = len
        | (str_char_at s pos) == 92 = ini skip quoted s (pos + 2) len q
        | (str_char_at s pos) == q = pos + 1
        | otherwise = ini skip quoted s (pos + 1) len q

fn :: ini strip comment loop String Int Int => String
      ini strip comment loop s pos len =
        | pos >= len = s
        | (str_char_at s pos) == 34 = ini strip comment loop s (ini skip quoted s (pos + 1) len 34) len
        | (str_char_at s pos) == 39 = ini strip comment loop s (ini skip quoted s (pos + 1) len 39) len
        | (str_char_at s pos) == 35 or (str_char_at s pos) == 59 = str_slice s 0 pos
        | (pos + 1) < len and (str_char_at s pos) == 45 and (str_char_at s (pos + 1)) == 45 = str_slice s 0 pos
        | otherwise = ini strip comment loop s (pos + 1) len

fn :: ini unquote unescape loop String Int Int String => String
      ini unquote unescape loop s pos len acc =
        | pos >= len = acc
        | (str_char_at s pos) == 92 and (pos + 1) < len and (str_char_at s (pos + 1)) == 110 = ini unquote unescape loop s (pos + 2) len (acc + (char_from_code 10))
        | (str_char_at s pos) == 92 and (pos + 1) < len and (str_char_at s (pos + 1)) == 116 = ini unquote unescape loop s (pos + 2) len (acc + (char_from_code 9))
        | (str_char_at s pos) == 92 and (pos + 1) < len = ini unquote unescape loop s (pos + 1 + 1) len (acc + (str_slice s (pos + 1) (pos + 2)))
        | otherwise = ini unquote unescape loop s (pos + 1) len (acc + (str_slice s pos (pos + 1)))

fn :: ini clean val String => String
      ini clean val raw =
        tr = ini trim raw
        len = str_len tr
        ini clean val len tr len

fn :: ini clean val len String Int => String
      ini clean val len tr len =
        | len >= 2 and (str_char_at tr 0) == 34 and (str_char_at tr (len - 1)) == 34 = ini unquote unescape loop (str_slice tr 1 (len - 1)) 0 (len - 2) ""
        | len >= 2 and (str_char_at tr 0) == 39 and (str_char_at tr (len - 1)) == 39 = str_slice tr 1 (len - 1)
        | otherwise = tr

-- ── Key-Value Pair Helpers (`[IniEntry]`) ────────────────────

fn :: ini p key IniEntry => String
      ini p key (IniEntry k _) = k

fn :: ini p val IniEntry => String
      ini p val (IniEntry _ v) = v

fn :: ini kv get [IniEntry] String String => String
      ini kv get [] _ fallback = fallback
      ini kv get (pair:rest) key fallback =
        | (ini p key pair) == key = ini p val pair
        | otherwise = ini kv get rest key fallback

fn :: ini kv put [IniEntry] String String => [IniEntry]
      ini kv put [] key val = [IniEntry key val]
      ini kv put (pair:rest) key val =
        | (ini p key pair) == key = [IniEntry key val] :: rest
        | otherwise = [pair] :: (ini kv put rest key val)

-- ── `${VAR}` Variable Interpolation ──────────────────────────

fn :: ini find rbrace String Int Int => Int
      ini find rbrace s pos len =
        | pos >= len = (0 - 1)
        | (str_char_at s pos) == 125 = pos
        | otherwise = ini find rbrace s (pos + 1) len

fn :: ini expand brace String Int Int [IniEntry] String Int => String
      ini expand brace s pos len env acc close_p =
        | close_p == (0 - 1) = ini interpolate loop s (pos + 1) len env (acc + "$")
        | otherwise = ini interpolate loop s (close_p + 1) len env (acc + (ini kv get env (str_slice s (pos + 2) close_p) ""))

fn :: ini interpolate loop String Int Int [IniEntry] String => String
      ini interpolate loop s pos len env acc =
        | pos >= len = acc
        | (pos + 1) < len and (str_char_at s pos) == 36 and (str_char_at s (pos + 1)) == 123 = ini expand brace s pos len env acc (ini find rbrace s (pos + 2) len)
        | otherwise = ini interpolate loop s (pos + 1) len env (acc + (str_slice s pos (pos + 1)))

fn :: ini interpolate String [IniEntry] => String
      ini interpolate s env = ini interpolate loop s 0 (str_len s) env ""

-- ── Sectioned INI Document Helpers ───────────────────────────

fn :: ini sec put [IniSection] String String String => [IniSection]
      ini sec put [] sec key val = [IniSection sec [IniEntry key val]]
      ini sec put (s:rest) sec key val =
        | (section_name s) == sec = [IniSection sec (ini kv put (entries s) key val)] :: rest
        | otherwise = [s] :: (ini sec put rest sec key val)

fn :: ini sec ensure [IniSection] String => [IniSection]
      ini sec ensure [] sec = [IniSection sec []]
      ini sec ensure (s:rest) sec =
        | (section_name s) == sec = [s] :: rest
        | otherwise = [s] :: (ini sec ensure rest sec)

fn :: ini sec get [IniSection] String String String => String
      ini sec get [] _ _ fallback = fallback
      ini sec get (s:rest) sec key fallback =
        | (section_name s) == sec = ini kv get (entries s) key fallback
        | otherwise = ini sec get rest sec key fallback

fn :: ini find eq String Int Int => Int
      ini find eq s pos len =
        | pos >= len = (0 - 1)
        | (str_char_at s pos) == 61 = pos
        | otherwise = ini find eq s (pos + 1) len

fn :: ini strip export String => String
      ini strip export tr =
        | str_starts_with tr "export " = ini trim (str_slice tr 7 (str_len tr))
        | otherwise = tr

fn :: ini parse kv at String [IniSection] String Int => [IniSection]
      ini parse kv at line secs cur_s eq_pos =
        | eq_pos == (0 - 1) = secs
        | otherwise = ini sec put secs cur_s (ini trim (str_slice line 0 eq_pos)) (ini interpolate (ini clean val (str_slice line (eq_pos + 1) (str_len line))) (ini sec entries secs cur_s))

fn :: ini sec entries [IniSection] String => [IniEntry]
      ini sec entries [] _ = []
      ini sec entries (s:rest) sec =
        | (section_name s) == sec = entries s
        | otherwise = ini sec entries rest sec

fn :: ini parse lines [String] [IniSection] String => [IniSection]
      ini parse lines [] secs _ = secs
      ini parse lines (l:ls) secs cur_s =
        clean = ini trim (ini strip comment loop l 0 (str_len l))
        ini parse clean line clean ls secs cur_s

fn :: ini parse sec hdr String [String] [IniSection] => [IniSection]
      ini parse sec hdr clean ls secs =
        new_sec = ini trim (str_slice clean 1 ((str_len clean) - 1))
        ini parse lines ls (ini sec ensure secs new_sec) new_sec

fn :: ini parse kv line String [String] [IniSection] String => [IniSection]
      ini parse kv line clean ls secs cur_s =
        stripped = ini strip export clean
        next_secs = ini parse kv at stripped secs cur_s (ini find eq stripped 0 (str_len stripped))
        ini parse lines ls next_secs cur_s

fn :: ini parse clean line String [String] [IniSection] String => [IniSection]
      ini parse clean line "" ls secs cur_s = ini parse lines ls secs cur_s
      ini parse clean line clean ls secs cur_s =
        | (str_char_at clean 0) == 91 and (str_char_at clean ((str_len clean) - 1)) == 93 = ini parse sec hdr clean ls secs
        | otherwise = ini parse kv line clean ls secs cur_s

-- @implements FR-INI-001
-- @implements API-INI-001
fn :: ini parse String => IniDoc
      ini parse src =
        lines = ini split lines loop src 0 (str_len src) 0 []
        IniDoc (ini parse lines lines [] "")

-- @implements FR-INI-001
-- @implements API-INI-001
fn :: dotenv parse String => [IniEntry]
      dotenv parse src =
        doc = ini parse src
        ini sec entries (sections doc) ""

-- ── Queries, Updates & Serialization ─────────────────────────

-- @implements FR-INI-001
-- @implements API-INI-001
fn :: ini get IniDoc String String String => String
      ini get doc sec key fallback = ini sec get (sections doc) sec key fallback

-- @implements FR-INI-001
-- @implements API-INI-001
fn :: ini get int IniDoc String String Int => Int
      ini get int doc sec key fallback =
        v = ini get doc sec key ""
        ini parse int or v fallback

fn :: ini parse int or String Int => Int
      ini parse int or "" fallback = fallback
      ini parse int or v _ = str_to_int v

-- @implements FR-INI-001
-- @implements API-INI-001
fn :: ini get bool IniDoc String String Bool => Bool
      ini get bool doc sec key fallback =
        v = ini get doc sec key ""
        ini parse bool or v fallback

fn :: ini parse bool or String Bool => Bool
      ini parse bool or "" fallback = fallback
      ini parse bool or "true" _ = True
      ini parse bool or "True" _ = True
      ini parse bool or "1" _ = True
      ini parse bool or "yes" _ = True
      ini parse bool or "false" _ = False
      ini parse bool or "False" _ = False
      ini parse bool or "0" _ = False
      ini parse bool or "no" _ = False
      ini parse bool or _ fallback = fallback

-- @implements FR-INI-001
-- @implements API-INI-001
fn :: ini set IniDoc String String String => IniDoc
      ini set doc sec key val = IniDoc (ini sec put (sections doc) sec key val)

fn :: ini collect sec names [IniSection] => [String]
      ini collect sec names [] = []
      ini collect sec names (s:rest) = [section_name s] :: (ini collect sec names rest)

-- @implements FR-INI-001
-- @implements API-INI-001
fn :: ini sections IniDoc => [String]
      ini sections doc = ini collect sec names (sections doc)

-- @implements FR-INI-001
-- @implements API-INI-001
fn :: dotenv get [IniEntry] String String => String
      dotenv get env key fallback = ini kv get env key fallback

fn :: ini format entries [IniEntry] => String
      ini format entries [] = ""
      ini format entries ((IniEntry k v):rs) = k + " = " + v + (char_from_code 10) + (ini format entries rs)

fn :: ini format section IniSection => String
      ini format section sec =
        | (section_name sec) == "" = ini format entries (entries sec)
        | otherwise = "[" + (section_name sec) + "]" + (char_from_code 10) + (ini format entries (entries sec))

fn :: ini format sections [IniSection] => String
      ini format sections [] = ""
      ini format sections (s:[]) = ini format section s
      ini format sections (s:rest) = (ini format section s) + (char_from_code 10) + (ini format sections rest)

-- @implements FR-INI-001
-- @implements API-INI-001
fn :: ini stringify IniDoc => String
      ini stringify doc = ini format sections (sections doc)
