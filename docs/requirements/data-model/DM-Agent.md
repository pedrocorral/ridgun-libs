---
id: DM-Agent
title: Native Agent status, reply, and stateful actor models
status: approved
related: [FR-AGENT-001, API-AGENT-001, ADR-0002]
---
# DM-Agent — Native Agent status, reply, and stateful actor models

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| agent_state | String | `"running"`, `"stopped"`, `"timeout"`, `"error"` | Formatted lifecycle or reply status of an `Agent In Out` instance |
| timeout_ms | Int | `>= 0` | Millisecond deadline for bounded agent reply polling |
| item_count | Int | `>= 0` | Current integer count or key-value entry count held by a stateful agent |

## Relations
- Defined in `agent.rg` (`type AgentStatus = AgentRunning | AgentStopped | AgentTimedOut Int | AgentFailed String`, `type AgentReply = ReplyInt Int | ReplyStr String | ReplyBool Bool | ReplyEmpty | ReplyStopped | ReplyTimeout Int | ReplyError String`, `type KvCmd = KvPut String String | KvGet String | KvDel String | KvHas String | KvCount | KvKeys | KvClear`), `pool.rg` (`type AgentPool = Pool Int [Agent]`), and `net_agent.rg` (`type ConnSlot = ConnSlot Int Agent`, `type StepOutcome = ConnKeep ConnSlot String | ConnClosed`) on top of Ridgun v0.9.14's built-in `Agent` concurrency model.

## Invariants
- Every agent encapsulates its mutable state exclusively inside its sequential `agent` loop (`RMM1`/`RMM2` isolated mailbox); callers interact solely by passing immutable messages via `send ... to` and receiving replies via `receive from` or `try receive from`.
- Sending to or receiving from a stopped agent never blocks indefinitely; lifecycle predicates (`is agent alive`, `agent status`) and timeout-bounded helpers (`ask int with timeout`, `ask str with timeout`) return typed status/reply variants.

## Lifecycle
- Spawned via `new counter agent`, `new log agent`, `new kv agent`, or custom `agent` definitions; queried via `ask *` / `try poll *`; and terminated deterministically via `stop agent`.
