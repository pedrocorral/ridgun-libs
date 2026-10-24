-- ============================================================
-- src/test/ridgun/test glob.rg
-- Comprehensive test suite for glob.rg inspired by POSIX fnmatch & Go path/filepath.Match
-- @tests TS-GLOB-001
-- ============================================================

import test
import glob

-- 1. Wildcard (*, ?) boundary cases, collapsed stars, and empty patterns/inputs
-- @tests TS-GLOB-001
fn :: test glob wildcards and boundaries => ()
      test glob wildcards and boundaries =
        _ = assert true (glob match "" "") "AC1: empty pattern matches empty string"
        _ = assert false (glob match "" "a") "AC1: empty pattern rejects non-empty"
        _ = assert true (glob match "*" "") "AC1: * matches empty string"
        _ = assert true (glob match "***" "") "AC1: *** matches empty string"
        _ = assert true (glob match "*" "anything.rg") "AC1: * matches full filename"
        _ = assert true (glob match "*.rg" "socket.rg") "AC1: *.rg matches socket.rg"
        _ = assert true (glob match "*.rg" ".rg") "AC1: *.rg matches leading dot .rg"
        _ = assert false (glob match "*.rg" "README.md") "AC1: *.rg rejects README.md"
        _ = assert false (glob match "*.rg" "socket.rg.bak") "AC1: *.rg rejects trailing suffix"
        _ = assert true (glob match "test_?.rg" "test_a.rg") "AC1: ? matches single char"
        _ = assert false (glob match "test_?.rg" "test_.rg") "AC1: ? rejects zero chars"
        _ = assert false (glob match "test_?.rg" "test_ab.rg") "AC1: ? rejects two chars"
        _ = assert true (glob match "???" "abc") "AC1: ??? matches 3 chars"
        _ = assert false (glob match "???" "ab") "AC1: ??? rejects 2 chars"
        _ = assert true (glob match "a*b*c" "abc") "AC1: multiple * matching zero chars"
        _ = assert true (glob match "a*b*c" "axxxbyyyc") "AC1: multiple * matching substrings"
        _ = assert true (glob match "a*b*c" "abbc") "AC1: backtracking * across repeated b"
        _ = assert false (glob match "a*b*c" "axxxbyyy") "AC1: missing trailing literal after *"
        _ = assert true (glob match "a***b" "axyzb") "AC1: collapsed *** matches"
        -- Pathological backtracking immunity via gl_skip_stars
        _ = assert false (glob match "****************a" "bbbbbbbbbbbbbbbbbbbbbbbbbbbb") "AC1: collapsed stars avoid exponential backtracking"
        ()

-- 2. Bracket character classes ([a-z], [!0-9], [^a-z], multi-range, unclosed '[') and case-insensitive matching
-- @tests TS-GLOB-001
fn :: test glob classes and case insensitivity => ()
      test glob classes and case insensitivity =
        _ = assert true (glob match "file_[0-9].txt" "file_0.txt") "AC2: [0-9] lower bound 0"
        _ = assert true (glob match "file_[0-9].txt" "file_9.txt") "AC2: [0-9] upper bound 9"
        _ = assert false (glob match "file_[0-9].txt" "file_a.txt") "AC2: [0-9] rejects alpha"
        _ = assert true (glob match "id_[a-zA-Z0-9].rg" "id_Z.rg") "AC2: multi-range [a-zA-Z0-9] matches Z"
        _ = assert true (glob match "id_[a-zA-Z0-9].rg" "id_5.rg") "AC2: multi-range [a-zA-Z0-9] matches 5"
        _ = assert false (glob match "id_[a-zA-Z0-9].rg" "id__.rg") "AC2: multi-range [a-zA-Z0-9] rejects _"
        _ = assert true (glob match "v[135].rg" "v3.rg") "AC2: discrete character set [135]"
        _ = assert false (glob match "v[135].rg" "v2.rg") "AC2: discrete character set rejects 2"
        _ = assert true (glob match "file_[!0-9].txt" "file_a.txt") "AC2: [!0-9] POSIX negated class"
        _ = assert false (glob match "file_[!0-9].txt" "file_7.txt") "AC2: [!0-9] rejects digit"
        _ = assert true (glob match "file_[^0-9].txt" "file_z.txt") "AC2: [^0-9] caret negated class"
        _ = assert false (glob match "file_[^0-9].txt" "file_0.txt") "AC2: [^0-9] rejects digit"
        _ = assert true (glob match "a[b" "a[b") "AC2: unclosed '[' matches literally"
        _ = assert false (glob match "a[b" "axb") "AC2: unclosed '[' rejects non-bracket"

        -- Case-insensitive matching
        _ = assert true (glob match ci "*.RG" "socket.rg") "AC2: glob_match_ci *.RG on lowercase"
        _ = assert true (glob match ci "*.rg" "SOCKET.RG") "AC2: glob_match_ci *.rg on uppercase"
        _ = assert true (glob match ci "src/**/Test_[A-Z]*.rg" "SRC/main/test_crypto.RG") "AC2: glob_match_ci mixed case"
        ()

-- 3. List filtering (`glob filter`) and multi-pattern disjunction (`glob any match`)
-- @tests TS-GLOB-001
fn :: test glob filter and any match => ()
      test glob filter and any match =
        files = ["socket.rg", "README.md", "test_socket.rg", "crypto.rg", "build.sh"]
        _ = assert eq (glob filter "*.rg" files) ["socket.rg", "test_socket.rg", "crypto.rg"]
        _ = assert eq (glob filter "test_*.rg" files) ["test_socket.rg"]
        _ = assert eq (glob filter "*.nomatch" files) []
        _ = assert eq (glob filter "*.rg" []) []
        _ = assert true (glob any match ["*.md", "*.txt", "*.sh"] "README.md") "AC3: glob_any_match first pattern"
        _ = assert true (glob any match ["*.md", "*.txt", "*.sh"] "build.sh") "AC3: glob_any_match last pattern"
        _ = assert false (glob any match ["*.md", "*.txt"] "socket.rg") "AC3: glob_any_match no match"
        _ = assert false (glob any match [] "socket.rg") "AC3: glob_any_match empty pattern list"
        ()

-- @tests TS-GLOB-001
fn :: main => ()
      main =
        _ = test glob wildcards and boundaries
        _ = test glob classes and case insensitivity
        _ = test glob filter and any match
        echo "[PASS] test glob: TS-GLOB-001 passed"
