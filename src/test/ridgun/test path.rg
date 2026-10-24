-- ============================================================
-- src/test/ridgun/test path.rg
-- Comprehensive test suite for path.rg inspired by Go path.Clean & OWASP Path Traversal vectors
-- @tests TS-PATH-001
-- ============================================================

import test
import path

fn :: pair_fst (String String) => String
      pair_fst (a, _)          =  a

fn :: pair_snd (String String) => String
      pair_snd (_, b)          =  b

-- 1. Go path.Clean canonical test vectors & multi-segment path joining
-- @tests TS-PATH-001
fn :: test path clean and join => ()
      test path clean and join =
        -- Go path/path_test.go cleantests vectors
        _ = assert str eq (path clean "") "." "AC1: empty -> ."
        _ = assert str eq (path clean ".") "." "AC1: . -> ."
        _ = assert str eq (path clean "././.") "." "AC1: ././. -> ."
        _ = assert str eq (path clean "/") "/" "AC1: / -> /"
        _ = assert str eq (path clean "///") "/" "AC1: /// -> /"
        _ = assert str eq (path clean "/././") "/" "AC1: /././ -> /"
        _ = assert str eq (path clean "/../a") "/a" "AC1: /../a clamped at root"
        _ = assert str eq (path clean "/../../..") "/" "AC1: /../../.. clamped at root"
        _ = assert str eq (path clean "a/b/..") "a" "AC1: a/b/.. -> a"
        _ = assert str eq (path clean "a/../b") "b" "AC1: a/../b -> b"
        _ = assert str eq (path clean "a/../../b") "../b" "AC1: relative .. preserved when above ."
        _ = assert str eq (path clean "../../a/b/..") "../../a" "AC1: leading ../.. preserved"
        _ = assert str eq (path clean "/a/b/../c/./d//") "/a/c/d" "AC1: complex absolute normalization"

        -- path_join & path_join_list
        _ = assert str eq (path join "" "") "." "AC1: join empty empty"
        _ = assert str eq (path join "/var/log" "") "/var/log" "AC1: join with empty right"
        _ = assert str eq (path join "" "app.log") "app.log" "AC1: join with empty left"
        _ = assert str eq (path join "/var/log" "app/server.log") "/var/log/app/server.log" "AC1: join relative child"
        _ = assert str eq (path join "/var/log" "/etc/hosts") "/etc/hosts" "AC1: join absolute child overrides base"
        _ = assert str eq (path join list []) "." "AC1: join_list [] -> ."
        _ = assert str eq (path join list ["src", "main", "ridgun", "lib", "path.rg"]) "src/main/ridgun/lib/path.rg" "AC1: join_list 5 segments"
        ()

-- 2. Component extraction (dirname, basename, split, stem, ext, replace_ext) and edge cases
-- @tests TS-PATH-001
fn :: test path components and confinement => ()
      test path components and confinement =
        p = "/home/boogie/ridgun-libs/src/socket.rg"
        _ = assert true (path is abs p) "AC2: path_is_abs true"
        _ = assert false (path is rel p) "AC2: path_is_rel false"
        _ = assert false (path is abs "") "AC2: empty is not abs"
        _ = assert true (path is rel "src/socket.rg") "AC2: relative path_is_rel"
        _ = assert str eq (path dirname p) "/home/boogie/ridgun-libs/src" "AC2: dirname"
        _ = assert str eq (path basename p) "socket.rg" "AC2: basename"
        sp = path split p
        _ = assert str eq (pair_fst sp) "/home/boogie/ridgun-libs/src" "AC2: split dirname"
        _ = assert str eq (pair_snd sp) "socket.rg" "AC2: split basename"
        _ = assert str eq (path dirname "/") "/" "AC2: dirname of / is /"
        _ = assert str eq (path basename "/") "/" "AC2: basename of / is /"
        _ = assert str eq (path dirname "/top") "/" "AC2: dirname of /top is /"
        _ = assert str eq (path dirname "barefile.txt") "." "AC2: dirname of bare filename is ."

        -- Multi-dot filenames, dotfiles, and extension replacement
        _ = assert str eq (path stem p) "socket" "AC2: stem"
        _ = assert str eq (path ext p) ".rg" "AC2: ext"
        _ = assert str eq (path stem "archive.tar.gz") "archive.tar" "AC2: multi-dot stem"
        _ = assert str eq (path ext "archive.tar.gz") ".gz" "AC2: multi-dot ext"
        _ = assert str eq (path stem ".gitignore") ".gitignore" "AC2: dotfile stem"
        _ = assert str eq (path ext ".gitignore") "" "AC2: dotfile empty ext"
        _ = assert str eq (path replace ext p "rglib") "/home/boogie/ridgun-libs/src/socket.rglib" "AC2: replace_ext without leading dot"
        _ = assert str eq (path replace ext p ".so") "/home/boogie/ridgun-libs/src/socket.so" "AC2: replace_ext with leading dot"
        _ = assert str eq (path replace ext "main.rg" "") "main" "AC2: replace_ext with empty removes extension"

        -- OWASP Path Traversal & Shell Injection Confinement (VUL-INJ-002)
        _ = assert true (path is safe subpath "/srv/www" "assets/app.js") "AC3: safe child subpath"
        _ = assert true (path is safe subpath "/srv/www" "a/b/../c_1-2.txt") "AC3: safe normalized internal .."
        _ = assert false (path is safe subpath "/srv/www" "") "AC3: empty child rejected"
        _ = assert false (path is safe subpath "" "assets/app.js") "AC3: empty base rejected"
        _ = assert false (path is safe subpath "/srv/www" "../etc/passwd") "AC3: direct .. traversal rejected"
        _ = assert false (path is safe subpath "/srv/www" "a/b/../../../etc/passwd") "AC3: deep .. traversal escaping base rejected"
        _ = assert false (path is safe subpath "/srv/www" "/etc/passwd") "AC3: absolute child path rejected"
        _ = assert false (path is safe subpath "/srv/www" "/srv/www/index.html") "AC3: absolute child matching base still rejected"
        _ = assert false (path is safe subpath "/srv/www" "bad;rm -rf /") "AC3: shell semicolon metachar rejected"
        _ = assert false (path is safe subpath "/srv/www" "bad|cat") "AC3: shell pipe metachar rejected"
        _ = assert false (path is safe subpath "/srv/www" "bad$var") "AC3: shell dollar metachar rejected"
        ()

-- @tests TS-PATH-001
fn :: main => ()
      main =
        _ = test path clean and join
        _ = test path components and confinement
        echo "[PASS] test path: TS-PATH-001 passed"
