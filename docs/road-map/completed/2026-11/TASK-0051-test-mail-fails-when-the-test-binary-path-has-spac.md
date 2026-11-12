---
id: TASK-0051
title: test mail fails when the test binary path has spaces
status: completed
created: 2026-11-10
completed: 2026-11-10
requirements: []
tests: [TS-MAIL-001]
security: []                # VUL-* to address
context_files: [src/test/ridgun/test mail.ridgun]
scope: [src/test/ridgun/test mail.ridgun]
owner: agent-001
claimed: 2026-11-10T19:06:41Z
claimed_by: claude claude@solarfall
policy:                     # a cycle for this task only (hotfix, release, ...); empty = the project's (aix policy)
---
# TASK-0051 — test mail fails when the test binary path has spaces

## Goal (one sentence)
`test mail.ridgun` passes under `stable test`, whose test binary is `target/.stable_test_test mail.rg_bin`.

## Plan
- [x] `start smtp` passes the binary path and the work directory to `sh` as quoted words (`sh quote`).

## Progress log (append-only, newest last)
- 2026-11-10: the compiler team reported 34/35 under `stable test` (compiler notes of 2026-11-10). Cause: the test relaunches itself through `sh` with its path unquoted, and that path has spaces, so the SMTP server never started. Not a compiler fault.

## Files changed (keep current)
- src/test/ridgun/test mail.ridgun

## Verification performed (command → result, newest last)
- Old binary copied to a path with spaces → `[FAIL] SMTP test server did not start (starttls)` (reproduced).
- Fixed binary at a path with spaces → TS-MAIL-001 passes.
- `stable test` with ridgunc 0.9.56 → 35/35.

## Exact next actions
1. None.

## Decisions / open questions
- None.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
