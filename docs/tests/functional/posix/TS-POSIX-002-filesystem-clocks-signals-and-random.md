---
id: TS-POSIX-002
title: Verify POSIX filesystem operations, monotonic and wall clocks, signal watching, and CSPRNG random bytes
level: unit
covers: [FR-POSIX-002]
status: automated
automated_in: [src/test/ridgun/test posix.rg]
---
# TS-POSIX-002 — Verify POSIX filesystem operations, monotonic and wall clocks, signal watching, and CSPRNG random bytes

## Preconditions / fixtures
- Pure-Ridgun `posix` module (`src/main/ridgun/lib/posix.rg`).

## Steps / inputs
1. Create `/tmp/rg_posix_dir`, write `/tmp/rg_posix_dir/a.txt`, `sys_chmod` to `493` (`0755`), `sys_rename` to `b.txt`, `sys_symlink` to `link.txt`, verify `sys_readlink`, `sys_unlink` files, `sys_rmdir` directory, and verify `sys_getpid () > 0` and `sys_getcwd () != ""`.
2. Measure `t1 = sys monotonic ms`, `n1 = sys time ns`, `m1 = sys monotonic ns`, `w1 = sys wall time ms`, call `sys sleep ms 25`, measure `t2`, `n2`, `m2`, `w2` the same way; verify `t2 - t1 >= 20`, `n2 > n1`, `n2 - n1 >= 20000000`, `m2 - m1 >= 20000000`, that 10 000 consecutive `sys time ns` reads never decrease, that `1700000000000 < w1 < 4102444800000`, that `w2 / 1000` is within 2 s of the seconds of `clock_gettime(CLOCK_REALTIME)` read with `sys call (nr clock gettime)` into a `Tensor[U8 * 16]`, and that `w2 - w1 >= 20`.
3. Call `sys_random_bytes 32` twice (`r1`, `r2`), `sys_random_bytes 0`, and `sys_random_bytes -1`; verify `r1` and `r2` succeed with 32 distinct bytes, `0` returns `(0, "")`, and `-1` returns `(-7, "")`. Call `sys random tensor 256`, `0`, `-1` and `65537`; verify `(0, t)` with a 256-byte `Tensor[U8]`, an empty tensor for `0`, and status `-7` for `-1` and `65537` (`ADR-0010`). Watch `[15]` via `sys_signal_watch`, verify `sys_signal_wait h 20` times out with `(-2, 0)`, deliver signal `15` (`SIGTERM`), and verify `sys_signal_wait h 500` returns `(0, 15)`.

## Expected results (map to acceptance criteria)
- AC1 → All `RG-010` filesystem and process operations succeed and reflect on the OS filesystem.
- AC2 → Wall and monotonic clocks (`RGF-017`) are monotonic and `sys_sleep_ms` honours the requested delay.
- AC3 → `sys_random_bytes` (`RGF-014`) produces distinct kernel CSPRNG byte strings and `sys_signal_watch`/`sys_signal_wait` (`RGF-018`) capture watched signals and honour timeouts.

## Not covered here (to avoid duplication)
- see `TS-POSIX-001` for `PollStatus`, `ProcStatus`, and low-level descriptor `wait fd`.
