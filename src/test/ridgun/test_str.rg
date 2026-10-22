-- ============================================================
-- src/test/ridgun/test_str.rg
-- Automated test suite for the string manipulation library (STR)
-- @tests TS-STR-001
-- ============================================================

import test
import posix
import str

-- @tests TS-STR-001
fn :: test_str_search_and_predicates => ()
      test_str_search_and_predicates =
        _ = assert_equals (str_index_of "hello world" "world") 6 "index_of world"
        _ = assert_equals (str_index_of "hello world" "hello") 0 "index_of hello"
        _ = assert_equals (str_index_of "hello" "xyz") (0 - 1) "index_of missing"
        _ = assert_equals (str_index_of "abc" "") 0 "index_of empty needle"
        _ = assert_equals (str index of "Hello,World" "World") 6 "space call str index of"
        _ = assert_true (str ends with "archive.rglib" ".rglib") "ends_with true"
        _ = assert_false (str ends with "archive.rg" ".rglib") "ends_with false"
        _ = assert_true (str is empty "") "is_empty true"
        _ = assert_false (str is empty "a") "is_empty false"
        _ = assert_true (str is blank "   \t\n\r ") "is_blank true"
        assert_false (str is blank "  x ") "is_blank false"

-- @tests TS-STR-001
fn :: test_str_trim_replace_and_split => ()
      test_str_trim_replace_and_split =
        _     = assert_equals (str_trim "  \thi\n\r ") "hi" "str_trim whitespace"
        _     = assert_equals (str_trim "   ") "" "str_trim all spaces"
        _     = assert_equals (str trim left "  abc  ") "abc  " "str trim left"
        _     = assert_equals (str trim right "  abc  ") "  abc" "str trim right"
        _     = assert_equals (str_replace "a-b-c" "-" "_") "a_b_c" "str_replace dash"
        _     = assert_equals (str_replace "Hello,World" "World" "There") "Hello,There" "str_replace word"
        _     = assert_equals (str_replace "abc" "" "x") "abc" "str_replace empty old"
        parts = str_split "a,b,c" ","
        _     = assert_equals parts ["a", "b", "c"] "str_split comma"
        emp   = str_split "a,,b" ","
        _     = assert_equals emp ["a", "", "b"] "str_split empty middle"
        chars = str_split "ab" ""
        _     = assert_equals chars ["a", "b"] "str_split empty delim"
        assert_equals (str join ["alpha", "beta", "gamma"] "::") "alpha::beta::gamma" "str join"

-- @tests TS-STR-001
fn :: test_str_case_repeat_and_padding => ()
      test_str_case_repeat_and_padding =
        _     = assert_equals (str_to_upper "Abc! 123") "ABC! 123" "str_to_upper"
        _     = assert_equals (str_to_lower "Abc! 123") "abc! 123" "str_to_lower"
        _     = assert_equals (str repeat "ab" 3) "ababab" "str repeat 3"
        _     = assert_equals (str repeat "ab" 0) "" "str repeat 0"
        t0    = sys monotonic ms
        r64k  = str repeat "x" 65536
        r256k = str repeat "x" 262144
        t1    = sys monotonic ms
        _     = assert_equals (str_len r64k) 65536 "str_repeat 65536 length"
        _     = assert_equals (str_len r256k) 262144 "str_repeat 262144 length"
        _     = assert_true ((t1 - t0) < 200) "LIB-9: str_repeat 64k+256k in < 200 ms"
        _     = assert_equals (str pad left "7" 3 "0") "007" "str pad left"
        _     = assert_equals (str pad right "7" 3 "0") "700" "str pad right"
        assert_equals (str pad left "1234" 3 "0") "1234" "str pad left already wide"

fn :: main => ()
      main =
        _ = test_str_search_and_predicates
        _ = test_str_trim_replace_and_split
        _ = test_str_case_repeat_and_padding
        echo "[PASS] test_str: TS-STR-001 passed"
