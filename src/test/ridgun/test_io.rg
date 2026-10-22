-- ============================================================
-- src/test/ridgun/test_io.rg
-- Test suite for io.rg (TS-IO-001, TS-IO-002, TS-PERF-001)
-- @tests TS-IO-001
-- @tests TS-IO-002
-- @tests TS-PERF-001
-- ============================================================

import test
import posix
import io

fn :: pipe rc3 (Int Int Int) => Int
      pipe rc3 (rc, _, _)    =  rc

fn :: pipe rfd3 (Int Int Int) => Int
      pipe rfd3 (_, rfd, _)   =  rfd

fn :: pipe wfd3 (Int Int Int) => Int
      pipe wfd3 (_, _, wfd)   =  wfd

fn :: int list len [Int]    => Int
      int list len []       =  0
      int list len (_:rest) =  1 + (int list len rest)

fn :: str list len [String] => Int
      str list len []       =  0
      str list len (_:rest) =  1 + (str list len rest)

-- ── TS-IO-001: IoError, IoResult & Timeout-Bounded Descriptor Ops ──

-- @tests TS-IO-001
fn :: test io error formatting => ()
      test io error formatting =
        _ = assert_str_eq (format io error (Timeout 500)) "timeout after 500 ms" "format Timeout 500"
        _ = assert_str_eq (format io error Eof) "unexpected end of file" "format Eof"
        _ = assert_str_eq (format io error (SysErr 9 "poll")) "syscall error 9 in poll" "format SysErr"
        _ = assert_str_eq (format io error (NotFound "/missing")) "file not found: /missing" "format NotFound"
        ()

-- @tests TS-IO-001
-- @tests TS-PERF-001
fn :: test io pipe timeout and eof => ()
      test io pipe timeout and eof =
        pt     = posix pipe
        rc     = pipe rc3 pt
        rfd    = pipe rfd3 pt
        wfd    = pipe wfd3 pt
        _      = assert eq rc 0

        -- 1. Empty pipe read with 50 ms timeout must time out within [40, 300) ms (TS-PERF-001 AC2)
        t3     = sys monotonic ms
        r_to   = read fd rfd max 32 timeout 50
        t4     = sys monotonic ms
        dt     = t4 - t3
        _      = assert_str_eq (format io result r_to) "err:timeout after 50 ms" "empty pipe read Timeout 50"
        _      = assert_true (dt >= 40 and dt < 300) "dt in [40, 300): {dt}"

        -- 2. Write payload via mixfix `write fd ... data ... timeout ...`
        w_res  = write fd wfd data "stream-ok" timeout 100
        _      = assert_str_eq (format io result w_res) "ok:int:9" "write fd returns 9 bytes"

        -- 3. Read payload via mixfix `read fd ... max ... timeout ...`
        r_ok   = read fd rfd max 64 timeout 100
        _      = assert_str_eq (format io result r_ok) "ok:str:stream-ok" "read fd returns stream-ok"

        -- 4. Close write end and verify subsequent read returns Eof
        _      = posix close wfd
        r_eof  = read fd rfd max 64 timeout 100
        _      = assert_str_eq (format io result r_eof) "err:unexpected end of file" "closed pipe read returns Eof"
        _      = posix close rfd

        -- 5. Bad fd / invalid max_bytes
        r_bad  = read fd (0 - 1) max 64 timeout 50
        _      = assert_str_eq (format io result r_bad) "err:syscall error 9 in read" "negative fd read SysErr 9"
        r_zero = read fd rfd max 0 timeout 50
        _      = assert_str_eq (format io result r_zero) "err:syscall error 22 in read" "zero max_bytes read SysErr 22"
        ()

-- @tests TS-IO-001
fn :: test io exec timeout => ()
      test io exec timeout =
        ok_res = io exec timeout "true" 500
        _      = assert_str_eq (format io result ok_res) "ok:int:0" "io exec timeout true succeeds"
        to_res = io exec timeout "sleep 2" 40
        _      = assert_str_eq (format io result to_res) "err:timeout after 40 ms" "io exec timeout sleep 2 times out"
        ()

-- ── TS-IO-002: RG-010 File Operations, Metadata & Line Streams ──

-- @tests TS-IO-002
fn :: test io file and metadata => ()
      test io file and metadata =
        pid   = sys_getpid
        dpath = "/tmp/rg_io_dir_{pid}"
        fpath = "{dpath}/file.txt"
        spath = "{dpath}/sym.txt"
        bpath = "{dpath}/bytes.bin"
        lpath = "{dpath}/lines.txt"

        _     = sys rmdir dpath
        _     = posix mkdir dpath
        _     = assert_true (is dir dpath) "is dir dpath"
        _     = assert_false (is file dpath) "not is file dpath"

        -- 1. write_file + append_file + read_file
        _     = write_file fpath "hello "
        w2    = append file fpath "world"
        _     = assert eq w2 0
        _     = assert_str_eq (read_file fpath) "hello world" "write_file + append_file content"

        -- 2. write_bytes + read_bytes
        _     = write_bytes bpath [65, 66, 67, 0, 255]
        rb    = read_bytes bpath
        _     = assert eq (int list len rb) 5

        -- 3. symlink + metadata predicates
        _     = assert_true (sys symlink fpath spath) "sys symlink fpath spath"
        _     = assert_true (file exists fpath) "file exists fpath"
        _     = assert_true (is file fpath) "is file fpath"
        _     = assert_false (is symlink fpath) "not is symlink fpath"
        _     = assert_true (is symlink spath) "is symlink spath"
        _     = assert eq (file size fpath) 11
        _     = assert_true ((file mtime fpath) > 1700000000) "file mtime > 1700000000"
        _     = assert_true ((file mode fpath) > 0) "file mode > 0"
        _     = assert_false (file exists "/tmp/rg_io_nonexistent_999999.txt") "missing file exists False"

        -- 4. io read file safe + io write lines / io read lines
        miss  = io read file safe "/tmp/rg_io_missing_999.txt"
        _     = assert_str_eq (format io result miss) "err:file not found: /tmp/rg_io_missing_999.txt" "NotFound missing file"
        hit   = io read file safe fpath
        _     = assert_str_eq (format io result hit) "ok:str:hello world" "safe read existing file"

        _     = io write lines lpath ["alpha", "beta", "gamma"]
        lines = io read lines lpath
        _     = assert eq (str list len lines) 3

        -- 5. v0.9.5 PAL `io read with timeout` (`with timeout wait_ms do` + `sys open path 2048 0` + `sys poll fd 1 -1`)
        r_amb  = io read with timeout fpath 200_ms
        _      = assert_str_eq (format io result r_amb) "ok:str:hello world" "io read with timeout 200_ms"
        r_miss = io read with timeout "/tmp/rg_io_missing_999.txt" 50_ms
        _      = assert_true (str_starts_with (format io result r_miss) "err:io error -") "io read with timeout missing file -> IoError"

        -- Cleanup
        _     = sys unlink spath
        _     = sys unlink fpath
        _     = sys unlink bpath
        _     = sys unlink lpath
        _     = sys rmdir dpath
        ()

fn :: main => ()
      main =
        _ = test io error formatting
        _ = test io pipe timeout and eof
        _ = test io exec timeout
        _ = test io file and metadata
        echo "[PASS] test_io: TS-IO-001, TS-IO-002, and TS-PERF-001 (poll timeout) passed"
