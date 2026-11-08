---
id: FR-LIST-002
title: Sort lists by Int or String keys and count or group elements by a String key
type: functional
status: implemented
priority: must
domain: LIST
depends_on: [FR-HASHMAP-001]
related: [ADR-0009, FR-LIST-001]
tests: [TS-LIST-002]
---
# FR-LIST-002 — Sort lists by Int or String keys and count or group elements by a String key

## Statement
The `list` lib SHALL provide:
- `list sort ints [Int] => [Int]`: ascending.
- `list sort texts [String] => [String]`: ascending byte order.
- `list sort by int [A] (A => Int) => [A]`: ascending by key, stable.
- `list sort by text [A] (A => String) => [A]`: ascending byte order of the key, stable.
- `list count by [A] (A => String) => [String Int]`: how many elements have each key.
- `list group by [A] (A => String) => [String [A]]`: the elements of each key, in their original order.

`count by` and `group by` list the keys in order of first appearance. The `by` functions call the key function once per element.

## Rationale
Solstice groups, counts and sorts large lists by key (request `2026-11-07-comparar-textos-y-mapa-hash.md`).

## Acceptance criteria
- AC1: Given lists of `Int` with negative values, the minimum and maximum `Int`, and repeats, when `list sort ints` is called, then the result is ascending and has the same elements.
- AC2: Given lists of `String` with bytes >= 128, the empty string, keys of 10 KB and repeats, when `list sort texts` is called, then the result is in byte order (the order of `<`).
- AC3: Given elements with equal keys, when `list sort by int` or `list sort by text` is called, then those elements keep their original order.
- AC4: Given a list, when `list count by` and `list group by` are called, then each key appears once, in order of first appearance, with its count or its elements in original order; the counts add up to the list length.
- AC5: Given empty lists, when any of these functions is called, then the result is `[]`.
- AC6: Given 100,000 elements on x86_64, when sorting, then `list sort ints` takes under 50 ms and `list sort by int` on records under 100 ms.

## Actors & permissions
- Any Ridgun program or lib that imports `list`.

## Constraints & edge cases
- The sorts use the native `sort by ints` and `sort by texts` (ridgunc 0.9.44), which are stable and use the order of `<`.
- Measured with ridgunc 0.9.44, 100,000 elements: `sort ints` 5 ms, `sort by int` on records 22 ms, `sort texts` 92 ms, `count by` 116 ms.

## Data & privacy
- In-memory only.

## Security & observability notes
- `count by` and `group by` use `hashmap`, which mitigates `VUL-INPUT-001` against chosen colliding keys.

## Out of scope
- Descending order: reverse the result, or negate an `Int` key.
