---
id: DM-IoResult
title: Extensible IoError and IoResult high-level I/O models
status: approved
related: [FR-IO-001, FR-IO-002, FR-POSIX-001, ADR-0002]
---
# DM-IoResult — Extensible IoError and IoResult high-level I/O models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| fd | Int | `>= 0` | Target descriptor for `read fd` / `write fd` |
| max_bytes | Int | `> 0` | Maximum byte count for bounded read operations |
| timeout_ms | Int | `-1`, `0`, `> 0` | Millisecond deadline before returning `Timeout timeout_ms` |
| errno_code | Int | `> 0` | Positive errno code carried in `SysErr errno_code op` |
| path | String | Non-empty filesystem path | Carried in `NotFound path` and file helpers |

## Relations
- Defined in `io.rg` (`type IoError = Timeout Int | Eof | SysErr Int String | NotFound String`, `type IoResult = String | Int | IoError`) on top of `posix.rg` (`DM-PosixStatus`) and extendable by downstream modules via `expand type IoError` / `expand type IoResult`.

## Invariants
- Every timeout-bounded descriptor read or write (`read fd`, `write fd`) checks readiness via `wait fd` before performing raw kernel I/O, guaranteeing that stalled pipes or sockets return `Timeout ms` instead of blocking the calling thread.
- Reading `0` bytes from a ready descriptor returns `Eof`.

## Lifecycle
- Single-call result sum value returned by `io.rg` operations and formatted via `format io error`.
