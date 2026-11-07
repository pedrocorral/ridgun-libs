-- ============================================================
-- src/test/ridgun/test_posix.rg
-- Automated test suite for the POSIX system library (POSIX)
-- @tests TS-POSIX-001
-- @tests TS-POSIX-002
-- @tests TS-POSIX-003
-- ============================================================

import test
import posix
import io

fn :: is poll timeout PollStatus  => Bool
      is poll timeout PollTimeout =  True
      is poll timeout _           =  False

fn :: is poll ready PollStatus    => Bool
      is poll ready (PollReady _) =  True
      is poll ready _             =  False

fn :: is poll error PollStatus    => Bool
      is poll error (PollError _) =  True
      is poll error _             =  False

fn :: tuple3 status (Int Int Int) => Int
      tuple3 status (st, _, _)    =  st

fn :: tuple3 rfd (Int Int Int) => Int
      tuple3 rfd (_, rfd, _)   =  rfd

fn :: tuple3 wfd (Int Int Int) => Int
      tuple3 wfd (_, _, wfd)   =  wfd

fn :: pair fst (A B)  => A
      pair fst (a, _) =  a

fn :: pair snd (A B)  => B
      pair snd (_, b) =  b

-- @tests TS-POSIX-001
fn :: test posix constants descriptors and poll => ()
      test posix constants descriptors and poll =
        _       = assert equals (poll in) 1 "POLLIN == 1"
        _       = assert equals poll out 4 "POLLOUT == 4"
        _       = assert equals (poll err) 8 "POLLERR == 8"
        _       = assert equals (sig int) 2 "SIGINT == 2"
        _       = assert equals (sig kill) 9 "SIGKILL == 9"
        _       = assert equals (sig term) 15 "SIGTERM == 15"
        _       = assert equals (o rdonly) 0 "O_RDONLY == 0"
        _       = assert equals (o wronly) 1 "O_WRONLY == 1"
        _       = assert equals (o rdwr) 2 "O_RDWR == 2"
        _       = assert equals (o creat) 64 "O_CREAT == 64"
        _       = assert equals (o trunc) 512 "O_TRUNC == 512"
        _       = assert equals (o append) 1024 "O_APPEND == 1024"
        _       = assert equals (o nonblock) 2048 "O_NONBLOCK == 2048"
        _       = assert equals (o cloexec) 524288 "O_CLOEXEC == 524288"
        bad_p   = wait fd (0 - 1) (poll in) 10
        _       = assert true (is poll error bad_p) "wait fd on -1 returns PollError"
        p_res   = posix pipe
        _       = assert equals (tuple3 status p_res) 0 "posix pipe status == 0"
        rfd     = tuple3 rfd p_res
        wfd     = tuple3 wfd p_res
        p_to    = wait fd rfd (poll in) 20
        _       = assert true (is poll timeout p_to) "wait fd on empty pipe times out"
        written = posix write wfd "hello-posix"
        _       = assert equals written 11 "posix write 11 bytes"
        p_rdy   = wait fd rfd (poll in) 100
        _       = assert true (is poll ready p_rdy) "wait fd after write is PollReady"
        got     = posix read rfd 64
        _       = assert equals got "hello-posix" "posix read matches written payload"
        _       = assert equals (posix close rfd) 0 "posix close rfd"
        assert equals (posix close wfd) 0 "posix close wfd"

