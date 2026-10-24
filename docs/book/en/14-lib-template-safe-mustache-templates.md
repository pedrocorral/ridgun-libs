# Chapter 14: The `template` Lib — Safe Mustache Templates with HTML and LaTeX Auto-Escaping

## 1. Why Does the `template` Lib Exist?

Let's be honest: assembling HTML pages or LaTeX reports by manual string concatenation is a textbook recipe for XSS vulnerabilities (`<script>`) or broken PDF builds the moment a user types `%` or `_`.

The **`template`** lib provides a logic-less **Mustache** engine with contextual auto-escaping (`TmplPlain`, `TmplHtml`, `TmplLatex`), explicit raw interpolation (`{{{raw}}}` / `{{&raw}}`), comments (`{{! ... }}`), truthy sections (`{{#sec}}...{{/sec}}`), and inverted sections (`{{^sec}}...{{/sec}}`).

---

## 2. Bundles, Imports, and Zero-`libc` Architecture

In `ridgun-libs`, **`template`** is a first-class **lib** located at `src/main/ridgun/lib/template.rg` (domain `TMPL`). When built with `stable bundle`, it compiles into three native artifacts:

| Artifact | Path | Purpose |
|---|---|---|
| **Ridgun Bundle** | `target/bundles/template.rglib` | Portable distribution and direct `import template` resolution |
| **Compiled Archive** | `target/template.rgc` | Type-checked intermediate artifact verified by `ridgunc` |
| **ELF64 Shared Object** | `target/libtemplate.so` | Native dynamic shared library with zero C or `libc` dependencies |

> To use this lib in any `.rg` file, simply add `import template` at the top and call its functions using either multi-word spaces or underscores.

---

## 3. Quick API Reference for `template`

| Signature / Function / Type | Purpose & Usage |
|---|---|
| `tmpl render / tmpl render html / tmpl render latex` | Render Mustache templates with plain, HTML, or LaTeX auto-escaping |
| `tmpl escape html / tmpl escape latex` | Escape `& < > " '` for HTML or `\ { } & % $ # _ ~ ^` for LaTeX |
| `tmpl extract vars / tmpl has unclosed tags` | Inspect required variable names and validate tag balance before rendering |

---

## 4. Practical Tabular Recipes

### Recipe 1: Core Workflow with `template`

Notice how the `=` signs and transformation steps align into a clean, scannable table:

```ridgun
import template

fn :: renderizar perfil html (usuario : String) (es_admin : String) => String
      renderizar perfil html usuario es_admin =
        plantilla = "<h1>Hola {{user}}</h1>{{#admin}}<span class='badge'>Admin</span>{{/admin}}"
        vars      = [("user", usuario), ("admin", es_admin)]
        tmpl render html plantilla vars
```

### Recipe 2: Safe, Side-Effect-Free Composition

Every function in the `template` lib composes seamlessly with the rest of the 32 libs in `ridgun-libs`:

```ridgun
import template

fn :: generar linea latex (metrica : String) => String
      generar linea latex metrica =
        -- Escapa automaticamente % _ & # para que LaTeX no falle
        tmpl render latex "Resultado: {{val}}" [("val", metrica)]
```

---

## 5. Under the Hood: Performance, RMM Memory, and Guarantees

- **Algorithmic & Safety Guarantee**: Default XSS prevention in `tmpl render html` (escaping `&`, `<`, `>`, `"`, `'`), while triple-stache `{{{var}}}` explicitly opts into raw trusted markup.
- **Deterministic Memory (`RMM1`/`RMM2`)**: Zero garbage-collector pauses; all intermediate allocations are reclaimed deterministically on scope exit.
- **Continuous Verification**: Statically checked via `stable check` and tested by the automated suite in `src/test/ridgun/test_template.rg`.
