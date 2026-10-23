---
id: TS-STR-001
title: Verify string searching, trimming, replacement, splitting, case conversion, and padding utilities
level: unit
covers: [FR-STR-001, API-STR-001]
status: automated
automated_in: [src/test/ridgun/test str.rg]
---
# TS-STR-001 — Verify string searching, trimming, replacement, splitting, case conversion, and padding utilities

## Preconditions / fixtures
- Pure-Ridgun `str` module (`src/main/ridgun/lib/str.rg`).

## Steps / inputs
1. Call `str_index_of "hello world" "world"` (`6`), `str_index_of "hello" "xyz"` (`-1`), and `str_index_of "abc" ""` (`0`), plus space-separated `str index of`.
2. Call `str_trim "  \thi\n\r "` (`"hi"`), `str_replace "a-b-c" "-" "_"` (`"a_b_c"`), `str_replace "abc" "" "x"` (`"abc"`), `str_split "a,b,c" ","` (`["a", "b", "c"]`), and `str_split "a,,b" ","` (`["a", "", "b"]`).
3. Call `str_to_upper "Abc! 123"` (`"ABC! 123"`), `str_to_lower "Abc! 123"` (`"abc! 123"`), `str join ["a", "b", "c"] "-"`, `str repeat "ab" 3`, `str_repeat "x" 8000000` (`str_len == 8000000` per `RG-052`), `str pad left "7" 3 "0"`, and `str pad right "7" 3 "0"`.

## Expected results (map to acceptance criteria)
- AC1 → `str_index_of` returns exact 0-based index or `-1` when absent.
- AC2 → `str_trim`, `str_replace`, and `str_split` match all `RG-010` assertions and edge cases.
- AC3 → `str_to_upper`, `str_to_lower`, `str join`, `str repeat`, `str pad left`, and `str pad right` produce exact formatted results.

## Not covered here (to avoid duplication)
- see `TS-IO-002` for file-based line reading/writing.
