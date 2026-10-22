---
id: TS-LOG-001
title: Verify level filtering, sensitive key redaction, and structured text/JSON log formatting
level: unit
covers: [FR-LOG-001, API-LOG-001]
status: automated
automated_in: [src/test/ridgun/test_log.rg]
---
# TS-LOG-001 — Verify level filtering, sensitive key redaction, and structured text/JSON log formatting

## Preconditions / fixtures
- Pure-Ridgun `log` module (`src/main/ridgun/lib/log.rg`).

## Steps / inputs
1. Call `log level rank`, `log level name`, and `log should emit` across `DEBUG`, `INFO`, `WARN`, and `ERROR`.
2. Call `log is sensitive key` and `log redact fields` on `password`, `Authorization`, `api_key`, `user_token`, and normal fields (`user`, `port`).
3. Call `log format text` and `log format json` and verify `[REDACTED]` replacement and newline/quote escaping.

## Expected results (map to acceptance criteria)
- AC1 → Severity ordering filters messages below `min_level`.
- AC2 → All credential/token keys are redacted to `"[REDACTED]"`.
- AC3 → Text and NDJSON log lines are properly formatted and escaped.

## Not covered here (to avoid duplication)
- File descriptor appending is covered in `TS-IO-002`.
