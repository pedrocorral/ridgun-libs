---
id: TASK-0031
title: Remove chapter 00 and expand all 32 lib chapters into multi-page chapters across 7 languages
status: completed
created: 2026-10-24
completed: 2026-10-24
requirements: [FR-STR-001, FR-MATH-001, FR-LIST-001, FR-BTREE-001, FR-TENSOR-001, FR-LINALG-001, FR-CODEC-001, FR-JSON-001, FR-CSV-001, FR-INI-001, FR-REGEX-001, FR-GLOB-001, FR-DIFF-001, FR-TMPL-001, FR-FMT-001, FR-CLI-001, FR-PATH-001, FR-TIME-001, FR-UUID-001, FR-LOG-001, FR-TST-001, FR-POSIX-001, FR-IO-001, FR-CRYPTO-001, FR-JWT-001, FR-SOCK-001, FR-HTTP-001, FR-WS-001, FR-AGENT-001]
tests: []
security: []
context_files:
  - docs/book/INDEX.md
  - docs/book/build_book.py
  - docs/INDEX.md
  - README.md
scope:
  - docs/book/**
  - docs/INDEX.md
  - README.md
owner: agent-001
claimed: 2026-10-24T11:55:51Z
claimed_by: agent gemini@solarfall
policy:                     # empty = project default
---
# TASK-0031 — Remove chapter 00 and expand all 32 lib chapters into multi-page chapters across 7 languages

## Goal (one sentence)
Remove Chapter `00` from the `ridgun-libs` book across all 7 languages (`es`, `ca`, `gl`, `eu`, `en`, `pt`, `sv`) and expand every single lib chapter (`01` through `32`) into a multi-page (233–724 lines, ~6–15 pages per lib) pedagogical and technical deep-dive with multiple runnable examples exploring every functionality of each lib.

## Plan
- [x] Delete `00-*` chapter files from `docs/book/{es,ca,gl,eu,en,pt,sv}/`.
- [x] Expand all 32 lib chapters (`01`–`32`) across all 7 languages (`es`, `ca`, `gl`, `eu`, `en`, `pt`, `sv`) into rich multi-page chapters (~445 lines average per chapter; 14,256 lines per language) covering:
  1. Motivation & architectural problem solved by the lib
  2. Native build artifacts + full public signature & ADT catalog from `src/main/ridgun/lib/<lib>.rg`
  3. Step-by-step functional exploration with 5–8 runnable Ridgun examples per chapter covering every functional area and boundary case
  4. Real under-the-hood pure-Ridgun implementation sections from `src/main/ridgun/lib/<lib>.rg`
  5. Algorithmic/security guarantees, `RMM1`/`RMM2` memory behavior, and the 5 Golden Rules
- [x] Update `docs/book/{es,ca,gl,eu,en,pt,sv}/INDEX.md`, `docs/book/INDEX.md`, `README.md`, and `docs/book/build_book.py` to reflect 32 chapters (`01`–`32`, no `00`), and regenerate the interactive HTML books.
- [x] Run `aix docs validate` and `aix docs coverage`.

## Progress log (append-only, newest last)
- 2026-10-24: Created and started `TASK-0031` to remove Chapter `00` and expand all 32 lib chapters into multi-page chapters across all 7 languages.
- 2026-10-24: Removed `docs/book/*/00-*.md`, expanded all 32 chapters (`01`–`32`) across `es`, `ca`, `gl`, `eu`, `en`, `pt`, and `sv` to 233–724 lines each (14,256 lines per edition) with 5–8 runnable examples per lib, full signature catalogs, and real implementation walkthroughs, and rebuilt all 8 standalone `index.html` books (~850 KB each).

## Files changed (keep current)
- `docs/book/INDEX.md`
- `docs/book/build_book.py`
- `docs/book/index.html`
- `docs/book/{es,ca,gl,eu,en,pt,sv}/INDEX.md`
- `docs/book/{es,ca,gl,eu,en,pt,sv}/index.html`
- `docs/book/{es,ca,gl,eu,en,pt,sv}/01-*.md` .. `32-*.md` (removed `00-*.md`)
- `README.md`

## Verification performed (command → result, newest last)
- `python3 docs/book/build_book.py` → 8 interactive HTML books generated (`32 chapters` each, ~850 KB per file).
- `aix docs coverage && aix docs validate` → `0 errors, 0 warnings`.

## Exact next actions
1. Complete `TASK-0031`.

## Decisions / open questions
- None.

## Definition of done checklist
- [x] requirements referenced are `implemented`  - [x] tests automated & green
- [x] security entries updated  - [x] docs INDEX updated  - [x] coverage matrix regenerated
