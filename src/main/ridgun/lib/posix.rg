-- ============================================================
-- src/main/ridgun/lib/posix.rg
-- Pure-Ridgun POSIX Descriptors, Poll, Signals, Clocks & Random Library (POSIX)
-- @implements FR-POSIX-001
-- @implements FR-POSIX-002
-- @implements API-POSIX-001
-- @implements DM-PosixStatus
-- @mitigates VUL-INJ-002
-- @mitigates VUL-INPUT-001
-- ============================================================

-- ── Poll & Process Status ADTs ───────────────────────────────

-- @implements FR-POSIX-001
-- @implements DM-PosixStatus
type PollStatus = PollReady Int | PollTimeout | PollError Int

-- @implements FR-POSIX-001
-- @implements DM-PosixStatus
type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int

-- ── Standard POSIX Poll Event Constants ──────────────────────

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: poll in => Int
      poll in =  1

fn :: poll out => Int
      poll out =  4

fn :: poll err => Int
      poll err =  8

fn :: poll hup => Int
      poll hup =  16

fn :: poll nval => Int
      poll nval =  32

-- ── Standard POSIX Signal Constants (Linux x86_64 / ARM64) ───

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: sig hup => Int
      sig hup =  1

fn :: sig int => Int
      sig int =  2

fn :: sig quit => Int
      sig quit =  3

fn :: sig kill => Int
      sig kill =  9

fn :: sig usr1 => Int
      sig usr1 =  10

fn :: sig usr2 => Int
      sig usr2 =  12

fn :: sig pipe => Int
      sig pipe =  13

fn :: sig alrm => Int
      sig alrm =  14

fn :: sig term => Int
      sig term =  15

fn :: sig chld => Int
      sig chld =  17

-- ── Standard POSIX Open Flag Constants ───────────────────────

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: o rdonly => Int
      o rdonly =  0

fn :: o wronly => Int
      o wronly =  1

fn :: o rdwr => Int
      o rdwr =  2

fn :: o creat => Int
      o creat =  64

fn :: o excl => Int
      o excl =  128

fn :: o trunc => Int
      o trunc =  512

fn :: o append => Int
      o append =  1024

fn :: o nonblock => Int
      o nonblock =  2048

fn :: o cloexec => Int
      o cloexec =  524288

-- ── Path Safety Validation (VUL-INJ-002 / VUL-INPUT-001) ─────

fn :: is bad posix code Int => Bool
      is bad posix code c   =
        c == 0 or c == 10 or c == 13 or c == 59 or c == 96 or c == 124 or c == 38 or c == 36 or c == 39 or c == 34

-- @mitigates VUL-INJ-002
-- @mitigates VUL-INPUT-001
fn :: has unsafe posix char String Int Int => Bool
      has unsafe posix char s idx slen =
        | idx >= slen                           = False
        | is bad posix code (str char at s idx) = True
        | otherwise                             = has unsafe posix char s (idx + 1) slen

fn :: is safe posix path len String Int => Bool
      is safe posix path len path plen =
        | plen == 0 or plen > 4096 = False
        | otherwise                = not (has unsafe posix char path 0 plen)

fn :: is safe posix path String => Bool
      is safe posix path path   =
        is safe posix path len path (str len path)

-- ── lstat Tuple Accessors ────────────────────────────────────

fn :: lstat exists (Bool String Int Int Int String String Int String) => Bool
      lstat exists (ex, _, _, _, _, _, _, _, _)                       =  ex

fn :: lstat kind (Bool String Int Int Int String String Int String) => String
      lstat kind (_, k, _, _, _, _, _, _, _)                        =  k

fn :: lstat mode (Bool String Int Int Int String String Int String) => Int
      lstat mode (_, _, m, _, _, _, _, _, _)                        =  m

fn :: lstat size (Bool String Int Int Int String String Int String) => Int
      lstat size (_, _, _, _, sz, _, _, _, _)                       =  sz

fn :: lstat mtime sec (Bool String Int Int Int String String Int String) => Int
      lstat mtime sec (_, _, _, _, _, _, _, mt, _)                       =  mt

fn :: lstat symlink target (Bool String Int Int Int String String Int String) => String
      lstat symlink target (_, _, _, _, _, _, _, _, target) = target

-- ── Kernel Memory Bridge Helpers (mmap + memfd_create + eventfd2) ──

