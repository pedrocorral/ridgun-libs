---
id: TS-TIME-001
title: Verify UTC civil calendar conversions, ISO-8601 formatting and parsing, human durations, and exponential backoff
level: unit
covers: [FR-TIME-001, API-TIME-001]
status: automated
automated_in: [src/test/ridgun/test_time.rg]
---
# TS-TIME-001 — Verify UTC civil calendar conversions, ISO-8601 formatting and parsing, human durations, and exponential backoff

## Preconditions / fixtures
- Pure-Ridgun `time` module (`src/main/ridgun/lib/time.rg`).

## Steps / inputs
1. Call `time is leap year`, `time days in month`, `time day of week`, `time utc to epoch`, and `time epoch to utc` across `1970-01-01`, `2000-02-29`, and `2026-10-22`.
2. Call `time format iso8601` and `time parse iso8601` on valid timestamps and malformed strings (`"2026-13-01T00:00:00Z"`, `"invalid"`).
3. Call `time format duration ms` and `time backoff ms` across boundary values.

## Expected results (map to acceptance criteria)
- AC1 → Calendar conversions and leap-year rules match proleptic Gregorian UTC exactly.
- AC2 → ISO-8601 formatting and parsing round-trip cleanly and reject invalid dates with `-1`.
- AC3 → Human durations and exponential backoff return exact expected values.

## Not covered here (to avoid duplication)
- Kernel monotonic/wall-clock syscalls are covered in `TS-POSIX-002`.
