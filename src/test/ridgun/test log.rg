-- ============================================================
-- src/test/ridgun/test log.rg
-- Automated test suite for log.rg (TS-LOG-001)
-- @tests TS-LOG-001
-- ============================================================

import test
import log

-- @tests TS-LOG-001
fn :: test log levels and redaction => ()
      test log levels and redaction =
        _      = assert int equals (log level rank "debug") 10 "rank debug == 10"
        _      = assert int equals (log level rank "INFO") 20 "rank INFO == 20"
        _      = assert int equals (log level rank "WARN") 30 "rank WARN == 30"
        _      = assert int equals (log level rank "ERROR") 40 "rank ERROR == 40"
        _      = assert true (log should emit "WARN" "ERROR") "ERROR >= WARN"
        _      = assert true (log should emit "WARN" "WARN") "WARN >= WARN"
        _      = assert false (log should emit "WARN" "INFO") "INFO < WARN"
        _      = assert true (log is sensitive key "user_password") "user_password sensitive"
        _      = assert true (log is sensitive key "Authorization") "Authorization sensitive"
        _      = assert true (log is sensitive key "X-Api-Key") "X-Api-Key sensitive"
        _      = assert false (log is sensitive key "username") "username not sensitive"
        fields = [("user", "alice"), ("password", "s3cr3t"), ("auth_token", "jwt-123")]
        txt    = log format text "info" "user login" fields
        _      = assert str eq txt "[INFO] user login user=alice password=[REDACTED] auth_token=[REDACTED]" "log format text redacted"
        jsn    = log format json "warn" "auth check\n" fields
        _      = assert str eq jsn "{\"level\":\"WARN\",\"msg\":\"auth check\\n\",\"user\":\"alice\",\"password\":\"[REDACTED]\",\"auth_token\":\"[REDACTED]\"}" "log format json redacted and escaped"
        ()

fn :: main => ()
      main =
        _ = test log levels and redaction
        echo "[PASS] test log: TS-LOG-001 passed"
