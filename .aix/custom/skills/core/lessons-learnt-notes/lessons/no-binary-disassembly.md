---
rule: "NEVER RUN OBJDUMP OR ANY BINARY DISASSEMBLY COMMAND ON EXECUTABLES OR SHARED LIBRARIES."
author: gemini@local
scope: project
updated: 2026-10-22
---
**Why:** On 2026-10-22, running `objdump -d` on a binary triggered a runtime safety policy refusal and aborted the agent's turn.
**How to apply:** When investigating compiler builtins or system interfaces, read source files, docs, or skills (`implement-code-ridgun`) or test small `.rg` snippets with `ridgunc check`/`ridgunc run` instead of disassembling binaries.
