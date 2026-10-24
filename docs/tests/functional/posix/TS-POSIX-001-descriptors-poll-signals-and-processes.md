---
id: TS-POSIX-001
title: Verify POSIX descriptor wrappers, PollStatus, ProcStatus, open flags, signals, and wait fd timeout polling
level: unit
covers: [FR-POSIX-001, API-POSIX-001]
status: automated
automated_in: [src/test/ridgun/test posix.rg]
---
# TS-POSIX-001 — Verify POSIX descriptor wrappers, PollStatus, ProcStatus, open flags, signals, and wait fd timeout polling

## Preconditions / fixtures
- Pure-Ridgun `posix` module (`src/main/ridgun/lib/posix.rg`).

## Steps / inputs
1. Query `poll in`, `poll out`, `poll err`, `sig term`, `sig kill`, `sig int`, `o rdonly`, `o wronly`, `o rdwr`, `o creat`, `o trunc`, `o append`, `o nonblock`, and `o cloexec` and verify their POSIX constants.
2. Create an OS pipe via `posix pipe`, call `wait fd rfd (poll in) 20` on the empty read end and verify `PollTimeout`, then write `"hello"` to `wfd` via `posix write`, call `wait fd rfd (poll in) 100` and verify `PollReady`, read back `"hello"` via `posix read`, and close both descriptors via `posix close`.
3. Open a temporary file `/tmp/rg_posix_fd_test.txt` with `posix open` (`o wronly + o creat + o trunc`, mode `420`), write data, close, reopen with `o rdonly`, read data, close, and verify `wait fd -1 (poll in) 10` returns `PollError`.
4. Create a pipe via `posix pipe`, fork a child via `posix fork`, duplicate `wfd` onto stdout (`fd 1`) via `posix dup2`, execute `/bin/echo` with literal shell metacharacters `["/bin/echo", "-n", "hello; $WORLD `safe`"]` via `posix execve`, reap the child in the parent via `posix waitpid` and `waitpid decode status`, and verify the exact unexpanded bytes are read from `rfd`.

## Expected results (map to acceptance criteria)
- AC1 → All POSIX `poll`, signal, `open` flag, and `waitpid` option constants match Linux x86_64/ARM64 values.
- AC2 → `wait fd` returns `PollTimeout` when no event arrives within `timeout_ms`, `PollReady` when readable/writable, and `PollError` on invalid descriptors.
- AC3 → `posix open`, `posix write`, `posix read`, `posix close`, `posix pipe`, `posix dup2`, `posix fork`, `posix execve`, `posix waitpid`, `waitpid decode status`, and `posix kill` operate cleanly on kernel descriptors and processes without shell injection.

## Not covered here (to avoid duplication)
- see `TS-POSIX-002` for `RG-010` filesystem helpers, monotonic clocks (`RGF-017`), signal watches (`RGF-018`), and CSPRNG (`RGF-014`).
