---
updated: 2026-10-29T21:05
active_task: none
agent_runtime: gemini
---
# Session state — read this first when resuming

## Where we are (3 lines max)
- Completed `TASK-0037`: removed `where` from the reserved keywords in the `fmt` lib (`src/main/ridgun/lib/fmt.rg`), added full support for unprefixed (`fn ::`/`op ::`-free) signatures and clauses (`swap A with B => (B, A)` / `swap x with y = (y, x)`, `bigger a b = ...`) at any indentation and in single-line `fmt highlight line`, ensured clause parameter slots (`a`, `b`, `x`, `y`) remain plain while `with`/`to`/`from` in expressions remain `rg-kw`, synced `/home/gemini/.local/lib/ridgun/fmt.rglib`, and updated `docs/book/build_book.py`.
## Files to load for the active task (nothing else)
- `docs/road-map/pending/next/INDEX.md`
## Last verified facts (tests green? migrations applied? env?)
- `ridgunc run --strict "src/test/ridgun/test fmt.rg"`: `[PASS] test fmt: TS-FMT-001 passed`.
- `aix docs validate`: 0 errors, 0 warnings.
## Immediate next action
- Ready for the next user request.
## Blockers / questions for the user
- None.
