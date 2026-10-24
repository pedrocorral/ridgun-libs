-- ============================================================
-- src/test/ridgun/test log.rg
-- Comprehensive test suite for log.rg inspired by Rust tracing & Go log/slog
-- @tests TS-LOG-001
-- ============================================================

import test
import log

-- 1. Severity level ranking, aliases, normalization, and threshold filtering matrix
-- @tests TS-LOG-001
fn :: test log levels and filtering => ()
      test log levels and filtering =
        _ = assert int equals (log level rank "debug") 10 "AC1: rank debug == 10"
        _ = assert int equals (log level rank "DEBUG") 10 "AC1: rank DEBUG == 10"
        _ = assert int equals (log level rank "info") 20 "AC1: rank info == 20"
        _ = assert int equals (log level rank "INFO") 20 "AC1: rank INFO == 20"
        _ = assert int equals (log level rank "warn") 30 "AC1: rank warn == 30"
        _ = assert int equals (log level rank "warning") 30 "AC1: rank warning alias == 30"
        _ = assert int equals (log level rank "error") 40 "AC1: rank error == 40"
        _ = assert int equals (log level rank "ERR") 40 "AC1: rank ERR alias == 40"
        _ = assert int equals (log level rank "unknown_level") 20 "AC1: unknown level defaults to INFO (20)"

        _ = assert str eq (log level name 10) "DEBUG" "AC1: level name 10 -> DEBUG"
        _ = assert str eq (log level name 20) "INFO" "AC1: level name 20 -> INFO"
        _ = assert str eq (log level name 30) "WARN" "AC1: level name 30 -> WARN"
        _ = assert str eq (log level name 40) "ERROR" "AC1: level name 40 -> ERROR"

        _ = assert true (log should emit "DEBUG" "DEBUG") "AC1: DEBUG emits DEBUG"
        _ = assert true (log should emit "DEBUG" "ERROR") "AC1: DEBUG emits ERROR"
        _ = assert true (log should emit "WARN" "ERROR") "AC1: WARN emits ERROR"
        _ = assert true (log should emit "WARN" "warning") "AC1: WARN emits warning"
        _ = assert false (log should emit "WARN" "INFO") "AC1: WARN suppresses INFO"
        _ = assert false (log should emit "ERROR" "WARN") "AC1: ERROR suppresses WARN"
        _ = assert false (log should emit "ERROR" "DEBUG") "AC1: ERROR suppresses DEBUG"
        ()

-- 2. Sensitive key detection across credential naming conventions (OWASP logging redaction)
-- @tests TS-LOG-001
fn :: test log sensitive key redaction => ()
      test log sensitive key redaction =
        _ = assert true (log is sensitive key "password") "AC2: password"
        _ = assert true (log is sensitive key "user_passwd") "AC2: user_passwd"
        _ = assert true (log is sensitive key "CLIENT_SECRET") "AC2: CLIENT_SECRET"
        _ = assert true (log is sensitive key "access_token") "AC2: access_token"
        _ = assert true (log is sensitive key "X-Api-Key") "AC2: X-Api-Key"
        _ = assert true (log is sensitive key "api_key_id") "AC2: api_key_id"
        _ = assert true (log is sensitive key "apikey") "AC2: apikey"
        _ = assert true (log is sensitive key "Authorization") "AC2: Authorization"
        _ = assert true (log is sensitive key "session_cookie") "AC2: session_cookie"
        _ = assert true (log is sensitive key "ssh_private_key") "AC2: ssh_private_key"
        _ = assert true (log is sensitive key "private-key-pem") "AC2: private-key-pem"
        _ = assert false (log is sensitive key "username") "AC2: username safe"
        _ = assert false (log is sensitive key "request_id") "AC2: request_id safe"
        _ = assert false (log is sensitive key "status_code") "AC2: status_code safe"
        ()

-- 3. Text & NDJSON formatting, log injection prevention (\n, \r, \t, ", \ escaping), and empty fields
-- @tests TS-LOG-001
fn :: test log text and ndjson formatting => ()
      test log text and ndjson formatting =
        fields = [("user", "alice"), ("password", "s3cr3t"), ("auth_token", "jwt-123"), ("cookie", "sid=99")]
        txt = log format text "info" "user login" fields
        _ = assert str eq txt "[INFO] user login user=alice password=[REDACTED] auth_token=[REDACTED] cookie=[REDACTED]" "AC3: log format text redacts all secret keys"

        txt_empty = log format text "error" "disk full" []
        _ = assert str eq txt_empty "[ERROR] disk full" "AC3: log format text with empty fields"

        -- Log injection defense: newlines, carriage returns, tabs, quotes, and backslashes in msg or values
        inj_fields = [("path", "C:\\app\\bin"), ("note", "line1\nline2\r\t\"quoted\"")]
        jsn = log format json "warn" "auth check\nforged_line" fields
        _ = assert str eq jsn "{\"level\":\"WARN\",\"msg\":\"auth check\\nforged_line\",\"user\":\"alice\",\"password\":\"[REDACTED]\",\"auth_token\":\"[REDACTED]\",\"cookie\":\"[REDACTED]\"}" "AC3: NDJSON escapes newline injection and redacts secrets"

        jsn_esc = log format json "debug" "trace" inj_fields
        _ = assert str eq jsn_esc "{\"level\":\"DEBUG\",\"msg\":\"trace\",\"path\":\"C:\\\\app\\\\bin\",\"note\":\"line1\\nline2\\r\\t\\\"quoted\\\"\"}" "AC3: NDJSON escapes \\, \\n, \\r, \\t, and \\\""
        ()

-- @tests TS-LOG-001
fn :: main => ()
      main =
        _ = test log levels and filtering
        _ = test log sensitive key redaction
        _ = test log text and ndjson formatting
        echo "[PASS] test log: TS-LOG-001 passed"
