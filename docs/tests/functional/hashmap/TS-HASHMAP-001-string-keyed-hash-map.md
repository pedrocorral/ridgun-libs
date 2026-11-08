---
id: TS-HASHMAP-001
title: Verify hashmap put, get, has, add, size and pairs, including unusual keys and growth
level: unit
covers: [FR-HASHMAP-001, API-HASHMAP-001]
status: automated
automated_in: [src/test/ridgun/test hashmap.rg]
---
# TS-HASHMAP-001 — Verify hashmap put, get, has, add, size and pairs, including unusual keys and growth

## Preconditions / fixtures
- `hashmap` lib (`src/main/ridgun/lib/hashmap.rg`).

## Steps / inputs
1. `get`, `has`, `size` and `pairs` on `hashmap empty`.
2. `put` three keys, put one again with a new value; read them back; read a missing key.
3. `add` on new and existing keys of a `HashMap Int`.
4. Put the empty key, keys with bytes >= 128, a 10 KB key, and two 10 KB keys that differ in the last byte.
5. Put records as values and read them back.
6. Insert 20,000 keys (several growths), then read every key and sum the values from `pairs`.
7. Define a program function named like a record field (`fill`, `count`) and use the map.

## Expected results (map to acceptance criteria)
- AC1 → steps 1, 2 and 6: defaults for missing keys, the latest value for each key, one pair per key in first-insertion order.
- AC2 → step 3: a missing key starts at 0; values are sums.
- AC3 → step 4: each unusual key keeps its own value.
- AC4 → step 5: records come back unchanged.
- AC5 → the time is checked by the benchmark in the task log, not by the suite.

## Not covered here (to avoid duplication)
- `list count by` and `list group by` are covered in `TS-LIST-002`.
