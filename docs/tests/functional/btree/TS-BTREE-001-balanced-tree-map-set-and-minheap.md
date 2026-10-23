---
id: TS-BTREE-001
title: Verify O(log N) balanced binary search tree Map, Set, and MinHeap priority queue
level: unit
covers: [FR-BTREE-001, API-BTREE-001]
status: planned
automated_in: []
---
# TS-BTREE-001 — Verify O(log N) balanced binary search tree Map, Set, and MinHeap priority queue

## Preconditions / fixtures
- Pure-Ridgun `btree` and `test` modules (`src/main/ridgun/lib/btree.rg`, `src/main/ridgun/lib/test.rg`).

## Steps / inputs
1. Insert ascending, descending, and mixed keys into `BTreeMap` via `btree put`; verify `btree height` stays logarithmic, `btree get`/`btree has`/`btree remove` work, and `btree keys` is sorted.
2. Construct `BTreeSet` instances and verify `bset add`, `bset remove`, `bset union`, `bset intersect`, and `bset diff`.
3. Push unordered `(priority_score, val)` pairs into `MinHeap` via `heap push` and verify `heap peek` and `heap pop` extract in ascending priority order.

## Expected results (map to acceptance criteria)
- AC1 → `BTreeMap` maintains AVL balance and sorted key order across insertions, updates, and deletions.
- AC2 → `BTreeSet` set algebra operations return exact sorted sets.
- AC3 → `MinHeap` dequeues lowest `priority_score` items first.

## Not covered here (to avoid duplication)
- Linear list KV helpers (`TS-LIST-001`).
