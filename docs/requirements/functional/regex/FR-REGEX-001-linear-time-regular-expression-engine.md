---
id: FR-REGEX-001
title: Provide linear-time Thompson NFA regular expression matching, search, replacement, and splitting
type: functional
status: implemented
priority: must
domain: REGEX
depends_on: []
related: [ADR-0002, DM-Regex, API-REGEX-001, VUL-INPUT-001]
tests: [TS-REGEX-001]
---
# FR-REGEX-001 — Provide linear-time Thompson NFA regular expression matching, search, replacement, and splitting

## Statement
The `regex` library SHALL provide a linear-time Thompson NFA regular expression engine supporting `.`, `*`, `+`, `?`, alternation `|`, grouping `(...)`, character classes `[a-z0-9]`, negated classes `[^...]`, shorthand escapes `\d`, `\w`, `\s`, and anchors `^`, `$`, exposing `regex match`, `regex is match`, `regex find`, `regex find all`, `regex replace`, `regex replace all`, and `regex split`.

## Rationale
Text parsing, validation, and lexing require full regular expressions with guaranteed $O(N \cdot M)$ execution time free of catastrophic backtracking (ReDoS).

## Acceptance criteria
- AC1: Given patterns using `.`, `*`, `+`, `?`, `|`, `(...)`, `[a-z]`, `[^0-9]`, `\d`, `\w`, `\s`, `^`, and `$`, when `regex match` or `regex is match` is called, then it returns `True` for matching inputs and `False` otherwise in linear time.
- AC2: Given an input string and pattern, when `regex find` or `regex find all` is called, then it returns `RegexMatch` records with exact `match_start`, `match_end`, and matched substring.
- AC3: Given an input string, pattern, and replacement string, when `regex replace`, `regex replace all`, or `regex split` is called, then it substitutes or splits non-empty matches accurately.

## Actors & permissions
- Any Ridgun program or lib importing `regex`.

## Constraints & edge cases
- Escaped literals (`\.`, `\*`, `\+`, `\?`, `\\`, `\[`, `\]`) match the literal character.

## Data & privacy
- Pure in-memory NFA state set simulation in `RMM1`/`RMM2` regions.

## Security & observability notes
- Mitigates `VUL-INPUT-001` and ReDoS by simulating active state sets without exponential recursion.

## Out of scope
- Backreferences (`\1`) that break regular language $O(N \cdot M)$ guarantees.
