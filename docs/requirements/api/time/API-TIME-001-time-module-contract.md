---
id: API-TIME-001
title: Public module contract for time (time.rglib / libtime.so)
status: approved
implements: [FR-TIME-001]
auth: none
---
# API-TIME-001 — Public module contract for `time` (`time.rg`)

## Request
- Imported via `import time`.
- Functions:
  - `time is leap year Int => Bool`, `time days in month Int Int => Int`, `time day of week Int Int Int => Int`
  - `time utc to epoch Int Int Int Int Int Int => Int`, `time epoch to utc Int => (Int, Int, Int, Int, Int, Int)`
  - `time format iso8601 Int => String`, `time parse iso8601 String => Int`
  - `time format duration ms Int => String`, `time backoff ms Int Int Int => Int`

## Responses
| Code | When | Body |
|---|---|---|
| `>= 0` | Valid ISO-8601 timestamp (`time parse iso8601`) | Unix epoch seconds |
| `-1` | Invalid ISO-8601 string or calendar out of range | `-1` |

## Rules
- Uses Howard Hinnant's proleptic Gregorian civil calendar algorithm.
