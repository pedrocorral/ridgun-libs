-- ============================================================
-- src/test/ridgun/test path.rg
-- Automated test suite for path.rg (TS-PATH-001)
-- @tests TS-PATH-001
-- ============================================================

import test
import path

-- @tests TS-PATH-001
fn :: test path clean and join => ()
      test path clean and join =
        _ = assert str eq (path clean "/a/b/../c/./d//") "/a/c/d" "path clean absolute"
        _ = assert str eq (path clean "a/../../b") "../b" "path clean relative parent"
        _ = assert str eq (path clean "/../a") "/a" "path clean root clamp"
        _ = assert str eq (path clean "") "." "path clean empty"
        _ = assert str eq (path clean "///") "/" "path clean root slashes"
        _ = assert str eq (path join "/var/log" "app/server.log") "/var/log/app/server.log" "path join"
        _ = assert str eq (path join "/var/log" "/etc/hosts") "/etc/hosts" "path join abs override"
        _ = assert str eq (path join list ["src", "main", "ridgun", "lib", "path.rg"]) "src/main/ridgun/lib/path.rg" "path join list"
        ()

-- @tests TS-PATH-001
fn :: test path components and confinement => ()
      test path components and confinement =
        p = "/home/boogie/ridgun-libs/src/socket.rg"
        _ = assert true (path is abs p) "path is abs"
        _ = assert false (path is rel p) "path is rel"
        _ = assert true (path is rel "src/socket.rg") "path is rel relative"
        _ = assert str eq (path dirname p) "/home/boogie/ridgun-libs/src" "path dirname"
        _ = assert str eq (path basename p) "socket.rg" "path basename"
        _ = assert str eq (path stem p) "socket" "path stem"
        _ = assert str eq (path ext p) ".rg" "path ext"
        _ = assert str eq (path replace ext p "rglib") "/home/boogie/ridgun-libs/src/socket.rglib" "path replace ext"
        _ = assert str eq (path stem ".gitignore") ".gitignore" "dotfile stem"
        _ = assert str eq (path ext ".gitignore") "" "dotfile empty ext"
        _ = assert true (path is safe subpath "/srv/www" "assets/app.js") "safe subpath"
        _ = assert true (path is safe subpath "/srv/www" "a/b/../c.txt") "safe normalized subpath"
        _ = assert false (path is safe subpath "/srv/www" "../etc/passwd") "traversal rejected"
        _ = assert false (path is safe subpath "/srv/www" "a/../../etc/passwd") "deep traversal rejected"
        _ = assert false (path is safe subpath "/srv/www" "/etc/passwd") "absolute child rejected"
        _ = assert false (path is safe subpath "/srv/www" "bad;rm.txt") "shell metachar rejected"
        ()

fn :: main => ()
      main =
        _ = test path clean and join
        _ = test path components and confinement
        echo "[PASS] test path: TS-PATH-001 passed"
