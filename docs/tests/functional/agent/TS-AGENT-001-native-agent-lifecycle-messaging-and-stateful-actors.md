---
id: TS-AGENT-001
title: Verify Native Agent lifecycle, timeout-bounded messaging, batch dispatch, and stateful Counter, Log, and Key-Value agents
level: unit
covers: [FR-AGENT-001, API-AGENT-001]
status: automated
automated_in: [src/test/ridgun/test agent.ridgun]
---
# TS-AGENT-001 — Verify Native Agent lifecycle, timeout-bounded messaging, batch dispatch, and stateful Counter, Log, and Key-Value agents

## Preconditions / fixtures
- Pure-Ridgun `agent`, `list`, `pool`, `net_agent`, and `test` modules (`src/main/ridgun/lib/agent.ridgun`, `src/main/ridgun/lib/list.ridgun`, `src/main/ridgun/lib/pool.ridgun`, `src/main/ridgun/lib/net_agent.ridgun`, `src/main/ridgun/lib/test.ridgun`).
- The `socket` module and the loopback interface (`127.0.0.1`), for a real TCP connection in step 7.

## Steps / inputs
1. Test core spec combinators (`agent ask`, `agent map batch`, `agent send batch`, `agent receive count`, `agent drain ready`, `agent stop all`), sharded pool operations (`Pool`, `pool ask shard`, `pool broadcast`, `pool drain all`, `pool shutdown`), and per-connection reactor lifecycle (`ConnSlot`, `conn feed payload` EOF, `conn handle event` POLLERR, `reactor sweep next`, `reactor shutdown`).
2. Spawn a counter agent via `new counter agent 10`; verify `is agent alive` is `True` and `agent status` formats as `"running"`; verify `format agent status` and `format agent reply` for all variants.
3. Perform `counter add c 5`, `counter add c 7`, `counter get c`, and `counter reset c`; verify values `15`, `22`, `22`, and `0`; test `ask batch int`, `relay int`, `try poll int`, and `ask int with timeout`; stop the agent with `stop agent` and verify `is agent alive` is `False` and subsequent `ask int` returns `ReplyStopped`.
4. Spawn a log agent via `new log agent "\n"`; call `log append` with `"alpha"`, `"beta"`, `"gamma"`, verify `log read` returns `"alpha\nbeta\ngamma"`, verify `log clear` resets the buffer, and stop the agent.
5. Import both `agent` and `list` in the same test module (`RG-066`), spawn a key-value store agent via `new kv agent`, test `agent kv put`, `agent kv get`, `agent kv has`, `agent kv count`, `agent kv keys`, `agent kv delete`, and `agent kv clear` alongside `list kv put`, `list kv get`, and `list kv keys`, and stop the agent.
6. Build a `Pool 3` of counter agents; call `pool ask shard` with the keys `0`, `1`, `2`, `3`, `7` (twice) and `-2` and verify which agent answers each one; verify `pool drain all` is `[]` when nothing is ready; call `pool broadcast` and read every counter; verify a pool of one agent takes any key; verify `pool shutdown` stops the agents.
7. Open a loopback TCP connection (`sys tcp listen` on port 0, `sys tcp connect`, `sys accept`) and pair the accepted descriptor with an echo agent in a `ConnSlot`; verify `conn poll step` with no data keeps the slot and writes nothing; send `ping` and then `pong` from the client and verify the replies `echo:1:ping` and `echo:2:pong` reach the client; verify `reactor sweep` keeps the live slot; close the client and verify `reactor sweep` drops the slot and the agent is stopped.

## Expected results (map to acceptance criteria)
- AC1 → Lifecycle predicates and status formatters accurately reflect running and stopped states.
- AC2 → Synchronous, non-blocking, timeout-bounded, batch, and relay messaging helpers return expected `AgentReply` values and handle stopped agents safely.
- AC3 → Counter, Log, and Key-Value stateful agents (`agent kv *`) maintain isolated state across sequential messages, support reset/clear operations, and coexist cleanly with `import list` (`RG-066`).
- AC4 → `pool ask shard` reaches agent `abs(key) % size` (same key, same agent; keys in turn, agents in turn; negative keys valid); `pool broadcast`, `pool drain all` and `pool shutdown` act on every agent.
- AC5 → Over a real connection, `conn poll step` passes the data to the agent and writes its reply, the agent keeps its state between messages, and a connection closed by the peer leaves the table with its agent stopped.

## Not covered here (to avoid duplication)
- OS-level process signals (covered in `TS-POSIX-002`).
