---
id: FR-AI-001
title: Provide AI agent conversations, thinking separation, tool schemas, OpenAI/Anthropic/Ollama JSON & SSE codecs, structured outputs, ReAct loop, guardrails, mini-RAG, handoffs, and MCP JSON-RPC
status: implemented
priority: critical
domain: AI
owner: platform
depends_on: [ADR-0001, ADR-0002]
apis: [API-AI-001]
data_models: [DM-Ai]
tests: [TS-AI-001]
security: [VUL-INPUT-001, VUL-INJ-001, VUL-SECRET-001]
---
# FR-AI-001 — AI Agent, Tool Calling, Streaming, Structured Output, ReAct, Guardrails, Mini-RAG & MCP Library (`ai.ridgun`)

## Statement
The `ai` library (`src/main/ridgun/lib/ai.ridgun`, `module :: ai`, imported via `import ai`) **shall** provide a 100% pure-Ridgun toolkit for building deterministic, secure AI agents:
1. **Conversation, `<think>` Separation & Context Window Management**:
   - Typed messages (`AiMsg`) with roles (`system`, `user`, `assistant`, `tool`), `tool_call_id`, `is_tool_error`, and conversation state (`AiConv`) tracking step count and cumulative token usage (`AiUsage`).
   - Separation of reasoning blocks (`<think>...</think>`) from clean output via `ai split thinking String => String String` and stripping historical `<think>` blocks via `ai strip thinking String => String`.
   - Deterministic token estimation (`ai estimate tokens`), sliding-window truncation (`ai trim context`) that always preserves the `system` prompt, and structured compaction (`ai compact conv`) that injects a `<context_summary>...</context_summary>` checkpoint while keeping the `system` prompt, initial goal, and last $N$ messages.
2. **Declarative Tool Schemas & Argument Validation**:
   - Tool parameter (`AiParam`) and tool definition (`AiTool`) constructors (`ai param`, `ai tool`), JSON Schema serialization (`ai tool to json`, `ai tools to json`), and strict tool-call validation (`ai validate tool call`) checking tool allow-lists and required JSON fields.
3. **Provider-Agnostic JSON Request/Response Codecs & SSE Streaming**:
   - Pure JSON request builders and response parsers for **OpenAI** (`ai openai request`, `ai openai parse`), **Anthropic** (`ai anthropic request`, `ai anthropic parse`), and **Ollama** (`ai ollama request`, `ai ollama parse`), plus `<tool_call>...</tool_call>` tag extraction (`ai parse xml tool calls`) returning a unified `AiTurn` (`AiReply`, `AiCallTools`, `AiStopError`) and `AiUsage`.
   - Incremental SSE (*Server-Sent Events*) parsing (`ai parse sse chunk`) and stream delta accumulation (`ai stream new`, `ai stream step`, `ai stream finish`) capable of reassembling streamed text, `<think>` blocks, and fragmented tool-call arguments across multiple chunks.
4. **Structured Outputs, Dirty JSON Extraction & Self-Repair**:
   - Extraction of balanced `{...}` or `[...]` JSON blocks from markdown code fences or prose (`ai extract json`), required-field validation against `[AiParam]` (`ai validate json schema`), and deterministic self-repair prompt generation (`ai build repair prompt`).
5. **Bounded ReAct State Machine, Usage Accounting & Replay Hashing**:
   - Explicit `AiPolicy` (`max_steps`, `max_tokens`, `allowed_tools`) and pure transition function (`ai step`) returning `AiDecisionDone`, `AiDecisionRunTools`, or `AiDecisionAbort` on step/token budget exhaustion or unauthorized tool calls.
   - Deterministic request hashing (`ai request hash`) for replay/caching tables (`ai replay lookup`).
6. **AI Security Guardrails (Prompt Injection & Secret Exfiltration)**:
   - Untrusted input boundary wrapping (`ai wrap untrusted`), prompt-injection heuristic detection (`ai has injection pattern`), and outbound secret redaction (`ai scrub secrets` scrubbing `sk-`, `ghp_`, `AKIA`, `Bearer `) before sending data to external LLMs.
7. **In-Memory Mini-RAG, Multi-Agent Handoff & MCP JSON-RPC 2.0**:
   - Lexical relevance scoring and top-$K$ document retrieval (`ai doc`, `ai score doc`, `ai retrieve top k`, `ai inject context`).
   - Multi-agent handoff formatting and detection (`ai handoff tool`, `ai is handoff`, `ai apply handoff`).
   - Model Context Protocol (MCP) JSON-RPC 2.0 request/response builders and parsers (`ai mcp tools list req`, `ai mcp tools call req`, `ai mcp parse response`).

## Acceptance criteria
- **AC-1 (Conversations, `<think>` & Compaction):** `ai split thinking "<think>plan</think>answer"` returns `("plan", "answer")`; `ai trim context` and `ai compact conv` preserve the `system` prompt and keep recent turns within budget.
- **AC-2 (Tool Schemas & Validation):** `ai tool to json` emits valid JSON Schema; `ai validate tool call` accepts valid calls and rejects unknown tools or missing required parameters.
- **AC-3 (OpenAI, Anthropic, Ollama & SSE Streaming):** Request builders and response parsers round-trip text replies, parallel tool calls, and token usage; `ai stream step` + `ai stream finish` reassemble fragmented SSE text and tool-call argument deltas and stop on `[DONE]`.
- **AC-4 (Structured Outputs & Repair):** `ai extract json` extracts JSON from markdown fences or surrounding prose; `ai validate json schema` and `ai build repair prompt` validate and generate repair prompts.
- **AC-5 (ReAct Loop, Guardrails, Mini-RAG, Handoff & MCP):** `ai step` enforces `max_steps`, `max_tokens`, and `allowed_tools`; `ai scrub secrets` redacts secrets; `ai retrieve top k` ranks matching documents above irrelevant ones; `ai apply handoff` switches system persona while preserving context; MCP JSON-RPC helpers build and parse `tools/list` and `tools/call` frames.
