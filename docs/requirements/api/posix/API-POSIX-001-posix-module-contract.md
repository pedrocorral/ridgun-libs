---
id: API-POSIX-001
title: Public lib contract for posix (posix.rglib / libposix.so)
status: approved
implements: [FR-POSIX-001, FR-POSIX-002]
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
- Descriptor, Poll, Pipe & Signal Functions:
  - `wait fd Int Int Int => PollStatus` (`wait fd fd events timeout_ms`)
  - `posix open String Int Int => Int`, `posix close Int => Int`, `posix read Int Int => String`, `posix write Int String => Int`
  - `posix pipe () => (Int, Int, Int)` (`(status, read_fd, write_fd)`)
  - `posix kill Int Int => Int`
- Filesystem, Process, Clock, Signal Watch & CSPRNG Functions (`RG-010`, `RGF-014`, `RGF-017`, `RGF-018`):
  - `sys_mkdir String => Int`, `sys_rmdir String => Int`, `sys_rename String String => Int`, `sys_symlink String String => Int`, `sys_readlink String => String`, `sys_unlink String => Int`, `sys_chmod String Int => Int`, `sys_chdir String => Int`, `sys_getcwd () => String`, `sys_getenv String => String`, `sys_getpid () => Int`
  - `sys_time_ms () => Int`, `sys_monotonic_ms () => Int`, `sys_monotonic_ns () => Int`, `sys_sleep_ms Int => Int`
  - `sys_signal_watch [Int] => (Int, Int)`, `sys_signal_wait Int Int => (Int, Int)`
  - `sys_random_bytes Int => (Int, String)`

## Responses
| Code | When | Body |
|---|---|---|
| `0` / `PollReady revents` | Operation succeeded or descriptor ready | `0` / `(0, ...)` / `PollReady revents` |
| `PollTimeout` / `-2` | Poll or signal wait timed out | `PollTimeout` / `(-2, 0)` |
| `PollError errno_code` / `< 0` | Invalid descriptor, signal, or syscall error | `PollError errno_code` / `(-7, ...)` |

## Rules
- `wait fd` delegates directly to the compiler's `sys poll` (`ppoll`) primitive.
- `sys_random_bytes` reads cryptographic entropy from the Linux kernel (`getrandom` syscall / `/dev/urandom`).
