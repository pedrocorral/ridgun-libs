---
id: API-AI-001
title: Public lib contract for ai (ai.rglib / libai.so)
status: implemented
implements: [FR-AI-001]
auth: none
---
# API-AI-001 — Public lib contract for `ai` (`ai.rg`)

## Request
- Imported via `import ai`.
- Public Types (see `DM-Ai`):
  - `type AiMsg = am_role: String, am_content: String, am_tool_id: String, am_is_err: Bool`
  - `type AiUsage = au_prompt: Int, au_completion: Int, au_total: Int`
  - `type AiConv = ac_system: String, ac_msgs: [AiMsg], ac_steps: Int, ac_usage: AiUsage`
  - `type AiParam = ap_name: String, ap_type: String, ap_desc: String, ap_req: Bool`
  - `type AiTool = at_name: String, at_desc: String, at_params: [AiParam]`
  - `type AiToolCall = atc_id: String, atc_name: String, atc_args: String`
  - `type AiTurn = AiReply String AiUsage | AiCallTools String [AiToolCall] AiUsage | AiStopError Int String`
  - `type AiStreamAcc = asa_text: String, asa_think: String, asa_tid: String, asa_tname: String, asa_targs: String, asa_done: Bool`
  - `type AiPolicy = apol_max_steps: Int, apol_max_tokens: Int, apol_allowed: [String]`
  - `type AiStepDecision = AiDecisionDone String | AiDecisionRunTools [AiToolCall] | AiDecisionAbort String`
  - `type AiDoc = ad_id: String, ad_title: String, ad_body: String`
- Public Functions:
  - Conversation & `<think>`: `ai new conv`, `ai add user`, `ai add assistant`, `ai add tool result`, `ai add tool error`, `ai split thinking`, `ai strip thinking`, `ai estimate tokens`, `ai conv tokens`, `ai trim context`, `ai compact conv`
  - Tools & Validation: `ai param`, `ai tool`, `ai tool to json`, `ai tools to json`, `ai validate tool call`
  - Provider JSON & XML Codecs: `ai openai request`, `ai openai parse`, `ai anthropic request`, `ai anthropic parse`, `ai ollama request`, `ai ollama parse`, `ai parse xml tool calls`
  - SSE Streaming: `ai parse sse chunk`, `ai stream new`, `ai stream step`, `ai stream finish`
  - Structured Outputs: `ai extract json`, `ai validate json schema`, `ai build repair prompt`
  - ReAct, Usage & Replay: `ai policy`, `ai step`, `ai add usage`, `ai request hash`, `ai replay lookup`
  - Security Guardrails: `ai wrap untrusted`, `ai has injection pattern`, `ai scrub secrets`
  - Mini-RAG, Handoff & MCP: `ai doc`, `ai score doc`, `ai retrieve top k`, `ai inject context`, `ai handoff tool`, `ai is handoff`, `ai apply handoff`, `ai mcp tools list req`, `ai mcp tools call req`, `ai mcp parse response`

## Responses
| Code | When | Body |
|---|---|---|
| `AiTurn` | Provider response parse or SSE stream finish | `AiReply`, `AiCallTools`, or `AiStopError` |
| `AiStepDecision` | `ai step` | `AiDecisionDone`, `AiDecisionRunTools`, or `AiDecisionAbort` |

## Rules
- All functions are total and never crash on malformed JSON, empty streams, or untrusted strings.
