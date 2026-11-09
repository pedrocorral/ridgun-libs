---
rule: "When asked to adapt some libraries, change those libraries; never build or test downstream apps whose own teams maintain them."
author: pedro@obdin.com
scope: project
updated: 2026-11-09
---
**Why:** On 2026-11-09, asked to adapt the `db/` libs to `Tensor[U8]`, the agent built and tested eterval (an app with its own team) instead; the user stopped it: "Corrige lo de db/. Eterval se arregla solo."
**How to apply:** Find what in the named libraries needs changing and change it, with their own tests. Downstream apps that depend on them are their teams' work: mention a likely break in one line at most, and do not build, test or edit them unless the user asks.
