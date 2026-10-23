---
id: API-REGEX-001
title: Public module contract for regex (regex.rglib / libregex.so)
status: approved
implements: [FR-REGEX-001]
auth: none
---
# API-REGEX-001 — Public module contract for `regex` (`regex.rg`)

## Request
- Imported via `import regex`.
- Public Types (see `DM-Regex`):
  - `type RegexMatch = matched: Bool, match_start: Int, match_end: Int, text: String`
- Matching & Search:
  - `regex match String String => Bool`
  - `regex is match String String => Bool`
  - `regex find String String => RegexMatch`
  - `regex find all String String => [RegexMatch]`
- Replacement & Splitting:
  - `regex replace String String String => String`
  - `regex replace all String String String => String`
  - `regex split String String => [String]`

## Responses
| Code | When | Body |
|---|---|---|
| `Bool` | `regex match` (full-string) or `regex is match` (substring) | `True` if matched, `False` otherwise |
| `RegexMatch` / `[RegexMatch]` | `regex find` / `regex find all` | Match span(s) with start, end, and substring |
| `String` / `[String]` | `regex replace*` / `regex split` | Replaced text or list of split segments |

## Rules
- `regex match` checks if the entire string matches `pattern_str` (implicit `^...$`), whereas `regex is match` checks if any substring matches `pattern_str`.
