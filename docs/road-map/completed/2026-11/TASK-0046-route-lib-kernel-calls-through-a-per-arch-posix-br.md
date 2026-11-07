---
id: TASK-0046
title: Route lib kernel calls through a per-arch posix bridge
status: completed
created: 2026-11-07
completed: 2026-11-07
requirements: [FR-POSIX-004, FR-POSIX-001, API-POSIX-001]   # FR-*/NFR-* this task delivers or touches
tests: [TS-POSIX-004]       # TS-* to automate
security: []                # VUL-* to address
context_files: [docs/requirements/decisions/ADR-0007-libs-reach-the-kernel-only-through-the-posix-bridge.md, docs/requirements/functional/posix/FR-POSIX-004-per-architecture-kernel-bridge-for-all-libs.md, src/main/ridgun/lib/posix.rg]   # THE ONLY files an agent must read to work on this task
scope: [src/main/ridgun/lib/posix.rg, src/main/ridgun/lib/socket.rg, src/main/ridgun/lib/uuid.rg, src/main/ridgun/lib/argon2id.rg, src/test/ridgun/test posix.rg, src/test/ridgun/test socket.rg, docs/requirements/functional/posix/, docs/requirements/api/posix/, docs/tests/functional/posix/, docs/requirements/decisions/]   # paths/globs this task will change (aix task start warns when two going-on tasks overlap)
owner: agent-001
claimed: 2026-11-07T09:51:22Z
claimed_by: claude claude@solarfall
policy:                     # a cycle for this task only (hotfix, release, ...); empty = the project's (aix policy)
---
# TASK-0046 — Route lib kernel calls through a per-arch posix bridge

## Goal (one sentence)
Make every kernel call in the libs correct on x86_64 and arm64 by routing it through one per-architecture syscall table in `posix`, and fix `posix execve` / `posix waitpid` on the way.

## Plan
- [x] Inventory raw `sys call` sites: about 60 in `posix`, `socket`, `uuid`, `argon2id`.
- [x] ADR-0007, FR-POSIX-004, TS-POSIX-004; update FR-POSIX-001 and API-POSIX-001.
- [x] Full `nr <name>` table (36 syscalls) and `at fdcwd` in `posix.rg`.
- [x] Move `posix`, `socket`, `uuid`, `argon2id` onto it; delete the `sk`/`uu`/inline buffer-helper copies.
- [x] `posix execve` via `execve` with a built argv/envp page; `posix waitpid` via `wait4` with the raw status.
- [x] Tests, header check, arm64 cross-build, rebuild bundles.

## Progress log (append-only, newest last)
- 2026-11-07: The user chose the posix bridge (option 2 in ADR-0007) after TASK-0045.
- 2026-11-07: Calls missing on arm64 use the shared form on both architectures: `fork` → `clone(SIGCHLD)`, `dup2` → `dup3` (with an `fcntl(F_GETFD)` check for `dup2 fd fd`), `unlink`/`rmdir` → `unlinkat`, `rename` → `renameat2`, `symlink` → `symlinkat`.
- 2026-11-07: `posix execve` and `posix waitpid` no longer use the compiler built-ins `sys execve` (adds `argv[0]` itself in ridgunc 0.9.33) and `sys waitpid` (returns the decoded exit code). They call `execve` and `wait4` directly, as FR-POSIX-001 AC3 says. The `test posix fork pipe dup2 execve waitpid` check passes again, and `main` in `test posix.rg` is back in its original order.
- 2026-11-07: `socket`, `uuid` and `argon2id` now `import posix`. `test posix.rg` replaces `sys call 201` (`time`, missing on arm64) with `px clock gettime 0`; `test socket.rg` uses `nr fcntl`.

## Files changed (keep current)
- src/main/ridgun/lib/posix.rg, socket.rg, uuid.rg, argon2id.rg
- src/test/ridgun/test posix.rg, src/test/ridgun/test socket.rg
- docs/requirements/decisions/ADR-0007-libs-reach-the-kernel-only-through-the-posix-bridge.md (new), decisions/INDEX.md
- docs/requirements/functional/posix/FR-POSIX-004-per-architecture-kernel-bridge-for-all-libs.md (new), FR-POSIX-001, INDEX.md
- docs/tests/functional/posix/TS-POSIX-004-per-architecture-kernel-bridge-for-all-libs.md (new), TS-POSIX-003, INDEX.md
- docs/requirements/api/posix/API-POSIX-001-posix-module-contract.md
- build/, target/bundles/, target/*.rgc, target/lib*.so for posix, socket, uuid, argon2id, io, crypto, http, tls, mail (rebuilt)

## Verification performed (command → result, newest last)
- `grep -n "sys call [0-9]" src/main/ridgun/lib/*.rg` → no matches.
- `ridgunc check --strict` on every lib in `build.rg` → 0 errors.
- Header check (scratch script): all 36 `nr` pairs equal `__NR_*` in `/usr/include/x86_64-linux-gnu/asm/unistd_64.h` and `/usr/include/asm-generic/unistd.h` → 0 mismatches.
- `ridgunc build --target arm64` of `test posix.rg`, `test socket.rg`, `test uuid.rg` → `ELF 64-bit LSB executable, ARM aarch64`. Not run: no arm64 host or emulator.
- `ridgunc run` on x86_64: `test posix.rg` (TS-POSIX-001..004, including the execve check), `test socket.rg`, `test io.rg`, `test uuid.rg`, `test time.rg` → PASS.
- `test crypto.rg`, `test tls.rg` (live included), `test mail.rg` (live included), `test http.rg`, `test argon2id.rg` → PASS.
- Rebuilt bundles and `.so` for posix, socket, uuid, argon2id, io, crypto, http, tls, mail → OK (2 min).
- `aix docs validate` → 0 errors; `aix docs coverage` regenerated.

## Exact next actions
1. Run the arm64 test binaries on an arm64 host.
2. Ask the `ridgun` compiler for `sys pread fd len offset => Int String` (or buffer primitives) to drop the memfd double copy.

## Decisions / open questions
- `posix exit` keeps `exit` (not `exit_group`), as before.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green (x86_64; arm64 cross-built only)
- [x] security entries updated (none needed)  - [x] docs INDEX updated  - [x] coverage matrix regenerated
