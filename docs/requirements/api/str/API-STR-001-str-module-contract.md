---
id: API-STR-001
title: Public module contract for str (str.rglib / libstr.so)
status: approved
implements: [FR-STR-001]
auth: none
---
# API-STR-001 — Public module contract for `str` (`str.rg`)

## Request
- Imported via `import str`.
- `RG-010` & Ridgun String Functions:
  - `str_index_of String String => Int` / `str index of String String => Int`
  - `str_trim String => String` / `str trim String => String`, `str trim left String => String`, `str trim right String => String`
  - `str_replace String String String => String` / `str replace String String String => String`
  - `str_split String String => [String]` / `str split String String => [String]`
  - `str_to_upper String => String` / `str to upper String => String`
  - `str_to_lower String => String` / `str to lower String => String`
  - `str join [String] String => String`, `str repeat String Int => String`, `str pad left String Int String => String`, `str pad right String Int String => String`, `str is empty String => Bool`, `str is blank String => Bool`

## Responses
| Code | When | Body |
|---|---|---|
| `>= 0` | `needle` found in `haystack` (`str_index_of`) | 0-based byte offset (`0` when `needle == ""`) |
| `-1` | `needle` not found in `haystack` (`str_index_of`) | `-1` |
| `String` / `[String]` | Transformation or split completed | Transformed `String` or list of segments `[String]` |

## Rules
- Pure functions with no side effects; `str_replace s "" new` returns `s` without infinite looping.
