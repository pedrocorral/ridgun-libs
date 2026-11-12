---
id: ADR-0007
title: Libs reach the kernel only through the posix per-architecture bridge
status: accepted
date: 2026-11-07
supersedes: []
affects: [FR-POSIX-001, FR-POSIX-002, FR-POSIX-004, API-POSIX-001, TS-POSIX-004, src/main/ridgun/lib/posix.ridgun, src/main/ridgun/lib/socket.ridgun, src/main/ridgun/lib/uuid.ridgun, src/main/ridgun/lib/argon2id.ridgun]
---
# ADR-0007 — Libs reach the kernel only through the posix per-architecture bridge

## Context
Ridgun builds for x86_64 and arm64 (`sys arch => SysArch`).
`posix`, `socket`, `uuid` and `argon2id` called `sys call` with about 60 literal x86_64 syscall numbers.
On arm64 those numbers name other syscalls, and some x86_64 syscalls (`fork`, `dup2`, `unlink`, `rmdir`, `rename`, `symlink`) do not exist there.
`socket`, `uuid` and `argon2id` also kept their own copies of the `mmap` + `memfd_create` buffer helpers, with a `memfd_create` name pointer fixed at `0x400007`.
`FR-POSIX-001` said the process functions are "raw Linux x86_64" calls.
`TASK-0045` (`FR-POSIX-003`) added a per-architecture number table to `posix`. The user chose to extend it to every lib on 2026-11-07.

## Options considered
1. Keep x86_64 numbers and document arm64 as unsupported.
2. One bridge in `posix`: `nr ...` functions pick the syscall number from `sys arch`; other libs import `posix` and use them.
3. A new leaf lib (`kernel`) that `posix`, `socket`, `uuid` and `argon2id` all import.

## Decision
Option 2, chosen by the user on 2026-11-07.
- Lib code never passes a literal syscall number to `sys call`. It calls `sys call (nr <name>) ...`.
- `nr <name>` returns the number for `sys arch`, from the kernel UAPI tables (`arch/x86/entry/syscalls/syscall_64.tbl` for x86_64, `include/uapi/asm-generic/unistd.h` for arm64).
- Where arm64 lacks an x86_64 syscall, both architectures use the call that exists on both with the same argument layout: `clone(SIGCHLD)` for `fork`, `dup3` for `dup2`, `unlinkat` for `unlink`/`rmdir`, `renameat2` for `rename`, `symlinkat` for `symlink`.
- Syscalls that need a memory buffer use only the `posix` helpers `px alloc page`, `px alloc mfd`, `px poke`, `px peek` and `px free page`.
- `posix execve` and `posix waitpid` call `execve` and `wait4` through the bridge, as `FR-POSIX-001` AC3 states, instead of the compiler built-ins `sys execve` and `sys waitpid`, whose argv and status handling changed in ridgunc 0.9.33.
Option 3 was not chosen: `posix` already imports nothing, so it is a leaf, and a new lib would add a build entry and a contract for no gain.

## Consequences
- Requirements to update: `FR-POSIX-001` (drop "x86_64"), `API-POSIX-001` (syscall numbers per architecture); new `FR-POSIX-004`.
- Tests to update: new `TS-POSIX-004`; `test posix.ridgun` and `test socket.ridgun` lose their literal `sys call` numbers.
- Code to update: `posix.ridgun`, `socket.ridgun`, `uuid.ridgun`, `argon2id.ridgun` (`socket`, `uuid` and `argon2id` now import `posix`).
- arm64 is checked against the kernel headers and by cross-building, not by running, until an arm64 host is available.
