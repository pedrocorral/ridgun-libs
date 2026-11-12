---
id: TASK-0042
title: Add it to supported locales and verify CLDR plural rules for Italian
status: completed
created: 2026-11-03
completed: 2026-11-03
requirements: [FR-LOCALE-001]
tests: [TS-LOCALE-001]
security: []
context_files:
  - src/main/ridgun/lib/locale.ridgun
  - src/test/ridgun/test locale.ridgun
  - docs/requirements/functional/locale/FR-LOCALE-001-cldr-plurals-dates-numbers-and-language-names.md
  - docs/requirements/api/locale/API-LOCALE-001-locale-module-contract.md
scope:
  - src/main/ridgun/lib/locale.ridgun
  - src/test/ridgun/test locale.ridgun
  - docs/requirements/**
  - docs/book/**
owner: agent-001
claimed: 2026-11-03T20:04:27Z
claimed_by: agent gemini@solarfall
---
# TASK-0042 — Add it to supported locales and verify CLDR plural rules for Italian

## Goal (one sentence)
Add `"it"` to `supported locales` in `src/main/ridgun/lib/locale.ridgun`, add `plural index cldr` alongside `plural index`, and verify `language name "it" == "Italiano"` and CLDR plural rules (`one`, `many`, `other`) in `src/test/ridgun/test locale.ridgun`.

## Plan
- [x] Add `"it"` to `supported locales` (`["es", "ca", "eu", "gl", "pt", "sv", "en", "it"]`) and `plural index cldr` in `src/main/ridgun/lib/locale.ridgun`.
- [x] Update `src/test/ridgun/test locale.ridgun` to test `supported locales`, `language name "it"`, `plural category`/`plural index` and `plural category cldr`/`plural index cldr` for `"it"`, plus Italian UTC dates and numbers.
- [x] Rebuild `target/bundles/locale.ridgunlib`, `target/locale.rgc`, `build/locale.ridgunlib`, `target/liblocale.so`, and `/home/gemini/.local/lib/ridgun/locale.ridgunlib`.

## Progress log (append-only, newest last)
- 2026-11-03: Added `"it"` to `supported locales`, added `plural index cldr`, updated `test locale.ridgun` and `FR-LOCALE-001` / `API-LOCALE-001`, rebuilt all `locale` artifacts and HTML books, and verified tests green.

## Files changed (keep current)
- `src/main/ridgun/lib/locale.ridgun`
- `src/test/ridgun/test locale.ridgun`
- `docs/requirements/functional/locale/FR-LOCALE-001-cldr-plurals-dates-numbers-and-language-names.md`
- `docs/requirements/api/locale/API-LOCALE-001-locale-module-contract.md`
- `docs/book/*/34-lib-locale-*.md`, `docs/book/*/index.html`, `docs/book/index.html`

## Verification performed (command → result, newest last)
- `ridgunc run --strict "src/test/ridgun/test locale.ridgun"` → `[PASS] test locale: TS-LOCALE-001 passed`
- `aix docs coverage && aix docs validate` → `0 errors, 0 warnings`

## Exact next actions
1. Complete task and await user instructions.

## Decisions / open questions
- None.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
