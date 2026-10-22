---
id: API-LOG-001
title: Public module contract for log (log.rglib / liblog.so)
status: approved
implements: [FR-LOG-001]
auth: none
---
# API-LOG-001 — Public module contract for `log` (`log.rg`)

## Request
- Imported via `import log`.
- Functions:
  - `log level rank String => Int`, `log level name Int => String`, `log should emit String String => Bool`
  - `log is sensitive key String => Bool`, `log redact fields [(String, String)] => [(String, String)]`
  - `log format text String String [(String, String)] => String`, `log format json String String [(String, String)] => String`

## Responses
| Code | When | Body |
|---|---|---|
| `String` / `Bool` / `[(String, String)]` | Log level check, redaction, or formatting | Sanitized and redacted log line or field list |

## Rules
- Sensitive keys are always redacted before formatting.
