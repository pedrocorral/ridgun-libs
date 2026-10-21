---
id: TS-IO-001
title: Verify IoError and IoResult formatting and timeout-bounded descriptor read, write, and command execution
level: unit
covers: [FR-IO-001]
status: planned
automated_in: [src/test/ridgun/test_io.rg]
---
# TS-IO-001 — Verify IoError and IoResult formatting and timeout-bounded descriptor read, write, and command execution

## Preconditions / fixtures
- Pure-Ridgun `io` and `posix` modules (`src/main/ridgun/lib/io.rg`, `src/main/ridgun/lib/posix.rg`).

## Steps / inputs
1. Call `format io error (Timeout 500)`, `format io error Eof`, `format io error (SysErr 9 "poll")`, and `format io error (NotFound "/missing")` and verify the formatted diagnostic strings.
2. Open a pipe via `posix pipe`; call `read fd rfd max 64 timeout 20` on the empty pipe and verify it returns `Timeout 20`; call `write fd wfd data "stream-ok" timeout 100` and verify it returns `9`; call `read fd rfd max 64 timeout 100` and verify it returns `"stream-ok"`; close `wfd` and call `read fd rfd max 64 timeout 100` to verify `Eof`.
3. Call `io exec timeout "true" 500` and verify it succeeds (`0`); call `io exec timeout "sleep 2" 40` and verify it times out and returns `Timeout 40`.

## Expected results (map to acceptance criteria)
- AC1 → `format io error` formats `Timeout`, `Eof`, `SysErr`, and `NotFound` variants as specified in `ridgun_posix_io_library_spec.md` §5.1.
- AC2 → `read fd` and `write fd` with timeout poll descriptor readiness first, returning `Timeout ms` on expiry, `Eof` on closed peer, `SysErr` on bad fd, and read `String` / written `Int` on success.
- AC3 → `io exec timeout` completes fast commands and terminates commands exceeding `timeout_ms`.

## Not covered here (to avoid duplication)
- see `TS-IO-002` for `RG-010` file operations, path metadata predicates, and line streams.
