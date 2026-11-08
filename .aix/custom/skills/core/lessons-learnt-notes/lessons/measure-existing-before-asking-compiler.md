---
rule: "Before asking the compiler for a primitive, check and measure existing built-ins; request only the smallest piece libs cannot build."
author: pedro@obdin.com
scope: project
updated: 2026-11-08
---
**Why:** On 2026-11-07 the agent asked for `Array A`, `str hash` and `HashMap` without checking `Tensor` and `sha256 raw`; the compiler team refused all three.
**How to apply:** Search the typechecker built-ins and spec, write a small benchmark with what exists, and attach the numbers. Ask only when the measured best in Ridgun misses the target.
