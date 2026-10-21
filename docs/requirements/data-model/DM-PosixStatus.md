---
id: DM-PosixStatus
title: POSIX descriptor, PollStatus, and ProcStatus models
status: approved
related: [FR-POSIX-001, FR-POSIX-002, FR-IO-001, ADR-0002]
---
# DM-PosixStatus — POSIX descriptor, PollStatus, and ProcStatus models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| fd | Int | `>= 0` for valid open descriptor | File, pipe, signal, or socket descriptor |
| events | Int | Bitmask (`POLLIN = 1`, `POLLOUT = 4`, `POLLERR = 8`) | Watched or returned `ppoll` events |
| timeout_ms | Int | `-1` (infinite), `0` (poll once), `> 0` (deadline in ms) | Passed to `wait fd` / `sys poll` |
| sig_num | Int | `1..64` (`SIGINT = 2`, `SIGKILL = 9`, `SIGTERM = 15`, etc.) | POSIX signal identifier |
| pid | Int | `> 0` | OS process ID |
| exit_code | Int | `0..255` | Child process exit status (`ProcExited Int`) |
| errno_code | Int | `> 0` | Positive POSIX `errno` encapsulated in `PollError Int` |

## Relations
- Exported by `posix.rg` (`PollStatus = PollReady Int | PollTimeout | PollError Int`, `ProcStatus = ProcExited Int | ProcTimedOut Int | ProcSignal Int`) and consumed by `io.rg`.

## Invariants
- `wait fd` maps `sys poll` return values deterministically: `0` → `PollTimeout`, `< 0` → `PollError (0 - rc)`, `> 0` → `PollReady rc`.
- Signal watch descriptors (`sys_signal_watch`) only watch valid POSIX signals and never block indefinitely when queried with `timeout_ms >= 0`.

## Lifecycle
- Descriptors opened via `posix open` or `posix pipe` transition from open (`fd >= 0`) to closed via `posix close fd`.
