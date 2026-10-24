---
id: FR-LIST-001
title: Provide pure-Ridgun list slicing, searching, deduplication, O(N log N) mergesort, and associative key-value map utilities
type: functional
status: implemented
priority: must
domain: LIST
depends_on: []
related: [ADR-0002, VUL-INPUT-001]
tests: [TS-LIST-001]
---
# FR-LIST-001 — Provide pure-Ridgun list slicing, searching, deduplication, O(N log N) mergesort, and associative key-value map utilities

## Statement
The `list` library SHALL provide pure-Ridgun operations over `[Int]` and `[String]` lists (`list len`, `list str len`, `list is empty`, `list str is empty`, `list nth`, `list nth or`, `list str nth`, `list str nth or`, `list head`, `list last`, `list take`, `list str take`, `list drop`, `list str drop`, `list slice`, `list str slice`, `list reverse`, `list str reverse`, `list range`, `list range step`, `list replicate`, `list contains`, `list str contains`, `list index of`, `list str index of`, `list count`, `list str count`, `list dedup`, `list str dedup`, `list sort`, `list str sort`, `list is sorted`), together with associative `[(String, String)]` key-value map operations (`kv empty`, `kv len`, `kv has`, `kv get`, `kv get or`, `kv put`, `kv remove`, `kv keys`, `kv values`, `kv merge`).

## Rationale
Ridgun's compiler provides `map`, `filter`, `fold`, and list cons/concat (`:`, `::`), while applications need standard indexing, slicing, deduplication, $O(N \log N)$ sorting, and associative key-value maps without reimplementing them per module.

## Acceptance criteria
- AC1: Given `[Int]` and `[String]` lists, when indexing, slicing, reversal, range generation (`list range`, `list range step`, `list replicate`), searching (`list contains`, `list index of`, `list count`), and deduplication (`list dedup`, `list str dedup`) are called, then they return exact results and clamp out-of-bounds indices/steps safely without panicking or infinite looping.
- AC2: Given unsorted `[Int]` and `[String]` lists, when `list sort` and `list str sort` are called, then they return deterministically sorted ascending lists in $O(N \log N)$ time using bottom-up/top-down mergesort, and `list is sorted` returns `True`.
- AC3: Given associative `[(String, String)]` key-value maps, when `kv put`, `kv get`, `kv get or`, `kv has`, `kv remove`, `kv keys`, `kv values`, and `kv merge` are called, then `kv put` updates existing keys in-place without duplicating keys, `kv remove` removes matching keys, and `kv merge` combines two maps with right-hand precedence.

## Actors & permissions
- Any Ridgun program or lib importing `list`.

## Constraints & edge cases
- `list range step start end 0` returns `[]` rather than looping infinitely.
- `list nth` / `list str nth` on negative or out-of-bounds indices returns `0` / `""` (or `default_val` for `*_or`).

## Data & privacy
- Pure in-memory list and tuple transformations.

## Security & observability notes
- Mitigates `VUL-INPUT-001` by guarding `list range step` against `step == 0` and bounding negative counts/indices in `take`, `drop`, `slice`, and `replicate`.

## Out of scope
- Mutable hash tables backed by raw pointers.