-- @tests TS-POSIX-002
fn :: test posix filesystem clocks signals and random => ()
      test posix filesystem clocks signals and random =
        my_pid  = sys getpid
        dir_p   = "/tmp/rg_posix_test_{my_pid}"
        f1      = "{dir_p}/a.txt"
        f2      = "{dir_p}/b.txt"
        lnk     = "{dir_p}/sym.txt"
        _       = sys rmdir dir_p
        _       = assert true (posix mkdir dir_p) "posix mkdir"
        _       = write file f1 "payload"
        _       = assert true (posix chmod f1 420) "posix chmod 0644"
        _       = assert true (sys rename f1 f2) "sys rename a.txt -> b.txt"
        _       = assert true (sys symlink f2 lnk) "sys symlink"
        _       = assert equals (sys readlink lnk) f2 "sys readlink target"
        _       = assert true (sys unlink lnk) "sys unlink symlink"
        _       = assert true (sys unlink f2) "sys unlink b.txt"
        _       = assert true (sys rmdir dir_p) "sys rmdir"
        _       = assert true ((sys getpid) > 0) "sys_getpid > 0"
        _       = assert true ((str len (sys getcwd)) > 0) "sys_getcwd non-empty"
        t1      = sys monotonic ms
        n1      = sys monotonic ns
        w1      = sys wall time ms
        _       = sys sleep ms 25
        t2      = sys monotonic ms
        n2      = sys monotonic ns
        w2      = sys wall time ms
        _       = assert true ((t2 - t1) >= 20) "monotonic ms elapsed >= 20"
        _       = assert true (n2 > n1) "monotonic ns non-decreasing"
        _       = assert true ((n2 - n1) >= 20000000) "monotonic ns elapsed >= 20ms (20,000,000 ns)"
        _       = assert true (w1 > 1700000000000) "wall time > 1700000000000"
        k_sec   = sys call 201 0 0 0 0 0 0
        w_sec   = w2 / 1000
        _       = assert true (((w_sec - k_sec) <= 2) and ((k_sec - w_sec) <= 2)) "sys_wall_time_ms matches kernel time(0) within 2s"
        _       = assert true ((w2 - w1) >= 20) "wall time ms elapsed >= 20"
        sw_bad  = sys signal watch [9]
        _       = assert equals (pair fst sw_bad) (0 - 7) "SIGKILL watch rejected with -7"
        sw_ok   = sys signal watch [sig term]
        _       = assert equals (pair fst sw_ok) 0 "SIGTERM watch ok"
        sh      = pair snd sw_ok
        _       = assert true ((sys call 72 sh 1 0 0 0 0) >= 0) "signalfd handle is real kernel fd"
        _       = assert equals (sys kill (sys getpid) (sig term)) 0 "real kernel sys_kill SIGTERM does not kill process"
        sw_got  = sys signal wait sh 100
        _       = assert equals (pair fst sw_got) 0 "sys_signal_wait status 0 after real sys_kill"
        _       = assert equals (pair snd sw_got) (sig term) "sys_signal_wait got real SIGTERM (15)"
        _       = assert equals (posix notify signal (sys getpid) (sig term)) 0 "notify signal"
        sw_got2 = sys signal wait sh 100
        _       = assert equals (pair fst sw_got2) 0 "sys_signal_wait status 0"
        _       = assert equals (pair snd sw_got2) (sig term) "sys_signal_wait got SIGTERM"
        sw_to   = sys signal wait sh 20
        _       = assert equals (pair fst sw_to) (0 - 2) "second sys_signal_wait times out (-2)"
        _       = assert equals (posix close sh) 0 "posix close signalfd"
        _       = assert equals (pair fst (sys signal wait sh 10)) (0 - 7) "sys_signal_wait on closed fd -> -7"
        r_bad   = sys random bytes (0 - 1)
        _       = assert equals (pair fst r_bad) (0 - 7) "negative random bytes -> -7"
        r_zero  = sys random bytes 0
        _       = assert equals (pair fst r_zero) 0 "0 random bytes -> 0"
        _       = assert equals (pair snd r_zero) "" "0 random bytes -> empty"
        r1      = sys random bytes 32
        r2      = sys random bytes 32
        rl      = sys random bytes list 256
        _       = assert equals (pair fst r1) 0 "random 32 status 0"
        _       = assert equals (str len (pair snd r1)) 32 "random 32 length == 32"
        _       = assert equals (pair fst rl) 0 "random list 256 status 0"
        _       = assert equals (path separator Linux) "/" "path separator Linux"
        _       = assert equals (path separator Windows) "\\" "path separator Windows"
        _       = assert equals (null device for Linux) "/dev/null" "null device Linux"
        _       = assert equals (null device for Windows) "NUL" "null device Windows"
        _       = assert true (process exists (sys getpid)) "process exists self"
        _       = assert false (process exists 99999999) "process exists non-existent pid"
        assert false ((pair snd r1) == (pair snd r2)) "two 32-byte random draws differ"

fn :: is proc exited ProcStatus        Int => Bool
      is proc exited (ProcExited code) exp =  code == exp
      is proc exited _                 _   =  False

fn :: run child echo Int Int => Int
      run child echo rfd wfd =
        _ = posix close rfd
        _ = posix dup2 wfd 1
        _ = posix close wfd
        _ = posix execve "/bin/echo" ["/bin/echo", "-n", "hello; $WORLD `safe`"] ["WORLD=injected"]
        posix exit 127

