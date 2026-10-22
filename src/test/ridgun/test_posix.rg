-- ============================================================
-- src/test/ridgun/test_posix.rg
-- Automated test suite for the POSIX system library (POSIX)
-- @tests TS-POSIX-001
-- @tests TS-POSIX-002
-- ============================================================

import test
import posix

fn :: is poll timeout PollStatus  => Bool
      is poll timeout PollTimeout =  True
      is poll timeout _           =  False

fn :: is poll ready PollStatus    => Bool
      is poll ready (PollReady _) =  True
      is poll ready _             =  False

fn :: is poll error PollStatus    => Bool
      is poll error (PollError _) =  True
      is poll error _             =  False

fn :: tuple3 status (Int, Int, Int) => Int
      tuple3 status (st, _, _)      =  st

fn :: tuple3 rfd (Int, Int, Int) => Int
      tuple3 rfd (_, rfd, _)     =  rfd

fn :: tuple3 wfd (Int, Int, Int) => Int
      tuple3 wfd (_, _, wfd)     =  wfd

fn :: pair fst (A, B) => A
      pair fst (a, _) =  a

fn :: pair snd (A, B) => B
      pair snd (_, b) =  b

-- @tests TS-POSIX-001
fn :: test_posix_constants_descriptors_and_poll => ()
      test_posix_constants_descriptors_and_poll =
        _       = assert_equals (poll in) 1 "POLLIN == 1"
        _       = assert_equals (poll_out) 4 "POLLOUT == 4"
        _       = assert_equals (poll err) 8 "POLLERR == 8"
        _       = assert_equals (sig int) 2 "SIGINT == 2"
        _       = assert_equals (sig kill) 9 "SIGKILL == 9"
        _       = assert_equals (sig term) 15 "SIGTERM == 15"
        _       = assert_equals (o rdonly) 0 "O_RDONLY == 0"
        _       = assert_equals (o wronly) 1 "O_WRONLY == 1"
        _       = assert_equals (o rdwr) 2 "O_RDWR == 2"
        _       = assert_equals (o creat) 64 "O_CREAT == 64"
        _       = assert_equals (o trunc) 512 "O_TRUNC == 512"
        _       = assert_equals (o append) 1024 "O_APPEND == 1024"
        _       = assert_equals (o nonblock) 2048 "O_NONBLOCK == 2048"
        _       = assert_equals (o cloexec) 524288 "O_CLOEXEC == 524288"
        bad_p   = wait fd (0 - 1) (poll in) 10
        _       = assert_true (is poll error bad_p) "wait fd on -1 returns PollError"
        p_res   = posix pipe
        _       = assert_equals (tuple3 status p_res) 0 "posix pipe status == 0"
        rfd     = tuple3 rfd p_res
        wfd     = tuple3 wfd p_res
        p_to    = wait fd rfd (poll in) 20
        _       = assert_true (is poll timeout p_to) "wait fd on empty pipe times out"
        written = posix write wfd "hello-posix"
        _       = assert_equals written 11 "posix write 11 bytes"
        p_rdy   = wait fd rfd (poll in) 100
        _       = assert_true (is poll ready p_rdy) "wait fd after write is PollReady"
        got     = posix read rfd 64
        _       = assert_equals got "hello-posix" "posix read matches written payload"
        _       = assert_equals (posix close rfd) 0 "posix close rfd"
        assert_equals (posix close wfd) 0 "posix close wfd"