fn :: px raw byte ub Int => String
      px raw byte ub ub  =
        | ub >= 1 and ub <= 127 = char from code ub
        | otherwise =
          efd = sys call 290 (256 + ub) 526336 0 0 0 0
          s   = sys read fd efd 8
          _   = sys close efd
          str slice s 0 1

fn :: px raw byte Int => String
      px raw byte b   =  px raw byte ub (((b % 256) + 256) % 256)

fn :: px u64 le Int => String
      px u64 le val =
        | val <= 0 =
          b0 = px raw byte 0
          b0 + b0 + b0 + b0 + b0 + b0 + b0 + b0
        | otherwise =
          efd = sys call 290 val 526336 0 0 0 0
          s   = sys read fd efd 8
          _   = sys close efd
          s

fn :: px decode u32 le String Int => Int
      px decode u32 le s off =
        b0 = str char at s off
        b1 = str char at s (off + 1)
        b2 = str char at s (off + 2)
        b3 = str char at s (off + 3)
        b0 + (b1 * 256) + (b2 * 65536) + (b3 * 16777216)

fn :: px decode u64 le String Int => Int
      px decode u64 le s off =
        lo = px decode u32 le s off
        hi = px decode u32 le s (off + 4)
        lo + (hi * 4294967296)

fn :: px alloc page Int => Int
      px alloc page sz  =
        neg1 = 0 - 1
        sys call 9 0 sz 3 34 neg1 0

fn :: px free page Int Int Int => Int
      px free page mfd ptr sz =
        _ = sys close mfd
        sys call 11 ptr sz 0 0 0 0

fn :: px alloc mfd => Int
      px alloc mfd =  sys call 319 4194311 1 0 0 0 0

fn :: px poke Int Int String => Int
      px poke mfd ptr s      =
        slen = str len s
        _    = sys call 8 mfd 0 0 0 0 0
        _    = sys write fd mfd s
        sys call 17 mfd ptr slen 0 0 0

fn :: px peek Int Int Int => String
      px peek mfd ptr len =
        _ = sys call 18 mfd ptr len 0 0 0
        _ = sys call 8 mfd 0 0 0 0 0
        sys read fd mfd len

-- ── Monotonic & Wall-Clock Time (RGF-017 / RG-010) ───────────

fn :: px clock gettime Int    => Int Int
      px clock gettime clk_id =
        ptr  = px alloc page 4096
        mfd  = px alloc mfd
        _    = sys call 228 clk_id ptr 0 0 0 0
        raw  = px peek mfd ptr 16
        _    = px free page mfd ptr 4096
        sec  = px decode u64 le raw 0
        nsec = px decode u64 le raw 8
        (sec, nsec)

fn :: px pair fst (Int Int) => Int
      px pair fst (a, _)    =  a

fn :: px pair snd (Int Int) => Int
      px pair snd (_, b)    =  b

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys monotonic ms => Int
      sys monotonic ms =
        ts = px clock gettime 1
        ((px pair fst ts) * 1000) + ((px pair snd ts) / 1000000)

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys monotonic ns => Int
      sys monotonic ns =
        ts = px clock gettime 1
        ((px pair fst ts) * 1000000000) + (px pair snd ts)

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys wall time ms => Int
      sys wall time ms =
        ts = px clock gettime 0
        ((px pair fst ts) * 1000) + ((px pair snd ts) / 1000000)

-- ── Descriptor Waiting & Typed POSIX Wrappers (FR-POSIX-001) ─

fn :: map poll rc Int => PollStatus
      map poll rc rc  =
        | rc == 0   = PollTimeout
        | rc < 0    = PollError (0 - rc)
        | otherwise = PollReady rc

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: wait fd Int Int    Int        => PollStatus
      wait fd fd  events timeout_ms =
        | fd < 0               = PollError 9
        | timeout_ms < (0 - 1) = PollError 22
        | otherwise            = map poll rc (sys poll fd events timeout_ms)

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: posix open String Int   Int  => Int
      posix open path   flags mode =
        | not (is safe posix path path) = 0 - 22
        | otherwise                     = sys open path flags mode

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: posix close Int => Int
      posix close fd  =
        | fd < 0    = 0 - 9
        | otherwise = sys close fd

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: posix read Int Int       => String
      posix read fd  max_bytes =
        | fd < 0 or max_bytes <= 0 = ""
        | otherwise                = sys read fd fd max_bytes

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: posix write Int String => Int
      posix write fd  data   =
        | fd < 0    = 0 - 9
        | otherwise = sys write fd fd data

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: posix kill Int Int     => Int
      posix kill pid sig_num =
        | pid <= 0 or sig_num <= 0 or sig_num > 64 = 0 - 22
        | otherwise                                = sys kill pid sig_num

