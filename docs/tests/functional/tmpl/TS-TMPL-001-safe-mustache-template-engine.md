---
id: TS-TMPL-001
title: Verify Mustache-style text template rendering with HTML/LaTeX auto-escaping and conditional sections
level: unit
covers: [FR-TMPL-001, API-TMPL-001]
status: planned
automated_in: []
---
# TS-TMPL-001 — Verify Mustache-style text template rendering with HTML/LaTeX auto-escaping and conditional sections

## Preconditions / fixtures
- Pure-Ridgun `template` and `test` modules (`src/main/ridgun/lib/template.rg`, `src/main/ridgun/lib/test.rg`).

## Steps / inputs
1. Render templates containing `{{var}}`, `{{{raw}}}`, and `{{! comment }}` via `tmpl render` and `tmpl render html`; verify HTML characters (`<`, `>`, `&`, `"`, `'`) are escaped in `{{var}}` and unescaped in `{{{raw}}}`.
2. Render conditional `{{#flag}}...{{/flag}}` and inverted `{{^flag}}...{{/flag}}` sections with truthy and falsy values.
3. Render `tmpl render latex` with `\`, `{`, `}` characters and verify LaTeX escaping.

## Expected results (map to acceptance criteria)
- AC1 → HTML auto-escaping, raw triple-brace interpolation, and comment stripping work accurately.
- AC2 → Conditional and inverted sections evaluate truthiness accurately.
- AC3 → LaTeX escaping escapes `\`, `{`, and `}` safely.

## Not covered here (to avoid duplication)
- Ridgun source code syntax highlighting (`TS-FMT-001`).
