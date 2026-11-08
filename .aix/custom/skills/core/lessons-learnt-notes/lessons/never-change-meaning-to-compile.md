---
rule: "Never change what code means just to make it compile; fix it with the correct semantics, e.g. Real linear algebra stays Real."
author: pedro@obdin.com
scope: project
updated: 2026-11-08
---
**Why:** On 2026-11-07, with ridgunc 0.9.41, the agent proposed moving linalg to `Tensor[Int]` to compile; the user rejected doing linear algebra with integers.
**How to apply:** When a compiler change breaks code, fix it in the domain's own terms (types, ranges, units). Only an ADR the user approves may change the meaning.
