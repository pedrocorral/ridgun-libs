---
id: DM-Ai
title: AI agent conversations, tool schemas, streaming, ReAct policy, mini-RAG, and MCP models
status: implemented
related: [FR-AI-001, API-AI-001, ADR-0002]
---
# DM-Ai — AI agent conversations, tool schemas, streaming, ReAct policy, mini-RAG, and MCP models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| role_name | String | `system`, `user`, `assistant`, `tool` | Role discriminator of an `AiMsg` |
| tool_call_id | String | Non-empty for tool calls/results | Correlates `AiToolCall` and tool observation messages |
| max_steps | Int | `>= 1` | Maximum ReAct iterations allowed by `AiPolicy` |
| max_tokens | Int | `>= 1` | Maximum context or cumulative token budget in `AiPolicy` |
| prompt_tokens | Int | `>= 0` | Input token count in `AiUsage` |
| completion_tokens | Int | `>= 0` | Output token count in `AiUsage` |
| is_tool_error | Bool | `True` or `False` | Indicates whether a tool result reports a recoverable execution error |

## Relations
- Used by `ai.ridgun` (`AiMsg`, `AiConv`, `AiParam`, `AiTool`, `AiToolCall`, `AiUsage`, `AiTurn`, `AiStreamAcc`, `AiPolicy`, `AiStepDecision`, `AiDoc`) to represent multi-turn LLM conversations, tool schemas, streaming SSE deltas, ReAct state transitions, BM25/TF document retrieval, multi-agent handoffs, and MCP JSON-RPC frames.

## Invariants
- `ai trim context` and `ai compact conv` always preserve the leading `system` prompt message.
- `ai step` refuses to execute any `AiToolCall` when `step_count >= max_steps`, when cumulative tokens exceed `max_tokens`, or when the tool name is not in `allowed_tools`.
- `ai scrub secrets` redacts API keys and bearer tokens before external transmission.

## Lifecycle
- Constructed and transformed purely in memory under `RMM1`/`RMM2`.
