---
id: DM-Formatter
title: Ridgun source formatter configuration, output target, and syntax token models
status: approved
related: [FR-FMT-001, API-FMT-001, ADR-0002]
---
# DM-Formatter — Ridgun source formatter configuration, output target, and syntax token models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| indent_width | Int | `>= 1` (default `2`) | Number of spaces per structural block indentation level |
| max_align_params | Int | `>= 0` (default `4`) | Maximum function/operator parameter count eligible for 2D column alignment |
| max_line_width | Int | `>= 20` (default `80`) | Maximum total signature width before falling back to single-space separation |
| is_aligned | Bool | `True` or `False` | Enables or disables 2D tabular signature/clause/`where` alignment |
| target_format | String | `plain`, `tty`, `truecolor`, `html_inline`, `html_css`, `markdown`, `pango`, `latex`, `rtf` | Selected output rendering target (`FmtTarget` ADT) |
| color_theme | String | `none`, `dark`, `light` | Selected syntax color palette (`FmtTheme` ADT) |

## Relations
- Used by `fmt.rg` (`FmtConfig`, `FmtTarget`, `FmtTheme`, `FmtCategory`) to format Ridgun `.rg` source text into 2D aligned canonical layout and render optional syntax highlighting across 9 enriched text formats.

## Invariants
- 2D column alignment geometry (`sig_cols`, `arrow_col`, `ret_col`) is always computed on raw uncolored source text before any ANSI escape sequence or HTML/Pango/LaTeX/RTF markup is emitted, guaranteeing that color sequences never distort column widths.
- HTML and Pango targets escape `&`, `<`, and `>` (and quotes where applicable); LaTeX escapes `\`, `{`, and `}`; RTF escapes `\`, `{`, and `}` before wrapping tokens in style spans.

## Lifecycle
- Constructed via `default fmt config` or `fmt config` and passed to `fmt source with config` or format-specific helpers (`fmt to tty`, `fmt to html`, etc.); reclaimed deterministically by `RMM1`/`RMM2`.