-- ── Kernel-Backed Anonymous Pipe via pipe2 (__NR_pipe2 = 293) ─

fn :: pack pipe fds Int Int Int => Int Int Int
      pack pipe fds rc rfd wfd =
        | rc < 0 or rfd < 0 or wfd < 0 = (0 - 1, 0 - 1, 0 - 1)
        | otherwise                    = (0, rfd, wfd)

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: posix pipe => Int Int Int
      posix pipe =
        ptr = px alloc page 4096
        mfd = px alloc mfd
        rc  = sys call 293 ptr 526336 0 0 0 0
        raw = px peek mfd ptr 8
        _   = px free page mfd ptr 4096
        rfd = px decode u32 le raw 0
        wfd = px decode u32 le raw 4
        pack pipe fds rc rfd wfd

-- ── RG-010 Filesystem & Process Operations ───────────────────

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: posix mkdir String => Bool
      posix mkdir path   =
        | not (is safe posix path path) = False
        | otherwise                     = (sys mkdir path 493) == 0

fn :: posix chmod String Int  => Bool
      posix chmod path   mode =
        | not (is safe posix path path) = False
        | otherwise                     = (sys chmod path mode) == 0

fn :: posix chdir String => Bool
      posix chdir path   =
        | not (is safe posix path path) = False
        | otherwise                     = (sys chdir path) == 0

fn :: px syscall1 path Int String => Int
      px syscall1 path nr  path   =
        ptr = px alloc page 4096
        mfd = px alloc mfd
        b0  = px raw byte 0
        _   = px poke mfd ptr (path + b0)
        rc  = sys call nr ptr 0 0 0 0 0
        _   = px free page mfd ptr 4096
        rc

fn :: px syscall2 path Int String String => Int
      px syscall2 path nr p1 p2 =
        ptr   = px alloc page 4096
        mfd   = px alloc mfd
        b0    = px raw byte 0
        p2048 = ptr + 2048
        _     = px poke mfd ptr (p1 + b0)
        _     = px poke mfd p2048 (p2 + b0)
        rc    = sys call nr ptr p2048 0 0 0 0
        _     = px free page mfd ptr 4096
        rc

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys rmdir String => Bool
      sys rmdir path   =
        | not (is safe posix path path) = False
        | otherwise                     = (px syscall1 path 84 path) == 0

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys unlink String => Bool
      sys unlink path   =
        | not (is safe posix path path) = False
        | otherwise                     = (px syscall1 path 87 path) == 0

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys rename String String   => Bool
      sys rename old_p  new_path =
        | not (is safe posix path old_p) or not (is safe posix path new_path) = False
        | otherwise = (px syscall2 path 82 old_p new_path) == 0

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys symlink String String    => Bool
      sys symlink target link_path =
        | not (is safe posix path target) or not (is safe posix path link_path) = False
        | otherwise = (px syscall2 path 88 target link_path) == 0

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys readlink String => String
      sys readlink path   =
        | not (is safe posix path path) = ""
        | otherwise                     = lstat symlink target (file lstat path)

-- ── RGF-018 Signal Watching & Waiting (rt_sigprocmask + signalfd4) ──

fn :: valid signal list [Int]    => Bool
      valid signal list []       =  False
      valid signal list (s:rest) =
        | s < 1 or s > 64 or s == 9 or s == 19 = False
        | otherwise                            = valid signal rest rest

fn :: valid signal rest [Int]    => Bool
      valid signal rest []       =  True
      valid signal rest (s:rest) =
        | s < 1 or s > 64 or s == 9 or s == 19 = False
        | otherwise                            = valid signal rest rest

fn :: px bit shift Int => Int
      px bit shift n   =
        | n <= 0    = 1
        | otherwise = 2 * (px bit shift (n - 1))

fn :: px sig mask [Int]    => Int
      px sig mask []       =  0
      px sig mask (s:rest) =  (px bit shift (s - 1)) + (px sig mask rest)

