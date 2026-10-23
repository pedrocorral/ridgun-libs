-- ============================================================
-- src/test/ridgun/test_str.rg
-- Automated test suite for the string manipulation library (STR)
-- @tests TS-STR-001
-- ============================================================

import test
import posix
import str

-- @tests TS-STR-001
fn :: test str search and predicates => ()
      test str search and predicates =
        _ = assert equals (str index of "hello world" "world") 6 "index_of world"
        _ = assert equals (str index of "hello world" "hello") 0 "index_of hello"
        _ = assert equals (str index of "hello" "xyz") (0 - 1) "index_of missing"
        _ = assert equals (str index of "abc" "") 0 "index_of empty needle"
        _ = assert equals (str index of "Hello,World" "World") 6 "space call str index of"
        _ = assert true (str ends with "archive.rglib" ".rglib") "ends_with true"
        _ = assert false (str ends with "archive.rg" ".rglib") "ends_with false"
        _ = assert true (str is empty "") "is_empty true"
        _ = assert false (str is empty "a") "is_empty false"
        _ = assert true (str is blank "   \t\n\r ") "is_blank true"
        assert false (str is blank "  x ") "is_blank false"

-- @tests TS-STR-001
fn :: test str trim replace and split => ()
      test str trim replace and split =
        _     = assert equals (str trim "  \thi\n\r ") "hi" "str_trim whitespace"
        _     = assert equals (str trim "   ") "" "str_trim all spaces"
        _     = assert equals (str trim left "  abc  ") "abc  " "str trim left"
        _     = assert equals (str trim right "  abc  ") "  abc" "str trim right"
        _     = assert equals (str replace "a-b-c" "-" "_") "a_b_c" "str_replace dash"
        _     = assert equals (str replace "Hello,World" "World" "There") "Hello,There" "str_replace word"
        _     = assert equals (str replace "abc" "" "x") "abc" "str_replace empty old"
        parts = str split "a,b,c" ","
        _     = assert equals parts ["a", "b", "c"] "str_split comma"
        emp   = str split "a,,b" ","
        _     = assert equals emp ["a", "", "b"] "str_split empty middle"
        chars = str split "ab" ""
        _     = assert equals chars ["a", "b"] "str_split empty delim"
        assert equals (str join ["alpha", "beta", "gamma"] "::") "alpha::beta::gamma" "str join"

-- @tests TS-STR-001
fn :: test str case repeat and padding => ()
      test str case repeat and padding =
        _     = assert equals (str to upper "Abc! 123") "ABC! 123" "str_to_upper"
        _     = assert equals (str to lower "Abc! 123") "abc! 123" "str_to_lower"
        _     = assert equals (str repeat "ab" 3) "ababab" "str repeat 3"
        _     = assert equals (str repeat "ab" 0) "" "str repeat 0"
        t0    = sys monotonic ms
        r64k  = str repeat "x" 65536
        r256k = str repeat "x" 262144
        t1    = sys monotonic ms
        r8m   = str repeat "x" 8000000
        _     = assert equals (str len r64k) 65536 "str_repeat 65536 length"
        _     = assert equals (str len r256k) 262144 "str_repeat 262144 length"
        _     = assert equals (str len r8m) 8000000 "RG-052: str_repeat 8000000 exact length without 1 MiB cap"
        _     = assert true ((t1 - t0) < 200) "LIB-9: str_repeat 64k+256k in < 200 ms"
        _     = assert equals (str pad left "7" 3 "0") "007" "str pad left"
        _     = assert equals (str pad right "7" 3 "0") "700" "str pad right"
        assert equals (str pad left "1234" 3 "0") "1234" "str pad left already wide"

fn :: main => ()
      main =
        _ = test str search and predicates
        _ = test str trim replace and split
        _ = test str case repeat and padding
        echo "[PASS] test_str: TS-STR-001 passed"
