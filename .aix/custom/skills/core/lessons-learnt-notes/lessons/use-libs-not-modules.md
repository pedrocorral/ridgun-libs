---
rule: "ALWAYS REFER TO THE ELEMENTS OF RIDGUN-LIBS AS LIBS RATHER THAN MODULES, RESERVING THE WORD MODULE FOR OTHER PURPOSES."
author: gemini@local
scope: project
updated: 2026-10-24
---
**Why:** On 2026-10-24, the user requested calling the 32 elements of `ridgun-libs` "libs" instead of "modules" so the term "module" remains reserved for other architectural concepts.
**How to apply:** Whenever writing documentation, specs (`API-*`, `FR-*`), `README.md`, or responses in `ridgun-libs`, call each `.rg` / `.rglib` / `.so` element a "lib" (plural "libs").
