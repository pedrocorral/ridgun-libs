-- ============================================================
-- src/test/ridgun/test time.rg
-- Comprehensive test suite for time.rg inspired by Howard Hinnant civil calendar & RFC 3339
-- @tests TS-TIME-001
-- ============================================================

import test
import time

fn :: utc y (Int Int Int Int Int Int) => Int
      utc y (y, _, _, _, _, _)        =  y

fn :: utc m (Int Int Int Int Int Int) => Int
      utc m (_, m, _, _, _, _)        =  m

fn :: utc d (Int Int Int Int Int Int) => Int
      utc d (_, _, d, _, _, _)        =  d

fn :: utc hh (Int Int Int Int Int Int) => Int
      utc hh (_, _, _, hh, _, _)       =  hh

fn :: utc mm (Int Int Int Int Int Int) => Int
      utc mm (_, _, _, _, mm, _)       =  mm

fn :: utc ss (Int Int Int Int Int Int) => Int
      utc ss (_, _, _, _, _, ss)       =  ss

-- 1. Proleptic Gregorian leap years (4/100/400 rule), month lengths, day of week, and Howard Hinnant vectors
-- @tests TS-TIME-001
fn :: test utc calendar and iso8601 => ()
      test utc calendar and iso8601 =
        -- Gregorian 4/100/400 leap year rules
        _ = assert true (time is leap year 1600) "AC1: 1600 divisible by 400 is leap"
        _ = assert false (time is leap year 1700) "AC1: 1700 divisible by 100 not leap"
        _ = assert false (time is leap year 1800) "AC1: 1800 divisible by 100 not leap"
        _ = assert false (time is leap year 1900) "AC1: 1900 divisible by 100 not leap"
        _ = assert true (time is leap year 2000) "AC1: 2000 divisible by 400 is leap"
        _ = assert true (time is leap year 2024) "AC1: 2024 divisible by 4 is leap"
        _ = assert false (time is leap year 2026) "AC1: 2026 not leap"
        _ = assert true (time is leap year 2400) "AC1: 2400 divisible by 400 is leap"

        -- Month lengths & out-of-range month safety
        _ = assert int equals (time days in month 2024 2) 29 "AC1: Feb 2024 == 29"
        _ = assert int equals (time days in month 2026 2) 28 "AC1: Feb 2026 == 28"
        _ = assert int equals (time days in month 2026 1) 31 "AC1: Jan == 31"
        _ = assert int equals (time days in month 2026 4) 30 "AC1: Apr == 30"
        _ = assert int equals (time days in month 2026 6) 30 "AC1: Jun == 30"
        _ = assert int equals (time days in month 2026 9) 30 "AC1: Sep == 30"
        _ = assert int equals (time days in month 2026 11) 30 "AC1: Nov == 30"
        _ = assert int equals (time days in month 2026 12) 31 "AC1: Dec == 31"
        _ = assert int equals (time days in month 2026 0) 0 "AC1: month 0 -> 0"
        _ = assert int equals (time days in month 2026 13) 0 "AC1: month 13 -> 0"

        -- Day of week (0=Sunday .. 6=Saturday)
        _ = assert int equals (time day of week 1970 1 1) 4 "AC1: 1970-01-01 was Thursday (4)"
        _ = assert int equals (time day of week 2000 1 1) 6 "AC1: 2000-01-01 was Saturday (6)"
        _ = assert int equals (time day of week 2026 10 24) 6 "AC1: 2026-10-24 is Saturday (6)"

        -- Famous Unix epoch milestones: 0, 1000000000 (2001-09-09T01:46:40Z), Y2038 (2147483647 -> 2038-01-19T03:14:07Z)
        _ = assert int equals (time utc to epoch 1970 1 1 0 0 0) 0 "AC2: Unix epoch 0"
        _ = assert str eq (time format iso8601 0) "1970-01-01T00:00:00Z" "AC2: format epoch 0"
        _ = assert str eq (time format iso8601 1000000000) "2001-09-09T01:46:40Z" "AC2: format billennium 1000000000"
        _ = assert int equals (time parse iso8601 "2001-09-09T01:46:40Z") 1000000000 "AC2: parse billennium"
        _ = assert str eq (time format iso8601 2147483647) "2038-01-19T03:14:07Z" "AC2: 64-bit Y2038 boundary 2147483647"
        _ = assert int equals (time parse iso8601 "2038-01-19 03:14:07") 2147483647 "AC2: RFC 3339 space separator without Z"

        ts = time utc to epoch 2026 10 22 10 20 59
        iso = time format iso8601 ts
        _ = assert str eq iso "2026-10-22T10:20:59Z" "AC2: format 2026-10-22T10:20:59Z"
        _ = assert int equals (time parse iso8601 iso) ts "AC2: parse roundtrip"
        tup = time epoch to utc ts
        _ = assert int equals (utc y tup) 2026 "AC1: year 2026"
        _ = assert int equals (utc m tup) 10 "AC1: month 10"
        _ = assert int equals (utc d tup) 22 "AC1: day 22"
        _ = assert int equals (utc hh tup) 10 "AC1: hour 10"
        _ = assert int equals (utc mm tup) 20 "AC1: minute 20"
        _ = assert int equals (utc ss tup) 59 "AC1: second 59"

        -- Negative validation on invalid calendar dates and timestamps
        _ = assert int equals (time parse iso8601 "2026-13-01T00:00:00Z") (0 - 1) "AC2: invalid month 13 -> -1"
        _ = assert int equals (time parse iso8601 "2026-00-01T00:00:00Z") (0 - 1) "AC2: invalid month 00 -> -1"
        _ = assert int equals (time parse iso8601 "2026-02-29T00:00:00Z") (0 - 1) "AC2: 2026-02-29 non-leap -> -1"
        _ = assert true ((time parse iso8601 "2024-02-29T00:00:00Z") > 0) "AC2: 2024-02-29 leap year valid"
        _ = assert int equals (time parse iso8601 "2026-04-31T00:00:00Z") (0 - 1) "AC2: April 31 -> -1"
        _ = assert int equals (time parse iso8601 "2026-01-01T24:00:00Z") (0 - 1) "AC2: hour 24 -> -1"
        _ = assert int equals (time parse iso8601 "2026-01-01T00:60:00Z") (0 - 1) "AC2: minute 60 -> -1"
        _ = assert int equals (time parse iso8601 "2026-01-01T00:00:60Z") (0 - 1) "AC2: second 60 -> -1"
        _ = assert int equals (time parse iso8601 "malformed") (0 - 1) "AC2: malformed -> -1"
        ()

