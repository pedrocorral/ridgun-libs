---
id: API-FMT-001
title: Public module contract for fmt (fmt.rglib / libfmt.so)
status: approved
implements: [FR-FMT-001]
auth: none
---
# API-FMT-001 — Public module contract for `fmt` (`fmt.rg`)

## Request
- Imported via `import fmt`.
- Public Types (see `DM-Formatter`):
  - `type FmtTarget = FmtPlain | FmtTty | FmtTrueColor | FmtHtmlInline | FmtHtmlCss | FmtMarkdown | FmtPango | FmtLatex | FmtRtf`
  - `type FmtTheme = FmtThemeNone | FmtThemeDark | FmtThemeLight`
  - `type FmtConfig = indent_width: Int, max_align_params: Int, max_line_width: Int, is_aligned: Bool, target_format: FmtTarget, color_theme: FmtTheme`
- Configuration & Core Formatting:
  - `default fmt config => FmtConfig`
  - `fmt config Int Int Int Bool FmtTarget FmtTheme => FmtConfig`
  - `format ridgun source String => String`
  - `fmt source with config String FmtConfig => String`
  - `fmt highlight line String FmtTarget FmtTheme => String`
- Enriched Output Target Helpers:
  - `fmt to tty String => String`
  - `fmt to tty with theme String FmtTheme => String`
  - `fmt to truecolor String => String`
  - `fmt to truecolor with theme String FmtTheme => String`
  - `fmt to html String => String`
  - `fmt to html with theme String FmtTheme => String`
  - `fmt to html css String => String`
  - `fmt html stylesheet FmtTheme => String`
  - `fmt to markdown String => String`
  - `fmt to pango String => String`
  - `fmt to pango with theme String FmtTheme => String`
  - `fmt to latex String => String`
  - `fmt to latex with theme String FmtTheme => String`
  - `fmt to rtf String => String`
  - `fmt to rtf with theme String FmtTheme => String`

## Responses
| Code | When | Body |
|---|---|---|
| `FmtConfig` | `default fmt config` or `fmt config` | Formatter & highlighter configuration record |
| `String` | `format ridgun source`, `fmt source with config`, or `fmt to *` | Canonically formatted and optionally syntax-highlighted Ridgun code in the target format |
| `String` | `fmt html stylesheet` | Complete `<style>...</style>` CSS rules for `.rg-*` syntax classes |

## Rules
- `format ridgun source` preserves 100% compatibility with `stable format` (`indent_width = 2`, `max_align_params = 4`, `max_line_width = 80`, `is_aligned = True`, `FmtPlain`, `FmtThemeNone`).
- All public functions support natural space-separated Ridgun invocation.
