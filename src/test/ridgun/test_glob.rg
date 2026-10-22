-- ============================================================
-- src/test/ridgun/test_glob.rg
-- Automated test suite for glob.rg (TS-GLOB-001)
-- @tests TS-GLOB-001
-- ============================================================

import test
import glob

-- @tests TS-GLOB-001
fn :: test glob wildcards and classes => ()
      test glob wildcards and classes =
        _     = assert_true (glob match "*.rg" "socket.rg") "*.rg matches socket.rg"
        _     = assert_false (glob match "*.rg" "README.md") "*.rg rejects README.md"
        _     = assert_true (glob match "test_?.rg" "test_a.rg") "test_?.rg single char"
        _     = assert_false (glob match "test_?.rg" "test_ab.rg") "test_?.rg rejects 2 chars"
        _     = assert_true (glob match "a***b" "axyzb") "collapsed *** matches"
        _     = assert_true (glob match ci "*.RG" "socket.rg") "case-insensitive glob_match_ci"
        _     = assert_true (glob match "file_[0-9].txt" "file_7.txt") "[0-9] range match"
        _     = assert_false (glob match "file_[0-9].txt" "file_a.txt") "[0-9] rejects a"
        _     = assert_true (glob match "file_[!0-9].txt" "file_a.txt") "[!0-9] negated class"
        _     = assert_false (glob match "file_[!0-9].txt" "file_7.txt") "[!0-9] rejects digit"
        _     = assert_true (glob match "a[b" "a[b") "unclosed [ matches literally"
        files = ["socket.rg", "README.md", "test_socket.rg", "crypto.rg"]
        _     = assert eq (glob filter "*.rg" files) ["socket.rg", "test_socket.rg", "crypto.rg"]
        _     = assert_true (glob any match ["*.md", "*.txt"] "README.md") "glob_any_match true"
        _     = assert_false (glob any match ["*.md", "*.txt"] "socket.rg") "glob_any_match false"
        ()

fn :: main => ()
      main =
        _ = test glob wildcards and classes
        echo "[PASS] test_glob: TS-GLOB-001 passed"
