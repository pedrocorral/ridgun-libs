---
id: TS-LIST-001
title: Verify list indexing, slicing, range generation, deduplication, mergesort, and associative key-value map operations
level: unit
covers: [FR-LIST-001, API-LIST-001]
status: automated
automated_in: [src/test/ridgun/test list.rg]
---
# TS-LIST-001 — Verify list indexing, slicing, range generation, deduplication, mergesort, and associative key-value map operations

## Preconditions / fixtures
- Pure-Ridgun `list` and `agent` modules (`src/main/ridgun/lib/list.rg`, `src/main/ridgun/lib/agent.rg`).

## Steps / inputs
1. Call `list len`, `list nth`, `list nth or`, `list take`, `list drop`, `list slice`, `list reverse`, `list range`, `list range step` (positive, negative, and `0` step), `list replicate`, `list contains`, `list index of`, `list count`, and `list dedup` (plus `[String]` variants).
2. Call `list sort`, `list str sort`, and `list is sorted` on unsorted, reverse-sorted, duplicate-containing, single-element, and empty lists.
3. Import both `list` and `agent` in the same test module (`RG-066`) and call `list kv empty`, `list kv len`, `list kv put`, `list kv get`, `list kv get or`, `list kv has`, `list kv remove`, `list kv keys`, `list kv values`, and `list kv merge` alongside `agent kv put` / `agent kv get` across insertions, updates, and deletions.

## Expected results (map to acceptance criteria)
- AC1 → List indexing, slicing, range generation, search, and deduplication return exact results and handle out-of-bounds/zero-step inputs safely.
- AC2 → `list sort` and `list str sort` produce ascending sorted lists verified by `list is sorted`.
- AC3 → Associative `list kv *` map functions compile cleanly alongside `import agent` (`RG-066`), preserve insertion order, overwrite existing keys without duplication, and merge maps deterministically.

## Not covered here (to avoid duplication)
- Statistical aggregations (`math sum`, `math median`) are covered in `TS-MATH-001`.
