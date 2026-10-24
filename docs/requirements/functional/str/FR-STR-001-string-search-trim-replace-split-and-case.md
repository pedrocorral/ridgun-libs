---
id: FR-STR-001
title: Provide pure-Ridgun string searching, trimming, replacement, splitting, case conversion, and padding utilities
type: functional
status: implemented
priority: must
domain: STR
depends_on: []
related: [ADR-0002, VUL-INPUT-001]
tests: [TS-STR-001]
---
# FR-STR-001 — Provide pure-Ridgun string searching, trimming, replacement, splitting, case conversion, and padding utilities

## Statement
The `str` library SHALL provide the `RG-010` string functions (`str_index_of`, `str_trim`, `str_replace`, `str_split`, `str_to_upper`, `str_to_lower`) together with natural-space Ridgun aliases and helper predicates (`str starts with`, `str ends with`, `str contains`, `str trim left`, `str trim right`, `str join`, `str repeat`, `str pad left`, `str pad right`, `str is empty`, `str is blank`).

## Rationale
Ridgun's compiler built-ins provide core primitives (`str_len`, `str_concat`, `str_slice`, `str_starts_with`, `str_ends_with`, `str_contains`, `char_at`, `char_code`, `char_from_code`), while applications and `RG-010` require `str_index_of`, `str_trim`, `str_replace`, `str_split`, `str_to_upper`, and `str_to_lower`.

## Acceptance criteria
- AC1: Given haystack and needle strings, when `str_index_of haystack needle` (or `str index of`) is called, then it returns the 0-based byte index of the first occurrence of `needle` in `haystack` (`0` when `needle == ""`, `-1` when `needle` is not found).
- AC2: Given strings with leading/trailing ASCII whitespace (`' '`, `'\t'`, `'\n'`, `'\r'`), target substrings, or delimiters, when `str_trim`, `str_replace`, and `str_split` are called, then `str_trim "  hi \n"` returns `"hi"`, `str_replace "a-b-c" "-" "_"` replaces all occurrences returning `"a_b_c"` (returning `s` unchanged when `old == ""`), and `str_split "a,b,c" ","` returns `["a", "b", "c"]` (preserving empty segments such as `str_split "a,,b" ","` → `["a", "", "b"]`).
- AC3: Given mixed-case ASCII strings and formatting inputs, when `str_to_upper`, `str_to_lower`, `str join`, `str repeat`, `str pad left`, and `str pad right` are called, then `str_to_upper "Abc!"` returns `"ABC!"`, `str_to_lower "Abc!"` returns `"abc!"`, and `str join` / `str repeat` / `str pad left` / `str pad right` produce exact formatted strings.

## Actors & permissions
- Any Ridgun program or lib importing `str`.

## Constraints & edge cases
- `str_replace s "" new` must not loop infinitely; it returns `s` unchanged.
- `str_split "" sep` returns `[""]` when `sep` is non-empty, matching standard split semantics.
- `str_repeat s n` supports multi-megabyte repetitions via binary-doubling without an artificial `1048576` cap (`RG-052`).

## Data & privacy
- Pure in-memory string transformations.

## Security & observability notes
- Mitigates `VUL-INPUT-001` by preventing infinite loops on empty needle/delimiter inputs in `str_replace` and `str_split`.

## Out of scope
- Full Unicode locale-dependent case folding tables beyond ASCII `A..Z` / `a..z`.
