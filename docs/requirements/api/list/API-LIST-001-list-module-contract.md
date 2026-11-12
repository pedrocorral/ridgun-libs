---
id: API-LIST-001
title: Public lib contract for list (list.ridgunlib / liblist.so)
status: approved
implements: [FR-LIST-001, FR-LIST-002]
auth: none
---
# API-LIST-001 — Public lib contract for `list` (`list.ridgun`)

## Request
- Imported via `import list`.
- List Inspection, Slicing & Generation:
  - Generic, from the compiler prelude (`ADR-0012`): `list len [A] => Int`, `list nth or [A] Int A => A`, `list last or [A] A => A`, `list take [A] Int => [A]`, `list drop [A] Int => [A]`, `list reverse [A] => [A]`, `list contains [A] A => Bool`
  - `list str len [String] => Int`, `list is empty [Int] => Bool`, `list str is empty [String] => Bool`
  - `list nth [Int] Int => Int`, `list str nth [String] Int => String`, `list str nth or [String] Int String => String`, `list head [Int] Int => Int`, `list last [Int] Int => Int`
  - `list str take [String] Int => [String]`, `list str drop [String] Int => [String]`, `list slice [Int] Int Int => [Int]`, `list str slice [String] Int Int => [String]`
  - `list str reverse [String] => [String]`, `list range Int Int => [Int]`, `list range step Int Int Int => [Int]`, `list replicate Int Int => [Int]`
- Search, Deduplication & Sorting:
  - `list str contains [String] String => Bool`, `list index of [Int] Int => Int`, `list str index of [String] String => Int`, `list count [Int] Int => Int`, `list str count [String] String => Int`
  - `list dedup [Int] => [Int]`, `list str dedup [String] => [String]`, `list sort [Int] => [Int]`, `list str sort [String] => [String]`, `list is sorted [Int] => Bool`
- Sorting, Counting & Grouping by Key (`FR-LIST-002`):
  - `list sort ints [Int] => [Int]`, `list sort texts [String] => [String]` (byte order)
  - `list sort by int [A] (A => Int) => [A]`, `list sort by text [A] (A => String) => [A]` (stable; the key function is called once per element)
  - `list count by [A] (A => String) => [String Int]`, `list group by [A] (A => String) => [String [A]]` (keys in order of first appearance; elements in original order)
- Associative Key-Value Map (`[String String]`, `RG-066`):
  - `list kv empty => [String String]`, `list kv len [String String] => Int`, `list kv has [String String] String => Bool`, `list kv get [String String] String => String`, `list kv get or [String String] String String => String`, `list kv put [String String] String String => [String String]`, `list kv remove [String String] String => [String String]`, `list kv keys [String String] => [String]`, `list kv values [String String] => [String]`, `list kv merge [String String] [String String] => [String String]`

## Responses
| Code | When | Body |
|---|---|---|
| `[Int]` / `[String]` / `[String String]` / `[A]` | Transformation, sort, or map update | New immutable collection |
| `[String Int]` / `[String [A]]` | `list count by` / `list group by` | One pair per key, in order of first appearance |
| `-1` / `0` / `""` | Element or key not found | `-1` for `index_of`, `0`/`""` (or `default_val`) for `nth`/`list_kv_get` |

## Rules
- The `list str` versions of the prelude functions are one-line aliases kept for compatibility (`ADR-0012`).
- All exported functions start with `list ` (`RG-066`) so `import list` and `import agent` never collide.
- All operations are pure, non-mutating, and safe on empty lists or out-of-range indices.
