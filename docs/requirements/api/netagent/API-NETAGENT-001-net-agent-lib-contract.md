---
id: API-NETAGENT-001
title: Public lib contract for net_agent (net_agent.ridgunlib)
status: approved
implements: [FR-NETAGENT-001]
auth: none
---
# API-NETAGENT-001 — Public lib contract for `net_agent` (`net_agent.ridgun`)

## Request
- Imported via `import net_agent`. `S` is the state the application keeps for each connection.
- Configuration:
  - `type ReactorConfig = max_conn_count: Int, max_accept_count: Int, input_limit_bytes: Int, output_limit_bytes: Int, first_message_limit_ms: Int, idle_limit_ms: Int`
  - `reactor defaults => ReactorConfig`: 1 024 connections, 64 accepted per turn, 64 MB of input, 64 MB of output, no limit for the first message, no idle limit
  - `reactor with max conns`, `reactor with max accepts`, `reactor with input limit`, `reactor with output limit`, `reactor with first message limit`, `reactor with idle limit`: each `ReactorConfig Int => ReactorConfig`
- The loop:
  - `type Reactor S` (fields private, see `DM-NetAgent`)
  - `reactor start Int ReactorConfig => Reactor S`: the `fd` of a listening socket
  - `reactor turn (Reactor S) [Int] Int => (Reactor S) [Int]`: one turn. It waits at most `timeout_ms` on the listening socket, on every connection and on the descriptors of the caller given in the list; then it accepts, reads, sends and applies the limits. The answer names the caller's descriptors that are ready
  - `reactor stop (Reactor S) Int => ReactorStats`: `timeout_ms` to send the queued output; then everything is closed
- What a turn left:
  - `reactor arrived (Reactor S) => [Int]`: the `conn_id` of the connections that entered the table in the last turn
  - `reactor ready (Reactor S) => [Int]`: the `conn_id` of the connections with input not taken yet
  - `reactor left (Reactor S) => [Int]`: the `conn_id` of the connections closed in the last turn
- One connection:
  - `reactor input (Reactor S) Int => String`: its `input_buf`
  - `reactor take (Reactor S) Int Int => Reactor S`: drops the first bytes of its `input_buf`
  - `reactor send (Reactor S) Int String => Reactor S`: adds to its `output_buf`
  - `reactor close after send (Reactor S) Int => Reactor S`
  - `reactor peer (Reactor S) Int => String`: its `peer_ip`
  - `reactor state (Reactor S) Int S => S`: its state, or the default given when it has none
  - `reactor set state (Reactor S) Int S => Reactor S`
- The simple case, each connection on its own:
  - `type ConnStep S = ConnStep S Int String Bool`: the next state, the bytes taken from the input, the output to queue, close after sending
  - `reactor each (Reactor S) S (S String => ConnStep S) => Reactor S`: calls the function once for every ready connection, with its state (the given first state for a new one) and its input
- Counters:
  - `type ReactorStats = open_count: Int, accepted_count: Int, refused_count: Int, dropped_count: Int`
  - `reactor stats (Reactor S) => ReactorStats`

## Responses
| Code | When | Body |
|---|---|---|
| `Reactor S` | every operation that changes the table | The reactor to use from now on |
| `[Int]` | `turn` | The caller's descriptors that are ready |
| `[Int]` | `arrived`, `ready`, `left` | Ids of connections; `[]` when there is none |
| `""` | `input`, `peer` | The id is not in the table |
| `ReactorStats` | `stats`, `stop` | The counters at that moment |

## Rules
- Every exported function starts with `reactor `.
- No operation waits for a peer: `reactor turn` is the only one that waits, and it waits for all descriptors at once (`FR-POSIX-005`).
- An operation on an id that is not in the table changes nothing.
- A limit of `0` in `first_message_limit_ms` or `idle_limit_ms` means no limit.
- A connection marked to close is closed in order: when its output is sent only its sending side is shut, what the peer still sends is thrown away, and the socket is closed when the peer closes or after one second. The peer loses no output.
- `ConnSlot`, `StepOutcome`, `conn poll step`, `reactor sweep` and `reactor shutdown` left the lib with this contract (`ADR-0015`).
