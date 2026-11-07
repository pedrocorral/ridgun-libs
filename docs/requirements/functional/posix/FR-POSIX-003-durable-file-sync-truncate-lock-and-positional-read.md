---
id: FR-POSIX-003
title: Provide durable file sync, truncate, directory sync, exclusive lock and positional read
type: functional
status: implemented
priority: must
domain: POSIX
depends_on: [FR-POSIX-001]
related: [VUL-INPUT-001]
tests: [TS-POSIX-003]
---
# FR-POSIX-003 — Provide durable file sync, truncate, directory sync, exclusive lock and positional read

## Statement
The `posix` lib SHALL provide `posix fdatasync`, `posix fsync`, `posix ftruncate`, `posix sync dir`, `posix lock exclusive`, `posix unlock` and `posix pread`.
Each function SHALL select the Linux syscall number for the target architecture (`x86_64` or `arm64`) from `sys arch`, so callers never pass syscall numbers.
Each function SHALL return `0` (or a byte count for `posix pread`) on success and the negative kernel error number on failure.
The lib SHALL export the error numbers callers need to tell failures apart: `errno eio` (`5`), `errno ebadf` (`9`), `errno ewouldblock` (`11`), `errno enotdir` (`20`), `errno einval` (`22`) and `errno enospc` (`28`).

| Function | Kernel call |
|---|---|
| `posix fdatasync Int => Int` | `fdatasync(fd)` |
| `posix fsync Int => Int` | `fsync(fd)` |
| `posix ftruncate Int Int => Int` | `ftruncate(fd, length)` |
| `posix sync dir String => Int` | `open(path, O_RDONLY\|O_DIRECTORY\|O_CLOEXEC)`, `fsync`, `close` |
| `posix lock exclusive Int => Int` | `flock(fd, LOCK_EX\|LOCK_NB)` |
| `posix unlock Int => Int` | `flock(fd, LOCK_UN)` |
| `posix pread Int Int Int => Int String` | `pread64(fd, buf, len, offset)`; returns `(bytes_read, data)` or `(-errno, "")` |

## Rationale
Eterval and Griphgun (`ecosystem/apps/db/`) promise that a confirmed write survives a crash.
They must force data to disk, cut a damaged log tail, make a `rename` or a new file durable, keep one process per data directory, and read blocks of a large file without moving the file position.
Today this needs `sys call` with x86_64-only syscall numbers.

## Acceptance criteria
- AC1: Given a program built for `x86_64` or `arm64`, when it calls any function in the statement, then the function issues the syscall number of that architecture, and the caller passes no syscall number.
- AC2: Given a file that was just written, when `posix fdatasync` and `posix fsync` are called on its descriptor, then both return `0`; given a closed descriptor, then both return `0 - errno ebadf`.
- AC3: Given a file of 100 bytes, when `posix ftruncate fd 40` is called, then it returns `0` and `file size` of the path returns `40`; given a negative length, then it returns `0 - errno einval`.
- AC4: Given an existing directory, when `posix sync dir` is called on it, then it returns `0`; given a regular file, then it returns `0 - errno enotdir`; given a missing path, then it returns a negative error.
- AC5: Given two processes that open the same file separately, when the first calls `posix lock exclusive` and then the second does, then the first gets `0` and the second gets `0 - errno ewouldblock` without waiting; after the first calls `posix unlock`, a new `posix lock exclusive` from another descriptor returns `0`.
- AC6: Given a file with known content and a descriptor positioned at offset `p`, when `posix pread fd offset len` is called, then it returns `(n, bytes)` where `bytes` equals the file bytes `[offset, offset + n)`, `n = min(len, size - offset)`, and the descriptor position is still `p` afterwards.

## Actors & permissions
- Any Ridgun program or lib importing `posix`.

## Constraints & edge cases
- A negative descriptor returns `0 - errno ebadf` without a syscall.
- `posix ftruncate` with a negative length returns `0 - errno einval` without a syscall.
- `posix sync dir` rejects an unsafe path (`is safe posix path` is false) with `0 - errno einval`.
- `posix pread` with a negative offset, a negative length, or a length above `16777216` (16 MiB) returns `(0 - errno einval, "")` without a syscall; a length of `0` returns `(0, "")`; an offset at or past the end of file returns `(0, "")`.
- `posix lock exclusive` never blocks: a held lock returns `0 - errno ewouldblock` at once.
- The lock is advisory (`flock`); the kernel releases it when every descriptor of that open file is closed, including at process exit.

## Data & privacy
- No data is logged.

## Security & observability notes
- Mitigates `VUL-INPUT-001`: lengths and offsets are bounded and paths are checked before any syscall.

## Out of scope
- Blocking locks, shared locks and byte-range (`fcntl`) locks.
- `pwrite`, `fallocate` and `sync_file_range`.
- Making the other raw `sys call` sites in `posix`, `socket`, `uuid` and `argon2id` arch-aware.
