#!/usr/bin/env python3
"""Writes tests/test_time.rg. Expected values come from Python's datetime (proleptic Gregorian, UTC), the calendar
time's contract names (docs/requirements/functional/time/FR-TIME-001, API-TIME-001: epochs in seconds, day of week
0 = Sunday, parse gives -1 for malformed or out-of-range input, durations and backoff in milliseconds)."""
import calendar, datetime as dt, os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rg_strict import strict

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "test_time.rg")
EPOCH = dt.datetime(1970, 1, 1, tzinfo=dt.timezone.utc)


def neg(n):
    return f"(0 - {-n})" if n < 0 else str(n)


checks = []
add = checks.append

# Dates around every rule: the epoch, before it, leap days of century years (1600, 2000 leap; 1700, 1900, 2100 not),
# month ends, 2038-01-19 (32-bit limit) and after, and year 9999.
DATES = [(1970, 1, 1, 0, 0, 0), (1969, 12, 31, 23, 59, 58), (1969, 12, 31, 0, 0, 0), (1900, 1, 1, 0, 0, 0), (1900, 3, 1, 12, 0, 0),
         (1600, 2, 29, 0, 0, 0), (1700, 3, 1, 0, 0, 0), (1601, 1, 1, 0, 0, 0), (2000, 2, 29, 23, 59, 59), (2000, 3, 1, 0, 0, 0),
         (2024, 2, 29, 6, 7, 8), (2023, 12, 31, 23, 59, 59), (2026, 10, 24, 18, 30, 0), (2038, 1, 19, 3, 14, 7), (2038, 1, 19, 3, 14, 8),
         (2100, 2, 28, 0, 0, 0), (2100, 3, 1, 0, 0, 0), (2400, 2, 29, 0, 0, 0), (9999, 12, 31, 23, 59, 59), (1, 1, 1, 0, 0, 0)]
for d in DATES:
    t = dt.datetime(*d, tzinfo=dt.timezone.utc)
    e = int((t - EPOCH).total_seconds())
    iso = "%04d-%02d-%02dT%02d:%02d:%02dZ" % d
    add('lt_int "time_utc_to_epoch %s" (time_utc_to_epoch %d %d %d %d %d %d) %s' % (iso, *d, neg(e)))
    add('lt_eq "time_epoch_to_utc %s gives the fields of %s" (time_t_fields (time_epoch_to_utc %s)) "%s"' % (neg(e).replace('"', ''), iso, neg(e), "%d %d %d %d %d %d" % d))
    add('lt_eq "time_format_iso8601 %s" (time_format_iso8601 %s) "%s"' % (neg(e), neg(e), iso))
    if e != -1:
        add('lt_int "time_parse_iso8601 %s" (time_parse_iso8601 "%s") %s' % (iso, iso, neg(e)))
    add('lt_int "time_day_of_week %04d-%02d-%02d (0 = Sunday)" (time_day_of_week %d %d %d) %d' % (d[0], d[1], d[2], d[0], d[1], d[2], (t.weekday() + 1) % 7))

for y in [1600, 1700, 1800, 1900, 2000, 2004, 2023, 2024, 2100, 2400]:
    add('lt_%s "time_is_leap_year %d" (time_is_leap_year %d)' % ("true" if calendar.isleap(y) else "false", y, y))
    add('lt_int "time_days_in_month %d 2" (time_days_in_month %d 2) %d' % (y, y, calendar.monthrange(y, 2)[1]))
for m in range(1, 13):
    add('lt_int "time_days_in_month 2026 %d" (time_days_in_month 2026 %d) %d' % (m, m, calendar.monthrange(2026, m)[1]))
add('lt_int "time_days_in_month 2026 13 is 0" (time_days_in_month 2026 13) 0')
add('lt_int "time_days_in_month 2026 0 is 0" (time_days_in_month 2026 0) 0')

