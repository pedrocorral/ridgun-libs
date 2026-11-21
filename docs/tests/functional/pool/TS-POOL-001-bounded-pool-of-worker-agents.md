---
id: TS-POOL-001
title: Verify the bounded pool of worker agents and the routing by key
status: automated
level: unit
domain: POOL
covers: [FR-POOL-001, API-POOL-001]
automated_in: [src/test/ridgun/test pool.ridgun]
---
# TS-POOL-001 — Verify the bounded pool of worker agents and the routing by key

## Preconditions / fixtures
- The `pool`, `agent`, `posix` and `test` libs.
- A worker function whose state is the number of jobs it has done, whose job is a number of milliseconds to take, and whose result is `job * 1000 + jobs done before`.

## Steps / inputs
1. Start a pool of 3 workers. Submit three jobs of 300 ms: the three are taken, by workers 0, 1 and 2, and `pool busy` is 3. Submit a fourth: it is refused at once (`-1`, in less than 100 ms) and `pool refused` is 1.
2. With the three jobs in flight, collect without waiting: no result, at once. Collect with 50 ms: no result after about 50 ms.
3. Wait on `pool done fd`: it becomes readable. Collect with 2 000 ms until the three results are in: each one comes exactly once, with the worker that ran it and its tag, and `pool busy` goes back to 0.
4. Submit two jobs of 200 ms and 20 ms: the second ends first, and each result still carries its own job.
5. Submit a job to a worker that has already done one: its result shows the state the first job left (jobs done before = 1), and another worker's shows its own.
6. Submit jobs with the tags `a`, `a` and `b`: `pool tagged` answers 2 for `a`, 1 for `b`, 0 for `c`; after collecting, 0 for all.
7. Submit two jobs and drain with 2 000 ms: both results come back, `pool busy` is 0, and a job submitted afterwards is refused.
8. `pool start 0` gives a pool of 1 worker and `pool start 100` one of 64.
9. Routing by key over a list of agents: keys 0, 1, 2, 3, 7 (twice) and -2 on three counter agents; `pool drain all` with nothing ready; `pool broadcast`; a list of one agent; `pool shutdown`; `pool ask shard or` on an empty list gives its default; `pool size` of `Pool 5 [a, b]` is 2.

## Expected results (map to acceptance criteria)
- AC1 → steps 1 and 5. AC2 → step 1. AC3 → step 3. AC4 → step 2. AC5 → step 6. AC6 → steps 3 and 4. AC7 → step 7. AC8 → step 9.
- Constraints (1 to 64 workers) → step 8.

## Not covered here (to avoid duplication)
- The agents themselves (`TS-AGENT-001`).
- `pool ask shard` on an empty list: it stops the program, so it is checked by hand, not in the suite.
