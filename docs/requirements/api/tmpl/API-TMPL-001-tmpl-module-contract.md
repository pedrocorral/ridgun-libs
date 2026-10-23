---
id: API-TMPL-001
title: Public module contract for template (template.rglib / libtemplate.so)
status: approved
implements: [FR-TMPL-001]
auth: none
---
# API-TMPL-001 — Public module contract for `template` (`template.rg`)

## Request
- Imported via `import template`.
- Public Types (see `DM-Template`):
  - `type TmplEscape = TmplEscapeNone | TmplEscapeHtml | TmplEscapeLatex`
- Rendering Functions:
  - `tmpl render String [(String, String)] => String`
  - `tmpl render html String [(String, String)] => String`
  - `tmpl render latex String [(String, String)] => String`
  - `tmpl render with escape String [(String, String)] TmplEscape => String`

## Responses
| Code | When | Body |
|---|---|---|
| `String` | `tmpl render*` | Rendered text with `{{var}}`, `{{{raw}}}`, `{{#sec}}...{{/sec}}`, and `{{^sec}}...{{/sec}}` evaluated |

## Rules
- `tmpl render` uses `TmplEscapeNone`; `tmpl render html` uses `TmplEscapeHtml`; `tmpl render latex` uses `TmplEscapeLatex`.
- Triple-brace `{{{var}}}` always bypasses escaping.