-- @tests TS-POSIX-002
fn :: test_posix_filesystem_clocks_signals_and_random => ()
      test_posix_filesystem_clocks_signals_and_random =
        dir_p   = "/tmp/rg_posix_test_{sys_getpid}"
        f1      = "{dir_p}/a.txt"
        f2      = "{dir_p}/b.txt"
        lnk     = "{dir_p}/sym.txt"
        _       = sys rmdir dir_p
        _       = assert_true (posix mkdir dir_p) "posix mkdir"
        _       = write_file f1 "payload"
        _       = assert_true (posix chmod f1 420) "posix chmod 0644"
        _       = assert_true (sys rename f1 f2) "sys rename a.txt -> b.txt"
        _       = assert_true (sys symlink f2 lnk) "sys symlink"
        _       = assert_equals (sys readlink lnk) f2 "sys readlink target"
        _       = assert_true (sys unlink lnk) "sys unlink symlink"
        _       = assert_true (sys unlink f2) "sys unlink b.txt"
        _       = assert_true (sys rmdir dir_p) "sys rmdir"
        _       = assert_true ((sys_getpid) > 0) "sys_getpid > 0"
        _       = assert_true ((str_len (sys_getcwd)) > 0) "sys_getcwd non-empty"
        t1      = sys monotonic ms
        n1      = sys monotonic ns
        w1      = sys wall time ms
        _       = sys_sleep_ms 25
        t2      = sys monotonic ms
        n2      = sys monotonic ns
        w2      = sys wall time ms
        _       = assert_true ((t2 - t1) >= 20) "monotonic ms elapsed >= 20"
        _       = assert_true (n2 > n1) "monotonic ns non-decreasing"
        _       = assert_true ((n2 - n1) >= 20000000) "monotonic ns elapsed >= 20ms (20,000,000 ns)"
        _       = assert_true (w1 > 1700000000000) "wall time > 1700000000000"
        k_sec   = sys_call 201 0 0 0 0 0 0
        w_sec   = w2 / 1000
        _       = assert_true (((w_sec - k_sec) <= 2) and ((k_sec - w_sec) <= 2)) "sys_wall_time_ms matches kernel time(0) within 2s"
        _       = assert_true ((w2 - w1) >= 20) "wall time ms elapsed >= 20"
        sw_bad  = sys signal watch [9]
        _       = assert_equals (pair fst sw_bad) (0 - 7) "SIGKILL watch rejected with -7"
        sw_ok   = sys signal watch [sig term]
        _       = assert_equals (pair fst sw_ok) 0 "SIGTERM watch ok"
        sh      = pair snd sw_ok
        _       = assert_true ((sys_call 72 sh 1 0 0 0 0) >= 0) "signalfd handle is real kernel fd"
        _       = assert_equals (sys_kill (sys_getpid) (sig term)) 0 "real kernel sys_kill SIGTERM does not kill process"
        sw_got  = sys signal wait sh 100
        _       = assert_equals (pair fst sw_got) 0 "sys_signal_wait status 0 after real sys_kill"
        _       = assert_equals (pair snd sw_got) (sig term) "sys_signal_wait got real SIGTERM (15)"
        _       = assert_equals (posix notify signal (sys_getpid) (sig term)) 0 "notify signal"
        sw_got2 = sys signal wait sh 100
        _       = assert_equals (pair fst sw_got2) 0 "sys_signal_wait status 0"
        _       = assert_equals (pair snd sw_got2) (sig term) "sys_signal_wait got SIGTERM"
        sw_to   = sys signal wait sh 20
        _       = assert_equals (pair fst sw_to) (0 - 2) "second sys_signal_wait times out (-2)"
        _       = assert_equals (posix close sh) 0 "posix close signalfd"
        _       = assert_equals (pair fst (sys signal wait sh 10)) (0 - 7) "sys_signal_wait on closed fd -> -7"
        r_bad   = sys random bytes (0 - 1)
        _       = assert_equals (pair fst r_bad) (0 - 7) "negative random bytes -> -7"
        r_zero  = sys random bytes 0
        _       = assert_equals (pair fst r_zero) 0 "0 random bytes -> 0"
        _       = assert_equals (pair snd r_zero) "" "0 random bytes -> empty"
        r1      = sys random bytes 32
        r2      = sys random bytes 32
        rl      = sys random bytes list 256
        _       = assert_equals (pair fst r1) 0 "random 32 status 0"
        _       = assert_equals (str_len (pair snd r1)) 32 "random 32 length == 32"
        _       = assert_equals (pair fst rl) 0 "random list 256 status 0"
        _       = assert_equals (path separator Linux) "/" "path separator Linux"
        _       = assert_equals (path separator Windows) "\\" "path separator Windows"
        _       = assert_equals (null device for Linux) "/dev/null" "null device Linux"
        _       = assert_equals (null device for Windows) "NUL" "null device Windows"
        _       = assert_true (process exists (sys_getpid)) "process exists self"
        _       = assert_false (process exists 99999999) "process exists non-existent pid"
        assert_false ((pair snd r1) == (pair snd r2)) "two 32-byte random draws differ"

fn :: main => ()
      main =
        _ = test_posix_constants_descriptors_and_poll
        _ = test_posix_filesystem_clocks_signals_and_random
        echo "[PASS] test_posix: TS-POSIX-001 and TS-POSIX-002 passed"
