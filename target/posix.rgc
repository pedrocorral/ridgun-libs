-- ============================================================
-- src/main/ridgun/lib/posix.rg
-- Pure-Ridgun POSIX Descriptors, Poll, Signals, Clocks & Random Library (POSIX)
-- @implements FR-POSIX-001
-- @implements FR-POSIX-002
-- @implements FR-POSIX-003
-- @implements FR-POSIX-004
-- @implements API-POSIX-001
-- @implements DM-PosixStatus
-- @mitigates VUL-INJ-002
-- @mitigates VUL-INPUT-001
-- ============================================================

module :: posix

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

-- @implements FR-POSIX-003
-- @implements API-POSIX-001
fn :: o directory for SysArch => Int
      o directory for Arm64   =  16384
      o directory for _       =  65536

-- @implements FR-POSIX-003
-- @implements API-POSIX-001
fn :: o directory => Int
      o directory =  o directory for (sys arch)

-- ── Kernel Error Numbers (FR-POSIX-003) ──────────────────────

-- @implements FR-POSIX-003
-- @implements API-POSIX-001
fn :: errno eio => Int
      errno eio =  5

fn :: errno ebadf => Int
      errno ebadf =  9

fn :: errno ewouldblock => Int
      errno ewouldblock =  11

fn :: errno enotdir => Int
      errno enotdir =  20

fn :: errno einval => Int
      errno einval =  22

fn :: errno enospc => Int
      errno enospc =  28

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

-- ── Byte Buffer Helpers (Tensor[U8], ADR-0010) ──────────────

-- One byte `b` (taken modulo 256) as a 1-byte String.
fn :: px raw byte Int => String
      px raw byte b   =
        t = Tensor[U8 * 1]
        t_(0) = ((b % 256) + 256) % 256
        tensor to str t

-- Writes `val` as 8 little-endian bytes at `off` and returns the same tensor.
fn :: px put u64 le Tensor[U8] Int Int => Tensor[U8]
      px put u64 le t          off val =
        t_(off)     = val and 255
        t_(off + 1) = (val shr 8) and 255
        t_(off + 2) = (val shr 16) and 255
        t_(off + 3) = (val shr 24) and 255
        t_(off + 4) = (val shr 32) and 255
        t_(off + 5) = (val shr 40) and 255
        t_(off + 6) = (val shr 48) and 255
        t_(off + 7) = (val shr 56) and 255
        t

fn :: px u64 le Int => String
      px u64 le val =  tensor to str (px put u64 le (Tensor[U8 * 8]) 0 val)

fn :: px get u32 le Tensor[U8] Int => Int
      px get u32 le t          off =  t_(off) + (t_(off + 1) shl 8) + (t_(off + 2) shl 16) + (t_(off + 3) shl 24)

fn :: px get u64 le Tensor[U8] Int => Int
      px get u64 le t          off =  (px get u32 le t off) + ((px get u32 le t (off + 4)) shl 32)

-- A NUL-terminated copy of `s` for the kernel.
fn :: px cstr String => Tensor[U8]
      px cstr s      =  tensor from str (s + (px raw byte 0))

-- ── Per-Architecture Syscall Numbers (FR-POSIX-003 AC1) ──────
-- x86_64 numbers from arch/x86/entry/syscalls/syscall_64.tbl;
-- arm64 numbers from include/uapi/asm-generic/unistd.h.

-- @implements FR-POSIX-003
-- @implements FR-POSIX-004
fn :: px sys nr SysArch Int Int => Int
      px sys nr Arm64   _   a   =  a
      px sys nr _       x   _   =  x

fn :: px nr Int Int => Int
      px nr x86 arm =  px sys nr (sys arch) x86 arm

-- @implements FR-POSIX-004
-- @implements API-POSIX-001
-- One `nr <name>` per syscall the libs use (ADR-0007). Never pass a literal number to `sys call`.
fn :: nr read => Int
      nr read =  px nr 0 63

fn :: nr lseek => Int
      nr lseek =  px nr 8 62

fn :: nr mmap => Int
      nr mmap =  px nr 9 222

fn :: nr munmap => Int
      nr munmap =  px nr 11 215

fn :: nr rt sigprocmask => Int
      nr rt sigprocmask =  px nr 14 135

fn :: nr pread64 => Int
      nr pread64 =  px nr 17 67

fn :: nr pwrite64 => Int
      nr pwrite64 =  px nr 18 68

fn :: nr socket => Int
      nr socket =  px nr 41 198

fn :: nr connect => Int
      nr connect =  px nr 42 203