fn :: px finish sig watch Int => Int Int
      px finish sig watch sfd =
        | sfd < 0   = (0 - 7, 0 - 1)
        | otherwise = (0, sfd)

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys signal watch [Int] => Int Int
      sys signal watch sigs  =
        | not (valid signal list sigs) = (0 - 7, 0 - 1)
        | otherwise                    =
          ptr  = px alloc page 4096
          mfd  = px alloc mfd
          mask = px sig mask sigs
          neg1 = 0 - 1
          _    = px poke mfd ptr (px u64 le mask)
          _    = sys call 14 0 ptr 0 8 0 0
          sfd  = sys call 289 neg1 ptr 8 526336 0 0
          _    = px free page mfd ptr 4096
          px finish sig watch sfd

fn :: px finish sig read Int String => Int Int
      px finish sig read n raw =
        | n < 128   = (0 - 7, 0)
        | otherwise = (0, px decode u32 le raw 0)

fn :: px wait sig after poll Int Int => Int Int
      px wait sig after poll handle prc =
        | prc == 0 = (0 - 2, 0)
        | prc < 0  = (0 - 7, 0)
        | otherwise =
          ptr = px alloc page 4096
          mfd = px alloc mfd
          n   = sys call 0 handle ptr 128 0 0 0
          raw = px peek mfd ptr 16
          _   = px free page mfd ptr 4096
          px finish sig read n raw

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys signal wait Int    Int        => Int Int
      sys signal wait handle timeout_ms =
        | handle < 0 or timeout_ms < (0 - 1)       = (0 - 7, 0)
        | (sys call 72 handle 1 0 0 0 0) < 0       = (0 - 7, 0)
        | otherwise                                = px wait sig after poll handle (sys poll handle 1 timeout_ms)

fn :: posix notify signal Int    Int    => Int
      posix notify signal target sig_no =
        posix kill target sig_no

-- ── RGF-014 Cryptographic Random Bytes (getrandom __NR_getrandom = 318) ──

fn :: px bytes to list loop String Int Int => [Int]
      px bytes to list loop s idx slen =
        | idx >= slen = []
        | otherwise   =
          b = ((str char at s idx) % 256 + 256) % 256
          [b] :: (px bytes to list loop s (idx + 1) slen)

fn :: px getrandom call Int Int Int => Int
      px getrandom call ptr rem rc =
        | rc == (0 - 4) = px getrandom loop ptr rem
        | otherwise     = rc

fn :: px getrandom step Int Int Int => Int
      px getrandom step ptr rem rc =
        | rc <= 0   = rc
        | rc >= rem = 0
        | otherwise = px getrandom loop (ptr + rc) (rem - rc)

fn :: px getrandom loop Int Int => Int
      px getrandom loop ptr rem =
        | rem <= 0  = 0
        | otherwise = px getrandom step ptr rem (px getrandom call ptr rem (sys call 318 ptr rem 0 0 0 0))

fn :: px finish getrandom Int String Int => Int String
      px finish getrandom rc raw n =
        | rc < 0 or (str len raw) != n = (0 - 99, "")
        | otherwise                    = (0, raw)

fn :: px getrandom checked Int => Int String
      px getrandom checked n   =
        psz = ((n / 4096) + 2) * 4096
        ptr = px alloc page psz
        mfd = px alloc mfd
        rc  = px getrandom loop ptr n
        raw = px peek mfd ptr n
        _   = px free page mfd ptr psz
        px finish getrandom rc raw n

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
-- @mitigates VUL-INPUT-001
fn :: sys random bytes Int => Int String
      sys random bytes n   =
        | n < 0     = (0 - 7, "")
        | n == 0    = (0, "")
        | n > 65536 = (0 - 7, "")
        | otherwise = px getrandom checked n

fn :: px finish random list (Int String) => Int [Int]
      px finish random list (rc, raw)    =
        | rc != 0   = (rc, [])
        | otherwise = (0, px bytes to list loop raw 0 (str len raw))

fn :: sys random bytes list Int => Int [Int]
      sys random bytes list n   =
        | n < 0     = (0 - 7, [])
        | n == 0    = (0, [])
        | n > 65536 = (0 - 7, [])
        | otherwise = px finish random list (px getrandom checked n)

-- ── Ridgun v0.9.5 Target OS / Arch & Process Probe Helpers ───

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: path separator SysOs   => String
      path separator Windows =  "\\"
      path separator _       =  "/"

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: null device for SysOs   => String
      null device for Windows =  "NUL"
      null device for _       =  "/dev/null"

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: null device => String
      null device =  null device for (sys os)

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: process exists Int => Bool
      process exists pid =
        | pid <= 0  = False
        | otherwise = (sys kill pid 0) == 0
