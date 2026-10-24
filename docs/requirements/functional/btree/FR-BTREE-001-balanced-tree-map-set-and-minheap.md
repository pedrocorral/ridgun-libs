---
id: FR-BTREE-001
title: Provide O(log N) balanced binary search tree Map, Set, and MinHeap priority queue
type: functional
status: implemented
priority: must
domain: BTREE
depends_on: []
related: [ADR-0002, DM-Btree, API-BTREE-001, VUL-INPUT-001]
tests: [TS-BTREE-001]
---
# FR-BTREE-001 — Provide O(log N) balanced binary search tree Map, Set, and MinHeap priority queue

## Statement
The `btree` library SHALL provide persistent $O(\log N)$ AVL-balanced ordered maps (`btree empty`, `btree put`, `btree get`, `btree get or`, `btree has`, `btree remove`, `btree size`, `btree keys`, `btree values`, `btree to list`, `btree from list`), ordered sets (`bset empty`, `bset add`, `bset has`, `bset remove`, `bset union`, `bset intersect`, `bset diff`, `bset to list`), and priority queues (`heap empty`, `heap push`, `heap peek`, `heap pop`, `heap size`).

## Rationale
Large collections and scheduling algorithms require guaranteed logarithmic lookup, insertion, deletion, and priority extraction instead of $O(N)$ list scans.

## Acceptance criteria
- AC1: Given sequential or random insertions into `BTreeMap`, when `btree put`, `btree get`, `btree remove`, and `btree keys` are called, then all lookups complete in $O(\log N)$, tree height remains balanced ($\le 1.44 \log_2(N+2)$), and `btree keys` returns keys in strict ascending order.
- AC2: Given two `BTreeSet` collections, when `bset union`, `bset intersect`, and `bset diff` are called, then they return sorted duplicate-free sets matching mathematical set semantics.
- AC3: Given items pushed with integer priorities into `MinHeap`, when `heap peek` and `heap pop` are called repeatedly, then items are extracted in non-decreasing order of `priority_score`.

## Actors & permissions
- Any Ridgun program or lib importing `btree`.

## Constraints & edge cases
- Updating an existing key in `BTreeMap` replaces its value without increasing `btree size`.

## Data & privacy
- Immutable persistent trees in `RMM1`/`RMM2` regions.

## Security & observability notes
- Mitigates hash-flooding DoS (`VUL-INPUT-001`) by guaranteeing worst-case $O(\log N)$ tree height regardless of key distribution.

## Out of scope
- Disk-backed B+Tree page files.
