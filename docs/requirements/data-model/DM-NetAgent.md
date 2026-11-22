---
id: DM-NetAgent
title: Reactor, its configuration and its table of connections
status: draft
related: [FR-NETAGENT-001, API-NETAGENT-001, ADR-0015]
---
# DM-NetAgent — Reactor, its configuration and its table of connections

## Fields
| Field | Type | Constraints | Notes |
|---|---|---|---|
| max_conn_count | Int | `>= 1` | `ReactorConfig`; 1 024 by default |
| max_accept_count | Int | `>= 1` | `ReactorConfig`; 64 by default |
| input_limit_bytes | Int | `>= 1` | `ReactorConfig`; 64 MB by default |
| output_limit_bytes | Int | `>= 1` | `ReactorConfig`; 64 MB by default |
| first_message_limit_ms | Int | `>= 0` | `ReactorConfig`; `0` is no limit |
| idle_limit_ms | Int | `>= 0` | `ReactorConfig`; `0` is no limit |
| fd | Int | `>= 0` | The listening socket of the reactor, and the descriptor of each connection |
| conn_id | Int | from `1`, never reused | One connection of the table |
| peer_ip | String | | Address of the peer, as the accept gave it |
| input_buf | String | at most `input_limit_bytes` | Bytes read and not taken by the application |
| output_buf | String | at most `output_limit_bytes` | Bytes queued and not taken by the peer |
| is_closing | Bool | | Close when `output_buf` is empty |
| last_active_ms | Int | monotonic | For `idle_limit_ms` and `first_message_limit_ms` |
| open_count | Int | `0 .. max_conn_count` | `ReactorStats` |
| accepted_count | Int | `>= 0` | `ReactorStats` |
| refused_count | Int | `>= 0` | `ReactorStats`: closed on arrival because the table was full |
| dropped_count | Int | `>= 0` | `ReactorStats`: closed for passing a limit |

## Relations
- Each connection carries one value of the state type the application chose; the reactor never reads it.

## Invariants
- A `conn_id` names at most one connection and is never given again.
- The bytes of `output_buf` leave in the order they were queued.
- A connection with `is_closing` set is not read any more.
- A descriptor is closed exactly once, when its connection leaves the table.

## Lifecycle
- A connection enters the table when it is accepted; it leaves when its peer closes, when it passes a limit, when it was marked to close, its output is sent and its peer has closed (or one second has passed), or when the reactor stops.
- In the code the fields of a connection carry the prefix `cn_` and those of the reactor `rx_` (`cn_in` is `input_buf`, `cn_out` is `output_buf`, `cn_closing` is `is_closing`, `cn_active` is `last_active_ms`).