fn :: handle fork branch Int Int Int => ()
      handle fork branch pid rfd wfd =
        | pid == 0 =
          _ = run child echo rfd wfd
          ()
        | otherwise =
          _     = assert true (pid > 0) "posix fork returns child pid > 0"
          _     = posix close wfd
          w_res = posix waitpid pid 0
          _     = assert equals (pair fst w_res) pid "posix waitpid returns child pid"
          st    = waitpid decode status (pair snd w_res)
          _     = assert true (is proc exited st 0) "waitpid decode status -> ProcExited 0"
          out   = posix read rfd 128
          _     = posix close rfd
          assert equals out "hello; $WORLD `safe`" "posix execve passes literal argv without shell interpretation"

fn :: test posix fork pipe dup2 execve waitpid => ()
      test posix fork pipe dup2 execve waitpid =
        _       = assert equals wnohang 1 "WNOHANG == 1"
        _       = assert equals wuntraced 2 "WUNTRACED == 2"
        p_res   = posix pipe
        _       = assert equals (tuple3 status p_res) 0 "posix pipe status == 0"
        rfd     = tuple3 rfd p_res
        wfd     = tuple3 wfd p_res
        handle fork branch (posix fork) rfd wfd

fn :: child lock probe String => ()
      child lock probe path   =
        fd = posix open path (o rdwr) 0
        rc = posix lock exclusive fd
        _  = posix exit (0 - rc)
        ()

fn :: parent lock check Int Int => ()
      parent lock check pid t0  =
        w_res = posix waitpid pid 0
        st    = pair snd w_res
        -- `sys waitpid` may return the decoded exit code (11) or the raw wait status (11 shl 8).
        _     = assert true ((st == (errno ewouldblock)) or (st == ((errno ewouldblock) * 256))) "second process gets EWOULDBLOCK (exit 11)"
        assert true (((sys monotonic ms) - t0) < 1000) "second process did not wait for the lock"

fn :: handle lock fork Int String Int => ()
      handle lock fork pid path   t0  =
        | pid == 0  = child lock probe path
        | otherwise = parent lock check pid t0

