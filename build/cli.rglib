-- ============================================================
-- src/main/ridgun/lib/cli.rg
-- Pure-Ridgun Command-Line Flag, Option, Positional & Environment Library (CLI)
-- @implements FR-CLI-001
-- @implements API-CLI-001
-- @mitigates VUL-INPUT-001
-- ============================================================

module :: cli

-- ── Internal String & List Helpers ───────────────────────────

fn :: cl str contains char String Int Int Int => Bool
      cl str contains char s ch idx len =
        | idx >= len                = False
        | (str char at s idx) == ch = True
        | otherwise                 = cl str contains char s ch (idx + 1) len

fn :: cl is bundled short String String => Bool
      cl is bundled short arg short_flag =
        | (str len short_flag) != 2        = False
        | (str char at short_flag 0) != 45 = False
        | (str len arg) < 2                = False
        | (str char at arg 0) != 45        = False
        | (str char at arg 1) == 45        = False
        | otherwise                        = cl str contains char arg (str char at short_flag 1) 1 (str len arg)

fn :: cl list contains str [String] String => Bool
      cl list contains str [] _ = False
      cl list contains str (x:rest) tgt =
        | x == tgt  = True
        | otherwise = cl list contains str rest tgt

fn :: cl is digits loop String Int Int => Bool
      cl is digits loop s idx len =
        | idx >= len                                           = True
        | (str char at s idx) < 48 or (str char at s idx) > 57 = False
        | otherwise                                            = cl is digits loop s (idx + 1) len

fn :: cl is signed int len String Int => Bool
      cl is signed int len s n =
        | n == 0                  = False
        | (str char at s 0) == 45 =
          | n <= 1    = False
          | otherwise = cl is digits loop s 1 n |.
        | otherwise               = cl is digits loop s 0 n

fn :: cl is signed int String => Bool
      cl is signed int s      =  cl is signed int len s (str len s)

fn :: cl is ws Int => Bool
      cl is ws c   =  c == 32 or c == 9 or c == 10 or c == 13

fn :: cl lower char String Int Int => String
      cl lower char s idx c =
        | c >= 65 and c <= 90 = char from code (c + 32)
        | otherwise           = str slice s idx (idx + 1)

fn :: cl trim lower loop String Int Int => String
      cl trim lower loop s idx len =
        | idx >= len                   = ""
        | cl is ws (str char at s idx) = cl trim lower loop s (idx + 1) len
        | otherwise                    = (cl lower char s idx (str char at s idx)) + (cl trim lower loop s (idx + 1) len)

-- ── Flag Detection (`--flag`, `-f`, bundled `-la`, stops at `--`) ─

-- @implements FR-CLI-001
-- @implements API-CLI-001
-- @mitigates VUL-INPUT-001
fn :: cli has flag [String] String String => Bool
      cli has flag [] _ _ = False
      cli has flag (a:rest) long_flag short_flag =
        | a == "--"                                                          = False
        | ((str len long_flag) > 0) and (a == long_flag)                     = True
        | ((str len short_flag) > 0) and (a == short_flag)                   = True
        | ((str len short_flag) == 2) and (cl is bundled short a short_flag) = True
        | otherwise                                                          = cli has flag rest long_flag short_flag

-- ── Option Value Extraction (`--key=val`, `--key val`, `-k val`) ─

fn :: cl match eq pfx String String => String
      cl match eq pfx arg pfx =
        | str starts with arg pfx = str slice arg (str len pfx) (str len arg)
        | otherwise               = ""

fn :: cl match eq prefix String String => String
      cl match eq prefix arg flag =
        | (str len flag) == 0 = ""
        | otherwise           = cl match eq pfx arg (flag + "=")

fn :: cl has eq prefix String String => Bool
      cl has eq prefix arg flag =
        | (str len flag) == 0 = False
        | otherwise           = str starts with arg (flag + "=")