fn :: nr accept => Int
      nr accept =  px nr 43 202

fn :: nr sendto => Int
      nr sendto =  px nr 44 206

fn :: nr shutdown => Int
      nr shutdown =  px nr 48 210

fn :: nr bind => Int
      nr bind =  px nr 49 200

fn :: nr listen => Int
      nr listen =  px nr 50 201

fn :: nr getsockname => Int
      nr getsockname =  px nr 51 204

fn :: nr setsockopt => Int
      nr setsockopt =  px nr 54 208

fn :: nr getsockopt => Int
      nr getsockopt =  px nr 55 209

fn :: nr clone => Int
      nr clone =  px nr 56 220

fn :: nr execve => Int
      nr execve =  px nr 59 221

fn :: nr exit => Int
      nr exit =  px nr 60 93

fn :: nr wait4 => Int
      nr wait4 =  px nr 61 260

fn :: nr fcntl => Int
      nr fcntl =  px nr 72 25

fn :: nr flock => Int
      nr flock =  px nr 73 32

fn :: nr fsync => Int
      nr fsync =  px nr 74 82

fn :: nr fdatasync => Int
      nr fdatasync =  px nr 75 83

fn :: nr ftruncate => Int
      nr ftruncate =  px nr 77 46

fn :: nr clock gettime => Int
      nr clock gettime =  px nr 228 113

fn :: nr unlinkat => Int
      nr unlinkat =  px nr 263 35

fn :: nr symlinkat => Int
      nr symlinkat =  px nr 266 36

fn :: nr signalfd4 => Int
      nr signalfd4 =  px nr 289 74

fn :: nr eventfd2 => Int
      nr eventfd2 =  px nr 290 19

fn :: nr dup3 => Int
      nr dup3 =  px nr 292 24

fn :: nr pipe2 => Int
      nr pipe2 =  px nr 293 59

fn :: nr renameat2 => Int
      nr renameat2 =  px nr 316 276

fn :: nr getrandom => Int
      nr getrandom =  px nr 318 278

fn :: nr memfd create => Int
      nr memfd create =  px nr 319 279

-- `AT_FDCWD`: resolve relative paths against the working directory (same on both architectures).
fn :: at fdcwd => Int
      at fdcwd =  0 - 100

-- Kernel buffers are `Tensor[U8]` passed to `sys call` (ADR-0010). The memfd helpers below stay
-- for `posix execve` (pointer tables need a known address) and existing callers; new code must not call them.
fn :: px alloc page Int => Int
      px alloc page sz  =
        neg1 = 0 - 1
        sys call (nr mmap) 0 sz 3 34 neg1 0

fn :: px free page Int Int Int => Int
      px free page mfd ptr sz =
        _ = sys close mfd
        sys call (nr munmap) ptr sz 0 0 0 0

-- `name_ptr` must point at a fresh anonymous mmap page: its first byte is 0, so the
-- memfd name is "". This works in an executable and in a .so at any load address.
fn :: px alloc mfd Int      => Int
      px alloc mfd name_ptr =  sys call (nr memfd create) name_ptr 1 0 0 0 0

fn :: px poke Int Int String => Int
      px poke mfd ptr s      =
        slen = str len s
        _    = sys call (nr lseek) mfd 0 0 0 0 0
        _    = sys write fd mfd s
        sys call (nr pread64) mfd ptr slen 0 0 0

fn :: px peek Int Int Int => String
      px peek mfd ptr len =
        _ = sys call (nr pwrite64) mfd ptr len 0 0 0
        _ = sys call (nr lseek) mfd 0 0 0 0 0
        sys read fd mfd len

-- ── Monotonic Clock (RGF-017 / RG-010) ───────────────────────
-- Thin names over the vDSO built-ins `sys time ms` / `sys time ns` (ADR-0010).
-- The wall clock is the built-in `sys wall time ms`.

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys monotonic ms => Int
      sys monotonic ms =  sys time ms

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys monotonic ns => Int
      sys monotonic ns =  sys time ns

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

-- ── Kernel-Backed Anonymous Pipe, Descriptor Duplication & Process Control ─
-- (`posix pipe`, `posix dup2`, `posix fork`, `posix execve`, `posix waitpid`)

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: wnohang => Int
      wnohang =  1

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: wuntraced => Int
      wuntraced =  2

