-- ============================================================
-- src/test/ridgun/test str.rg
-- Comprehensive test suite for str.rg inspired by Go strings & Rust str stdlib
-- @tests TS-STR-001
-- ============================================================

import test
import posix
import str

-- 1. Substring search (`str index of`), suffix predicates (`str ends with`), and emptiness/blankness
-- @tests TS-STR-001
fn :: test str search and predicates => ()
      test str search and predicates =
        _ = assert equals (str index of "hello world" "world") 6 "AC1: index_of world"
        _ = assert equals (str index of "hello world" "hello") 0 "AC1: index_of hello at 0"
        _ = assert equals (str index of "ababa" "aba") 0 "AC1: index_of returns first occurrence"
        _ = assert equals (str index of "hello" "xyz") (0 - 1) "AC1: index_of missing"
        _ = assert equals (str index of "short" "much_longer_needle") (0 - 1) "AC1: needle longer than haystack -> -1"
        _ = assert equals (str index of "" "a") (0 - 1) "AC1: non-empty needle in empty haystack -> -1"
        _ = assert equals (str index of "" "") 0 "AC1: empty needle in empty haystack -> 0"
        _ = assert equals (str index of "abc" "") 0 "AC1: empty needle -> 0"

        _ = assert true (str ends with "archive.rglib" ".rglib") "AC1: ends_with true"
        _ = assert true (str ends with "exact" "exact") "AC1: ends_with full string"
        _ = assert true (str ends with "any" "") "AC1: ends_with empty suffix true"
        _ = assert false (str ends with "archive.rg" ".rglib") "AC1: ends_with false"
        _ = assert false (str ends with "short" "longer_suffix") "AC1: ends_with suffix longer than string"

        _ = assert true (str is empty "") "AC1: is_empty true"
        _ = assert false (str is empty " ") "AC1: space is not empty"
        _ = assert true (str is blank "") "AC1: empty is blank"
        _ = assert true (str is blank "   \t\n\r ") "AC1: whitespace-only is blank"
        _ = assert false (str is blank "  x ") "AC1: non-whitespace is not blank"
        ()

-- 2. Trimming (`trim`, `trim left`, `trim right`), replacement (`str replace`), splitting, and joining
-- @tests TS-STR-001
fn :: test str trim replace and split => ()
      test str trim replace and split =
        _ = assert equals (str trim "  \thi\n\r ") "hi" "AC2: str_trim mixed ASCII whitespace"
        _ = assert equals (str trim "   \t\r\n") "" "AC2: str_trim all whitespace -> empty"
        _ = assert equals (str trim "") "" "AC2: str_trim empty -> empty"
        _ = assert equals (str trim "no_ws") "no_ws" "AC2: str_trim no whitespace"
        _ = assert equals (str trim left "  abc  ") "abc  " "AC2: str_trim_left"
        _ = assert equals (str trim right "  abc  ") "  abc" "AC2: str_trim_right"

        _ = assert equals (str replace "a-b-c" "-" "_") "a_b_c" "AC2: str_replace single char"
        _ = assert equals (str replace "aaaa" "aa" "b") "bb" "AC2: str_replace non-overlapping left-to-right"
        _ = assert equals (str replace "Hello,World" "World" "") "Hello," "AC2: str_replace deletion to empty"
        _ = assert equals (str replace "abc" "" "x") "abc" "AC2: str_replace empty old leaves string unchanged"
        _ = assert equals (str replace "abc" "z" "y") "abc" "AC2: str_replace absent needle"

        _ = assert equals (str split "a,b,c" ",") ["a", "b", "c"] "AC2: str_split comma"
        _ = assert equals (str split "a,,b," ",") ["a", "", "b", ""] "AC2: str_split consecutive and trailing delim"
        _ = assert equals (str split ",a" ",") ["", "a"] "AC2: str_split leading delim"
        _ = assert equals (str split "a::b::c" "::") ["a", "b", "c"] "AC2: str_split multi-char delimiter"
        _ = assert equals (str split "ab" "") ["a", "b"] "AC2: str_split empty delim splits chars"
        _ = assert equals (str split "" "") [] "AC2: str_split empty string with empty delim -> []"

        _ = assert equals (str join [] "::") "" "AC2: str_join empty list"
        _ = assert equals (str join ["only"] "::") "only" "AC2: str_join singleton"
        _ = assert equals (str join ["alpha", "beta", "gamma"] "::") "alpha::beta::gamma" "AC2: str_join 3 items"
        ()

-- 3. Case conversion, O(log N) binary-exponentiation `str repeat` (up to 8 MiB), and left/right padding
-- @tests TS-STR-001
fn :: test str case repeat and padding => ()
      test str case repeat and padding =
        _ = assert equals (str to upper "Abc! 123 xyz") "ABC! 123 XYZ" "AC3: str_to_upper"
        _ = assert equals (str to lower "Abc! 123 XYZ") "abc! 123 xyz" "AC3: str_to_lower"
        _ = assert equals (str to upper "") "" "AC3: str_to_upper empty"

        _ = assert equals (str repeat "ab" 3) "ababab" "AC3: str_repeat 3"
        _ = assert equals (str repeat "ab" 1) "ab" "AC3: str_repeat 1"
        _ = assert equals (str repeat "ab" 0) "" "AC3: str_repeat 0"
        _ = assert equals (str repeat "ab" (0 - 5)) "" "AC3: str_repeat negative -> empty"
        _ = assert equals (str repeat "" 100) "" "AC3: str_repeat empty string -> empty"

        t0 = sys monotonic ms
        r64k = str repeat "x" 65536
        r256k = str repeat "x" 262144
        t1 = sys monotonic ms
        r8m = str repeat "x" 8000000
        _ = assert equals (str len r64k) 65536 "AC3: str_repeat 65536 length"
        _ = assert equals (str len r256k) 262144 "AC3: str_repeat 262144 length"
        _ = assert equals (str len r8m) 8000000 "AC3: RG-052 str_repeat 8000000 exact length without 1 MiB cap"
        _ = assert true ((t1 - t0) < 200) "AC3: LIB-9 str_repeat 64k+256k in < 200 ms"

        _ = assert equals (str pad left "7" 3 "0") "007" "AC3: str_pad_left"
        _ = assert equals (str pad right "7" 3 "0") "700" "AC3: str_pad_right"
        _ = assert equals (str pad left "7" 4 "") "   7" "AC3: str_pad_left empty pad_ch defaults to space"
        _ = assert equals (str pad left "7" 4 "xyz") "xxx7" "AC3: str_pad_left uses first char of pad_ch"
        _ = assert equals (str pad left "1234" 3 "0") "1234" "AC3: str_pad_left already wider than width"
        _ = assert equals (str pad right "1234" 3 "0") "1234" "AC3: str_pad_right already wider than width"
        ()

-- @tests TS-STR-001
fn :: main => ()
      main =
        _ = test str search and predicates
        _ = test str trim replace and split
        _ = test str case repeat and padding
        echo "[PASS] test str: TS-STR-001 passed"
