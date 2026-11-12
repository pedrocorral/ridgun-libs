---
id: TS-POSIX-004
title: Verify every lib kernel call goes through the posix per-architecture bridge
level: unit
covers: [FR-POSIX-004]
status: automated
automated_in: [src/test/ridgun/test posix.ridgun]
---
# TS-POSIX-004 — Verify every lib kernel call goes through the posix per-architecture bridge

## Preconditions / fixtures
- The repository root as working directory (the test reads `src/main/ridgun/lib/*.ridgun`).

## Steps / inputs
1. Read `posix.ridgun`, `socket.ridgun`, `uuid.ridgun`, `argon2id.ridgun`, `io.ridgun`, `crypto.ridgun`, `tls.ridgun` and `mail.ridgun`; search each for `sys call ` followed by a digit.
2. Fork a child that runs `posix execve "/bin/echo" ["/bin/echo", "-n", "hello; $WORLD `safe`"] ["WORLD=injected"]` with stdout on a pipe; read the pipe in the parent (the `test posix fork pipe dup2 execve waitpid` check).
3. Fork a child that calls `posix exit 11`; decode the `posix waitpid` status. Fork a child that sleeps; `posix kill` it with `sig kill`; decode the status.
4. `posix dup2 fd fd` on an open pipe descriptor and on `99999`.
5. Outside the suite: compare each `nr <name>` x86_64/arm64 pair in `posix.ridgun` with `/usr/include/x86_64-linux-gnu/asm/unistd_64.h` and `/usr/include/asm-generic/unistd.h`; build each changed lib and test program with `ridgunc build --target arm64`; run the suites listed in AC3.

## Expected results (map to acceptance criteria)
- AC1 → Step 1: no file has a literal syscall number.
- AC2 → Step 5: every pair matches the headers.
- AC3 → Step 5: every suite passes on x86_64.
- AC4 → Step 5: every arm64 build succeeds.
- AC5 → Steps 2–3: output ``hello; $WORLD `safe` `` exactly; `ProcExited 11`; `ProcSignal 9`.
- AC6 → Step 4: `fd`; `0 - errno ebadf`.

## Not covered here (to avoid duplication)
- Running on arm64 (no host available).
- The behaviour of each wrapped call: see `TS-POSIX-001`, `TS-POSIX-002`, `TS-POSIX-003`, `TS-SOCK-*`, `TS-UUID-*`, `TS-CRYPTO-*`.