-- @implements FR-CLI-001
-- @implements API-CLI-001
-- @mitigates VUL-INPUT-001
fn :: cli get opt [String] String String String => String
      cli get opt [] _ _ fallback = fallback
      cli get opt (a:[]) long_flag short_flag fallback =
        | a == "--"                     = fallback
        | cl has eq prefix a long_flag  = cl match eq prefix a long_flag
        | cl has eq prefix a short_flag = cl match eq prefix a short_flag
        | otherwise                     = fallback
      cli get opt (a:b:rst) long_flag short_flag fallback =
        | a == "--"                                        = fallback
        | cl has eq prefix a long_flag                     = cl match eq prefix a long_flag
        | cl has eq prefix a short_flag                    = cl match eq prefix a short_flag
        | ((str len long_flag) > 0) and (a == long_flag)   = b
        | ((str len short_flag) > 0) and (a == short_flag) = b
        | otherwise                                        = cli get opt ([b] :: rst) long_flag short_flag fallback

fn :: cl parse int opt String Int => Int
      cl parse int opt raw fallback =
        | not (cl is signed int raw) = fallback
        | otherwise                  = str to int raw

-- @implements FR-CLI-001
-- @implements API-CLI-001
-- @mitigates VUL-INPUT-001
fn :: cli get int opt [String] String String Int => Int
      cli get int opt args long_flag short_flag fallback =
        cl parse int opt (cli get opt args long_flag short_flag "") fallback

-- ── Positional Arguments & Subcommand Extraction ─────────────

fn :: cl is flag tok String => Bool
      cl is flag tok a      =
        | (str len a) <= 1        = False
        | (str char at a 0) == 45 = True
        | otherwise               = False

-- @implements FR-CLI-001
-- @implements API-CLI-001
-- @mitigates VUL-INPUT-001
fn :: cli positionals with opts [String] [String] => [String]
      cli positionals with opts [] _ = []
      cli positionals with opts (a:[]) _ =
        | a == "--"        = []
        | cl is flag tok a = []
        | otherwise        = [a]
      cli positionals with opts (a:b:rst) val_opts =
        | a == "--"                       = [b] :: rst
        | cl list contains str val_opts a = cli positionals with opts rst val_opts
        | cl is flag tok a                = cli positionals with opts ([b] :: rst) val_opts
        | otherwise                       = [a] :: (cli positionals with opts ([b] :: rst) val_opts)

-- @implements FR-CLI-001
-- @implements API-CLI-001
fn :: cli positionals [String] => [String]
      cli positionals args     =  cli positionals with opts args []

fn :: cl first str [String] => String
      cl first str []       =  ""
      cl first str (x:_)    =  x

-- @implements FR-CLI-001
-- @implements API-CLI-001
fn :: cli subcommand [String] => String
      cli subcommand args     =  args cli positionals -> cl first str

-- ── Typed Environment Variable Readers ───────────────────────

fn :: cl env val or String String => String
      cl env val or val fallback =
        | (str len val) == 0 = fallback
        | otherwise          = val

-- @implements FR-CLI-001
-- @implements API-CLI-001
fn :: env get or String String   => String
      env get or key    fallback =  cl env val or (sys getenv key) fallback

-- @implements FR-CLI-001
-- @implements API-CLI-001
-- @mitigates VUL-INPUT-001
fn :: env get int or String Int => Int
      env get int or key fallback = cl parse int opt (sys getenv key) fallback

fn :: cl parse bool val String Bool => Bool
      cl parse bool val val fallback =
        | val == "1" or val == "true" or val == "yes" or val == "on"  = True
        | val == "0" or val == "false" or val == "no" or val == "off" = False
        | otherwise                                                   = fallback

-- @implements FR-CLI-001
-- @implements API-CLI-001
fn :: env get bool or String Bool => Bool
      env get bool or key fallback =
        key sys getenv -> raw
        cl trim lower loop raw 0 (str len raw) -> norm
        cl parse bool val norm fallback
