---
updated: 2026-11-09T19:57
active_task: none
agent_runtime: claude
---
# Session state — read this first when resuming

## Where we are (3 lines max)
- `TASK-0046` (per-arch kernel bridge, FR-POSIX-004, ADR-0007) and `TASK-0045` (FR-POSIX-003) completed.
- No active task.
## Files to load for the active task (nothing else)
- none
## Last verified facts (tests green? migrations applied? env?)
- On x86_64 the posix, socket, io, uuid, time, crypto, tls, mail, http and argon2id suites pass (posix execve fixed). arm64: cross-built, header-checked, not run.
- `aix docs validate` 0 errors; coverage matrix regenerated.
## Immediate next action
- Candidate: run the arm64 test binaries on an arm64 host; ask the `ridgun` compiler for a `sys pread` primitive.
- Candidate: audit `VUL-AUTHN-004`, `VUL-INPUT-003`, `VUL-INJ-003` (`expected`).
## Blockers / questions for the user
- None.
