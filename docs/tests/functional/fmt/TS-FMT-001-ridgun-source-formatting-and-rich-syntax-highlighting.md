---
id: TS-FMT-001
title: Verify configurable 2D Ridgun source formatting and syntax highlighting across Plain, TTY, TrueColor, HTML, CSS, Markdown, Pango, LaTeX, and RTF targets
level: unit
covers: [FR-FMT-001, API-FMT-001]
status: automated
automated_in: [src/test/ridgun/test fmt.rg]
---
# TS-FMT-001 — Verify configurable 2D Ridgun source formatting and syntax highlighting across Plain, TTY, TrueColor, HTML, CSS, Markdown, Pango, LaTeX, and RTF targets

## Preconditions / fixtures
- Pure-Ridgun `fmt` and `test` modules (`src/main/ridgun/lib/fmt.rg`, `src/main/ridgun/lib/test.rg`).

## Steps / inputs
1. Call `format ridgun source` and `fmt source with config` (with both `is_aligned = True` and `is_aligned = False`, and custom `indent_width`) on unaligned Ridgun `fn ::` / `op ::` signatures, clauses (`=`), guards (`|`, `||`), and `where` bindings (`->`); verify 2D column alignment of `=>`, `=`, and `->`.
2. Call `fmt to tty`, `fmt to tty with theme ... FmtThemeNone`, and `fmt to truecolor` on Ridgun code containing keywords (`fn`, `type`, `where`, `otherwise`), logical/bitwise ops (`and`, `xor`), types (`Int`, `Tensor[U64 * 8 * 16]`), strings (`"hello {name}"`), numbers (`0xFF`, `42`), comments (`-- comment`), and AIX annotations (`@implements FR-FMT-001`); verify ANSI 16-color (`\x1b[`) and 24-bit TrueColor (`\x1b[38;2;`) sequences when themed and plain output when `FmtThemeNone`.
3. Call `fmt to html`, `fmt to html css`, `fmt html stylesheet`, `fmt to markdown`, `fmt to pango`, `fmt to latex`, and `fmt to rtf` on code containing special characters (`<`, `>`, `&`, `{`, `}`); verify proper escaping and target wrapper tags (`<pre><code class="language-ridgun">`, `<span class="rg-kw">`, ```` ```ridgun ````, `<span foreground=`, `\begin{Verbatim}`, `{\rtf1\ansi`).

## Expected results (map to acceptance criteria)
- AC1 → 2D tabular signature, clause, guard, and `where` alignment matches `stable format` and respects `FmtConfig` parameters.
- AC2 → Terminal targets (`FmtTty`, `FmtTrueColor`) emit accurate SGR / 24-bit RGB sequences for all Ridgun lexical categories without shifting 2D column alignment, and emit no escape codes under `FmtThemeNone`.
- AC3 → Rich document targets (`FmtHtmlInline`, `FmtHtmlCss`, `FmtMarkdown`, `FmtPango`, `FmtLatex`, `FmtRtf`) escape special characters and emit valid target markup.

## Not covered here (to avoid duplication)
- CLI file-system traversal in `stable format`.
