---
id: TS-POSIX-002
title: Verify POSIX filesystem operations, monotonic and wall clocks, signal watching, and CSPRNG random bytes
level: unit
covers: [FR-POSIX-002]
status: automated
automated_in: [src/test/ridgun/test_posix.rg]
---
# TS-POSIX-002 — Verify POSIX filesystem operations, monotonic and wall clocks, signal watching, and CSPRNG random bytes

## Preconditions / fixtures
- Pure-Ridgun `posix` module (`src/main/ridgun/lib/posix.rg`).

## Steps / inputs
1. Create `/tmp/rg_posix_dir`, write `/tmp/rg_posix_dir/a.txt`, `sys_chmod` to `493` (`0755`), `sys_rename` to `b.txt`, `sys_symlink` to `link.txt`, verify `sys_readlink`, `sys_unlink` files, `sys_rmdir` directory, and verify `sys_getpid () > 0` and `sys_getcwd () != ""`.
2. Measure `t1 = sys_monotonic_ms ()`, `n1 = sys_monotonic_ns ()`, call `sys_sleep_ms 30`, measure `t2 = sys_monotonic_ms ()`, `n2 = sys_monotonic_ns ()`, and `wall = sys_time_ms ()`; verify `wall > 1700000000000`, `t2 - t1 >= 25`, and `n2 > n1`.
3. Call `sys_random_bytes 32` twice (`r1`, `r2`), `sys_random_bytes 0`, and `sys_random_bytes -1`; verify `r1` and `r2` succeed with 32 distinct bytes, `0` returns `(0, "")`, and `-1` returns `(-7, "")`. Watch `[15]` via `sys_signal_watch`, verify `sys_signal_wait h 20` times out with `(-2, 0)`, deliver signal `15` (`SIGTERM`), and verify `sys_signal_wait h 500` returns `(0, 15)`.

## Expected results (map to acceptance criteria)
- AC1 → All `RG-010` filesystem and process operations succeed and reflect on the OS filesystem.
- AC2 → Wall and monotonic clocks (`RGF-017`) are monotonic and `sys_sleep_ms` honours the requested delay.
- AC3 → `sys_random_bytes` (`RGF-014`) produces distinct kernel CSPRNG byte strings and `sys_signal_watch`/`sys_signal_wait` (`RGF-018`) capture watched signals and honour timeouts.

## Not covered here (to avoid duplication)
- see `TS-POSIX-001` for `PollStatus`, `ProcStatus`, and low-level descriptor `wait fd`.
