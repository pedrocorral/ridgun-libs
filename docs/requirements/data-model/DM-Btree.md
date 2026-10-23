---
id: DM-Btree
title: Balanced binary search tree (Map/Set) and MinHeap priority queue models
status: approved
related: [FR-BTREE-001, API-BTREE-001, ADR-0002]
---
# DM-Btree — Balanced binary search tree (Map/Set) and MinHeap priority queue models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| tree_height | Int | `>= 0` | Cached AVL subtree height maintaining balance factor in `[-1, 1]` |
| priority_score | Int | Any `Int` | Numeric priority key in `MinHeap` (lowest score dequeued first) |

## Relations
- Used by `btree.rg` (`BTreeMap`, `BTreeSet`, `MinHeap`) for $O(\log N)$ ordered key-value lookup, set operations, and priority scheduling.

## Invariants
- Every `BTreeMap` and `BTreeSet` rotation (`LL`, `LR`, `RL`, `RR`) preserves strict in-order key sorting and height difference $\le 1$ between left and right subtrees.
- Every `MinHeap` node has `priority_score` $\le$ its children's priority scores.

## Lifecycle
- Persistent functional data structures allocated and rebalanced in `RMM1`/`RMM2` regions.
