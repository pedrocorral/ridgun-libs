---
id: TS-REGEX-001
title: Verify linear-time Thompson NFA regular expression matching, search, replacement, and splitting
level: unit
covers: [FR-REGEX-001, API-REGEX-001]
status: planned
automated_in: []
---
# TS-REGEX-001 — Verify linear-time Thompson NFA regular expression matching, search, replacement, and splitting

## Preconditions / fixtures
- Pure-Ridgun `regex` and `test` modules (`src/main/ridgun/lib/regex.rg`, `src/main/ridgun/lib/test.rg`).

## Steps / inputs
1. Test `regex match` and `regex is match` with `.`, `*`, `+`, `?`, `|`, `(...)`, `[a-z0-9]`, `[^0-9]`, `\d`, `\w`, `\s`, `^`, `$`, and pathological `(a?){20}a{20}` patterns.
2. Test `regex find` and `regex find all` on multi-token strings and verify `match_start`, `match_end`, and `text`.
3. Test `regex replace`, `regex replace all`, and `regex split`.

## Expected results (map to acceptance criteria)
- AC1 → All regular expression operators evaluate accurately in linear time.
- AC2 → `regex find` and `regex find all` return exact match spans.
- AC3 → `regex replace*` and `regex split` transform strings accurately.

## Not covered here (to avoid duplication)
- Shell wildcard globbing (`TS-GLOB-001`).
