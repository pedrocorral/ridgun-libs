---
id: TASK-0035
title: Implement the ai library (ai.rg) for AI agents, tool calling, streaming SSE, structured outputs, ReAct loop, guardrails, mini-RAG, handoffs, and MCP JSON-RPC
status: completed
created: 2026-10-28
completed: 2026-10-29
requirements: [FR-AI-001, API-AI-001]
tests: [TS-AI-001]
security: [VUL-INPUT-001, VUL-INJ-001, VUL-SECRET-001]
context_files: [docs/requirements/functional/ai/FR-AI-001-ai-agents-tools-streaming-rag-and-mcp.md, docs/requirements/api/ai/API-AI-001-ai-module-contract.md, docs/requirements/data-model/DM-Ai.md, docs/tests/functional/ai/TS-AI-001-ai-agents-tools-streaming-rag-and-mcp.md, src/main/ridgun/lib/ai.rg, src/test/ridgun/test ai.rg]
scope: [src/main/ridgun/lib/ai.rg, src/test/ridgun/test ai.rg, build.rg, target/, build/, docs/]
owner: agent-001
claimed: 2026-10-28T21:00:00Z
claimed_by: agent gemini@solarfall
policy:
---
# TASK-0035 — Implement the `ai` library (`ai.rg`) for AI agents, tool calling, streaming SSE, structured outputs, ReAct loop, guardrails, mini-RAG, handoffs, and MCP JSON-RPC

## Goal (one sentence)
Implement `src/main/ridgun/lib/ai.rg` (`module :: ai`) in 100% pure idiomatic Ridgun v0.9.21+, verify all capabilities with `src/test/ridgun/test ai.rg` (`TS-AI-001`), register `ai` in `build.rg`, and add Chapter 33 across all 7 editions of the `ridgun-libs` book.

## Plan
- [x] Author SDD docs (`FR-AI-001`, `API-AI-001`, `DM-Ai`, `TS-AI-001`, `TASK-0035`) and update `glossary.md`, `field-dictionary.md`, and `INDEX.md` files.
- [x] Implement `src/main/ridgun/lib/ai.rg` (`module :: ai`) covering:
  1. Conversation & `<think>` separation (`ai new conv`, `ai add user`, `ai add assistant`, `ai add tool result`, `ai add tool error`, `ai split thinking`, `ai strip thinking`, `ai estimate tokens`, `ai conv tokens`, `ai trim context`, `ai compact conv`).
  2. Declarative tool schemas & validation (`ai param`, `ai tool`, `ai tool to json`, `ai tools to json`, `ai validate tool call`).
  3. OpenAI, Anthropic, Ollama & XML `<tool_call>` JSON codecs (`ai openai request/parse`, `ai anthropic request/parse`, `ai ollama request/parse`, `ai parse xml tool calls`).
  4. SSE streaming & delta accumulation (`ai parse sse chunk`, `ai stream new`, `ai stream step`, `ai stream finish`).
  5. Structured output extraction & self-repair (`ai extract json`, `ai validate json schema`, `ai build repair prompt`).
  6. Bounded ReAct state machine, usage accounting & replay hashing (`ai policy`, `ai step`, `ai add usage`, `ai request hash`, `ai replay lookup`).
  7. Security guardrails (`ai wrap untrusted`, `ai has injection pattern`, `ai scrub secrets`).
  8. In-memory BM25/TF mini-RAG, multi-agent handoff & MCP JSON-RPC 2.0 (`ai doc`, `ai score doc`, `ai retrieve top k`, `ai inject context`, `ai handoff tool`, `ai is handoff`, `ai apply handoff`, `ai mcp tools list req`, `ai mcp tools call req`, `ai mcp parse response`).
- [x] Register `ai` in `build.rg` and implement `src/test/ridgun/test ai.rg` (`TS-AI-001`).
- [x] Run `ridgunc run --strict "src/test/ridgun/test ai.rg"`, `stable check`, `stable bundle`, add Chapter 33 (`ai`) to all 7 book editions (`docs/book/`), and run `aix docs validate`.

## Progress log (append-only, newest last)
- 2026-10-28: Created `FR-AI-001`, `API-AI-001`, `DM-Ai`, `TS-AI-001`, and started `TASK-0035`.
- 2026-10-29: Implemented `src/main/ridgun/lib/ai.rg` (144 functions, 11 types), `src/test/ridgun/test ai.rg` (`TS-AI-001`), registered `ai` in `build.rg`, added Chapter 33 (`ai`) across all 7 editions of the book (`es`, `ca`, `gl`, `eu`, `en`, `pt`, `sv`), and verified `stable check`, `stable bundle`, and `aix docs validate`.

## Files changed (keep current)
- `src/main/ridgun/lib/ai.rg`
- `src/test/ridgun/test ai.rg`
- `build.rg`
- `docs/requirements/functional/ai/FR-AI-001-ai-agents-tools-streaming-rag-and-mcp.md`
- `docs/requirements/api/ai/API-AI-001-ai-module-contract.md`
- `docs/requirements/data-model/DM-Ai.md`
- `docs/tests/functional/ai/TS-AI-001-ai-agents-tools-streaming-rag-and-mcp.md`
- `docs/book/` (Chapter 33 across all 7 editions + HTML books)

## Verification performed (command → result, newest last)
- `ridgunc check --strict src/main/ridgun/lib/ai.rg` → `0 error(s)`.
- `ridgunc run --strict "src/test/ridgun/test ai.rg"` → `=== ALL ai.rg TESTS PASSED ===`.
- `stable check && stable bundle` → 33 libs checked and bundled cleanly (`target/bundles/ai.rglib`, `target/ai.rgc`, `target/libai.so`).
- `aix docs validate` → `0 error(s), 0 warning(s)`.