-- @tests TS-POSIX-003
fn :: test posix durable file ops => ()
      test posix durable file ops =
        _      = assert equals (px sys nr X86_64 75 83) 75 "picker: x86_64 number"
        _      = assert equals (px sys nr Arm64 75 83) 83 "picker: arm64 number"
        _      = assert equals (o directory for X86_64) 65536 "O_DIRECTORY x86_64"
        _      = assert equals (o directory for Arm64) 16384 "O_DIRECTORY arm64"
        _      = assert equals (nr fdatasync) (px sys nr (sys arch) 75 83) "fdatasync nr matches the host arch"
        _      = assert equals (nr fsync) (px sys nr (sys arch) 74 82) "fsync nr matches the host arch"
        _      = assert equals (nr ftruncate) (px sys nr (sys arch) 77 46) "ftruncate nr matches the host arch"
        _      = assert equals (nr flock) (px sys nr (sys arch) 73 32) "flock nr matches the host arch"
        _      = assert equals (nr pread64) (px sys nr (sys arch) 17 67) "pread64 nr matches the host arch"
        my_pid = sys getpid
        dir_p  = "/tmp/rg_posix_dur_{my_pid}"
        f_dat  = "{dir_p}/f.dat"
        f_lock = "{dir_p}/lock"
        f_r    = "{dir_p}/r.dat"
        _      = assert true (posix mkdir dir_p) "mkdir durable test dir"
        fd     = posix open f_dat ((o creat) + (o rdwr) + (o trunc)) 420
        _      = assert true (fd >= 0) "open f.dat"
        _      = assert equals (posix write fd "0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789") 100 "write 100 bytes"
        _      = assert equals (posix fdatasync fd) 0 "fdatasync on fresh write -> 0"
        _      = assert equals (posix fsync fd) 0 "fsync on fresh write -> 0"
        _      = assert equals (posix close fd) 0 "close f.dat"
        _      = assert equals (posix fdatasync fd) (0 - errno ebadf) "fdatasync on closed fd -> -EBADF"
        _      = assert equals (posix fsync fd) (0 - errno ebadf) "fsync on closed fd -> -EBADF"
        _      = assert equals (posix fdatasync (0 - 1)) (0 - 9) "fdatasync on -1 -> -9"
        fd2    = posix open f_dat (o rdwr) 0
        _      = assert equals (file size f_dat) 100 "file size before truncate"
        _      = assert equals (posix ftruncate fd2 40) 0 "ftruncate to 40 -> 0"
        _      = assert equals (file size f_dat) 40 "file size after truncate == 40"
        _      = assert equals (posix ftruncate fd2 (0 - 1)) (0 - errno einval) "ftruncate negative -> -EINVAL"
        _      = posix close fd2
        _      = assert equals (posix sync dir dir_p) 0 "sync dir on directory -> 0"
        _      = assert equals (posix sync dir f_dat) (0 - errno enotdir) "sync dir on file -> -ENOTDIR"
        _      = assert true ((posix sync dir "{dir_p}/missing") < 0) "sync dir on missing path -> error"
        _      = write file f_lock "x"
        la     = posix open f_lock (o rdwr) 0
        lb     = posix open f_lock (o rdwr) 0
        _      = assert equals (posix lock exclusive la) 0 "first lock -> 0"
        _      = assert equals (posix lock exclusive lb) (0 - errno ewouldblock) "second open file -> -EWOULDBLOCK"
        t0     = sys monotonic ms
        _      = handle lock fork (posix fork) f_lock t0
        _      = assert equals (posix unlock la) 0 "unlock -> 0"
        _      = assert equals (posix lock exclusive lb) 0 "lock after unlock -> 0"
        _      = posix close la
        _      = posix close lb
        _      = write file f_r "0123456789ABCDEFGHIJ"
        rf     = posix open f_r (o rdonly) 0
        _      = assert equals (posix read rf 3) "012" "read 3 moves position to 3"
        p1     = posix pread rf 10 5
        _      = assert equals (pair fst p1) 5 "pread 5 bytes"
        _      = assert equals (pair snd p1) "ABCDE" "pread [10,15)"
        p2     = posix pread rf 15 100
        _      = assert equals (pair fst p2) 5 "pread short read at end"
        _      = assert equals (pair snd p2) "FGHIJ" "pread [15,20)"
        p3     = posix pread rf 20 4
        _      = assert equals (pair fst p3) 0 "pread at EOF -> 0"
        _      = assert equals (pair snd p3) "" "pread at EOF -> empty"
        _      = assert equals (posix read rf 2) "34" "pread kept the descriptor position"
        _      = assert equals (pair fst (posix pread rf (0 - 1) 4)) (0 - errno einval) "pread negative offset -> -EINVAL"
        _      = assert equals (pair fst (posix pread rf 0 (0 - 1))) (0 - errno einval) "pread negative length -> -EINVAL"
        _      = assert equals (pair fst (posix pread rf 0 16777217)) (0 - errno einval) "pread over 16 MiB -> -EINVAL"
        _      = assert equals (pair fst (posix pread rf 0 0)) 0 "pread length 0 -> 0"
        _      = posix close rf
        z      = px raw byte 0
        ff     = px raw byte 255
        hi     = px raw byte 128
        bin    = "{z}{ff}{z}A{hi}{ff}{z}Z"
        _      = assert equals (str len bin) 8 "binary fixture is 8 bytes"
        bf     = posix open "{dir_p}/b.dat" ((o creat) + (o wronly) + (o trunc)) 420
        _      = assert equals (posix write bf bin) 8 "write 8 binary bytes"
        _      = posix close bf
        bf2    = posix open "{dir_p}/b.dat" (o rdonly) 0
        pb     = posix pread bf2 1 6
        _      = posix close bf2
        got    = pair snd pb
        _      = assert equals (pair fst pb) 6 "pread 6 binary bytes"
        _      = assert equals got (str slice bin 1 7) "pread binary [1,7) matches"
        _      = assert equals (str char at got 0) 255 "pread keeps 0xFF"
        _      = assert equals (str char at got 1) 0 "pread keeps 0x00"
        _      = assert equals (str char at got 3) 128 "pread keeps 0x80"
        _      = assert equals (str char at got 5) 0 "pread keeps trailing 0x00"
        _      = sys unlink "{dir_p}/b.dat"
        _      = assert equals (pair fst (posix pread 99999 0 4)) (0 - errno ebadf) "pread on unopened fd -> -EBADF"
        _      = assert equals (pair fst (posix pread (0 - 1) 0 4)) (0 - errno ebadf) "pread on -1 -> -EBADF"
        _      = assert equals (errno eio) 5 "EIO == 5"
        _      = assert equals (errno enospc) 28 "ENOSPC == 28"
        _      = sys unlink f_dat
        _      = sys unlink f_lock
        _      = sys unlink f_r
        assert true (sys rmdir dir_p) "remove durable test dir"

fn :: main => ()
      main =
        _ = test posix constants descriptors and poll
        _ = test posix filesystem clocks signals and random
        _ = test posix durable file ops
        _ = test posix fork pipe dup2 execve waitpid
        echo "[PASS] test_posix: TS-POSIX-001, TS-POSIX-002 and TS-POSIX-003 passed"
