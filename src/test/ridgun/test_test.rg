-- ============================================================
-- src/test/ridgun/test_test.rg
-- Automated test suite for the test assertion library (TST)
-- @tests TS-TST-001
-- @tests TS-OBS-001
-- ============================================================

import test

-- @tests TS-TST-001
fn :: test_rg011_assertions => ()
      test_rg011_assertions =
        _ = assert_equals 4 4 "math int equality"
        _ = assert_equals "ok" "ok" "string equality"
        _ = assert_equals True True "bool equality"
        _ = assert_true (1 < 2) "1 < 2 holds"
        _ = assert_false (1 > 2) "1 > 2 is false"
        _ = assert_str_eq "ridgun" "ridgun" "str eq helper"
        _ = assert_int_equals 42 42 "int eq helper"
        _ = assert eq 10 10
        _ = assert ok True
        _ = assert not False
        _ = assert_true (check eq 2 2) "check eq True"
        _ = assert_false (check eq 1 2) "check eq False"
        _ = assert_true (check str eq "a" "a") "check str eq True"
        _ = assert_false (check str eq "a" "b") "check str eq False"
        _ = assert_true (check true True) "check true True"
        assert_false (check true False) "check true False"

fn :: main => ()
      main =
        _ = test_rg011_assertions
        echo "[PASS] test_test: TS-TST-001 passed"
