---
id: FR-POSIX-002
title: Provide POSIX filesystem operations, monotonic and wall clocks, signal watching, and CSPRNG random bytes
type: functional
status: implemented
priority: must
domain: POSIX
depends_on: [FR-POSIX-001]
related: [ADR-0002, ADR-0010, VUL-INJ-002, VUL-INPUT-001]
tests: [TS-POSIX-002]
---
# FR-POSIX-002 — Provide POSIX filesystem operations, monotonic and wall clocks, signal watching, and CSPRNG random bytes

## Statement
The `posix` library SHALL provide the `RG-010` filesystem and process operations (`sys_mkdir`, `sys_rmdir`, `sys_rename`, `sys_symlink`, `sys_readlink`, `sys_unlink`, `sys_chmod`, `sys_chdir`, `sys_getcwd`, `sys_getenv`, `sys_getpid`), `RGF-017` clocks and sleep (`sys_time_ms`, `sys_monotonic_ms`, `sys_monotonic_ns`, `sys_sleep_ms`), `RGF-018` signal watching (`sys_signal_watch`, `sys_signal_wait`), and `RGF-014` cryptographic random byte generation (`sys_random_bytes`, `sys_random_tensor`).
`sys monotonic ms` and `sys monotonic ns` SHALL return the compiler built-ins `sys time ms` and `sys time ns` (vDSO, no system call); the wall clock is the built-in `sys wall time ms`, which `posix` SHALL NOT redefine (`ADR-0010`).
Random bytes as a byte sequence SHALL be a `Tensor[U8]` (`sys random tensor`), not a list of `Int` (`ADR-0010`).

## Rationale
Applications and servers require portable access to POSIX directory/file manipulation, non-decreasing monotonic clocks for deadline calculation, non-blocking signal notifications (`SIGINT`/`SIGTERM`), and kernel CSPRNG entropy (`getrandom` / `/dev/urandom`).

## Acceptance criteria
- AC1: Given valid filesystem paths and process queries, when `sys_mkdir`, `sys_rmdir`, `sys_rename`, `sys_symlink`, `sys_readlink`, `sys_unlink`, `sys_chmod`, `sys_chdir`, `sys_getcwd`, `sys_getenv`, and `sys_getpid` are invoked (with either underscore or space syntax), then directory creation/removal, atomic rename, symlink creation/target reading, unlink, permission changes, working directory changes, and PID queries (`> 0`) succeed and reflect immediately on the OS filesystem.
- AC2: Given clock and sleep calls (`sys time ms`, `sys time ns`, `sys monotonic ms`, `sys monotonic ns`, `sys wall time ms`, `sys sleep ms`), when invoked sequentially around `sys sleep ms 25`, then `sys wall time ms` returns Unix epoch milliseconds (`> 1700000000000`) within 2 s of the kernel `CLOCK_REALTIME`, the monotonic clocks are non-decreasing (`t2 >= t1`) and advance by at least 20 ms, and `sys sleep ms 25` pauses execution for at least `20` ms.
- AC3: Given `sys_random_bytes n` (`RGF-014`) and `sys_signal_watch sig_list` / `sys_signal_wait handle timeout_ms` (`RGF-018`), when `sys_random_bytes 32` is called twice, then both return `(0, bytes)` of length `32` with distinct unpredictable content (`r1 != r2`, or `(0, "")` for `n == 0`, `(-7, "")` for `n < 0`); `sys random tensor n` follows the same status convention and returns a `Tensor[U8]` of length `n` (empty on error or `n == 0`); and when a watched signal (`SIGTERM = 15`) is sent to `sys_getpid ()` (or queued on the watch handle), `sys_signal_wait` returns `(0, 15)` before timeout and `(-2, 0)` on timeout.

## Actors & permissions
- Any Ridgun program or lib importing `posix`.

## Constraints & edge cases
- `sys_random_bytes` with `n < 0` or `n > 65536` returns `(-7, "")` (`INVALID`); `sys random tensor` returns `(-7, Tensor[U8 * 0])` in the same cases. A kernel failure returns status `-99`.
- `sys_signal_watch` rejects empty signal lists or invalid signal numbers (`<= 0` or `> 64`) with `(-7, -1)`.

## Data & privacy
- Random bytes are generated directly from kernel entropy (`getrandom` syscall / `/dev/urandom`) and never logged.

## Security & observability notes
- Mitigates `VUL-INJ-002` and `VUL-INPUT-001`.

## Out of scope
- Real-time POSIX timers (`timer_create`).
