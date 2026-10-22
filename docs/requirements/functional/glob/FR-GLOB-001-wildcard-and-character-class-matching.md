---
id: FR-GLOB-001
title: Provide pure-Ridgun wildcard (*, ?), character class ([a-z], [!a-z]), and list filtering utilities
type: functional
status: implemented
priority: must
domain: GLOB
depends_on: []
related: [ADR-0002, VUL-INPUT-001]
tests: [TS-GLOB-001]
---
# FR-GLOB-001 — Provide pure-Ridgun wildcard (`*`, `?`), character class (`[a-z]`, `[!a-z]`), and list filtering utilities

## Statement
The `glob` library SHALL provide pure-Ridgun wildcard and pattern matching functions (`glob match`, `glob match ci`, `glob filter`, `glob any match`) supporting `*` (zero or more characters), `?` (any single character), `[abc]` / `[a-z]` (character sets and ranges), and `[!abc]` / `[^a-z]` (negated character classes).

## Rationale
CLI tools (`unix-tools`), build systems (`stable`), and routing/filtering layers require fast, deterministic wildcard pattern matching without external C regex libraries.

## Acceptance criteria
- AC1: Given patterns with `*` and `?`, when `glob match pattern text` and `glob match ci pattern text` are called, then `glob match "*.rg" "socket.rg"` returns `True`, `glob match "test_?.rg" "test_a.rg"` returns `True`, and `glob match ci "*.RG" "socket.rg"` returns `True`.
- AC2: Given patterns with bracket character classes (`[a-z]`, `[0-9_]`, `[!0-9]`, `[^a-z]`), when `glob match` is called, then positive and negated character ranges match single characters accurately and unclosed `[` brackets are matched literally without crashing.
- AC3: Given a list of candidate strings `[String]` and one or more patterns, when `glob filter pattern candidates` and `glob any match patterns text` are called, then `glob filter` returns the matching subset in order and `glob any match` returns `True` if any pattern in the list matches `text`.

## Actors & permissions
- Any Ridgun module importing `glob`.

## Constraints & edge cases
- Consecutive `*` wildcards (`"***"`) are collapsed so matching never suffers exponential backtracking on long strings.

## Data & privacy
- Pure in-memory string pattern matching.

## Security & observability notes
- Mitigates `VUL-INPUT-001` (ReDoS / backtracking denial of service) by collapsing adjacent `*` wildcards.

## Out of scope
- Full POSIX ERE capture groups and backreferences.
