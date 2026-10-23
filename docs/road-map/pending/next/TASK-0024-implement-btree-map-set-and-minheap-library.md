---
id: TASK-0024
title: Implement btree.rg O(log N) balanced tree Map, Set, and MinHeap priority queue library
status: pending
priority: must
owner: unassigned
implements: [FR-BTREE-001, API-BTREE-001, DM-Btree]
tests: [TS-BTREE-001]
mitigates: [VUL-INPUT-001]
depends_on: []
scope:
  - src/main/ridgun/lib/btree.rg
  - src/test/ridgun/test btree.rg
  - build.rg
context_files:
  - docs/requirements/functional/btree/FR-BTREE-001-balanced-tree-map-set-and-minheap.md
  - docs/requirements/api/btree/API-BTREE-001-btree-module-contract.md
---
# TASK-0024 — Implement `btree.rg` $O(\log N)$ balanced tree Map, Set, and `MinHeap` priority queue library

## Goal
Implement pure-Ridgun `btree.rg` (`BTreeMap`, `BTreeSet`, `MinHeap`), `test btree.rg`, and `.rglib`/`.so` bundles.
