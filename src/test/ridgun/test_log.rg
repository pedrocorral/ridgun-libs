-- ============================================================
-- src/test/ridgun/test_log.rg
-- Automated test suite for log.rg (TS-LOG-001)
-- @tests TS-LOG-001
-- ============================================================

import test
import log

-- @tests TS-LOG-001
fn :: test log levels and redaction => ()
      test log levels and redaction =
        _      = assert_int_equals (log level rank "debug") 10 "rank debug == 10"
        _      = assert_int_equals (log level rank "INFO") 20 "rank INFO == 20"
        _      = assert_int_equals (log level rank "WARN") 30 "rank WARN == 30"
        _      = assert_int_equals (log level rank "ERROR") 40 "rank ERROR == 40"
        _      = assert_true (log should emit "WARN" "ERROR") "ERROR >= WARN"
        _      = assert_true (log should emit "WARN" "WARN") "WARN >= WARN"
        _      = assert_false (log should emit "WARN" "INFO") "INFO < WARN"
        _      = assert_true (log is sensitive key "user_password") "user_password sensitive"
        _      = assert_true (log is sensitive key "Authorization") "Authorization sensitive"
        _      = assert_true (log is sensitive key "X-Api-Key") "X-Api-Key sensitive"
        _      = assert_false (log is sensitive key "username") "username not sensitive"
        fields = [("user", "alice"), ("password", "s3cr3t"), ("auth_token", "jwt-123")]
        txt    = log format text "info" "user login" fields
        _      = assert_str_eq txt "[INFO] user login user=alice password=[REDACTED] auth_token=[REDACTED]" "log_format_text redacted"
        jsn    = log format json "warn" "auth check\n" fields
        _      = assert_str_eq jsn "{\"level\":\"WARN\",\"msg\":\"auth check\\n\",\"user\":\"alice\",\"password\":\"[REDACTED]\",\"auth_token\":\"[REDACTED]\"}" "log_format_json redacted and escaped"
        ()

fn :: main => ()
      main =
        _ = test log levels and redaction
        echo "[PASS] test_log: TS-LOG-001 passed"
