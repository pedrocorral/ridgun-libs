---
id: FR-AGENT-001
title: Provide Native Agent lifecycle, timeout-bounded messaging, batch dispatch, and stateful Counter, Log, and Key-Value agents
type: functional
status: implemented
priority: must
domain: AGENT
depends_on: []
related: [ADR-0002, DM-Agent, VUL-INPUT-001]
tests: [TS-AGENT-001]
---
# FR-AGENT-001 — Provide Native Agent lifecycle, timeout-bounded messaging, batch dispatch, and stateful Counter, Log, and Key-Value agents

## Statement
The `agent`, `pool`, and `net_agent` libraries SHALL provide core Native Agent combinators (`agent ask`, `agent try ask`, `agent send batch`, `agent receive count`, `agent map batch`, `agent drain ready`, `agent stop all`), sharded and round-robin agent pools (`AgentPool`, `pool get agent`, `pool ask shard`, `pool abs`, `pool broadcast`, `pool drain all`, `pool shutdown`), per-connection non-blocking `sys poll` agent reactors (`ConnSlot`, `StepOutcome`, `conn poll step`, `conn handle event`, `conn feed payload`, `conn drain outbound`, `reactor sweep`, `reactor shutdown`), typed lifecycle inspection (`AgentStatus`, `format agent status`, `is agent alive`, `agent status`, `stop agent`), synchronous and non-blocking request-reply helpers (`ask int`, `ask str`, `try poll int`, `try poll str`, `ask int with timeout`, `ask str with timeout`), batch sequential dispatch (`ask batch int`, `ask batch str`, `relay int`, `relay str`), and ready-to-use stateful actors built on Ridgun's Native Agent Model (`new counter agent`, `counter add`, `counter get`, `counter reset`, `new log agent`, `log append`, `log read`, `log clear`, `new kv agent`, `kv put`, `kv get`, `kv delete`, `kv has`, `kv count`, `kv keys`, `kv clear`).

## Rationale
Ridgun v0.9.12 provides the low-level Native Agent Model primitives (`agent`, `Agent In Out`, `send ... to`, `receive from`, `try receive from`, `stop`, `agent alive`). Applications require a higher-level standard library (`agent.rg`) with typed reply/status ADTs, bounded-timeout polling, batch/pipeline messaging, and reusable stateful actors (counters, append-only logs/buffers, and in-memory key-value stores) without shared mutable memory.

## Acceptance criteria
- AC1: Given an `Agent In Out` instance, when `is agent alive` and `agent status` are called before and after `stop agent`, then they transition deterministically from `True` / `AgentRunning` to `False` / `AgentStopped`, and `format agent status` / `format agent reply` return human-readable diagnostics.
- AC2: Given an `Agent Int Int` or `Agent String String`, when `ask int`, `ask str`, `try poll int`, `try poll str`, `ask int with timeout`, `ask str with timeout`, `ask batch int`, `ask batch str`, `relay int`, or `relay str` are invoked, then messages are delivered in FIFO mailbox order, stopped agents return `ReplyStopped` without hanging, and empty non-blocking polls return `ReplyEmpty` or `ReplyTimeout ms`.
- AC3: Given stateful agents created with `new counter agent`, `new log agent`, and `new kv agent`, when callers perform state transitions (`counter add`, `counter get`, `counter reset`, `log append`, `log read`, `log clear`, `kv put`, `kv get`, `kv delete`, `kv has`, `kv count`, `kv keys`, `kv clear`), then each agent updates its isolated state deterministically and returns the expected updated value.

## Actors & permissions
- Any Ridgun module importing `agent`.

## Constraints & edge cases
- Polling with `timeout_ms <= 0` performs an immediate non-blocking `try receive from` check and returns `ReplyTimeout 0` if no message is ready.
- Calling `ask *` on a stopped agent immediately returns `ReplyStopped` without sending or blocking.

## Data & privacy
- Agent state is confined to the agent's isolated heap region and released upon `stop`.

## Security & observability notes
- Mitigates `VUL-INPUT-001` by guarding agent request-reply cycles against stopped mailboxes and unbounded waits.

## Out of scope
- Distributed network transport across OS processes (handled by `socket.rg`).
