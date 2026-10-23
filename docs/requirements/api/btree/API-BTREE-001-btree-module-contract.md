---
id: API-BTREE-001
title: Public module contract for btree (btree.rglib / libbtree.so)
status: approved
implements: [FR-BTREE-001]
auth: none
---
# API-BTREE-001 — Public module contract for `btree` (`btree.rg`)

## Request
- Imported via `import btree`.
- Public Types (see `DM-Btree`):
  - `type BTreeMap = BMapEmpty | BMapNode String String Int BTreeMap BTreeMap`
  - `type BTreeSet = BSetEmpty | BSetNode String Int BTreeSet BTreeSet`
  - `type MinHeap = HeapEmpty | HeapNode Int String Int MinHeap MinHeap`
- Ordered Map (`BTreeMap` — $O(\log N)$):
  - `btree empty => BTreeMap`
  - `btree put BTreeMap String String => BTreeMap`
  - `btree get BTreeMap String => String`
  - `btree get or BTreeMap String String => String`
  - `btree has BTreeMap String => Bool`
  - `btree remove BTreeMap String => BTreeMap`
  - `btree size BTreeMap => Int`
  - `btree height BTreeMap => Int`
  - `btree keys BTreeMap => [String]`
  - `btree values BTreeMap => [String]`
  - `btree to list BTreeMap => [(String, String)]`
  - `btree from list [(String, String)] => BTreeMap`
- Ordered Set (`BTreeSet` — $O(\log N)$):
  - `bset empty => BTreeSet`
  - `bset add BTreeSet String => BTreeSet`
  - `bset has BTreeSet String => Bool`
  - `bset remove BTreeSet String => BTreeSet`
  - `bset size BTreeSet => Int`
  - `bset to list BTreeSet => [String]`
  - `bset from list [String] => BTreeSet`
  - `bset union BTreeSet BTreeSet => BTreeSet`
  - `bset intersect BTreeSet BTreeSet => BTreeSet`
  - `bset diff BTreeSet BTreeSet => BTreeSet`
- Priority Queue (`MinHeap` — $O(\log N)$):
  - `heap empty => MinHeap`
  - `heap push MinHeap Int String => MinHeap`
  - `heap peek MinHeap => (Int, String)`
  - `heap pop MinHeap => (Int, String, MinHeap)`
  - `heap size MinHeap => Int`

## Responses
| Code | When | Body |
|---|---|---|
| `BTreeMap` / `BTreeSet` / `MinHeap` | Structural updates | Rebalanced persistent tree or leftist min-heap |
| `[String]` / `[(String, String)]` | Traversals | Strictly sorted in-order keys or entries |

## Rules
- All AVL rotations preserve $|h(left) - h(right)| \le 1$.
