---
rule: "ALWAYS USE SPACE-SEPARATED TUPLE AND SEQUENCE TYPE SIGNATURES (`Int Int`, `[String String]`) INSTEAD OF COMMA-SEPARATED TUPLES (`(Int, Int)`)."
author: gemini@local
scope: project
updated: 2026-10-22
---
**Why:** On 2026-10-22, the user pointed out legacy comma-separated tuple return signatures (`=> (Int, Int)`) where Ridgun v0.9.10 uses unified space-separated tuple and sequence type signatures (`=> Int Int`).
**How to apply:** In every `fn ::` type signature and `type` definition, write tuple returns as `=> A B`, grouped tuple parameters as `(A B)`, and tuple lists as `[A B]`; never use commas inside type signatures.
