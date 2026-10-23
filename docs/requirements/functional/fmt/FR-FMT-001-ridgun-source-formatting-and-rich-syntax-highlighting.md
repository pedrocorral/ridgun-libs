---
id: FR-FMT-001
title: Provide configurable 2D Ridgun source code formatting and multi-target syntax highlighting
type: functional
status: implemented
priority: must
domain: FMT
depends_on: []
related: [ADR-0002, DM-Formatter, API-FMT-001, VUL-INPUT-001]
tests: [TS-FMT-001]
---
# FR-FMT-001 — Provide configurable 2D Ridgun source code formatting and multi-target syntax highlighting

## Statement
The `fmt` library SHALL generalise the canonical Ridgun source code formatter found in `stable` with configurable indentation, parameter alignment limits, line width, and 2D tabular clause/signature/`where` alignment (`FmtConfig`), and SHALL provide optional lexical syntax highlighting across 9 output targets (`FmtPlain`, `FmtTty`, `FmtTrueColor`, `FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, and `FmtRtf`) with selectable color themes (`FmtThemeNone`, `FmtThemeDark`, `FmtThemeLight`).

## Rationale
Tools, documentation generators, CLI commands, terminal viewers, web pages, GTK/Pango desktop interfaces, LaTeX specifications, and office documents need a single pure-Ridgun library (`fmt.rg`) that both formats `.rg` source into canonical 2D tabular alignment and optionally enriches it with syntax highlighting without allowing escape codes or markup tags to corrupt column geometry.

## Acceptance criteria
- AC1: Given Ridgun source code containing `fn ::` / `op ::` signatures, multi-clause definitions (`=`), guards (`|`, `||`), and `where` bindings (`->`), when `format ridgun source src` or `fmt source with config src cfg` (with `FmtPlain`) is called, then it returns canonically aligned 2D source text matching `stable format` and honouring `indent_width`, `max_align_params`, `max_line_width`, and `is_aligned`.
- AC2: Given Ridgun source code and a terminal target (`FmtTty` or `FmtTrueColor`, or convenience functions `fmt to tty` / `fmt to truecolor`), when formatted with `FmtThemeDark` or `FmtThemeLight`, then keywords, logical/bitwise operators, types/constructors, function names, string literals (including `{expr}` interpolation), numeric literals (`0x...`, `_KB`/`_MB`/`_GB`, integers/reals), structural operators (`::`, `=>`, `->`, `||`), and comments/pragmas (`-- ...`, `@implements`, `@tests`, `@mitigates`) are wrapped in ANSI SGR or 24-bit RGB escape sequences while preserving 2D column alignment; when `FmtThemeNone` is selected, no ANSI escape codes are emitted.
- AC3: Given Ridgun source code and a rich document target (`FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, or `FmtRtf`, or their convenience functions `fmt to html`, `fmt to html css`, `fmt html stylesheet`, `fmt to markdown`, `fmt to pango`, `fmt to latex`, `fmt to rtf`), when formatted, then special target characters (`&`, `<`, `>`, `\`, `{`, `}`) are safely escaped and tokens are wrapped in the target's enriched markup.

## Actors & permissions
- Any Ridgun module or CLI tool importing `fmt`.

## Constraints & edge cases
- 2D column widths MUST be computed before applying syntax highlighting spans so markup or ANSI sequences never shift column offsets.
- Quoted string literals (`"..."` and `'...'`) and comments (`-- ...`) MUST not have inner words misclassified as keywords or operators.

## Data & privacy
- Pure in-memory string transformation in `RMM1`/`RMM2` regions; no network or filesystem side effects.

## Security & observability notes
- Mitigates `VUL-INPUT-001` and HTML/markup injection by escaping `<`, `>`, `&` in HTML/Pango outputs and `\`, `{`, `}` in LaTeX/RTF outputs.

## Out of scope
- Enforcing formatting rules inside `ridgunc` compilation.