fn :: pack pipe fds Int Int Int => Int Int Int
      pack pipe fds rc rfd wfd =
        | rc < 0 or rfd < 0 or wfd < 0 = (0 - 1, 0 - 1, 0 - 1)
        | otherwise                    = (0, rfd, wfd)

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: posix pipe flags Int => Int Int Int
      posix pipe flags flags =
        buf = Tensor[U8 * 8]
        rc  = sys call (nr pipe2) buf flags 0 0 0 0
        pack pipe fds rc (px get u32 le buf 0) (px get u32 le buf 4)

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: posix pipe => Int Int Int
      posix pipe =
        rfd, wfd = sys pipe
        pack pipe fds 0 rfd wfd

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: posix pipe cloexec => Int Int Int
      posix pipe cloexec =
        posix pipe flags 526336

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: posix dup2 Int Int => Int
      posix dup2 oldfd newfd =
        | oldfd < 0 or newfd < 0 = 0 - 9
        | oldfd == newfd         = px dup same oldfd (sys call (nr fcntl) oldfd 1 0 0 0 0)
        | otherwise              = sys call (nr dup3) oldfd newfd 0 0 0 0

-- `dup3` rejects equal descriptors; `dup2(fd, fd)` returns `fd` when it is open.
fn :: px dup same Int Int => Int
      px dup same fd  rc  =
        | rc < 0    = rc
        | otherwise = fd

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: posix fork => Int
      posix fork =
        sys call (nr clone) (sig chld) 0 0 0 0 0

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: posix exit Int => Int
      posix exit code =
        sys call (nr exit) (code and 255) 0 0 0 0 0

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
-- @mitigates VUL-INJ-002
-- @mitigates VUL-INPUT-001
fn :: posix execve String [String] [String] => Int
      posix execve path argv envp =
        | (str len path) == 0 or (str len path) > 4096 = 0 - 22
        | otherwise                                    = px execve raw path argv envp

fn :: px count [A]      => Int
      px count []       =  0
      px count (_:rest) =  1 + (px count rest)

-- Bytes of the NUL-terminated strings.
fn :: px cstr size [String] => Int
      px cstr size []       =  0
      px cstr size (x:rest) =  (str len x) + 1 + (px cstr size rest)

fn :: px cstr blob [String] => String
      px cstr blob []       =  ""
      px cstr blob (x:rest) =  x + (px raw byte 0) + (px cstr blob rest)

-- u64 pointers to consecutive strings starting at `addr`, then a NULL pointer.
fn :: px cstr table [String] Int  => String
      px cstr table []       _    =  px u64 le 0
      px cstr table (x:rest) addr =  (px u64 le addr) + (px cstr table rest (addr + (str len x) + 1))

-- execve needs a table of absolute pointers, so the block lives in a page whose
-- address is known, filled through a memfd. The built-in `sys execve` always passes
-- `path` as argv[0], so it cannot keep a caller's argv[0] (ADR-0010).
-- Page layout: argv pointers, NULL, envp pointers, NULL, path, argv strings, envp strings.
fn :: px execve raw String [String] [String] => Int
      px execve raw path   argv     envp     =
        na     = px count argv
        ne     = px count envp
        tbl_sz = 8 * (na + ne + 2)
        total  = tbl_sz + (str len path) + 1 + (px cstr size argv) + (px cstr size envp)
        sz     = ((total + 4095) / 4096) * 4096
        ptr    = px alloc page sz
        mfd    = px alloc mfd ptr
        p_path = ptr + tbl_sz
        p_argv = p_path + (str len path) + 1
        p_envp = p_argv + (px cstr size argv)
        blob   = (px cstr table argv p_argv) + (px cstr table envp p_envp) + path + (px raw byte 0) + (px cstr blob argv) + (px cstr blob envp)
        _      = px poke mfd ptr blob
        rc     = sys call (nr execve) p_path ptr (ptr + (8 * (na + 1))) 0 0 0
        _      = px free page mfd ptr sz
        rc

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
fn :: posix waitpid Int Int => Int Int
      posix waitpid pid options =
        st = Tensor[U8 * 4]
        rc = px wait4 retry pid st options
        px wait4 result rc (px get u32 le st 0)

-- `wait4(pid, &status, options, NULL)`, retried on `EINTR`.
fn :: px wait4 retry Int Tensor[U8] Int     => Int
      px wait4 retry pid st         options =  px wait4 again pid st options (sys call (nr wait4) pid st options 0 0 0)

fn :: px wait4 again Int Tensor[U8] Int     Int => Int
      px wait4 again pid st         options rc  =
        | rc == (0 - 4) = px wait4 retry pid st options
        | otherwise     = rc

-- `(ret_pid, raw wait status)`; the status is `0` when `wait4` failed or `WNOHANG` found nothing.
fn :: px wait4 result Int Int    => Int Int
      px wait4 result rc  status =
        | rc <= 0   = (rc, 0)
        | otherwise = (rc, status)

