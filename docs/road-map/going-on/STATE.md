---
updated: 2026-10-30T13:37
active_task: none
agent_runtime: gemini
---
# Session state — read this first when resuming

## Where we are (3 lines max)
- `TASK-0038` completed: added `JsonNum String` (`json num text`, `json get float`), strict RFC 3629 UTF-8 byte sequence validation in JSON strings and object keys, `json find field` (`Option JsonVal`) and `json has field`, and parser fast-paths (`O(1)` list prepend + reverse, unescaped ASCII slice, in-place integer parsing) in `src/main/ridgun/lib/json.rg`.
## Files to load for the active task (nothing else)
- `docs/road-map/completed/2026-10/TASK-0038-title.md`
## Last verified facts (tests green? migrations applied? env?)
- `ridgunc run --strict "src/test/ridgun/test json.rg"` → `[PASS] test json: TS-JSON-001 (including RG-076, RG-077, RG-078) passed`
- `ridgunc run "src/test/ridgun/test jwt.rg"` → `[PASS] test jwt: TS-JWT-001 passed`
- Solstice repro (`2026-10-30-json-repro`) passes all cases (`1.5`, `-1.5`, `1e3`, `{"price":19.99}`, `bad-ff.json`, `bad-overlong.json`), and 100,000 small objects (900 KB) parse in `766 ms` (down from `1,836 ms`).
- `aix docs coverage && aix docs validate` → `0 errors, 0 warnings`
## Immediate next action
- Await next user instructions.
## Blockers / questions for the user
- None.
