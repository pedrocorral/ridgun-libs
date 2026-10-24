---
id: API-AGENT-001
title: Public lib contract for agent (agent.rglib / libagent.so)
status: approved
implements: [FR-AGENT-001]
auth: none
---
# API-AGENT-001 — Public lib contract for `agent` (`agent.rg`)

## Request
- Imported via `import agent`.
- Inputs (see `DM-Agent`): `timeout_ms` (`Int`), `agent_state` (`String`), `item_count` (`Int`).
- Lifecycle & Reply Types:
  - `type AgentStatus = AgentRunning | AgentStopped | AgentTimedOut Int | AgentFailed String`
  - `type AgentReply = ReplyInt Int | ReplyStr String | ReplyBool Bool | ReplyEmpty | ReplyStopped | ReplyTimeout Int | ReplyError String`
  - `type KvCmd = KvPut String String | KvGet String | KvDel String | KvHas String | KvCount | KvKeys | KvClear`
  - `format agent status AgentStatus => String`
  - `format agent reply AgentReply => String`
- Core Combinators (`agent.rg`):
  - `agent ask Agent A => B`
  - `agent try ask Agent A => Option`
  - `agent send batch Agent [A] => ()`
  - `agent receive count Agent Int => [B]`
  - `agent map batch Agent [A] => [B]`
  - `agent drain ready Agent => [B]`
  - `agent stop all [Agent] => ()`
- Sharded & Round-Robin Agent Pools (`pool.rg`):
  - `type AgentPool = Pool Int [Agent]`
  - `pool get agent [Agent] Int => Agent`
  - `pool ask shard AgentPool Int A => B`
  - `pool abs Int => Int`
  - `pool broadcast AgentPool A => ()`
  - `pool drain all AgentPool => [B]`
  - `pool shutdown AgentPool => ()`
- Per-Connection Stateful Agent Reactor (`net_agent.rg`):
  - `type ConnSlot = ConnSlot Int Agent`
  - `type StepOutcome = ConnKeep ConnSlot String | ConnClosed`
  - `conn poll step ConnSlot => StepOutcome`
  - `conn handle event Int Agent Int => StepOutcome`
  - `conn feed payload Int Agent String => StepOutcome`
  - `conn drain outbound Int Agent Option => StepOutcome`
  - `reactor sweep [ConnSlot] => [ConnSlot]`
  - `reactor shutdown [ConnSlot] => ()`
- Lifecycle & Messaging Operations:
  - `is agent alive (Agent A B) => Bool`
  - `agent status (Agent A B) => AgentStatus`
  - `stop agent (Agent A B) => AgentStatus`
  - `ask int (Agent Int Int) Int => AgentReply`
  - `ask str (Agent String String) String => AgentReply`
  - `try poll int (Agent A Int) => AgentReply`
  - `try poll str (Agent A String) => AgentReply`
  - `ask int with timeout (Agent Int Int) Int Int => AgentReply`
  - `ask str with timeout (Agent String String) String Int => AgentReply`
  - `ask batch int (Agent Int Int) [Int] => [Int]`
  - `ask batch str (Agent String String) [String] => [String]`
  - `relay int (Agent Int Int) (Agent Int Int) Int => AgentReply`
  - `relay str (Agent String String) (Agent String String) String => AgentReply`
- Reusable Stateful Agents:
  - `new counter agent Int => Agent Int Int`
  - `counter add (Agent Int Int) Int => Int`, `counter get (Agent Int Int) => Int`, `counter reset (Agent Int Int) => Int`
  - `new log agent String => Agent String String`
  - `log append (Agent String String) String => String`, `log read (Agent String String) => String`, `log clear (Agent String String) => String`
  - `new kv agent => Agent KvCmd String`
  - `agent kv put (Agent KvCmd String) String String => String`, `agent kv get (Agent KvCmd String) String => String`, `agent kv delete (Agent KvCmd String) String => String`, `agent kv has (Agent KvCmd String) String => Bool`, `agent kv count (Agent KvCmd String) => Int`, `agent kv keys (Agent KvCmd String) => String`, `agent kv clear (Agent KvCmd String) => String`

## Responses
| Code | When | Body |
|---|---|---|
| `ReplyInt n` / `ReplyStr s` / `ReplyBool b` | Agent processed message and replied | Typed payload |
| `ReplyEmpty` | Non-blocking poll found no message in outbox | `ReplyEmpty` (`"agent outbox empty"`) |
| `ReplyStopped` | Target agent is stopped | `ReplyStopped` (`"agent stopped"`) |
| `ReplyTimeout ms` | Agent did not reply within `timeout_ms` | `ReplyTimeout ms` (`"agent timeout after {ms} ms"`) |
| `ReplyError msg` | Agent operation failed | `ReplyError msg` (`"agent error: {msg}"`) |

## Rules
- All public functions use natural space-separated Ridgun names (`new counter agent`, `ask int with timeout`, `agent kv get`, etc.) and avoid colliding with `list.rg` (`RG-066`).
- Calling `ask *` or `relay *` checks `agent alive` before sending so stopped agents never block the caller.
