---
rule: "Do not ask the user to confirm an engineering choice whose right answer is clear; do it and report the result."
author: pedro@obdin.com
scope: project
updated: 2026-11-08
---
**Why:** On 2026-11-07 the agent asked whether to rewrite linalg with Real after the user had already said linear algebra is Real; the user called it a waste.
**How to apply:** Ask only for real trade-offs, irreversible or outward-facing actions (commit, push, send), or when the request is ambiguous. Otherwise act and show tests.
