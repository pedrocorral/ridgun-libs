---
id: FR-POSIX-004
title: Route every lib kernel call through the posix per-architecture bridge
type: functional
status: implemented
priority: must
domain: POSIX
depends_on: [FR-POSIX-001, FR-POSIX-003]
related: [ADR-0007, ADR-0010]
tests: [TS-POSIX-004]
---
# FR-POSIX-004 — Route every lib kernel call through the posix per-architecture bridge

## Statement
The `posix` lib SHALL provide a function `nr <name> => Int` for every syscall the libs use. Each function returns that syscall's number for the target architecture, chosen with `sys arch` (`X86_64` or `Arm64`).
Lib code under `src/main/ridgun/lib/` SHALL NOT pass a literal number as the first argument of `sys call`.
Where arm64 has no equivalent of an x86_64 syscall, both architectures SHALL use a syscall that exists on both with the same argument layout: `clone` with `SIGCHLD` for `fork`, `dup3` for `dup2`, `unlinkat` for `unlink` and `rmdir`, `renameat2` for `rename`, `symlinkat` for `symlink`.
Libs that need a memory buffer for a syscall SHALL pass a `Tensor[U8]` to `sys call` (or use `sys read into` / `sys write from`), and SHALL decode integers from it by indexing (`ADR-0010`). The `posix` memfd helpers (`px alloc page`, `px alloc mfd`, `px poke`, `px peek`, `px free page`) are deprecated and SHALL NOT be used by new code.
`posix execve` SHALL call `execve` with `argv` exactly as given, and `posix waitpid` SHALL call `wait4` and return the raw wait status, so that `waitpid decode status` decodes it.

## Rationale
Ridgun builds for x86_64 and arm64. Literal x86_64 numbers call the wrong syscall on arm64 (`ADR-0007`).

## Acceptance criteria
- AC1: Given the lib sources, when they are scanned for `sys call` followed by a digit, then there are no matches.
- AC2: Given every `nr <name>` function, then its x86_64 value equals `__NR_<name>` in the x86_64 UAPI header and its arm64 value equals `__NR_<name>` in `asm-generic/unistd.h`.
- AC3: Given an x86_64 host, when the `posix`, `socket`, `io`, `uuid`, `time`, `crypto`, `tls` and `mail` suites run, then they pass.
- AC4: Given `ridgunc build --target arm64`, when each changed lib and the `posix` and `socket` test programs are built, then the build succeeds.
- AC5: Given `posix execve "/bin/echo" ["/bin/echo", "-n", "a b"] []` in a forked child, then the parent reads exactly `a b` (`argv[0]` is not repeated); given a child that exits with code `11`, then `waitpid decode status` of the `posix waitpid` status is `ProcExited 11`; given a child killed by `SIGKILL`, then it is `ProcSignal 9`.
- AC6: Given `posix dup2 fd fd` on an open descriptor, then it returns `fd`; on a closed descriptor it returns `0 - errno ebadf`.

## Actors & permissions
- Lib maintainers; any program importing `posix`, `socket`, `uuid` or `argon2id`.

## Constraints & edge cases
- `AT_FDCWD` is `-100` on both architectures.
- `dup3` rejects equal descriptors with `EINVAL`, so `posix dup2 fd fd` checks `fd` with `fcntl(F_GETFD)` instead.
- Flag values passed with the calls (`O_CLOEXEC`, `O_NONBLOCK`, `MSG_*`, `SOL_SOCKET`, `SO_*`, `AT_REMOVEDIR`, `mmap` and `memfd` flags) are the same on both architectures. `O_DIRECTORY` is not, and stays in `o directory`.
- `posix execve` uses the built-in `sys execve`, which builds the pointer tables itself.
- On x86-64, `socket` TCP functions and `posix` `sys unlink`, `sys rmdir` and `sys rename` use the runtime's `net …` and file operations instead of the bridge (`ADR-0013`).

## Data & privacy
- None.

## Security & observability notes
- Removing the `0x400007` name pointer from the copied helpers removes the last fixed-address dependency (`FR-POSIX-003`).

## Out of scope
- Running the suites on an arm64 host (no host or emulator is available).
- Compiler built-ins (`sys open`, `sys poll`, `sys read fd`, ...): the compiler lowers them per architecture.
- Test programs may still use `sys call (nr ...)` directly.
