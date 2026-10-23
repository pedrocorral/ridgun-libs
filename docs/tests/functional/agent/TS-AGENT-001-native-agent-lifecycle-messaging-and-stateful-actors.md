---
id: TS-AGENT-001
title: Verify Native Agent lifecycle, timeout-bounded messaging, batch dispatch, and stateful Counter, Log, and Key-Value agents
level: unit
covers: [FR-AGENT-001, API-AGENT-001]
status: automated
automated_in: [src/test/ridgun/test agent.rg]
---
# TS-AGENT-001 — Verify Native Agent lifecycle, timeout-bounded messaging, batch dispatch, and stateful Counter, Log, and Key-Value agents

## Preconditions / fixtures
- Pure-Ridgun `agent`, `pool`, `net_agent`, and `test` modules (`src/main/ridgun/lib/agent.rg`, `src/main/ridgun/lib/pool.rg`, `src/main/ridgun/lib/net_agent.rg`, `src/main/ridgun/lib/test.rg`).

## Steps / inputs
1. Test core spec combinators (`agent ask`, `agent map batch`, `agent send batch`, `agent receive count`, `agent drain ready`, `agent stop all`), sharded pool operations (`Pool`, `pool ask shard`, `pool broadcast`, `pool drain all`, `pool shutdown`), and per-connection reactor lifecycle (`ConnSlot`, `conn feed payload` EOF, `conn handle event` POLLERR, `reactor sweep next`, `reactor shutdown`).
2. Spawn a counter agent via `new counter agent 10`; verify `is agent alive` is `True` and `agent status` formats as `"running"`; verify `format agent status` and `format agent reply` for all variants.
3. Perform `counter add c 5`, `counter add c 7`, `counter get c`, and `counter reset c`; verify values `15`, `22`, `22`, and `0`; test `ask batch int`, `relay int`, `try poll int`, and `ask int with timeout`; stop the agent with `stop agent` and verify `is agent alive` is `False` and subsequent `ask int` returns `ReplyStopped`.
4. Spawn a log agent via `new log agent "\n"`; call `log append` with `"alpha"`, `"beta"`, `"gamma"`, verify `log read` returns `"alpha\nbeta\ngamma"`, verify `log clear` resets the buffer, and stop the agent.
5. Spawn a key-value store agent via `new kv agent`; test `kv put`, `kv get`, `kv has`, `kv count`, `kv keys`, `kv delete`, and `kv clear`, and stop the agent.

## Expected results (map to acceptance criteria)
- AC1 → Lifecycle predicates and status formatters accurately reflect running and stopped states.
- AC2 → Synchronous, non-blocking, timeout-bounded, batch, and relay messaging helpers return expected `AgentReply` values and handle stopped agents safely.
- AC3 → Counter, Log, and Key-Value stateful agents maintain isolated state across sequential messages and support reset/clear operations.

## Not covered here (to avoid duplication)
- OS-level process signals (covered in `TS-POSIX-002`).
