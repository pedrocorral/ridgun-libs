---
id: TASK-0021
title: Implement pure-Ridgun configurable source code formatter and multi-target syntax highlighting library (fmt.rg)
status: completed
priority: must
owner: agent-001
implements: [FR-FMT-001, API-FMT-001, DM-Formatter]
tests: [TS-FMT-001]
mitigates: [VUL-INPUT-001]
depends_on: []
scope:
  - src/main/ridgun/lib/fmt.rg
  - src/test/ridgun/test fmt.rg
  - build.rg
context_files:
  - docs/requirements/functional/fmt/FR-FMT-001-ridgun-source-formatting-and-rich-syntax-highlighting.md
  - docs/requirements/api/fmt/API-FMT-001-fmt-module-contract.md
  - docs/requirements/data-model/DM-Formatter.md
  - docs/tests/functional/fmt/TS-FMT-001-ridgun-source-formatting-and-rich-syntax-highlighting.md
claimed: 2026-10-23T19:47:05Z
claimed_by: agent gemini@solarfall
---
# TASK-0021 — Implement pure-Ridgun configurable source code formatter and multi-target syntax highlighting library (`fmt.rg`)

## Goal
Implement `src/main/ridgun/lib/fmt.rg` and `src/test/ridgun/test fmt.rg`, generalising `stable`'s canonical 2D source code formatter with `FmtConfig` and adding optional lexical syntax highlighting across 9 output targets (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`) and 3 themes (`FmtThemeNone`, `FmtThemeDark`, `FmtThemeLight`), and compile `target/bundles/fmt.rglib`, `target/fmt.rgc`, and `target/libfmt.so`.

## Steps
- [x] Step 0: Document `FMT` in glossary, field dictionary, `DM-Formatter`, `FR-FMT-001`, `API-FMT-001`, `TS-FMT-001`, and `TASK-0021`.
- [ ] Step 1: Implement `src/main/ridgun/lib/fmt.rg` and `src/test/ridgun/test fmt.rg`.
- [ ] Step 2: Build `target/bundles/fmt.rglib`, `target/fmt.rgc`, and `target/libfmt.so`, update `build.rg`, run `test fmt.rg`, and validate AIX docs.

## Verification
- `ridgunc check src/main/ridgun/lib/fmt.rg "src/test/ridgun/test fmt.rg"` passes with 0 errors.
- `ridgunc run "src/test/ridgun/test fmt.rg"` passes all assertions (`[PASS] test fmt: TS-FMT-001 passed`).
- `aix docs validate && aix docs coverage` reports 0 errors and 0 warnings.