-- 2. Human duration formatting and bounded exponential backoff
-- @tests TS-TIME-001
fn :: test durations and backoff => ()
      test durations and backoff =
        _ = assert str eq (time format duration ms 0) "0ms" "AC3: 0ms"
        _ = assert str eq (time format duration ms (0 - 50)) "0ms" "AC3: negative ms -> 0ms"
        _ = assert str eq (time format duration ms 450) "450ms" "AC3: 450ms"
        _ = assert str eq (time format duration ms 1000) "1s" "AC3: exact 1s omits 0ms"
        _ = assert str eq (time format duration ms 60000) "1m" "AC3: exact 1m"
        _ = assert str eq (time format duration ms 3600000) "1h" "AC3: exact 1h"
        _ = assert str eq (time format duration ms 3661005) "1h 1m 1s 5ms" "AC3: 1h 1m 1s 5ms"

        _ = assert int equals (time backoff ms (0 - 1) 100 5000) 100 "AC3: negative attempt -> base_ms"
        _ = assert int equals (time backoff ms 0 100 5000) 100 "AC3: attempt 0 -> 100"
        _ = assert int equals (time backoff ms 1 100 5000) 200 "AC3: attempt 1 -> 200"
        _ = assert int equals (time backoff ms 3 100 5000) 800 "AC3: attempt 3 -> 800"
        _ = assert int equals (time backoff ms 10 100 5000) 5000 "AC3: clamped at max_ms 5000"
        _ = assert int equals (time backoff ms 3 0 5000) 0 "AC3: base_ms <= 0 -> 0"
        _ = assert int equals (time backoff ms 3 500 200) 500 "AC3: max_ms <= base_ms -> base_ms"
        ()

-- @tests TS-TIME-001
fn :: main => ()
      main =
        _ = test utc calendar and iso8601
        _ = test durations and backoff
        echo "[PASS] test time: TS-TIME-001 passed"