# Impossible dates and malformed text give -1 (FR-TIME-001); Python's datetime refuses each date too.
for name, s in [("29 February of a common year", "2026-02-29T00:00:00Z"), ("29 February 1900 (century, not leap)", "1900-02-29T00:00:00Z"),
                ("31 April", "2026-04-31T00:00:00Z"), ("month 13", "2026-13-01T00:00:00Z"), ("month 0", "2026-00-10T00:00:00Z"), ("day 0", "2026-01-00T00:00:00Z"),
                ("hour 24", "2026-01-01T24:00:00Z"), ("minute 60", "2026-01-01T00:60:00Z"), ("second 60", "2026-01-01T00:00:60Z"),
                ("missing seconds", "2026-01-01T00:00Z"), ("one-digit month", "2026-1-01T00:00:00Z"), ("letters", "2026-0a-01T00:00:00Z"),
                ("trailing text", "2026-01-01T00:00:00Zjunk"), ("empty", ""), ("a negative sign inside", "2026-01--1T00:00:00Z")]:
    add('lt_int "time_parse_iso8601 refuses %s" (time_parse_iso8601 "%s") (0 - 1)' % (name, s))
add('lt_int "time_utc_to_epoch refuses 31 April (-1)" (time_utc_to_epoch 2026 4 31 0 0 0) (0 - 1)')
add('lt_int "time_utc_to_epoch refuses 29 February 2100 (-1)" (time_utc_to_epoch 2100 2 29 0 0 0) (0 - 1)')

# Every second of a day boundary and a leap day survives format → parse → format.
add('lt_true "format then parse gives the epoch back for 10 000 epochs spread over 1601..2400" (time_t_round_trips (0 - 11644473600) 2522880000 0)')

# Durations (ms) and backoff (FR-TIME-001: "1h 1m 1s 5ms", zero parts left out, <= 0 is "0ms"; backoff base·2^attempt within [base, max]).
for ms, want in [(0, "0ms"), (-5, "0ms"), (1, "1ms"), (1000, "1s"), (60000, "1m"), (3661005, "1h 1m 1s 5ms"), (86400000, "24h"), (3600001, "1h 1ms")]:
    add('lt_eq "time_format_duration_ms %d" (time_format_duration_ms %s) "%s"' % (ms, neg(ms), want))
for a, base, mx, want in [(0, 100, 10000, 100), (3, 100, 10000, 800), (7, 100, 10000, 10000), (62, 100, 10000, 10000), (63, 100, 10000, 10000), (200, 100, 10000, 10000)]:
    add('lt_int "time_backoff_ms attempt %d base %d max %d (no overflow for large attempts)" (time_backoff_ms %d %d %d) %d' % (a, base, mx, a, base, mx, want))

body = "\n".join(f"        c{i} = {c}" for i, c in enumerate(checks))
names = ", ".join(f"c{i}" for i in range(len(checks)))
src = f'''-- test_time.rg — time against its contract (FR-TIME-001, API-TIME-001) on the edges of the proleptic Gregorian
-- calendar: before 1970, century years, 29 February, 2038 and after, year 1 and 9999, impossible dates.
-- Generated by tests/gen/make_time.py; Python's datetime gives every expected value.

import test
import str
import time
import lt

fn :: time_t_fields (Int Int Int Int Int Int) => String
      time_t_fields (y, mo, d, h, mi, s) =  (int_to_str y) + " " + (int_to_str mo) + " " + (int_to_str d) + " " + (int_to_str h) + " " + (int_to_str mi) + " " + (int_to_str s)

-- 10 000 epochs from `start`, `span` / 10 000 apart, plus an odd number of seconds so times of day vary.
fn :: time_t_round_trips Int Int Int => Bool
      time_t_round_trips start span i =
        | i >= 10000 = True
        | not (time_t_one (start + (i * (span / 10000)) + (i * 7919) % 86400)) = False
        | otherwise  = time_t_round_trips start span (i + 1)

fn :: time_t_one Int => Bool
      time_t_one e =  e == (0 - 1) or ((time_parse_iso8601 (time_format_iso8601 e)) == e)

fn :: main => ()
      main =
{body}
        lt_done "time" [{names}]
'''
open(OUT, "w").write(strict(src))
print(f"wrote {OUT}: {len(checks)} checks")
