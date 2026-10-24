---
id: FR-IO-001
title: Provide extensible IoError and IoResult types and timeout-bounded descriptor read, write, and command execution
type: functional
status: implemented
priority: must
domain: IO
depends_on: [FR-POSIX-001, FR-POSIX-002]
related: [ADR-0002, VUL-INJ-002, VUL-INPUT-001]
tests: [TS-IO-001]
---
# FR-IO-001 — Provide extensible IoError and IoResult types and timeout-bounded descriptor read, write, and command execution

## Statement
The `io` library SHALL import `posix`, define the extensible `IoError` (`Timeout Int | Eof | SysErr Int String | NotFound String`) and `IoResult` (`String | Int | IoError`) types with `format io error`, and provide timeout-bounded descriptor reading (`read fd Int max Int timeout Int => IoResult` and `read fd after poll`), timeout-bounded descriptor writing (`write fd Int data String timeout Int => IoResult`), and timeout-bounded command execution (`exec with timeout` / `io exec timeout`).

## Rationale
As specified in `ridgun_posix_io_library_spec.md` (§5), applications, servers, and `unix-tools` require high-level descriptor and process operations that never hang indefinitely when a pipe, socket, or child command stalls.

## Acceptance criteria
- AC1: Given an `IoError` value (`Timeout ms`, `Eof`, `SysErr code op`, `NotFound path`), when `format io error` is called, then it returns `"timeout after {ms} ms"`, `"unexpected end of file"`, `"syscall error {code} in {op}"`, or `"file not found: {path}"` respectively.
- AC2: Given an open descriptor `fd`, byte limit `n`, and timeout `ms`, when `read fd fd max n timeout ms` or `write fd fd data s timeout ms` is called, then it first polls readiness via `wait fd fd (poll in) ms` (or `poll out`), returning `Timeout ms` on poll timeout, `SysErr err "poll"` on poll error, `Eof` when a ready read returns 0 bytes, or the read `String` / written `Int` byte count on success.
- AC3: Given a command and a timeout `ms`, when `io exec timeout cmd ms` is invoked, then commands completing within `ms` return their exit status or output, and commands exceeding `ms` are terminated (`sig term` / `sig kill`) and return `Timeout ms` (or `ProcTimedOut ms`).

## Actors & permissions
- Any Ridgun program or lib importing `io`.

## Constraints & edge cases
- `read fd` with `n <= 0` returns `SysErr 22 "read"` (`EINVAL`) without blocking.
- Command execution rejects null bytes in command strings.

## Data & privacy
- Descriptor data is held only in transient memory buffers.

## Security & observability notes
- Mitigates `VUL-INJ-002` and `VUL-INPUT-001` via explicit `max` byte bounds and mandatory `timeout` checks.

## Out of scope
- Asynchronous TLS record framing.