fn :: waitpid decode sig Int Int => ProcStatus
      waitpid decode sig wstatus sig =
        | sig == 0  = ProcExited ((wstatus shr 8) and 255)
        | otherwise = ProcSignal sig

-- @implements FR-POSIX-001
-- @implements API-POSIX-001
-- @implements DM-PosixStatus
fn :: waitpid decode status Int => ProcStatus
      waitpid decode status wstatus =
        waitpid decode sig wstatus (wstatus and 127)

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

-- `unlinkat(AT_FDCWD, path, flags)`; flags `512` (`AT_REMOVEDIR`) removes a directory.
fn :: px unlinkat path String Int   => Int
      px unlinkat path path   flags =
        sys call (nr unlinkat) (at fdcwd) (px cstr path) flags 0 0 0

-- kind `0`: `renameat2(AT_FDCWD, p1, AT_FDCWD, p2, 0)`; kind `1`: `symlinkat(p1, AT_FDCWD, p2)`.
fn :: px path pair sys Int Tensor[U8] Tensor[U8] => Int
      px path pair sys 0    a          b          =  sys call (nr renameat2) (at fdcwd) a (at fdcwd) b 0
      px path pair sys _    a          b          =  sys call (nr symlinkat) a (at fdcwd) b 0 0 0

fn :: px path pair call Int String String => Int
      px path pair call kind p1 p2 =  px path pair sys kind (px cstr p1) (px cstr p2)

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys rmdir String => Bool
      sys rmdir path   =
        | not (is safe posix path path) = False
        | otherwise                     = (px unlinkat path path 512) == 0

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys unlink String => Bool
      sys unlink path   =
        | not (is safe posix path path) = False
        | otherwise                     = (px unlinkat path path 0) == 0

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys rename String String   => Bool
      sys rename old_p  new_path =
        | not (is safe posix path old_p) or not (is safe posix path new_path) = False
        | otherwise = (px path pair call 0 old_p new_path) == 0

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys symlink String String    => Bool
      sys symlink target link_path =
        | not (is safe posix path target) or not (is safe posix path link_path) = False
        | otherwise = (px path pair call 1 target link_path) == 0

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
          mask = px put u64 le (Tensor[U8 * 8]) 0 (px sig mask sigs)
          neg1 = 0 - 1
          _    = sys call (nr rt sigprocmask) 0 mask 0 8 0 0
          px finish sig watch (sys call (nr signalfd4) neg1 mask 8 526336 0 0)

fn :: px finish sig read Int Tensor[U8] => Int Int
      px finish sig read n   info       =
        | n < 128   = (0 - 7, 0)
        | otherwise = (0, px get u32 le info 0)

fn :: px wait sig after poll Int Int => Int Int
      px wait sig after poll handle prc =
        | prc == 0 = (0 - 2, 0)
        | prc < 0  = (0 - 7, 0)
        | otherwise =
          info = Tensor[U8 * 128]
          px finish sig read (sys read into handle info 0 128) info

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
fn :: sys signal wait Int    Int        => Int Int
      sys signal wait handle timeout_ms =
        | handle < 0 or timeout_ms < (0 - 1)       = (0 - 7, 0)
        | (sys call (nr fcntl) handle 1 0 0 0 0) < 0 = (0 - 7, 0)
        | otherwise                                = px wait sig after poll handle (sys poll handle 1 timeout_ms)

fn :: posix notify signal Int    Int    => Int
      posix notify signal target sig_no =
        posix kill target sig_no

-- ── RGF-014 Cryptographic Random Bytes (getrandom __NR_getrandom = 318) ──

fn :: px no bytes => Tensor[U8]
      px no bytes =  Tensor[U8 * 0]

-- `getrandom` into a fresh `n`-byte tensor, retried on `EINTR`. A short read (only possible
-- above 256 bytes when a signal arrives) keeps the bytes received and asks for the rest.
fn :: px getrandom tensor Int => Int Tensor[U8]
      px getrandom tensor n   =
        t = Tensor[U8 * n]
        px getrandom got n t (sys call (nr getrandom) t n 0 0 0 0)

fn :: px getrandom got Int Tensor[U8] Int => Int Tensor[U8]
      px getrandom got n   t          rc  =
        | rc == (0 - 4) = px getrandom tensor n
        | rc < 0        = (0 - 99, px no bytes)
        | rc >= n       = (0, t)
        | otherwise     = px getrandom join (str slice (tensor to str t) 0 rc) (px getrandom tensor (n - rc))

