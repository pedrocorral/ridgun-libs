-- ============================================================
-- src/test/ridgun/test time.rg
-- Automated test suite for time.rg (TS-TIME-001)
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

-- @tests TS-TIME-001
fn :: test utc calendar and iso8601 => ()
      test utc calendar and iso8601 =
        _   = assert true (time is leap year 2000) "2000 leap"
        _   = assert false (time is leap year 1900) "1900 not leap"
        _   = assert true (time is leap year 2024) "2024 leap"
        _   = assert false (time is leap year 2026) "2026 not leap"
        _   = assert int equals (time days in month 2024 2) 29 "Feb 2024 == 29"
        _   = assert int equals (time days in month 2026 2) 28 "Feb 2026 == 28"
        _   = assert int equals (time days in month 2026 4) 30 "Apr == 30"
        _   = assert int equals (time days in month 2026 10) 31 "Oct == 31"
        _   = assert int equals (time day of week 1970 1 1) 4 "1970-01-01 was Thursday (4)"
        _   = assert int equals (time utc to epoch 1970 1 1 0 0 0) 0 "Unix epoch 0"
        _   = assert str eq (time format iso8601 0) "1970-01-01T00:00:00Z" "format epoch 0"
        ts  = time utc to epoch 2026 10 22 10 20 0
        iso = time format iso8601 ts
        _   = assert str eq iso "2026-10-22T10:20:00Z" "format 2026-10-22T10:20:00Z"
        _   = assert int equals (time parse iso8601 iso) ts "parse roundtrip"
        tup = time epoch to utc ts
        _   = assert int equals (utc y tup) 2026 "year 2026"
        _   = assert int equals (utc m tup) 10 "month 10"
        _   = assert int equals (utc d tup) 22 "day 22"
        _   = assert int equals (utc hh tup) 10 "hour 10"
        -- Negative validation
        _   = assert int equals (time parse iso8601 "2026-13-01T00:00:00Z") (0 - 1) "invalid month 13 -> -1"
        _   = assert int equals (time parse iso8601 "2026-02-29T00:00:00Z") (0 - 1) "2026-02-29 non-leap -> -1"
        _   = assert int equals (time parse iso8601 "malformed") (0 - 1) "malformed -> -1"
        ()

-- @tests TS-TIME-001
fn :: test durations and backoff => ()
      test durations and backoff =
        _ = assert str eq (time format duration ms 0) "0ms" "0ms"
        _ = assert str eq (time format duration ms 450) "450ms" "450ms"
        _ = assert str eq (time format duration ms 3661005) "1h 1m 1s 5ms" "1h 1m 1s 5ms"
        _ = assert int equals (time backoff ms 0 100 5000) 100 "attempt 0 -> 100"
        _ = assert int equals (time backoff ms 3 100 5000) 800 "attempt 3 -> 800"
        _ = assert int equals (time backoff ms 10 100 5000) 5000 "clamped at max ms 5000"
        ()

fn :: main => ()
      main =
        _ = test utc calendar and iso8601
        _ = test durations and backoff
        echo "[PASS] test time: TS-TIME-001 passed"
