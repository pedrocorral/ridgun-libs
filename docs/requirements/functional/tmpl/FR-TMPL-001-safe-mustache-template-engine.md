---
id: FR-TMPL-001
title: Provide Mustache-style text template rendering with HTML/LaTeX auto-escaping and conditional sections
type: functional
status: implemented
priority: must
domain: TMPL
depends_on: []
related: [ADR-0002, DM-Template, API-TMPL-001, VUL-INPUT-001]
tests: [TS-TMPL-001]
---
# FR-TMPL-001 — Provide Mustache-style text template rendering with HTML/LaTeX auto-escaping and conditional sections

## Statement
The `template` library SHALL provide Mustache-style template rendering (`tmpl render`, `tmpl render html`, `tmpl render latex`, `tmpl render with escape`), supporting escaped variables `{{var}}`, raw unescaped variables `{{{var}}}`, comments `{{! comment }}`, truthy conditional sections `{{#key}}...{{/key}}`, and inverted falsy sections `{{^key}}...{{/key}}`.

## Rationale
HTML views, reports, emails, and documentation generators require safe text templating with automatic escaping against XSS and markup injection.

## Acceptance criteria
- AC1: Given a template containing `{{var}}`, `{{{raw}}}`, and `{{! comment }}` and a `[(String, String)]` context, when `tmpl render html` is called, then `{{var}}` escapes `&`, `<`, `>`, `"`, `'`, `{{{raw}}}` outputs raw text, and `{{! ... }}` is omitted.
- AC2: Given a template containing `{{#flag}}ON{{/flag}}{{^flag}}OFF{{/flag}}`, when `flag` is non-empty and not `"false"`/`"0"`, then `ON` is rendered; when `flag` is missing, `""`, `"false"`, or `"0"`, then `OFF` is rendered.
- AC3: Given `tmpl render latex`, when a variable contains `\`, `{`, or `}`, then it is escaped for LaTeX output.

## Actors & permissions
- Any Ridgun program or lib importing `template`.

## Constraints & edge cases
- Missing variables evaluate to `""` without failing.

## Data & privacy
- Pure in-memory string rendering in `RMM1`/`RMM2` regions.

## Security & observability notes
- Mitigates `VUL-INPUT-001` and template injection by disallowing code execution in templates and escaping HTML/LaTeX characters by default.

## Out of scope
- File-system partial template loading.
