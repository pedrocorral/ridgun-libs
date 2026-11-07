---
id: FR-POSIX-001
title: Provide typed POSIX descriptor wrappers, PollStatus, ProcStatus, open flags, signals, and poll timeout waiting
type: functional
status: implemented
priority: must
domain: POSIX
depends_on: []
related: [ADR-0007, ADR-0002, VUL-INPUT-001]
tests: [TS-POSIX-001]
---
# FR-POSIX-001 — Provide typed POSIX descriptor wrappers, PollStatus, ProcStatus, open flags, signals, and poll timeout waiting

## Statement
The `posix` library SHALL export the `PollStatus` (`PollReady Int | PollTimeout | PollError Int`) and `ProcStatus` (`ProcExited Int | ProcTimedOut Int | ProcSignal Int`) ADTs, standard POSIX `poll` event constants (`poll in`, `poll out`, `poll err`), signal constants (`sig int`, `sig kill`, `sig term`, `sig hup`, `sig pipe`, `sig chld`, `sig usr1`, `sig usr2`), `open` flag constants (`o rdonly`, `o wronly`, `o rdwr`, `o creat`, `o trunc`, `o append`, `o nonblock`, `o cloexec`), `waitpid` option constants (`wnohang`, `wuntraced`), `wait fd` timeout polling over `sys poll`, typed descriptor/pipe/signal operations (`posix open`, `posix close`, `posix read`, `posix write`, `posix pipe`, `posix pipe cloexec`, `posix dup2`, `posix kill`), and raw Linux kernel process control operations for x86_64 and arm64 (through the `FR-POSIX-004` bridge, `ADR-0007`) (`posix fork`, `posix execve`, `posix waitpid`, `waitpid decode status`, `posix exit`).

## Rationale
As specified in `ridgun_posix_io_library_spec.md` (§4), systems tools (`sh`, `doas`, `timeout`, `find -exec`, `make`) and `io.rglib` need a clean, pure-Ridgun POSIX abstraction layer over `ridgunc` Layer 1 kernel primitives (`sys open`, `sys close`, `sys read fd`, `sys write fd`, `sys poll`, `sys kill`, `sys call` with `clone`, `execve`, `wait4`, `pipe2`, `dup3` and `exit`, numbered per architecture by `FR-POSIX-004`) for shell-injection-free process execution and descriptor pipelines (`pipe + fork + dup2 + execve + waitpid`).

## Acceptance criteria
- AC1: Given `posix` constants and types, when `poll in`, `poll out`, `poll err`, `sig term`, `sig kill`, `sig int`, `o rdonly`, `o wronly`, `o rdwr`, `o creat`, `o trunc`, `o append`, `o nonblock`, `o cloexec`, `wnohang`, and `wuntraced` are queried, then they return their canonical Linux x86_64/ARM64 POSIX integer values (`POLLIN = 1`, `POLLOUT = 4`, `POLLERR = 8`, `SIGTERM = 15`, `SIGKILL = 9`, `SIGINT = 2`, `WNOHANG = 1`, `WUNTRACED = 2`, etc.).
- AC2: Given an open descriptor `fd`, an `events` bitmask, and `timeout_ms`, when `wait fd fd events timeout_ms` is called, then it invokes `sys poll fd events timeout_ms` and returns `PollTimeout` when `rc == 0`, `PollError (0 - rc)` when `rc < 0`, and `PollReady rc` when `rc > 0`.
- AC3: Given file paths, pipes, or process IDs, when `posix open`, `posix write`, `posix read`, `posix close`, `posix pipe`, `posix pipe cloexec`, `posix dup2`, `posix fork`, `posix execve`, `posix waitpid`, `waitpid decode status`, or `posix kill` is called, then descriptors and child processes are managed deterministically without shell injection, `posix pipe` creates an inheritable kernel pipe pair `(status, read_fd, write_fd)`, `posix dup2` duplicates descriptors across `fork`/`execve`, `posix execve` passes `argv` and `envp` unchanged to the `execve` syscall, and `posix waitpid` reaps the raw child status with the `wait4` syscall (numbers per architecture: `FR-POSIX-004`).

## Actors & permissions
- Any Ridgun program or lib importing `posix` (including `io`).

## Constraints & edge cases
- `wait fd` with an invalid descriptor (`fd < 0`) returns `PollError 9` (`EBADF`).

## Data & privacy
- Operating system descriptors only; no persistent user data.

## Security & observability notes
- Mitigates `VUL-INPUT-001` by validating descriptor numbers and read bounds before invoking kernel primitives.

## Out of scope
- High-level buffered line streams or `IoError` formatting (owned by `IO` / `io.rg`).
