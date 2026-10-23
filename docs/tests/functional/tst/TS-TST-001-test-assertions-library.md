---
id: TS-TST-001
title: Verify RG-011 test assertion library with message-annotated and concise assertion helpers
level: unit
covers: [FR-TST-001, API-TST-001]
status: automated
automated_in: [src/test/ridgun/test test.rg]
---
# TS-TST-001 — Verify RG-011 test assertion library with message-annotated and concise assertion helpers

## Preconditions / fixtures
- Pure-Ridgun `test` module (`src/main/ridgun/lib/test.rg`).

## Steps / inputs
1. Call `assert_equals 4 4 "math"`, `assert_equals "ok" "ok" "str"`, `assert_true (1 < 2) "lt"`, and `assert_false (1 > 2) "gt"` and verify they return `()` cleanly.
2. Call non-exiting predicate checks `check eq 1 2` (`False`), `check eq 2 2` (`True`), `check true False` (`False`), and `check true True` (`True`) to verify failure detection logic.
3. Call 2-argument `assert eq 10 10`, `assert str eq "a" "a"`, and 1-argument `assert ok True`, `assert false False` and verify backward compatibility across existing test suites.

## Expected results (map to acceptance criteria)
- AC1 → `assert_equals` (3-arg) and `assert_true` / `assert_false` (2-arg) succeed when conditions hold.
- AC2 → Non-matching assertions are detected accurately and failure diagnostics format the label.
- AC3 → Concise 2-arg/1-arg assertion helpers (`assert eq`, `assert str eq`, `assert ok`, `assert false`) continue working seamlessly.

## Not covered here (to avoid duplication)
- see domain test specs (`TS-SOCK-*`, `TS-CRYPTO-*`, `TS-POSIX-*`, `TS-IO-*`, `TS-STR-*`) for domain-specific assertions.
