---
id: TS-POSIX-005
title: Verify the wait on many descriptors at once
level: unit
covers: [FR-POSIX-005]
status: automated
automated_in: [src/test/ridgun/test posix.ridgun]
---
# TS-POSIX-005 — Verify the wait on many descriptors at once

## Preconditions / fixtures
- Pipes, a TCP listener on `127.0.0.1` with a port chosen by the kernel, and a signal descriptor for `SIGUSR1`, all made by the test. No network outside the machine.

## Steps / inputs
1. `test posix wait on many descriptors`: `posix wait many [] [] 60` waits at least 50 ms and answers three empty lists. Three empty pipes with a limit of `0`, of 60 ms and under `0` answer nothing; the 60 ms call waits for its limit.
2. Bytes are written into two of the three pipes: the call with a limit of 5 s returns at once and names those two, in the order given; another order of the call gives that order. The bytes are still there after the wait. After reading one pipe only the other is named.
3. Write ends of pipes with room are named as ready to write. A descriptor given in both lists is answered in each.
4. A closed descriptor, the number `999999`, the number `-1` and the write end of a pipe whose reader is closed are named as failed, once each, and the other descriptors of the same call are still answered. A pipe whose writer closed is ready to read and not failed.
5. A listening socket, a signal descriptor and a pipe in one call: only the pipe is ready. After a client connects, the listener is ready. After `SIGUSR1`, the signal descriptor is ready and the client socket is ready to write. After the client sends, the accepted connection is ready, and it stays ready when the client closes.
6. 1 024 entries in one call: 400 pipes, 624 read entries (224 descriptors given twice) and 400 write entries, a byte in every second pipe. The 200 pipes with a byte are named (112 of them twice), all 400 write ends are ready, none failed. After closing them, all 800 are named as failed.

## Expected results (map to acceptance criteria)
- AC1 → steps 2 and 3.
- AC2 → step 1.
- AC3 → step 4.
- AC4 → step 5.
- AC5 → step 6.

## Not covered here (to avoid duplication)
- `wait fd` on one descriptor: `TS-POSIX-001`.
