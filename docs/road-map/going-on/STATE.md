---
updated: 2026-11-07T10:35
active_task: none
agent_runtime: claude
---
# Session state — read this first when resuming

## Where we are (3 lines max)
- `TASK-0045` (posix durable file syscalls, FR-POSIX-003) completed; earlier `TASK-0043` and `TASK-0044`.
- No active task.
## Files to load for the active task (nothing else)
- none
## Last verified facts (tests green? migrations applied? env?)
- `test posix.rg`: TS-POSIX-001/002/003 pass on x86_64; the existing `posix execve` check fails with ridgunc 0.9.33 (also on `main`). Not run on arm64.
- `aix docs validate` 0 errors; coverage matrix regenerated.
## Immediate next action
- Candidate: fix `posix execve` and `waitpid decode status` for ridgunc 0.9.33 `sys execve` / `sys waitpid` semantics (see TASK-0045 log).
- Candidate: audit `VUL-AUTHN-004`, `VUL-INPUT-003`, `VUL-INJ-003` (`expected`).
## Blockers / questions for the user
- None.
