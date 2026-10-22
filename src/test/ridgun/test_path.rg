-- ============================================================
-- src/test/ridgun/test_path.rg
-- Automated test suite for path.rg (TS-PATH-001)
-- @tests TS-PATH-001
-- ============================================================

import test
import path

-- @tests TS-PATH-001
fn :: test path clean and join => ()
      test path clean and join =
        _ = assert_str_eq (path clean "/a/b/../c/./d//") "/a/c/d" "path_clean absolute"
        _ = assert_str_eq (path clean "a/../../b") "../b" "path_clean relative parent"
        _ = assert_str_eq (path clean "/../a") "/a" "path_clean root clamp"
        _ = assert_str_eq (path clean "") "." "path_clean empty"
        _ = assert_str_eq (path clean "///") "/" "path_clean root slashes"
        _ = assert_str_eq (path join "/var/log" "app/server.log") "/var/log/app/server.log" "path_join"
        _ = assert_str_eq (path join "/var/log" "/etc/hosts") "/etc/hosts" "path_join abs override"
        _ = assert_str_eq (path join list ["src", "main", "ridgun", "lib", "path.rg"]) "src/main/ridgun/lib/path.rg" "path_join_list"
        ()

-- @tests TS-PATH-001
fn :: test path components and confinement => ()
      test path components and confinement =
        p = "/home/boogie/ridgun-libs/src/socket.rg"
        _ = assert_true (path is abs p) "path_is_abs"
        _ = assert_false (path is rel p) "path_is_rel"
        _ = assert_true (path is rel "src/socket.rg") "path_is_rel relative"
        _ = assert_str_eq (path dirname p) "/home/boogie/ridgun-libs/src" "path_dirname"
        _ = assert_str_eq (path basename p) "socket.rg" "path_basename"
        _ = assert_str_eq (path stem p) "socket" "path_stem"
        _ = assert_str_eq (path ext p) ".rg" "path_ext"
        _ = assert_str_eq (path replace ext p "rglib") "/home/boogie/ridgun-libs/src/socket.rglib" "path_replace_ext"
        _ = assert_str_eq (path stem ".gitignore") ".gitignore" "dotfile stem"
        _ = assert_str_eq (path ext ".gitignore") "" "dotfile empty ext"
        _ = assert_true (path is safe subpath "/srv/www" "assets/app.js") "safe subpath"
        _ = assert_true (path is safe subpath "/srv/www" "a/b/../c.txt") "safe normalized subpath"
        _ = assert_false (path is safe subpath "/srv/www" "../etc/passwd") "traversal rejected"
        _ = assert_false (path is safe subpath "/srv/www" "a/../../etc/passwd") "deep traversal rejected"
        _ = assert_false (path is safe subpath "/srv/www" "/etc/passwd") "absolute child rejected"
        _ = assert_false (path is safe subpath "/srv/www" "bad;rm.txt") "shell metachar rejected"
        ()

fn :: main => ()
      main =
        _ = test path clean and join
        _ = test path components and confinement
        echo "[PASS] test_path: TS-PATH-001 passed"
