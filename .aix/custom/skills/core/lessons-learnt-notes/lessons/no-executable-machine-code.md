---
rule: "NEVER USE PROT_EXEC MMAP PAGES, RAW MACHINE-CODE BLOBS, OR SHELLCODE-LIKE EXECUTION; WRITE ALL ALGORITHMS IN PURE RIDGUN."
author: gemini@local
scope: project
updated: 2026-10-22
---
**Why:** On 2026-10-22, generating raw executable machine code into a `PROT_EXEC` `mmap` buffer triggered Gemini's safety filters and blocked the response.
**How to apply:** Always implement cryptographic and system algorithms in 100% pure Ridgun source code (`src/main/ridgun/lib/*.rg`) using standard language constructs and normal data-only OS syscalls.