fn :: px getrandom join String (Int Tensor[U8]) => Int Tensor[U8]
      px getrandom join head   (rc, rest)       =
        | rc != 0   = (rc, px no bytes)
        | otherwise = (0, tensor from str (head + (tensor to str rest)))

fn :: px random as str (Int Tensor[U8]) => Int String
      px random as str (rc, t)          =
        | rc != 0   = (rc, "")
        | otherwise = (0, tensor to str t)

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
-- @mitigates VUL-INPUT-001
fn :: sys random bytes Int => Int String
      sys random bytes n   =
        | n < 0     = (0 - 7, "")
        | n == 0    = (0, "")
        | n > 65536 = (0 - 7, "")
        | otherwise = px random as str (px getrandom tensor n)

-- @implements FR-POSIX-002
-- @implements API-POSIX-001
-- @mitigates VUL-INPUT-001
fn :: sys random tensor Int => Int Tensor[U8]
      sys random tensor n   =
        | n < 0     = (0 - 7, px no bytes)
        | n == 0    = (0, px no bytes)
        | n > 65536 = (0 - 7, px no bytes)
        | otherwise = px getrandom tensor n

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

-- ── Durable File Sync, Truncate, Lock & Positional Read (FR-POSIX-003) ─
-- Every syscall number comes from the `nr ...` table, picked per `sys arch`.

-- @implements FR-POSIX-003
-- @implements API-POSIX-001
fn :: posix fdatasync Int => Int
      posix fdatasync fd  =
        | fd < 0    = 0 - errno ebadf
        | otherwise = sys call (nr fdatasync) fd 0 0 0 0 0

-- @implements FR-POSIX-003
-- @implements API-POSIX-001
fn :: posix fsync Int => Int
      posix fsync fd  =
        | fd < 0    = 0 - errno ebadf
        | otherwise = sys call (nr fsync) fd 0 0 0 0 0

-- @implements FR-POSIX-003
-- @implements API-POSIX-001
-- @mitigates VUL-INPUT-001
fn :: posix ftruncate Int Int    => Int
      posix ftruncate fd  length =
        | fd < 0     = 0 - errno ebadf
        | length < 0 = 0 - errno einval
        | otherwise  = sys call (nr ftruncate) fd length 0 0 0 0

fn :: px close keep rc Int Int => Int
      px close keep rc fd  rc  =
        _ = sys close fd
        rc

fn :: px fsync opened dir Int => Int
      px fsync opened dir fd  =
        | fd < 0    = fd
        | otherwise = px close keep rc fd (sys call (nr fsync) fd 0 0 0 0 0)

-- @implements FR-POSIX-003
-- @implements API-POSIX-001
-- @mitigates VUL-INPUT-001
fn :: posix sync dir String => Int
      posix sync dir path   =
        | not (is safe posix path path) = 0 - errno einval
        | otherwise                     = px fsync opened dir (sys open path ((o rdonly) + (o directory) + (o cloexec)) 0)

-- @implements FR-POSIX-003
-- @implements API-POSIX-001
fn :: posix lock exclusive Int => Int
      posix lock exclusive fd  =
        | fd < 0    = 0 - errno ebadf
        | otherwise = sys call (nr flock) fd 6 0 0 0 0

-- @implements FR-POSIX-003
-- @implements API-POSIX-001
fn :: posix unlock Int => Int
      posix unlock fd  =
        | fd < 0    = 0 - errno ebadf
        | otherwise = sys call (nr flock) fd 8 0 0 0 0

-- @implements FR-POSIX-003
fn :: posix pread max => Int
      posix pread max =  16777216

fn :: px pread result Int Tensor[U8] Int => Int String
      px pread result n   buf        len =
        | n <= 0    = (n, "")
        | n >= len  = (n, tensor to str buf)
        | otherwise = (n, str slice (tensor to str buf) 0 n)

fn :: px pread into Int Int    Int => Int String
      px pread into fd  offset len =
        buf = Tensor[U8 * len]
        px pread result (sys call (nr pread64) fd buf len offset 0 0) buf len

-- @implements FR-POSIX-003
-- @implements API-POSIX-001
-- @mitigates VUL-INPUT-001
fn :: posix pread Int Int    Int => Int String
      posix pread fd  offset len =
        | fd < 0                                         = (0 - errno ebadf, "")
        | offset < 0 or len < 0 or len > posix pread max = (0 - errno einval, "")
        | len == 0                                       = (0, "")
        | otherwise                                      = px pread into fd offset len
