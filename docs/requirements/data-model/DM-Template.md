---
id: DM-Template
title: Safe Mustache-style text template and auto-escaping models
status: approved
related: [FR-TMPL-001, API-TMPL-001, ADR-0002]
---
# DM-Template — Safe Mustache-style text template and auto-escaping models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| escape_mode | String | `none`, `html`, `latex` | Auto-escaping mode applied to `{{var}}` substitutions (`TmplEscape` ADT) |

## Relations
- Used by `template.rg` (`TmplEscape`) to render `{{var}}`, raw `{{{var}}}`, conditional `{{#key}}...{{/key}}`, and inverted `{{^key}}...{{/key}}` sections against key-value contexts `[(String, String)]`.

## Invariants
- `{{var}}` escapes `&`, `<`, `>`, `"`, `'` under `TmplEscapeHtml` and `\`, `{`, `}` under `TmplEscapeLatex`, while `{{{var}}}` (triple braces) emits raw unescaped text.

## Lifecycle
- Evaluated purely in memory over template strings and `[(String, String)]` bindings.
