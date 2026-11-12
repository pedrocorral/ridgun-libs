---
id: TS-AI-001
title: Verify AI conversations, thinking separation, tool schemas, OpenAI/Anthropic/Ollama codecs, SSE streaming, structured JSON extraction, ReAct loop, security guardrails, mini-RAG, handoffs, and MCP JSON-RPC
status: automated
level: unit
verifies: [FR-AI-001, API-AI-001]
test_file: "src/test/ridgun/test ai.ridgun"
---
# TS-AI-001 — AI Agent, Tool Calling, Streaming, Structured Output, ReAct, Guardrails, Mini-RAG & MCP Test Suite

## Cases
| Case | Verifies | Input | Expected |
|---|---|---|---|
| `test ai conv thinking and compaction` | AC-1 (`FR-AI-001`) | Conversation with `<think>` blocks, token estimation, `ai trim context`, and `ai compact conv` | Separates `<think>` from clean reply; preserves `system` prompt and `<context_summary>` checkpoint |
| `test ai tools and provider codecs` | AC-2, AC-3 (`FR-AI-001`) | Tool definitions, `ai validate tool call`, and OpenAI / Anthropic / Ollama / XML `<tool_call>` requests & responses | Emits valid JSON schemas, parses `AiReply` and `AiCallTools` with `AiUsage`, rejects unauthorized or incomplete tool calls |
| `test ai sse streaming and structured json` | AC-3, AC-4 (`FR-AI-001`) | Multi-chunk SSE stream with fragmented tool arguments, markdown-fenced JSON, schema validation, and repair prompt | Reassembles complete `AiTurn` on `[DONE]`; extracts balanced JSON from prose/fences and validates required fields |
| `test ai react guardrails rag handoff and mcp` | AC-5 (`FR-AI-001`) | `AiPolicy` step/token limits, prompt-injection detection, secret scrubbing (`sk-`, `ghp_`, `Bearer`), BM25 retrieval, agent handoff, and MCP JSON-RPC | Enforces ReAct budgets, scrubs secrets, retrieves top-$K$ relevant docs, switches agent persona on handoff, and round-trips MCP `tools/list` and `tools/call` |
