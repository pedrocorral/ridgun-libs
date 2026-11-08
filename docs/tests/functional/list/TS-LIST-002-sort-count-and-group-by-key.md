---
id: TS-LIST-002
title: Verify sorting by Int and String keys, stability, and counting and grouping by key
level: unit
covers: [FR-LIST-002, API-LIST-001]
status: automated
automated_in: [src/test/ridgun/test list.rg]
---
# TS-LIST-002 — Verify sorting by Int and String keys, stability, and counting and grouping by key

## Preconditions / fixtures
- `list` and `hashmap` libs (`src/main/ridgun/lib/list.rg`, `src/main/ridgun/lib/hashmap.rg`).

## Steps / inputs
1. `list sort ints` on `[]`, one element, repeats, negative values and the minimum and maximum `Int`.
2. `list sort texts` on `[]`, the empty string, strings with bytes >= 128, a 10 KB string and repeats.
3. `list sort by int` and `list sort by text` on records with equal keys; count key function calls.
4. `list count by` and `list group by` on `[]`, an empty key, keys with bytes >= 128, a 10 KB key and repeats.
5. Sort 100,000 generated `Int` values and 100,000 records by an `Int` key and check order and length.

## Expected results (map to acceptance criteria)
- AC1 → step 1 gives ascending lists with the same elements.
- AC2 → step 2 gives byte order.
- AC3 → step 3 keeps the original order of equal keys and calls the key function once per element.
- AC4 → step 4 gives keys in first-appearance order, counts that add up to the length, and elements in original order.
- AC5 → `[]` for every function in steps 1–4.
- AC6 → step 5 is sorted and keeps every element. The times are checked by the benchmark in the task log, not by the suite.

## Not covered here (to avoid duplication)
- The hashmap itself is covered in `TS-HASHMAP-001`.
