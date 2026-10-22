---
id: FR-TIME-001
title: Provide pure-Ridgun UTC civil calendar conversions, ISO-8601/RFC 3339 formatting and parsing, human durations, and exponential backoff
type: functional
status: implemented
priority: must
domain: TIME
depends_on: []
related: [ADR-0002, VUL-INPUT-001]
tests: [TS-TIME-001]
---
# FR-TIME-001 — Provide pure-Ridgun UTC civil calendar conversions, ISO-8601/RFC 3339 formatting and parsing, human durations, and exponential backoff

## Statement
The `time` library SHALL provide pure-Ridgun conversions between Unix epoch seconds and UTC civil calendar dates (`time epoch to utc`, `time utc to epoch`, `time is leap year`, `time days in month`, `time day of week`), ISO-8601 / RFC 3339 formatting and parsing (`time format iso8601`, `time parse iso8601`), human-readable duration formatting (`time format duration ms`), and bounded exponential backoff calculation (`time backoff ms`).

## Rationale
Applications, logs, HTTP headers, and retry loops require civil UTC calendar arithmetic, ISO-8601 timestamps (`YYYY-MM-DDTHH:MM:SSZ`), and duration/backoff formatting on top of raw epoch counters.

## Acceptance criteria
- AC1: Given Unix epoch seconds (`0` for `1970-01-01T00:00:00Z`, `1792664400` for `2026-10-22T10:20:00Z`, and leap-day timestamps), when `time epoch to utc` and `time utc to epoch` are called, then they round-trip `(year, month, day, hour, minute, second)` accurately and `time is leap year` / `time days in month` / `time day of week` return exact calendar values.
- AC2: Given epoch seconds or ISO-8601 strings (`"2026-10-22T10:20:00Z"`), when `time format iso8601` and `time parse iso8601` are called, then they round-trip valid timestamps and `time parse iso8601` returns `-1` on malformed date/time strings or out-of-range calendar fields.
- AC3: Given millisecond durations and retry attempt counts, when `time format duration ms` and `time backoff ms` are called, then `time format duration ms 3661005` returns `"1h 1m 1s 5ms"` and `time backoff ms attempt base_ms max_ms` returns $base \times 2^{attempt}$ clamped to `[base_ms, max_ms]`.

## Actors & permissions
- Any Ridgun module importing `time`.

## Constraints & edge cases
- Invalid calendar months (`< 1` or `> 12`), days (`< 1` or `> days_in_month`), hours (`> 23`), minutes (`> 59`), or seconds (`> 59`) in `time parse iso8601` return `-1`.

## Data & privacy
- Pure in-memory calendar and duration calculations.

## Security & observability notes
- Mitigates `VUL-INPUT-001` by validating all ISO-8601 field ranges before computing epoch seconds.

## Out of scope
- IANA political timezone database (`tzdata`) historical rules.
