---
id: TS-POSIX-003
title: Verify durable file sync, truncate, directory sync, exclusive lock and positional read
level: unit
covers: [FR-POSIX-003]
status: automated
automated_in: [src/test/ridgun/test posix.ridgun]
---
# TS-POSIX-003 — Verify durable file sync, truncate, directory sync, exclusive lock and positional read

## Preconditions / fixtures
- `posix` lib (`src/main/ridgun/lib/posix.ridgun`) and `io` lib (`file size`).
- A fresh directory `/tmp/rg_posix_dur_<pid>`, removed at the end.

## Steps / inputs
1. Check the syscall picker: `px sys nr X86_64 x a` returns `x` and `px sys nr Arm64 x a` returns `a`; check that `nr fdatasync` (75/83), `nr fsync` (74/82), `nr ftruncate` (77/46), `nr flock` (73/32) and `nr pread64` (17/67) equal `px sys nr (sys arch) x86 arm`, so the step passes on either host; check `o directory for` (65536/16384).
2. Write 100 bytes to `f.dat` through `posix write`; call `posix fdatasync` and `posix fsync`; close the descriptor; call both again on the closed descriptor and on `-1`.
3. Reopen `f.dat` read-write; `posix ftruncate fd 40`; check `file size` is `40`; call `posix ftruncate fd -1`.
4. `posix sync dir` on the test directory, on `f.dat`, and on a missing path.
5. Open `lock` twice (two separate open files). `posix lock exclusive` on the first. Fork a child that opens `lock` again, calls `posix lock exclusive`, and exits with the negated result; the parent checks `waitpid decode status` gives `ProcExited 11` and the child returned at once (under 1 s). Check the second descriptor in the parent also gets `0 - errno ewouldblock`. `posix unlock` the first, then lock the second.
6. Write `0123456789ABCDEFGHIJ` to `r.dat`; open it read-only; `posix read fd 3` (position 3); `posix pread fd 10 5` → `(5, "ABCDE")`; `posix pread fd 15 100` → `(5, "FGHIJ")`; `posix pread fd 20 4` → `(0, "")`; `posix read fd 2` → `"34"` (position unchanged); write the 8 binary bytes `00 FF 00 41 80 FF 00 5A` to `b.dat` and check `posix pread fd 1 6` returns those 6 bytes unchanged, including `0x00`, `0x80` and `0xFF`; `posix pread` with offset `-1`, length `-1`, length `16777217` → `(-22, "")`; on an unopened descriptor (`99999`) and on `-1` → `(-9, "")`. A closed descriptor is not used here, so the step does not depend on which descriptor numbers are free.

## Expected results (map to acceptance criteria)
- AC1 → Step 1: every function takes its number from the per-architecture table; the suite runs on the build host's architecture.
- AC2 → Step 2: `0` on the open descriptor; `-9` on the closed descriptor and on `-1`.
- AC3 → Step 3: `0` and `file size` `40`; `-22` for the negative length.
- AC4 → Step 4: `0`, `-20`, and a negative result.
- AC5 → Step 5: `0` for the first lock; `-11` for the child and the second descriptor, without waiting; `0` after unlock.
- AC6 → Step 6: the bytes and counts listed, and the position is unchanged.

## Not covered here (to avoid duplication)
- Real durability across a power loss (needs fault-injection hardware).
- Running on arm64: the suite must also be run on an arm64 host; this host is x86_64. Step 5's `posix fork` / `posix exit` use the per-architecture table since `FR-POSIX-004`.
- See `TS-POSIX-001` for `posix open/read/write/close`.
