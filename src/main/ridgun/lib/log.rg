-- ============================================================
-- src/main/ridgun/lib/log.rg
-- Pure-Ridgun Level-Filtered Text & NDJSON Structured Logging Library with Secret Redaction (LOG)
-- @implements FR-LOG-001
-- @implements API-LOG-001
-- @implements NFR-OBS-001
-- @mitigates VUL-INPUT-001
-- ============================================================

module :: log

fn :: lg lower char String Int Int => String
      lg lower char s idx c =
        | c >= 65 and c <= 90 = char from code (c + 32)
        | otherwise           = str slice s idx (idx + 1)

fn :: lg to lower loop String Int Int => String
      lg to lower loop s idx len =
        | idx >= len = ""
        | otherwise  = (lg lower char s idx (str char at s idx)) + (lg to lower loop s (idx + 1) len)

fn :: lg to lower String => String
      lg to lower s      =  lg to lower loop s 0 (str len s)

-- ── Severity Levels (`DEBUG`, `INFO`, `WARN`, `ERROR`) ───────

fn :: lg rank from lower String => Int
      lg rank from lower lv     =
        | lv == "debug"                       = 10
        | lv == "info"                        = 20
        | lv == "warn" or lv == "warning"     = 30
        | lv == "error" or lv == "err"        = 40
        | otherwise                           = 20

-- @implements FR-LOG-001
-- @implements API-LOG-001
fn :: log level rank String => Int
      log level rank level  =  lg rank from lower (lg to lower level)

-- @implements FR-LOG-001
-- @implements API-LOG-001
fn :: log level name Int  => String
      log level name rank =
        | rank <= 10 = "DEBUG"
        | rank <= 20 = "INFO"
        | rank <= 30 = "WARN"
        | otherwise  = "ERROR"

-- @implements FR-LOG-001
-- @implements API-LOG-001
fn :: log should emit String    String    => Bool
      log should emit min_level msg_level =  (log level rank msg_level) >= (log level rank min_level)

-- ── Sensitive Key Detection & Redaction ──────────────────────

fn :: lg check sens lower String => Bool
      lg check sens lower lk     =
        | str contains lk "password" or str contains lk "passwd"       = True
        | str contains lk "secret" or str contains lk "token"          = True
        | str contains lk "api_key" or str contains lk "api-key"       = True
        | str contains lk "apikey"                                     = True
        | str contains lk "authorization" or str contains lk "cookie"  = True
        | str contains lk "private_key" or str contains lk "private-key" = True
        | otherwise                                                    = False

-- @implements FR-LOG-001
-- @implements API-LOG-001
-- @mitigates VUL-INPUT-001
fn :: log is sensitive key String => Bool
      log is sensitive key key    =  lg check sens lower (lg to lower key)

fn :: lg pair key (String String) => String
      lg pair key (k, _)          =  k

fn :: lg pair val (String String) => String
      lg pair val (_, v)          =  v

fn :: lg redact pair (String String) => String String
      lg redact pair (k, v)          =
        | log is sensitive key k = (k, "[REDACTED]")
        | otherwise              = (k, v)

-- @implements FR-LOG-001
-- @implements API-LOG-001
-- @mitigates VUL-INPUT-001
fn :: log redact fields [String String] => [String String]
      log redact fields []              =  []
      log redact fields (pair:rest)     =  [(lg redact pair pair)] :: (log redact fields rest)

-- ── Escaping & Text / NDJSON Formatting ──────────────────────

fn :: lg esc char String Int Int => String
      lg esc char s idx c =
        | c == 34   = "\\\""
        | c == 92   = "\\\\"
        | c == 10   = "\\n"
        | c == 13   = "\\r"
        | c == 9    = "\\t"
        | otherwise = str slice s idx (idx + 1)

fn :: lg esc loop String Int Int => String
      lg esc loop s idx len =
        | idx >= len = ""
        | otherwise  = (lg esc char s idx (str char at s idx)) + (lg esc loop s (idx + 1) len)

fn :: lg esc str String => String
      lg esc str s      =  lg esc loop s 0 (str len s)

fn :: lg quote String => String
      lg quote s      =  "\"" + (lg esc str s) + "\""

fn :: lg fmt text fields [String String] => String
      lg fmt text fields []              =  ""
      lg fmt text fields (pair:rest)     =
        " " + (lg esc str (lg pair key pair)) + "=" + (lg esc str (lg pair val pair)) + (lg fmt text fields rest)

-- @implements FR-LOG-001
-- @implements API-LOG-001
-- @implements NFR-OBS-001
-- @mitigates VUL-INPUT-001
fn :: log format text String String [String String] => String
      log format text level msg fields =
        norm_lv = log level name (log level rank level)
        safe_f  = log redact fields fields
        "[" + norm_lv + "] " + (lg esc str msg) + (lg fmt text fields safe_f)

fn :: lg fmt json fields [String String] => String
      lg fmt json fields []              =  ""
      lg fmt json fields (pair:rest)     =
        "," + (lg quote (lg pair key pair)) + ":" + (lg quote (lg pair val pair)) + (lg fmt json fields rest)

-- @implements FR-LOG-001
-- @implements API-LOG-001
-- @implements NFR-OBS-001
-- @mitigates VUL-INPUT-001
fn :: log format json String String [String String] => String
      log format json level msg fields =
        norm_lv = log level name (log level rank level)
        safe_f  = log redact fields fields
        "{\"level\":" + (lg quote norm_lv) + ",\"msg\":" + (lg quote msg) + (lg fmt json fields safe_f) + "}"
