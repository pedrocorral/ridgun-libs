---
id: API-LIST-001
title: Public lib contract for list (list.rglib / liblist.so)
status: approved
implements: [FR-LIST-001]
auth: none
---
# API-LIST-001 — Public lib contract for `list` (`list.rg`)

## Request
- Imported via `import list`.
- List Inspection, Slicing & Generation:
  - `list len [Int] => Int`, `list str len [String] => Int`, `list is empty [Int] => Bool`, `list str is empty [String] => Bool`
  - `list nth [Int] Int => Int`, `list nth or [Int] Int Int => Int`, `list str nth [String] Int => String`, `list str nth or [String] Int String => String`, `list head [Int] Int => Int`, `list last [Int] Int => Int`
  - `list take [Int] Int => [Int]`, `list str take [String] Int => [String]`, `list drop [Int] Int => [Int]`, `list str drop [String] Int => [String]`, `list slice [Int] Int Int => [Int]`, `list str slice [String] Int Int => [String]`
  - `list reverse [Int] => [Int]`, `list str reverse [String] => [String]`, `list range Int Int => [Int]`, `list range step Int Int Int => [Int]`, `list replicate Int Int => [Int]`
- Search, Deduplication & Sorting:
  - `list contains [Int] Int => Bool`, `list str contains [String] String => Bool`, `list index of [Int] Int => Int`, `list str index of [String] String => Int`, `list count [Int] Int => Int`, `list str count [String] String => Int`
  - `list dedup [Int] => [Int]`, `list str dedup [String] => [String]`, `list sort [Int] => [Int]`, `list str sort [String] => [String]`, `list is sorted [Int] => Bool`
- Associative Key-Value Map (`[(String, String)]`):
  - `kv empty => [(String, String)]`, `kv len [(String, String)] => Int`, `kv has [(String, String)] String => Bool`, `kv get [(String, String)] String => String`, `kv get or [(String, String)] String String => String`, `kv put [(String, String)] String String => [(String, String)]`, `kv remove [(String, String)] String => [(String, String)]`, `kv keys [(String, String)] => [String]`, `kv values [(String, String)] => [String]`, `kv merge [(String, String)] [(String, String)] => [(String, String)]`

## Responses
| Code | When | Body |
|---|---|---|
| `[Int]` / `[String]` / `[(String, String)]` | Transformation, sort, or map update | New immutable collection |
| `-1` / `0` / `""` | Element or key not found | `-1` for `index_of`, `0`/`""` (or `default_val`) for `nth`/`kv_get` |

## Rules
- All operations are pure, non-mutating, and safe on empty lists or out-of-range indices.
