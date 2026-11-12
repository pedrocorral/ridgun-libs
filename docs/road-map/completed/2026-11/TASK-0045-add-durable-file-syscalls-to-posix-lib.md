---
id: TASK-0045
title: Add durable file syscalls to posix lib
status: completed
created: 2026-11-07
completed: 2026-11-07
requirements: [FR-POSIX-003, API-POSIX-001]   # FR-*/NFR-* this task delivers or touches
tests: [TS-POSIX-003]       # TS-* to automate
security: [VUL-INPUT-001]   # VUL-* to address
context_files: [docs/requirements/functional/posix/FR-POSIX-003-durable-file-sync-truncate-lock-and-positional-read.md, docs/tests/functional/posix/TS-POSIX-003-durable-file-sync-truncate-lock-and-positional-read.md, src/main/ridgun/lib/posix.ridgun, src/test/ridgun/test posix.ridgun]   # THE ONLY files an agent must read to work on this task
scope: [src/main/ridgun/lib/posix.ridgun, src/test/ridgun/test posix.ridgun, docs/requirements/functional/posix/, docs/requirements/api/posix/, docs/tests/functional/posix/]   # paths/globs this task will change (aix task start warns when two going-on tasks overlap)
owner: agent-001
claimed: 2026-11-07T09:35:42Z
claimed_by: claude claude@solarfall
policy:                     # a cycle for this task only (hotfix, release, ...); empty = the project's (aix policy)
---
# TASK-0045 — Add durable file syscalls to posix lib

## Goal (one sentence)
Give the Eterval and Griphgun databases (`ecosystem/apps/db/`) `fdatasync`, `fsync`, `ftruncate`, directory sync, an exclusive non-blocking lock and `pread` in the `posix` lib, with the right syscall numbers on x86_64 and arm64.

## Plan
- [x] Write FR-POSIX-003 and TS-POSIX-003; extend API-POSIX-001.
- [x] Add a per-architecture syscall number picker (`sys arch`) to `posix.ridgun`.
- [x] Implement the six functions plus `posix unlock`, `o directory` and the `errno` constants.
- [x] Make the buffer helpers that `posix pread` uses (`mmap`, `munmap`, `memfd_create`, `lseek`, `pread64`, `pwrite64`) arch-aware.
- [x] Automate TS-POSIX-003 in `test posix.ridgun`; build the posix bundle; validate docs; regenerate coverage.

## Progress log (append-only, newest last)
- 2026-11-07: Request from Eterval and Griphgun (`/tmp/ridgun-lib/requirements/2026-11-07-sincronizar-y-truncar-archivos.md`). The user chose "spec and build". Placed in `posix`. `posix pread` returns `Int String` (`(rc, data)`), not `String`, so a negative error code can be returned.
- 2026-11-07: Added the `px sys nr` / `nr ...` syscall table (`sys arch`), `o directory`, the `errno` constants, and `posix fdatasync`, `fsync`, `ftruncate`, `sync dir`, `lock exclusive`, `unlock`, `pread`. The `mmap`/`munmap`/`memfd_create`/`lseek`/`pread64`/`pwrite64` buffer helpers now use the table too.
- 2026-11-07: Found two failures that predate this task (they also fail on `main` at `5bed8f7`) with ridgunc 0.9.33: (1) `sys execve` seems to put the path in `argv[0]` itself, so `posix execve` passes it twice and `test posix fork pipe dup2 execve waitpid` fails; (2) `sys waitpid` returns the decoded exit code, but `waitpid decode status` expects the raw wait status, so exit code 11 is read as `ProcSignal 11`. Not fixed here. The TS-POSIX-003 lock check accepts both encodings. `main` in `test posix.ridgun` now runs the durable test before the fork test, so the new test's results still show up while the fork test fails.
- 2026-11-07: Review fixes before commit: TS-POSIX-003 step 1 now compares `nr ...` with `px sys nr (sys arch) ...` instead of x86_64 literals, so it passes on arm64; added a binary `posix pread` check (`0x00`, `0x80`, `0xFF`); `px alloc mfd` now takes the fresh zeroed mmap page as the `memfd_create` name instead of the fixed address `0x400007`, which only exists in an executable loaded at `0x400000` (not in a `.so`). All `px alloc mfd` callers pass the page they just mapped.
- 2026-11-07: Replaced `{sys_getpid}` interpolation in `test posix.ridgun` with a `my_pid` binding so the test file passes `ridgunc check --strict`.

## Files changed (keep current)
- docs/requirements/functional/posix/FR-POSIX-003-durable-file-sync-truncate-lock-and-positional-read.md (new)
- docs/tests/functional/posix/TS-POSIX-003-durable-file-sync-truncate-lock-and-positional-read.md (new)
- docs/requirements/api/posix/API-POSIX-001-posix-module-contract.md
- docs/requirements/functional/posix/INDEX.md, docs/tests/functional/posix/INDEX.md, docs/tests/coverage-matrix.md
- src/main/ridgun/lib/posix.ridgun
- src/test/ridgun/test posix.ridgun
- build/posix.ridgunlib, target/bundles/posix.ridgunlib, target/posix.rgc, target/libposix.so (rebuilt)

## Verification performed (command → result, newest last)
- `ridgunc check --strict src/main/ridgun/lib/posix.ridgun` → 0 errors; same for `io`, `socket`, `uuid`, `argon2id`, `tls`, `mail` and `src/test/ridgun/test posix.ridgun`.
- `ridgunc run "src/test/ridgun/test posix.ridgun"` → TS-POSIX-001, TS-POSIX-002 and TS-POSIX-003 pass; stops at the existing `posix execve passes literal argv` failure (same result on `main` without this change).
- `ridgunc build --strict --so src/main/ridgun/lib/posix.ridgun -o target/libposix.so` → OK.
- `aix docs validate` → 0 errors, 0 warnings; `aix docs coverage` → FR-POSIX-003 `ok`.
- After the review fixes: `test posix.ridgun` → TS-POSIX-001/002/003 pass (binary pread included), same existing `execve` failure; `test io.ridgun`, `test time.ridgun`, `test uuid.ridgun` → PASS; posix bundle and `target/libposix.so` rebuilt. Not verified: `libposix.so` loaded at a non-default address.

## Exact next actions
1. Run `test posix.ridgun` on an arm64 host (FR-POSIX-003 AC1 on arm64 is unverified).
2. Next task: move every kernel call in `posix`, `socket`, `uuid` and `argon2id` onto a per-arch operation bridge (`fork` → `clone`, `dup2` → `dup3`, `exit` 93, ...); FR + ADR "libs never call `sys call` directly".
3. Ask the `ridgun` compiler for `sys pread fd len offset => Int String` (or buffer primitives) to remove the memfd double copy.
4. Fix `posix execve` / `waitpid decode status` against ridgunc 0.9.33 (`sys execve`, `sys waitpid` semantics).

## Decisions / open questions
- arm64 numbers come from the kernel's generic syscall table (`include/uapi/asm-generic/unistd.h`). They cannot be run on this x86_64 host; arm64 stays unverified until the tests run on an arm64 machine.
- Other raw `sys call` sites in `posix.ridgun` (clocks, signals, pipes, process), `socket.ridgun`, `uuid.ridgun` and `argon2id.ridgun` still use x86_64 numbers only. Out of scope here.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green (TS-POSIX-003; x86_64 only)
- [x] security entries updated (VUL-INPUT-001 already lists posix.ridgun)  - [x] docs INDEX updated  - [x] coverage matrix regenerated
