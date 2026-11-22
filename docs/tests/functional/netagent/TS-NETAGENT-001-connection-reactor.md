---
id: TS-NETAGENT-001
title: Verify the connection reactor over real sockets
level: functional
covers: [FR-NETAGENT-001]
status: automated
automated_in: [src/test/ridgun/test net_agent.ridgun]
---
# TS-NETAGENT-001 — Verify the connection reactor over real sockets

## Preconditions / fixtures
- TCP listeners on `127.0.0.1` with ports chosen by the kernel, and clients made by the test in the same process. A pipe and a worker pool of one worker for the descriptors of the caller. No network outside the machine.

## Steps / inputs
1. `test reactor accepts and refuses`: the defaults of `reactor defaults`. With a table of 2 and 2 accepts in a turn, three clients connect: the first turn accepts two (ids 1 and 2, peer `127.0.0.1`), the second refuses the third, which sees its connection closed, and the two in the table stay. A client closes: its connection leaves. A new client gets id 3. The counters after each step.
2. `test reactor input messages and state`: a message sent in two parts is in the input whole, once; taking 0 bytes leaves it; taking the message leaves the start of the next, which is offered again with what arrives later. The state of a connection: the default, the one that was left, and one of its own for each connection. `reactor each` with a protocol of lines: one call for each connection, the line taken, the part kept, the answers in their order, and `quit` answered and closed.
3. `test reactor output and the peer that does not read`: two outputs queued leave in their order. Two million bytes arrive whole over several turns. With two million bytes queued for a client that does not read, five turns take under 1.5 s and the other connection is answered meanwhile. Past the output limit (3 MB, with 14 MB queued) that connection is closed and counted, and only that one. A connection marked to close, with 1.5 MB queued and bytes the client sent after the mark: nothing is read from it, the client gets the 1.5 MB whole and then the end, and the connection leaves the table when the client closes. A client that never closes is closed after one second. Past the input limit a connection is closed and counted.
4. `test reactor time limits`: with 150 ms for the first message, the connection that sent none is closed and the one whose message was taken stays. With an idle limit of 150 ms, a connection stays while it is active and is closed after it goes silent.
5. `test reactor waits on everything at once`: a turn with nothing to do sleeps for its limit and answers nothing. A byte in a pipe of the caller, a new connection and bytes on a connection each wake a turn of 5 s at once. The descriptor of a worker pool is named when its job ends.
6. `test reactor stop`: the queued output reaches each client, the connections are closed, nobody can connect to the port any more, and the counters come back. With three million bytes queued for a client that does not read, a stop of 300 ms ends in under 2 s.

## Expected results (map to acceptance criteria)
- AC1, AC2, AC12 → step 1.
- AC3 → steps 1, 2 and 3.
- AC4, AC10 → step 2.
- AC5, AC6, AC7 → step 3 (and step 2 for the order of the answers).
- AC8 → step 4.
- AC9 → step 5.
- AC11 → step 6.

## Not covered here (to avoid duplication)
- The wait on many descriptors itself: `TS-POSIX-005`.
- The worker pool: `TS-POOL-001`.
