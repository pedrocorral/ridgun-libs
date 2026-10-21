---
id: TS-LIST-001
title: Verify list indexing, slicing, range generation, deduplication, mergesort, and associative key-value map operations
level: unit
covers: [FR-LIST-001, API-LIST-001]
status: automated
automated_in: [src/test/ridgun/test_list.rg]
---
# TS-LIST-001 — Verify list indexing, slicing, range generation, deduplication, mergesort, and associative key-value map operations

## Preconditions / fixtures
- Pure-Ridgun `list` module (`src/main/ridgun/lib/list.rg`).

## Steps / inputs
1. Call `list len`, `list nth`, `list nth or`, `list take`, `list drop`, `list slice`, `list reverse`, `list range`, `list range step` (positive, negative, and `0` step), `list replicate`, `list contains`, `list index of`, `list count`, and `list dedup` (plus `[String]` variants).
2. Call `list sort`, `list str sort`, and `list is sorted` on unsorted, reverse-sorted, duplicate-containing, single-element, and empty lists.
3. Call `kv empty`, `kv put`, `kv get`, `kv get or`, `kv has`, `kv remove`, `kv keys`, `kv values`, and `kv merge` across insertions, updates, and deletions.

## Expected results (map to acceptance criteria)
- AC1 → List indexing, slicing, range generation, search, and deduplication return exact results and handle out-of-bounds/zero-step inputs safely.
- AC2 → `list sort` and `list str sort` produce ascending sorted lists verified by `list is sorted`.
- AC3 → Associative `kv_*` map functions preserve insertion order, overwrite existing keys without duplication, and merge maps deterministically.

## Not covered here (to avoid duplication)
- Statistical aggregations (`math sum`, `math median`) are covered in `TS-MATH-001`.
