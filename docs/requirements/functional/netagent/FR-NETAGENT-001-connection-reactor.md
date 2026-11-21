---
id: FR-NETAGENT-001
title: Serve many connections in one loop without waiting for any of them
type: functional
status: approved
priority: must
domain: NETAGENT
depends_on: [FR-SOCK-004, FR-POSIX-005]
related: [API-NETAGENT-001, DM-NetAgent, ADR-0015, FR-POOL-001, VUL-INFRA-002, VUL-INPUT-001]
tests: []
---
# FR-NETAGENT-001 — Serve many connections in one loop without waiting for any of them

## Statement
The `net_agent` lib SHALL keep a table of connections and, in each turn of one loop, accept new ones, read what has arrived, give the application the input of each connection and send its queued output, never waiting for one connection while another has work.

## Rationale
Eterval (`server.ridgun`, its ADR-0011) and Vonkeep (`gate.ridgun`) each wrote this loop by hand: a table of connections, an input buffer and an output buffer per connection, limits, and a close for the client that does not read. The `net_agent` lib of today has none of that: each read is taken as a whole message, a reply is sent in one go, and there are no limits. No program uses it.

## Acceptance criteria
- AC1: Given a listening socket with connections pending, when a turn runs, then it accepts those pending without waiting, at most a set number per turn (64 by default), and each one enters the table with an id of its own (from 1) and the address of its peer.
- AC2: Given a table that holds its maximum number of connections, when another one arrives, then it is closed at once and counted as refused, and the connections in the table are not affected.
- AC3: Given connections with bytes to read, when a turn runs, then the bytes of each are added to its input buffer without waiting. A connection closed by its peer leaves the table. A connection whose input buffer passes the input limit leaves the table.
- AC4: Given the input buffer of a connection, when the application takes the complete messages it finds there, then the bytes it did not take stay in the buffer and are offered again, with what arrives later, in a later turn. A message that arrives in several reads is seen whole once.
- AC5: Given output queued for a connection, when a turn runs, then it sends what the peer takes without waiting, keeps the rest queued, and the bytes leave in the order they were queued.
- AC6: Given a peer that stops reading, when its queued output passes the output limit (64 MB by default), then that connection is closed and no other connection is delayed.
- AC7: Given a connection marked to close, when its queued output has been sent, then it is closed, and nothing more is read from it meanwhile.
- AC8: Given a limit for the first complete message and a limit of idle time, when a connection passes either one, then it is closed.
- AC9: Given a turn in which nothing happened, when the loop waits, then it sleeps until a connection, the listening socket or a descriptor the caller added (a signal descriptor, the descriptor of a worker pool) has something, or until its time limit ends: one wait on all of them, not a busy loop.
- AC10: Given a state of the application for each connection, when the application handles a connection, then it gets the state it left there the time before, and the state is released when the connection closes.
- AC11: Given a request to stop, when the loop ends, then it accepts no more connections, sends the queued output for at most a set time, and closes every connection and the listening socket.
- AC12: Given a running loop, then the numbers of connections open, accepted, refused and closed by a limit are available to the caller.

## Actors & permissions
- Any Ridgun program or lib importing `net_agent`.

## Constraints & edge cases
- One thread runs the loop. Work that takes long belongs to a worker pool (`FR-POOL-001`), whose descriptor the loop can wait on (AC9).
- The application decides what a message is: the lib offers bytes and is told how many were taken.
- The application may handle each connection alone or take the input of all of them in one turn (Eterval runs the commands of every connection as one batch).
- A descriptor that fails in the wait, in a read or in a write closes its connection only.

## Data & privacy
- The buffers hold what the peers sent and what the application answered, for as long as the connection is open. The lib writes none of it to a log. See `DM-NetAgent`.

## Security & observability notes
- `VUL-INFRA-002` and `VUL-INPUT-001`: the number of connections, the input held per connection, the output held per connection and the time a silent connection may stay are all bounded.
- The counters of AC12 feed a server's metrics.

## Out of scope
- TLS, HTTP and any message format: they belong to the application or to another lib.
- UDP.
- Limits per client address: the application applies them with the address of AC1 (Solstice does).
- Several loops sharing one listening socket.
