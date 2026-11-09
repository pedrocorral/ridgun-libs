---
id: API-POSIX-001
title: Public lib contract for posix (posix.rglib / libposix.so)
status: approved
implements: [FR-POSIX-001, FR-POSIX-002, FR-POSIX-003, FR-POSIX-004]
auth: none
---
# API-POSIX-001 — Public lib contract for `posix` (`posix.rg`)

## Request
- Imported via `import posix`.
- Inputs (see `DM-PosixStatus`): `fd` (`Int`), `events` (`Int`), `timeout_ms` (`Int`), `sig_num` (`Int`), `pid` (`Int`), `path` (`String`).
- Exported ADTs & Constants (`ridgun_posix_io_library_spec.md` §4):
  - `type PollStatus = PollReady Int | PollTimeout | PollError Int`
  - `type ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int`
  - `poll in => Int` (`1`), `poll out => Int` (`4`), `poll err => Int` (`8`)
  - `sig hup => Int` (`1`), `sig int => Int` (`2`), `sig kill => Int` (`9`), `sig usr1 => Int` (`10`), `sig usr2 => Int` (`12`), `sig pipe => Int` (`13`), `sig term => Int` (`15`), `sig chld => Int` (`17`)
  - `o rdonly => Int` (`0`), `o wronly => Int` (`1`), `o rdwr => Int` (`2`), `o creat => Int` (`64`), `o trunc => Int` (`512`), `o append => Int` (`1024`), `o nonblock => Int` (`2048`), `o cloexec => Int` (`524288`)
- Descriptor, Poll, Pipe, Process & Signal Functions:
  - `wait fd Int Int Int => PollStatus` (`wait fd fd events timeout_ms`)
  - `posix open String Int Int => Int`, `posix close Int => Int`, `posix read Int Int => String`, `posix write Int String => Int`
  - `posix pipe => Int Int Int` (`(status, read_fd, write_fd)`), `posix pipe cloexec => Int Int Int`, `posix pipe flags Int => Int Int Int`
  - `posix dup2 Int Int => Int` (`dup3`; `dup2 fd fd` returns `fd` when open)
  - `posix fork => Int` (`clone` with `SIGCHLD`), `posix execve String [String] [String] => Int` (`execve`, argv unchanged), `posix waitpid Int Int => Int Int` (`wait4`; `(ret_pid, raw wait status)`), `waitpid decode status Int => ProcStatus`, `posix exit Int => Int` (`exit`), `wnohang => Int` (`1`), `wuntraced => Int` (`2`)
  - `posix kill Int Int => Int`
- Filesystem, Process, Clock, Signal Watch & CSPRNG Functions (`RG-010`, `RGF-014`, `RGF-017`, `RGF-018`):
  - `sys_mkdir String => Int`, `sys_rmdir String => Int`, `sys_rename String String => Int`, `sys_symlink String String => Int`, `sys_readlink String => String`, `sys_unlink String => Int`, `sys_chmod String Int => Int`, `sys_chdir String => Int`, `sys_getcwd () => String`, `sys_getenv String => String`, `sys_getpid () => Int`
  - `sys monotonic ms => Int` and `sys monotonic ns => Int` return the built-ins `sys time ms` / `sys time ns` (vDSO). The wall clock is the built-in `sys wall time ms => Int`; `posix` does not define it (`ADR-0010`). `sys sleep ms Int => ()` is a built-in.
  - `sys_signal_watch [Int] => (Int, Int)` (a list of signal numbers), `sys_signal_wait Int Int => (Int, Int)`
  - `sys random bytes Int => Int String` (`(status, bytes)`)
  - `sys random tensor Int => Int Tensor[U8]` (`(status, bytes)`; replaces `sys random bytes list Int => Int [Int]`, `ADR-0010`)
- Durable File Functions (`FR-POSIX-003`; syscall numbers picked per `sys arch`):
  - `posix fdatasync Int => Int`, `posix fsync Int => Int`, `posix ftruncate Int Int => Int` (`fd length`)
  - `posix sync dir String => Int` (`open O_RDONLY|O_DIRECTORY|O_CLOEXEC`, `fsync`, `close`)
  - `posix lock exclusive Int => Int` (`flock LOCK_EX|LOCK_NB`), `posix unlock Int => Int` (`flock LOCK_UN`)
  - `posix pread Int Int Int => Int String` (`fd offset len` → `(bytes_read, data)` or `(-errno, "")`; `len <= 16777216`)
  - `o directory => Int` (`65536` on x86_64, `16384` on arm64)
- Kernel Bridge (`FR-POSIX-004`, `ADR-0007`): `nr <name> => Int` returns the syscall number for `sys arch` for `read`, `lseek`, `mmap`, `munmap`, `rt sigprocmask`, `pread64`, `pwrite64`, `socket`, `connect`, `accept`, `sendto`, `shutdown`, `bind`, `listen`, `getsockname`, `setsockopt`, `getsockopt`, `clone`, `execve`, `exit`, `wait4`, `fcntl`, `flock`, `fsync`, `fdatasync`, `ftruncate`, `clock gettime`, `unlinkat`, `symlinkat`, `signalfd4`, `eventfd2`, `dup3`, `pipe2`, `renameat2`, `getrandom`, `memfd create`; `at fdcwd => Int` (`-100`).
  - Kernel buffers are `Tensor[U8]` values passed straight to `sys call` (`ADR-0010`). Byte helpers for other libs: `px raw byte Int => String`, `px u64 le Int => String`, `px put u64 le Tensor[U8] Int Int => Tensor[U8]`, `px get u32 le Tensor[U8] Int => Int`, `px get u64 le Tensor[U8] Int => Int`, `px cstr String => Tensor[U8]` (NUL-terminated copy), `px tensor addr Tensor[U8] => Int` (address of byte 0, for kernel structures that hold pointers).
  - The memfd helpers `px alloc page`, `px alloc mfd`, `px poke`, `px peek` and `px free page` are deprecated. Only `posix execve` uses them (a pointer table needs a known address); they are removed once the compiler offers an execve that keeps the caller's argv[0] (`ADR-0010`).
  - `errno eio => Int` (`5`), `errno ebadf => Int` (`9`), `errno ewouldblock => Int` (`11`), `errno enotdir => Int` (`20`), `errno einval => Int` (`22`), `errno enospc => Int` (`28`)

## Responses
| Code | When | Body |
|---|---|---|
| `0` / `PollReady revents` | Operation succeeded or descriptor ready | `0` / `(0, ...)` / `PollReady revents` |
| `PollTimeout` / `-2` | Poll or signal wait timed out | `PollTimeout` / `(-2, 0)` |
| `PollError errno_code` / `< 0` | Invalid descriptor, signal, or syscall error | `PollError errno_code` / `(-7, ...)` |
| `-errno` | Durable file function failed (`FR-POSIX-003`) | `0 - errno ebadf`, `0 - errno ewouldblock`, ... / `(-errno, "")` |

## Rules
- `wait fd` delegates directly to the compiler's `sys poll` (`ppoll`) primitive.
- `sys random bytes` and `sys random tensor` read cryptographic entropy with the `getrandom` syscall into a `Tensor[U8]`, retried on `EINTR`.
- `posix pread` reads into a `Tensor[U8 * len]` with `pread64`; `posix execve` builds argv/envp in one `Tensor[U8]` and takes its address with `px tensor addr`.
- `FR-POSIX-003` functions return the raw negative kernel error number; callers compare it with `0 - errno <name>`.
- Lib code never passes a literal syscall number to `sys call`; it uses `nr <name>` (`ADR-0007`).
